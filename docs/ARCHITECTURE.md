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
| `appDatabaseProvider` | `FutureProvider<Database>` | core/persistence | Opened on first read, closed on dispose. It has no consumers until Phase 4. |

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
- **Accessibility checks:** `test/gallery/gallery_accessibility_test.dart` runs Flutter's `textContrastGuideline`, `androidTapTargetGuideline` and `labeledTapTargetGuideline` over every gallery section in all four themes (40 tests).
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

### 1.12 Calculation engine (`packages/calc_engine`, Phase 3)

Pure Dart; the app depends on it by path. Dependencies: `rational` ^2.2.3, and `test` ^1.31.1 for development (DEC-038).

- **API** (`lib/calc_engine.dart` exports only these): `CalcEngine().evaluate(expression, variables: {...})` returns a `CalcResult`, which is either `CalcSuccess(CalcValue)` or `CalcFailure(CalcError)`. `CalcError` is empty, syntax, incomplete, divisionByZero or overflow. Nothing throws to the caller.
- **`CalcValue`** (`src/number/`, the only place that imports `rational`): an exact fraction. It offers `+ − × ÷` and negation, `isZero`, `isTooLarge` (10¹⁰⁰ or more), `CalcValue.parse` for decimal literals, and `toStorageString` / `tryParseStorage` (`n` or `n/d`) for saving values exactly. `toDecimalString()` gives the canonical text: 12 significant digits, half away from zero, `d.ddde±N` from 10¹² up and below 10⁻⁶, never `-0`.
- **Pipeline:**
  1. `src/lexer`: characters → tokens. It accepts digits and `.`, letters (variable names), `+ − × ÷` and `- * /`, `%`, brackets and spaces.
  2. `src/parser`: recursive descent → a sealed `Node` tree (number, variable, negate, percent, binary). Precedence: unary minus, then `%`, then `× ÷` and implied multiplication, then `+ −`.
  3. `src/eval`: evaluates the tree exactly, with smart percent (DEC-036), and checks every intermediate value for overflow.
- **Limits:** 100 nested brackets and 1000 tokens (DEC-039).
- **Variables** carry exact values into an expression: the app passes results and the memory as letter-only names (§1.13).
- **Tests** (`dart test` in the package): 260. They are 224 table-driven cases (numbers, malformed input, each operator, precedence, brackets, implied multiplication, unary minus, smart percent, exactness, division by zero, incomplete input, large and small numbers, overflow, variables), plus `CalcValue` tests and a 20,000-input fuzz test with a fixed seed.

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

### 1.14 Platforms

| Platform | Identity | Verification |
| --- | --- | --- |
| Android | `com.parasshakya.smartcalculator`, label "Smart Calculator"; the Kotlin package matches | APK builds, and it was tested on the user's phone (Android 15, 360 dp; see DEVELOPMENT_STATUS.md) |
| iOS | Bundle ID `com.parasshakya.smartcalculator` (tests: `.RunnerTests`), `CFBundleName` and `CFBundleDisplayName` "Smart Calculator" | Can't be built on Windows (P-5) |
| web, Windows, Linux, macOS | Template identifiers (DEC-025) | Not built. Not supported targets (DEC-004). |

### 1.15 Tests (408 in the normal app run, plus 260 in the engine)

| File | Covers |
| --- | --- |
| `packages/calc_engine/test/*` | The engine (§1.12): 260 tests, run with `dart test` in the package |
| `test/features/calculator/domain/expression_buffer_test.dart` | 140 input-rule cases (numbers, operators, percent, brackets, the smart bracket key, backspace, editing at the cursor, values), limits, engine input |
| `test/features/calculator/application/calculator_notifier_test.dart` | 61 tests: typing and preview, `=`, smart percent, continuing after a result, errors, editing in the middle (Phase 3 audit, 2026-09-28), the cursor, paste, and memory (including exactness and a restart) |
| `test/features/calculator/presentation/*` | The display formatter (18), and the screen (24): keypad names and layout, haptics, display lines and their semantics, errors, tap-to-move, hold ⌫, region formats (en_IN, de_DE), the memory row, the keyboard and paste, and layouts at 200% text on phones and tablets, including landscape under a status bar |
| `test/core/formatting/localized_number_format_test.dart` | 33 tests: separators, grouping (en_US, en_IN, de_DE), fallbacks, scientific notation, offsets, paste |
| `test/app/app_test.dart` | The app starts in Basic mode with the calculator, the system theme and the app title; modes not built yet show an empty state |
| `test/app/shell/app_shell_test.dart` | Each window class's layout; the mode sheet grid (every mode, current one selected, switching); the rail; no bottom navigation; the shell and the mode sheet at 200% text; on a phone in landscape, no history panel and the rail scrolling |
| `test/app/navigation/app_navigator_test.dart` | Header actions push the typed routes; back returns |
| `test/app/theme/app_colors_test.dart` | WCAG contrast for all four palettes (AA, and AAA for high contrast) |
| `test/app/theme/app_theme_test.dart` | Each theme uses Manrope and carries its tokens; tabular figures on the number styles; the platform's high-contrast switch; reduced motion |
| `test/app/font_licenses_test.dart` | The fonts are bundled; Manrope's OFL is registered |
| `test/core/widgets/*` | Each component's behaviour, semantics, touch target, variants and colours, including high-contrast outlines, the confirmation results and loading states |
| `test/gallery/gallery_accessibility_test.dart` | Flutter's contrast, tap-target and label guidelines on every gallery section, in four themes |
| `test/features/settings/*` | The repository format and fallback; the theme choice surviving a restart |
| `test/core/persistence/app_database_test.dart` | Schema, reopening, provider lifecycle |
| `test/core/layout/window_size_class_test.dart` | Breakpoints |
| `test/architecture/layer_boundaries_test.dart` | The engine and domain layers stay free of Flutter |
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

## 2. Confirmed Decisions

Decided by the user. The "Implemented" column reflects the state after Phase 3.

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
| Persistence | `SharedPreferencesWithCache` for settings; `sqflite` for history and saved calculations | Preferences: theme and calculator memory (§1.10). Database: schema only. | DEC-009 |
| Testing | 200+ engine tests before the calculator UI counts as complete; unit, widget and integration tests | Engine gate met (260 engine tests); unit and widget tests; no integration tests yet | DEC-010 |
| UI/UX | "Quiet precision" | Design system (§1.7–1.9), approved; used by the calculator | DEC-011 |
| Navigation UX | Phones: mode pill and sheet, no bottom nav. Tablets and landscape: rail and history panel | Yes (§1.6); the panel is hidden below 480 dp of height (DEC-042) | DEC-012 |
| Shared state | Basic and scientific share one calculator state | Prepared: one `calculatorProvider`, used by Basic; Scientific comes in Phase 5 | DEC-013 |
| Privacy | Offline first and privacy first | Partly (§3.10) | DEC-014 |
| Dependencies | Verify before adding | Applied; Phase 3 added `rational` and `test` to the engine | DEC-015 |
| Phase 1 scope | Foundation only | Yes | DEC-016 |
| Reusable widgets | Screens use only the shared components and tokens | Yes (§1.2, §1.8); the calculator added `DisplayText` and a memory key kind (DEC-043) | DEC-034 |
| Percent | Smart percent: `50+10%` = 55, `50×10%` = 5 | Yes (§1.12) | DEC-036 |
| Number format | Follows the device region (12,34,567.89 on an India-region phone) | Yes (§1.13) | DEC-037 |

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

### 3.3 Calculation engine: still to come (Phase 5 and later)

The basic engine is built (§1.12). Still to come:

- **Functions** (Phase 5): kept in a registry, so a new one needs no parser changes. It was not built in Phase 3, which has no functions to register. The parser gets a function-call node when the first function arrives.
- **Irrational results:** `CalcValue` gains an approximate form (such as a double) for roots and trigonometry, and settings (angle mode, precision) reach the evaluator.
- **More errors:** invalid function input and undefined (such as `tan 90°`), each with a translated message.
- **Editing:** backspace removes a function name such as `sin(` as one unit.
- **Programmer mode:** a separate `BigInt` evaluator with a set word size and two's complement.
- **Default behaviours still open (P-6):** `−3²`, `2^3^2`, `0^0`, `(−8)^(1/3)`, `tan 90°`.

### 3.4 State (Phase 4 onward)

- `AsyncNotifier` for persisted lists.
- The keypad already rebuilds only when the number format changes; keep new keypads that way.

### 3.5 Persistence still to come

- The history and saved-calculation repositories (Phase 4). Their interfaces go in domain; the sqflite implementations go in data.
- Paged queries.
- A history retention limit and an off switch (values not decided).
- Saved calculations reopen the right tool from `kind` plus `inputs_json`.
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
