// Pure date helpers. Timezone math uses Intl so no extra deps are needed.

type Parts = {
  year: number; month: number; day: number;
  hour: number; minute: number; weekday: number; // weekday 1=Mon..7=Sun
};

const WEEKDAY_INDEX: Record<string, number> = {
  Mon: 1, Tue: 2, Wed: 3, Thu: 4, Fri: 5, Sat: 6, Sun: 7,
};

export function localParts(nowUtc: Date, timeZone: string): Parts {
  const fmt = new Intl.DateTimeFormat("en-US", {
    timeZone, year: "numeric", month: "2-digit", day: "2-digit",
    hour: "2-digit", minute: "2-digit", hour12: false, weekday: "short",
  });
  const map: Record<string, string> = {};
  for (const part of fmt.formatToParts(nowUtc)) map[part.type] = part.value;
  return {
    year: Number(map.year),
    month: Number(map.month),
    day: Number(map.day),
    hour: Number(map.hour === "24" ? "0" : map.hour),
    minute: Number(map.minute),
    weekday: WEEKDAY_INDEX[map.weekday] ?? 1,
  };
}

export function minutesOfDay(p: { hour: number; minute: number }): number {
  return p.hour * 60 + p.minute;
}

// The UTC instant corresponding to local wall-clock `Y-M-D H:M` in `timeZone`.
function zonedWallClockToUtc(
  y: number, mo: number, d: number, h: number, mi: number, timeZone: string,
): Date {
  // Guess from a UTC instant with the same wall-clock numbers, then correct by
  // the zone offset that guess lands on (one iteration is exact for whole-minute
  // offsets, which all IANA zones use).
  const guess = new Date(Date.UTC(y, mo - 1, d, h, mi));
  const p = localParts(guess, timeZone);
  const guessAsLocalMs = Date.UTC(p.year, p.month - 1, p.day, p.hour, p.minute);
  const wantedMs = Date.UTC(y, mo - 1, d, h, mi);
  return new Date(guess.getTime() + (wantedMs - guessAsLocalMs));
}

export function weekStartUtc(nowUtc: Date, timeZone: string): Date {
  const p = localParts(nowUtc, timeZone);
  // Monday 00:00 local of this week.
  const mondayUtcMidnightGuess = zonedWallClockToUtc(
    p.year, p.month, p.day, 0, 0, timeZone,
  );
  // Step back (weekday-1) whole days from local midnight today.
  return new Date(mondayUtcMidnightGuess.getTime() - (p.weekday - 1) * 86400000);
}

export function localDayString(instantUtc: Date, timeZone: string): string {
  const p = localParts(instantUtc, timeZone);
  const mm = String(p.month).padStart(2, "0");
  const dd = String(p.day).padStart(2, "0");
  return `${p.year}-${mm}-${dd}`;
}
