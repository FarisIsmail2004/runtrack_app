import { localParts, minutesOfDay, weekStartUtc, localDayString } from "./week.ts";

export type RunRow = { started_at: string; distance_m: number; duration_s: number };
export type Goal = { type: string; target_value: number } | null;

export function inQuietHours(localMin: number, startMin: number, endMin: number): boolean {
  if (startMin === endMin) return false;
  if (startMin < endMin) return localMin >= startMin && localMin < endMin;
  // Wrapping window (e.g. 1260..480): inside if at/after start OR before end.
  return localMin >= startMin || localMin < endMin;
}

// Distinct local calendar days that have >=1 run, as YYYY-MM-DD.
function runDaySet(runsUtc: string[], tz: string): Set<string> {
  const days = new Set<string>();
  for (const iso of runsUtc) days.add(localDayString(new Date(iso), tz));
  return days;
}

function addDays(dayStr: string, delta: number): string {
  const [y, m, d] = dayStr.split("-").map(Number);
  const dt = new Date(Date.UTC(y, m - 1, d));
  dt.setUTCDate(dt.getUTCDate() + delta);
  return dt.toISOString().slice(0, 10);
}

export function currentStreak(runsUtc: string[], nowUtc: Date, tz: string): number {
  const days = runDaySet(runsUtc, tz);
  if (days.size === 0) return 0;
  const today = localDayString(nowUtc, tz);
  const yesterday = addDays(today, -1);
  // An active streak must include today or yesterday.
  let cursor: string;
  if (days.has(today)) cursor = today;
  else if (days.has(yesterday)) cursor = yesterday;
  else return 0;
  let streak = 0;
  while (days.has(cursor)) {
    streak++;
    cursor = addDays(cursor, -1);
  }
  return streak;
}

export function weeklyProgress(runs: RunRow[], goal: Goal, nowUtc: Date, tz: string) {
  const start = weekStartUtc(nowUtc, tz).getTime();
  const inWeek = runs.filter((r) => new Date(r.started_at).getTime() >= start);
  const metric = goal?.type ?? "runs";
  const current = metric === "distance"
    ? inWeek.reduce((s, r) => s + r.distance_m, 0)
    : metric === "duration"
    ? inWeek.reduce((s, r) => s + r.duration_s, 0)
    : inWeek.length;
  const target = goal?.target_value ?? 0;
  return { current, target, met: target > 0 && current >= target };
}

export function daysSinceLastRun(runsUtc: string[], nowUtc: Date, tz: string): number | null {
  if (runsUtc.length === 0) return null;
  const today = localDayString(nowUtc, tz);
  let maxDay = "";
  for (const iso of runsUtc) {
    const d = localDayString(new Date(iso), tz);
    if (d > maxDay) maxDay = d;
  }
  // Difference in whole local days between maxDay and today.
  const [ty, tm, td] = today.split("-").map(Number);
  const [my, mm, md] = maxDay.split("-").map(Number);
  const diffMs = Date.UTC(ty, tm - 1, td) - Date.UTC(my, mm - 1, md);
  return Math.max(0, Math.round(diffMs / 86400000));
}
