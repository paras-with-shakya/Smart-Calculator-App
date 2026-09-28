# Development Status

> **The most important file for context recovery.** Rewrite it to the current truth at the end of every meaningful session, following the Session Handoff Protocol in [CLAUDE.md](../CLAUDE.md). Every claim here must be backed by code, by Git, or by a command that was actually run.

**Last updated:** 2026-09-28, in the session that created the project-memory system.

## At a Glance

| Question | Answer |
| --- | --- |
| Where are we? | Between Phase 0 (audit and architecture, **complete**) and Phase 1 (Foundation, **not started**) |
| What exists in code? | Only the untouched `flutter create` counter template |
| What is being worked on? | No code work. The project-memory docs were just created and await the user's review. |
| What happens next? | The user reviews these docs, then gives or withholds the explicit go-ahead for Phase 1 |
| What must not be repeated? | The Phase 0 audit and the architecture validation (see "Do NOT Repeat") |
| Known issues? | Template-level only (see "Known Issues") |
| Pending decisions? | P-1 to P-8 below. The biggest is P-1, the Phase 1 go-ahead. |

## Current Phase

**Pre-Phase 1.** Phase 0 is complete. **Phase 1 (Foundation) has NOT started, and its implementation is NOT approved to begin.**

How approval got here, so that no new session misreads it:

1. **2026-09-28:** the user approved the Final Architecture Decision Report and listed 12 explicit decisions, including the Phase 1 scope (foundation only). These, together with the workflow and roadmap decisions from the same day, are recorded as DEC-001 to DEC-017 in [DECISIONS.md](DECISIONS.md).
2. Before any Phase 1 work began, the user interrupted and asked for the project-memory and status system to be set up first.
3. In the session that created these docs, the user stated: *"Phase 1 implementation has NOT been approved yet"* and *"the architecture/roadmap discussion has happened, but implementation is not yet approved."*

**So:** treat the architecture decisions as CONFIRMED and the Phase 1 scope as defined, but **do not start Phase 1 until the user explicitly says so.**

## Phase Status

| Phase | Name | Status |
| --- | --- | --- |
| 0 | Project audit and architecture | **Completed** 2026-09-28 (planning and validation only; no project files changed) |
| — | Project-memory system | **Completed** 2026-09-28; awaiting the user's review |
| 1 | Foundation | **Not started.** Scope approved; the start needs the user's explicit go-ahead (P-1). |
| 2 | Design system | Not started |
| 3 | Basic calculator (engine, memory) | Not started |
| 4 | History and saved calculations | Not started |
| 5 | Scientific | Not started |
| 6 | Converters | Not started |
| 7 | Financial | Not started |
| 8 | Date calculator | Not started |
| 9 | Programmer calculator | Not started |
| 10 | Settings screen | Not started |
| 11 | Polish | Not started |
| 12 | QA | Not started |

## Completed Work

### Phase 0: audit and architecture (2026-09-28, previous session)

- **Project audit.** Confirmed that the project is an untouched `flutter create` template: no calculator code, state management, routing, theme, assets or services. The findings are under "Known Issues" below.
- **Planning documents.**
  - Delivered the audit and plan report: architecture, dependencies, roadmap, UI/UX plan, implementation plan.
  - Then delivered the **Final Architecture Decision Report**.
- **Validation in a throwaway scratch project outside the repository.** None of these are tests of this repo, and none changed it.
  - `material_ui` is not required on Flutter 3.47.5, so framework Material stays (DEC-002).
  - Measured go_router 18 running with the framework `MaterialApp`, and compared release APK sizes (DEC-003).
  - Every planned dependency resolved at its latest version on Flutter 3.47.5 / Dart 3.13.4 (DEC-015).
  - Runtime smoke tests passed for a Riverpod notifier, `SharedPreferencesWithCache`, and in-memory SQLite through `sqflite_common_ffi`.
  - Exact arithmetic with `decimal` gave `0.1+0.2−0.3 == 0` and `(1÷3)×3 == 1`, and `2^100` came out exact.
  - A pub workspace containing a pure-Dart engine package resolved, and its tests ran under plain `dart test`. The analyzer requires `rational` as a direct dependency of the engine.
  - Android debug and release builds of the scratch project succeeded with the plugins included (AGP 9.1, Gradle 9.3.1, Kotlin 2.4).
- **Approval.** The user approved the plan and the final architecture: DEC-001 to DEC-017.

### Project-memory system (2026-09-28, this session)

- **Created:**
  - `CLAUDE.md`
  - `docs/PROJECT_MEMORY.md`, `docs/DEVELOPMENT_STATUS.md`, `docs/ARCHITECTURE.md`
  - `docs/DECISIONS.md`, `docs/ROADMAP.md`, `docs/CHANGELOG.md`
- **Also created** a short pointer file at `../CLAUDE.md`, the workspace folder `SmartCalculator/`, which sits outside the planned Git repo. It exists so that sessions started in the parent folder find this project's memory.
- **Unchanged:** no application code, configuration or dependencies.

## Work In Progress

None.

## Current Task

The user reviews the project-memory docs. No implementation task is active.

## Next Task

**Only after the user explicitly approves starting Phase 1:** do Phase 1 (Foundation) as scoped in [ROADMAP.md](ROADMAP.md#phase-1-foundation).

1. First ask about P-2 (what goes in the baseline commit) and P-3 (whether the app ID change belongs in Phase 1), unless they have already been answered.
2. Git setup: `git init` in `smart_calculator/`, branch `main`, `.gitattributes`, then the baseline commit.
3. Work through the rest of the Phase 1 scope in the order given in ROADMAP.md, following the per-module workflow.
4. Finish with the Phase 1 report in the user's required format (9 items; see ROADMAP.md), then **stop** and wait for Phase 2 approval.

## Do NOT Repeat

- **Don't redo the Phase 0 audit or the scratch-project validation.** The results are in [DECISIONS.md](DECISIONS.md).
  - Re-verify a specific fact only when there is a concrete reason, such as a Flutter upgrade.
  - Always re-verify a dependency's version and compatibility right before adding it (DEC-015).
- **Don't re-propose `material_ui` or `go_router`** without new evidence (DEC-002, DEC-003).
- **Don't delete** the web, Windows, Linux or macOS folders (DEC-004).
- **Don't invent or ask again for the application ID.** It is decided (DEC-005); only the timing is open (P-3).
- **Don't start Phase 1** without explicit approval. Inside Phase 1, don't start Phase 2 work: no final calculator UI, no scientific keypad, no engine logic.
- **Don't push** to any remote.
- **Don't treat as fact** the example "Development Status" template the user pasted in the previous session. Its "Completed" list (Riverpod 3, the calculation engine package, theme foundation, persistence foundation) was a format example. **None of those exist yet.**

## Pending Decisions

| ID | Decision | Needed by | Notes |
| --- | --- | --- | --- |
| **P-1** | Go-ahead to start Phase 1 | Before any Phase 1 work | The user said implementation is not yet approved |
| **P-2** | What goes in the Git baseline commit | Phase 1, step 1 | See note P-2 below the table |
| **P-3** | When to apply the app ID and display name | Phase 1 start | See note P-3 below the table |
| **P-4** | Android test device | From the Phase 2 design review | See note P-4 below the table |
| **P-5** | iOS verification: does the user have access to a Mac? | Before any iOS claim | Without one, iOS stays correct by design but unverified |
| **P-6** | Engine default behaviours | Before Phase 3 engine work | Proposed in the final report; the user did not object but has not explicitly confirmed. See [PROJECT_MEMORY.md](PROJECT_MEMORY.md#calculation-correctness-principles). |
| **P-7** | App version source for the About screen | Phase 10 | `package_info_plus` (pulls in `http` and `win32`) or a build-time constant |
| **P-8** | Fonts | Phase 2 | Proposed: Manrope, pending a check that it has tabular digits, and JetBrains Mono for programmer mode. Licenses must allow bundling. |

**P-2, baseline commit.** The user asked for *"the untouched Flutter scaffold as the baseline commit,"* but `CLAUDE.md` and `docs/` now exist in the folder. Suggested:

- commit 1: the scaffold only, excluding `CLAUDE.md` and `docs/`
- commit 2: the project-memory docs

**P-3, app ID timing.** The confirmed values are ID `com.parasshakya.smartcalculator` and display name "Smart Calculator". Two instructions conflict:

- Approval item 4 says to apply them consistently and report exactly what changed.
- The approved Phase 1 scope (item 12, *"implement only the items you listed"*) does not include them, and the final report said *"App IDs and design work aren't part of Phase 1."*

Ask the user which applies.

**P-4, test device.** On 2026-09-28, `flutter devices` showed a physical Android device connected: model `23124RN87I`, Android 15 (API 35). No emulators exist. The user has not confirmed that this is the intended test device.

## Important Files

| File | State (verified 2026-09-28) |
| --- | --- |
| `pubspec.yaml` | Template: `name: smart_calculator`, description "A new Flutter project.", `version: 1.0.0+1`, SDK `^3.13.4` |
| `lib/main.dart` | Template counter demo (`MyApp`, `MyHomePage`), 122 lines. To be replaced in Phase 1. |
| `test/widget_test.dart` | Template "Counter increments smoke test". To be replaced in Phase 1. |
| `analysis_options.yaml` | `package:flutter_lints/flutter.yaml` only; platform folders excluded. Stricter rules are planned for Phase 1. |
| `android/app/build.gradle.kts` | `namespace` and `applicationId` = `com.example.smart_calculator`; release signs with the debug key (template TODO) |
| `android/app/src/main/AndroidManifest.xml` | `android:label="smart_calculator"`; no INTERNET permission (good, keep it) |
| `android/app/src/main/kotlin/com/example/smart_calculator/MainActivity.kt` | Package `com.example.smart_calculator`; the folder moves when the ID changes |
| `ios/Runner.xcodeproj/project.pbxproj` | `PRODUCT_BUNDLE_IDENTIFIER = com.example.smartCalculator` (and `.RunnerTests`); `IPHONEOS_DEPLOYMENT_TARGET = 15.0` |
| `ios/Runner/Info.plist` | `CFBundleDisplayName` = "Smart Calculator"; `CFBundleName` = `smart_calculator` |
| `web/manifest.json`, `web/index.html` | Name `smart_calculator`, description "A new Flutter project." (web isn't a supported target) |
| `CLAUDE.md`, `docs/*.md` | The project-memory system (created 2026-09-28) |

## Dependencies

**Actually in `pubspec.yaml` and `pubspec.lock` (verified 2026-09-28):**

| Package | Constraint | Locked | Notes |
| --- | --- | --- | --- |
| `flutter` (SDK) | — | — | |
| `cupertino_icons` | ^1.0.8 | 1.0.9 | Unused; removal planned for Phase 1 |
| `flutter_test` (SDK, dev) | — | — | |
| `flutter_lints` (dev) | ^6.0.0 | 6.0.0 | Brings in `lints` 6.1.0 |

**Planned, but NOT installed.** These were verified in the scratch project on 2026-09-28 and must be re-verified when they are added. Details are in [ARCHITECTURE.md](ARCHITECTURE.md#dependencies-planned) and DEC-015.

| Package | Planned version |
| --- | --- |
| `flutter_riverpod` | ^3.4.3 |
| `shared_preferences` | ^2.5.5 |
| `sqflite` | ^2.4.4 |
| `path` | ^1.9.1 |
| `intl` | SDK-pinned |
| `flutter_localizations` | SDK |
| `decimal` (engine only) | ^3.2.6 |
| `rational` (engine only) | ^2.2.3 |
| dev: `sqflite_common_ffi` | ^2.4.3 |
| dev: `integration_test` | SDK |
| dev: `test` (engine) | — |

## Tests

These checks were run in this repository:

| Date | Command (in `smart_calculator/`) | Result |
| --- | --- | --- |
| 2026-09-28 (this session) | `flutter analyze` | `No issues found! (ran in 26.7s)`, exit 0 |
| 2026-09-28 (this session) | `flutter test` | `+1: All tests passed!` (the template "Counter increments smoke test"), exit 0 |

- **Coverage:** no project tests exist beyond the template test, and there are no engine tests yet.
- **Scratch-project results** from Phase 0 are listed under Completed Work. They are *not* results for this repository.

## Known Issues

All of these come from the template. None is a bug in project code, since there is none yet.

- **Placeholder IDs.** Android is `com.example.smart_calculator` (namespace, applicationId and the Kotlin package folder). iOS is `com.example.smartCalculator`. Google Play rejects `com.example.*` IDs. The fix is DEC-005, with the timing open (P-3).
- **Names.** The Android label and iOS `CFBundleName` are `smart_calculator`. The pubspec, web manifest and web `index.html` descriptions say "A new Flutter project."
- **Release signing.** Release builds are signed with the debug key (template TODO). This is not scheduled yet, but must be fixed before any release build is distributed.
- **Default launcher icons.** Planned for Phase 11.
- **Unused dependency.** `cupertino_icons` is unused.
- **Lints.** Only the default recommended lint set is enabled, with no strict analyzer modes.
- **No Git repository yet.**

## Blockers

- **Phase 1** is blocked on the user's go-ahead (P-1). P-2 and P-3 need answers at the start of Phase 1.
- **Technical limits on this machine** (not blockers for Phase 1):
  - iOS can't be built on Windows.
  - Windows desktop can't be built (no Visual Studio). Windows isn't a target, so this doesn't matter.

## Discrepancies Found

Found on 2026-09-28 while creating these docs.

1. **Stale auto-memory.**
   - Claude's local auto-memory said the architecture was "awaiting the user's explicit approval," but the previous session's transcript shows the user approved it.
   - It also described go_router and the app ID as open questions, but both were decided (DEC-003, DEC-005).
   - Resolved: these docs follow the user's own words from the transcript, plus the user's statement in this session that Phase 1 implementation is not yet approved.
2. **Example template treated as status.** The "Development Status" template the user pasted in the previous session listed items as "Completed" that don't exist in code. They are recorded here as not started.
3. **App ID timing.** The approval messages conflict about whether the app ID change is part of Phase 1. This is recorded as P-3, not guessed.
4. **Baseline commit.** The approved "untouched scaffold baseline commit" predates the docs that now exist in the folder. This is recorded as P-2.
5. **Where the docs live.** The docs structure the user pasted in the previous session placed `CLAUDE.md` and `docs/` inside `smart_calculator/` without `PROJECT_MEMORY.md`. This session's request added `PROJECT_MEMORY.md`. The docs follow the latest request, inside `smart_calculator/`, the planned Git root.

## Last Session Summary

**2026-09-28, project-memory session.**

- **Inspected:** the full project structure, `pubspec.yaml` and `pubspec.lock`, the Android and iOS identifiers, the toolchain (`flutter --version`), connected devices, Git (not initialized) and Python (only the Store stub).
- **Checked:** ran `flutter analyze` (clean) and `flutter test` (1 passed).
- **Reconstructed** the decisions from the previous session's local Claude Code transcript (the user's own messages and Claude's reports) and from Claude's auto-memory. Where they differed, the transcript won.
- **Created** the project-memory docs.
- **Unchanged:** no source, configuration or dependencies. Phase 1 was not started.

## Instructions For Next Session

1. Follow the Context Recovery Protocol in [CLAUDE.md](../CLAUDE.md).
2. Check whether the user has given the Phase 1 go-ahead (P-1). If they haven't, don't start Phase 1; help with whatever they ask, or ask them.
3. When Phase 1 is approved:
   - Settle P-2 and P-3 first.
   - Then carry out the Phase 1 scope exactly as listed in [ROADMAP.md](ROADMAP.md), and nothing from Phase 2 or later.
   - Re-verify each dependency right before adding it.
   - Run `flutter analyze`, `dart format .` and `flutter test`, and record the actual results.
   - Make one local commit; never push.
   - Deliver the 9-item Phase 1 report, then stop.
4. At the end of the session, follow the Session Handoff Protocol. That includes moving implemented items in [ARCHITECTURE.md](ARCHITECTURE.md) from Proposed to Implemented.
