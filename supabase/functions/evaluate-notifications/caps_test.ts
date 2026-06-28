import { assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";
import { eligibleByCaps, pickOne } from "./caps.ts";

const now = new Date("2026-06-28T18:00:00Z"); // Sun, UTC
const tz = "UTC";

Deno.test("pickOne: priority order", () => {
  assertEquals(pickOne(["comeback", "streak", "goal_achieved"]), "goal_achieved");
  assertEquals(pickOne(["comeback", "weekly_goal"]), "weekly_goal");
  assertEquals(pickOne([]), null);
});

Deno.test("global cap: anything sent today blocks all", () => {
  const log = [{ type: "streak" as const, sent_at: "2026-06-28T07:00:00Z" }];
  assertEquals(eligibleByCaps("weekly_goal", log, now, tz, null), false);
});

Deno.test("streak: 1x/day", () => {
  assertEquals(eligibleByCaps("streak", [], now, tz, null), true);
  const log = [{ type: "streak" as const, sent_at: "2026-06-27T18:00:00Z" }]; // yesterday
  assertEquals(eligibleByCaps("streak", log, now, tz, null), true);
});

Deno.test("weekly_goal & goal_achieved: 1x/week", () => {
  const thisWeek = [{ type: "weekly_goal" as const, sent_at: "2026-06-23T09:00:00Z" }]; // Tue
  assertEquals(eligibleByCaps("weekly_goal", thisWeek, now, tz, null), false);
  const lastWeek = [{ type: "goal_achieved" as const, sent_at: "2026-06-20T09:00:00Z" }];
  assertEquals(eligibleByCaps("goal_achieved", lastWeek, now, tz, null), true);
});

Deno.test("comeback: suppressed until the user runs again", () => {
  // Comeback sent after the last run -> still in the same inactivity spell.
  const log = [{ type: "comeback" as const, sent_at: "2026-06-20T09:00:00Z" }];
  assertEquals(eligibleByCaps("comeback", log, now, tz, "2026-06-19T07:00:00Z"), false);
  // A run happened after the last comeback -> a new spell, eligible again.
  assertEquals(eligibleByCaps("comeback", log, now, tz, "2026-06-21T07:00:00Z"), true);
  assertEquals(eligibleByCaps("comeback", [], now, tz, null), true);
});
