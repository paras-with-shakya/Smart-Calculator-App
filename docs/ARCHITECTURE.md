# Architecture

> **Status (2026-09-28): nothing in this document is implemented yet, except §1.** The code is still the `flutter create` template.
>
> - §2 lists what the user has **confirmed**.
> - §3 is the **proposed** target design from the Final Architecture Decision Report (2026-09-28), which the user approved as a whole. It is not yet built, and details may be refined during implementation, but any refinement must be explained first.
> - §4 lists what is still **pending**.
>
> The reasons behind decisions are in [DECISIONS.md](DECISIONS.md). When something gets built, move it into §1 and describe what the code actually does.

## 1. Implemented (actual state of the code)

This is the untouched `flutter create` template, verified 2026-09-28:

```text
smart_calculator/
├── pubspec.yaml            # flutter, cupertino_icons; dev: flutter_test, flutter_lints
├── analysis_options.yaml   # flutter_lints recommended set; platform dirs excluded
├── lib/main.dart           # counter demo: MyApp → MaterialApp → MyHomePage (setState)
├── test/widget_test.dart   # counter smoke test
├── android/ ios/ web/ windows/ linux/ macos/   # template platform folders
├── CLAUDE.md               # project-memory entry point (docs only)
└── docs/                   # project-memory system (docs only)
```

What the template does **not** have:

- state management, routing, a theme system, localization or persistence
- assets, services or packages
- Git

## 2. Confirmed Decisions

All of these were decided by the user on 2026-09-28. None is implemented yet.

| Area | Decision | Record |
| --- | --- | --- |
| Workflow | Phase by phase with approval gates; a per-module QA loop | DEC-001 |
| Material | Keep `package:flutter/material.dart`; **no `material_ui`** | DEC-002 |
| Navigation mechanism | **Plain `Navigator` plus our own typed route layer; no `go_router` for now** | DEC-003 |
| Platforms | Android and iOS are primary; web and desktop folders are kept but not supported or tested | DEC-004 |
| App identity | ID `com.parasshakya.smartcalculator`, display name "Smart Calculator". When to apply it is PENDING (P-3). | DEC-005 |
| Version control | Local Git in `smart_calculator/`, branch `main`, a scaffold baseline commit, commits per phase, never push | DEC-006 |
| State management | Riverpod 3 (`flutter_riverpod`) **without code generation** | DEC-007 |
| Calculation engine | A separate pure-Dart package, `packages/calc_engine`, that can't import Flutter; `decimal`/`rational` hidden behind our own types; exact arithmetic where practical | DEC-008 |
| Persistence | `SharedPreferencesWithCache` for settings; `sqflite` for history and saved calculations | DEC-009 |
| Testing | More than 200 engine edge-case tests before the calculator UI counts as complete; unit, widget and integration tests | DEC-010 |
| UI/UX | The "quiet precision" direction (see PROJECT_MEMORY.md) | DEC-011 |
| Navigation UX | Phones: a mode pill and mode sheet, no bottom nav. Tablets and landscape: a navigation rail and a history side panel | DEC-012 |
| Shared state | Basic and scientific share one expression, memory and history state | DEC-013 |
| Privacy | Offline first and privacy first | DEC-014 |
| Dependencies | Verify compatibility and maintenance before adding any package | DEC-015 |
| Phase 1 scope | Foundation only (see ROADMAP.md) | DEC-016 |

## 3. Proposed Architecture (target design — NOT implemented)

### 3.1 Repository layout

```text
smart_calculator/                      ← planned Git root
├── pubspec.yaml                       ← app package + pub workspace root
├── packages/
│   └── calc_engine/                   ← pure Dart (no Flutter); public API exposes only our own types
│       └── lib/src/  lexer/ parser/ ast/ eval/ functions/ number/ format/ errors/
├── lib/
│   ├── main.dart                      ← startup only: preload prefs → ProviderScope → app
│   ├── app/        app.dart · navigation/ (typed routes) · theme/ · modes/ (mode registry)
│   ├── l10n/       ARB files (gen-l10n); English first; every visible string from day one
│   ├── core/       widgets/ (design system) · persistence/ · services/ · layout/ · extensions/ · utils/
│   └── features/
│       ├── calculator/       ← basic + scientific + memory (shared expression state)
│       ├── programmer/  history/  saved/  converter/  finance/  date_calculator/  settings/
│       └── (each feature)    domain/ (pure Dart) · data/ · application/ (notifiers) · presentation/
├── test/                              ← mirrors lib/
├── integration_test/
├── docs/                              ← project memory + architecture
└── android/ ios/ web/ windows/ linux/ macos/   ← all kept
```

This departs from the folder structure in the master prompt in three ways. Each was explained and then approved:

- The engine is its own package, so the compiler enforces its independence from the UI.
- An `application/` layer holds the notifiers.
- Scientific lives inside `calculator/`, because the two share state.

### 3.2 Layers

- Dependencies point one way: **presentation → application → domain ← data.**
- **Domain** code is plain Dart and never imports Flutter.
- **Widgets** only render state and pass user input on to the application layer.
- **Repository interfaces** live in domain; their implementations live in data.

### 3.3 Startup

`main.dart` does only three things:

1. Initializes the bindings.
2. Preloads `SharedPreferencesWithCache`, so the correct theme shows on the very first frame with no flash.
3. Runs the app inside `ProviderScope`, with the preloaded instance passed in as a provider override.

### 3.4 Navigation (mechanism CONFIRMED; details proposed)

- **Typed routes.** A small in-house route layer over plain `Navigator`: routes are typed classes, not string paths. All navigation goes through this one layer, so switching to go_router later (if deep links or web are ever needed) is a contained change.
- **Modes aren't routes.** Switching calculator modes changes app state; it doesn't navigate.
- **Pushed pages.** Only full-screen pages are pushed: history, saved calculations, settings and its subpages (About, licenses, privacy) and the finance tools.
- **Adaptive shell** (Material window size classes: compact, medium, expanded):
  - Phones: a mode pill in the header opens the mode sheet. No bottom bar.
  - Tablets and landscape: a navigation rail, with history in a side panel.
- **Mode registry.** The mode sheet and the navigation rail are both built from one list of modes (Basic, Scientific, Programmer, Finance, Converter, Date). Adding a mode means one entry plus its screen.
- **Android.** Enable the predictive back gesture in the manifest.

### 3.5 State management (library CONFIRMED; patterns proposed)

- **Library:** Riverpod 3, using `Notifier` and `AsyncNotifier`, with no `riverpod_generator` or `build_runner`.
- **Narrow rebuilds:** `ref.watch(provider.select(...))` means a keystroke rebuilds only the display. The keypad is `const` and never rebuilds.
- **Dependency injection:** provider overrides act as DI, so tests swap in in-memory fakes. No `get_it`, no mocking package.
- **No automatic retry:** Riverpod 3's automatic retry is **disabled app-wide** (`retry` returns `null`), so errors are deterministic.
- **Calculation errors are values:** the engine returns them as ordinary result values, not exceptions.

### 3.6 Calculation engine (package and number isolation CONFIRMED; internals proposed)

- **Pipeline:** tokenize → precedence-aware parse → syntax tree → evaluate with settings (angle mode, precision) → format.
- **Types:**
  - `CalcValue` holds either an exact fraction or an approximate double.
  - `CalcResult` is either a success or a typed `CalcError`.
  - `decimal` and `rational` are used **only inside `src/number/`**, so replacing them later touches only that folder.
- **Error types:** a fixed set — syntax, incomplete, divide by zero, invalid function input, undefined, overflow. Each maps to a translated message, so `NaN`, `Infinity` and `null` can never reach the screen. Size limits prevent freezes on inputs like `9^9^9`.
- **Functions:** kept in a registry. Adding a new one (for example nCr) is a registry entry plus a key, with no parser changes.
- **Editing model:** the expression is a list of tokens plus a cursor, not a raw string.
  - Backspace removes `sin(` as one unit.
  - The cursor moves by token.
  - Pasted text goes through the tokenizer.
- **Live preview:** runs on every keystroke and closes open brackets automatically. It appears only when the expression is valid; errors show only after `=`.
- **Programmer mode:** a separate whole-number evaluator (`BigInt`) with a set word size and two's complement. It reuses the tokenizer and parser with its own operator table.
- **Default behaviours:** PENDING confirmation (P-6); the table is in PROJECT_MEMORY.md.

### 3.7 Persistence (libraries CONFIRMED; schema proposed)

| Data | Storage |
| --- | --- |
| Settings, theme, memory value, last mode | `SharedPreferencesWithCache`, preloaded before the first frame |
| History, saved calculations | `sqflite`, schema v1, with version-based migrations |

- **Tables:**
  - `history`: expression, result, timestamp, mode
  - `saved_calculations`: `kind` plus the inputs as JSON, so "reuse" or "edit" reopens the right tool already filled in
- Both tables get date indexes.
- **Queries:** paged, so long histories stay fast.
- **Privacy:** history has a retention limit and an off switch. The values are not yet decided.
- **Testing:** database tests use in-memory SQLite (`sqflite_common_ffi`); notifier tests use fakes.
- **Desktop:** if desktop is ever wanted, only the database setup (one place) would need a desktop SQLite driver.

### 3.8 Theme and design system (direction CONFIRMED; tokens proposed)

- **Tokens** are converted into `ThemeData` plus `ThemeExtension`s:
  - colour roles (primary, secondary, background, surface, card, text, muted text, accent, success, warning, error, divider, operator keys, number keys)
  - typography (display, expression, result, heading, body, caption, button, label)
  - spacing (xs to xxl)
  - radius
  - motion
- **Themes:** light, dark and system, plus high-contrast variants. Colour contrast is checked in Phase 2.
- **Palette:** warm neutrals ("porcelain" in light mode, "graphite" in dark) with one "iris" violet accent, used sparingly: on `=`, the active mode and the final result.
- **Keys:** squircle shape (`RoundedSuperellipseBorder`, confirmed present in this SDK) in three tones:
  - digits on a plain surface
  - operators on a tinted surface with an accent symbol
  - `=` as the only solid-colour key
- **Components** (Phase 2): the master prompt's list minus `AppBottomNavigation`, which was dropped by DEC-012. There is also a debug-only gallery screen for the design review.
- **Phase 1** builds only the *basic theme structure* and the light/dark/system setting, which persists.

### 3.9 Localization (CONFIRMED for Phase 1; details proposed)

- `flutter_localizations` plus `intl`, with gen-l10n ARB files in `lib/l10n/`.
- English first. Every user-visible string goes through l10n from day one.
- Numbers and dates are formatted through `intl`.

### 3.10 Platform configuration

- **Release manifest:** requests no INTERNET permission. Keep it that way.
- **iOS:** the planned plugins (`shared_preferences`, `sqflite`) support Swift Package Manager (checked 2026-09-28). The iOS configuration must stay correct even though it can't be built here.
- **Identifiers:** see DEC-005 and P-3.

### Dependencies (planned)

These were verified on 2026-09-28 in a scratch project: each resolved at its latest version on Flutter 3.47.5 / Dart 3.13.4 and passed a runtime smoke test. They are **not installed yet**. Re-verify each one when adding it (DEC-015).

| Package | Version | Scope | Purpose | Publisher / maintenance |
| --- | --- | --- | --- | --- |
| `flutter_riverpod` | ^3.4.3 | app | State and DI | dash-overflow.net (verified); 14 releases in the past year |
| `shared_preferences` | ^2.5.5 | app | Settings | flutter.dev (verified) |
| `sqflite` | ^2.4.4 | app | History, saved calculations | tekartik.com (verified) |
| `path` | ^1.9.1 | app | Database path | dart.dev (verified) |
| `intl` | `any` (SDK-pinned) | app | Number and date formatting | dart.dev (verified) |
| `flutter_localizations` | SDK | app | Translations | SDK |
| `decimal` | ^3.2.6 | engine only | Exact arithmetic | Single maintainer, no verified publisher; repo active 2026-07. It is wrapped so it can be swapped. |
| `rational` | ^2.2.3 | engine only | Fraction type (must be a direct dependency) | Same author; stable |
| `sqflite_common_ffi` | ^2.4.3 | dev | In-memory SQLite in tests | tekartik.com (verified) |
| `flutter_test`, `integration_test` | SDK | dev | Widget and integration tests | SDK |
| `flutter_lints` | ^6.0.0 | dev | Lints (to be made stricter) | Already present |
| `test` | SDK-compatible | engine dev | Engine unit tests | dart.dev |

**To remove in Phase 1:** `cupertino_icons` (unused).

**Deferred:** `package_info_plus` (P-7, Phase 10); `http`, until live currency rates exist.

## 4. Pending Decisions

The decisions that affect architecture (full list: [DEVELOPMENT_STATUS.md](DEVELOPMENT_STATUS.md#pending-decisions)):

- **P-3:** when the app ID and display name change is applied (it touches the Android namespace and folder, and the iOS bundle ID).
- **P-6:** the engine's default behaviours (percent rules, power associativity, `0^0` and similar).
- **P-7:** where the app version comes from (`package_info_plus` or a build-time constant).
- **P-8:** which fonts to use.

**Not decided at all yet:** the history retention default; the currency-rate service design beyond "behind a service interface, no committed keys"; the release signing setup.

## 5. Rejected Alternatives (summary)

See [DECISIONS.md](DECISIONS.md) for the full reasoning.

| Rejected | Instead | Record |
| --- | --- | --- |
| `material_ui` | framework Material | DEC-002 |
| `go_router` 18 | typed Navigator layer | DEC-003 |
| Deleting the web and desktop folders | keep them unsupported | DEC-004 |
| `drift` for a web demo | — | DEC-004 |
| Bloc, Provider, `get_it`, code generation | — | DEC-007 |
| `math_expressions` or string evaluation | — | DEC-008 |
| Hive, Isar, drift, SharedPreferences for history | — | DEC-009 |
| Bottom navigation bar | — | DEC-012 |
| `google_fonts`, `fl_chart`, `freezed`, `json_serializable`, analytics, audio/vibration packages | — | DEC-015 |
