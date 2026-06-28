import { assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";
import { inQuietHours, currentStreak, weeklyProgress, daysSinceLastRun } from "./rules.ts";

Deno.test("inQuietHours: wrapping window 21:00->08:00", () => {
  assertEquals(inQuietHours(1290, 1260, 480), true);  // 21:30 inside
  assertEquals(inQuietHours(60, 1260, 480), true);    // 01:00 inside
  assertEquals(inQuietHours(479, 1260, 480), true);   // 07:59 inside
  assertEquals(inQuietHours(480, 1260, 480), false);  // 08:00 end-exclusive
  assertEquals(inQuietHours(720, 1260, 480), false);  // 12:00 outside
  assertEquals(inQuietHours(1259, 1260, 480), false); // 20:59 outside
});

Deno.test("currentStreak: consecutive days ending today", () => {
  const now = new Date("2026-06-28T18:00:00Z"); // Sun, UTC
  const runs = [
    "2026-06-28T07:00:00Z",
    "2026-06-27T07:00:00Z",
    "2026-06-26T07:00:00Z",
  ];
  assertEquals(currentStreak(runs, now, "UTC"), 3);
});

Deno.test("currentStreak: ending yesterday still counts; gap breaks it", () => {
  const now = new Date("2026-06-28T18:00:00Z");
  assertEquals(currentStreak(["2026-06-27T07:00:00Z", "2026-06-26T07:00:00Z"], now, "UTC"), 2);
  // Last run 2 days ago -> streak is 0 (not active).
  assertEquals(currentStreak(["2026-06-26T07:00:00Z"], now, "UTC"), 0);
  assertEquals(currentStreak([], now, "UTC"), 0);
});

Deno.test("weeklyProgress: distance metric this week", () => {
  const now = new Date("2026-06-28T18:00:00Z"); // Sun
  const runs = [
    { started_at: "2026-06-22T07:00:00Z", distance_m: 3000, duration_s: 1000 }, // Mon, in week
    { started_at: "2026-06-24T07:00:00Z", distance_m: 5000, duration_s: 1500 }, // Wed, in week
    { started_at: "2026-06-21T07:00:00Z", distance_m: 9999, duration_s: 9999 }, // last Sun, excluded
  ];
  const p = weeklyProgress(runs, { type: "distance", target_value: 10000 }, now, "UTC");
  assertEquals(p.current, 8000);
  assertEquals(p.target, 10000);
  assertEquals(p.met, false);
});

Deno.test("weeklyProgress: runs metric met; null goal -> target 0", () => {
  const now = new Date("2026-06-28T18:00:00Z");
  const runs = [
    { started_at: "2026-06-22T07:00:00Z", distance_m: 1, duration_s: 1 },
    { started_at: "2026-06-24T07:00:00Z", distance_m: 1, duration_s: 1 },
    { started_at: "2026-06-26T07:00:00Z", distance_m: 1, duration_s: 1 },
  ];
  assertEquals(weeklyProgress(runs, { type: "runs", target_value: 3 }, now, "UTC").met, true);
  assertEquals(weeklyProgress(runs, null, now, "UTC"), { current: 3, target: 0, met: false });
});

Deno.test("weeklyProgress: duration metric sums duration_s this week", () => {
  const now = new Date("2026-06-28T18:00:00Z"); // Sun
  const runs = [
    { started_at: "2026-06-22T07:00:00Z", distance_m: 3000, duration_s: 1200 }, // Mon, in week
    { started_at: "2026-06-24T07:00:00Z", distance_m: 5000, duration_s: 1800 }, // Wed, in week
    { started_at: "2026-06-21T07:00:00Z", distance_m: 9999, duration_s: 9999 }, // last Sun, excluded
  ];
  const p = weeklyProgress(runs, { type: "duration", target_value: 3000 }, now, "UTC");
  assertEquals(p.current, 3000);
  assertEquals(p.target, 3000);
  assertEquals(p.met, true);
});

Deno.test("daysSinceLastRun", () => {
  const now = new Date("2026-06-28T18:00:00Z");
  assertEquals(daysSinceLastRun(["2026-06-21T07:00:00Z"], now, "UTC"), 7);
  assertEquals(daysSinceLastRun(["2026-06-28T07:00:00Z"], now, "UTC"), 0);
  assertEquals(daysSinceLastRun([], now, "UTC"), null);
});
