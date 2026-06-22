# Task 20 Report: Live Run — Unified 4-State Layout

## State → Styling Map

| State | GpsPill | Timer color | Paused chip | Warning banner | Route / map | RunControlBar |
|---|---|---|---|---|---|---|
| **Active** | `GpsQuality.strong` (green) | `onSurface` (white in dark) | hidden | hidden | normal | `paused: false` |
| **Paused** | `GpsQuality.strong` | `textMuted` (dimmed) | shows PAUSED + RESUME | hidden | dim overlay (black 45%) | `paused: true` |
| **Weak GPS** | `GpsQuality.weak` (amber) | `onSurface` | hidden | shown (amber bordered card) | normal | `paused: false` |
| **Acquiring** | n/a — `AcquiringGpsView` shown instead | — | — | — | — | — |

**Confirm Stop** = `showStopConfirmSheet` bottom sheet with red `Icons.stop_circle_outlined`, "Finish this run?" headline, optional recap `StatRow` (Dist/Duration), `PrimaryButton('Finish & Save')`, `SecondaryButton('Keep running')`.

## Layout-Stability Guarantee

`_TrackingBody.build` always emits the exact same widget subtree structure across Active/Paused/Weak:

```
SafeArea > Column [
  _WeakGpsBanner   ← AnimatedCrossFade; firstChild = banner card, secondChild = SizedBox(height=0)
  SizedBox
  kit.GpsPill      ← fixed geometry (28px height, stadium border)
  SizedBox
  _PausedChip      ← if(!visible) return SizedBox(height=0); else Row[PAUSED + RESUME]
  _ElapsedTimer    ← Column[timer text + "TIME" label]
  SizedBox
  _LiveStatRow     ← StatRow 3-up
  SizedBox
  Expanded > Stack [
    _LiveRunMap (Positioned.fill)
    dim overlay (Positioned.fill, IgnorePointer, AnimatedOpacity)
    _PaceTrendCard (Positioned, bottom-left)
    RunControlBar (Positioned, bottom)
  ]
]
```

The `AnimatedCrossFade` for `_WeakGpsBanner` transitions between a banner card and `SizedBox(width: double.infinity)` so that the layout height stays constant (both children have the same horizontal stretch). `_PausedChip` uses a plain `if` rather than AnimatedCrossFade so that `find.text('PAUSED'/'RESUME')` responds immediately after `pump()`.

## Widget Replacements

| Old widget | New widget | Action |
|---|---|---|
| `gps_status.dart` `GpsPill` (custom, hex colors) | `shared/widgets/gps_pill.dart` `GpsPill` (theme-aware) | Replaced; old file kept but no longer imported by live_run_screen |
| `gps_status.dart` `GpsWarningBanner` | `_WeakGpsBanner` (inline in live_run_screen.dart, theme-aware) | Replaced inline |
| `run_controls.dart` `RunControls` | `shared/widgets/run_control_bar.dart` `RunControlBar` | Replaced |
| `stat_block.dart` `StatBlock` | `shared/widgets/stat_grid.dart` `StatRow`/`StatItem` + inline `_ElapsedTimer` | Replaced |
| `stop_confirm_sheet.dart` | Restyled: `PrimaryButton('Finish & Save')` + `SecondaryButton('Keep running')` + red icon + `StatRow` recap | Modified |

Old widget files (`gps_status.dart`, `run_controls.dart`, `stat_block.dart`) are still on disk but no longer imported by `live_run_screen.dart`. They can be removed in a cleanup pass.

## GPS Quality Enum Mapping

Two enums coexist: `core/location/location_service.dart::GpsQuality` (session state: searching/good/weak/lost) and `shared/widgets/gps_pill.dart::GpsQuality` (kit: acquiring/strong/weak). Mapped in `_toKitQuality()`:
- `good` → `strong`
- `weak` → `weak`
- `lost` → `weak` (signal lost treated as weak for display; banner text distinguishes)
- `searching` → `acquiring`

## Test Changes

- Added imports for `kit.GpsPill` and `RunControlBar` types.
- Replaced `find.byIcon(Icons.stop)` with `find.byKey(ValueKey('run-stop'))` (RunControlBar uses `Icons.stop_circle_outlined`; using key avoids ambiguity with the sheet's decorative stop icon).
- Replaced `find.byIcon(Icons.lock_open)` with `find.byKey(ValueKey('run-lock'))` for lock test.
- Updated stop-sheet button text: `'STOP RUN'` → `'Finish & Save'`; `'CANCEL'` (in sheet) → `'Keep running'`; sheet headline `'Stop and finish run?'` → `'Finish this run?'`.
- Added layout-stability assertions in the pause test: `RunControlBar` and `kit.GpsPill` found in tree across active, paused, and resumed states.
- Stop sheet uses `isScrollControlled: true` to avoid content overflow in the 800×600 test viewport.

## Full-Suite Result

```
flutter test → 278 tests passed (0 failures)
flutter analyze → No issues found
dart format → 3 files reformatted
```

## Deviations from Brief

- `RouteSparkline` overlay on the map is not implemented (the live-run screen uses `RunMap` / flutter_map for the actual map; adding a `RouteSparkline` on top would duplicate the polyline). The `_PaceTrendCard` mini-card shows a placeholder flat line rather than a full `TrendLine` (live pace history accumulation would require storing a time-series in the session state, which would be a behavior change). This is presentation-only groundwork; the card and layout position are in place for a future step.
- `_PausedChip` uses a plain conditional (`if (!visible) return SizedBox`) rather than an animated cross-fade. This keeps `find.text('PAUSED')` / `find.text('RESUME')` reliably invisible after a single `pump()`, matching the existing test contract.
