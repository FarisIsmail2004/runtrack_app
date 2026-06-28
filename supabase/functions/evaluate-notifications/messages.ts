import type { NotifType } from "./caps.ts";

// Hand-written templated copy — no AI. Keep short and glanceable.
const TEMPLATES: Record<NotifType, { title: string; body: string }> = {
  streak: {
    title: "Keep your streak alive 🔥",
    body: "You've run several days in a row — a quick one today keeps it going.",
  },
  weekly_goal: {
    title: "Your weekly goal is in reach",
    body: "You're close. A run or two before the week ends will get you there.",
  },
  goal_achieved: {
    title: "Goal smashed! 🎉",
    body: "You hit your weekly goal. Nice work — enjoy the win.",
  },
  comeback: {
    title: "We miss your runs 👟",
    body: "It's been a while. A short, easy run is a great way back.",
  },
};

export function messageFor(type: NotifType): { title: string; body: string } {
  return TEMPLATES[type];
}
