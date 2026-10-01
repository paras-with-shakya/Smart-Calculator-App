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
- **Implemented:** Yes (2026-09-28): repository in `smart_calculator/` on branch `main`. Commits: the untouched scaffold with `.gitattributes` (`8ca813c`), the project-memory docs (`813533e`), the app identity (`06c0a93`), then the Phase 1 foundation. Claude has never pushed; see the update below about the user's remote.

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

**Update, 2026-09-28 (after Phase 1):**

- The user added the GitHub remote `origin` (`https://github.com/paras-with-shakya/Smart-Calculator-App.git`) and pushed `main` up to `01f120a`, outside Claude's sessions.
- Claude found this in the Phase 2 session, through `git branch -vv` (`origin/main` at `01f120a`, a `FETCH_HEAD` file present). Claude has never pushed or fetched.
- The rule for Claude: **never push, and never add or change remotes.** The user said on 2026-09-28: *"tumko mera code push nhi krna, mere github mai khud krunga"*, meaning they push their own code. Claude makes local commits only (CLAUDE.md rule 10).
- **The user confirmed (2026-09-28):** they pushed the app to GitHub themselves, and the remote stays as it is.

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
- **Implemented:** Yes (Phase 3, commit `4fec0b6`): the engine for the basic calculator, with `rational` only (DEC-038) and 260 tests. Floating point for irrational results and the programmer evaluator come in later phases.

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
- **Implemented:** The engine gate is met for the basic calculator (Phase 3): 260 engine tests, including 224 table-driven cases and a 20,000-input fuzz test. Function edge cases (√−1, log 0, factorial) come with the functions in Phase 5. Integration tests: none yet.

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

- New pages follow ARCHITECTURE.md §1.16 ("How to extend").
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
- Phase 3/5 must decide the landscape calculator layout. **Resolved by DEC-042** (phones in landscape: no history panel below 480 dp height).

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

---

### [DEC-035] Single choices use the adaptive AppChoiceGroup

- **Status:** Adopted (fix for a bug found on the user's phone, 2026-09-28; open to the user's review)
- **Date:** 2026-09-28
- **Implemented:** Yes (`lib/core/widgets/app_choice_group.dart`, commit `950493b`)

**Context:** On the user's phone (360 dp wide, 200% system font), the settings page's segmented theme control broke "System" as "Syste/m". The 200% widget tests had covered only the shell.

**Decision:**

- Every "pick one of a few" control uses the reusable `AppChoiceGroup`.
- **How it chooses a layout:** it measures each label at the current text scale, allowing for Material 3's segment padding, icon, gap and border (56 dp at 100%, an upper bound).
  - If every label fits on one line, it shows a segmented button.
  - Otherwise it shows a vertical radio list (`RadioGroup` with `RadioListTile`), which screen readers announce as a mutually exclusive group.
- **Background:** the list is wrapped in a transparent `Material`, so it works on any background.

**Reason:** No label is ever broken mid-word, whether from large text or long translations. It is one reusable control for this and the Phase 10 settings (angle mode, precision, default mode).

**Alternatives:**

- **Rejected:** always a radio list (less compact at normal size).
- **Rejected:** shrinking or ellipsizing the labels (it defeats the user's text size).

**Impact:**

- Tests measure the layout with the real Manrope font, because the default test font is much wider.
- A regression test covers the settings page at 200% on a 360 dp phone.

---

### [DEC-036] Smart percent (resolves the percent part of P-6)

- **Status:** Accepted (user decision, 2026-09-28)
- **Date:** 2026-09-28
- **Implemented:** Yes (`packages/calc_engine/lib/src/eval/evaluator.dart`, commit `4fec0b6`)

**Context:** Calculators treat `%` differently. P-6 listed the proposed defaults.

**Decision:** `%` is a postfix operator.

- **After `+` or `−`:** the percent is of the left operand. `50+10%` = 55, and `50−10%` = 45.
- **Elsewhere:** `b%` means b/100. `50×10%` = 5, `50÷10%` = 500, and a lone `10%` = 0.1.

**Reason:** The user chose this ("Smart percent"). It matches common phone calculators.

**Alternatives:**

- **Rejected by the user:** plain percent, where `50+10%` = 50.1.

**Impact:**

- The other P-6 defaults (`−3²`, `2^3^2`, `0^0`, `(−8)^(1/3)`, `tan 90°`) concern powers and trigonometry. They are settled before Phase 5.

---

### [DEC-037] Numbers are formatted for the phone's region

- **Status:** Accepted (user decision, 2026-09-28)
- **Date:** 2026-09-28
- **Implemented:** Yes (`lib/core/formatting/`, commits `57a1e73` and `85c6c84`)

**Context:** Large numbers need digit grouping, and regions differ. India uses 12,34,567.89; many other regions use 1,234,567.89; some use a comma as the decimal separator.

**Decision:** Displayed numbers follow the device's region: its grouping pattern and its decimal and group separators. The user's `en-IN` phone therefore shows 12,34,567.89. The engine works with locale-neutral canonical strings, and the presentation layer localizes them.

**Reason:** The user chose this ("Phone region follow").

**Alternatives:**

- **Rejected by the user:** always international, or always Indian.

**Impact:**

- The app's UI language stays English (the only supported locale), but number formatting uses the device region.
- Digits stay Latin (0–9).


---

### [DEC-038] The engine uses `rational` only; `decimal` is not added

- **Status:** Adopted (Phase 3 implementation; refines DEC-008 and DEC-019; open to the user's review)
- **Date:** 2026-09-28
- **Implemented:** Yes (`packages/calc_engine/lib/src/number/calc_value.dart`, commit `4fec0b6`)

**Context:** DEC-008 and DEC-019 planned `decimal` and `rational` for the engine. DEC-008 noted that `decimal` has a single maintainer and no verified publisher.

**Decision:**

- `CalcValue` wraps a `Rational` (package `rational` ^2.2.3, locked at 2.2.3). Only `src/number/` imports it.
- Decimal output is the engine's own code (`CalcValue.toDecimalString`), working on the exact fraction.
- `test` ^1.31.1 is the engine's dev dependency. 1.32 needs a newer `test_api` than the Flutter SDK pins.

**Reason:** Every basic operation is exact with fractions, and formatting needs only integer arithmetic. `decimal` would add a dependency without adding anything.

**Alternatives:**

- **Rejected:** adding `decimal` as planned. It is unused, and weaker on maintenance.

**Impact:**

- Replacing the numeric library later touches only `src/number/`.
- Irrational results (roots, trigonometry) come with Phase 5, which decides how they are represented.

---

### [DEC-039] Engine semantics and limits for the basic calculator

- **Status:** Adopted (Phase 3 implementation; open to the user's review)
- **Date:** 2026-09-28
- **Implemented:** Yes (`packages/calc_engine`, commit `4fec0b6`; 260 engine tests)

**Context:** P-6 and DEC-010 list behaviours that must be fixed before the engine counts as correct.

**Decision:**

- **Pipeline:** lexer → recursive-descent parser → syntax tree → exact evaluation. Input symbols: digits, `.`, `+ − × ÷` (and `- * /`), `%`, brackets, and letter-only variables (used for exact values; DEC-040).
- **Precedence:** unary minus, then postfix `%`, then `× ÷`, then `+ −`, all left to right.
- **Implied multiplication** has the same precedence as `×`: `2(3)`, `(2)(3)`, `(2)3` and `50%2`. So `6÷2(1+2)` = 9.
- **Results:** 12 significant digits, rounded half away from zero, with trailing zeros removed and never `-0`. Scientific notation is used from 10¹² up, and below 10⁻⁶.
- **Errors** are values (`CalcFailure`), never exceptions: empty, syntax, incomplete (the input ends too early), division by zero (including `0÷0`), and overflow.
- **Limits:** overflow at 10¹⁰⁰ in size (any intermediate value); at most 100 nested brackets and 1000 tokens. Pathological input fails fast rather than freezing. A 20,000-input fuzz test checks that nothing throws.

**Reason:** Common phone-calculator conventions, with safe limits.

**Alternatives:**

- **Rejected:** implied multiplication binding tighter than `÷` (which makes `6÷2(1+2)` = 1). That rule differs between calculators, and same-precedence is the simpler one to explain.

**Impact:** The input limits of the expression buffer (DEC-040) keep ordinary typing well inside these limits.

---

### [DEC-040] Calculator input, results and errors

- **Status:** Adopted (Phase 3 implementation; open to the user's review)
- **Date:** 2026-09-28
- **Implemented:** Yes (`lib/features/calculator/domain/` and `application/`, commit `57a1e73`)

**Context:** The roadmap proposed token-based editing with a cursor, a live preview, a smart `( )` key and long-press ⌫ to clear.

**Decision:**

- **The expression is a list of units** (one per key press) with a cursor. The input rules keep it sensible:
  - no leading zeros; one decimal point per number (`.` alone types `0.`); at most 15 digits per number and 100 units in all
  - a new operator replaces the previous one, except that `−` after `×` or `÷` starts a negative number
  - `%` only after an operand, and `)` only when a bracket is open
  - `×` is inserted when a number, bracket or value follows `)`, `%` or a value, so two operands never look like one number
  - the single `( )` key closes a bracket when one is open and an operand comes before the cursor, otherwise it opens one
- **Exact values:** a result or the memory is inserted as one unit holding the exact fraction. So `1÷3=`, then `×3=`, gives exactly 1. Backspace removes such a value in one step.
- **Live preview:** the value of the expression with open brackets closed, shown only when it is valid and more than a plain number.
- **After `=`:**
  - an operator or `%` continues from the exact result
  - a digit, the decimal point or a bracket starts a new expression
  - ⌫ clears the result; holding ⌫ clears everything at any time
  - a key the rules reject leaves the result in place
- **Errors** show a message under the expression, which stays editable. The next accepted edit clears the message. When closing brackets would turn an unfinished expression into a syntax error (`(5+`), it is reported as incomplete.
- **Paste** (Ctrl+V) is all or nothing: text with anything that isn't calculator input is not typed at all, because skipping characters could change a number (`1.5e12` would become `1.512`).

**Reason:** These are the proposed behaviours from the roadmap, plus the rules needed to make them exact and predictable.

**Alternatives:**

- **Rejected:** inserting the result as its displayed digits, which loses precision.
- **Rejected:** clearing the expression when an error appears.

**Impact:** Scientific mode (Phase 5) reuses the buffer and adds function units.

---

### [DEC-041] Memory keys are always visible; no "more" menu yet

- **Status:** Adopted (Phase 3 implementation; open to the user's review)
- **Date:** 2026-09-28
- **Implemented:** Yes (`CalculatorMemoryKeys`, `MemoryNotifier`, `PreferencesMemoryRepository`)

**Context:** The roadmap's Phase 3 header listed a "more" menu. The master prompt requires MC, MR, M+, M− and MS.

**Decision:**

- **A memory row** (MC MR M+ M− MS) sits between the display and the keypad, always visible.
  - MC and MR need a value in memory; M+, M− and MS need a value on the display (the result or the live value). Keys that can't act are disabled.
  - A small "M" badge on the display shows the value in memory.
- **The memory is saved** under the preference key `calculator.memory` as an exact fraction (such as `1/3`), so it survives restarts exactly. A value of 10¹⁰⁰ or more is refused, and the memory keeps its value.
- **No "more" menu in Phase 3.** It would have nothing to hold yet. It can be added with the first item that needs it.

**Reason:** Memory one tap away is faster than a menu, and a menu with no items would be clutter.

**Alternatives:**

- **Rejected:** memory functions inside a "more" menu.
- **Rejected:** an empty "more" menu to match the roadmap wording.

**Impact:** The header is unchanged: mode, history and settings.

---

### [DEC-042] Calculator layouts, including phones in landscape (resolves the open item in DEC-022)

- **Status:** Adopted (Phase 3 implementation; open to the user's review)
- **Date:** 2026-09-28
- **Implemented:** Yes (`CalculatorView`, `AppShell`, commit `85c6c84`); checked on the user's phone in both orientations

**Context:** DEC-022 left the phone-landscape calculator layout to Phase 3. Most phones in landscape are "expanded" by width, so the shell showed a 320 dp history panel there too.

**Decision:**

- **Portrait** (taller than wide): display, memory row and keypad in a centred column at most 480 dp wide. Keys are square unless the keypad would take more than 60% of the height.
- **Landscape** (wider than tall): the display and memory row on the left; the keypad on the right, taking 55% of the width (at most 480 dp), aligned to the bottom.
- **Short windows** (under 480 dp tall, Material's compact height): tighter spacing, so keys keep their 48 dp touch target. On the user's phone in landscape they are 49 dp.
- **Shell:** an expanded window shorter than 480 dp shows no history panel. The history action opens the page instead, as on medium windows.

**Reason:** A phone in landscape has about 280 dp of height for the calculator; a history panel there would squeeze it.

**Alternatives:**

- **Deferred to Phase 5:** scientific keys beside the keypad in landscape.

**Impact:** Tablets in landscape keep the history panel.

---

### [DEC-043] The calculator display, and two additions to the components

- **Status:** Adopted (Phase 3 implementation; open to the user's review)
- **Date:** 2026-09-28
- **Implemented:** Yes (`lib/core/widgets/display_text.dart`, `CalculatorButtonKind.memory`, `CalculatorDisplay`)

**Context:** DEC-034 requires reusable components. The display needs text that shrinks to fit, a caret and tap-to-move, which no existing component provided.

**Decision:**

- **`DisplayText`** (new, in `core/widgets`): end-aligned text that shrinks down to 50% to stay on one line, then wraps at that size. It can draw a caret at a text offset, reports taps as text offsets, and has a semantics label and an optional live region. Programmer and finance screens can reuse it.
- **`CalculatorButtonKind.memory`** (new): no fill, a smaller label in the muted text colour, and no high-contrast outline, so the memory row stays quieter than the keypad.
- **The display:** the memory badge; the expression the result came from; the main line (the expression with a caret while the cursor is not at the end, or the result); and below it, the live preview or the error. Every line keeps its height when empty, and a muted `0` shows before anything is typed. The result fades in (reduced motion respected).
- **Line breaks:** a long expression wraps only after a binary operator (a zero-width space marks the spot), never inside a number that fits on a line.
- **Screen readers** hear words, not symbols: "12 plus 3", "Preview: 15", "Equals 15" (a live region), "Memory: 42".

**Reason:** The user's reusable-widgets requirement, and a display that stays readable at any length and text size.

**Alternatives:**

- **Rejected:** `FittedBox` scaling of the whole display. It can't wrap, and the text would become unreadably small.
- **Rejected:** memory keys as `AppButton`s. Their labels could break mid-word at large text sizes (the DEC-035 bug).

**Impact:** Both additions have tests and gallery entries.

---

### [DEC-044] History: what's stored, and what "reuse" and "copy" do

- **Status:** Adopted (Phase 4 implementation; open to the user's review)
- **Date:** 2026-09-29
- **Implemented:** Yes (`lib/features/history/`, `packages/calc_engine` untouched)

**Context:** ROADMAP.md's Phase 4 scope: each history item stores the expression, result, timestamp and mode; view, search, reuse, copy, delete one, clear all. The `history` table (schema v1, DEC-023) already fixes the columns: `expression`, `result`, `mode`, `created_at`, all `TEXT`/`INTEGER`. Nothing had decided yet exactly what those columns hold or what tapping an entry does.

**Decision:**

- **`expression`** is locale-neutral display text only, built by a new `ExpressionBuffer.toCanonicalText()`: typed symbols pass through as-is, and any inserted value (a previous result or the memory) is written as its own decimal text, not as a reusable variable. It is **never re-parsed**.
- **`result`** is stored exactly, the same way the calculator memory is (`CalcValue.toStorageString()`, DEC-041), so it survives a restart exactly.
- **`mode`** is a new `CalculatorModeStorage.storageId` extension on `CalculatorMode` (fixed strings, not enum names, the same convention `ThemePreference` uses) — not the schema's job to invent, but needed the moment anything writes to it.
- **Reuse** (tapping an entry) inserts the entry's exact `result` at the cursor, exactly like MR inserts the memory (a new `CalculatorNotifier.useHistoryResult`). It does **not** try to restore the original editable expression. On a pushed page (compact and medium windows) it also pops back to the calculator; on the always-visible panel (expanded windows) it doesn't, since there's nothing to pop.
- **Copy** puts the entry's formatted result on the clipboard (`Clipboard.setData`), with a brief confirmation.
- **Delete** removes one entry immediately (a trailing icon button, not swipe). **Clear all** asks for confirmation first (`showConfirmationDialog`, `isDestructive: true`).
- **Every successful `=`** adds an entry; a failed `=` does not. Repeated identical results are **not** deduplicated — history is a log, not a set.
- **Search** filters client-side over the loaded list, matching the stored expression text or the formatted result.
- **Not built, by decision:** grouping by Today/Yesterday/earlier, paging, swipe-to-delete with Undo, a result "tape," and a retention limit — all explicitly marked *(Proposed)* in ROADMAP.md's Phase 4 section, not required by its "Done when" gate.

**Reason:**

- Storing only the exact result (not a re-editable expression) mirrors a precedent the engine already established: after `=`, continuing an expression or recalling the memory both act on the exact `CalcValue`, never on re-parsed expression text (DEC-040). A second serialization scheme for "restore the whole editable expression" would be new complexity solving a problem the app doesn't otherwise have, and reusing the MR mechanism means no new engine-facing code path at all.
- Keeping `expression` locale-neutral and display-only (rather than trying to re-localize a stored mixed string of symbols and numbers) avoids a second, partial number-formatting path outside `LocalizedNumberFormat`.

**Alternatives:**

- **Rejected:** serializing the full expression buffer (units and cursor) so reuse restores it editable. More moving parts, and no existing precedent in this codebase to build on; deferred unless the user asks for it.
- **Rejected:** deduplicating repeated identical calculations. Users may deliberately recompute the same thing at different times, and a log is simpler to reason about than a merged set.
- **Rejected:** swipe-to-delete for v1. A visible, labelled icon button is more discoverable and easier to get right for accessibility than a gesture, and the "Done when" gate doesn't ask for it.

**Impact:** `ExpressionBuffer` gained one pure, side-effect-free method (`toCanonicalText`); `CalculatorNotifier` gained `useHistoryResult` and a call into `historyProvider` on a successful `=`. No changes to `packages/calc_engine` or to the approved calculator screen's layout.

---

### [DEC-045] Every widget test gets an isolated in-memory database

- **Status:** Adopted (Phase 4 test-infrastructure fix; open to the user's review)
- **Date:** 2026-09-29
- **Implemented:** Yes (`test/helpers/test_app.dart`, `lib/app/app_root.dart`, `lib/core/persistence/app_database.dart`)

**Context:** Until Phase 4, nothing read `appDatabaseProvider` (DEVELOPMENT_STATUS.md, Known Issue #10), so no widget test ever needed a database. Wiring history into the calculator and the shell's history panel meant every `pumpApp`-based test could now reach it, including ones that never mention history (any test at an expanded window size touches `HistoryPanel`, which is always visible there).

**Decision:**

- `AppRoot` takes an optional `overrides` parameter (`List<Override>`), applied after its own preferences override, so tests can override further providers without wrapping `AppRoot` in a second `ProviderScope`.
- `pumpApp` overrides `appDatabaseProvider` with a fresh in-memory database (`sqflite_common_ffi`, `inMemoryDatabasePath`) for every test.
- `AppDatabase.open` gained an optional `singleInstance` parameter (default `true`, unchanged for the real app). Tests pass `false`, because sqflite caches a database by path for `singleInstance: true` (the correct choice for the app's one real file) — without it, every test in a process would share the *same* in-memory database, and history from one test would leak into the next.
- The app depends on `riverpod` directly (already resolved transitively through `flutter_riverpod`, same publisher), because `flutter_riverpod`'s public API doesn't re-export the `Override` type `AppRoot.overrides` needs to be typed with.

**Reason:**

- A `ProviderScope` nested around `AppRoot` doesn't work for this: Riverpod resolves an unscoped provider (everything in this app; none use explicit `dependencies:` scoping) at the *root* `ProviderScope`, wherever that provider's override happens to be set — not at the nearest ancestor. Wrapping `AppRoot` in an outer `ProviderScope` with a database override made the *root* become that outer scope, which broke `AppRoot`'s own `sharedPreferencesProvider` override (verified: it throws "must be overridden," reproducibly, until the fix). Every override the app needs has to be in the single list `AppRoot` builds.
- Verified directly (not assumed): without `singleInstance: false`, `calculator_notifier_test.dart`'s history tests accumulated rows across unrelated tests in the same file; with it, each test starts empty.

**Alternatives:**

- **Rejected:** a second `ProviderScope` wrapped around `AppRoot`, for the reason above.
- **Rejected:** a real temp-file database per test (more moving parts — directory creation and cleanup — for no benefit over true in-memory).

**Impact:** Any future provider that owns a real resource (another database-backed feature, a future network client) follows this same pattern: override it through `AppRoot.overrides`/`pumpApp`, not a wrapping `ProviderScope`.

---

### [DEC-046] Saved calculations: where "save" lives, and what it means for now

- **Status:** Adopted (Phase 4 implementation; the user delegated this design to Claude — "jaisa tum karo, waha karo," 2026-09-29)
- **Date:** 2026-09-29
- **Implemented:** Yes (`lib/features/saved_calculations/`, `lib/features/history/presentation/history_content.dart`)

**Context:** ROADMAP.md's Phase 4 scope: "save, rename, edit, reuse and delete" a calculation. P-12 asked how saving should be triggered from the calculator screen; the user's answer was to let Claude decide ("however you do it, do it there"). The constraint carried into that decision: the calculator screen and the app shell (mode pill, history/settings icons) are the *already-approved* Phase 2/3 UI (DEC-011, DEC-012, DEC-022), and shouldn't gain new tap targets without being asked for.

**Decision:**

- **No new UI on the calculator screen or the shell header.** Saved calculations live entirely inside the screen History already owns.
- **A tab toggle** (`AppChoiceGroup`, History/Saved) sits above `HistoryContent`'s list, shared by the history page and panel. Switching tabs resets the search field.
- **Saving is triggered from a history entry**, not the calculator: a third action (a bookmark icon, alongside copy and delete) opens a name sheet (`showAppBottomSheet` with an `AppTextField`; the action button is disabled until the name is non-empty).
- **`SavedCalculation`** mirrors `HistoryEntry`'s shape (name plus the same exact expression/result), stored in the existing `saved_calculations` table's `inputs_json` as `{"expression": ..., "result": ...}`. `kind` is a fixed `'basic'` for now — no other calculator produces a saved calculation yet.
- **"Rename" is "edit," for now.** A basic saved calculation has no inputs to edit beyond its name; richer editing (loan amount, interest rate, and so on) arrives with the calculators that need it (Phase 7).
- **Reuse, search and clear-all** work exactly like History's (DEC-044): reuse inserts the exact result at the cursor; clear-all asks for confirmation first; each tab's search and clear-all act only on that tab's list.

**Reason:**

- Reusing the screen History already owns avoids a new navigation route and a new shell affordance for what is, functionally, "history you keep on purpose."
- `AppChoiceGroup`, `showAppBottomSheet` and `AppTextField` already exist and fit exactly; no new reusable component was needed (unlike History, which needed `DisplayText` and a memory key kind in Phase 3 — DEC-043).
- Triggering "save" from a history entry, rather than from the calculator mid-calculation, means the result is already known and exact by the time it's named — there's nothing to compute or validate.

**Alternatives:**

- **Rejected:** a third icon in the calculator header or the shell, next to history and settings. Touches the approved Phase 2/3 UI, which the user asked Claude not to do without being told to.
- **Rejected:** a separate pushed page/route for saved calculations. Splits two closely related lists (things you've calculated; things you chose to keep) across two navigation destinations for no real benefit.
- **Rejected:** letting "rename" also edit the expression or result directly. A saved basic calculation's expression and result are a historical fact (what was actually calculated); changing them would misrepresent what happened. A new calculation should be saved instead.

**Impact:** When a future mode (Phase 7's EMI, GST, and so on) needs to save its own kind of calculation, `SavedCalculation`, the repository and the notifier will need to grow to hold that kind's inputs — this decision's "`kind` is always `'basic'`" note is the marker for where that change starts.

---

### [DEC-047] Scientific engine: exact/approximate values, the power operator, and every function's domain (settles the rest of P-6)

- **Status:** Adopted; **explicitly approved by the user 2026-09-29**, first with "okay" (to a different session), then by naming all five defaults individually and instructing that they stay binding across the app and future phases unless a later documented decision changes them (recorded in full in DEC-049). Originally: Adopted (Phase 5, Module 1 implementation; open to the user's review — see DEVELOPMENT_STATUS.md's "Deviation" note, since this was built before the user confirmed the P-6 defaults, not after)
- **Date:** 2026-09-29
- **Implemented:** Yes (`packages/calc_engine`, commit `ef7b0ba`; 377 engine tests)

**Context:** ROADMAP.md's Phase 5 scope needs `^`, `!`, π, e, sin/cos/tan/asin/acos/atan/sinh/cosh/tanh, log/ln, sqrt/cbrt, abs, and degree/radian mode. P-6 left five defaults open before this could be built: `−3²`, `2^3^2`, `0^0`, `(−8)^(1/3)`, `tan 90°`. DEVELOPMENT_STATUS.md's own "Instructions For Next Session" said to settle P-6 *before* building the function registry; that didn't happen — see the deviation note below.

**Decision:**

- **`CalcValue` becomes a sealed hierarchy:** `_ExactCalcValue` (still `Rational`, as before) and a new `_ApproximateCalcValue` (`double`). Arithmetic is contagious: exact-op-exact stays exact; anything touching an approximate value becomes approximate. `isExact` is public so tests (and, later, the UI) can tell which kind a result is.
- **Exactness is preserved wherever it provably can be, not just where it's cheap:** `sqrt`/`cbrt` and the general `^` operator all detect perfect roots and perfect powers by integer binary search on `BigInt` (`_exactRoot`/`_exactPower`), for both positive and negative bases. So `sqrt(4)=2`, `(−8)^(1/3)=−2`, `4^0.5=2` and `(−8)^(2/3)=4` are all exact, not lossy doubles — matching the project's "exact where practical" principle (DEC-008) rather than reaching for a double the moment a root or a fractional exponent appears.
- **The power operator (P-6):** `^` is right-associative and binds tighter than unary minus but looser than postfix `%`/`!`. So `−3^2 = −9` (the minus applies after squaring), `2^3^2 = 2^(3^2) = 512`, and `2^3! = 2^(3!) = 2^6 = 64`. `0^0 = 1` (the common convention; there is no calculus context here to argue for leaving it undefined). `0^(negative)` is `CalcError.undefined`, not overflow — dividing by zero, not a value that's merely too large.
- **A negative base needs an odd-denominator (in lowest terms) rational exponent to have a real result** (`(−8)^(1/3)` is fine; `(−4)^(1/2)` and `(−1)^0.5` are `CalcError.undefined`, not `NaN` or a complex number).
- **New `CalcError.undefined`** (distinct from `divisionByZero`/`overflow`): a function argument outside its domain — `√−1`, `ln 0`, `asin 2`, `tan` at an odd multiple of 90°, a negative base with no real root, `0^(negative)`, or `!` of a negative or non-integer value.
- **Angle mode** is a new `AngleMode` enum (degrees/radians), threaded through `CalcEngine.evaluate(..., angleMode: ...)` as a third parameter, defaulting to degrees. It affects sin/cos/tan/asin/acos/atan only; the hyperbolic functions are never affected by it, matching every calculator's convention.
- **Floating-point noise at exact axis angles is snapped away**, not shown as noise: `cos(90°)` naturally computes to `6.12…e-17` in a double, not exactly `0`; sin/cos/tan results are snapped to `0` (and `tan` additionally checked for an exact input at an odd multiple of 90°, since a huge-but-finite double would otherwise silently stand in for "undefined") within `1e-10`. This mirrors the existing 12-significant-digit rounding — both exist so the *appearance* of a result matches its mathematical meaning, not raw IEEE 754 output.
- **`e` and `π` are always the constants, never a variable name** — even if a caller supplies a variable named `e` or `π` (which the app's `ExpressionBuffer` never does *by design*; see the buffer fix below, added for exactly this reason). Function names (`sin`, `sqrt`, …) require an immediately following `(`; without one, they parse as an ordinary (unresolved, unless supplied) variable, so `sin` alone doesn't call the function.
- **Implied multiplication is extended to a number directly followed by a name**: `2π`, `5sin(30)` now parse the way `2(3)` already did, since that was an existing inconsistency (a number before `(` already implied `×`; a number before an identifier didn't). Two numbers in a row (`1 2`) still does **not** imply multiplication — that stays a syntax error, unchanged from Phase 3 (DEC-039).
- **`ExpressionBuffer._variableName`** (the app's letter-naming scheme for inserted values: a, b, c, …) now skips the single letter `e`, so the 5th+ inserted value is never silently read back as Euler's number instead of the value the user actually inserted.

**Reason:** These are the standard conventions real scientific calculators use (Casio/TI), chosen because they're what users already expect, and because `0^0=1`/`(−8)^(1/3)` exact-real-root handling are the mathematically defensible reading given this engine has no complex-number support. `CalcError.undefined` is split from `overflow`/`divisionByZero` because the message a user needs is different ("this has no real answer" vs. "this number's too big" vs. "you divided by zero") and conflating them would misdirect the user editing their expression.

**Alternatives:**

- **Rejected:** always returning an approximate `double` for `^`/`sqrt`/`cbrt`, which is simpler but breaks exactness for the common case (perfect squares, perfect cubes) that Phase 3 already promised (DEC-008, DEC-039's "exact arithmetic instead of floating point").
- **Rejected:** treating `(−4)^(1/2)` as a syntax error instead of `CalcError.undefined`. The *expression* is syntactically fine; it's the *value* that has no real answer, which is exactly what `undefined` exists to say.
- **Rejected:** leaving `2π` as a syntax error (matching `2a`, a plain variable, exactly) on the reasoning that the app's keypad could always insert an explicit `×` before a constant key. Extending the grammar was simpler, matches how `2(3)` already behaves, and costs nothing: it only makes previously-rejected input succeed, so it can't change any currently-passing case (`'12a'` still fails, now at evaluation instead of parse time, since an unresolved variable `a` still throws `CalcError.syntax`).

**Deviation, flagged rather than silent:** DEVELOPMENT_STATUS.md's "Instructions For Next Session" (written at the end of the Phase 4 session) explicitly said to settle the rest of P-6 *before* building the engine's function registry. That didn't happen — Claude built the whole engine module (registry, power operator, all five P-6 defaults, and every scientific function) in the same pass, without first taking the five specific defaults back to the user for a yes/no. The defaults chosen are recorded above, exactly as implemented and tested; nothing about them requires more engine work to change if the user wants a different one (the specific case a different default would touch is footnoted directly in the code and this entry). Flagged here, and repeated in the session's chat report, so the user reviews these five decisions specifically rather than the module simply landing as a fait accompli.

**Impact:** `packages/calc_engine`'s public API (`calc_engine.dart`) now also exports `AngleMode`; `CalcEngine.evaluate` gained the `angleMode` parameter (default `AngleMode.degrees`, so every Phase 3/4 call site is unaffected). `lib/features/calculator/presentation/calculator_display_formatter.dart` needed a new switch case for `CalcError.undefined` (a new `errorUndefined` string in `app_en.arb`) purely to keep the existing exhaustive-switch compiling — this is not new scientific-mode UI, just what a non-exhaustive `switch` on the enum demanded the moment the engine gained the new error. Module 2 (the calculator's scientific input logic — buffer support for function calls, `^`/`!` keys, angle-mode state and persistence) and Module 3 (the scientific keypad) are not built yet.


---

### [DEC-048] Scientific input logic (Phase 5, Module 2): units, keys, angle mode, and how wrong input is handled

- **Status:** Adopted (Phase 5, Module 2 implementation; open to the user's review)
- **Date:** 2026-09-29
- **Implemented:** Yes (`lib/features/calculator/`, `lib/features/settings/`, one engine fix; 592 app tests + 387 engine tests)

**Context:** The user replied to the list of five P-6 defaults with "okay lekin mera app shi se work krna chahiye, koi galat and wrong equation ka kre, proper sb handle". Claude took that as (a) acceptance of the DEC-047 defaults and (b) a requirement that invalid, impossible and hostile input is handled properly. If they meant something else, DEC-047's defaults are cheap to change (see its "Deviation" note).

**Decision:**

- **Units.** `^`, `!`, `π` and `e` are single `SymbolUnit`s. A function opener (`sin(`, `sqrt(` …) is also **one** `SymbolUnit` whose symbol ends in `(`, so backspace removes the name and its bracket together and the engine reads the symbol text unchanged. `CalculatorSymbols.opensBracket` treats `(` and every function opener alike, so bracket counting, auto-closing at `=`, the smart bracket key, unary-minus detection and line-breaking all work for calls with no special cases.
- **Input rules** (extending DEC-040): `^` is a binary operator, and `−` after it is a sign (`2^−3`); `!` needs an operand before it and is refused after another `!`; a constant, a function opener or an inserted value next to an operand gets an **explicit** `×` (`2π` is shown `2×π`, `π2` is `π×2`), so nothing can be misread (the engine reads `2e3` as a syntax error but `2e` as 2×e, so leaving it implicit would be a trap); a typed number before an existing constant/function/value gets a `×` after it. Rejected keys return the same buffer, as before.
- **Keys.** `CalculatorKey` gained `power`, `factorial`, `pi`, `euler` and one key per `CalcFunction` (`CalculatorKey.function` gives the function). After `=`, an operator, `^`, `!` or `%` continues from the exact answer; a digit, constant, function or bracket starts a new expression (the existing DEC-040 rule).
- **Typed / pasted text** accepts `^`, `!` and `π`. It does **not** accept letters (`sin(30)`, `1.5e12`): the all-or-nothing rule stays, because reading a letter could silently change a number. Function names are keypad-only.
- **Angle mode** is `angleModeProvider` (`lib/features/settings/application/angle_mode_notifier.dart`), saved under `settings.angle_mode` as the fixed strings `degrees`/`radians` (unknown becomes degrees) through `SettingsRepository`. The calculator passes it to every `CalcEngine.evaluate`. Changing it applies at once and recomputes the live value and any error (`tan(90)` is undefined in degrees, fine in radians); an answer already shown is **not** recomputed. A failed save leaves the choice applied but not remembered.
- **Display.** `sqrt(`/`cbrt(` are shown as `√(` and `∛(`; everything else as typed. Screen readers get words (`square root of`, `to the power of`, `factorial`, `pi`) through 18 new `spoken*` strings.
- **Wrong and impossible input.** The input rules refuse what can be refused (a leading `^`/`!`, `)` without a bracket, `!!`), and `=` reports the rest as a typed error with the expression left editable (incomplete `sin(5+`, syntax, `tan 90°`/`√−1`/`ln 0`/`3.5!` undefined, `÷0`, overflow). Verified by a table of 21 such expressions and two seeded fuzz tests (400 runs of 30-40 random keys each) that check nothing throws, the state stays consistent (never a result and an error together, brackets never negative, at most 100 units) and the engine accepts whatever the buffer builds, in both angle modes.
- **One engine fix, found by stress-testing.** Powers with an exponent beyond ±2000 were always "overflow", including ones with an ordinary answer (`1.0000001^100000000` is about 22026.45). They now fall back to a double: a finite non-zero result is returned (approximate); infinity or underflow to zero is still overflow. No hang or exception was found for `99999999!`, `9^9^9^9`, `10^1000000` and similar (each under 40 ms).
- **`CalcFunction` is now exported** from `calc_engine.dart` (the keypad needs it).

**Alternatives:**

- **Rejected:** a separate `FunctionUnit` type. A symbol ending in `(` needs no new class and no change to the engine text.
- **Rejected:** implicit `×` for constants (`2π`): the engine accepts it, but `2e`/`e2`/`2e3` show why a visible `×` is safer.
- **Rejected:** accepting function names and `e` in pasted text (see above).
- **Left for Module 3:** where the degree/radian toggle sits on the keypad, and whether a function key after `=` should wrap the answer (today it starts fresh).

~~**Known limitation (same class as Phase 3's):** backspacing a constant or value can leave the `×` that was added next to it (`|×sin(`); `=` then reports "Invalid expression" and the expression stays editable.~~ **Fixed in DEC-049**, at the user's explicit request: unlike Phase 3's accepted limitations, this one was cleanly fixable without touching the grammar, so it was.

**Impact:** `SettingsRepository` gained `angleMode`/`setAngleMode`; `PreferenceKeys.all` gained `settings.angle_mode`. `CalculatorNotifier` reads `angleModeProvider` and listens to it. No screen, widget or layout changed; the keypad has no scientific keys yet (Module 3).

---

### [DEC-049] The P-6 defaults, formally confirmed; Module 2 audited; the orphaned-× limitation fixed

- **Status:** Adopted
- **Date:** 2026-09-29
- **Implemented:** Yes (`lib/features/calculator/domain/expression_buffer.dart`, one fix; test-only otherwise)

**Context:** Module 1 (DEC-047) was built before asking the user to confirm the five P-6 defaults, a flagged deviation. Module 2 (DEC-048) was then built and committed by a *different* Claude Code session (co-authored "Claude Sonnet 5.5") while this session was between turns — discovered by reading the actual file contents and `git log`, not assumed, since it contradicted this session's own prior belief that Module 2 hadn't started. The user's message that prompted this entry assumed Module 2 already existed, which is what confirmed it. That message: explicit, by-name approval of the five P-6 defaults, plus an instruction to audit Module 2 (not rebuild it) against a specific checklist, fix the orphaned-`×` limitation DEC-048 had documented as accepted, and not start Module 3.

**Decision:**

- **The five P-6 defaults are now formally confirmed, not merely "not objected to."** `−3² = −9`, `2^3^2 = 512`, `0^0 = 1`, `(−8)^(1/3) = −2`, `tan 90° → CalcError.undefined`. Per the user's explicit instruction, these are **binding across the whole app**, including future phases (a Programmer-mode power operator, for instance), unless a later decision explicitly changes them. The already-implemented DEC-047/048 work is **not to be reverted**.
- **Module 2 audit: every requested item verified against the actual code and tests, not read by name.** All checked out:
  - `2π`, `5sin(30)`, `2(3)`, `π2` all insert an **explicit** `×` in the buffer (DEC-048's own "Rejected: implicit × for constants" — the app doesn't lean on DEC-047's engine-level implied-multiplication grammar extension at all).
  - `e`/`π` are never read as variables (DEC-047), and the buffer's variable-naming scheme never produces one named `e` (its own regression test, from the Module 1 session).
  - `^`, `!`, every function, and degree/radian mode are table-driven and fuzz-tested end to end in `calculator_scientific_test.dart`, including that changing the mode recomputes a *live* value/error but not an answer already shown.
  - Invalid/incomplete/overflow/undefined input: the existing 21-case table and two 400-run fuzz tests, re-run and still passing.
  - Screen-reader labels: 18 `spoken*` strings, one per symbol/function, each verified to read sensibly.
  - Reusable components: Module 2 changed no screen; the new code extends the existing `SettingsRepository`/`CalculatorKey`/`CalculatorDisplayFormatter` rather than duplicating them. No violation found.
  - **One minor, genuinely out-of-scope gap noted, not fixed:** a base of exactly `1` or `−1` past the ±2000-exponent overflow cutoff returns an *approximate* `CalcValue` even though the true answer is exact (DEVELOPMENT_STATUS.md, Known Issues #15). Cosmetically invisible and narrow; left alone rather than expanding the audit's scope unasked.
- **The orphaned-`×` limitation is fixed**, not merely documented as accepted (unlike Phase 3's analogous edge cases, which the user previously judged acceptable — this one had a clean fix, so the user asked for it instead). `ExpressionBuffer.backspace()` now removes a `×` that ends up with nothing before it that ends an operand (buffer start, or right after an operator/open bracket/function opener) in the same backspace step. A `×` with a real operand before it (`5×`, mid-typing) is untouched — it's unfinished, not orphaned. The fix applies to constants, functions **and inserted values** alike (they share one insertion path), so it also closes a latent version of the same bug in the Basic/Phase-4 memory-recall path.
- **Module 3 was not started**, per the user's explicit instruction.

**Reason:** The user's instruction was specific and sequential — confirm semantics, audit before extending, fix the one concrete bug named, then stop. Each part is a direct, traceable response to that instruction, not a judgment call.

**Alternatives:**

- **Rejected:** leaving the orphaned-`×` case as an accepted limitation, the way Phase 3's `5×+3`/"two operands adjacent" cases were. The user distinguished this one explicitly ("Do NOT simply rely on `=` showing 'Invalid expression'"), and it had a genuinely small, grammar-preserving fix available, unlike those.
- **Rejected:** re-deriving or rebuilding Module 2 from scratch, on the theory that a different session's work should be distrusted. The committed code was read in full, understood, and audited on its own merits; it held up.
- **Rejected:** fixing the near-1-base exactness gap unasked. It wasn't part of the requested checklist, and the project's own norm is not to expand scope without being asked.

**Impact:** No engine or public-API change. `ExpressionBuffer` gains one new private helper (`_unitEndsOperand`, factored out of the existing `_endsWithOperand`) and a rewritten `backspace()`. Four regression tests added/updated in `expression_buffer_test.dart`. 596 app tests (was 592), 387 engine tests (unchanged).

---

### [DEC-050] The scientific keypad (Module 3): the tray, the two toggles, and the four composite keys

- **Status:** Adopted (Phase 5, Module 3 implementation; a detailed plan was written and approved before any code, per the user's explicit instruction)
- **Date:** 2026-09-30
- **Implemented:** Yes (`lib/features/calculator/{domain,presentation}/`, `lib/core/widgets/calculator_button.dart`, `lib/app/shell/app_shell.dart`, `lib/gallery/`; 645 app tests + 387 engine tests; phone-tested)

**Context:** Modules 1 (engine) and 2 (input logic) built and audited everything a scientific calculator needs to compute, but none of it was reachable by tapping — Scientific mode still showed the Phase 1 "not available yet" placeholder. The user gave a detailed brief (retain Basic as the foundation; add a dedicated, grouped function area rather than one overloaded keypad; a compact DEG/RAD control reusing the existing persisted angle mode; a 2nd/inverse toggle, mapped only to functions the engine actually has; a dedicated landscape layout that never forces in the history panel; reuse components; stay inside the approved Phase 2 design system) and asked for a written plan before any code. The plan was drafted, independently stress-tested by a second pass that caught two real bugs before implementation (below), then approved and built exactly as planned.

**Decision:**

- **One new screen, composed entirely from reused pieces.** `ScientificCalculatorView` (new file; `calculator_view.dart` untouched) reuses `CalculatorDisplay`, `CalculatorMemoryKeys` and `CalculatorKeypad` exactly as Basic does — same width cap, same square-key sizing math, same two-column landscape shape — and adds two new rows above the memory row: a DEG/RAD + 2nd toggle row, and `ScientificFunctionTray`. `app_shell.dart`'s mode switch now renders it for `CalculatorMode.scientific` (previously `EmptyState`); every mode shares one `calculatorProvider` (DEC-013).
- **The tray is one horizontally-scrollable row**, not a flat grid: `scientificKeyGroups` (new `lib/features/calculator/domain/scientific_keys.dart`, pure data, tested without pumping a widget) groups the 14 engine functions plus `^`/`!`/π/e into Trigonometry, Hyperbolic, Logarithms & powers, Roots and Other. Scrolling, not shrinking, is how more keys fit a 360 dp phone than would fit flat — every key stays a real `CalculatorButton` at the full 48 dp target.
- **DEG/RAD and 2nd are both a single `CalculatorButton` each, not `AppChoiceGroup`.** `AppChoiceGroup` is the right reuse for a persistent, always-both-options choice (History/Saved, the theme picker) — but it can switch to a vertical radio list at 200% text or long labels, which would overflow a fixed-height toggle row. A `CalculatorButton` never changes layout mode, only shrinks its label, so it was the safer fit for this exact shape. DEG/RAD's label carries the state directly (`"DEG"`/`"RAD"`); 2nd's does not (always `"2nd"`), so `CalculatorButton` gained one new optional parameter, `selected: bool = false`, tinted with `AppColors.primary`/`onPrimary` — not `primaryContainer`, which turned out to be byte-identical to `functionKey` in the light and high-contrast-light palettes (caught by the plan's independent review pass, verified in code before writing it). Every existing call site is unaffected by the new parameter's default.
- **The 2nd/inverse mapping is exactly seven pairs, nothing invented:** sin↔asin, cos↔acos, tan↔atan (`CalcFunction` already has all six); sqrt↔square (x²), cbrt↔cube (x³), log↔powerOfTen (10ˣ), ln↔powerOfE (eˣ) — the latter four via three new small, additive `ExpressionBuffer` methods (below), not new `CalcFunction`s. sinh/cosh/tanh/abs/`!`/π/e have no 2nd mapping and are unaffected by the toggle: the engine has no inverse-hyperbolic functions or nCr/nPr, so nothing was invented to fill that space. 2nd's own state is ephemeral (not persisted) — ordinary widget state, reset on restart or leaving the screen, matching how a physical calculator's 2nd key behaves and avoiding a second persisted-settings concept for something this transient.
- **Three new small, additive `ExpressionBuffer` methods**, not notifier-level chaining of existing ones — the plan's independent review pass found that naively chaining `insertOperator(power)` then `insertDigit` silently degrades to "just type a bare digit" wherever `insertOperator` already no-ops (an empty buffer, right after `(`, right after a function opener), since the chained call still runs against the *unchanged* buffer in that case:
  - `insertPowerOf(String digit)` (x²/x³): guards on `_endsWithOperand` first, mirroring `insertFactorial`'s own guard, before doing the operator-then-digit insert.
  - `insertPowerOfTen()`/`insertPowerOfE()` (10ˣ/eˣ): each is one atomic insert (a leading `×` after an existing operand, then the value/constant, then `^`), refused — like every other operand insert — when an operand already starts right after the cursor, since `^` must bind to the exponent typed next and there's no sensible place for an implied `×` in that position. The review also traced a rarer bug in the naive chained approach here (a misplaced auto-`×` relative to `^` when the cursor sits before an existing operand); the atomic version doesn't have it.
  - `square`/`cube` join `power`/`factorial` in the notifier's "continuing after `=`" branch (postfix, applies to what's already there); `powerOfTen`/`powerOfE` start a fresh expression, like a function key (prefix, a new value to work from).
- **A pre-existing Basic-calculator bug, found and reported, not silently touched.** `CalculatorMemoryKeys` (reused unchanged) already narrows its 5 keys below 48 dp width in the exact combination of landscape *and* 200% text — reproduced identically by pumping plain `CalculatorView`, so Module 3 didn't cause it; it just inherited an already-shipped gap by reusing the widget. Not fixed here: `calculator_memory_keys.dart` belongs to the already-approved Basic screen, and fixing it wasn't asked for. Recorded in DEVELOPMENT_STATUS.md's Known Issues; the new test that found it excludes memory keys from its touch-target check for this one combination, with a comment explaining why, rather than silently weakening the check for everything.
- **The gallery gained one new section** (`GallerySection.scientificKeys`), demonstrating the tray's key tones and both toggle states (including `selected: true`) with static, non-functional buttons — the same pattern the existing "Calculator keys" section already uses, and the reason `gallery_accessibility_test.dart` needed no changes to cover it (it iterates `GallerySection.values`).
- **Phone-tested** (`23124RN87I`, USB): mode switching, sin/cos/tan producing correct degree-mode results, the 2nd toggle's visual state and label swap (and that unmapped keys stay unchanged), the DEG↔RAD flip, the x² composite key (`4^2` → `16`, confirming the atomic-insert fix works on-device, not just in tests), the tray's horizontal scroll, and the landscape layout (rail, display, both new rows, keypad, no history panel). Every check passed.

**Reason:** Each design choice traces to something specific the user asked for or something the independent review pass actually found broken — not a preference exercised for its own sake. `AppChoiceGroup`'s rejection and `primaryContainer`'s rejection are both cases where the "obvious" reuse would have shipped a real defect; both were caught before writing any code, not after.

**Alternatives:**

- **Rejected:** a 3-column landscape layout (function tray as its own column, display and keypad narrowed to make room). Splitting 800 dp three ways left either the keypad or the display too narrow to be usable at this exact breakpoint; the 2-column shape (toggles and tray stacked into the existing display column) keeps the keypad and display exactly Basic's size.
- **Rejected:** the "pull-up tray from an fx handle" idea `ROADMAP.md` had proposed. A single always-visible, horizontally-scrollable row is the smaller, lower-risk first pass; the pull-up idea can still happen later as a pure presentation refinement, since it wouldn't change any of the domain/notifier work here.
- **Rejected:** silently fixing the pre-existing memory-key touch-target gap while in the area. It's real, but it's Basic's widget and wasn't part of what was asked; flagged instead, matching this project's standing rule not to expand scope unasked.

**Impact:** `CalculatorKey` gains four values (`square`, `cube`, `powerOfTen`, `powerOfE`), appended after the existing ones. `CalculatorButton` gains `selected` (default `false`, backward-compatible). `~35` new `app_en.arb` strings (tray labels/semantics, group names, toggle labels), regenerated via `flutter gen-l10n`. No engine change, no new dependency. Programmer mode (Phase 9), if it ever needs a similar toggle-style key, can reuse `CalculatorButton.selected` directly rather than inventing its own.

### [DEC-051] Phase 6, Converters: the affine conversion model, the gallon and currency scope, and two implementation simplifications

- **Status:** Adopted (a detailed plan was written, independently reviewed and approved before any code, per this project's now-standard practice for a non-trivial new feature — DEC-050 set the precedent)
- **Date:** 2026-09-30
- **Implemented:** Yes (`lib/features/converter/{domain,application,presentation}/`, `lib/app/shell/app_shell.dart`, `lib/features/settings/*`, `lib/gallery/`; new tests throughout — see DEVELOPMENT_STATUS.md "Tests")

**Context:** The user approved Phase 5 and asked for the next phase to start. `ROADMAP.md`'s Phase 6 scope (six physical categories plus a currency design, "no network yet") explicitly left two things open: US or imperial gallon, and how far the currency design should go. No detailed brief was given for this phase (unlike Module 3's), so a plan was written and independently reviewed before any code — the same practice that caught two real bugs in Module 3 caught one more here (below) before it shipped.

**Decision:**

- **One affine transform covers every category, including temperature.** Every unit converts to/from its category's base unit via `toBase(v) = v*scale + offset`, `fromBase(b) = (b-offset)/scale`; a purely proportional unit (km, lb, gallon, …) just has `offset = 0`. This avoids a separate temperature-specific code path for the one category that genuinely needs an offset.
- **The independent review pass caught the classic temperature bug before any code existed:** the first draft copied `+32` from the familiar `F = C×9/5+32` formula directly into Fahrenheit's `offset` — but `offset` must be in *base-unit* (Celsius) terms for the `toBase` direction, and `+32` is from `fromBase`. The correct pair is `scale = 5/9`, `offset = −160/9` (i.e. `−32 × 5/9`). Caught and corrected in the plan itself, then locked in by fixed-point tests (0°C=32°F=273.15K, 100°C=212°F=373.15K, −40°C=−40°F) so a future change to this table can't silently reintroduce the same bug.
- **Volume's gallon is the US liquid gallon** (`3.785411784 L`, exactly `231 in³`), id `gallonUs` (not bare `gallon`) so an imperial gallon can be added later as a new id, never a rename of something that might already be persisted as "last used unit." Labeled `"gallon (US)"` on screen so it's never ambiguous. The imperial gallon isn't built.
- **Currency is a real, working category, not a placeholder:** one short, curated list (USD/EUR/INR/GBP — DEC-051 chose a curated list over all of ISO 4217, matching the "no network yet" scope), USD fixed as the base (`scale = 1`), every other currency's rate ("how many of this currency per 1 USD," matching how a person actually phrases a rate) user-editable and persisted locally via the same `SettingsRepository` pattern as everything else — never fetched, no network call anywhere, matching the app's no-`INTERNET`-permission constraint. Built via `currencyCategory(ratesPerUsd)`, a function (not `const` data) that constructs the category from the live rates, so the exact same `ConversionUnit.toBase`/`fromBase` mechanism used everywhere else needs no special case for currency.
- **`NumberEntryBuffer`, a deliberately much simpler sibling of `ExpressionBuffer`:** no cursor, no operators, no brackets — a conversion is "one optionally-negative number," so this is a small, direct, plain-string class (digit/decimal-point/sign-toggle/backspace/clear), not a cut-down `ExpressionBuffer`. Non-temperature categories refuse the minus sign at the buffer level (`toggleSign(allowed:)`), not just by hiding the key, so a category that shouldn't allow negative amounts never can, regardless of how it's driven.
- **A new, separate `ConverterNotifier`/`ConverterState`, not an extension of `calculatorProvider`.** DEC-013's reason for Basic and Scientific sharing state (switching mid-calculation, one cursor, one memory, one history) doesn't apply here: a conversion has no expression, no operators, no memory recall.
- **Reused as-is:** `AppCard` (the category-tile grid and the From/To cards — preferred over `AppChoiceGroup`, which falls back to a vertical radio list once labels stop fitting a segmented row, likely with 7 category options), `CalculatorButton` (the compact numeric keypad, built directly from it — not `CalculatorKeypad`, which is wired to the main calculator's own notifier and grammar), `showAppBottomSheet`/`AppTextField` (the searchable unit-picker sheet, mirroring `history_content.dart`'s own search pattern), `AppIconButton` (swap, and a currency unit's "edit rate" action), `AppDialog`'s sibling pattern (a small `AlertDialog` with an `AppTextField`, for editing a currency's rate — `AppDialog` itself is message-only and doesn't fit a form field, so this one dialog is built directly rather than stretching that component to do something it wasn't designed for), `LocalizedNumberFormat` (region-correct grouping/decimal separator for both the typed amount and the computed result, so a converted number looks consistent with the rest of the app without depending on `calc_engine`/`CalcValue` — conversion factors are inherently approximate (km↔miles), so the engine's exact-rational arithmetic isn't the right tool here; plain `double` math is used throughout instead).
- **Two implementation simplifications versus the plan's literal wording, made without asking first, flagged here:**
  1. The plan's `SettingsRepository` interface was worded as per-category "last used units" (`lastConverterUnits(category)` — a separate remembered from/to pair for each of the 7 categories). Implemented as a single, category-independent `lastConverterUnits` pair instead (whichever category was last active), mirroring `AngleModeNotifier`'s own single-piece-of-state simplicity, and needing 2 preference keys instead of 14+.
  2. The plan specified a separate `ConverterPreferencesNotifier`, mirroring `AngleModeNotifier`/`SettingsRepository`. Persistence was folded directly into `ConverterNotifier` instead — `AngleModeNotifier` is separate mainly because *both* the settings screen and the calculator notifier need to read it; no second consumer exists for converter preferences.
  Both are reductions in scope/complexity within the plan's intent, not changes to it; the user hasn't been asked about either specifically, and both are easy to split out later if a second consumer for converter preferences ever appears.
- **`swap()` keeps the typed amount's text unchanged, rather than re-typing the previous result.** An earlier draft tried to carry the computed result across as new typed text (an `insertRaw(double)` extension on `NumberEntryBuffer`, string-parsing a double back into digits) so swap would "continue from the result" the way the main calculator continues from an exact result after `=`. Dropped before it shipped: Dart's `double.toString()` can produce scientific notation (`1e-10`) for very small/large values, which a char-by-char parse doesn't handle, and doing this exactly would need its own number-to-text formatting layer just to undo the split `NumberEntryBuffer` exists to avoid. `swap()` now only exchanges `fromUnitId`/`toUnitId`; the same typed amount, now interpreted in the other unit, naturally gives a new result.

**Reason:** Every design choice traces to either the plan's explicit reasoning or something the independent review pass verified before writing code — the temperature offset sign, in particular, is the single most common bug in this exact kind of feature, and it was caught before it ever ran once, not found by a test after the fact.

**Alternatives:**

- **Rejected:** the imperial gallon, in addition to or instead of the US gallon. Not requested, and would double the id/label surface for one unit; can be added later as a new id without touching anything existing.
- **Rejected:** a currency placeholder (visibly present, editing disabled, "coming later" label). The plan flagged this as the phase's single biggest open scope question; proceeded with the fuller, real-working-category version since nothing in the "done when" bar or the user's later approval objected to it.
- **Rejected:** reusing `calc_engine`/`CalcValue` for conversion math. Conversion factors are approximate by nature; the engine's exact-rational machinery solves a problem this feature doesn't have.
- **Rejected:** history integration (a conversion showing up in the History tab). Out of scope for this phase — `HistoryEntry` has no notion of a category/unit pair, and adding one wasn't asked for.

**Impact:** New feature directory `lib/features/converter/`, fully additive. `SettingsRepository`/`PreferencesSettingsRepository`/`PreferenceKeys` gain six new members (category, units, three currency rates), additive only — existing theme/angle-mode behaviour re-verified by re-running their existing tests unchanged. `app_shell.dart` gains one new switch arm. The gallery gains one new section. No engine change, no new dependency, and `calculator_view.dart`/`scientific_calculator_view.dart`/`calculator_notifier.dart`/`calc_engine`/`HistoryEntry` are all untouched, exactly as the plan specified.

### [DEC-052] Phase 7, Financial: seven independent tools, the share-of-whole bar over a donut, and the GST split convention

- **Status:** Adopted (a detailed plan was written, then independently, adversarially reviewed for financial-formula correctness and architectural soundness before any code — the same practice DEC-050/DEC-051 established; the review confirmed every formula correct but found five real implementation gaps, all fixed in the plan before coding started)
- **Date:** 2026-10-01
- **Implemented:** Yes (`lib/features/financial/{domain,application,presentation}/`, `lib/core/widgets/share_of_whole_bar.dart`, `lib/app/shell/app_shell.dart`, `lib/features/settings/*`, `lib/gallery/`; 1356 app tests + 387 engine tests; phone-tested)

**Context:** The user approved Phase 6 and asked for Phase 7 (Financial) with a detailed process brief of their own: audit the repo, write a plan, have the plan independently reviewed specifically for financial-formula correctness (incorrect formulas, sign conventions, rounding, division-by-zero, validation-range mistakes), then implement, test, phone-test and document. `docs/ROADMAP.md`'s Phase 7 scope is seven tools (EMI; simple and compound interest; GST with CGST/SGST/IGST; discount, tip and percentage) plus "charts where they genuinely help," with the specific chart forms and several other details explicitly left as `(Proposed)` design latitude.

**Decision:**

- **No unifying domain abstraction across the seven tools, unlike Converter's `ConversionCategory`.** Converter's 7 categories are all the same shape (`(units, allowsNegative)` + one `convert()`), so one class covered all of them. Financial's 7 tools are genuinely different shapes — EMI takes 3 inputs and produces 3 outputs, GST takes 2 inputs plus a mode toggle and produces 3, percentage takes a 3-way *operation* choice with a different input shape per operation. Each tool gets its own small, independent domain file (a validation-errors type, a `validate...Inputs` function, a `...Result` type, a pure `calculate...` function); they're unified only at the presentation layer by a `FinancialToolId` enum, a picker, and a `switch`.
- **No per-tool Riverpod `Notifier`.** Every input is a plain `AppTextField` (the gallery's own pre-existing `_InputsSection` already demos exactly this shape for a loan amount/interest rate pair), not a custom on-screen keypad — Basic/Scientific/Converter need a keypad because they model "type a number with domain-specific grammar" (cursor, implied multiplication, decimal rules); a financial tool's inputs are just standard decimal fields. Each tool view is a plain `StatefulWidget` with one `TextEditingController` per field, merged under one `ListenableBuilder` so the result and every field's error recompute live on each keystroke. The only new Riverpod piece is `financialToolProvider`, mirroring `AngleModeNotifier`'s shape (not `ConverterNotifier`'s bigger one) — there's no shared amount/unit state to carry, only "which tile is selected."
- **Every formula independently re-derived and hand-checked, not copied from a template:** `EMI = P·r·(1+r)ⁿ/((1+r)ⁿ−1)` (r=0 special-cased to `P/n`); `SI = P·R·T/100`; `A = P·(1+R/(100·n))^(n·T)` with `n` a required, user-selectable compounding frequency (annual/semi-annual/quarterly/monthly — never hardcoded to one); GST exclusive (`gst = amount·rate/100`) and inclusive (`base = amount/(1+rate/100)`); discount (`discountAmount = price·discount%/100`); tip (with an optional per-person split); three percentage operations. The classic EMI reference example (₹100,000 at 10% for 12 months → ₹8,791.59) was checked twice independently (by hand during planning, then cross-checked again during the adversarial review) and confirmed to the cent, then again on the user's phone.
- **The CGST/SGST/IGST convention, stated precisely since it's easy to get backwards:** the domain layer computes only `{baseAmount, gstAmount, totalAmount}` from one `GstMode` (exclusive/inclusive); the intra-state/inter-state choice is a **presentation-only** toggle over the *same* `gstAmount` (`cgst = sgst = gstAmount/2`, or `igst = gstAmount` — the whole figure), never a different total. A CGST/SGST chart was deliberately not built: CGST and SGST are, by definition, always exactly half of the same amount, so a chart of that split would show a constant 50/50 regardless of input — zero data-dependent information, failing "genuinely helps understanding" on its face.
- **Chart scope: one reusable `ShareOfWholeBar` (`lib/core/widgets/`), not a donut, not `CustomPaint`.** Used for EMI (principal vs. interest) and GST (base vs. GST amount) — qualifying for `core/widgets/` under CLAUDE.md rule 12 (used by more than one screen), unlike feature-local widgets like `ConverterCard`. A 2-segment donut/pie is a documented anti-pattern for comparing two close-ish part-to-whole values; a horizontal proportional bar is the standard, more legible form for exactly this job, and the roadmap's chart *type* was explicit design latitude, not a mandate — the *requirement* ("charts where they help") is satisfied either way. No `CustomPaint` is used anywhere in this app yet, and a 2-segment bar needs none: it's a `Row` of flex-proportioned, rounded, themed containers plus a legend. Color convention: `secondary`/`onSecondary` for the *base* segment, `primary`/`onPrimary` for the *added* segment (interest, GST) — the accent always marks the part worth noticing, consistent across both uses, using only colour roles the app already has and already contrast-checks.
- **The percentage-tool scope:** one flexible tool with three operations ("X% of Y", "X is what % of Y", "increase/decrease Y by X%"), reasoned from the roadmap's own wording — "discount, tip **and** percentage" is one grouped bullet, unlike EMI/GST's own dedicated bullets, read as percentage being the lighter, generalized sibling of the other two, not a request for several more full calculators.
- **Persistence: the last-selected tool only**, mirroring `lastConverterCategory` exactly (one new `SettingsRepository` member, one new `PreferenceKeys` constant). No per-field value is persisted (loan amount typed in, etc.) — explicitly the roadmap's own "(Proposed): save and reuse," out of scope this phase, mirroring DEC-051's identical call for Converter's typed amount.
- **Validation bounds chosen without an explicit brief ask, each a judgment call, open to revision:** EMI tenure ≤600 months (50 years — a UX sanity bound, not numeric); EMI/simple/compound-interest rate ≤1000%; simple/compound-interest time ≤100 years; GST rate ≤100% (jurisdiction-agnostic, not a hardcode of India's specific slabs, which stay free-entry presets); discount ≤100% (rejected over, never clamped — would make price negative); tip ≤100% (a fat-finger guard, not a mathematical ceiling).
- **Five concrete fixes added by the independent adversarial review, before any of this shipped:**
  1. **A `NaN`/`Infinity` guard.** An uncapped rate combined with a long tenure/time can overflow `double` to `Infinity` (`(1+r)ⁿ` for extreme `r`), making EMI/compound-interest evaluate to `NaN` — which would otherwise render as the literal text "NaN" in the result card. Fixed by capping rate at 1000% *and*, belt-and-braces, having every `calculate...` function check `.isFinite` before returning (mirroring `calc_engine`'s own `CalcError.overflow` precedent).
  2. **A missing validation bound.** The first draft gave EMI's tenure an explicit bound but left simple/compound interest's time field completely unvalidated — inconsistent for the same kind of input. Added `0 < T ≤ 100` years.
  3. **An unspecified rounding rule.** EMI's years→months tenure toggle had no stated behaviour for a fractional year. Fixed: round-to-nearest whole month (`(years×12).round()`), e.g. `2.33` years → 28 months, applied before the `≤600` bound check.
  4. **A genuine crash path in `ShareOfWholeBar`.** Its proportion formula, `(value/total*1000).round()`, throws `UnsupportedError` in Dart if `total=0` (confirmed by direct test: `(0.0/0.0).round()` throws). Not reachable today (both call sites already guarantee `total>0` via their own validation), but undocumented — fixed with an explicit `assert(total > 0, ...)` precondition and a doc comment, so a future caller can't ship the same crash silently.
  5. **A landscape layout that didn't fit the content.** The first draft proposed mirroring Converter's 2-column landscape split (picker+cards left, keypad right). The review identified why that doesn't transfer: Converter's split works because its right-hand pane is a self-contained physical keypad that never summons the system keyboard; Financial's fields all pop the *system* numeric keyboard, which on a real landscape phone covers much of an already-short screen, and a forced split would also leave the 7-tile picker at half-width mid-form. Fixed: one scrollable column, unchanged between portrait and landscape — confirmed on the user's phone with the keyboard actually open on the heaviest tool (EMI), where the focused field auto-scrolls into view above the keyboard with no overflow.

**Reason:** The user's own brief specifically asked for formula correctness to be independently verified, not assumed — and a genuinely separate review pass (re-deriving every formula from scratch, reading the actual source files rather than trusting citations) is what caught the five fixes above before they shipped, exactly mirroring how DEC-050's and DEC-051's review passes each caught something real.

**Alternatives:**

- **Rejected:** a donut/pie chart for EMI and GST, literally following the roadmap's proposed chart type. Documented anti-pattern for this data shape; the bar satisfies the actual requirement.
- **Rejected:** `CustomPaint` for the chart. No graphics package or precedent exists in this codebase yet; unjustified new surface area for a shape three `Container`s already solve.
- **Rejected:** a forced generic "FinancialTool" abstraction across all seven tools, to mirror Converter's `ConversionCategory`. Would produce a lowest-common-denominator shape fitting none of the seven well.
- **Rejected:** per-field persistence (save and reuse). Explicitly the roadmap's own deferred "(Proposed)" item.
- **Rejected:** history/saved-calculations integration for financial results. Out of scope, mirrors DEC-051's identical, explicit rejection for Converter.
- **Rejected:** an amortization schedule/chart and a compound-interest growth-over-time chart. Different, higher-effort chart forms sharing no code with the bar; "(Proposed)" only, and building them unasked would be exactly the kind of extra bespoke chart work the user's own brief warned against.

**Impact:** New feature directory `lib/features/financial/`, fully additive. One new reusable core widget, `ShareOfWholeBar`. `SettingsRepository`/`PreferencesSettingsRepository`/`PreferenceKeys` gain one new member (last tool), additive only — existing theme/angle-mode/converter tests re-verified unchanged. `app_shell.dart` gains one new switch arm. The gallery gains one new section. No engine change, no new dependency, and `calculator_view.dart`/`scientific_calculator_view.dart`/`converter_view.dart`/`calculator_notifier.dart`/`calc_engine`/`HistoryEntry` are all untouched.


### [DEC-053] Phase 8, Date calculator: calendar dates in UTC, months defined by `addMonths`, and one shared month-end rule

- **Status:** Adopted (a plan was written, then independently reviewed before any code, the same practice as DEC-050 to DEC-052; the review found real defects, listed below).
- **Date:** 2026-10-01
- **Implemented:** Yes (`lib/features/date_calculator/`, `lib/core/widgets/{app_date_field,result_row}.dart`, `lib/core/formatting/{localized_date_format,date_format_provider}.dart`, `lib/core/time/clock_provider.dart`, `lib/app/shell/app_shell.dart`, `lib/main.dart`, `lib/gallery/gallery_sections.dart`). Phone test pending.

**Context:** The user approved Phase 8 with "okay start phase 8" and no detailed brief. ROADMAP.md fixed the scope (date difference in days/weeks/months/years; add or subtract; no time-zone bugs) and proposed UTC calendar-date arithmetic with month-end clamping.

**Decision:**

- **A date is a calendar date, not an instant.** Every domain function takes and returns `DateTime.utc(y, m, d)`; anything from a picker or the clock goes through `calendarDate()`, which keeps only year, month and day. Nothing in the domain reads a time zone or a time of day, so daylight saving cannot move a result by a day. Domain functions `assert(isUtc)`.
- **Add/subtract.** Days and weeks move by exact calendar days. Months and years move by calendar months (a year is 12 months) and clamp to the target month's last day: 31 Jan + 1 month = 28 Feb (29 in a leap year); 29 Feb 2024 + 1 year = 28 Feb 2025. Years 1 to 9999 are supported; a result outside them is reported (`outOfRange`), never wrapped. The amount is a whole number from 0 to 1,000,000.
- **Difference.** The months are the *largest* `m` with `addMonths(earlier, m) <= later`, and the days are what is left (0 to 30). This ties the two tools together: `dateDifference(a, addMonths(a, k))` is always exactly `k` months 0 days, so 31 Jan to 30 Apr is 3 months 0 days, 31 Jan to 28 Feb is 1 month 0 days, 29 Feb 2024 to 28 Feb 2025 is 1 year 0 days. Also shown: total days, whole weeks plus days, and total months. The order of the two dates does not matter (the gap is always positive).
- **Screen.** One scrollable column in portrait and landscape (the DEC-052 reasoning: the amount field raises the system keyboard). A two-way choice (Difference / Add or subtract); dates default to today and are not persisted; no Riverpod notifier (local state, like the financial tools).
- **Reusable pieces (rule 12).** `AppDateField` (core), `ResultRow` and `ResultPlaceholder` (moved to core from the financial feature, because two features now use them), `LocalizedDateFormat` + `dateFormatProvider` (core, mirroring DEC-037's number format), `clockProvider` (core, so tests pin "today"). `AppTextField` gained `readOnly`, `onTap`, `suffixIcon` rather than a second text-field widget being written.
- **Region.** The device region's date order is used (like numbers), which needs date data for that region; `initializeLocalizedDates` loads it in `main`, because Flutter only loads plain `en`. Unknown regions fall back to English.
- **Picker range** 1 Jan 1900 to 31 Dec 2200 (`date_pick_range.dart`): a picker over 10,000 years is unusable, while the domain accepts years 1 to 9999 (reachable by typing an amount).
- **Plurals.** Unit counts use ICU `one`/`other` plurals; parts are joined with a separate `dateSpanJoin` message so translations can reorder; zero parts are omitted, and an all-zero gap reads "0 days".

**Defects found by the independent review of the first draft, all fixed before coding:**

1. The difference algorithm (`months--` when the end day is before the start day) disagreed with `addMonths`' clamping (31 Jan to 30 Apr gave 2 months 30 days; 257 round-trip pairs failed in the reviewer's sweep). Replaced by the "largest `m`" definition, with a property test the first draft's own planned test would not have caught.
2. The DST tests could not prove anything on this machine; the guarantee is now structural and the tests describe themselves honestly.
3. The amount limit (1,000,000) and the digit limit (7) disagreed; a "too large" message was added.
4. `showDatePicker` asserts initial date within range; `AppDateField` clamps.
5. Removing the "not available yet" placeholder would have broken Programmer mode; only the Date arm was added.
6. The device-region date order needed `initializeLocalizedDates` (see above).
7. Result values can be long prose ("Wednesday, September 29, 2027"); `ResultRow.wrapValue` lets them wrap instead of truncating with an ellipsis.
8. Accessibility: a merged semantics node and a live region for the result. A further gap was found while testing (a read-only text field cannot be activated by a screen reader); fixed in `AppDateField`.

**Alternatives:**

- **Rejected:** `DateTime` local arithmetic (`difference().inDays`, `add(Duration(days: n))`), which is off by one across a daylight-saving change.
- **Rejected:** the "borrow days from the previous month" difference algorithm, which disagrees with the add tool at month ends.
- **Rejected:** an "include the end day" toggle, working-day (business-day) counts and holidays: beyond the roadmap's scope. Possible later additions.
- **Rejected:** persisting the chosen dates or tool, and history / saved-calculations integration (the same reasoning as DEC-051 and DEC-052).

**Impact:** New feature directory, additive. `FinancialResultRow` was renamed and moved (import and rename only). `AppTextField` gained three optional parameters. `main` now awaits `initializeLocalizedDates`. The "not available yet" fallback now covers only Programmer.
