import { assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";
import { decideForUser } from "./index.ts";

const base = {
  nowUtc: new Date("2026-06-28T18:30:00Z"), // Sun 18:30 UTC -> evening
  tz: "UTC",
  prefs: {
    streak_alerts: true, weekly_goal_alerts: true,
    goal_achieved_alerts: true, comeback_alerts: true,
    quiet_hours_start_min: 1260, quiet_hours_end_min: 480,
  },
  runs: [] as { started_at: string; distance_m: number; duration_s: number }[],
  goal: null as ({ type: string; target_value: number } | null),
  log: [] as { type: "streak"|"weekly_goal"|"goal_achieved"|"comeback"; sent_at: string }[],
};

Deno.test("decideForUser: quiet hours -> null", () => {
  const input = { ...base, nowUtc: new Date("2026-06-28T22:00:00Z") };
  assertEquals(decideForUser(input), null);
});

Deno.test("decideForUser: goal achieved beats streak", () => {
  const runs = [
    { started_at: "2026-06-26T07:00:00Z", distance_m: 4000, duration_s: 1200 }, // Fri
    { started_at: "2026-06-27T07:00:00Z", distance_m: 4000, duration_s: 1200 }, // Sat
    { started_at: "2026-06-28T07:00:00Z", distance_m: 4000, duration_s: 1200 }, // Sun (streak 3)
  ];
  const input = { ...base, runs, goal: { type: "distance", target_value: 10000 } };
  assertEquals(decideForUser(input), "goal_achieved");
});

Deno.test("decideForUser: comeback when inactive >=7 days", () => {
  const input = { ...base, runs: [
    { started_at: "2026-06-19T07:00:00Z", distance_m: 3000, duration_s: 900 },
  ] };
  assertEquals(decideForUser(input), "comeback");
});

Deno.test("decideForUser: disabled type is not chosen", () => {
  const input = {
    ...base,
    prefs: { ...base.prefs, comeback_alerts: false },
    runs: [{ started_at: "2026-06-19T07:00:00Z", distance_m: 3000, duration_s: 900 }],
  };
  assertEquals(decideForUser(input), null);
});

Deno.test("decideForUser: already sent today -> null", () => {
  const runs = [{ started_at: "2026-06-19T07:00:00Z", distance_m: 3000, duration_s: 900 }];
  const log = [{ type: "comeback" as const, sent_at: "2026-06-28T08:00:00Z" }];
  assertEquals(decideForUser({ ...base, runs, log }), null);
});
