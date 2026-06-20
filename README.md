# RunTrack

**An offline-first mobile running tracker built with Flutter.** Start a run, watch live stats and your route draw on a map in real time, then review a full summary and history — all while staying reliable even with no connectivity mid-run.

RunTrack is a portfolio project built to production standards: layered feature-first architecture, an offline-capable local database as the source of truth, background GPS tracking that survives a locked screen, Postgres + Row Level Security on the backend, and a ~33-file automated test suite.

---

## What it does

A runner opens the app, hits **Start Run**, sees live distance / pace / time with their route drawing on a map, can pause and resume, finishes with a confirmation step, reviews a summary, and finds the run saved in their history — synced to the cloud when a connection is available.

### Core features

- **Live run tracking** — real-time distance, duration, current pace, and average pace computed from a stream of GPS points, with the route drawn as a live polyline.
- **Background location** — tracking continues with the screen off via an Android foreground service (persistent notification) and iOS background-location mode, so a run is never silently dropped.
- **Distinct run states** — *acquiring GPS*, *active*, *paused*, and *weak/lost signal* each get their own clear treatment, with a **confirmation step before stopping** so a run is never ended by accident.
- **Accurate distance & pace** — Haversine distance between points with **GPS-jitter filtering**, so a stationary phone doesn't inflate the total.
- **Run summary & history** — post-run summary (distance, duration, average pace, estimated calories, completed route, optional per-kilometre pace splits), a scrollable history list, and a detail view per run.
- **Calorie estimation** — MET-based estimate using the runner's weight from their profile.
- **Goals** — set and track weekly running goals with live progress.
- **Profile & units** — weight (for calorie estimates), km/mi unit preference, and account management.
- **Auth** — email/password sign-up & login (Supabase Auth), with Google / Apple sign-in wired in. Runs **fully offline** with no backend configured, dropping straight to the home screen.

### Offline-first by design

The local [drift](https://drift.simonbinder.eu/) database is the **source of truth** during and after a run — never the network. A run is persisted as it happens and survives an app kill. Rows are flagged `synced = false` and a **background sync service** uploads them to Supabase when connectivity returns, handling the retry case rather than assuming the network is there.

---

## Screens

| Screen | Purpose |
| --- | --- |
| **Auth** | Email/password sign-up & login (skipped entirely in offline mode). |
| **Home / Dashboard** | Prominent **Start Run** CTA plus a glance at recent activity and weekly goal progress. |
| **Live Run** | The core screen — live stats and a route map, with separate UI for acquiring-GPS, active, paused, and weak-signal states. Designed to be glanceable at arm's length, mid-run, in sunlight. |
| **Run Summary** | Shown right after finishing — totals, calories, route polyline, per-km splits, and Save / Discard. |
| **History** | Scrollable list of past runs → tap through to a detail view. |
| **Profile** | Weight, unit preference (km/mi), and log out. |

---

## Architecture

Feature-first, layered structure. Each feature owns its `data / domain / application / presentation` slices; cross-cutting concerns live in `core/`.

```
lib/
  core/
    database/    # drift setup + DAOs (runs, goals, settings) — local source of truth
    location/    # geolocator wrapper + foreground-service host for background tracking
    supabase/    # client + auth helpers
    utils/       # geo/Haversine, pace formatting, calorie estimator, km splits, units
    router/      # go_router config (offline-aware redirects)
  features/
    auth/        # email/password + Google/Apple, splash/login/signup
    run_tracking/ # live run notifier, GPS stream, map, summary, local + remote repos, sync
    history/     # list, run detail, route thumbnails
    goals/       # weekly goals, progress, editor, sync
    profile/     # profile + settings, sync
    home/        # dashboard
  shared/        # theme + shared widgets
```

**State management** uses [Riverpod](https://riverpod.dev/). The live-run state is a `Notifier` that accumulates the point stream and derives distance, elapsed time, and pace. **Routing** uses [go_router](https://pub.dev/packages/go_router) with offline-aware redirects.

### Backend

Postgres on [Supabase](https://supabase.com/) with **Row Level Security enabled on every table from day one** (`user_id = auth.uid()`) — not bolted on later. The schema (`profiles`, `runs`, `run_points`, `goals`) is version-controlled as a migration under [supabase/migrations/](supabase/migrations/) and mirrored locally in drift. High-volume `run_points` are indexed on `run_id`.

---

## Tech stack

| Concern | Choice |
| --- | --- |
| UI & app framework | Flutter / Dart (SDK `^3.10.8`) |
| State management | flutter_riverpod |
| Navigation | go_router |
| Local database | drift + drift_flutter |
| Location | geolocator + flutter_foreground_task (background-safe) |
| Maps | flutter_map (OpenStreetMap) + latlong2 |
| Backend | supabase_flutter (Postgres, Auth, RLS) |
| Auth providers | email/password, google_sign_in, sign_in_with_apple |
| Misc | intl, uuid, crypto, flutter_screenutil |

Targets Android, iOS, web, macOS, Linux, and Windows.

---

## Engineering highlights

- **De-risked the hard part first.** The background-location capability (foreground service + screen-off survival on real Android *and* iOS hardware) was spiked before building features around it — the riskiest unknown, validated up front.
- **Offline as a first-class state, not an error.** The app is fully usable with no backend; auth and sync are additive layers, and local persistence is authoritative during a run.
- **Security from day one.** RLS on every table, and a [test asserting passwords are never stored in plaintext](test/security/no_plaintext_password_test.dart). Secrets are injected at build time via `--dart-define-from-file` and never committed.
- **Tested.** ~33 test files spanning pure logic (Haversine/jitter, pace, calories, km splits, units), DAOs, sync services, Riverpod controllers, and widget tests for every major screen.

---

## Getting started

```sh
flutter pub get
flutter run            # offline mode — drops straight to Home, no backend needed
```

---

## Development

```sh
flutter analyze                                          # static analysis / lint
dart format .                                            # format
flutter test                                             # run the full test suite
dart run build_runner build --delete-conflicting-outputs # regenerate drift code
```
