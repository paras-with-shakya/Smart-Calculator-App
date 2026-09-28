# Changelog

This is the chronological development log. It is **append-only**, with the newest date first, and records **only real changes and checks that were actually run**. Planned work belongs in [ROADMAP.md](ROADMAP.md), not here.

Entry format:

```md
## YYYY-MM-DD

### Added
### Changed
### Fixed
### Decisions
### Tests
### Notes
```

When one date has more than one entry, each heading names its session.

---

## 2026-09-28: Phase 3 (Basic calculator)

### Added

- **Engine** (`packages/calc_engine`, commit `4fec0b6`): exact evaluation with `rational` (DEC-038). It has a lexer, a recursive-descent parser, a syntax tree and an evaluator, with smart percent (DEC-036), implied multiplication, typed errors, overflow at 10¹⁰⁰, and nesting and token limits (DEC-039). Results use 12 significant digits and switch to scientific notation from 10¹² and below 10⁻⁶.
- **Calculator logic** (commit `57a1e73`):
  - `ExpressionBuffer`: units with a cursor and the input rules (DEC-040)
  - `CalculatorNotifier`: live value, `=`, continuing from the exact result, errors, cursor moves, paste
  - memory (MC MR M+ M− MS), saved exactly under `calculator.memory` (DEC-041)
  - `LocalizedNumberFormat` and `numberFormatProvider`: numbers in the device region's format (DEC-037)
- **Calculator screen** (commit `85c6c84`):
  - `CalculatorView` with portrait and landscape layouts (DEC-042) and hardware keyboard support
  - `CalculatorDisplay`, `CalculatorKeypad`, `CalculatorMemoryKeys` and `CalculatorDisplayFormatter` (DEC-043)
  - haptic ticks on key presses; hold ⌫ to clear everything
- **Components:** `DisplayText`, and `CalculatorButtonKind.memory` (DEC-043). The gallery has a new "Display text" section and a memory row in the keys section.
- **Strings:** 37 new, for key labels, what screen readers say, and the error messages (55 in all).

### Changed

- **Basic mode** shows the calculator instead of the empty state.
- **Shell:** an expanded window shorter than 480 dp (a phone in landscape) shows no history panel; the history action opens the page instead (DEC-042).
- **App dependencies:** `calc_engine` (path). **Engine dependencies:** `rational` ^2.2.3; dev `test` ^1.31.1.
- **Design-review screenshots:** 17 more (15 calculator screens, and the gallery's display section in light and dark), 50 in all.

### Fixed

Found during this phase, before the commits:

- **Screenshots:** a long expression broke inside a number. It now wraps only after an operator.
- **Screenshots:** the tablet-landscape keypad floated in the middle. It is now aligned to the bottom.
- **On the user's phone, in landscape:** keys were 47.6 dp tall under the 34 dp status bar. Tighter vertical padding in short windows makes them 49 dp. A regression test covers it.
- **On the user's phone:** the memory badge's screen-reader label was attached to the whole screen. It is now its own node.

### Decisions

- DEC-036 (smart percent) and DEC-037 (region number format) are implemented.
- New: DEC-038 to DEC-043. DEC-008, DEC-010 and DEC-022 are updated.

### Tests

- **Engine** (`dart test` in `packages/calc_engine`): **260 passed.** That is 224 table-driven cases, `CalcValue` tests, and a 20,000-input fuzz test. Mutation checks: plain percent caused 13 failures, and truncating instead of rounding caused 10. Both were restored.
- **App** (`flutter test`): **404 passed**, 1 skipped (the design-review generator). There are 292 new tests:
  - expression buffer 138, notifier and memory 59, number format 33
  - `DisplayText` 12, display formatter 18, screen 24
  - `CalculatorButton` +2, app +1, shell +1, gallery accessibility +4
- **Mutation checks** on the new tests, all caught and then restored: leading-zero rule, closing-bracket rule, bracketed variables, incomplete-error mapping, rejected-key handling, Indian grouping. The landscape regression test fails with the old padding.
- **`flutter analyze`:** no issues. **Formatting:** 104 files, 0 changed.
- **Design review:** 50 screenshots generated and reviewed.
- **Builds:** `flutter build apk --debug` built (85.9 s). `flutter build apk --release` built, 46.6 MB. `aapt`: package `com.parasshakya.smartcalculator`, label "Smart Calculator", **no INTERNET permission**.
- **On the user's phone** (`23124RN87I`, Android 15, 360×800 dp, region en-IN; release APK):
  - every key is exposed with its name
  - `1234567×8+90` shows `12,34,567×8+90`, preview `98,76,626`, then the result `98,76,626`
  - `50+10%` previews 55
  - MS, then `2×` MR shows `2×98,76,626` (preview `1,97,53,252`)
  - `5÷0=` shows "Can't divide by zero"
  - the memory survives a force-stop and relaunch
  - landscape: the keypad is beside the display
  - holding ⌫ clears the display
  - the rotation setting, changed for the landscape test, was restored (auto-rotate off, rotation 0). No other setting was changed.

### Notes

- **Not built in Phase 3:** the engine's function registry (there are no functions until Phase 5), and the roadmap's "more" menu (DEC-041).

---
## 2026-09-28: Test on the user's phone

### Added

- `AppChoiceGroup` / `AppChoice` (`lib/core/widgets/app_choice_group.dart`). It shows a segmented button when every label fits on one line, and a radio list otherwise (DEC-035).
- Tests:
  - `test/core/widgets/app_choice_group_test.dart` (4 tests, measured with the real font)
  - a settings regression test at 200% text on a 360 dp phone

### Changed

- **Settings page:** the theme control is an `AppChoiceGroup`, outside the list tile, so it gets the full content width.
- **Gallery:** the inputs section is renamed "Inputs and choices" and shows `AppChoiceGroup`.
- **Screenshot harness:** it paints sections on a `Material` instead of a `ColoredBox`.

### Fixed

- **Settings theme control at 200% system font on a 360 dp phone:** "System" was broken as "Syste/m". It was found on the user's phone and fixed in `950493b`.

### Tests

- **On the user's phone** (`23124RN87I`, Android 15, 360×800 dp; release APK installed with `adb`):
  - cold start 1126 ms (then 621–1080 ms)
  - launch screen, mode sheet, mode switch, history page and system back all correct
  - Dark survives a force-stop and relaunch
  - 200% font: the mode sheet uses 2 columns; the theme control bug above was found, then fixed and re-tested
  - landscape: rail layout, with scrolling
  - accessibility labels present in `uiautomator dump`
  - no errors in `logcat`
  - phone settings restored afterwards
- **`flutter analyze`:** no issues.
- **Formatting:** 72 files, 0 changed.
- **`flutter test`:** 112 passed.
- **Design-review screenshots:** 33 regenerated.
- **Mutation check:** without the `Material` wrapper, the coloured-background test fails.
- **`flutter build apk --release`:** built, 46.1 MB.

### Decisions

- DEC-035 was adopted.
- P-4 is resolved: the user's phone is used for device tests when it is connected and the user asks.

### Notes

- Phase 2 still awaits the user's design sign-off (P-11).
- Nothing was pushed (the user pushes to GitHub themselves).

---

## 2026-09-28: Phase 2 (Design system)

### Added

- **Design tokens** (`lib/app/theme/`):
  - `AppColors`: 27 roles; light "porcelain", dark "graphite", and high-contrast light and dark palettes
  - `AppTypography`: 11 styles, with tabular figures on the number styles
  - `AppRadius`: superellipse shapes
  - `AppMotion`: reduced-motion aware
  - `AppSpacing`: extended to xs–xxl
- **Themes:** `AppTheme` builds four themes and the Material component themes. `MaterialApp` gets `highContrastTheme`, `highContrastDarkTheme` and a theme-change animation.
- **Manrope font** (400/500/600/700, `googlefonts/manrope@6f81ebe`) in `assets/fonts/`, with its OFL, registered through `lib/app/font_licenses.dart`.
- **Reusable components** (`lib/core/widgets/`): `AppButton`, `AppIconButton`, `CalculatorButton`, `AppCard`, `AppBottomSheet`/`showAppBottomSheet`, `AppDialog`/`showConfirmationDialog`, `AppTextField`, `EmptyState`, `ErrorState`, `LoadingState`, `SectionHeader`, `AppHeader`.
- **Component gallery:** `lib/main_gallery.dart` and `lib/gallery/`.
- **Tests:**
  - palette contrast (WCAG)
  - theme, font and motion tests
  - component tests
  - Flutter accessibility guidelines over every gallery section in four themes
  - the design-review screenshot generator (tag `design-review`, skipped by default through `dart_test.yaml`)
  - helpers: `themed.dart`, `real_fonts.dart`

### Changed

- **Shell:**
  - The header uses `AppHeader` and `AppIconButton`.
  - The mode pill is an `AppButton`.
  - The mode sheet is a grid of `AppCard` tiles, with the current mode selected.
- **Placeholders:** the mode, history page and history panel placeholders use `EmptyState`.
- **Settings page:** uses `AppHeader` and `SectionHeader`.
- **Startup:** `main.dart` registers the font licences.
- **`pubspec.yaml`:** the fonts and the licence asset.
- **`CLAUDE.md`:** rule 12 (reusable widgets only) and rule 13 (Hinglish replies), plus the design-review commands.

### Removed

- `lib/core/widgets/placeholder_view.dart` (replaced by `EmptyState`).

### Fixed

Found in Claude's review of the screenshots, and fixed before the final set:

- **Mode sheet:**
  - Tiles were invisible on the white sheet. Sheets now use the page background.
  - "Programmer" broke mid-word. There is less tile padding, 2 columns from 115% text, and a one-line label.
- **Keys:** operator and `=` symbols looked faint. There is a new `keySymbol` style.
- **Text fields:** the floating label sat on the field's edge. Filled fields now use `UnderlineInputBorder` (DEC-031).
- **Buttons:** they were cramped at 200% text. Vertical padding added.

### Decisions

- The user approved Phase 2 and required reusable widgets (DEC-034).
- DEC-028 to DEC-033 were adopted:
  - DEC-028: the font; resolves P-8
  - DEC-029: the tokens
  - DEC-030: the consolidated components
  - DEC-031: the filled fields
  - DEC-032: the gallery entry point
  - DEC-033: the screenshot review
- New pending decision: P-11, the user's design sign-off.

### Tests

- **Font check:** `tnum` is present in all four Manrope weights.
- **Mutation check:** a low-contrast `textMuted` made the gallery contrast test fail. Restored.
- **`flutter analyze`:** no issues.
- **Formatting:** 70 files, 0 changed.
- **`flutter test`:** 107 passed, and 1 skipped (the screenshot generator).
- **Screenshot generator:** 33 passed; screenshots written to `build/design_review/`.
- **`flutter build apk --debug`:** built. **`--release`:** built, 45.7 MB, no INTERNET permission, fonts bundled.

### Notes

- **Phase 2 awaits the user's design sign-off.** Phase 3 has not started.
- **Commits:** `0fc15ef` (code), then the docs update.

---

## 2026-09-28: Phase 1 (Foundation)

### Added

- **Git repository** in `smart_calculator/` on `main`, with a `.gitattributes` file. Commits:
  - `8ca813c` baseline scaffold
  - `813533e` project-memory docs
  - `06c0a93` app identity
  - `7926920` Phase 1 foundation
  - then the docs update
- **Pub workspace**, with the empty pure-Dart package `packages/calc_engine` (`pubspec.yaml`, `lib/calc_engine.dart`, `README.md`).
- **Dependencies:**
  - app: `flutter_riverpod` 3.4.3, `shared_preferences` 2.5.5, `sqflite` 2.4.4, `path` 1.9.1, `intl` 0.20.3 (SDK-pinned), `flutter_localizations`
  - dev: `sqflite_common_ffi` 2.4.3, `shared_preferences_platform_interface` 2.4.2
- **Startup:** `main` preloads the preferences, then `AppRoot` builds a `ProviderScope` (with overrides, automatic retry off) around `SmartCalculatorApp`.
- **Typed navigation:** the sealed `AppRoute` (`/history`, `/settings`) and `context.pushRoute`.
- **Adaptive shell** with placeholder screens:
  - compact windows: the mode pill and mode sheet
  - medium windows: a navigation rail
  - expanded windows: the rail plus a history panel
  - no bottom navigation
- **Mode registry:** the `CalculatorMode` enum, with icons and translated names; the current mode is held in `currentModeProvider`.
- **Theme foundation:** light and dark themes from a provisional seed colour, provisional spacing, and a persisted system/light/dark choice on the settings page.
- **Persistence foundation:**
  - `SharedPreferencesWithCache` with the key allow-list `PreferenceKeys`
  - `SettingsRepository` and its preferences implementation
  - `AppDatabase` schema v1 (`history` and `saved_calculations`, with indexes) and its migration setup
  - `appDatabaseProvider`, which opens the database lazily
- **Localization:** `l10n.yaml`, `lib/l10n/app_en.arb` (18 strings, each with a description) and the generated `app_localizations*.dart`.
- **24 tests** in 8 files, plus `test/helpers/test_app.dart`.

### Changed

- **Android:** `namespace` and `applicationId` are now `com.parasshakya.smartcalculator`; `MainActivity` moved to the matching package; the label is "Smart Calculator".
- **iOS:** the bundle ID is `com.parasshakya.smartcalculator` (tests: `.RunnerTests`), and `CFBundleName` is "Smart Calculator".
- **`pubspec.yaml`:** the real description, the workspace, the dependencies, and `flutter: generate: true`. The template comments and `cupertino_icons` were removed.
- **`analysis_options.yaml`:** strict analyzer modes, 26 extra lint rules, and `depend_on_referenced_packages` raised to an error.
- **`lib/main.dart`:** the counter demo was replaced by the real startup.
- **`macos/Flutter/GeneratedPluginRegistrant.swift`:** regenerated by Flutter for the new plugins.
- **Docs:** ARCHITECTURE.md now describes the implemented state; DECISIONS.md, ROADMAP.md, DEVELOPMENT_STATUS.md, PROJECT_MEMORY.md and CLAUDE.md were updated.

### Removed

- `test/widget_test.dart`, the template counter test.

### Fixed

- **Android build across drives:** `kotlin.incremental=false` in `android/gradle.properties` (DEC-027). Without it, `compileDebugKotlin` and `compileReleaseKotlin` failed with "this and base files have different roots".
- **Kotlin session data:** `android/.gitignore` now ignores `/.kotlin/`, so the Kotlin 2.x session files stay out of Git.
- **DEC-015:** corrected the claim that every planned package was released within the past year (`path` 1.9.1 dates from 2024-10).

### Decisions

- The user approved Phase 1, which resolved P-1, P-2 and P-3.
- DEC-019 to DEC-027 were adopted during implementation:
  - DEC-019: the dependency set and deferrals
  - DEC-020: the lint configuration and boundary checks
  - DEC-021: the navigation and mode-state implementation
  - DEC-022: the shell breakpoints
  - DEC-023: the persistence details
  - DEC-024: the l10n setup
  - DEC-025: the identity scope
  - DEC-026: the Riverpod conventions
  - DEC-027: the Kotlin incremental setting
- New pending decisions: P-9 (Windows Developer Mode) and P-10 (the drives for the project and pub cache).

### Tests

- **`flutter analyze`:** no issues.
- **`dart format --set-exit-if-changed lib test packages`:** 41 files, 0 changed.
- **`flutter test`:** 24 passed.
- **`flutter build apk --debug`:** built. **`flutter build apk --release`:** built, 45.3 MB. This was after DEC-027; both failed before it.
- **`aapt`:** checked the package, label, SDK levels and permissions. The release build has no INTERNET permission.
- **Mutation check:** without its scroll wrapper, the rail made the phone-landscape test fail, as it should.
- **Not run:** the iOS build, running on a device, integration tests.

### Notes

- **Phase 1 is complete** and awaits the user's review. **Phase 2 has not started.**
- **Build quirks on this machine** (P-9): the first `flutter pub get` after a plugin change fails once (no symlink permission), and `dart format .` crashes on long paths under `build/`.

---

## 2026-09-28: Phase 0 and the project-memory system

### Added

- **The project-memory system (DEC-018):**
  - `CLAUDE.md` is the session entry point. It contains the Context Recovery Protocol, the Session Handoff Protocol and the accuracy rules.
  - `docs/PROJECT_MEMORY.md`, `docs/DEVELOPMENT_STATUS.md`, `docs/ARCHITECTURE.md`, `docs/DECISIONS.md`, `docs/ROADMAP.md` and `docs/CHANGELOG.md`.
- `../CLAUDE.md` (in the workspace folder `SmartCalculator/`, outside the planned Git repo): a pointer, so that sessions opened in the parent folder find this project's memory.

### Changed

- Nothing. No application code, configuration or dependencies changed.

### Fixed

- Nothing.

### Decisions

Phase 0 was an audit and planning phase, and the user approved its results.

- DEC-001: phased, approval-gated workflow
- DEC-002: framework Material, not `material_ui`
- DEC-003: plain Navigator with a typed route layer, not `go_router`
- DEC-004: Android and iOS are primary; the other platform folders are kept
- DEC-005: app ID `com.parasshakya.smartcalculator` and display name "Smart Calculator" (not applied yet)
- DEC-006: local Git, never pushed (not initialized yet)
- DEC-007: Riverpod 3 without code generation
- DEC-008: a pure-Dart `packages/calc_engine` with exact arithmetic
- DEC-009: `SharedPreferencesWithCache` and `sqflite`
- DEC-010: the 200+ engine-test gate
- DEC-011: the "quiet precision" UI direction
- DEC-012: no bottom navigation on phones
- DEC-013: shared basic and scientific state
- DEC-014: offline first and privacy first
- DEC-015: the dependency policy
- DEC-016: Phase 1 is foundation only
- DEC-017: roadmap adjustments
- DEC-018: the repository docs are the source of truth

### Tests

Run in `smart_calculator/` on the untouched template:

- `flutter analyze`: `No issues found! (ran in 26.7s)`
- `flutter test`: `+1: All tests passed!` (the template "Counter increments smoke test")

Phase 0 validation ran in a throwaway scratch project outside the repository. Those results support DEC-002, DEC-003, DEC-008, DEC-009 and DEC-015, but they are not tests of this repository:

- dependency resolution
- runtime smoke tests
- exact-arithmetic checks
- in-memory SQLite
- the pub workspace
- Android debug and release builds
- the go_router and APK-size comparison

### Notes

- Phase 0 (audit and architecture) is complete.
- **Phase 1 has not started and is not yet approved to start.**
- Git is not initialized yet, so this entry has no commit hash.
