import { weekStartUtc, localDayString } from "./week.ts";

export type NotifType = "streak" | "weekly_goal" | "goal_achieved" | "comeback";
export type LogRow = { type: NotifType; sent_at: string };

const PRIORITY: NotifType[] = ["goal_achieved", "streak", "weekly_goal", "comeback"];

export function pickOne(candidates: NotifType[]): NotifType | null {
  for (const t of PRIORITY) if (candidates.includes(t)) return t;
  return null;
}

export function eligibleByCaps(
  candidate: NotifType,
  log: LogRow[],
  nowUtc: Date,
  tz: string,
  lastRunUtc: string | null,
): boolean {
  const today = localDayString(nowUtc, tz);
  const weekStart = weekStartUtc(nowUtc, tz).getTime();

  // Global guardrail: at most one conditional push per user per local day.
  const sentToday = log.some((l) => localDayString(new Date(l.sent_at), tz) === today);
  if (sentToday) return false;

  const sameType = log.filter((l) => l.type === candidate);
  switch (candidate) {
    case "streak":
      // 1x/day — already covered by the global daily cap; nothing extra.
      return true;
    case "weekly_goal":
    case "goal_achieved":
      // 1x/week.
      return !sameType.some((l) => new Date(l.sent_at).getTime() >= weekStart);
    case "comeback": {
      // 1 per inactivity spell: suppress if the most recent comeback was sent
      // and no run has happened since.
      if (sameType.length === 0) return true;
      const lastComeback = sameType
        .map((l) => new Date(l.sent_at).getTime())
        .reduce((a, b) => Math.max(a, b), 0);
      const lastRun = lastRunUtc ? new Date(lastRunUtc).getTime() : 0;
      return lastRun > lastComeback;
    }
  }
}
