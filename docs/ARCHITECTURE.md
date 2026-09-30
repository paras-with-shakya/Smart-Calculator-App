# Architecture

> **Status (2026-09-28): Phases 1 (Foundation) and 2 (Design system) are complete. Phase 3 (Basic calculator) is implemented and awaits the user's review** (§1.12, §1.13).
>
> - **§1 Implemented** describes what the code actually does.
> - **§2 Confirmed** lists the decisions the user has made.
> - **§3 Proposed** is the design for later phases, which is **not built yet**.
> - **§4 Pending** lists what still needs a decision.
>
> The reasons behind decisions are in [DECISIONS.md](DECISIONS.md), and build and test results are in [DEVELOPMENT_STATUS.md](DEVELOPMENT_STATUS.md). When something from §3 gets built, move it into §1 and describe what the code does.

## 1. Implemented

### 1.1 Repository layout

```text
smart_calculator/                    ← Git root and pub workspace root
├── pubspec.yaml                     ← app package, workspace, dependencies, fonts, assets
├── analysis_options.yaml            ← strict analyzer and lint rules for the whole workspace
├── dart_test.yaml                   ← skips the design-review screenshot generator by default
├── l10n.yaml                        ← gen-l10n configuration
├── assets/fonts/                    ← Manrope 400/500/600/700 and its OFL licence
├── packages/calc_engine/            ← pure-Dart calculation engine and its tests (§1.12)
├── lib/
│   ├── main.dart                    ← registers font licences, preloads preferences → AppRoot
│   ├── main_gallery.dart            ← debug-only entry point of the component gallery (§1.9)
│   ├── app/
│   │   ├── app.dart                 ← SmartCalculatorApp (MaterialApp, four themes)
│   │   ├── app_root.dart            ← ProviderScope: overrides, automatic retry off
│   │   ├── font_licenses.dart       ← registers Manrope's licence
│   │   ├── modes/                   ← CalculatorMode registry, its icons and names, currentModeProvider
│   │   ├── navigation/              ← AppRoute (sealed) and context.pushRoute
│   │   ├── shell/                   ← adaptive shell, header, mode pill and mode sheet, mode rail
│   │   └── theme/                   ← design tokens and AppTheme (§1.7)
│   ├── core/
│   │   ├── formatting/              ← LocalizedNumberFormat, numberFormatProvider (DEC-037)
│   │   ├── layout/                  ← WindowSizeClass
│   │   ├── persistence/             ← preferences, PreferenceKeys, AppDatabase, database providers
│   │   └── widgets/                 ← the reusable components (§1.8)
│   ├── features/
│   │   ├── calculator/              ← domain/ · data/ · application/ · presentation/ (§1.13)
│   │   ├── settings/                ← domain/ · data/ · application/ · presentation/
│   │   └── history/                 ← presentation/ (placeholders only)
│   ├── gallery/                     ← component gallery (debug-only tool, not part of the app)
│   └── l10n/                        ← app_en.arb and the generated app_localizations*.dart
└── test/                            ← mirrors lib/, plus architecture/, gallery/, design_review/ and helpers/
```

Folders from the target design (§3.1) that have no code yet are **not** created as empty placeholders. Each one is created when its first file is written.

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
- **UI rule (user requirement):** screens are built only from the widgets in `lib/core/widgets/` and the tokens in `lib/app/theme/`. Feature code never hard-codes colours, sizes, shapes or text styles (CLAUDE.md, rule 12).

### 1.3 Startup

1. `main` initializes the bindings and calls `registerFontLicenses()`, which is lazy: the licence file is read only when the licences page asks for it.
2. `main` calls `openPreferences()`, which creates `SharedPreferencesWithCache` with the allow-list `PreferenceKeys.all` and loads every allowed key into memory, so the saved theme applies on the first frame.
3. `runApp(AppRoot(preferences))` builds `ProviderScope(retry: never, overrides: [sharedPreferencesProvider → preferences])`, then `SmartCalculatorApp`.
4. `SmartCalculatorApp` builds the `MaterialApp`:
   - `theme`, `darkTheme`, `highContrastTheme` and `highContrastDarkTheme`
   - `themeMode` from `themePreferenceProvider`
   - a theme-change animation from the motion tokens
   - the localization delegates and `onGenerateTitle`
   - `home: AppShell`
5. **The database is not opened at startup.** It opens the first time `appDatabaseProvider` is read, and nothing reads it yet.

The widget tests start the app through the same `AppRoot`, so they run the real configuration.

### 1.4 State management (Riverpod 3.4.3, no code generation)

| Provider | Kind | Location | Holds |
| --- | --- | --- | --- |
| `sharedPreferencesProvider` | `Provider<SharedPreferencesWithCache>` | core/persistence | The preloaded preferences. It throws unless overridden. |
| `settingsRepositoryProvider` | `Provider<SettingsRepository>` | settings/data | A `PreferencesSettingsRepository` |
| `themePreferenceProvider` | `NotifierProvider<ThemePreferenceNotifier, ThemePreference>` | settings/application | The theme choice. `setPreference` saves first, then updates the state. |
| `currentModeProvider` | `NotifierProvider<CurrentModeNotifier, CalculatorMode>` | app/modes | The current mode: in memory only, starting at Basic |
| `calculatorProvider` | `NotifierProvider<CalculatorNotifier, CalculatorState>` | calculator/application | The expression, its live value, the result or the error (§1.13) |
| `memoryProvider` | `NotifierProvider<MemoryNotifier, CalcValue?>` | calculator/application | The calculator memory; saves first, then updates |
| `memoryRepositoryProvider` | `Provider<MemoryRepository>` | calculator/data | A `PreferencesMemoryRepository` |
| `numberFormatProvider` | `Provider<LocalizedNumberFormat>` | core/formatting | The device region's number format, read from the platform locale |
| `databaseFactoryProvider` | `Provider<DatabaseFactory>` | core/persistence | The sqflite plugin factory; tests use an FFI factory instead |
| `appDatabaseProvider` | `FutureProvider<Database>` | core/persistence | Opened on first read, closed on dispose. Read by `historyRepositoryProvider` and `savedCalculationRepositoryProvider` (§1.17, §1.18). |
| `historyRepositoryProvider` | `Provider<HistoryRepository>` | history/data | A `SqfliteHistoryRepository` |
| `historyProvider` | `AsyncNotifierProvider<HistoryNotifier, List<HistoryEntry>>` | history/application | The history, newest first (§1.17) |
| `savedCalculationRepositoryProvider` | `Provider<SavedCalculationRepository>` | saved_calculations/data | A `SqfliteSavedCalculationRepository` |
| `savedCalculationsProvider` | `AsyncNotifierProvider<SavedCalculationsNotifier, List<SavedCalculation>>` | saved_calculations/application | The saved calculations, most recently updated first (§1.18) |
| `converterProvider` | `NotifierProvider<ConverterNotifier, ConverterState>` | converter/application | The current category, its two selected units, the typed amount and the live currency rates (§1.19) |

Conventions:

- **Repository providers** live in the data layer and are typed by the domain interface. Notifiers read them through `ref`.
- **Dependency injection** is done with provider overrides. Tests use real in-memory backends (`InMemorySharedPreferencesAsync`, `sqflite_common_ffi`) rather than mocks.
- **Automatic retry** (a Riverpod 3 default) is turned off app-wide in `AppRoot`.
- **`select`:** the memory row watches only whether a memory and a current value exist (`provider.select`), so typing doesn't rebuild it for every digit. The keypad watches only the number format; the display watches the whole calculator state.

### 1.5 Navigation (plain Navigator with a typed route layer)

- **Pages** are the sealed `AppRoute` hierarchy: `HistoryRoute` (`/history`) and `SettingsRoute` (`/settings`).
- **Pushing:** `context.pushRoute<T>(route)` (the `AppNavigator` extension) calls `Navigator.push` with a `MaterialPageRoute` whose `RouteSettings.name` is the route's name. That gives each platform its native transition, including the iOS back-swipe. The page for each route comes from an exhaustive `switch` in `app_navigator.dart`, so the compiler rejects a route without a page.
- **Going back and closing sheets** use the standard `Navigator.pop`.
- **Modes are state, not routes.**
- There are no deep links, no named-route table and no `go_router`.

### 1.6 Adaptive shell

| Window width | Layout |
| --- | --- |
| Compact (< 600 dp) | An `AppHeader` with the **mode pill** (`AppButton`, secondary, with a dropdown arrow) and the history and settings `AppIconButton`s, above the current mode. The pill opens a bottom sheet with a **grid of `AppCard` mode tiles**: 3 columns, or 2 from 115% text size. The current mode's tile is selected. **No bottom navigation.** |
| Medium (600–839 dp) | A `NavigationRail` of modes, then the header (mode name, history, settings), then the current mode |
| Expanded (≥ 840 dp) | Rail, current mode and a 320 dp **history panel**. The history action is hidden because the panel is visible. **Below 480 dp of height** (a phone in landscape) there is no panel, and the history action shows instead (DEC-042). |

- **Size class:** `WindowSizeClass.fromWidth(MediaQuery.sizeOf(context).width)`, using the Material 3 breakpoints. Most phones in landscape measure 840 dp or more, so they get the expanded layout, without the panel.
- **Short windows:** the rail scrolls when it can't show every destination. A test checks this.
- **Mode registry:** the `CalculatorMode` enum (basic, scientific, programmer, finance, converter, date). `CalculatorModePresentation` gives each mode its icon and translated name through exhaustive switches.
- **Mode content:** Basic shows the calculator (`CalculatorView`, §1.13). The other modes show an `EmptyState` ("This mode isn't available yet."), and so do the history page and panel.

### 1.7 Design system: tokens and themes (Phase 2)

All tokens live in `lib/app/theme/`. Components and screens read them from the theme; nothing hard-codes a value.

- **`AppColors`** (`ThemeExtension`, `AppColors.of(context)`):
  - **27 colour roles:** background, surface, card, surfaceMuted, textPrimary, textMuted; primary with its container and "on" colours; secondary; success, warning, error, onError; divider, outline, contrastOutline; digit, operator, function and equals keys, each with its label colour.
  - **Four palettes:** `light` ("porcelain"), `dark` ("graphite"), `highContrastLight`, `highContrastDark`.
  - **One accent:** `primary` (iris) is the only accent. There is deliberately no separate "accent" role.
  - **`contrastOutline`** is transparent except in the high-contrast palettes, where it draws a visible edge around keys, cards, buttons, sheets and dialogs.
  - **Checked by tests:** every foreground/background pair meets WCAG AA (4.5:1) in the normal palettes and AAA (7:1) in the high-contrast ones. Outlines meet 3:1, and 4.5:1 in high contrast.
- **`AppTypography`** (`ThemeExtension`): 11 styles.
  - display 40, result 48, expression 24, key 28, keySymbol 34, heading 22, title 17, body 16, caption 13, button 16, label 14.
  - All use the bundled **Manrope**. The number styles (display, result, expression, key) turn on **tabular figures**, because Manrope's default digits are proportional.
  - `keySymbol` is larger and heavier because Manrope draws + − × ÷ = small.
- **`AppSpacing`:** xs 4, sm 8, md 16, lg 24, xl 32, xxl 48.
- **`AppRadius`:** sm 8, md 12, lg 16, xl 24. `AppRadius.shape(radius)` returns a `RoundedSuperellipseBorder` (a squircle); every rounded shape in the app uses it.
- **`AppMotion`:** short 100 ms, medium 200 ms, long 300 ms; standard and emphasized curves. `AppMotion.durationOf(context, d)` returns zero when the platform asks for reduced motion.
- **`AppTheme`:** builds the four `ThemeData`s from the tokens. It maps them onto `ColorScheme` (the page background is `surface`), onto `TextTheme` (Manrope everywhere) and onto the component themes:
  - app bar, filled/outlined/text buttons, card, dialog, bottom sheet
  - text fields: filled, `UnderlineInputBorder` rounded on every corner, so the label floats inside the fill
  - navigation rail and segmented button: the active item uses the accent tint
  - list tile, divider, progress indicator, text selection

  Plain Material widgets therefore match the design system too.
- **Sheets** use the page background, so cards inside them read the same way they do on a page. **Dialogs** use `surface`.
- **High contrast:** `MaterialApp` switches to the high-contrast themes when the platform asks for more contrast (a test checks this). Flutter reports that request on **Android 14+ (API 34+)**, through the "High contrast text" setting, and on **iOS 13+** ("Increase Contrast"). On older Android versions only the Phase 10 in-app switch will turn it on.
- **Fonts:** Manrope static TTFs (from `googlefonts/manrope` at commit `6f81ebe`) are bundled in `assets/fonts/` and declared in pubspec. They are never downloaded at runtime. `registerFontLicenses()` adds the OFL text to `LicenseRegistry`.

### 1.8 Reusable components (`lib/core/widgets/`, Phase 2)

| Widget | Purpose and API highlights |
| --- | --- |
| `AppButton` | Every text button. `variant`: primary, secondary, text, destructive. Optional `icon` / `trailingIcon`, `isLoading` (a spinner; the label stays for size and screen readers), `expand`. At least 48 dp. |
| `AppIconButton` | Icon-only button. `tooltip` is **required**; it is the accessibility label. `variant`: standard or tonal. |
| `CalculatorButton` | A squircle calculator key. `kind`: digit, operator, function, equals, which sets the tone, or memory (no fill, a muted label and no high-contrast outline; DEC-043). `semanticLabel` is **required** (screen readers hear "Divide", not "÷"). `label` or `icon`, and `onLongPress`. Pressing scales it (off under reduced motion). Never below 48 dp, and the label shrinks rather than overflows. |
| `DisplayText` | A calculator display line (DEC-043): end-aligned text that shrinks to 50% to stay on one line, then wraps. Optional caret at a text offset, `onTapOffset` for tap-to-move, a semantics label and a live region. A custom `RenderBox` (`RenderDisplayText`) that owns and disposes its `TextPainter`. |
| `AppCard` | Rounded surface, optionally tappable. `selected` gives the accent tint and matching foreground, and is announced. |
| `AppBottomSheet` / `showAppBottomSheet` | A titled modal sheet (heading semantics), as tall as its content and scrollable beyond. It returns the popped value. |
| `AppDialog` / `showConfirmationDialog` | A title, a message and `AppButton` actions. The confirmation returns `bool` (dismiss counts as cancel), and `isDestructive` uses the error colour. Cancel defaults to the platform's translated label. |
| `AppTextField` | A filled text field. `label` is **required**. Also hint, helper, error, prefix/suffix, keyboard type, formatters and callbacks. |
| `AppChoiceGroup` / `AppChoice` | Pick one of a few options: a segmented button when every label fits on one line, otherwise a radio list (DEC-035). |
| `EmptyState` / `ErrorState` / `LoadingState` | Status views sharing one layout: icon badge (or spinner), optional title, message, optional action. They scroll at large text sizes. `LoadingState` is a live region. |
| `SectionHeader` | A quiet group heading (heading semantics). |
| `AppHeader` | The top bar: title, automatic back button, actions. `primary: false` for headers inside panels. |

`PlaceholderView` (Phase 1) was replaced by `EmptyState`, and the settings page's private section header by `SectionHeader`. The settings page's theme control is an `AppChoiceGroup`. `ShellHeader`, the mode pill, the mode sheet, the history and settings pages and the calculator all use these components.

### 1.9 Component gallery and design review (Phase 2)

- **Gallery:** `lib/main_gallery.dart` (`flutter run -t lib/main_gallery.dart`) shows every token and component. Switches toggle light/dark, high contrast and text size (100%, 150%, 200%). It is a separate entry point, so `main.dart` never includes it in app builds. The gallery's demo copy is not localized (it is a developer tool).
- **Accessibility checks:** `test/gallery/gallery_accessibility_test.dart` runs Flutter's `textContrastGuideline`, `androidTapTargetGuideline` and `labeledTapTargetGuideline` over every gallery section in all four themes (44 tests, 11 sections × 4 themes since DEC-050 added "Scientific keys").
- **Screenshots:** `test/design_review/design_review_screenshots_test.dart` (tag `design-review`, skipped by default through `dart_test.yaml`) renders 50 PNGs with the real fonts into `build/design_review/`:
  - every section, in light and dark
  - some sections at 200% text and in high contrast
  - phone shell, mode sheet and settings, and the tablet landscape shell
  - 15 calculator screens on a 360×800 dp phone in the India region (empty, typing with memory, result, landscape, error, cursor, a long expression, scientific notation, 200% text) and on tablets

  Generate them with `flutter test --tags design-review --run-skipped --update-goldens`. They are review images, not committed, and not a cross-machine regression suite.

### 1.10 Persistence

**Preferences** (`SharedPreferencesWithCache`, allow-list `PreferenceKeys.all`):

| Key | Stored values | Default |
| --- | --- | --- |
| `settings.theme_preference` | `system`, `light`, `dark` (fixed strings, not enum names) | `system`, also for any unrecognized value |
| `calculator.memory` | The memory as an exact fraction: `n` or `n/d` (such as `1/3`); removed when the memory is cleared | Empty, also for any unreadable value |

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

### 1.11 Localization

- **Configuration** (`l10n.yaml`): `arb-dir: lib/l10n`, template `app_en.arb`, output `app_localizations.dart`, `nullable-getter: false`, `required-resource-attributes: true`, `format: true`.
- **Strings:** English only (55 strings). Every visible string of the app is in `app_en.arb`, with a description for translators. That includes the calculator's key labels, what screen readers say for keys and expressions ("divided by"), and the error messages. The component gallery is the only exception, as a developer tool.
- **Numbers** follow the device region, not the app language (DEC-037, §1.13).
- **Access:** `AppLocalizations.of(context)` never returns null.
- **Generated files:** `lib/l10n/app_localizations*.dart` are committed. `flutter pub get` (and run, build, analyze) regenerates them.

### 1.12 Calculation engine (`packages/calc_engine`, Phase 3; scientific functions added Phase 5)

Pure Dart; the app depends on it by path. Dependencies: `rational` ^2.2.3, and `test` ^1.31.1 for development (DEC-038).

- **API** (`lib/calc_engine.dart` exports only these): `CalcEngine().evaluate(expression, variables: {...}, angleMode: AngleMode.degrees)` returns a `CalcResult`, which is either `CalcSuccess(CalcValue)` or `CalcFailure(CalcError)`. `CalcError` is empty, syntax, incomplete, divisionByZero, overflow or undefined (DEC-047). Nothing throws to the caller.
- **`CalcValue`** (`src/number/`, the only place that imports `rational`): a sealed hierarchy of an exact fraction (`Rational`) or an approximate value (`double`), for irrational results (DEC-047). Arithmetic is contagious: exact-op-exact stays exact; anything touching an approximate operand becomes approximate. It offers `+ − × ÷` and negation, `isZero`, `isExact`, `isTooLarge` (10¹⁰⁰ or more), `CalcValue.parse` for decimal literals, and `toStorageString` / `tryParseStorage` (`n`, `n/d` or `~<double>`) for saving values exactly. `toDecimalString()` gives the canonical text: 12 significant digits, half away from zero, `d.ddde±N` from 10¹² up and below 10⁻⁶, never `-0`.
- **Pipeline:**
  1. `src/lexer`: characters → tokens. It accepts digits and `.`, letters and `π` (variable, constant and function names), `+ − × ÷` and `- * /`, `%`, `^`, `!`, brackets and spaces.
  2. `src/parser`: recursive descent → a sealed `Node` tree (number, variable, constant, negate, percent, factorial, function call, binary). Precedence, lowest to highest: `+ −`, then `× ÷` and implied multiplication, then unary `−`/`+`, then `^` (right-associative), then postfix `%`/`!`. `2^3^2 = 512`; `−3^2 = −9`; `2^3! = 64` (DEC-047).
  3. `src/eval`: evaluates the tree exactly wherever provably possible (including through `^`, `sqrt`, `cbrt` via perfect-root/perfect-power detection on `BigInt`; DEC-047), with smart percent (DEC-036), angle-mode-aware trigonometry, and checks every intermediate value for overflow.
- **Functions** (`src/ast/node.dart`'s `CalcFunction`, dispatched in `src/eval/evaluator.dart`): `sin cos tan asin acos atan sinh cosh tanh log ln sqrt cbrt abs`. A name is only read as a function call immediately followed by `(`; otherwise it's an ordinary variable. `π` and `e` are always the constants, never a variable, even if one of that name is supplied (DEC-047).
- **`AngleMode`** (`src/angle_mode.dart`): `degrees` (the default) or `radians`, affecting sin/cos/tan/asin/acos/atan only — never the hyperbolic functions.
- **Limits:** 100 nested brackets and 1000 tokens (DEC-039); factorial and `^` reject magnitudes past 2000 as overflow before computing.
- **Variables** carry exact values into an expression: the app passes results and the memory as letter-only names (§1.13), skipping `e` (§1.13's `ExpressionBuffer._variableName`, DEC-047).
- **Tests** (`dart test` in the package): 377. 260 from Phase 3 (224 table-driven cases, `CalcValue` tests, a 20,000-input fuzz test), plus `test/scientific_test.dart`'s 117 Phase 5 cases (the power operator's precedence and exactness, every function's normal range and domain errors, both angle modes, and the constants). The fuzz test's alphabet now also includes `^ ! π e` and function-name letters.

### 1.13 Basic calculator (`lib/features/calculator/`, Phase 3)

- **domain:**
  - `ExpressionBuffer`: the expression as units (a typed symbol, or a `ValueUnit` holding an exact value) plus a cursor. Its edits apply the input rules (DEC-040) and return a new buffer, or the same buffer when a rule rejects the key. `toEngineInput()` writes each value as a bracketed variable, `(a)`, so values are evaluated exactly and multiply their neighbours.
  - `CalculatorSymbols`, the `CalculatorKey` enum, and the `MemoryRepository` interface.
- **data:** `PreferencesMemoryRepository` saves the memory under `calculator.memory` as an exact fraction.
- **application:**
  - `CalculatorNotifier` turns key presses into `CalculatorState`: the buffer, its live `value`, and after `=` either the `result` (with `evaluatedExpression`) or an `error`. It also handles continuing from a result, cursor moves, all-or-nothing `typeText` for paste, and M+ M− MS MR MC.
  - `MemoryNotifier` saves first, then updates its state. It refuses values of 10¹⁰⁰ or more.
- **presentation:**
  - `CalculatorView`: the layout (portrait column or landscape row; DEC-042) and hardware keyboard handling (digits, operators including `* x /`, Enter and `=`, Backspace, Escape and Delete for AC, arrows, Home, End, and Ctrl+V).
  - `CalculatorDisplay`: memory badge, evaluated expression, main line and preview/error line, built from `DisplayText` (DEC-043).
  - `CalculatorKeypad`: the 4×5 grid of `CalculatorButton`s. The decimal key shows the region's separator. Presses give a selection-click haptic; holding ⌫ clears, with a medium impact.
  - `CalculatorMemoryKeys`: the memory row (DEC-041).
  - `CalculatorDisplayFormatter`: turns units into display text in the region's format. It keeps a map from cursor positions to text offsets (for the caret and taps), brackets negative values after the start, puts a zero-width space after binary operators as the only line-break points, and builds the spoken text for screen readers.
- **Number format** (`lib/core/formatting/`, DEC-037): `LocalizedNumberFormat` reads the decimal separator, group separator and grouping sizes from `intl`'s data for the device locale (falling back to the language, then English). It formats locale-neutral number text: `formatTyped` (as typed, so `5.` keeps its point), `formatTypedWithOffsets`, `formatCanonical` (`−` and `×10ⁿ` superscripts), and `toPlainInput` for paste. `en_IN` groups as 12,34,567.

**Scientific input (Phase 5, Module 2, DEC-048; audited and fixed, DEC-049).** `ExpressionBuffer` also holds `^`, `!`, `π`, `e` and function openers (`sin(`, `sqrt(` …, one unit each, treated as open brackets), with `insertFactorial`, `insertConstant` and `insertFunction`; `CalculatorKey` has the matching keys (`CalculatorKey.function` names the `CalcFunction`). `CalculatorNotifier` reads `angleModeProvider` (`lib/features/settings/`, saved as `settings.angle_mode`) for every evaluation and listens to it, recomputing the live value/error when the mode changes. The formatter shows `√(`/`∛(` and speaks every new symbol. `backspace()` also removes a `×` left with no operand before it (an orphan a constant/function/value can leave behind when deleted), via `_withoutOrphanedTimes()` and a shared `_unitEndsOperand` helper — applies to inserted values too, not just scientific units. `ExpressionBuffer` also has three composite inserts for keys with no direct engine node: `insertPowerOf(digit)` (x²/x³, refused with no operand before the cursor), `insertPowerOfTen()`/`insertPowerOfE()` (10ˣ/eˣ, refused when an operand already starts right after the cursor) — see DEC-050.

**The scientific keypad (Phase 5, Module 3, DEC-050).** `ScientificCalculatorView` (`lib/features/calculator/presentation/`) is what `app_shell.dart` shows for `CalculatorMode.scientific` (previously `EmptyState`); it reuses `CalculatorDisplay`/`CalculatorMemoryKeys`/`CalculatorKeypad` exactly as Basic does, adding a DEG/RAD + 2nd toggle row and `ScientificFunctionTray` above the memory row (portrait), or stacked into Basic's existing display column (landscape — the keypad column is untouched). `CalculatorKey` gained `square`, `cube`, `powerOfTen`, `powerOfE` for the four composite keys. `lib/features/calculator/domain/scientific_keys.dart` is a pure-data table (`scientificKeyGroups`) of five key groups and the seven engine-backed 2nd/inverse pairs (sin↔asin, cos↔acos, tan↔atan, sqrt↔square, cbrt↔cube, log↔powerOfTen, ln↔powerOfE); keys with no engine-backed inverse (sinh, cosh, tanh, abs, `!`, π, e) are unaffected by 2nd. `CalculatorButton` gained an optional `selected` parameter (default `false`), toned with `AppColors.primary`/`onPrimary`, for the 2nd key's toggled-on state. 2nd's own on/off state is ephemeral widget state, not persisted.

### 1.14 Platforms

| Platform | Identity | Verification |
| --- | --- | --- |
| Android | `com.parasshakya.smartcalculator`, label "Smart Calculator"; the Kotlin package matches | APK builds, and it was tested on the user's phone (Android 15, 360 dp; see DEVELOPMENT_STATUS.md) |
| iOS | Bundle ID `com.parasshakya.smartcalculator` (tests: `.RunnerTests`), `CFBundleName` and `CFBundleDisplayName` "Smart Calculator" | Can't be built on Windows (P-5) |
| web, Windows, Linux, macOS | Template identifiers (DEC-025) | Not built. Not supported targets (DEC-004). |

### 1.15 Tests (1252 passed in the normal app run, plus 387 in the engine)

| File | Covers |
| --- | --- |
| `packages/calc_engine/test/*` | The engine (§1.12): 387 tests, run with `dart test` in the package |
| `test/features/calculator/domain/expression_buffer_test.dart` | 246 input-rule cases: numbers, operators, percent, brackets, the smart bracket key, backspace, editing at the cursor, values, limits, engine input, Phase 5's power/factorial/constants/functions groups, the orphaned-`×` backspace fix (DEC-049), and the x²/x³/10ˣ/eˣ composite inserts (DEC-050) |
| `test/features/calculator/domain/scientific_keys_test.dart` | 5 tests: every group is non-empty, no key is a primary twice, the seven engine-backed 2nd mappings, the unaffected keys stay unaffected, `keyFor(second: false)` always returns the primary (DEC-050) |
| `test/features/calculator/application/calculator_notifier_test.dart` | 66 tests: typing and preview, `=`, smart percent, continuing after a result, errors, editing in the middle (Phase 3 audit, 2026-09-28), the cursor, paste, and memory (including exactness and a restart) |
| `test/features/calculator/application/calculator_scientific_test.dart` | 46 tests: scientific keys through the notifier, the power-of composite keys (continuing vs. fresh, refused where there's no operand or one already follows), angle mode (default, live recompute, persistence, an answer already shown not recomputed), a 21-case wrong/impossible-input table, and two seeded fuzz tests (DEC-048, DEC-050) |
| `test/features/calculator/presentation/scientific_calculator_view_test.dart` | 10 tests: portrait and landscape layout (matching Basic's keypad width formula, Display kept to a sane minimum height), 200%-text at four sizes, the DEG/RAD and 2nd toggles' visible/semantic state, that 2nd swaps only the mapped keys (DEC-050) |
| `test/features/calculator/presentation/*` | The display formatter (25, including 7 scientific-expression cases: display glyphs, spoken text, error names), and the screen (24): keypad names and layout, haptics, display lines and their semantics, errors, tap-to-move, hold ⌫, region formats (en_IN, de_DE), the memory row, the keyboard and paste, and layouts at 200% text on phones and tablets, including landscape under a status bar |
| `test/core/formatting/localized_number_format_test.dart` | 33 tests: separators, grouping (en_US, en_IN, de_DE), fallbacks, scientific notation, offsets, paste |
| `test/app/app_test.dart` | The app starts in Basic mode with the calculator, the system theme and the app title; modes not built yet show an empty state |
| `test/app/shell/app_shell_test.dart` | Each window class's layout; the mode sheet grid (every mode, current one selected, switching); the rail; no bottom navigation; the shell and the mode sheet at 200% text; on a phone in landscape, no history panel and the rail scrolling |
| `test/app/navigation/app_navigator_test.dart` | Header actions push the typed routes; back returns |
| `test/app/theme/app_colors_test.dart` | WCAG contrast for all four palettes (AA, and AAA for high contrast) |
| `test/app/theme/app_theme_test.dart` | Each theme uses Manrope and carries its tokens; tabular figures on the number styles; the platform's high-contrast switch; reduced motion |
| `test/app/font_licenses_test.dart` | The fonts are bundled; Manrope's OFL is registered |
| `test/core/widgets/*` | Each component's behaviour, semantics, touch target, variants and colours, including high-contrast outlines, the confirmation results and loading states, and `CalculatorButton.selected` (announced, toned with the accent and distinguishable from the resting tone in all four themes — DEC-050) |
| `test/gallery/gallery_accessibility_test.dart` | Flutter's contrast, tap-target and label guidelines on every gallery section (12, since DEC-051 added "Converter"), in four themes |
| `test/features/settings/*` | The repository format and fallback; the theme choice surviving a restart; the angle mode falling back to degrees for an unrecognized stored value; the converter's last category, last unit pair and per-currency rate (DEC-051) |
| `test/core/persistence/app_database_test.dart` | Schema, reopening, provider lifecycle |
| `test/core/layout/window_size_class_test.dart` | Breakpoints |
| `test/architecture/layer_boundaries_test.dart` | The engine and domain layers stay free of Flutter |
| `test/features/history/data/sqflite_history_repository_test.dart` | Storage: adds, lists newest first, exact results, deletes one, clears all, an unrecognized stored mode falls back to basic |
| `test/features/history/application/history_notifier_test.dart` | The provider: starts empty, add/delete/clear update the state, a fresh container reloads what was saved |
| `test/features/history/presentation/history_content_test.dart` | The empty state, a computed result appearing, reuse (with and without a page to pop back to), search (including no matches), copy, delete, clear all with confirmation, the disabled clear-all button, the 3-action row (save, copy, delete) fits at 200% text |
| `test/features/saved_calculations/data/sqflite_saved_calculation_repository_test.dart` | Storage: adds, lists most recently updated first, exact results, rename (and that it re-sorts), deletes one, clears all |
| `test/features/saved_calculations/application/saved_calculations_notifier_test.dart` | The provider: starts empty, add/rename/delete/clear update the state, a fresh container reloads what was saved |
| `test/features/saved_calculations/presentation/saved_calculations_content_test.dart` | Saving a history entry (and that the save action requires a name), the empty state, reuse, rename, delete, search, clear all with confirmation, that switching tabs clears the search field |
| `test/features/converter/domain/conversion_category_test.dart` | 5 tests: `ConversionUnit.toBase`/`fromBase` on synthetic proportional and affine examples, `ConversionCategory.unit()` (found/throws) and `convert()` |
| `test/features/converter/domain/conversion_tables_test.dart` | 542 tests: temperature fixed points (0/100/−40°C↔°F↔K, both directions — the exact case that catches the offset-sign bug, DEC-051), exact integer cross-checks (mile/yd/ft, lb/oz, acre/ft², hectare/m², US gallon/in³, hour/day/week), per-unit round-trip and full pairwise round-trip (every unit × every other unit × back) across all six physical categories, all with a combined absolute+relative tolerance, and `currencyCategory` (USD fixed, rate conversion, rate-change reactivity, every id has a default and a symbol) |
| `test/features/converter/domain/number_entry_buffer_test.dart` | 18 tests: digits, decimal point, sign toggle (refused unless allowed), backspace/clear, `isEmpty`/`isNegative`/`value`, equality |
| `test/features/converter/application/converter_notifier_test.dart` | 13 tests: initial state, typing computes the result, decimal/backspace/clear, switching category resets to fresh units, selecting a unit, swap (units exchange, typed text unchanged), the sign toggle (refused outside temperature, `−40°C=−40°F` for it), currency (default rates, live rate edits, a non-positive rate refused), and persistence across a restart |
| `test/features/converter/presentation/converter_view_test.dart` | 14 tests: the whole screen — portrait/landscape layout and touch targets, 200%-text at four sizes, category switching, typing and the computed result, backspace, swap, the unit-picker sheet (open, search-filter, pick, no-matches), and the sign toggle enabled only for temperature (DEC-051) |
| `test/design_review/…` | The screenshot generator (skipped by default; §1.9) |

Helpers:

- `test/helpers/test_app.dart`: `pumpApp`, in-memory preferences, English strings
- `themed.dart`: `pumpThemed`
- `real_fonts.dart`: loads the fonts for screenshots
- `expression_text.dart`: an `ExpressionBuffer` as text with `|` for the cursor

### 1.16 How to extend the current code

- **Add or change a screen:** compose it from `lib/core/widgets/` and the tokens. If a needed widget is missing, add a reusable one to `core/widgets` (with tests and a gallery entry) rather than styling inline.
- **Add a colour role or text style:**
  1. Add it to `AppColors` (all four palettes, `copyWith`, `lerp`) or `AppTypography`.
  2. Add a contrast pair to `app_colors_test.dart`.
  3. Show it in the gallery.
- **Add a calculator mode:** add a value to `CalculatorMode`. The compiler then flags the icon and name switches. Add the mode's screen to `_CurrentModeView` in `app_shell.dart`.
- **Add a calculator key:** add it to `CalculatorKey`, handle it in `CalculatorNotifier.press` (and in `ExpressionBuffer` if it types a symbol), then add its `CalculatorButton` with a translated `semanticLabel`. Engine syntax changes go in the lexer, parser and evaluator, with table-driven tests.
- **Add a pushed page:** add a `final class` to `AppRoute` with a unique `name`, then add its case to `_pageFor`. Open it with `context.pushRoute`.
- **Add a preference:** add its key to `PreferenceKeys` and `PreferenceKeys.all`. Read and write it through a repository in the owning feature's data layer, storing fixed strings.
- **Change the database schema:** append a migration to `_migrations`. `schemaVersion` follows automatically. Add a test.
- **Add a string:** add it to `app_en.arb` with a description, then run `flutter pub get`.
- **Checks** (run from `smart_calculator/`):
  - `flutter analyze`
  - `dart format --set-exit-if-changed lib test packages`
  - `flutter test`
  - `dart test`, inside `packages/calc_engine`
  - `flutter build apk --debug`
  - after visual changes: the design-review screenshots (§1.9)
- **Add a database-backed feature:** a repository interface in `domain/`, a sqflite implementation in `data/` reading `appDatabaseProvider` (see `history/data/sqflite_history_repository.dart`), and an `AsyncNotifier` in `application/` for the loaded state. Give widget tests an isolated database the same way `test/helpers/test_app.dart` does for history: override `appDatabaseProvider` through `AppRoot.overrides`/`pumpApp` with `AppDatabase.open(..., singleInstance: false)` (DEC-045) — never wrap `AppRoot` in a second `ProviderScope`, which breaks its own overrides (DEC-045).
- **Add a conversion category:** add one `const ConversionCategory` to `conversion_tables.dart` (a list of `ConversionUnit(id, symbol, scale, offset)`, `offset` in base-unit terms — see §1.19/DEC-051 for the temperature offset-sign pitfall) and one value to `ConversionCategoryId`; the UI, persistence and math all pick it up with no other change. Add fixed-point and exact-integer-cross-check tests for its scale constants, not just a round-trip test (a round-trip test alone can't catch a wrong constant).

### 1.17 History (`lib/features/history/`, Phase 4)

- **domain:**
  - `HistoryEntry`: the row id, locale-neutral display text for what was typed, the exact result, the mode, and when.
  - `HistoryRepository`, the interface: `list`, `add`, `delete`, `clear`.
- **data:** `SqfliteHistoryRepository`, over the `history` table (schema v1, DEC-023). `expression` is locale-neutral text (`ExpressionBuffer.toCanonicalText()`, §1.13); `result` is stored exactly (`CalcValue.toStorageString()`); `mode` is a fixed string (`CalculatorModeStorage.storageId`, not the enum name, added to `app/modes/calculator_mode.dart`). None of this is re-parsed (DEC-044).
- **application:** `HistoryNotifier` (`AsyncNotifier<List<HistoryEntry>>`): loads on first read, and `add`/`delete`/`clear` update its state after the write succeeds.
- **presentation:** `HistoryContent`, used by both `HistoryPage` (pushed, on compact and medium windows) and `HistoryPanel` (always visible, on expanded windows), replacing their Phase 1 placeholders. It's a tab toggle (`AppChoiceGroup`, History/Saved, DEC-046) over two sections:
  - **`_HistorySection`:** a search field filtering the loaded list client-side, and a clear-all action (disabled when empty, confirmed with `showConfirmationDialog`); each entry shows the stored expression and the result in the region's format, with save (§1.18), copy (clipboard) and delete actions
  - tapping an entry inserts its exact result at the cursor via a new `CalculatorNotifier.useHistoryResult` (the same mechanism MR uses), then pops back to the calculator if there's a page to pop back to
  - empty states for no history at all, and for a search matching nothing
  - switching tabs resets the search field
- **Wiring into the calculator:** `CalculatorNotifier._evaluate()` adds a history entry after every successful `=` (not on an error), reading the current mode from `currentModeProvider`. This is the only change to `calculator/application/`; the approved calculator screen's layout is untouched.
- **Not built, by decision (DEC-044):** grouping by Today/Yesterday/earlier, paging, swipe-to-delete with Undo, a result "tape," a retention limit — all *(Proposed)* in ROADMAP.md, not required by Phase 4's "Done when" gate.

### 1.18 Saved calculations (`lib/features/saved_calculations/`, Phase 4)

A calculation the user chose to keep under a name, rather than one every `=` produces automatically. DEC-046 records why it's shaped this way and why it has no UI of its own on the calculator screen.

- **domain:**
  - `SavedCalculation`: the row id, the user's name, the same locale-neutral expression and exact result a history entry holds, and when it was created and last updated.
  - `SavedCalculationRepository`, the interface: `list`, `add`, `rename`, `delete`, `clear`.
- **data:** `SqfliteSavedCalculationRepository`, over the `saved_calculations` table (schema v1, DEC-023). `kind` is always the fixed string `'basic'` (no other calculator can produce one yet); `inputs_json` holds `{"expression": ..., "result": ...}`, encoded and decoded with `dart:convert`. Sorted most-recently-updated first; a rename updates `updated_at` too, so it moves to the top.
- **application:** `SavedCalculationsNotifier` (`AsyncNotifier<List<SavedCalculation>>`): loads on first read; `add`/`delete`/`clear` patch its state directly, `rename` re-fetches the list (simplest way to get the new sort order right).
- **presentation:**
  - The Saved tab of `HistoryContent` (`_SavedSection`, `_SavedTile`): its own search field and clear-all (independent of History's), an empty state, and a search-with-no-matches state.
  - Each entry shows its name, the result and the expression it came from; tapping it reuses the result exactly like a history entry; rename and delete actions sit beside it.
  - **Saving** is a third action on a *history* entry (`_HistoryTile`, a bookmark icon next to copy and delete): it opens `lib/features/saved_calculations/presentation/save_name_sheet.dart`'s `promptForName` (a bottom sheet with an `AppTextField`, its action disabled until the name is non-empty), also reused for renaming.
- **Not built, by decision (DEC-046):** editing a saved calculation's expression or result (only its name can change — see DEC-046 for why), and anything beyond `kind: 'basic'` (no other calculator produces a saved calculation yet).

### 1.19 Converters (`lib/features/converter/`, Phase 6)

Its own state (`converterProvider`, not `calculatorProvider` — DEC-013's reason for Basic/Scientific sharing state doesn't apply to a conversion, which has no expression, operators or memory recall). Full reasoning: DEC-051.

- **domain:**
  - `ConversionUnit`: `(id, symbol, scale, offset)`. `toBase(v) = v*scale + offset`, `fromBase(b) = (b-offset)/scale` — one affine transform covers every category, including temperature, whose `offset` is expressed in base-unit (Celsius) terms, not copied from the familiar `F = C×9/5+32` formula (that constant is `fromBase`'s, not `toBase`'s — DEC-051).
  - `ConversionCategory`: `id`, `units`, `allowsNegative` (true only for temperature); `unit(id)` (throws if unknown — every unit id used anywhere, typed or persisted, is checked against the live table before being trusted) and `convert(value, {from, to})`.
  - `conversion_tables.dart`: six `const ConversionCategory`s (length, weight, temperature, area, volume, time) with exact scale constants (`mile`/`yard`/`foot`/`inch` and `lb`/`oz` use the exact international definitions, so `1 mile = 5280 ft` and `1 lb = 16 oz` hold exactly); `currencyCategory(ratesPerUsd)`, a function (not `const`) building the currency category from live rates — USD fixed at `scale = 1`, every other currency's `scale = 1/rate`.
  - `NumberEntryBuffer`: a plain, cursor-free "one optionally-negative number" buffer (digit/decimal-point/sign-toggle/backspace/clear) — deliberately simpler than `ExpressionBuffer`, since a conversion's input has no grammar beyond that. `toggleSign(allowed:)` refuses the minus sign at the buffer level for every category except temperature, not just by hiding the key.
- **application:** `ConverterNotifier`/`ConverterState` — category, `fromUnitId`, `toUnitId`, the typed `amount`, and (for currency) the live `currencyRates` map. `table` resolves to the active category's live conversion table; `result` is `table.convert(...)` or null while nothing's typed. `swap()` exchanges `fromUnitId`/`toUnitId` only, leaving the typed text unchanged (re-typing the previous result would need its own number-to-text formatting, with its own edge cases — DEC-051). Persistence (last category, last from/to unit pair, each currency's rate) is folded directly into this notifier, reading/writing through `SettingsRepository` — no separate preferences notifier, since (unlike `AngleModeNotifier`) nothing else needs to read converter preferences (DEC-051).
- **presentation:**
  - `ConverterView`: the screen `app_shell.dart` renders for `CalculatorMode.converter`. One scrollable column in portrait; category picker and cards on the left, keypad on the right in landscape.
  - `CategoryPicker`: a wrapping `AppCard` grid, one tile per `ConversionCategoryId`, `selected` tint on the active one — not `AppChoiceGroup`, which falls back to a vertical radio list once labels stop fitting a segmented row (likely with 7 options).
  - `ConverterCard`: shows one side's amount and unit; tapping opens `unit_picker_sheet.dart`'s searchable bottom sheet (mirroring `history_content.dart`'s own search pattern). A non-USD currency unit also gets a small "edit rate" button opening a dialog (an `AppTextField` in an `AlertDialog` — `AppDialog` itself is message-only, so this one dialog is built directly rather than stretched to fit a form field).
  - `ConverterKeypad`: digits, `.`, ⌫ (held clears) and a ± key (enabled only where the category allows a negative amount), built directly from `CalculatorButton` — not `CalculatorKeypad`, which is wired to the main calculator's own notifier and grammar.
- **Reused as-is:** `AppCard`, `AppIconButton`, `showAppBottomSheet`/`AppTextField`, `CalculatorButton`, `LocalizedNumberFormat` (region-correct grouping/decimal separator for both the typed amount and the computed result).
- **Not built, by decision (DEC-051):** the imperial gallon (only the US gallon, id `gallonUs`); live/fetched currency rates (typed and persisted locally only); history integration (a conversion showing up in the History tab).

## 2. Confirmed Decisions

Decided by the user. The "Implemented" column reflects the state after Phase 4's History module.

| Area | Decision | Implemented | Record |
| --- | --- | --- | --- |
| Workflow | Phase by phase with approval gates | Process | DEC-001 |
| Material | `package:flutter/material.dart`; no `material_ui` | Yes | DEC-002 |
| Navigation | Plain `Navigator` with a typed route layer; no `go_router` | Yes (§1.5) | DEC-003 |
| Platforms | Android and iOS primary; other folders kept, unsupported | Yes | DEC-004 |
| App identity | `com.parasshakya.smartcalculator`, "Smart Calculator" | Yes, on Android and iOS | DEC-005 |
| Version control | Local Git, `main`, never push | Yes | DEC-006 |
| State management | Riverpod 3 without code generation | Foundation (§1.4) | DEC-007 |
| Calculation engine | Pure-Dart `packages/calc_engine`; numeric library hidden; exact arithmetic | Yes, for the basic calculator (§1.12; `rational` only, DEC-038) | DEC-008 |
| Persistence | `SharedPreferencesWithCache` for settings; `sqflite` for history and saved calculations | Preferences: theme and calculator memory (§1.10). Database: both tables implemented (§1.17, §1.18). | DEC-009 |
| Testing | 200+ engine tests before the calculator UI counts as complete; unit, widget and integration tests | Engine gate met (260 engine tests); 464 app tests; no integration tests yet | DEC-010 |
| UI/UX | "Quiet precision" | Design system (§1.7–1.9), approved; used by the calculator | DEC-011 |
| Navigation UX | Phones: mode pill and sheet, no bottom nav. Tablets and landscape: rail and history panel | Yes (§1.6); the panel is hidden below 480 dp of height (DEC-042) | DEC-012 |
| Shared state | Basic and scientific share one calculator state | Prepared: one `calculatorProvider`, used by Basic; Scientific comes in Phase 5 | DEC-013 |
| Privacy | Offline first and privacy first | Partly (§3.10) | DEC-014 |
| Dependencies | Verify before adding | Applied; Phase 3 added `rational` and `test` to the engine | DEC-015 |
| Phase 1 scope | Foundation only | Yes | DEC-016 |
| Reusable widgets | Screens use only the shared components and tokens | Yes (§1.2, §1.8); the calculator added `DisplayText` and a memory key kind (DEC-043) | DEC-034 |
| Percent | Smart percent: `50+10%` = 55, `50×10%` = 5 | Yes (§1.12) | DEC-036 |
| Number format | Follows the device region (12,34,567.89 on an India-region phone) | Yes (§1.13) | DEC-037 |
| History | Stores the exact result and locale-neutral text; reuse inserts the result, like MR | Yes (§1.17) | DEC-044 |
| Saved calculations | A History/Saved tab toggle; saving is a history-entry action, not new UI on the calculator screen; "rename" is "edit" for now | Yes (§1.18) | DEC-046 |

## 3. Proposed Architecture (target design — NOT implemented yet)

### 3.1 Target folders still to come

These folders don't exist yet:

- `core/services/`, `core/extensions/`, `core/utils/`
- the scientific keypad inside `features/calculator/`, sharing its state (Phase 5)
- `features/programmer/`, `saved/`, `converter/`, `finance/`, `date_calculator/`
- `integration_test/`

Each feature has `domain/` (pure Dart), `data/`, `application/` and `presentation/`, as the settings feature does now.

### 3.2 Navigation still to come

- **Pages to add:** saved calculations, the settings subpages (About, licenses, privacy) and the finance tools.
- **Android predictive back gesture:** not scheduled yet (see ROADMAP.md).

### 3.3 Calculation engine: still to come (later phases)

The scientific engine (functions, `^`, exact/approximate values, angle mode, the P-6 defaults, §1.12, DEC-047), the input logic (§1.13, DEC-048/049) and the keypad (§1.13, DEC-050) are all built and tested — Phase 5 is complete. Still to come:

- **Undefined-result messaging in the app:** `CalcError.undefined` has a generic translated message (`errorUndefined`) for now; whether specific domain errors (asin out of range vs. tan at 90°) deserve their own wording is a future-phase question, not an engine one.
- **Programmer mode:** a separate `BigInt` evaluator with a set word size and two's complement.

### 3.4 State (Phase 4 onward)

- `AsyncNotifier` for persisted lists. **Done:** `HistoryNotifier` and `SavedCalculationsNotifier` (§1.17, §1.18).
- The keypad already rebuilds only when the number format changes; keep new keypads that way.

### 3.5 Persistence still to come

- Paged queries.
- A history retention limit and an off switch (values not decided).
- Saved calculations reopening the right *tool* from `kind` plus `inputs_json` (Phase 7 and later): only `kind: 'basic'` exists so far (§1.18), which just reuses the result; a future kind's own screen reopening from its saved inputs is still to come.
- The last mode in preferences. Right now the current mode isn't persisted (DEC-021). The memory already is (§1.10).
- If desktop is ever wanted, only the database setup would need a desktop SQLite driver.

### 3.6 Design system: still to come

- **In-app switches** (Phase 10): high contrast, "larger buttons", and possibly haptics on or off. Today high contrast follows only the platform setting, and haptics are always on.
- **Programmer mode font** (Phase 9): JetBrains Mono, which must be re-verified and bundled first (DEC-028).
- **Icon scaling review** (Phase 11): icons follow the platform and don't grow with text size.

### 3.7 Localization still to come

Date formatting through `intl` (Phase 8). Numbers already follow the device region (§1.13).

### 3.8 Planned dependencies not added yet

Each must be re-verified before it is added (DEC-015).

| Package | When | Purpose |
| --- | --- | --- |
| `integration_test` (SDK) | When the first end-to-end flow exists | Integration tests |
| `package_info_plus` | Phase 10, if chosen (P-7) | App version on the About screen |
| `http` | Only if live currency rates are approved | Currency service |

### 3.9 Platform configuration still to come

- **Release signing:** the release build is still signed with the debug key; not scheduled yet.
- **Android predictive back:** not scheduled yet.
- **Web and desktop identifiers:** unchanged (DEC-025).

### 3.10 Privacy checks

- **Plan:** the release app requests no INTERNET permission.
- **Actual:** fonts are bundled, not downloaded. For the release manifest check, see DEVELOPMENT_STATUS.md.

## 4. Pending Decisions

The decisions that affect architecture (full list: [DEVELOPMENT_STATUS.md](DEVELOPMENT_STATUS.md#pending-decisions)):

- **P-6 (rest):** the power and trigonometry defaults, before Phase 5. Percent is settled (DEC-036).
- **P-7:** where the app version comes from (Phase 10).
- **P-9:** Windows Developer Mode (symlinks), which affects `flutter pub get` on this machine.
- **P-10:** Kotlin incremental compilation across drives.

**Not decided at all yet:** the history retention default; the currency-rate service beyond "behind a service interface, no committed keys"; the release signing setup; the scientific keys in landscape (Phase 5).

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
| A variable font; a separate "accent" colour role | DEC-028, DEC-029 |
| Separate PrimaryButton, SecondaryButton and OperatorButton classes | DEC-030 |
| Outlined-style borders on filled text fields | DEC-031 |
| The gallery as an in-app route; committed golden images | DEC-032, DEC-033 |
| `decimal` alongside `rational` in the engine | DEC-038 |
| Implied multiplication binding tighter than `÷`; inserting results as rounded digits; clearing the expression on an error | DEC-039, DEC-040 |
| Memory keys in a "more" menu; an empty "more" menu | DEC-041 |
| `FittedBox` scaling of the whole display; memory keys as `AppButton`s | DEC-043 |
