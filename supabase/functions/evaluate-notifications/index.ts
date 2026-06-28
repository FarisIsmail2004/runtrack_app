import { createClient } from "npm:@supabase/supabase-js@2";
import { GoogleAuth } from "npm:google-auth-library@9";
import { localParts, minutesOfDay } from "./week.ts";
import {
  currentStreak, daysSinceLastRun, inQuietHours, weeklyProgress,
  type RunRow, type Goal,
} from "./rules.ts";
import { eligibleByCaps, pickOne, type LogRow, type NotifType } from "./caps.ts";
import { messageFor } from "./messages.ts";
import { makeFcmSender } from "./fcm.ts";

type Prefs = {
  streak_alerts: boolean; weekly_goal_alerts: boolean;
  goal_achieved_alerts: boolean; comeback_alerts: boolean;
  quiet_hours_start_min: number; quiet_hours_end_min: number;
};

type DecideInput = {
  nowUtc: Date; tz: string; prefs: Prefs;
  runs: RunRow[]; goal: Goal; log: LogRow[];
};

const COMEBACK_DAYS = 7;
const STREAK_MIN = 2;
const EVENING_START_MIN = 17 * 60; // 17:00 local

// Pure: decide the single notification (if any) to send to one user right now.
export function decideForUser(input: DecideInput): NotifType | null {
  const { nowUtc, tz, prefs, runs, goal, log } = input;
  const local = localParts(nowUtc, tz);
  const localMin = minutesOfDay(local);

  if (inQuietHours(localMin, prefs.quiet_hours_start_min, prefs.quiet_hours_end_min)) {
    return null;
  }

  const runIsos = runs.map((r) => r.started_at);
  const lastRunIso = runIsos.length
    ? runIsos.reduce((a, b) => (a > b ? a : b))
    : null;

  const candidates: NotifType[] = [];

  // Compute weekly progress once and reuse for both goal_achieved and weekly_goal.
  const wp = weeklyProgress(runs, goal, nowUtc, tz);

  // goal_achieved: this week's goal met.
  if (prefs.goal_achieved_alerts && wp.met) {
    candidates.push("goal_achieved");
  }
  // streak: active streak >= 2, no run today, evening local.
  if (prefs.streak_alerts) {
    const streak = currentStreak(runIsos, nowUtc, tz);
    const ranToday = daysSinceLastRun(runIsos, nowUtc, tz) === 0;
    if (streak >= STREAK_MIN && !ranToday && localMin >= EVENING_START_MIN) {
      candidates.push("streak");
    }
  }
  // weekly_goal: behind, <=2 days left in the week (Sat=6, Sun=7), goal set.
  if (prefs.weekly_goal_alerts && goal) {
    const daysLeft = 7 - local.weekday; // Sun -> 0, Sat -> 1
    if (!wp.met && daysLeft <= 2) candidates.push("weekly_goal");
  }
  // comeback: inactive >= 7 days.
  if (prefs.comeback_alerts) {
    const since = daysSinceLastRun(runIsos, nowUtc, tz);
    if (since !== null && since >= COMEBACK_DAYS) candidates.push("comeback");
  }

  const eligible = candidates.filter((c) => eligibleByCaps(c, log, nowUtc, tz, lastRunIso));
  return pickOne(eligible);
}

// ── HTTP handler (invoked hourly by pg_cron) ─────────────────────────────────
// Guard with import.meta.main so tests can import decideForUser without
// Deno.serve trying to bind a port during the test run.
if (import.meta.main) {
  Deno.serve(async (req) => {
    // Authenticate the cron caller with a shared secret.
    const cronSecret = Deno.env.get("CRON_SECRET");
    if (!cronSecret || req.headers.get("x-cron-secret") !== cronSecret) {
      return new Response("unauthorized", { status: 401 });
    }

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );

    // Access token for FCM v1 from the service-account credential.
    const projectId = Deno.env.get("FCM_PROJECT_ID")!;
    const credentials = JSON.parse(Deno.env.get("FCM_SERVICE_ACCOUNT")!);
    const auth = new GoogleAuth({
      credentials,
      scopes: ["https://www.googleapis.com/auth/firebase.messaging"],
    });
    const accessToken = (await auth.getAccessToken()) as string;
    const send = makeFcmSender(projectId, accessToken);

    const nowUtc = new Date();

    // Users that have at least one Android device token.
    const { data: tokenRows, error: tokErr } = await supabase
      .from("device_tokens")
      .select("user_id, token, platform, timezone")
      .eq("platform", "android");
    if (tokErr) return new Response(`db error: ${tokErr.message}`, { status: 500 });

    const byUser = new Map<string, { tz: string; tokens: string[] }>();
    for (const r of tokenRows ?? []) {
      const existing = byUser.get(r.user_id);
      if (existing) {
        existing.tz = r.timezone || "UTC";
        existing.tokens.push(r.token as string);
      } else {
        byUser.set(r.user_id, { tz: r.timezone || "UTC", tokens: [r.token as string] });
      }
    }

    let sent = 0;
    for (const [userId, { tz, tokens }] of byUser) {
      const [
        { data: prefsRow, error: prefsErr },
        { data: runs, error: runsErr },
        { data: goals, error: goalsErr },
        { data: log, error: logErr },
      ] = await Promise.all([
        supabase.from("notification_prefs").select("*").eq("user_id", userId).maybeSingle(),
        supabase.from("runs").select("started_at, distance_m, duration_s")
          .eq("user_id", userId).not("ended_at", "is", null)
          .order("started_at", { ascending: false }).limit(60),
        supabase.from("goals").select("type, target_value")
          .eq("user_id", userId).order("created_at", { ascending: false }).limit(1),
        supabase.from("notification_log").select("type, sent_at")
          .eq("user_id", userId).order("sent_at", { ascending: false }).limit(30),
      ]);

      if (prefsErr || runsErr || goalsErr || logErr) {
        console.error(
          `skip user ${userId}: ${prefsErr?.message ?? runsErr?.message ?? goalsErr?.message ?? logErr?.message}`,
        );
        continue;
      }

      const prefs: Prefs = prefsRow ?? {
        streak_alerts: true, weekly_goal_alerts: true,
        goal_achieved_alerts: true, comeback_alerts: true,
        quiet_hours_start_min: 1260, quiet_hours_end_min: 480,
      };
      const goal: Goal = goals && goals.length ? goals[0] : null;

      const type = decideForUser({
        nowUtc, tz, prefs,
        runs: (runs ?? []) as RunRow[],
        goal,
        log: (log ?? []) as LogRow[],
      });
      if (!type) continue;

      const { title, body } = messageFor(type);
      let delivered = false;
      for (const token of tokens) {
        if (await send(token, title, body, { type })) delivered = true;
      }
      if (delivered) {
        const { error: insErr } = await supabase
          .from("notification_log")
          .insert({ user_id: userId, type });
        if (insErr) {
          console.error(`failed to log notification for user ${userId}: ${insErr.message}`);
        } else {
          sent++;
        }
      }
    }

    return new Response(JSON.stringify({ ok: true, sent }), {
      headers: { "Content-Type": "application/json" },
    });
  });
}
