import { assert, assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";
import { messageFor } from "./messages.ts";
import type { NotifType } from "./caps.ts";

Deno.test("messageFor: every type has non-empty title+body", () => {
  const types: NotifType[] = ["streak", "weekly_goal", "goal_achieved", "comeback"];
  for (const t of types) {
    const m = messageFor(t);
    assert(m.title.length > 0, `${t} title`);
    assert(m.body.length > 0, `${t} body`);
  }
});

Deno.test("messageFor: goal_achieved is celebratory copy", () => {
  assertEquals(messageFor("goal_achieved").title, "Goal smashed! 🎉");
});
