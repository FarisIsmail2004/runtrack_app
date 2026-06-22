# RunTrack UX Refresh (Spec A) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Reskin the existing, working RunTrack app to the reimagined dark+orange UI — a consistent component system with real data-viz (goal ring, weekly bars, route sparklines) and Fraunces/Inter typography — plus a Light/Dark/System theme toggle, with no change to run/tracking behavior.

**Architecture:** Design-system-first. Build the token layer (two palettes via a `ThemeExtension`) and a theme-aware shared widget kit (`lib/shared/widgets/`, `lib/shared/charts/`) first; then restyle each `presentation/` screen to compose the kit. Charts are hand-rolled `CustomPainter`. Theme mode is persisted in the existing single-row drift Settings table and applied at `MaterialApp.router`.

**Tech Stack:** Flutter, Riverpod, drift, go_router, flutter_screenutil, google_fonts (new), flutter_map (existing).

**Spec:** `docs/superpowers/specs/2026-06-22-runtrack-ux-refresh-design.md`

## Global Constraints

- Dart SDK `^3.10.8`; match existing dot-shorthand style (`.fromSeed`, `.center`).
- `flutter analyze` clean and `dart format .` applied before every commit.
- **Theme-aware kit (mandatory):** every shared widget and restyled screen resolves color from `Theme.of(context).colorScheme` or `Theme.of(context).extension<AppColors>()!` — **no hardcoded hex outside the two `AppTheme` definitions.**
- **Near-zero behavior change:** only `lib/shared/theme/`, `lib/shared/widgets/`, `lib/shared/charts/`, `presentation/` change — plus the one allowed exception: a persisted `themeMode` (new `settings_dao` key + `themeModeProvider` + `MaterialApp.router` wiring). Do not touch `application/`, `data/`, `domain/`, run logic, routes, or sync.
- Tokens (dark / light): `accent` `#FF6A1A`/`#FF6A1A`; `base` `#0B0B0C`/`#F6F5F1`; `surface` `#161618`/`#FFFFFF`; `surfaceBorder` white@8%/black@8%; `success` `#2EBC51`/`#1FA847`; `warning` `#EFA31C`/`#B97700`; `destructive` `#FF453A`/`#E5392E`; `textPrimary` `#FFFFFF`/`#0B0B0C`; `textMuted` `#8A8A8E`/`#6B6B70`.
- Geometry: card radius 20, button radius 16, pill radius full, card padding 20, screen gutter 20.
- Fonts: Fraunces (display 600/700, tabular figures on for numerics) + Inter (body 400/500/600). Self-hosted in `assets/fonts/`.
- Existing widget tests must stay green; tests use an in-memory drift DB via `databaseProvider.overrideWithValue(...)`.
- Mockup reference crops live in `design/refresh/` (e.g. `c_dash.png`, `c_live_active.png`, `c_summary.png`, `c_history.png`, `c_profile.png`).

---

## Phase 0 — Foundation (theme + persistence)

### Task 1: Add `google_fonts` + bundle Fraunces/Inter

**Files:**
- Modify: `pubspec.yaml` (dependencies + `flutter:` fonts/assets)
- Create: `assets/fonts/Fraunces-VariableFont.ttf`, `assets/fonts/Inter-VariableFont.ttf` (downloaded)

**Interfaces:**
- Produces: bundled font families `Fraunces` and `Inter` usable via `GoogleFonts` or `TextStyle(fontFamily:)`.

- [ ] **Step 1: Add dependency**

In `pubspec.yaml` under `dependencies:` (after `flutter_screenutil`):

```yaml
  google_fonts: ^6.2.1
```

- [ ] **Step 2: Download the font files**

```bash
mkdir -p assets/fonts
curl -L -o assets/fonts/Fraunces.ttf "https://github.com/google/fonts/raw/main/ofl/fraunces/Fraunces%5BSOFT%2CWONK%2Copsz%2Cwght%5D.ttf"
curl -L -o assets/fonts/Inter.ttf "https://github.com/google/fonts/raw/main/ofl/inter/Inter%5Bopsz%2Cwght%5D.ttf"
ls -la assets/fonts/
```
Expected: two `.ttf` files, each > 200 KB.

- [ ] **Step 3: Declare fonts + assets in pubspec**

Under `flutter:` (replace the bare `uses-material-design: true` block):

```yaml
flutter:
  uses-material-design: true
  assets:
    - assets/fonts/
  fonts:
    - family: Fraunces
      fonts:
        - asset: assets/fonts/Fraunces.ttf
    - family: Inter
      fonts:
        - asset: assets/fonts/Inter.ttf
```

- [ ] **Step 4: Fetch packages**

Run: `flutter pub get`
Expected: resolves with `google_fonts` added, no errors.

- [ ] **Step 5: Commit**

```bash
git add pubspec.yaml pubspec.lock assets/fonts/
git commit -m "build(ux-refresh): add google_fonts + bundle Fraunces & Inter"
```

---

### Task 2: Color tokens + `AppColors` ThemeExtension

**Files:**
- Create: `lib/shared/theme/app_colors.dart`
- Test: `test/shared/theme/app_colors_test.dart`

**Interfaces:**
- Produces:
  - `class AppColors extends ThemeExtension<AppColors>` with fields `Color success, warning, destructive, surfaceBorder, textMuted;`
  - `static const AppColors dark` and `static const AppColors light`.
  - Extension getter `AppColors get appColors => extension<AppColors>()!` on `ThemeData`... (provided as a top-level helper `AppColors of(BuildContext)`).

- [ ] **Step 1: Write the failing test**

```dart
// test/shared/theme/app_colors_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runtrack_app/shared/theme/app_colors.dart';

void main() {
  test('dark and light tokens use the documented hex values', () {
    expect(AppColors.dark.success, const Color(0xFF2EBC51));
    expect(AppColors.light.success, const Color(0xFF1FA847));
    expect(AppColors.dark.destructive, const Color(0xFFFF453A));
    expect(AppColors.light.warning, const Color(0xFFB97700));
  });

  test('lerp returns an AppColors (theme animation safety)', () {
    final mid = AppColors.dark.lerp(AppColors.light, 0.5);
    expect(mid, isA<AppColors>());
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/shared/theme/app_colors_test.dart`
Expected: FAIL — `app_colors.dart` not found.

- [ ] **Step 3: Implement**

```dart
// lib/shared/theme/app_colors.dart
import 'package:flutter/material.dart';

/// Semantic colors that Material's [ColorScheme] has no slot for, carried per
/// theme so widgets resolve them with `Theme.of(context).extension<AppColors>()`.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.success,
    required this.warning,
    required this.destructive,
    required this.surfaceBorder,
    required this.textMuted,
  });

  final Color success;
  final Color warning;
  final Color destructive;
  final Color surfaceBorder;
  final Color textMuted;

  static const AppColors dark = AppColors(
    success: Color(0xFF2EBC51),
    warning: Color(0xFFEFA31C),
    destructive: Color(0xFFFF453A),
    surfaceBorder: Color(0x14FFFFFF), // white @ 8%
    textMuted: Color(0xFF8A8A8E),
  );

  static const AppColors light = AppColors(
    success: Color(0xFF1FA847),
    warning: Color(0xFFB97700),
    destructive: Color(0xFFE5392E),
    surfaceBorder: Color(0x140B0B0C), // black @ 8%
    textMuted: Color(0xFF6B6B70),
  );

  /// Convenience resolver used throughout the widget kit.
  static AppColors of(BuildContext context) =>
      Theme.of(context).extension<AppColors>()!;

  @override
  AppColors copyWith({
    Color? success,
    Color? warning,
    Color? destructive,
    Color? surfaceBorder,
    Color? textMuted,
  }) => AppColors(
    success: success ?? this.success,
    warning: warning ?? this.warning,
    destructive: destructive ?? this.destructive,
    surfaceBorder: surfaceBorder ?? this.surfaceBorder,
    textMuted: textMuted ?? this.textMuted,
  );

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      destructive: Color.lerp(destructive, other.destructive, t)!,
      surfaceBorder: Color.lerp(surfaceBorder, other.surfaceBorder, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/shared/theme/app_colors_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/shared/theme/app_colors.dart test/shared/theme/app_colors_test.dart
git commit -m "feat(theme): add AppColors ThemeExtension with dark+light tokens"
```

---

### Task 3: Rebuild `AppTheme` with dark + light + typography

**Files:**
- Modify: `lib/shared/theme/app_theme.dart` (full rewrite)
- Test: `test/shared/theme/app_theme_test.dart`

**Interfaces:**
- Consumes: `AppColors` (Task 2).
- Produces: `AppTheme.dark` and `AppTheme.light` (both `ThemeData`); a `TextTheme` where `displayLarge/Medium/Small` + `headlineMedium` use Fraunces and the rest use Inter; both themes register the matching `AppColors` extension.

- [ ] **Step 1: Write the failing test**

```dart
// test/shared/theme/app_theme_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runtrack_app/shared/theme/app_colors.dart';
import 'package:runtrack_app/shared/theme/app_theme.dart';

void main() {
  test('dark theme wires base/accent and the dark AppColors extension', () {
    final t = AppTheme.dark;
    expect(t.scaffoldBackgroundColor, const Color(0xFF0B0B0C));
    expect(t.colorScheme.primary, const Color(0xFFFF6A1A));
    expect(t.extension<AppColors>(), AppColors.dark);
    expect(t.brightness, Brightness.dark);
  });

  test('light theme wires base/accent and the light AppColors extension', () {
    final t = AppTheme.light;
    expect(t.scaffoldBackgroundColor, const Color(0xFFF6F5F1));
    expect(t.extension<AppColors>(), AppColors.light);
    expect(t.brightness, Brightness.light);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/shared/theme/app_theme_test.dart`
Expected: FAIL — `AppTheme.light` undefined / extension null.

- [ ] **Step 3: Implement**

```dart
// lib/shared/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static const _accent = Color(0xFFFF6A1A);

  static ThemeData get dark => _build(
        brightness: Brightness.dark,
        base: const Color(0xFF0B0B0C),
        surface: const Color(0xFF161618),
        onSurface: Colors.white,
        appColors: AppColors.dark,
      );

  static ThemeData get light => _build(
        brightness: Brightness.light,
        base: const Color(0xFFF6F5F1),
        surface: Colors.white,
        onSurface: const Color(0xFF0B0B0C),
        appColors: AppColors.light,
      );

  static ThemeData _build({
    required Brightness brightness,
    required Color base,
    required Color surface,
    required Color onSurface,
    required AppColors appColors,
  }) {
    final scheme = ColorScheme.fromSeed(
      seedColor: _accent,
      brightness: brightness,
    ).copyWith(
      primary: _accent,
      onPrimary: brightness == Brightness.dark ? Colors.black : Colors.white,
      surface: surface,
      onSurface: onSurface,
      error: appColors.destructive,
    );

    // Fraunces for display + headlines, Inter for everything else.
    final fraunces = GoogleFonts.frauncesTextTheme();
    final inter = GoogleFonts.interTextTheme();
    final text = inter.copyWith(
      displayLarge: fraunces.displayLarge?.copyWith(
        fontWeight: FontWeight.w700,
        color: onSurface,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
      displayMedium: fraunces.displayMedium?.copyWith(
        fontWeight: FontWeight.w700,
        color: onSurface,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
      displaySmall: fraunces.displaySmall?.copyWith(
        fontWeight: FontWeight.w600,
        color: onSurface,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
      headlineMedium: fraunces.headlineMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: onSurface,
      ),
    ).apply(bodyColor: onSurface, displayColor: onSurface);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: base,
      colorScheme: scheme,
      textTheme: text,
      extensions: [appColors],
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _accent,
          foregroundColor: scheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
          textStyle: GoogleFonts.fraunces(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
```

> Note: `GoogleFonts.fraunces/inter*` resolve to the bundled `assets/fonts/` files at runtime because the family names match; no network fetch needed.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/shared/theme/app_theme_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/shared/theme/app_theme.dart test/shared/theme/app_theme_test.dart
git commit -m "feat(theme): dark+light AppTheme with Fraunces/Inter type scale"
```

---

### Task 4: Persist `themeMode` in the Settings table (drift migration)

**Files:**
- Modify: `lib/core/database/app_database.dart` (Settings table column, `schemaVersion`, migration, `beforeOpen`)
- Modify: `lib/core/database/settings_dao.dart` (`setThemeMode`, `_defaultRow`)
- Regenerate: `lib/core/database/app_database.g.dart`, `settings_dao.g.dart` (codegen)
- Test: `test/core/database/settings_theme_mode_test.dart`

**Interfaces:**
- Produces: `Setting.themeMode` (`String`, default `'system'`); `SettingsDao.setThemeMode(String mode)`.

- [ ] **Step 1: Add the column + migration**

In `app_database.dart`, add to `class Settings`:

```dart
  TextColumn get themeMode => text().withDefault(const Constant('system'))();
```

Bump the version:

```dart
  @override
  int get schemaVersion => 5;
```

Add to `onUpgrade` (after the `from < 4` block):

```dart
      // v4 → v5 added Settings.theme_mode (light/dark/system).
      if (from < 5) {
        await m.addColumn(settings, settings.themeMode);
      }
```

- [ ] **Step 2: Add the DAO setter + default**

In `settings_dao.dart`, add a method beside `setUnit`:

```dart
  Future<void> setThemeMode(String mode) =>
      into(settings).insertOnConflictUpdate(
        SettingsCompanion(id: const Value(_rowId), themeMode: Value(mode)),
      );
```

Update `_defaultRow`:

```dart
  static const _defaultRow = Setting(
    id: _rowId,
    weightKg: 70.0,
    unit: 'km',
    onboardingSeen: false,
    themeMode: 'system',
  );
```

- [ ] **Step 3: Regenerate drift code**

Run: `dart run build_runner build --delete-conflicting-outputs`
Expected: `app_database.g.dart` / `settings_dao.g.dart` regenerate with `themeMode`; no errors.

- [ ] **Step 4: Write the test**

```dart
// test/core/database/settings_theme_mode_test.dart
import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runtrack_app/core/database/app_database.dart';

void main() {
  test('themeMode defaults to system and round-trips', () async {
    final db = AppDatabase(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
    );
    addTearDown(db.close);

    final initial = await db.settingsDao.getSettings();
    expect(initial.themeMode, 'system');

    await db.settingsDao.setThemeMode('light');
    final updated = await db.settingsDao.getSettings();
    expect(updated.themeMode, 'light');
  });
}
```

- [ ] **Step 5: Run test to verify it passes**

Run: `flutter test test/core/database/settings_theme_mode_test.dart`
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/core/database/ test/core/database/settings_theme_mode_test.dart
git commit -m "feat(db): persist themeMode in Settings (schema v5)"
```

---

### Task 5: `themeModeProvider` + wire `MaterialApp.router`

**Files:**
- Create: `lib/features/profile/application/theme_mode_providers.dart`
- Modify: `lib/main.dart:64-71` (MaterialApp.router theme wiring)
- Test: `test/features/profile/theme_mode_provider_test.dart`

**Interfaces:**
- Consumes: `settingsStreamProvider` (existing), `settingsDaoProvider` (existing).
- Produces:
  - `final themeModeProvider = Provider<ThemeMode>(...)` mapping the stored string → `ThemeMode`.
  - `ThemeMode themeModeFromString(String)` / `String themeModeToString(ThemeMode)` helpers.

- [ ] **Step 1: Write the failing test**

```dart
// test/features/profile/theme_mode_provider_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runtrack_app/features/profile/application/theme_mode_providers.dart';

void main() {
  test('string <-> ThemeMode mapping', () {
    expect(themeModeFromString('light'), ThemeMode.light);
    expect(themeModeFromString('dark'), ThemeMode.dark);
    expect(themeModeFromString('system'), ThemeMode.system);
    expect(themeModeFromString('garbage'), ThemeMode.system);
    expect(themeModeToString(ThemeMode.light), 'light');
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/profile/theme_mode_provider_test.dart`
Expected: FAIL — file not found.

- [ ] **Step 3: Implement the provider**

```dart
// lib/features/profile/application/theme_mode_providers.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:runtrack_app/features/profile/application/profile_providers.dart';

ThemeMode themeModeFromString(String s) => switch (s) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };

String themeModeToString(ThemeMode m) => switch (m) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };

/// Current theme mode, defaulting to system while settings load.
final themeModeProvider = Provider<ThemeMode>((ref) {
  final settings = ref.watch(settingsStreamProvider);
  return settings.maybeWhen(
    data: (s) => themeModeFromString(s.themeMode),
    orElse: () => ThemeMode.system,
  );
});
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/profile/theme_mode_provider_test.dart`
Expected: PASS.

- [ ] **Step 5: Wire into `main.dart`**

Add import:

```dart
import 'features/profile/application/theme_mode_providers.dart';
```

In `build`, before `return ScreenUtilInit`:

```dart
    final themeMode = ref.watch(themeModeProvider);
```

Replace the three theme lines in `MaterialApp.router`:

```dart
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: themeMode,
```

- [ ] **Step 6: Run the existing smoke test**

Run: `flutter test test/widget_test.dart`
Expected: PASS (app still boots; default mode = system).

- [ ] **Step 7: Commit**

```bash
git add lib/features/profile/application/theme_mode_providers.dart lib/main.dart test/features/profile/theme_mode_provider_test.dart
git commit -m "feat(theme): themeModeProvider wired into MaterialApp.router"
```

---

## Phase 1 — Shared widget kit

> Convention for every widget below: stateless, takes plain data + callbacks (no provider reads inside the kit), resolves color via `Theme.of(context).colorScheme` and `AppColors.of(context)`. Tests render the widget inside `MaterialApp(theme: AppTheme.dark, home: Scaffold(body: ...))` and assert structure/behavior (not goldens).

### Task 6: Buttons (`PrimaryButton` / `SecondaryButton` / `DestructiveButton`)

**Files:**
- Create: `lib/shared/widgets/app_buttons.dart`
- Test: `test/shared/widgets/app_buttons_test.dart`

**Interfaces:**
- Produces:
  - `PrimaryButton({required String label, IconData? icon, required VoidCallback? onPressed, bool glow = false})`
  - `SecondaryButton({required String label, required VoidCallback? onPressed})`
  - `DestructiveButton({required String label, required VoidCallback? onPressed})` (text-style, `AppColors.destructive`)

- [ ] **Step 1: Write the failing test**

```dart
// test/shared/widgets/app_buttons_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runtrack_app/shared/theme/app_theme.dart';
import 'package:runtrack_app/shared/widgets/app_buttons.dart';

void main() {
  testWidgets('PrimaryButton shows label, icon, and fires onPressed',
      (tester) async {
    var tapped = false;
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(
        body: PrimaryButton(
          label: 'START RUN',
          icon: Icons.play_arrow,
          onPressed: () => tapped = true,
        ),
      ),
    ));
    expect(find.text('START RUN'), findsOneWidget);
    expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    await tester.tap(find.byType(PrimaryButton));
    expect(tapped, isTrue);
  });

  testWidgets('DestructiveButton uses the destructive token', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(
        body: DestructiveButton(label: 'Discard', onPressed: () {}),
      ),
    ));
    final text = tester.widget<Text>(find.text('Discard'));
    expect(text.style?.color, const Color(0xFFFF453A)); // AppColors.dark.destructive
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/shared/widgets/app_buttons_test.dart`
Expected: FAIL — file not found.

- [ ] **Step 3: Implement**

```dart
// lib/shared/widgets/app_buttons.dart
import 'package:flutter/material.dart';
import 'package:runtrack_app/shared/theme/app_colors.dart';

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.glow = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool glow;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final button = SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[Icon(icon), const SizedBox(width: 10)],
            Text(label),
          ],
        ),
      ),
    );
    if (!glow) return button;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: cs.primary.withValues(alpha: 0.45),
            blurRadius: 28,
            spreadRadius: -4,
          ),
        ],
      ),
      child: button,
    );
  }
}

class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final border = AppColors.of(context).surfaceBorder;
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: cs.onSurface,
          backgroundColor: cs.surface,
          side: BorderSide(color: border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(label),
      ),
    );
  }
}

class DestructiveButton extends StatelessWidget {
  const DestructiveButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final destructive = AppColors.of(context).destructive;
    return TextButton(
      onPressed: onPressed,
      child: Text(
        label,
        style: TextStyle(color: destructive, fontWeight: FontWeight.w600),
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/shared/widgets/app_buttons_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/shared/widgets/app_buttons.dart test/shared/widgets/app_buttons_test.dart
git commit -m "feat(kit): primary/secondary/destructive buttons"
```

---

### Task 7: `SectionHeader` + `PageDots`

**Files:**
- Create: `lib/shared/widgets/section_header.dart`, `lib/shared/widgets/page_dots.dart`
- Test: `test/shared/widgets/section_header_test.dart`

> Note: an onboarding-specific `page_dots.dart` already exists under `features/onboarding/presentation/widgets/`. This shared one is the canonical version; Task 17 swaps onboarding to it and deletes the old file.

**Interfaces:**
- Produces:
  - `SectionHeader({required String title, String? trailing})` — uppercase Inter 600, tracked, `textMuted`.
  - `PageDots({required int count, required int index})` — row of dots, active one is an elongated accent pill.

- [ ] **Step 1: Write the failing test**

```dart
// test/shared/widgets/section_header_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runtrack_app/shared/theme/app_theme.dart';
import 'package:runtrack_app/shared/widgets/page_dots.dart';
import 'package:runtrack_app/shared/widgets/section_header.dart';

void main() {
  testWidgets('SectionHeader renders title + trailing', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.dark,
      home: const Scaffold(
        body: SectionHeader(title: 'THIS WEEK', trailing: 'Apr 28 – May 4'),
      ),
    ));
    expect(find.text('THIS WEEK'), findsOneWidget);
    expect(find.text('Apr 28 – May 4'), findsOneWidget);
  });

  testWidgets('PageDots renders one dot per page', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.dark,
      home: const Scaffold(body: PageDots(count: 4, index: 0)),
    ));
    expect(find.byType(AnimatedContainer), findsNWidgets(4));
  });
}
```

- [ ] **Step 2: Run to verify FAIL** — `flutter test test/shared/widgets/section_header_test.dart` → FAIL (files missing).

- [ ] **Step 3: Implement**

```dart
// lib/shared/widgets/section_header.dart
import 'package:flutter/material.dart';
import 'package:runtrack_app/shared/theme/app_colors.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.trailing});

  final String title;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final muted = AppColors.of(context).textMuted;
    final style = TextStyle(
      fontFamily: 'Inter',
      fontWeight: FontWeight.w600,
      fontSize: 13,
      letterSpacing: 1.0,
      color: muted,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title.toUpperCase(), style: style),
        if (trailing != null) Text(trailing!, style: style),
      ],
    );
  }
}
```

```dart
// lib/shared/widgets/page_dots.dart
import 'package:flutter/material.dart';
import 'package:runtrack_app/shared/theme/app_colors.dart';

class PageDots extends StatelessWidget {
  const PageDots({super.key, required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final inactive = AppColors.of(context).textMuted.withValues(alpha: 0.4);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          height: 6,
          width: active ? 20 : 6,
          decoration: BoxDecoration(
            color: active ? cs.primary : inactive,
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }
}
```

- [ ] **Step 4: Run to verify PASS** — `flutter test test/shared/widgets/section_header_test.dart` → PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/shared/widgets/section_header.dart lib/shared/widgets/page_dots.dart test/shared/widgets/section_header_test.dart
git commit -m "feat(kit): SectionHeader + PageDots"
```

---

### Task 8: `StatCell` / `StatGrid`

**Files:**
- Create: `lib/shared/widgets/stat_grid.dart`
- Test: `test/shared/widgets/stat_grid_test.dart`

**Interfaces:**
- Produces:
  - `class StatItem { final String value; final String? unit; final String label; final bool accent; }`
  - `StatRow({required List<StatItem> items})` — equal-width cells with thin dividers (live-run 3-up).
  - `StatColumn({required List<StatItem> items})` — vertically stacked cells, value + label side by side per row (dashboard "THIS WEEK" Distance/Runs/Time).
  - `StatGrid({required List<StatItem> items})` — 2×2 (summary).
  - Big number uses `Theme.textTheme.displaySmall`; label uses muted uppercase; `accent` cells color the number `cs.primary`.

- [ ] **Step 1: Write the failing test**

```dart
// test/shared/widgets/stat_grid_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runtrack_app/shared/theme/app_theme.dart';
import 'package:runtrack_app/shared/widgets/stat_grid.dart';

void main() {
  testWidgets('StatRow shows each value and label', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.dark,
      home: const Scaffold(
        body: StatRow(items: [
          StatItem(value: '4.21', label: 'DIST · KM'),
          StatItem(value: '5:48', label: 'PACE /KM', accent: true),
          StatItem(value: '5:42', label: 'AVG /KM'),
        ]),
      ),
    ));
    expect(find.text('4.21'), findsOneWidget);
    expect(find.text('PACE /KM'), findsOneWidget);
  });

  testWidgets('accent cell colors the number with primary', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.dark,
      home: const Scaffold(
        body: StatRow(items: [StatItem(value: '5:48', label: 'P', accent: true)]),
      ),
    ));
    final t = tester.widget<Text>(find.text('5:48'));
    expect(t.style?.color, AppTheme.dark.colorScheme.primary);
  });
}
```

- [ ] **Step 2: Run to verify FAIL.**

- [ ] **Step 3: Implement** (`StatItem`, a private `_Cell`, `StatRow` using `IntrinsicHeight`+`Row` with `VerticalDivider`s colored `AppColors.surfaceBorder`, `StatColumn` as a `Column` of `_Cell`s laid out value-then-label horizontally, `StatGrid` as two `StatRow`s). Number `Text` uses `Theme.of(context).textTheme.displaySmall!.copyWith(color: item.accent ? cs.primary : null)`; optional `unit` rendered as a smaller superscript-style `Text`; label uses the muted uppercase style from `SectionHeader`'s pattern.

- [ ] **Step 4: Run to verify PASS.**

- [ ] **Step 5: Commit** — `feat(kit): StatRow + StatGrid stat cards`.

---

### Task 9: `GoalRing` (CustomPainter)

**Files:**
- Create: `lib/shared/charts/goal_ring.dart`
- Test: `test/shared/charts/goal_ring_test.dart`

**Interfaces:**
- Produces: `GoalRing({required double progress /*0..1, clamped*/, required String centerLabel, String? subLabel, double size = 160})`. Exposes `static double clampProgress(double v)` for testing the clamp.

- [ ] **Step 1: Write the failing test**

```dart
// test/shared/charts/goal_ring_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runtrack_app/shared/charts/goal_ring.dart';
import 'package:runtrack_app/shared/theme/app_theme.dart';

void main() {
  test('progress clamps to 0..1', () {
    expect(GoalRing.clampProgress(-0.5), 0.0);
    expect(GoalRing.clampProgress(1.7), 1.0);
    expect(GoalRing.clampProgress(0.74), 0.74);
  });

  testWidgets('renders the center label', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.dark,
      home: const Scaffold(
        body: GoalRing(progress: 0.74, centerLabel: '74%', subLabel: 'of goal'),
      ),
    ));
    expect(find.text('74%'), findsOneWidget);
    expect(find.text('of goal'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run to verify FAIL.**

- [ ] **Step 3: Implement**

```dart
// lib/shared/charts/goal_ring.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:runtrack_app/shared/theme/app_colors.dart';

class GoalRing extends StatelessWidget {
  const GoalRing({
    super.key,
    required this.progress,
    required this.centerLabel,
    this.subLabel,
    this.size = 160,
  });

  final double progress;
  final String centerLabel;
  final String? subLabel;
  final double size;

  static double clampProgress(double v) => v.clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final track = AppColors.of(context).surfaceBorder;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RingPainter(
          progress: clampProgress(progress),
          color: cs.primary,
          track: track,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(centerLabel, style: Theme.of(context).textTheme.displaySmall),
              if (subLabel != null)
                Text(subLabel!,
                    style: TextStyle(color: AppColors.of(context).textMuted)),
            ],
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.color,
    required this.track,
  });

  final double progress;
  final Color color;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 12.0;
    final rect = Offset.zero & size;
    final center = rect.center;
    final radius = (size.shortestSide - stroke) / 2;
    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = track;
    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = color;
    canvas.drawCircle(center, radius, trackPaint);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.color != color || old.track != track;
}
```

- [ ] **Step 4: Run to verify PASS.**

- [ ] **Step 5: Commit** — `feat(charts): GoalRing progress arc`.

---

### Task 10: `WeeklyBarChart` (CustomPainter)

**Files:**
- Create: `lib/shared/charts/weekly_bar_chart.dart`
- Test: `test/shared/charts/weekly_bar_chart_test.dart`

**Interfaces:**
- Produces: `WeeklyBarChart({required List<double> values /*len 7, Mon..Sun*/, int? highlightIndex, double height = 120})`. Exposes `static int? resolveHighlight(List<double> v, int? explicit)` → explicit if given else index of max (null if all zero).

- [ ] **Step 1: Write the failing test**

```dart
// test/shared/charts/weekly_bar_chart_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:runtrack_app/shared/charts/weekly_bar_chart.dart';

void main() {
  test('highlight defaults to the max day', () {
    expect(WeeklyBarChart.resolveHighlight([1, 2, 0, 0, 0, 5, 1], null), 5);
  });
  test('explicit highlight wins', () {
    expect(WeeklyBarChart.resolveHighlight([1, 2, 3, 0, 0, 0, 0], 1), 1);
  });
  test('all-zero week has no highlight', () {
    expect(WeeklyBarChart.resolveHighlight([0, 0, 0, 0, 0, 0, 0], null), isNull);
  });
}
```

- [ ] **Step 2: Run to verify FAIL.**

- [ ] **Step 3: Implement** — `WeeklyBarChart` is a `Column` of a fixed-height `CustomPaint` (bars) above a `Row` of 7 day labels `M T W T F S S`. Painter scales bars to `max(values)`, draws rounded-top rects: highlighted bar = `cs.primary`, others = `AppColors.surfaceBorder` lightened. `resolveHighlight` as specified. Guard divide-by-zero when max is 0.

- [ ] **Step 4: Run to verify PASS.**

- [ ] **Step 5: Commit** — `feat(charts): WeeklyBarChart`.

---

### Task 11: `RouteSparkline` (CustomPainter — solid/dashed/live-dot)

**Files:**
- Create: `lib/shared/charts/route_sparkline.dart`
- Test: `test/shared/charts/route_sparkline_test.dart`

**Interfaces:**
- Produces:
  - `class SparkPoint { final double lat; final double lng; }`
  - `RouteSparkline({required List<SparkPoint> points, bool dashed = false, bool showGrid = true, bool startMarker = true, bool endMarker = true, bool livePulse = false, double strokeWidth = 3})`.
  - Static helper `static List<Offset> normalize(List<SparkPoint> pts, Size size)` (lat/lng → padded canvas offsets) — unit-tested.

- [ ] **Step 1: Write the failing test**

```dart
// test/shared/charts/route_sparkline_test.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runtrack_app/shared/charts/route_sparkline.dart';
import 'package:runtrack_app/shared/theme/app_theme.dart';

void main() {
  test('normalize maps bounds into the padded box and is finite', () {
    final pts = [
      const SparkPoint(lat: 0, lng: 0),
      const SparkPoint(lat: 1, lng: 2),
    ];
    final out = RouteSparkline.normalize(pts, const Size(100, 100));
    expect(out.length, 2);
    for (final o in out) {
      expect(o.dx.isFinite && o.dy.isFinite, isTrue);
      expect(o.dx >= 0 && o.dx <= 100, isTrue);
    }
  });

  testWidgets('renders dashed + live variants without throwing',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.dark,
      home: const Scaffold(
        body: SizedBox(
          width: 200, height: 200,
          child: RouteSparkline(
            points: [SparkPoint(lat: 0, lng: 0), SparkPoint(lat: 1, lng: 1)],
            dashed: true, livePulse: true,
          ),
        ),
      ),
    ));
    expect(tester.takeException(), isNull);
  });
}
```

- [ ] **Step 2: Run to verify FAIL.**

- [ ] **Step 3: Implement** — `normalize` computes lat/lng bounds, applies ~10% padding, flips Y (north up), handles single-point/zero-range by centering. Painter: optional faint grid (lines at `AppColors.surfaceBorder`), polyline in `cs.primary` (dashed → manual dash segments via `PathMetric`), green start marker = `AppColors.success`, end marker = filled `cs.primary` ring; `livePulse` overlays a translucent expanding circle at the last point (wrap in a `StatefulWidget` with a repeating `AnimationController` only when `livePulse`).

- [ ] **Step 4: Run to verify PASS.**

- [ ] **Step 5: Commit** — `feat(charts): RouteSparkline (solid/dashed/live pulse)`.

---

### Task 12: `TrendLine` (CustomPainter)

**Files:**
- Create: `lib/shared/charts/trend_line.dart`
- Test: `test/shared/charts/trend_line_test.dart`

**Interfaces:**
- Produces: `TrendLine({required List<double> values, bool fill = true, double height = 64})` — smooth orange line with a soft gradient fill below; used by History summary + live "PACE TREND" mini-card.

- [ ] **Step 1–5:** Test asserts it builds with 0, 1, and N values without throwing (`tester.takeException()` null) and that an empty list renders nothing. Implement painter scaling values to height, gradient fill from `cs.primary.withValues(alpha:.25)` → transparent. Commit `feat(charts): TrendLine`.

---

### Task 13: `GpsPill` (fixed-position, 3 states)

**Files:**
- Create: `lib/shared/widgets/gps_pill.dart`
- Test: `test/shared/widgets/gps_pill_test.dart`

**Interfaces:**
- Produces:
  - `enum GpsQuality { acquiring, strong, weak }`
  - `GpsPill({required GpsQuality quality})` — centered pill; STRONG → success dot+text "GPS · STRONG"; WEAK → warning "GPS · WEAK"; ACQUIRING → muted "ACQUIRING GPS…". Fixed height/padding so it never reflows.

- [ ] **Step 1: Write the failing test**

```dart
// test/shared/widgets/gps_pill_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runtrack_app/shared/theme/app_theme.dart';
import 'package:runtrack_app/shared/widgets/gps_pill.dart';

void main() {
  testWidgets('shows the right label per quality', (tester) async {
    for (final (q, label) in [
      (GpsQuality.strong, 'GPS · STRONG'),
      (GpsQuality.weak, 'GPS · WEAK'),
    ]) {
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(body: GpsPill(quality: q)),
      ));
      expect(find.text(label), findsOneWidget);
    }
  });
}
```

- [ ] **Step 2–5:** FAIL → implement (dot + label `Row` in a `Container` with `StadiumBorder`, color resolved from quality via `AppColors`) → PASS → commit `feat(kit): GpsPill fixed status pill`.

---

### Task 14: `RunControlBar` (unified lock · play/pause · stop)

**Files:**
- Create: `lib/shared/widgets/run_control_bar.dart`
- Test: `test/shared/widgets/run_control_bar_test.dart`

**Interfaces:**
- Produces: `RunControlBar({required bool paused, required bool locked, required VoidCallback onLockToggle, required VoidCallback onPlayPause, required VoidCallback onStop})`. Lock left, big play/pause center (accent), stop right (destructive). When `locked`, play/pause + stop are disabled and dimmed but the bar geometry is unchanged.

- [ ] **Step 1: Write the failing test** — pump with `paused:false, locked:false`; expect `Icons.pause` present, tap center fires `onPlayPause`, tap stop fires `onStop`; pump with `locked:true`; expect stop tap does **not** fire.

- [ ] **Step 2–5:** FAIL → implement → PASS → commit `feat(kit): unified RunControlBar`.

---

### Task 15: `PaceBars` (restyle of pace-by-km)

**Files:**
- Create: `lib/shared/widgets/pace_bars.dart`
- Test: `test/shared/widgets/pace_bars_test.dart`

**Interfaces:**
- Produces: `class PaceBarItem { final int km; final String paceLabel; final double fraction; }` and `PaceBars({required List<PaceBarItem> items})` — row per km: index, proportional orange bar (`fraction` 0..1), right-aligned pace label.

- [ ] **Step 1–5:** Test asserts a 3-item list renders all three pace labels and 3 bars. Implement with `LayoutBuilder`/`FractionallySizedBox`. Commit `feat(kit): PaceBars`.

---

### Task 16: `AppBottomNav`

**Files:**
- Create: `lib/shared/widgets/app_bottom_nav.dart`
- Test: `test/shared/widgets/app_bottom_nav_test.dart`

**Interfaces:**
- Produces: `enum AppTab { home, history, profile }` and `AppBottomNav({required AppTab current, required ValueChanged<AppTab> onSelect})` — 3 items (Home/History/Profile), active item icon+label in `cs.primary`, others muted.

- [ ] **Step 1: Write the failing test** — pump with `current: AppTab.home`; expect labels Home/History/Profile; tapping "Profile" calls `onSelect(AppTab.profile)`.

- [ ] **Step 2–5:** FAIL → implement → PASS → commit `feat(kit): AppBottomNav`.

---

**Checkpoint after Phase 1:** run the full suite — `flutter test` and `flutter analyze`. Both must be clean before screens.

---

## Phase 2 — Screen restyles

> Each screen task keeps its existing providers/routes and only rewrites the `build`/widget tree to compose the Phase 1 kit. For each: (a) update/extend the existing widget test so it still finds the screen's key text/among the new widgets, (b) verify the screen builds under **both** themes, (c) match the referenced mockup crop. No provider/data edits.

### Task 17: Onboarding

**Files:**
- Modify: `lib/features/onboarding/presentation/onboarding_screen.dart` and `widgets/onboarding_page.dart`
- Modify: swap to shared `PageDots`; delete `features/onboarding/presentation/widgets/page_dots.dart`
- Test: `test/features/onboarding/onboarding_screen_test.dart` (update)

**Interfaces:**
- Consumes: `PageDots` (Task 7), `PrimaryButton`/`SecondaryButton` (Task 6), `StatRow` (Task 8), `WeeklyBarChart` (Task 10), `RouteSparkline` (Task 11).

- [ ] **Step 1:** Update the existing test to expect the welcome wordmark + "Create Account"/"Log In" on slide 1 and the shared `PageDots` (`find.byType(PageDots)`).
- [ ] **Step 2:** Run → FAIL.
- [ ] **Step 3:** Rebuild the 4 slides per `design/refresh/c_ob_body_L.png`/`c_ob_body_R.png`: Welcome (logo, "Track every run. / Improve every day.", `PrimaryButton('Create Account')`, `SecondaryButton('Log In')`), Tour·Map (`RouteSparkline` + headline/body), Tour·Stats (a stat card via `StatRow`), Tour·Progress (`WeeklyBarChart`). "Skip" top-right; `PageDots` at bottom. Headlines use `textTheme.displaySmall` (Fraunces).
- [ ] **Step 4:** Run the onboarding test → PASS; `flutter analyze` clean.
- [ ] **Step 5:** Commit `feat(onboarding): restyle to refreshed design`.

---

### Task 18: Auth — unified Sign up / Log in

**Files:**
- Modify: `lib/features/auth/presentation/login_screen.dart`, `signup_screen.dart`, `widgets/auth_widgets.dart`
- Test: `test/features/auth/*` (update existing login/signup tests)

**Interfaces:**
- Consumes: existing `auth_notifier` actions (unchanged); `PrimaryButton`, `SecondaryButton`.

- [ ] **Step 1:** Update tests: a segmented control toggles between Log in / Sign up on one screen; "Continue with Apple" appears first; password field shows a strength indicator on input. Keep existing auth-action assertions (calls into `authNotifier`).
- [ ] **Step 2:** Run → FAIL.
- [ ] **Step 3:** Implement a `SegmentedButton`/custom toggle at top selecting mode; below it the shared email/password fields (`auth_widgets`) restyled to surface cards with 54px min height; Apple button first; a lightweight password-strength meter (length/character-class heuristic — display only, no policy change). Routes unchanged; both `/login` and `/signup` render this unified screen with the toggle preselected to match the route.
- [ ] **Step 4:** Run auth tests → PASS.
- [ ] **Step 5:** Commit `feat(auth): unified sign-up/log-in screen`.

---

### Task 19: Home / Dashboard

**Files:**
- Modify: `lib/features/home/presentation/home_screen.dart`
- Test: `test/features/home/home_screen_test.dart` (update)

**Interfaces:**
- Consumes: existing providers (`historyProvider` last-run, `weeklyGoalCard` data, profile name); `PrimaryButton(glow:true)`, `StatRow`/`StatGrid`, `GoalRing`, `WeeklyBarChart`, `RouteSparkline`, `AppBottomNav`, `SectionHeader`.

- [ ] **Step 1:** Update test to expect: greeting text, a glowing START RUN (`find.byType(PrimaryButton)`), `find.byType(GoalRing)`, `find.byType(WeeklyBarChart)`, the last-run card. Keep the in-memory DB override pattern from the existing test.
- [ ] **Step 2:** Run → FAIL.
- [ ] **Step 3:** Rebuild per `design/refresh/c_dash.png`: header "Ready to run, {name}?" (Fraunces `displaySmall`) + circular avatar button; `PrimaryButton(label:'START RUN', icon: play, glow:true, onPressed → context.go(runRoute))`; "THIS WEEK" `SectionHeader` + card composing `StatColumn` (Distance/Runs/Time) + `GoalRing(74%)` + `WeeklyBarChart`; "Last run" card with `RouteSparkline` thumbnail + stats; `AppBottomNav(current: home)`. All values come from the existing providers — no new data.
- [ ] **Step 4:** Run home test → PASS.
- [ ] **Step 5:** Commit `feat(home): restyle dashboard with data-viz`.

---

### Task 20: Live Run — 4 states (the core screen)

**Files:**
- Modify: `lib/features/run_tracking/presentation/live_run_screen.dart`
- Modify/replace usages: `widgets/gps_status.dart` → `GpsPill`; `widgets/run_controls.dart` → `RunControlBar`; restyle `widgets/run_map.dart`, `widgets/stat_block.dart`, `widgets/stop_confirm_sheet.dart`, `widgets/acquiring_gps_view.dart`
- Test: `test/features/run_tracking/*` (update affected)

**Interfaces:**
- Consumes: existing `runSessionProvider` (phase/elapsed/distance/pace/points) — unchanged; `GpsPill`, `StatRow`, `RunControlBar`, `RouteSparkline`, `TrendLine`.

- [ ] **Step 1:** Update tests that referenced the old `gps_status`/`run_controls` to find `GpsPill`/`RunControlBar`. Add assertions: Active → white timer + `GpsQuality.strong`; Paused → "PAUSED" affordance + dimmed timer; layout widget tree identical across active/paused (same widget types present).
- [ ] **Step 2:** Run → FAIL.
- [ ] **Step 3:** Compose the single layout (top→bottom): `GpsPill`, big timer (`displayLarge`, white when running / muted when paused), `StatRow` (pace accent), map area = `run_map` (existing flutter_map) with a `RouteSparkline`/`TrendLine` "PACE TREND" mini-card overlay, `RunControlBar`. **Weak** = `GpsPill(weak)` + an inline warning banner (warning-bordered card) above the timer, route → `RouteSparkline(dashed:true)`; **no layout jump**. **Paused** = dim timer + desaturated route + grey position dot (pass flags into `RouteSparkline`). **Stop** = restyle `stop_confirm_sheet` as the bottom sheet with red stop icon, recap `StatRow`, `PrimaryButton('Finish & Save')` + `SecondaryButton('Keep running')`. Preserve all existing callbacks (start/pause/resume/stop, lock).
- [ ] **Step 4:** Run run_tracking tests → PASS.
- [ ] **Step 5:** Commit `feat(live-run): unified 4-state layout with GpsPill + control bar`.

---

### Task 21: Run Summary

**Files:**
- Modify: `lib/features/run_tracking/presentation/widgets/run_summary_view.dart`, `run_summary_screen.dart`; restyle `widgets/pace_by_km_list.dart` → use `PaceBars`
- Test: `test/features/run_tracking/run_summary_*` (update)

**Interfaces:**
- Consumes: existing summary data; `RouteSparkline`, `StatGrid`, `PaceBars`, `PrimaryButton`, `DestructiveButton`.

- [ ] **Step 1–5:** Update test to find `StatGrid`, `PaceBars`, "Save Run", "Discard". FAIL → rebuild per `c_summary.png` (app bar back/title/delete, `RouteSparkline` header, 2×2 `StatGrid` Distance/Duration/Avg Pace/Calories, `PaceBars`, `PrimaryButton('Save Run')`, `DestructiveButton('Discard')`) → PASS → commit `feat(summary): restyle run summary`.

---

### Task 22: History

**Files:**
- Modify: `lib/features/history/presentation/history_screen.dart`, `widgets/run_list_tile.dart`, `widgets/route_thumbnail.dart` → use `RouteSparkline`
- Test: `test/features/history/history_screen_test.dart` (update)

**Interfaces:**
- Consumes: existing `historyProvider`; `TrendLine`, `RouteSparkline`, `SectionHeader`, `AppBottomNav`.

- [ ] **Step 1–5:** Update test for the summary card ("this year" total + `TrendLine`), month `SectionHeader`s, tiles with `RouteSparkline` thumbnails + chevrons, `AppBottomNav(current: history)`. FAIL → implement per `c_history.png` → PASS → commit `feat(history): restyle list + year trend card`.

---

### Task 23: Run Detail

**Files:**
- Modify: `lib/features/history/presentation/run_detail_screen.dart`
- Test: `test/features/history/run_detail_*` (update if present)

**Interfaces:**
- Consumes: `run_summary_view` composition (Task 21) reused read-only.

- [ ] **Step 1–5:** Update/confirm test finds `StatGrid` + `PaceBars`. FAIL → reuse the Task 21 summary composition without Save/Discard (read-only) → PASS → commit `feat(history): restyle run detail to match summary`.

---

### Task 24: Profile + Appearance (Light/Dark/System) selector

**Files:**
- Modify: `lib/features/profile/presentation/profile_screen.dart`
- Create: `lib/features/profile/presentation/widgets/appearance_sheet.dart`
- Test: `test/features/profile/profile_screen_test.dart` (update), `test/features/profile/appearance_sheet_test.dart` (new)

**Interfaces:**
- Consumes: existing `settingsStreamProvider`, `weightKgProvider`, `unitProvider`, `authStateProvider`; new `themeModeProvider` + `settingsDaoProvider.setThemeMode` (Tasks 4–5); `StatRow`/`StatGrid`, `AppBottomNav`.
- Produces: `showAppearanceSheet(BuildContext, {required ThemeMode current, required ValueChanged<ThemeMode> onSelect})`.

- [ ] **Step 1: Write the failing test**

```dart
// test/features/profile/appearance_sheet_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runtrack_app/features/profile/presentation/widgets/appearance_sheet.dart';
import 'package:runtrack_app/shared/theme/app_theme.dart';

void main() {
  testWidgets('selecting Light fires onSelect(ThemeMode.light)', (tester) async {
    ThemeMode? picked;
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(
        body: Builder(builder: (context) {
          return ElevatedButton(
            onPressed: () => showAppearanceSheet(
              context,
              current: ThemeMode.system,
              onSelect: (m) => picked = m,
            ),
            child: const Text('open'),
          );
        }),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Light'));
    await tester.pumpAndSettle();
    expect(picked, ThemeMode.light);
  });
}
```

- [ ] **Step 2:** Run → FAIL (file missing).
- [ ] **Step 3:** Implement `appearance_sheet.dart` — a `showModalBottomSheet` with three `RadioListTile`/tappable rows: System / Light / Dark, current one checked, each calling `onSelect` then `Navigator.pop`. Then in `profile_screen.dart` add the **Appearance** settings row (label + current value text from `themeModeProvider` + chevron) between Weekly goal and a new **Notifications →** row; tapping Appearance calls `showAppearanceSheet(..., onSelect: (m) => ref.read(settingsDaoProvider).setThemeMode(themeModeToString(m)))`. Restyle the whole screen per `c_profile.png` (Edit action, orange avatar with initials, name+email, `StatGrid` Runs/Total/Avg, settings card, `DestructiveButton`-style Log Out, `AppBottomNav(current: profile)`).
- [ ] **Step 4:** Run profile + appearance tests → PASS. Manually/with a test verify selecting Light updates `themeModeProvider`.
- [ ] **Step 5:** Commit `feat(profile): restyle + Appearance (light/dark/system) selector`.

---

### Task 25: Notifications placeholder screen + route

**Files:**
- Create: `lib/features/profile/presentation/notifications_screen.dart`
- Modify: `lib/core/router/app_router.dart` (add `/profile/notifications` route)
- Test: `test/features/profile/notifications_placeholder_test.dart`

**Interfaces:**
- Consumes: router; the Profile **Notifications →** row (Task 24) navigates here.
- Produces: a placeholder screen ("Smart notifications coming soon") styled with the kit — Spec B replaces its body.

- [ ] **Step 1:** Test: pushing the route shows the placeholder title.
- [ ] **Step 2:** Run → FAIL.
- [ ] **Step 3:** Add the route + a simple themed `Scaffold` with an app bar "Notifications" and centered copy. Wire the Profile row's `onTap` to `context.push('/profile/notifications')`.
- [ ] **Step 4:** Run → PASS.
- [ ] **Step 5:** Commit `feat(profile): notifications settings placeholder (Spec B stub)`.

---

## Final verification

- [ ] **Full suite:** `flutter test` — all green (existing + new).
- [ ] **Analyze:** `flutter analyze` — no issues.
- [ ] **Format:** `dart format .` — no diff.
- [ ] **Manual both-theme pass:** run the app, toggle Profile → Appearance through System/Light/Dark, confirm every screen (onboarding, auth, home, live-run states, summary, history, detail, profile) renders correctly and no hardcoded-dark color leaks into light mode.
- [ ] **Behavior intact:** start → pause → resume → finish → save a run; confirm history/sync unaffected.
- [ ] Final commit / ready to open PR for the `ux-refresh` branch.

---

## Self-review notes (coverage check)

- Spec Section 1 (tokens) → Tasks 2–3. Typography → Task 3. ✔
- Spec Section 2 (widget kit, 11 components) → Tasks 6–16. ✔
- Spec Section 3 (9 screens) → Tasks 17–25 (Detail reuses Summary; Notifications placeholder included). ✔
- Spec Section 4: google_fonts only → Task 1; theme-aware mandate → enforced per widget + final manual pass; themeMode persistence → Tasks 4–5; testing (painter logic, themeMode round-trip, both-theme smoke) → Tasks 4, 9, 10, 11 + final pass; YAGNI guard (no extra screens beyond placeholder + appearance sheet) → respected. ✔
- Light/Dark/System (added to spec) → Tasks 2–5, 24. ✔
