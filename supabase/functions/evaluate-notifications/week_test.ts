import { assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";
import { localParts, minutesOfDay, weekStartUtc, localDayString } from "./week.ts";

Deno.test("localParts: UTC instant rendered in a +offset zone", () => {
  // 2026-06-28T23:30:00Z is 2026-06-29 09:30 in Australia/Sydney (UTC+10).
  const p = localParts(new Date("2026-06-28T23:30:00Z"), "Australia/Sydney");
  assertEquals(p.year, 2026);
  assertEquals(p.month, 6);
  assertEquals(p.day, 29);
  assertEquals(p.hour, 9);
  assertEquals(p.minute, 30);
  assertEquals(p.weekday, 1); // Monday
});

Deno.test("minutesOfDay", () => {
  assertEquals(minutesOfDay({ hour: 0, minute: 0 }), 0);
  assertEquals(minutesOfDay({ hour: 21, minute: 0 }), 1260);
  assertEquals(minutesOfDay({ hour: 8, minute: 30 }), 510);
});

Deno.test("weekStartUtc: Monday 00:00 local in UTC", () => {
  // Sunday 2026-06-28 12:00Z, zone UTC -> week Monday is 2026-06-22 00:00Z.
  const ws = weekStartUtc(new Date("2026-06-28T12:00:00Z"), "UTC");
  assertEquals(ws.toISOString(), "2026-06-22T00:00:00.000Z");

  // 2026-06-28T23:30Z is Mon 09:30 Sydney (AEST, UTC+10) -> week start = Mon 00:00 AEST.
  const wsSyd = weekStartUtc(new Date("2026-06-28T23:30:00Z"), "Australia/Sydney");
  assertEquals(wsSyd.toISOString(), "2026-06-28T14:00:00.000Z");
});

Deno.test("localDayString", () => {
  assertEquals(localDayString(new Date("2026-06-28T23:30:00Z"), "Australia/Sydney"), "2026-06-29");
  assertEquals(localDayString(new Date("2026-06-28T23:30:00Z"), "UTC"), "2026-06-28");
});
