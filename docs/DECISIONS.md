# Decisions

This is the architecture and product decision record. It is **append-only**: when a decision changes, set its status to `Superseded` (or `Rejected`) and add a new entry that references it. Never delete an entry. The reasons are the point of this file.

**Status values:**

| Status | Meaning |
| --- | --- |
| `Accepted` | Decided by the user; may or may not be implemented yet (see "Implemented") |
| `Adopted` | An implementation choice Claude made within a user-approved scope. It stands unless the user objects. |
| `Proposed` | Awaiting the user's decision |
| `Superseded` | Replaced by a later decision |
| `Rejected` | Considered and turned down |

**Sources for DEC-001 to DEC-017:**

- the user's master prompt
- the user's validation request and final approval messages (all 2026-09-28)
- Claude's Phase 0 audit and Final Architecture Decision Report (2026-09-28)

## Decision Format

```md
### [DEC-000] Title

- **Status:** Accepted | Proposed | Superseded by DEC-xxx | Rejected
- **Date:** YYYY-MM-DD
- **Implemented:** No | Partly | Yes (where)

**Context:** Why a decision was needed.

**Decision:** What was decided.

**Reason:** Why.

**Alternatives:** What else was considered, and why not.

**Impact:** What it affects or constrains.
```

---

### [DEC-001] Phased, approval-gated, module-by-module development

- **Status:** Accepted
- **Date:** 2026-09-28
- **Implemented:** Process (applies to all work)

**Context:** The user wants a portfolio- and production-quality app, and wants to stay in control of large decisions.

**Decision:**

- Build in phases 0–12 (see ROADMAP.md).
- Each phase needs the user's explicit approval before it starts, and ends with a report followed by a stop.
- Per module: analyze → design the architecture → design the UI → build components → implement logic → connect state → add persistence → add tests → `flutter analyze` → `dart format` → `flutter test` → review the UI → fix issues → move on.
- Deviations from the master prompt are explained first (issue → proposal → why it is better), and only then implemented.

**Reason:** This is what the master prompt requires (§30, §31, §38).

**Alternatives:** Building the whole app in one step. The user explicitly forbade it.

**Impact:** Never batch phases. Never make silent architectural changes.

---

### [DEC-002] Use standard Flutter Material (`package:flutter/material.dart`); do not adopt `material_ui`

- **Status:** Accepted
- **Date:** 2026-09-28
- **Implemented:** Yes, as the template already uses framework Material. Keep it that way.

**Context:** The first audit recommended moving to the separate `material_ui` package, because Material was moving out of the framework and go_router 18 already depends on it. The user asked for this to be verified against the actual Flutter 3.47.5 tooling.

**Decision:** Keep the framework Material APIs. Do not add `material_ui`.

**Reason:** Verified 2026-09-28 against the installed SDK:

- On 3.47.5, `material_ui` is opt-in.
- The SDK's fix data describes the move as an *eventual* deprecation that hasn't happened (`TODO: Link eventual deprecation PR`).
- `flutter create`, `flutter_test` and the gen-l10n code generator all still use framework Material.

**Alternatives:**

- **Rejected:** moving to `material_ui` (Claude's first-audit recommendation, which was wrong). It would mean mixing two copies of Material and bridging themes between them.

**Impact:** Any package that imports `material_ui` needs scrutiny (see DEC-003). Revisit only if Flutter actually deprecates framework Material.

---

### [DEC-003] Navigation: plain `Navigator` with our own typed route layer; no `go_router` for now

- **Status:** Accepted
- **Date:** 2026-09-28
- **Implemented:** Yes, in Phase 1 (2026-09-28): sealed `AppRoute` and `context.pushRoute` over `MaterialPageRoute`; see ARCHITECTURE.md §1.5 and DEC-021.

**Context:** The first audit proposed `go_router` ^18.0.1. Validation found that go_router 18 moved onto `material_ui` and checks for *`material_ui`'s* `MaterialApp`, which is a different class from the framework's.

**Decision:** Use plain `Navigator` behind a small typed route layer. All navigation goes through that layer. The user chose Option A.

**Reason:** A runtime test in a scratch project, using the framework `MaterialApp`, showed:

| Setup | Route type | Transition | iOS swipe-back |
| --- | --- | --- | --- |
| go_router route with `builder:` | `NoTransitionPage` | 0 ms | Broken |
| go_router route with `pageBuilder:` returning `MaterialPage` | Material route | 450 ms | Works |
| plain `Navigator` | Material route | 450 ms | Works |

A minimal-app arm64 release APK was 16.2 MB with go_router 18 and 15.3 MB with plain Navigator. The difference includes 333 KB of unused, duplicated `material_ui`/`cupertino_ui` code.

The 17.x line has had no releases since 18.0.0, so pinning 17.x would mean pinning a frozen line.

**Alternatives:**

- **Rejected:** go_router 18, with every route forced through `pageBuilder:` by a shared helper and a test (Option B). It works, but costs about 0.9 MB and adds a trap.
- **Rejected:** pinning go_router 17.x (frozen).

**Impact:**

- There are no URL deep links for now.
- Because navigation is centralized, adopting go_router later (for deep links or web) is a contained change.
- Revisit only if deep links or web become requirements.

---

### [DEC-004] Platform strategy: Android and iOS primary; keep the other platform folders

- **Status:** Accepted
- **Date:** 2026-09-28
- **Implemented:** Yes (all folders present). Support status is a documentation matter.

**Context:** The template scaffolds web, Windows, Linux and macOS as well. The first audit recommended deleting them, and offered a web demo as an option.

**Decision:**

- Android and iOS are the primary targets.
- The web, Windows, Linux and macOS folders stay, but they are **not supported or tested** targets.

**Reason:** This is the user's explicit instruction. There is no concrete technical reason to delete the folders, and keeping them is cheap.

**Alternatives:**

- **Rejected:** deleting the non-mobile folders (Claude's first-audit recommendation).
- **Rejected:** a web demo, which would require replacing `sqflite` with `drift`.

**Impact:**

- Don't build or test the other platforms, and don't claim they work.
- If desktop is ever wanted, only the database setup needs a desktop SQLite driver.
- iOS can't be built on this Windows machine, so iOS stays unverified until a Mac is available (P-5).

---

### [DEC-005] Application ID and display name

- **Status:** Accepted. The user approved applying the values in Phase 1 (2026-09-28), which resolved P-3.
- **Date:** 2026-09-28
- **Implemented:** Yes on Android and iOS (Phase 1, 2026-09-28, commit `06c0a93`): namespace, applicationId, Kotlin package, label; iOS bundle IDs and `CFBundleName`. Web and desktop keep template identifiers (DEC-025).

**Context:** `com.example.*` IDs are rejected by Google Play. Claude was told never to invent an ID.

**Decision:**

- The application ID is **`com.parasshakya.smartcalculator`**.
- The display name is **"Smart Calculator"**.
- The platform-specific identifiers are updated consistently, and exactly what changed is reported:
  - Android `namespace` and `applicationId`
  - the Kotlin package and its folder
  - the iOS `PRODUCT_BUNDLE_IDENTIFIER` (plus `.RunnerTests`)
  - the Android label and iOS `CFBundleName`

**Reason:** Provided by the user.

**Alternatives:** None; this was the user's choice.

**Impact:** The approved Phase 1 scope list didn't include this step, which raised P-3. **Resolved 2026-09-28:** the user said to apply the values in Phase 1, and they were (DEC-025).

---

### [DEC-006] Local Git repository, never pushed

- **Status:** Accepted
- **Date:** 2026-09-28
- **Implemented:** Yes (2026-09-28): repository in `smart_calculator/` on branch `main`. Commits: the untouched scaffold with `.gitattributes` (`8ca813c`), the project-memory docs (`813533e`), the app identity (`06c0a93`), then the Phase 1 foundation. Nothing is pushed.

**Context:** The folder isn't a Git repository, which is risky for a 12-phase build.

**Decision:**

- Initialize Git in `smart_calculator/` on branch `main`.
- The first commit is the untouched Flutter scaffold, as a baseline.
- Make one local commit after Phase 1, and meaningful commits after each major phase from then on.
- Add a `.gitattributes` file for consistent line endings (a proposed default the user didn't object to).
- **Never push to any remote.**

**Reason:** The user approved this.

**Alternatives:** None considered.

**Impact:** `CLAUDE.md` and `docs/` existed before `git init`, which raised P-2. **Resolved 2026-09-28:** the user allowed the docs in the initial commits. The scaffold (with `.gitattributes`) and the docs went into separate commits, `8ca813c` and `813533e`.

---

### [DEC-007] State management: Riverpod 3 without code generation

- **Status:** Accepted
- **Date:** 2026-09-28
- **Implemented:** Foundation (Phase 1): `flutter_riverpod` 3.4.3, `Notifier` providers, overrides for dependency injection, retry disabled in `AppRoot`. See ARCHITECTURE.md §1.4 and DEC-026.

**Context:** The project had no state management. Settings (angle mode, precision, haptics) feed several features, and three modes write to the same history.

**Decision:**

- Use `flutter_riverpod` 3 (`Notifier` and `AsyncNotifier`), without `riverpod_generator` or `build_runner`.
- Proposed patterns: narrow `select` rebuilds, provider overrides as dependency injection, and Riverpod 3's automatic retry disabled app-wide.

**Reason:**

- It handles shared state without passing it through the widget tree.
- It gives narrow rebuilds, so a keystroke rebuilds only the display.
- Overrides make tests easy.
- `AsyncNotifier` provides loading and error states.
- Without code generation there is no build step.

**Alternatives:**

- **Rejected:** Bloc/Cubit, which means events and states for all seven modules and adds little here.
- **Rejected:** Provider, whose own author recommends Riverpod.
- **Rejected:** `riverpod_generator` / `build_runner`, to avoid a code-generation step.
- **Rejected:** `get_it`, since Riverpod already provides dependency injection.

**Impact:** No generated code (`*.g.dart`) anywhere in the project.

---

### [DEC-008] Calculation engine: a separate pure-Dart package with exact arithmetic behind our own types

- **Status:** Accepted
- **Date:** 2026-09-28
- **Implemented:** Skeleton only (Phase 1): `packages/calc_engine` exists as a workspace member with no dependencies and an empty library. The engine logic, `decimal`/`rational` and its tests come in Phase 3 (DEC-019).

**Context:**

- The master prompt forbids unsafe string evaluation and requires an engine that is independent of the UI.
- Plain floating point shows `0.1+0.2−0.3` as `5.55e-17`.

**Decision:**

- The engine lives in `packages/calc_engine`, a pure-Dart package in a pub workspace. **Flutter imports are not allowed in it.**
- It uses exact fractions where practical, and floating point only for irrational results.
- `decimal` and `rational` stay hidden behind our own types (`CalcValue`, `CalcResult`, `CalcError`) inside `src/number/`, so the numeric library can be replaced later.
- Programmer mode uses a separate `BigInt` evaluator.

**Reason:**

- The compiler, not convention, enforces that the engine is independent of the UI.
- Its tests run under plain `dart test`.
- Exact arithmetic avoids a classic class of calculator bugs. Verified in the scratch project: `0.1+0.2−0.3 == 0`, `(1÷3)×3 == 1`, and `2^100` is exact.

**Alternatives:**

- **Rejected:** `math_expressions`, which uses floating point and so has the `0.1+0.2−0.3` bug. Besides, the engine *is* the product.
- **Rejected:** any string/`eval`-style evaluation, which is unsafe and forbidden.
- **Rejected:** an engine folder inside `lib/`, where independence would depend only on convention.

**Impact:**

- `decimal` has a single maintainer and no verified publisher, which is why it is wrapped.
- The engine must declare `rational` as a direct dependency (the analyzer requires it).
- The default behaviours are pending (P-6).

---

### [DEC-009] Persistence: `SharedPreferencesWithCache` for settings, `sqflite` for history and saved calculations

- **Status:** Accepted
- **Date:** 2026-09-28
- **Implemented:** Foundation (Phase 1): `SharedPreferencesWithCache` preloaded at startup, stores the theme choice; `AppDatabase` schema v1 with migration setup, opened lazily through `appDatabaseProvider`. No history or saved-calculation repositories yet (Phase 4). See DEC-023.

**Context:** History, saved calculations, settings, the theme and calculator preferences must persist locally. The master prompt says: don't introduce a database unnecessarily.

**Decision:**

- **Settings, theme, memory value and last mode:** `SharedPreferencesWithCache` (the newer API), preloaded before the first frame.
- **History and saved calculations:** `sqflite` with a versioned schema (v1) and migrations.

**Reason:**

- History needs search, date ordering, paging, single-row deletes and migrations, which justifies SQLite.
- Preloading the preferences avoids a flash of the wrong theme at launch.
- Verified in the scratch project: in-memory SQLite works on this Windows machine (SQLite 3.53.4, no C compiler needed), and Android builds work with the plugins.

**Alternatives:**

- **Rejected:** Hive and Isar, whose originals are unmaintained forks.
- **Rejected:** `drift`, which is excellent but adds code generation for two tables. It would only be needed for web.
- **Rejected:** SharedPreferences for history, which can't search or page.

**Impact:**

- `sqflite` doesn't support web, which is consistent with DEC-004.
- Database tests use `sqflite_common_ffi`.

---

### [DEC-010] Testing strategy and the engine test gate

- **Status:** Accepted
- **Date:** 2026-09-28
- **Implemented:** Foundation tests only (Phase 1): 24 widget and unit tests for the shell, navigation, theme persistence, the database and the architecture boundaries. The engine test gate applies from Phase 3.

**Context:** Calculation correctness is the core of the product.

**Decision:**

- Use unit, widget and integration tests where appropriate.
- **More than 200 table-driven engine edge-case tests must pass before the calculator UI counts as complete.** They cover:
  - precedence, grouping, unary minus and implied multiplication
  - percent rules; unbalanced or empty brackets
  - decimal edge cases (`.5`, `5.`, `1..2`)
  - overflow and very small numbers; division by zero, including `0/0`
  - invalid function inputs (√−1, log 0, asin 2); factorial edge cases
  - formatting (no `-0`, and when to switch to scientific notation)
  - a randomized fuzz test proving that no input ever crashes and every input returns a result
- Every phase ends with `flutter analyze` clean, `dart format` run, and all tests passing.

**Reason:** The master prompt (§27, §28) and the user's approval.

**Alternatives:** None.

**Impact:** Phase 3 can't be marked complete without the gate passing.

---

### [DEC-011] UI/UX direction: "quiet precision"

- **Status:** Accepted
- **Date:** 2026-09-28
- **Implemented:** Design system in Phase 2: tokens, four themes, components, gallery (DEC-028 to DEC-033). It awaits the user's design sign-off (P-11). Feature screens come from Phase 3 on.

**Context:** The master prompt asks for a premium, original design language.

**Decision:** The app is premium, modern, minimal and original, with:

- warm neutral surfaces and an iris accent
- squircle calculator keys
- strong visual hierarchy
- excellent dark mode
- accessibility first
- responsive layouts
- smooth but restrained animations

Phase 2 ends with a design review: a debug-only gallery of every component, in light and dark, at up to 200% text size, for the user's sign-off.

**Reason:** Proposed by Claude and approved by the user, with the condition that the final UI must be portfolio quality.

**Alternatives:** None recorded.

**Impact:** The fonts are pending (P-8). Detailed screen layouts are proposals (see ARCHITECTURE.md §3.8).

---

### [DEC-012] Navigation UX: no bottom navigation on phones

- **Status:** Accepted
- **Date:** 2026-09-28
- **Implemented:** Shell with placeholders (Phase 1): mode pill and mode sheet on compact windows (a grid of mode tiles since Phase 2), navigation rail on medium and expanded windows, history panel on expanded windows. No bottom navigation, and a test checks this (DEC-022).

**Context:** The master prompt listed an `AppBottomNavigation` component.

**Decision:**

- **Phones:** a mode pill in the header opens a mode sheet. There is **no bottom bar**.
- **Tablets and landscape:** a navigation rail, with a history side panel where appropriate.
- Both are generated from a single mode registry.

**Reason:**

- On small phones, keypad height is the scarcest space, and a bottom bar costs about 80 dp of it (roughly 12%).
- Six modes also exceed Material's limit of five bottom-bar items.

**Alternatives:**

- **Rejected:** a bottom navigation bar on phones, from the master prompt.

**Impact:** `AppBottomNavigation` is dropped from the component list.

---

### [DEC-013] Basic and scientific share one calculator state

- **Status:** Accepted
- **Date:** 2026-09-28
- **Implemented:** No

**Context:** The master prompt asked for a separate scientific module.

**Decision:** Scientific has its own keypad and layout, but shares the calculator's expression, memory and history state. It lives inside `features/calculator/`.

**Reason:** Users switch to scientific in the middle of a calculation (to reach √, for example). Separate state would mean two cursors, two memory registers and two paths into history.

**Alternatives:**

- **Rejected:** a fully separate scientific module with its own state.

**Impact:** The basic keypad must stay uncluttered. Scientific functions go in a separate tray or keypad.

---

### [DEC-014] Offline first and privacy first

- **Status:** Accepted
- **Date:** 2026-09-28
- **Implemented:** Partly. The template's release manifest already has no INTERNET permission.

**Context:** The master prompt, §25.

**Decision:**

- Process everything locally.
- No analytics, tracking or crash reporting.
- History is never sent to a server.
- The release build requests no INTERNET permission.
- Fonts are bundled, not downloaded.
- Any future remote API sits behind a service, and secrets are never hardcoded or committed.
- *(Proposed in the final report; values not decided):* history gets a retention limit and an off switch.

**Reason:** The user's privacy requirements.

**Alternatives:**

- **Rejected:** `google_fonts`, because of runtime downloads.
- **Rejected:** any analytics or crash-reporting SDK.

**Impact:** Live currency rates, if ever added, need the user's explicit decision on a network service.

---

### [DEC-015] Dependency policy and the packages we deliberately don't use

- **Status:** Accepted
- **Date:** 2026-09-28
- **Implemented:** Policy (applies whenever a dependency is added). Applied in Phase 1; see the re-verification note below.

**Context:** The user said: don't add dependencies because they are popular, and verify that each one is compatible and maintained.

**Decision:**

- Before adding a package, verify that it is compatible with Flutter 3.47.5 / Dart 3.13.4 and actively maintained.
- The planned set was verified 2026-09-28 in a scratch project: each package resolved at its latest version, none is discontinued, and each passed a runtime smoke test. **Correction (Phase 1 re-check):** the earlier claim that all were released within the past year was wrong for `path`. Its latest version, 1.9.1, dates from 2024-10; it is a stable dart.dev core package and stays in the plan.
- **Re-verified on pub.dev, 2026-09-28, before adding in Phase 1:** `flutter_riverpod` 3.4.3 (2026-09-03), `shared_preferences` 2.5.5 (2026-03-25), `shared_preferences_platform_interface` 2.4.2 (2026-03-25), `sqflite` 2.4.4 (2026-09-10), `sqflite_common_ffi` 2.4.3 (2026-09-10), `path` 1.9.1 (2024-10-17). All are the latest versions, none is discontinued, and all come from verified publishers. The packages still to be added are listed in ARCHITECTURE.md §3.8.
- **Deferred:**
  - `package_info_plus` (P-7), which pulls in `http` and `win32`
  - `http`, until live currency rates exist
- **Removed in Phase 1:** `cupertino_icons` (unused).

**Reason:** Keep the dependency footprint small and justified.

**Alternatives (rejected):**

| Package | Reason |
| --- | --- |
| `google_fonts` | Downloads fonts at runtime (privacy, offline) |
| `fl_chart` | Two simple charts are easier to style and make accessible with custom painting |
| `freezed`, `json_serializable` | No code generation; Dart 3 sealed classes and records are enough |
| `get_it` | Riverpod provides dependency injection |
| `math_expressions` | Floating point (DEC-008) |
| `material_ui` | DEC-002 |
| `go_router` | DEC-003 |
| Analytics or crash-reporting SDKs | DEC-014 |
| Audio or vibration packages | The built-in system click and haptics are enough |

**Impact:** Record every dependency added (with its exact version) in DEVELOPMENT_STATUS.md and CHANGELOG.md.

---

### [DEC-016] Phase 1 is foundation only

- **Status:** Accepted (scope). Phase 1 was approved and carried out on 2026-09-28.
- **Date:** 2026-09-28
- **Implemented:** Yes (Phase 1, 2026-09-28). No Phase 2 work was started.

**Context:** The user wants foundations laid before any feature UI is built.

**Decision:** Phase 1 does only the following:

- Git setup
- dependencies and strict lint rules
- the pub workspace and an empty calculation-engine package
- the folder structure and startup architecture
- the typed route layer over plain Navigator, and an adaptive shell with placeholder screens
- the basic theme structure, with the light/dark/system choice persisted
- settings storage and database v1
- translation (l10n) setup
- `docs/ARCHITECTURE.md` updated
- replacing the default counter test
- running format, analyze and tests
- the Phase 1 local Git commit

**Excluded from Phase 1:**

- anything in Phase 2
- the final calculator UI and the scientific keypad
- any engine logic beyond the skeleton

**Reason:** The user's explicit instruction.

**Alternatives:** None.

**Impact:** The Phase 1 report must include:

1. files created
2. files modified
3. dependencies added, with exact versions
4. the architecture implemented
5. tests executed and their results
6. the `flutter analyze` result
7. the `dart format` result
8. the Git commit hash
9. any warnings or remaining issues

Then stop.

---

### [DEC-017] Roadmap adjustments to the master prompt's phase order

- **Status:** Accepted, as part of the plan the user agreed with on 2026-09-28 (*"I agree with the overall production architecture and module-by-module approach"*)
- **Date:** 2026-09-28
- **Implemented:** No

**Context:** The master prompt set the phase order in §30.

**Decision:**

- Settings **storage** moves up to Phase 1, because the engine needs precision and angle mode. The settings **screen** stays in Phase 10.
- Phase 4 covers both history **and** saved calculations.
- Phase 6 includes a design for currency rates, but no network access.

**Reason:** The dependencies between modules.

**Alternatives:** Following the master prompt's order exactly.

**Impact:** See ROADMAP.md.

---

### [DEC-018] The repository documentation is the persistent source of truth for project state

- **Status:** Accepted
- **Date:** 2026-09-28
- **Implemented:** Yes (`CLAUDE.md` and `docs/`)

**Context:** When a Claude Code conversation's context fills up and a new session starts, the new session must be able to recover what was decided, what is done and what comes next, without the previous chat.

**Decision:**

- `CLAUDE.md` is the entry point, and it defines the Context Recovery and Session Handoff protocols and the accuracy rules.
- The `docs/` files hold the project memory, status, architecture, decisions, roadmap and changelog.
- The conversation history is never the only record.

**Reason:** The user's explicit requirement.

**Alternatives:**

- **Rejected as the primary store:** Claude's local auto-memory. It is outside the repository, tied to the machine and the working directory, and it had already gone stale once (see DEVELOPMENT_STATUS.md, "Discrepancies Found").

**Impact:** Every meaningful session must end with the Session Handoff Protocol.

---

### [DEC-019] Phase 1 dependency set; engine dependencies and empty folders deferred

- **Status:** Adopted (Phase 1 implementation choice; open to the user's review)
- **Date:** 2026-09-28
- **Implemented:** Yes (Phase 1)

**Context:** Phase 1 scope included "dependencies" and the "folder structure". The engineering standards also say: no unnecessary dependencies and no dead code.

**Decision:**

- **Added** only what Phase 1 code uses:
  - `flutter_riverpod` ^3.4.3, `shared_preferences` ^2.5.5, `sqflite` ^2.4.4, `path` ^1.9.1, `intl` (`any`, pinned by the SDK), `flutter_localizations` (SDK)
  - dev: `sqflite_common_ffi` ^2.4.3, and `shared_preferences_platform_interface` ^2.4.2
- `shared_preferences_platform_interface` was not in the original plan. The tests need its in-memory preferences store, and `depend_on_referenced_packages` requires imported packages to be declared.
- **Removed:** `cupertino_icons`.
- **Not added yet:**
  - `decimal`, `rational` and `test` for the engine (Phase 3, when engine code uses them)
  - `integration_test` (when the first end-to-end flow exists)
- **The app does not depend on `calc_engine` yet.** It is a workspace member only.
- **No empty placeholder folders** (such as `.gitkeep` files for future features). Folders appear with their first file; the target layout is documented in ARCHITECTURE.md §3.1.

**Reason:** An unused dependency or an empty folder adds maintenance and review noise and enforces nothing.

**Alternatives:**

- **Rejected:** adding every planned dependency now.
- **Rejected:** scaffolding every feature folder with placeholders.

**Impact:** Phase 3 adds the engine dependencies, and re-verifies them first (DEC-015).

---

### [DEC-020] One strict lint configuration for the workspace, plus boundary checks

- **Status:** Adopted (Phase 1 implementation choice; open to the user's review)
- **Date:** 2026-09-28
- **Implemented:** Yes (`analysis_options.yaml`, `test/architecture/layer_boundaries_test.dart`)

**Context:** Phase 1 called for "strict lint rules". DEC-008 requires that the engine never import Flutter. In a pub workspace, every package resolves imports through one shared package config, so an undeclared import would still resolve.

**Decision:**

- **One `analysis_options.yaml`** at the root. `packages/calc_engine` inherits it.
- **What it enables:**
  - `flutter_lints`
  - `strict-casts`, `strict-inference` and `strict-raw-types`
  - 26 extra rules, including `avoid_dynamic_calls`, `unawaited_futures`, `prefer_final_locals`, `directives_ordering`, `comment_references` and `type_annotate_public_apis`
- **`depend_on_referenced_packages` is raised to an error.**
- **An architecture test** fails if the engine or any `domain/` folder imports `package:flutter…` or `dart:ui`, or if the engine's pubspec declares a Flutter dependency.

**Reason:** The compiler and the tests enforce the boundary, instead of a convention that could be forgotten.

**Alternatives:**

- **Not chosen for now:** a separate `analysis_options.yaml` for the engine, based on `package:lints`. The engine has no code yet. Revisit in Phase 3 if engine-only rules (such as `public_member_api_docs`) are wanted.

**Impact:** Every new file must pass these rules. Suppressing a rule needs a documented reason.

---

### [DEC-021] How the typed navigation and mode state are implemented

- **Status:** Adopted (Phase 1 implementation of DEC-003 and DEC-012; open to the user's review)
- **Date:** 2026-09-28
- **Implemented:** Yes (`lib/app/navigation/`, `lib/app/modes/`)

**Context:** DEC-003 chose plain Navigator with a typed route layer. Modes change state; they don't navigate.

**Decision:**

- **Routes:** a sealed `AppRoute` class, with one `final class` per page (`HistoryRoute`, `SettingsRoute`), each with a unique `name`.
- **Pushing:** only through `context.pushRoute(route)`, which pushes a `MaterialPageRoute` whose `RouteSettings.name` is the route's name.
- **Pages:** one exhaustive `switch` maps each route to its page.
- **Going back and closing sheets** use the standard `Navigator.pop`.
- **The mode registry** is the `CalculatorMode` enum, with an exhaustive presentation extension (icon and translated name).
- **The current mode** lives in `CurrentModeNotifier`, **in memory only**. It always starts at Basic.

**Reason:**

- The compiler rejects a route without a page.
- Routes are plain data.
- Platform-native transitions and iOS swipe-back come without special rules.
- Remembering the last mode (in the persistence plan) was not in the Phase 1 scope, so it is deferred.

**Alternatives:**

- **Rejected:** a string-keyed route table, which has no exhaustiveness check.
- **Rejected:** Flutter's named routes, which are untyped arguments.

**Impact:**

- New pages follow ARCHITECTURE.md §1.13.
- Persisting the last mode, and the "default mode" setting (Phase 10), are still to come.

---

### [DEC-022] Adaptive shell breakpoints and behaviour

- **Status:** Adopted (Phase 1 implementation of DEC-012; open to the user's review)
- **Date:** 2026-09-28
- **Implemented:** Yes (`lib/app/shell/`, `lib/core/layout/window_size_class.dart`)

**Context:** The approved plan uses the Material compact, medium and expanded classes: a mode pill on phones, and a rail plus a history panel on tablets and in landscape.

**Decision:**

- **Size class** comes from the window width (`MediaQuery.sizeOf`), using the Material 3 breakpoints of 600 and 840 dp.
- **Compact:** a top bar with the mode pill, which opens a bottom sheet **list** of modes, plus the history and settings actions.
- **Medium:** a navigation rail and a top bar with the mode name. History is a pushed page.
- **Expanded:** the rail plus a 320 dp history panel. The history action is hidden.
- **The rail scrolls** when the window is too short to show every destination.

**Reason:** These are the standard Material breakpoints, and width alone covers phones in landscape too.

**Alternatives:**

- **Deferred:** the audit's proposed *grid* mode sheet. That is a visual-design question for Phase 2.
- **Deferred:** a dedicated phone-landscape calculator layout, with the scientific keys beside the keypad. That belongs to Phase 3/5.

**Impact:**

- Most phones in landscape measure 840 dp or more, so they currently get the expanded layout, history panel included.
- Phase 3/5 must decide the landscape calculator layout.

---

### [DEC-023] Persistence foundation details

- **Status:** Adopted (Phase 1 implementation of DEC-009; open to the user's review)
- **Date:** 2026-09-28
- **Implemented:** Yes (`lib/core/persistence/`, `lib/features/settings/data/`)

**Context:** DEC-009 chose `SharedPreferencesWithCache` and `sqflite`. Phase 1 needed the foundation, without any history features.

**Decision:**

- **Preferences:**
  - They are opened once, before the first frame, with the allow-list `PreferenceKeys.all`.
  - `sharedPreferencesProvider` has no default and throws unless overridden, so forgetting to preload fails loudly.
  - Values are stored as fixed strings (for example `settings.theme_preference` = `dark`), never enum names. Unknown values fall back to the default.
- **Database:**
  - It is opened **lazily** through `appDatabaseProvider`, not at startup. Nothing uses it yet, and this keeps startup fast.
  - Migrations are an ordered list of SQL statement lists, and `schemaVersion` is derived from the list length.
  - Schema v1 creates the `history` and `saved_calculations` tables with date indexes; the columns are in ARCHITECTURE.md §1.8.

**Reason:** Deterministic startup, protection against typos in keys, and schema changes that must go through a migration.

**Alternatives:**

- **Rejected:** opening the database at startup (startup cost, and nothing uses it).
- **Rejected:** storing enum names, since a rename would break saved values.

**Impact:**

- Phase 4 adds the history and saved-calculation repositories.
- Phase 4 should confirm the v1 columns before any release. Once v1 ships, schema changes need a new migration.

---

### [DEC-024] Localization setup

- **Status:** Adopted (Phase 1 implementation; open to the user's review)
- **Date:** 2026-09-28
- **Implemented:** Yes (`l10n.yaml`, `lib/l10n/`)

**Context:** The architecture requires l10n from day one. On Flutter 3.47, gen-l10n no longer supports a synthetic package.

**Decision:**

- **gen-l10n configuration:** ARB files in `lib/l10n`, output `app_localizations.dart`, `nullable-getter: false`, `required-resource-attributes: true` (every string needs a description) and `format: true`.
- **Language:** English only.
- **Generated files** are committed; `flutter pub get` regenerates them.

**Reason:**

- Every visible string can be translated.
- Translators get context for each string.
- Committed output keeps the repository readable and analyzable.

**Alternatives:**

- **Rejected:** ignoring the generated files in Git. The repository would be incomplete until someone ran `pub get`.

**Impact:** Editing an ARB file changes the generated files, and both are committed together.

---

### [DEC-025] Application identity applied to Android and iOS only

- **Status:** Adopted (Phase 1 implementation of DEC-005; open to the user's review)
- **Date:** 2026-09-28
- **Implemented:** Yes (commit `06c0a93`)

**Context:** The user said to apply the ID and display name "where appropriate within Phase 1."

**Decision:**

- **Android:** `namespace` and `applicationId` set to `com.parasshakya.smartcalculator`; the Kotlin package moved to match; the launcher label is "Smart Calculator".
- **iOS:** `PRODUCT_BUNDLE_IDENTIFIER` set to `com.parasshakya.smartcalculator` (and `.RunnerTests` for the tests); `CFBundleName` is "Smart Calculator".
- **Web, Windows, Linux and macOS:** unchanged, with their template identifiers.

**Reason:** Android and iOS are the primary platforms. The others are unsupported (DEC-004), and none of them can be built or verified on this machine.

**Alternatives:**

- **Deferred:** updating every platform now, which would mean unverifiable changes.

**Impact:** If a web or desktop target is ever approved, update its identifiers first.

---

### [DEC-026] Riverpod wiring conventions

- **Status:** Adopted (Phase 1 implementation of DEC-007; open to the user's review)
- **Date:** 2026-09-28
- **Implemented:** Yes

**Context:** DEC-007 chose Riverpod 3 without code generation. Phase 1 set the patterns that later features will copy.

**Decision:**

- **Providers** are top-level `final`s with explicit types.
- **Repository providers** live in the feature's data layer and are typed by the domain interface. Notifiers (the application layer) read them through `ref`.
- **After an `await`, notifiers check `ref.mounted`** before updating their state.
- **Automatic retry** is disabled once, in `AppRoot`.
- **Tests** use real in-memory backends through overrides and `AppRoot`, with no mocking packages.

**Reason:** Layers stay swappable and testable, with no generated code and no service locator.

**Alternatives:**

- **Rejected:** `riverpod_generator`, per DEC-007.
- **Rejected:** declaring repository providers in the domain layer and overriding them in `main`. It adds ceremony and has no Phase 1 benefit.

**Impact:** New features follow the settings feature's structure.

---

### [DEC-027] Kotlin incremental compilation disabled for Android builds

- **Status:** Adopted (Phase 1 build fix; the alternative is pending, see P-10)
- **Date:** 2026-09-28
- **Implemented:** Yes (`android/gradle.properties`: `kotlin.incremental=false`)

**Context:**

- After Phase 1 added the plugins, `flutter build apk` failed in `:shared_preferences_android:compileDebugKotlin` (and `compileReleaseKotlin`) with "Could not close incremental caches … this and base files have different roots".
- The plugins' Kotlin sources are in the pub cache on drive `C:`, and this project and its build folder are on drive `D:`. Kotlin's incremental caches can't relate paths across Windows drives.
- The previous session's scratch builds passed because that project was on `C:`.

**Decision:** Set `kotlin.incremental=false` in `android/gradle.properties`.

**Reason:**

- It fixes the build with a project-level setting that doesn't change the machine.
- It only turns off incremental caching for Kotlin compilation. App behaviour is unaffected, and the app's own Kotlin code is one small file.

**Alternatives:**

- **Pending (P-10):** move the project, or `PUB_CACHE`, onto the same drive, and then remove this setting. That is the user's environment choice.

**Impact:** Plugin Kotlin code is fully recompiled when it changes, so those rebuilds are slightly slower.

---

### [DEC-028] Font: Manrope, bundled, with tabular figures (resolves P-8)

- **Status:** Adopted (Phase 2). This was the approved proposal, pending one check, which passed. Open to the user's review.
- **Date:** 2026-09-28
- **Implemented:** Yes (`assets/fonts/`, `pubspec.yaml`, `AppTypography`, `lib/app/font_licenses.dart`)

**Context:** The UI plan proposed Manrope, "pending a check that it supports fixed-width digits". Fonts must be bundled, never downloaded (DEC-014).

**Decision:**

- **Source:** the static Manrope TTFs in weights 400, 500, 600 and 700, from `googlefonts/manrope` at commit `6f81ebe`. That is the commit Google Fonts used; the original `sharanda/manrope` repository no longer exists.
- **Tabular figures:** a Dart check of each font's OpenType feature list found `tnum` in all four weights. The default digits are proportional (for example, "1" is 780 units wide and "0" is 1220), so the number styles turn on `FontFeature.tabularFigures()`.
- **Licence:** the OFL text is bundled and registered with `LicenseRegistry`.
- **JetBrains Mono** (programmer mode) is deferred to Phase 9, when it is first used.

**Reason:** The check confirmed the proposal. With tabular digits, numbers don't shift while being typed.

**Alternatives:**

- **Rejected:** the variable font. Flutter's `fontWeight` doesn't drive the weight axis, so Material widgets that set a weight would render at the wrong weight.
- **Rejected:** `google_fonts` (runtime download, DEC-015).

**Impact:**

- The release APK grew by about 0.4 MB (45.3 to 45.7 MB).
- Any new number style must enable tabular figures, and a test checks the existing ones.

---

### [DEC-029] Design tokens as theme extensions, with four palettes

- **Status:** Adopted (Phase 2 implementation of DEC-011; open to the user's review)
- **Date:** 2026-09-28
- **Implemented:** Yes (`lib/app/theme/`)

**Context:** The master prompt asks for centralized tokens: colours, typography, spacing, radius, and motion. The UI direction is "quiet precision".

**Decision:**

- **`AppColors`** and **`AppTypography`** are `ThemeExtension`s, so they animate with theme changes and are read through the theme.
- **`AppSpacing`, `AppRadius` and `AppMotion`** are constants. `AppMotion` has a reduced-motion helper.
- **Four palettes:** light ("porcelain"), dark ("graphite"), high-contrast light and high-contrast dark. They are wired into `MaterialApp.highContrastTheme` and `highContrastDarkTheme`.
- **One accent:** `primary` (iris) is the only accent; there is no separate "accent" role. The master prompt listed both, but the approved direction is "one signature accent".
- **Neutral secondary:** `secondary` and tonal fills are warm neutrals.
- **Three key tones:**
  - digits: plain
  - operators and functions: the same tint, with operator symbols in the accent colour and function labels in the text colour
  - `=`: solid accent
- **Tested contrast:** a test checks every foreground/background pair against WCAG (AA, and AAA in high contrast). The Flutter guideline tests check every gallery component in all four themes.
- **Shapes:** every rounded shape is a superellipse, through `AppRadius.shape`.

**Reason:**

- One place to change the look.
- Accessibility is enforced by tests rather than by eye.
- High contrast works as soon as the platform asks for it.

**Alternatives:**

- **Rejected:** `ColorScheme.fromSeed` (the Phase 1 stand-in). It can't express the warm neutrals or the three key tones.
- **Rejected:** a fourth, neutral tone for function keys. It would break the approved three-tone hierarchy.

**Impact:** Every new colour or text style starts as a token, with a contrast test and a gallery entry.

---

### [DEC-030] Component set: one widget per concept, with variants

- **Status:** Adopted (Phase 2; a deviation from the master prompt's component list, explained here; open to the user's review)
- **Date:** 2026-09-28
- **Implemented:** Yes (`lib/core/widgets/`)

**Context:** The master prompt listed AppButton, PrimaryButton, SecondaryButton, AppIconButton, CalculatorButton, OperatorButton, AppCard, AppBottomSheet, AppDialog, AppTextField, EmptyState, ErrorState, SectionHeader, AppHeader and AppBottomNavigation. It also said: "Do not duplicate UI code."

**Decision:**

- **`AppButton`** has variants (primary, secondary, text, destructive) instead of separate PrimaryButton and SecondaryButton classes.
- **`CalculatorButton`** has kinds (digit, operator, function, equals) instead of a separate OperatorButton.
- **`LoadingState`** was added, because the UI direction requires designed loading states. It shares a layout with `EmptyState` and `ErrorState`.
- **`AppBottomNavigation`** stays dropped (DEC-012).
- **Phase 1 stand-ins replaced:** `PlaceholderView` became `EmptyState`, and the settings page's private header became `SectionHeader`.
- **Mode sheet:** it became a grid of `AppCard` tiles, as the audit proposed, instead of a list.
- **Required accessibility inputs:**
  - `AppIconButton.tooltip`
  - `CalculatorButton.semanticLabel`
  - `AppTextField.label`

**Reason:** One widget per concept means sizes, shapes, loading and disabled states are defined once. Required labels make an unlabelled control impossible to write.

**Alternatives:**

- **Rejected:** one class per variant. It would duplicate the styling and behaviour, which the master prompt forbids.

**Impact:** New variants extend the existing widget, instead of adding a new class.

---

### [DEC-031] Filled text fields with the label inside the fill

- **Status:** Adopted (Phase 2; open to the user's review)
- **Date:** 2026-09-28
- **Implemented:** Yes (`AppTheme` input decoration theme)

**Context:** The first design-review screenshots showed each floating label sitting on the field's top edge. `OutlineInputBorder` places the label in a gap in the outline, which clashes with a filled field.

**Decision:**

- Use `UnderlineInputBorder`, rounded on every corner.
- The label floats inside the fill.
- The enabled field has no line, except in high contrast.
- Focus and error show a 2 px or 1 px line along the bottom.

**Reason:** This is Material's filled style, and it reads cleanly on the warm surfaces.

**Alternatives:**

- **Rejected:** outlined fields. They add more lines than the quiet style wants.

**Impact:** Only the theme changed; `AppTextField` is the same.

---

### [DEC-032] The component gallery is a separate debug-only entry point

- **Status:** Adopted (Phase 2; open to the user's review)
- **Date:** 2026-09-28
- **Implemented:** Yes (`lib/main_gallery.dart`, `lib/gallery/`)

**Context:** Phase 2 needed a debug-only screen showing every component for the design review.

**Decision:**

- The gallery runs with `flutter run -t lib/main_gallery.dart`, with switches for light/dark, high contrast and text size.
- `main.dart` never imports it, so it isn't in app builds.
- Its demo copy is not localized, because it is a developer tool.

**Reason:** The app has no debug routes or flags, and the gallery can't leak into a release.

**Alternatives:**

- **Rejected:** a debug-only route inside the app. It would put debug code paths into the app's navigation.

**Impact:** Every new component gets a gallery entry.

---

### [DEC-033] Design review through generated screenshots; accessibility through guideline tests

- **Status:** Adopted (Phase 2; open to the user's review). It answers how to review without an emulator (P-4).
- **Date:** 2026-09-28
- **Implemented:** Yes (`test/design_review/`, `dart_test.yaml`, `test/gallery/`)

**Context:** The user doesn't want an emulator, and Phase 2 must not depend on the physical device.

**Decision:**

- **Screenshots:** a tagged test renders 33 design-review screenshots with the real fonts into `build/design_review/`: gallery sections and app screens, in light, dark, high contrast and at 200% text.
  - It is skipped by default, and runs with `flutter test --tags design-review --run-skipped --update-goldens`.
  - The images are not committed and are not compared across machines.
- **Accessibility:** the normal test run checks every gallery section against Flutter's contrast, tap-target and label guidelines, in all four themes.

**Reason:** The design can be reviewed, by Claude and by the user, without a device. The accessibility checks run on every test run.

**Alternatives:**

- **Rejected:** committed golden images. They are platform-dependent, so they would fail on another operating system.
- **Deferred:** a run on the physical device, which the user can do.

**Impact:** After visual changes, regenerate and review the screenshots.

---

### [DEC-034] Screens use only the reusable widgets and tokens

- **Status:** Accepted (user requirement, 2026-09-28: *"ye dhyan rkhna ki mere app mai reusable wedgits use krna"*)
- **Date:** 2026-09-28
- **Implemented:** Yes (CLAUDE.md rule 12; ARCHITECTURE.md §1.2 and §1.8)

**Context:** The user asked for the app to use reusable widgets. The master prompt also forbids duplicated UI code.

**Decision:**

- Every screen is built from `lib/core/widgets/` and the tokens in `lib/app/theme/`.
- Feature code never copies colours, sizes, shapes or text styles.
- A widget needed by more than one screen goes into `core/widgets`, with tests and a gallery entry.

**Reason:** The user's explicit requirement, plus a consistent look and less code to maintain.

**Alternatives:** None.

**Impact:** Reviews of new screens check that they use only shared components.
