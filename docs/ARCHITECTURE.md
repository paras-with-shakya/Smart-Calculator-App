# Architecture

> **Status (2026-09-28): Phase 1 (Foundation) is implemented.**
>
> - **§1 Implemented** describes what the code actually does.
> - **§2 Confirmed** lists the decisions the user has made.
> - **§3 Proposed** is the design for later phases, which is **not built yet**.
> - **§4 Pending** lists what still needs a decision.
>
> The reasons behind decisions are in [DECISIONS.md](DECISIONS.md), and build and test results are in [DEVELOPMENT_STATUS.md](DEVELOPMENT_STATUS.md). When something from §3 gets built, move it into §1 and describe what the code does.

## 1. Implemented (Phase 1)

### 1.1 Repository layout

```text
smart_calculator/                    ← Git root and pub workspace root
├── pubspec.yaml                     ← app package; `workspace: [packages/calc_engine]`
├── analysis_options.yaml            ← strict analyzer and lint rules for the whole workspace
├── l10n.yaml                        ← gen-l10n configuration
├── packages/calc_engine/            ← pure-Dart engine package: empty skeleton (§1.10)
├── lib/
│   ├── main.dart                    ← preload preferences → AppRoot
│   ├── app/
│   │   ├── app.dart                 ← SmartCalculatorApp (MaterialApp)
│   │   ├── app_root.dart            ← ProviderScope: overrides, automatic retry off
│   │   ├── modes/                   ← CalculatorMode registry, its icons and names, currentModeProvider
│   │   ├── navigation/              ← AppRoute (sealed) and context.pushRoute
│   │   ├── shell/                   ← adaptive shell, header, mode pill and sheet, mode rail
│   │   └── theme/                   ← AppTheme, AppSpacing, ThemePreference → ThemeMode
│   ├── core/
│   │   ├── layout/                  ← WindowSizeClass
│   │   ├── persistence/             ← preferences, PreferenceKeys, AppDatabase, database providers
│   │   └── widgets/                 ← PlaceholderView
│   ├── features/
│   │   ├── settings/                ← domain/ · data/ · application/ · presentation/
│   │   └── history/                 ← presentation/ (placeholders only)
│   └── l10n/                        ← app_en.arb and the generated app_localizations*.dart
└── test/                            ← mirrors lib/, plus architecture/ and helpers/
```

Folders from the target design (§3.1) that have no code yet are **not** created as empty placeholders. Each one is created when its first file is written: `core/services`, `core/extensions`, `core/utils`, `features/calculator`, `programmer`, `saved`, `converter`, `finance`, `date_calculator`, and `integration_test/`.

### 1.2 Layers and how the boundaries are enforced

- **Dependency direction:** presentation → application → domain ← data. Domain code never imports Flutter.
- **The settings feature follows this pattern:**
  - domain: `ThemePreference`, and the `SettingsRepository` interface
  - data: `PreferencesSettingsRepository`, and `settingsRepositoryProvider`, which is typed as the interface
  - application: `ThemePreferenceNotifier`
  - presentation: `SettingsPage`
- **Enforcement:**
  - `test/architecture/layer_boundaries_test.dart` fails if any file under a `domain/` folder, or any file in `packages/calc_engine`, imports `package:flutter…` or `dart:ui`. It also fails if `calc_engine`'s pubspec declares a Flutter dependency.
  - `analysis_options.yaml` makes `depend_on_referenced_packages` an **error**. In a pub workspace every package shares one package config, so this rule is what stops `calc_engine` from importing a package it doesn't declare.

### 1.3 Startup

1. `main` calls `WidgetsFlutterBinding.ensureInitialized()`, then `openPreferences()`. That creates `SharedPreferencesWithCache` with the allow-list `PreferenceKeys.all` and loads every allowed key into memory, so the saved theme applies on the first frame.
2. `runApp(AppRoot(preferences))` builds `ProviderScope(retry: never, overrides: [sharedPreferencesProvider → preferences])`, then `SmartCalculatorApp`.
3. `SmartCalculatorApp` builds the `MaterialApp`: light and dark themes, `themeMode` from `themePreferenceProvider`, the localization delegates, `onGenerateTitle`, and `home: AppShell`.
4. **The database is not opened at startup.** It opens the first time `appDatabaseProvider` is read, and nothing reads it yet.

The widget tests start the app through the same `AppRoot`, so they run the real configuration.

### 1.4 State management (Riverpod 3.4.3, no code generation)

| Provider | Kind | Location | Holds |
| --- | --- | --- | --- |
| `sharedPreferencesProvider` | `Provider<SharedPreferencesWithCache>` | core/persistence | The preloaded preferences. It throws unless overridden. |
| `settingsRepositoryProvider` | `Provider<SettingsRepository>` | settings/data | A `PreferencesSettingsRepository` |
| `themePreferenceProvider` | `NotifierProvider<ThemePreferenceNotifier, ThemePreference>` | settings/application | The theme choice. `setPreference` saves first, then updates the state. |
| `currentModeProvider` | `NotifierProvider<CurrentModeNotifier, CalculatorMode>` | app/modes | The current mode: in memory only, starting at Basic |
| `databaseFactoryProvider` | `Provider<DatabaseFactory>` | core/persistence | The sqflite plugin factory; tests use an FFI factory instead |
| `appDatabaseProvider` | `FutureProvider<Database>` | core/persistence | Opened on first read, closed on dispose. It has no consumers until Phase 4. |

Conventions:

- **Repository providers** live in the data layer and are typed by the domain interface. Notifiers read them through `ref`.
- **Dependency injection** is done with provider overrides. Tests use real in-memory backends (`InMemorySharedPreferencesAsync`, `sqflite_common_ffi`) rather than mocks.
- **Automatic retry** (a Riverpod 3 default) is turned off app-wide in `AppRoot`.
- **`select`:** every Phase 1 provider holds a single value, so there is nothing to narrow yet. Use `ref.watch(provider.select(...))` once a widget needs part of a larger state, such as the calculator display in Phase 3.

### 1.5 Navigation (plain Navigator with a typed route layer)

- **Pages** are the sealed `AppRoute` hierarchy: `HistoryRoute` (`/history`) and `SettingsRoute` (`/settings`).
- **Pushing:** `context.pushRoute<T>(route)` (the `AppNavigator` extension) calls `Navigator.push` with a `MaterialPageRoute` whose `RouteSettings.name` is the route's name. That gives each platform its native transition, including the iOS back-swipe. The page for each route comes from an exhaustive `switch` in `app_navigator.dart`, so the compiler rejects a route without a page.
- **Going back and closing sheets** use the standard `Navigator.pop`: the app-bar back button, the system back gesture, iOS swipe-back.
- **Modes are state, not routes.**
- There are no deep links, no named-route table and no `go_router`.

### 1.6 Adaptive shell

| Window width | Layout |
| --- | --- |
| Compact (< 600 dp) | A top bar with the **mode pill** and the history and settings actions, above the current mode. The pill opens a bottom sheet listing the modes. **No bottom navigation.** |
| Medium (600–839 dp) | A `NavigationRail` of modes, then a top bar (mode name, history, settings), then the current mode |
| Expanded (≥ 840 dp) | Rail, current mode and a 320 dp **history panel**. The history action is hidden because the panel is visible. |

- **Size class:** `WindowSizeClass.fromWidth(MediaQuery.sizeOf(context).width)`, using the Material 3 breakpoints. Most phones in landscape measure 840 dp or more, so they get the expanded layout.
- **Short windows:** the rail scrolls when it can't show every destination, for example a phone in landscape. A test checks this.
- **Mode registry:** the `CalculatorMode` enum (basic, scientific, programmer, finance, converter, date). `CalculatorModePresentation` gives each mode its icon and translated name through exhaustive switches.
- **Mode content:** every mode shows `PlaceholderView` (an icon plus "This mode isn't available yet."), and so do the history page and panel.

### 1.7 Theme

- **`AppTheme.light` / `AppTheme.dark`:** `ThemeData(colorScheme: ColorScheme.fromSeed(...))` from a single, **provisional** "iris" seed, `0xFF5B57D1`.
- **`AppSpacing`:** sm 8, md 16, lg 24 (provisional). Only the steps in use exist; Phase 2 defines the full scale.
- **Theme mode:** `ThemePreference` (system, light, dark) maps to `ThemeMode`. `MaterialApp` animates theme changes.
- **Settings page:** Phase 1 has only the foundation, an "Appearance → Theme" segmented button.

### 1.8 Persistence

**Preferences** (`SharedPreferencesWithCache`, allow-list `PreferenceKeys.all`):

| Key | Stored values | Default |
| --- | --- | --- |
| `settings.theme_preference` | `system`, `light`, `dark` (fixed strings, not enum names) | `system`, also for any unrecognized value |

**Database** (`AppDatabase`, sqflite):

- **File:** `smart_calculator.db` in the platform's databases directory.
- **Version:** `schemaVersion` is the number of migrations, currently 1.
- **Migrations** are ordered lists of SQL statements. `onCreate` runs all of them; `onUpgrade` runs the ones that are missing. Each run is one batch inside sqflite's transaction. Never edit a migration once it has shipped; append a new one.
- **Schema v1.** Timestamps are UTC milliseconds since the epoch, and `mode`/`kind` hold stable identifiers.

  | Table | Columns | Index |
  | --- | --- | --- |
  | `history` | `id` INTEGER PK AUTOINCREMENT, `expression` TEXT, `result` TEXT, `mode` TEXT, `created_at` INTEGER (all NOT NULL) | `idx_history_created_at` |
  | `saved_calculations` | `id` INTEGER PK AUTOINCREMENT, `name` TEXT, `kind` TEXT, `inputs_json` TEXT, `created_at` INTEGER, `updated_at` INTEGER (all NOT NULL) | `idx_saved_calculations_updated_at` |

- **Nothing reads or writes these tables yet.** The repositories come in Phase 4.

### 1.9 Localization

- **Configuration** (`l10n.yaml`): `arb-dir: lib/l10n`, template `app_en.arb`, output `app_localizations.dart`, `nullable-getter: false`, `required-resource-attributes: true`, `format: true`.
- **Strings:** English only. Every visible string is in `app_en.arb`, with a description for translators.
- **Access:** `AppLocalizations.of(context)` never returns null.
- **Generated files:** `lib/l10n/app_localizations*.dart` are committed. `flutter pub get` (and run, build, analyze) regenerates them because `flutter: generate: true` is set.

### 1.10 Calculation engine package

`packages/calc_engine` contains:

- a `pubspec.yaml` with no dependencies (`resolution: workspace`)
- `lib/calc_engine.dart`, which holds only the library documentation
- a `README.md`

The app does **not** depend on it yet. The engine, its dependencies (`decimal`, `rational`, `test`) and its tests arrive in Phase 3 (DEC-019).

### 1.11 Platforms

| Platform | Identity | Verification |
| --- | --- | --- |
| Android | `com.parasshakya.smartcalculator`, label "Smart Calculator"; the Kotlin package matches | APK builds; see DEVELOPMENT_STATUS.md |
| iOS | Bundle ID `com.parasshakya.smartcalculator` (tests: `.RunnerTests`), `CFBundleName` and `CFBundleDisplayName` "Smart Calculator" | Can't be built on Windows (P-5) |
| web, Windows, Linux, macOS | Template identifiers (DEC-025) | Not built. Not supported targets (DEC-004). |

### 1.12 Tests

| File | Covers |
| --- | --- |
| `test/app/app_test.dart` | The app starts in Basic mode, with the system theme and the app title |
| `test/app/shell/app_shell_test.dart` | Each window class's layout; the mode sheet and rail switching modes; no bottom navigation; no overflow at 200% text; the rail scrolling on a phone in landscape |
| `test/app/navigation/app_navigator_test.dart` | Header actions push the typed routes (checking route names); back returns to the shell |
| `test/features/settings/preferences_settings_repository_test.dart` | Default value, round trip, the stored string format, fallback for unknown values |
| `test/features/settings/theme_preference_test.dart` | The notifier loads and saves; choosing Dark in the UI survives a simulated restart |
| `test/core/persistence/app_database_test.dart` | Schema version, tables, columns and indexes; reopening keeps data; the provider opens in the databases directory and closes on dispose |
| `test/core/layout/window_size_class_test.dart` | Breakpoint boundaries |
| `test/architecture/layer_boundaries_test.dart` | The engine and the domain layers stay free of Flutter |

Shared helpers are in `test/helpers/test_app.dart`: in-memory preferences, `pumpApp` with a window size, and English strings.

### 1.13 How to extend the current code

- **Add a calculator mode:** add a value to `CalculatorMode`. The compiler then flags the icon and name switches. From Phase 3, add the mode's screen.
- **Add a pushed page:** add a `final class` to `AppRoute` with a unique `name`, then add its case to `_pageFor` (the compiler enforces this). Open it with `context.pushRoute`.
- **Add a preference:** add its key to `PreferenceKeys` and to `PreferenceKeys.all`. Read and write it through a repository in the owning feature's data layer, storing fixed strings.
- **Change the database schema:** append a migration to `_migrations` in `app_database.dart`. `schemaVersion` follows automatically. Add a test.
- **Add a string:** add it to `app_en.arb` with a description, then run `flutter pub get`.
- **Checks** (run from `smart_calculator/`): `flutter analyze`, `dart format .`, `flutter test`, `flutter build apk --debug`.

## 2. Confirmed Decisions

Decided by the user. The "Implemented" column reflects the state after Phase 1.

| Area | Decision | Implemented | Record |
| --- | --- | --- | --- |
| Workflow | Phase by phase with approval gates | Process | DEC-001 |
| Material | `package:flutter/material.dart`; no `material_ui` | Yes | DEC-002 |
| Navigation | Plain `Navigator` with a typed route layer; no `go_router` | Yes (§1.5) | DEC-003 |
| Platforms | Android and iOS primary; other folders kept, unsupported | Yes | DEC-004 |
| App identity | `com.parasshakya.smartcalculator`, "Smart Calculator" | Yes, on Android and iOS | DEC-005 |
| Version control | Local Git, `main`, never push | Yes | DEC-006 |
| State management | Riverpod 3 without code generation | Foundation (§1.4) | DEC-007 |
| Calculation engine | Pure-Dart `packages/calc_engine`; numeric library hidden; exact arithmetic | Skeleton only (§1.10) | DEC-008 |
| Persistence | `SharedPreferencesWithCache` for settings; `sqflite` for history and saved calculations | Foundation (§1.8) | DEC-009 |
| Testing | 200+ engine tests before the calculator UI counts as complete; unit, widget and integration tests | Foundation tests only | DEC-010 |
| UI/UX | "Quiet precision" | No (Phase 2) | DEC-011 |
| Navigation UX | Phones: mode pill and sheet, no bottom nav. Tablets and landscape: rail and history panel | Shell with placeholders (§1.6) | DEC-012 |
| Shared state | Basic and scientific share one calculator state | No (Phase 3/5) | DEC-013 |
| Privacy | Offline first and privacy first | Partly (§3.10) | DEC-014 |
| Dependencies | Verify before adding | Applied in Phase 1 | DEC-015 |
| Phase 1 scope | Foundation only | Yes | DEC-016 |

## 3. Proposed Architecture (target design — NOT implemented yet)

### 3.1 Target folders still to come

These folders don't exist yet:

- `core/services/`, `core/extensions/`, `core/utils/`
- `features/calculator/` (basic, scientific and memory, sharing one state)
- `features/programmer/`, `saved/`, `converter/`, `finance/`, `date_calculator/`
- `integration_test/`

Each feature has `domain/` (pure Dart), `data/`, `application/` and `presentation/`, as the settings feature does now.

### 3.2 Navigation still to come

- **Pages to add:** saved calculations, the settings subpages (About, licenses, privacy) and the finance tools.
- **Android predictive back gesture:** not scheduled yet (see ROADMAP.md).

### 3.3 Calculation engine (Phase 3)

- **Pipeline:** tokenize → precedence-aware parse → syntax tree → evaluate with settings (angle mode, precision) → format.
- **Types:**
  - `CalcValue` holds either an exact fraction or an approximate double.
  - `CalcResult` is either a success or a typed `CalcError`.
  - `decimal` and `rational` are used only inside `src/number/`.
- **Errors:** a fixed set (syntax, incomplete, divide by zero, invalid function input, undefined, overflow), each with a translated message. `NaN`, `Infinity` and `null` never reach the screen. Size limits prevent freezes.
- **Functions:** kept in a registry, so a new one needs no parser changes.
- **Editing model:** tokens plus a cursor. Backspace removes a function name such as `sin(` as one unit; pasted text goes through the tokenizer.
- **Live preview:** closes open brackets automatically. It shows only valid results; errors appear after `=`.
- **Programmer mode:** a separate `BigInt` evaluator with a set word size and two's complement.
- **Default behaviours:** PENDING (P-6).

### 3.4 State (Phase 3 onward)

- Narrow rebuilds: a keystroke rebuilds only the display, and the keypad stays `const`.
- `AsyncNotifier` for persisted lists.
- Calculation errors are values, not exceptions.

### 3.5 Persistence still to come

- The history and saved-calculation repositories (Phase 4). Their interfaces go in domain; the sqflite implementations go in data.
- Paged queries.
- A history retention limit and an off switch (values not decided).
- Saved calculations reopen the right tool from `kind` plus `inputs_json`.
- Memory value and last mode in preferences. Right now the current mode isn't persisted (DEC-021).
- If desktop is ever wanted, only the database setup would need a desktop SQLite driver.

### 3.6 Design system (Phase 2)

- **Tokens:**
  - colour roles (primary, secondary, background, surface, card, text, muted text, accent, success, warning, error, divider, operator keys, number keys)
  - typography (display, expression, result, heading, body, caption, button, label)
  - the full spacing scale, radius and motion
  - light, dark and high-contrast variants
- **Palette:** warm neutral surfaces ("porcelain" and "graphite") and the iris accent, used sparingly.
- **Keys:** squircle shape (`RoundedSuperellipseBorder`) in three tones.
- **Fonts:** bundled, with tabular digits (P-8).
- **Components:** everything in the master prompt except `AppBottomNavigation`. `PlaceholderView` and the settings page's private section header are Phase 1 stand-ins; Phase 2 decides what replaces them.
- **Review:** a debug-only component gallery for the design review.

### 3.7 Localization still to come

Number and date formatting through `intl`, once there are numbers and dates to show.

### 3.8 Planned dependencies not added yet

Each must be re-verified before it is added (DEC-015).

| Package | When | Purpose |
| --- | --- | --- |
| `decimal` ^3.2.6, `rational` ^2.2.3 | Phase 3, engine only | Exact arithmetic |
| `test` | Phase 3, engine dev | Engine unit tests |
| `integration_test` (SDK) | When the first end-to-end flow exists | Integration tests |
| `package_info_plus` | Phase 10, if chosen (P-7) | App version on the About screen |
| `http` | Only if live currency rates are approved | Currency service |

### 3.9 Platform configuration still to come

- **Release signing:** the release build is still signed with the debug key; not scheduled yet.
- **Android predictive back:** not scheduled yet.
- **Web and desktop identifiers:** unchanged (DEC-025).

### 3.10 Privacy checks

- **Plan:** the release app requests no INTERNET permission.
- **Actual:** the plugins added in Phase 1 add no network permission. For the release manifest check, see DEVELOPMENT_STATUS.md.

## 4. Pending Decisions

The decisions that affect architecture (full list: [DEVELOPMENT_STATUS.md](DEVELOPMENT_STATUS.md#pending-decisions)):

- **P-6:** the engine's default behaviours, before Phase 3.
- **P-7:** where the app version comes from (Phase 10).
- **P-8:** which fonts to use (Phase 2).
- **P-9:** Windows Developer Mode (symlinks), which affects `flutter pub get` on this machine.
- **P-10:** Kotlin incremental compilation across drives (see DEVELOPMENT_STATUS.md).

**Not decided at all yet:** the history retention default; the currency-rate service beyond "behind a service interface, no committed keys"; the release signing setup; the phone-landscape calculator layout (Phase 3/5).

## 5. Rejected Alternatives (summary)

See [DECISIONS.md](DECISIONS.md) for the reasoning.

| Rejected | Record |
| --- | --- |
| `material_ui` | DEC-002 |
| `go_router` 18 or 17.x | DEC-003 |
| Deleting the web and desktop folders; `drift` for a web demo | DEC-004 |
| Bloc, Provider, `get_it`, code generation | DEC-007 |
| `math_expressions` or string evaluation; an engine folder inside `lib/` | DEC-008 |
| Hive, Isar, drift, SharedPreferences for history | DEC-009 |
| A bottom navigation bar on phones | DEC-012 |
| `google_fonts`, `fl_chart`, `freezed`, `json_serializable`, analytics, audio/vibration packages | DEC-015 |
| Empty placeholder folders; adding engine dependencies before they are used | DEC-019 |
