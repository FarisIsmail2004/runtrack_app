# RunTrack UX Refresh (Spec A) — Design

**Date:** 2026-06-22
**Status:** Approved (design); pending implementation plan
**Scope:** Visual reskin + data-visualization layer over the existing, working app. **No behavior change.**

## Context

`runtrack_app` is a fully-built Flutter running tracker (auth, onboarding, live-run with 4 phases, run summary, history, run detail, profile — plus the Riverpod notifiers, drift DAOs, and Supabase sync behind them). The user supplied a reimagined UI (`RunTrack UX Refresh.pdf`, rendered to `design/refresh/*.png`). The design's own stated intent:

> "Dark + orange kept exactly as-is. The work targets the two things you flagged — **consistency across screens** and **stronger data visualization**."

So this is a reskin, not a rebuild. The dark+orange identity stays; we add a consistent component system and real data-viz (goal ring, weekly bars, route sparklines, live pace trend), and a serif-forward type treatment.

This is **Spec A of two**. Spec B (Smart Notifications — hybrid local + server push) is a separate spec, built after A, and consumes A's components.

## Decisions locked

- **Sequence:** Spec A (refresh) fully, then Spec B (notifications).
- **Build approach:** design-system-first — tokens + shared widget kit first, then screens compose them.
- **Typography:** Fraunces (display/headlines/numbers, tabular figures) + Inter (body/labels), via `google_fonts`, self-hosted in `assets/fonts/` for offline reliability.
- **Charts:** hand-rolled `CustomPainter` (no `fl_chart`).
- **No behavior change:** only `lib/shared/theme/`, `lib/shared/widgets/`, `lib/shared/charts/`, and `presentation/` layers change. `application/`, `data/`, `domain/`, `core/` (outside theme) untouched. Routes/providers unchanged.

## Section 1 — Design tokens (`lib/shared/theme/`)

Pixel-sampled from the mockups.

| Token | Value | Use |
|---|---|---|
| `accent` | `#FF6A1A` | primary CTAs, active route, highlights (was `#FF6A00`) |
| `base` | `#0B0B0C` | scaffold background (was pure black) |
| `surface` | `#161618` | cards, sheets, list tiles |
| `surfaceBorder` | white @ 8% | hairline card borders |
| `success` (GPS OK) | `#2EBC51` | strong GPS, run-day bar, positive trend badge |
| `warning` (GPS weak) | `#EFA31C` | weak GPS pill + banner, paused accent |
| `destructive` | `#FF453A` | Discard, Log Out, Stop icon |
| `textPrimary` | `#FFFFFF` | numbers, headlines |
| `textMuted` | `#8A8A8E` | uppercase labels, secondary text |

**Type scale** (Fraunces display + Inter body):

- `display` — Fraunces 700; wordmark, screen titles, big timer, stat numbers, `%`. **Tabular figures on** for timer/pace.
- `headline` — Fraunces 600; card titles, sheet titles.
- `body` — Inter 400/500; descriptions, list metadata.
- `label` — Inter 600, uppercase, +0.08em tracking, `textMuted`; "THIS WEEK", "ELAPSED TIME", "DIST · KM".

**Geometry:** card radius 20; button radius 16; pill radius full; card padding 20; screen gutter 20; primary buttons carry a soft accent glow (the START RUN shadow). `flutter_screenutil` stays for responsive sizing; tokens centralize the magic numbers.

## Section 2 — Shared widget kit (`lib/shared/widgets/`, `lib/shared/charts/`)

Each is self-contained and independently testable.

- **`StatCell` / `StatGrid`** — big Fraunces number + uppercase label; row variant (live-run 3-up) and 2×2 grid variant (summary); optional per-cell accent (pace = orange).
- **`GoalRing`** — `CustomPainter` arc, orange progress on dark track, % centered. Clamps 0–100%.
- **`WeeklyBarChart`** — 7 bars M–S, muted with the highlighted day in accent.
- **`RouteSparkline`** — `CustomPainter` polyline on a faint grid; green start marker + end marker; **dashed** variant (weak GPS) and a pulsing **live-position** dot. Powers the live map overlay, last-run thumbnail, history tiles, summary header.
- **`TrendLine`** — area/line trend for history "182 km this year" and the live "PACE TREND" mini-card.
- **`GpsPill`** — fixed-position centered pill; states STRONG (green) / WEAK (amber) / ACQUIRING. **Never moves** (replaces the layout-shifting `gps_status`).
- **`RunControlBar`** — unified lock · play/pause · stop; identical across active/paused/weak (the "one control bar" mandate).
- **`PaceBars`** — restyle of `pace_by_km_list` to proportional orange bars.
- **`PrimaryButton` / `SecondaryButton` / `DestructiveButton`**, **`SectionHeader`**, **`PageDots`** (elongated active pill), **`AppBottomNav`** (Home/History/Profile, orange active).

New dependency: `google_fonts` only.

## Section 3 — Screen-by-screen mapping

Every screen keeps its current logic, providers, and routes; only `build`/widgets change.

| Screen | File(s) | New look |
|---|---|---|
| Onboarding | `onboarding_screen.dart` + widgets | 4 slides: Welcome (wordmark, tagline, Create Account / Log In), Tour·Map, Tour·Stats (stat card), Tour·Progress (weekly bars). `PageDots`; "Skip" top-right. |
| Auth | `login_screen.dart`, `signup_screen.dart`, `auth_widgets.dart` | Unified screen with segmented **Sign up / Log in** toggle; "Continue with Apple" first; live password-strength meter; 54px tap targets. Reuses `auth_notifier`. |
| Home | `home_screen.dart` | "Ready to run, {name}?" + avatar button; glowing **START RUN**; "THIS WEEK" card = `StatGrid` + `GoalRing` + `WeeklyBarChart`; "Last run" card with `RouteSparkline`; `AppBottomNav`. Folds in `weekly_goal_card` data. |
| Live Run (4 states) | `live_run_screen.dart`, `gps_status.dart`→`GpsPill`, `run_controls.dart`→`RunControlBar`, `run_map.dart`, `stat_block.dart`, `stop_confirm_sheet.dart` | Fixed `GpsPill`; big Fraunces timer; `StatGrid` row (pace orange); map + `RouteSparkline` overlay + "PACE TREND" mini-card; `RunControlBar`. **Active**: white timer / green pill / bright route. **Paused**: dimmed timer / amber pill / desaturated route + grey position dot. **Weak**: amber pill + inline warning banner + dashed route, no layout jump. **Confirm Stop**: bottom sheet (red stop icon, recap stats, Finish & Save / Keep running). |
| Run Summary | `run_summary_view.dart`, `run_summary_screen.dart` | Back/title/delete app bar; `RouteSparkline` header; 2×2 `StatGrid` (Distance/Duration/Avg Pace/Calories); `PaceBars`; Save Run / Discard. |
| History | `history_screen.dart`, `run_list_tile.dart`, `route_thumbnail.dart` | Title + filter; "182 km · this year" card with `TrendLine` + green `+12%` badge; month sections; tiles = sparkline + date + metadata + chevron. |
| Run Detail | `run_detail_screen.dart` | Same composition as Summary, read-only. |
| Profile | `profile_screen.dart` | Title + Edit; orange avatar with initials; name + email; `StatGrid` (Runs/Total/Avg); settings rows (Weight, Units, Weekly goal, **Notifications →**); Log Out. The **Notifications row routes to a placeholder screen** in Spec A; Spec B fills it in. |

## Section 4 — Constraints, dependencies, testing

- **No behavior change.** No edits to `application/`, `data/`, `domain/`, or `core/` outside `theme/`. Routes/providers untouched.
- **New dependency:** `google_fonts` only. Charts are `CustomPainter`.
- **Fonts:** bundle Fraunces + Inter in `assets/fonts/` (self-hosted, offline-safe — matches the offline-first rule). Declared in `pubspec.yaml`.
- **`flutter_screenutil`** stays; tokens centralize magic numbers.
- **Testing:** existing widget tests stay green; update any asserting on removed widgets (e.g. old `gps_status`). Add logic tests for new painters (`GoalRing` clamps 0–100%, `WeeklyBarChart` highlights correct day, `RouteSparkline` dashed/live-dot variants render without error). `flutter analyze` clean; `dart format .` applied.
- **Scope guard (YAGNI):** no new screens beyond the Notifications placeholder; no theme toggle (dark-only as today); no animation beyond the live-position pulse and existing `reveal_in`.

## Out of scope (→ Spec B)

- Smart notifications: hybrid delivery — local notifications (instant goal-congrats + scheduled preferred-time reminder) and server push via Supabase Edge Function + `pg_cron` → FCM/APNs (inactivity nudge + weekly-goal-at-risk).
- Re-engagement triggers: inactivity (no run in N days), weekly-goal-at-risk, user-set preferred time/days + quiet hours. (Streak protection explicitly excluded.)
- The functional Notifications settings screen behind the Profile row.

## Reference assets

- Source: `RunTrack UX Refresh.pdf` (repo root)
- Rendered pages: `design/refresh/page-1..3.png`, hi-res `design/refresh/hi-1..3.png`
- Per-screen crops: `design/refresh/c_*.png`
