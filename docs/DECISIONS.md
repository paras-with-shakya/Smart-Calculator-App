# Decisions

This is the architecture and product decision record. It is **append-only**: when a decision changes, set its status to `Superseded` (or `Rejected`) and add a new entry that references it. Never delete an entry. The reasons are the point of this file.

**Status values:**

| Status | Meaning |
| --- | --- |
| `Accepted` | Decided by the user; may or may not be implemented yet (see "Implemented") |
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
- **Implemented:** No (Phase 1)

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

- **Status:** Accepted (values); **when to apply them is pending (P-3)**
- **Date:** 2026-09-28
- **Implemented:** No. The code still has Android `com.example.smart_calculator` and iOS `com.example.smartCalculator`.

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

**Impact:** The approved Phase 1 scope list doesn't include this step, and the final report said app IDs weren't part of Phase 1. Ask the user whether it belongs in Phase 1 (P-3).

---

### [DEC-006] Local Git repository, never pushed

- **Status:** Accepted
- **Date:** 2026-09-28
- **Implemented:** No. Git is not initialized, verified 2026-09-28.

**Context:** The folder isn't a Git repository, which is risky for a 12-phase build.

**Decision:**

- Initialize Git in `smart_calculator/` on branch `main`.
- The first commit is the untouched Flutter scaffold, as a baseline.
- Make one local commit after Phase 1, and meaningful commits after each major phase from then on.
- Add a `.gitattributes` file for consistent line endings (a proposed default the user didn't object to).
- **Never push to any remote.**

**Reason:** The user approved this.

**Alternatives:** None considered.

**Impact:** `CLAUDE.md` and `docs/` now exist before `git init`. How the baseline commit should handle them is pending (P-2).

---

### [DEC-007] State management: Riverpod 3 without code generation

- **Status:** Accepted
- **Date:** 2026-09-28
- **Implemented:** No (the dependency is added in Phase 1)

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
- **Implemented:** No. Phase 1 creates only an **empty** package skeleton; the engine logic comes in Phase 3.

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
- **Implemented:** No (settings storage and database v1 are in Phase 1)

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
- **Implemented:** No. Only the template test exists.

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
- **Implemented:** No. Design-system work starts in Phase 2. Phase 1 builds only the basic theme structure and placeholder screens, and no feature UI is built before the Phase 2 design review is signed off.

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
- **Implemented:** No (the adaptive shell with placeholder screens comes in Phase 1)

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
- **Implemented:** Policy (applies whenever a dependency is added)

**Context:** The user said: don't add dependencies because they are popular, and verify that each one is compatible and maintained.

**Decision:**

- Before adding a package, verify that it is compatible with Flutter 3.47.5 / Dart 3.13.4 and actively maintained.
- The planned set is listed in ARCHITECTURE.md ("Dependencies (planned)"). It was verified 2026-09-28 in a scratch project: each package resolved at its latest version, none is discontinued, all were released within the past year, and each passed a runtime smoke test.
- **Deferred:**
  - `package_info_plus` (P-7), which pulls in `http` and `win32`
  - `http`, until live currency rates exist
- **To remove:** `cupertino_icons` (unused).

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

- **Status:** Accepted (scope). **The start of Phase 1 is not approved yet (P-1).**
- **Date:** 2026-09-28
- **Implemented:** No

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
