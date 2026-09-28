# Smart Calculator — Project Memory

This file holds the stable, long-lived facts about the project. Current status is in [DEVELOPMENT_STATUS.md](DEVELOPMENT_STATUS.md), and the reasons behind decisions are in [DECISIONS.md](DECISIONS.md).

**Sources:** the user's master prompt and the approval messages of 2026-09-28, the Phase 0 audit and the Final Architecture Decision Report (2026-09-28), and direct inspection of the repository. Anything still open is marked **PENDING**.

## Project Identity

| Item | Value | Status |
| --- | --- | --- |
| Product name | Smart Calculator | CONFIRMED |
| Flutter package name | `smart_calculator` | Implemented (template) |
| Location | `D:\Flutter App Developement\SmartCalculator\smart_calculator` | Implemented |
| Application ID | `com.parasshakya.smartcalculator` | CONFIRMED, **not applied yet**. The code still uses `com.example.*`, and the timing is PENDING (see DEVELOPMENT_STATUS P-3). |
| Display name | Smart Calculator | CONFIRMED, not applied yet on Android (label is `smart_calculator`). iOS `CFBundleDisplayName` is already "Smart Calculator". |
| Version | `1.0.0+1` | Template default |
| Purpose | A production-quality, portfolio-level Flutter project | CONFIRMED |

## Project Goal

Build a premium, modern, feature-rich Smart Calculator app in Flutter. It should have excellent UI/UX, clean architecture, reusable components, smooth animations, strong usability, accessibility, responsive layouts and maintainable code. It should be strong enough to serve as a portfolio-level project that demonstrates production engineering practices.

## Product Vision

It should feel like *"a complete Smart Calculator product built professionally with Flutter"*, not *"just another calculator app."* The design aim is **Premium + Minimal + Smart + Professional + Fast**, with an original visual identity that copies no existing calculator app.

**Core UX rule:** OPEN APP → START CALCULATING → GET RESULT, with minimum friction. Advanced features should be discoverable without making the basic calculator complicated.

**Planned capabilities** (none implemented yet; the order is in [ROADMAP.md](ROADMAP.md)):

- basic calculator, with expression editing, live preview and memory (MC, MR, M+, M−, MS)
- scientific calculator
- history and saved calculations
- unit converter, plus an architecture for currency conversion (no network yet)
- financial calculators
- date calculator
- programmer calculator
- settings, themes (light, dark, system), accessibility, localization-ready architecture

The architecture must allow new calculator modes, converters and tools to be added without rewriting the core.

## Target Platforms

| Platform | Status |
| --- | --- |
| Android | **Primary.** Can be built on this machine. |
| iOS | **Primary.** Can't be built or run on Windows. It stays correct by design but unverified until a Mac is available (PENDING P-5). |
| web, Windows, Linux, macOS | Folders **kept** but **not supported or tested** targets. Do not delete them. |

## Current Flutter/Dart Environment

Verified 2026-09-28 with `flutter --version` and the project files.

| Item | Value |
| --- | --- |
| Flutter | 3.47.5, channel stable, framework revision `6a19cca564` (2026-09-17) |
| Dart | 3.13.4 |
| DevTools | 2.60.0 |
| pubspec SDK constraint | `^3.13.4` |
| Android build | AGP 9.1.0, Kotlin 2.4.0, Gradle 9.3.1, Java/JVM target 17; Android SDK 36.1.0 (`flutter doctor`) |
| iOS deployment target | 15.0 |
| Host | Windows 11 Pro (10.0.26200); Git 2.55.0 |

Machine limits:

- No real Python (the `python` on PATH is the Microsoft Store stub).
- No Visual Studio, so no Windows desktop builds.
- No Android emulators exist.
- A USB Android device was seen connected on 2026-09-28 (see DEVELOPMENT_STATUS P-4).

## Engineering Principles

From the master prompt:

- Flutter-first, mobile-first, production quality: modular, scalable, maintainable, reusable, testable, responsive, accessible, fast, offline-first where possible.
- Strong typing and null safety. Small widgets, single responsibility, composition, clear naming, immutable models where appropriate, and documentation for complex logic.
- **Avoid:** `dynamic` without a real need, giant widgets or functions, duplicate logic, magic numbers and strings, hardcoded colours and dimensions, business logic in UI.
- **File creation rule:** before creating a file, check whether an existing component, service or utility can be extended. Never duplicate buttons, cards, dialogs, utilities, calculation logic, constants or theme definitions.
- **Think like a senior engineer.** If the analysis shows a better solution, explain the issue, the proposal and why it is better *before* implementing it. No risky architectural changes are made silently.
- Never hide errors. Never suppress warnings without a legitimate, documented reason.

## Architecture Principles

- Separate UI, state, domain logic, the calculation engine, persistence, services, utilities and configuration.
- **The calculation engine is independent of the UI.** It is planned as a pure-Dart package that cannot import Flutter (CONFIRMED, DEC-008).
- Layers depend in one direction: presentation → application → domain ← data. Domain code never imports Flutter. (PROPOSED detail from the approved final report; see ARCHITECTURE.md.)
- The code is organized as feature modules (CONFIRMED). Calculator modes come from a single mode registry, so adding a mode is a contained change (PROPOSED).
- External or remote data (for example future currency rates) sits behind service interfaces.
- The confirmed choices (standard Flutter Material, plain Navigator with typed routes, Riverpod 3 without code generation, SharedPreferencesWithCache + sqflite) are in [DECISIONS.md](DECISIONS.md).

## UI/UX Direction

**CONFIRMED: the "quiet precision" direction.** It must be premium, modern, minimal and original, with:

- warm neutral surfaces and an iris (violet) accent
- squircle calculator keys
- strong visual hierarchy
- excellent dark mode
- accessibility first
- responsive layouts
- smooth but restrained animations

It must reach portfolio quality.

- **Navigation UX (CONFIRMED):**
  - Phones use a mode pill that opens a mode sheet, with no bottom navigation.
  - Tablets and landscape use a navigation rail, with a history side panel where appropriate.
- **Themes:** light, dark and system. High-contrast support is required (settings → accessibility).
- **Master prompt "use":**
  - strong visual hierarchy, proper spacing
  - rounded components, subtle elevation
  - modern typography, carefully chosen colours, excellent button hierarchy
  - smooth, meaningful transitions
  - designed empty, error and loading states
- **Master prompt "avoid":**
  - excessive gradients, excessive shadows, random colours
  - huge text, clutter, unnecessary animations
  - inconsistent spacing, corner radius or button sizes
- **Design system:** centralized tokens for colour, typography, spacing, radius and motion, plus a reusable component set. No hardcoded colours in widgets.
- **Motion:** fast and meaningful, reduced when accessibility settings require it.
- **Fonts:** bundled with the app, never downloaded at runtime, with fixed-width (tabular) digits. The specific fonts are **PENDING** (P-8).
- Detailed screen plans (keypad layout, scientific tray, result "tape", gestures) are PROPOSED; see ARCHITECTURE.md.

## Calculation Correctness Principles

- **Never** use unsafe string evaluation. The app uses its own engine: tokenize → parse (precedence-aware) → syntax tree → evaluate → format.
- **Exact arithmetic where practical** (CONFIRMED):
  - exact fractions for + − × ÷ %, whole-number powers and factorials
  - floating point only where the answer is irrational (trig, logs, non-perfect roots, fractional powers)
  - `0.1+0.2−0.3` must equal `0`
- The numeric library (`decimal`/`rational`) stays **hidden behind the engine's own types** so it can be replaced (CONFIRMED).
- **Never show** `NaN`, `Infinity`, `null` or `undefined`. Every error is a typed error with a clear, human-readable, translatable message.
- Every module must handle:
  - invalid, empty or unsupported input
  - division by zero
  - overflow
  - invalid expressions
  - invalid dates
  - negative values where they aren't allowed
- Very large and very small numbers are handled with limits, so nothing freezes.
- **Engine default behaviours are PENDING confirmation (P-6).** The final report proposed these and the user did not object:

  | Input | Result |
  | --- | --- |
  | `50+10%` | 55 |
  | `50×10%` | 5 |
  | `−3²` | −9 |
  | `2^3^2` | 512 |
  | `0^0` | 1 |
  | `(−8)^(1/3)` | −2 |
  | `tan(90°)` | "Undefined" |
  | too-large results | "Number too large" |

- **Dates:** avoid time-zone bugs. The PROPOSED approach is calendar-date arithmetic in UTC, with add-month clamping to the month end (31 Jan + 1 month = 28/29 Feb).

## Security & Privacy Principles

- Privacy first. Collect no unnecessary personal data, and process everything locally.
- No analytics, tracking or crash reporting unless the user explicitly asks for them.
- Calculation history is never sent to a server.
- Any future remote API (for example currency rates) is isolated behind a service. **API secrets are never hardcoded or committed.**
- The release Android manifest requests **no INTERNET permission**. Currently only the debug and profile manifests do, as the Flutter tooling needs. Keep it that way, so the app can honestly claim to work fully offline.
- Fonts are bundled, never fetched at runtime (so no `google_fonts`).
- History gets a retention limit and an off switch (PROPOSED; the values are not yet decided).

## Testing Principles

- **Tests are written alongside the implementation,** never afterwards.
- **Unit tests cover:**
  - the four operations, precedence, parentheses, decimals, negatives and percent
  - scientific functions
  - division by zero and invalid expressions
  - conversion formulas
  - EMI, GST and interest
  - date and programmer calculations
- **Widget tests cover:**
  - the keypad and the expression and result displays
  - history and settings
  - the converter and the finance forms
- **Integration tests** cover complete user flows.
- **CONFIRMED gate:** more than 200 table-driven calculation-engine edge-case tests must pass *before* the calculator UI counts as complete.
- **QA per module and phase:** `flutter analyze` (clean) → `dart format` → `flutter test` → build verification. That means an Android debug build, plus a release build check where practical.
- Only errors and warnings introduced by our work are fixed. None are hidden or suppressed without a documented reason.
- A test result is recorded only if the test was actually run (command, date, result).

## Development Workflow

- **Phase by phase, with an approval gate between phases.** The user must explicitly approve each phase before it starts. Every phase ends with a report, and then work stops.
- **Per module:**
  1. Analyze requirements.
  2. Design the architecture, then the UI.
  3. Build reusable components.
  4. Implement the logic.
  5. Connect state.
  6. Add persistence if it is needed.
  7. Add tests.
  8. Run the analyzer and formatter, then the tests.
  9. Review the UI and fix issues.
  10. Only then move on.
- **Never build the whole app in one giant step.**
- **Deviations** from the master prompt are welcome, but they are explained first (issue → proposal → why it is better) and approved.
- **Git:**
  - A local repository in `smart_calculator/`, on branch `main`.
  - A baseline commit of the untouched scaffold, then one meaningful commit per major phase.
  - **Never push to a remote.**
  - Not initialized yet.
- **Project memory:** keep the files in `docs/` accurate, following the protocols in [CLAUDE.md](../CLAUDE.md).

## Important Constraints

- Don't add dependencies just because they are popular. Verify each package's compatibility with Flutter 3.47.5 / Dart 3.13.4 and that it is actively maintained, **at the time it is added**.
- Keep `package:flutter/material.dart`. Don't add `material_ui`.
- Don't use `go_router` for now.
- Don't delete the web or desktop platform folders.
- Don't change the Android or iOS identifiers to anything other than the confirmed ID, and only when that step is approved (P-3).
- Phase 1 is **foundation only**: no calculator UI, no scientific keypad, and no engine logic beyond an empty package skeleton.
- iOS can't be verified on this machine. Windows desktop can't be built on it.

## Things We Explicitly Do Not Want

- A generic, copied-looking calculator UI, or "just another calculator app"
- Unsafe string evaluation, or floating-point-only arithmetic (so no `math_expressions`)
- `NaN`, `Infinity`, `null` or `undefined` shown to users
- Business logic inside widgets; giant widgets or files; duplicated components or logic
- Hardcoded colours, magic numbers or magic strings
- Excessive gradients or shadows, random colours, huge text, clutter, over-animation
- A bottom navigation bar on phones (the `AppBottomNavigation` component from the master prompt was dropped)
- `material_ui`; `go_router` (for now)
- Code generation (`build_runner`, `riverpod_generator`, `freezed`, `json_serializable`); `get_it`
- `google_fonts` (runtime font downloads); analytics or tracking; sending data to servers
- Hardcoded API secrets
- Hive or Isar (unmaintained forks); a database where one isn't needed
- Silent architectural changes; batching several phases together; invented facts or test results
- Pushing to any remote repository
