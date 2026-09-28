# Development Status

> **The most important file for context recovery.** Rewrite it to the current truth at the end of every meaningful session, following the Session Handoff Protocol in [CLAUDE.md](../CLAUDE.md). Every claim here must be backed by code, by Git, or by a command that was actually run.

**Last updated:** 2026-09-28, at the end of the Phase 1 session.

## At a Glance

| Question | Answer |
| --- | --- |
| Where are we? | **Phase 1 (Foundation) is complete** and awaits the user's review. **Phase 2 has not started and needs explicit approval.** |
| What exists in code? | The Phase 1 foundation: startup, Riverpod, typed navigation, an adaptive shell with placeholder screens, the theme with a persisted light/dark/system choice, preferences and database v1, l10n, and an empty engine package. **No calculator features.** |
| What is being worked on? | Nothing |
| What happens next? | The user reviews the Phase 1 report, then approves Phase 2 or asks for changes |
| What must not be repeated? | The Phase 0 validation and the Phase 1 setup steps (see "Do NOT Repeat") |
| Known issues? | Two local-machine build quirks (P-9, P-10), a `dart format .` crash on `build/`, and template leftovers (see "Known Issues") |
| Pending decisions? | P-4 to P-10 |

## Current Phase

**Phase 1 (Foundation): completed on 2026-09-28**, and awaiting the user's review.

- The user approved Phase 1 on 2026-09-28 with explicit decisions: navigation option A, standard Material, the app identity, Riverpod 3 without code generation, the persistence choices, the platform strategy, no emulator, Git on `main` with no push.
- It was built to the approved scope only (see [ROADMAP.md](ROADMAP.md) for each scope item).
- **Phase 2 (Design system) must not start without the user's explicit approval.**

## Phase Status

| Phase | Name | Status |
| --- | --- | --- |
| 0 | Project audit and architecture | Completed 2026-09-28 |
| — | Project-memory system | Completed 2026-09-28 |
| 1 | Foundation | **Completed 2026-09-28** (commits `06c0a93`, `7926920`); awaiting review |
| 2 | Design system | Not started; **pending approval** |
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

### Phase 0 (2026-09-28, earlier session)

- Audited the project; wrote the audit and plan report and the Final Architecture Decision Report.
- Validated the plan in a throwaway scratch project: `material_ui`, go_router, the dependencies, exact arithmetic, the workspace, Android builds. The results are in DECISIONS.md.
- The user approved DEC-001 to DEC-017.

### Project-memory system (2026-09-28)

- `CLAUDE.md` and `docs/` (DEC-018), committed as `813533e`.

### Phase 1: Foundation (2026-09-28, this session)

What was implemented; details are in [ARCHITECTURE.md](ARCHITECTURE.md) §1.

- **Git** (DEC-006):
  - `git init` in `smart_calculator/` on `main`
  - `.gitattributes` (`* text=auto`, with binary markers for `*.png` and `*.ico`)
  - commits:
    - `8ca813c` baseline scaffold
    - `813533e` project-memory docs
    - `06c0a93` app identity
    - `7926920` Phase 1 foundation
    - a following docs commit
  - Nothing is pushed, and there is no remote.
- **App identity** (DEC-025), on Android and iOS:
  - `com.parasshakya.smartcalculator`, "Smart Calculator"
  - the Kotlin package moved to `com/parasshakya/smartcalculator`
- **Dependencies** (DEC-019):
  - each was re-verified on pub.dev before it was added
  - `cupertino_icons` removed
  - the engine's dependencies deferred to Phase 3
- **Lints** (DEC-020):
  - `strict-casts`, `strict-inference`, `strict-raw-types`
  - 26 extra rules
  - `depend_on_referenced_packages` raised to an error
- **Workspace and engine:** `packages/calc_engine` is an empty pure-Dart skeleton (`pubspec.yaml`, `lib/calc_engine.dart`, `README.md`).
- **App code**, 29 hand-written Dart files under `lib/`, plus the ARB file and 2 generated l10n files:
  - `main.dart`
  - `app/`:
    - `app.dart`, `app_root.dart`
    - `modes/`: 3 files
    - `navigation/`: 2 files
    - `shell/`: 4 files
    - `theme/`: 3 files
  - `core/`:
    - `layout/window_size_class.dart`
    - `persistence/`: 4 files
    - `widgets/placeholder_view.dart`
  - `features/settings/`: domain, data, application and presentation
  - `features/history/presentation/`: page, panel and placeholder
  - `l10n/`: `app_en.arb` and the generated `app_localizations*.dart`
- **Tests:** the template counter test was replaced by 24 tests in 8 files, plus a helper (`test/helpers/test_app.dart`).
- **Build configuration:**
  - `android/gradle.properties`: `kotlin.incremental=false` (DEC-027)
  - `android/.gitignore`: `/.kotlin/`
  - `l10n.yaml`
- **Docs:** ARCHITECTURE.md (the implemented state), DECISIONS.md (DEC-019 to DEC-027, plus status updates), ROADMAP.md, CHANGELOG.md, this file, and PROJECT_MEMORY.md and CLAUDE.md.

## Work In Progress

None.

## Current Task

The user reviews the Phase 1 report. No implementation task is active.

## Next Task

**Only after the user explicitly approves Phase 2:** do Phase 2, the design system (see [ROADMAP.md](ROADMAP.md#phase-2-design-system)).

1. Settle P-8 (fonts) and confirm how the Phase 2 design review will be viewed on a device (P-4). The user does not want an emulator set up.
2. Build the tokens, then the components, then the debug-only gallery, following the per-module workflow.
3. Replace or absorb the Phase 1 stand-ins: `PlaceholderView`, the settings page's private section header, the provisional seed colour and spacing.
4. Stop for the user's design sign-off.

## Do NOT Repeat

- **Don't redo the Phase 0 audit or the scratch-project validation** (DECISIONS.md).
- **Don't redo the Phase 1 setup:** `git init`, the baseline and docs commits, the app identity change, adding the Phase 1 dependencies. It is all done and committed.
- **Dependencies:** re-verify one only when adding it or changing its version (DEC-015).
- **Don't re-propose `material_ui` or `go_router`** without new evidence (DEC-002, DEC-003).
- **Don't run `dart format .`.** It crashes on long paths under `build/`. Use `dart format lib test packages`.
- **Don't remove `kotlin.incremental=false`** unless P-10 is resolved by moving the project or the pub cache to the same drive. Without it, Android builds fail on this machine.
- **Don't treat the first `flutter pub get` failure after a plugin change as a code problem** (P-9). Run it again.
- **Don't delete** the web or desktop folders (DEC-004). **Don't push** to any remote.
- **Don't start Phase 2** without explicit approval.
- **Don't set up an Android emulator.** The user doesn't want one right now.

## Pending Decisions

| ID | Decision | Needed by | Notes |
| --- | --- | --- | --- |
| **P-4** | How the UI is checked on a device | Phase 2 design review | See note P-4 below the table |
| **P-5** | iOS verification: does the user have access to a Mac? | Before any iOS claim | iOS was not built (Windows) |
| **P-6** | Engine default behaviours (percent, `−3²`, `2^3^2`, `0^0`, …) | Before Phase 3 engine work | See [PROJECT_MEMORY.md](PROJECT_MEMORY.md#calculation-correctness-principles) |
| **P-7** | App version source for the About screen | Phase 10 | `package_info_plus` or a build-time constant |
| **P-8** | Fonts | Phase 2 | Proposed: Manrope, pending a check that it has tabular digits, and JetBrains Mono. Licenses must allow bundling. |
| **P-9** | Windows Developer Mode | Whenever convenient | See note P-9 below the table |
| **P-10** | Kotlin incremental builds across drives | Optional | See note P-10 below the table |

**P-4, device checks.** The user said: no emulator, and Phase 1 shouldn't depend on device testing. A physical Android 15 device (`23124RN87I`) was seen connected on 2026-09-28. The app has **not** been installed or run on it.

**P-9, Developer Mode.** It is off on this machine, so Flutter can't create the plugin symlinks for the kept Windows and Linux folders. The first `flutter pub get` after the plugin list changes fails once; running it again succeeds, and Android and iOS are unaffected. The choices:

- enable Developer Mode (a Windows setting), or
- accept the one-time failure.

**P-10, Kotlin across drives.** The current fix is `kotlin.incremental=false` (DEC-027). The alternative is to move the project, or `PUB_CACHE`, onto the same drive, then remove the setting.

**Resolved this session:**

- **P-1:** Phase 1 was approved.
- **P-2:** the user allowed the docs in the initial commits; the scaffold and the docs were committed separately.
- **P-3:** the app ID was applied in Phase 1.

## Important Files

| File | Role |
| --- | --- |
| `pubspec.yaml` | App package, workspace root, dependencies, `flutter: generate: true` |
| `analysis_options.yaml` | The strict lint configuration for the whole workspace |
| `l10n.yaml`, `lib/l10n/app_en.arb` | Localization configuration and the English strings |
| `lib/main.dart`, `lib/app/app_root.dart`, `lib/app/app.dart` | Startup chain |
| `lib/app/navigation/app_route.dart`, `app_navigator.dart` | The typed route layer |
| `lib/app/shell/app_shell.dart` | The adaptive layouts |
| `lib/app/modes/calculator_mode.dart` | The mode registry |
| `lib/core/persistence/app_database.dart` | Schema v1 and migrations |
| `lib/core/persistence/preferences.dart`, `preference_keys.dart` | Preferences loading, provider and key allow-list |
| `lib/features/settings/**` | The reference feature for the layered structure |
| `packages/calc_engine/` | The engine skeleton |
| `test/helpers/test_app.dart` | `pumpApp`, in-memory preferences, window sizes |
| `test/architecture/layer_boundaries_test.dart` | Enforces the engine and domain boundaries |
| `android/gradle.properties` | `kotlin.incremental=false` (DEC-027) |
| `android/app/build.gradle.kts` | ID `com.parasshakya.smartcalculator`; release still signs with the debug key |

## Dependencies

Actually in `pubspec.yaml` and `pubspec.lock` (verified 2026-09-28):

| Package | Constraint | Locked | Scope |
| --- | --- | --- | --- |
| `flutter`, `flutter_localizations` | SDK | — | app |
| `flutter_riverpod` | ^3.4.3 | 3.4.3 (with `riverpod` 3.4.3) | app |
| `intl` | any | 0.20.3 | app |
| `path` | ^1.9.1 | 1.9.1 | app |
| `shared_preferences` | ^2.5.5 | 2.5.5 | app |
| `sqflite` | ^2.4.4 | 2.4.4 | app |
| `flutter_test` | SDK | — | dev |
| `flutter_lints` | ^6.0.0 | 6.0.0 | dev |
| `shared_preferences_platform_interface` | ^2.4.2 | 2.4.2 | dev |
| `sqflite_common_ffi` | ^2.4.3 | 2.4.3 (with `sqlite3` 3.5.2) | dev |

- **Removed:** `cupertino_icons`.
- **`packages/calc_engine`** has no dependencies.
- **Still planned:** see [ARCHITECTURE.md](ARCHITECTURE.md) §3.8.

## Tests

These checks were run this session, in `smart_calculator/`:

| Command | Result |
| --- | --- |
| `flutter pub get` (first run after adding the plugins) | Dependencies resolved and l10n generated, then **exit 1** because symlinks need Developer Mode (P-9) |
| `flutter pub get` (again) | Exit 0 |
| `flutter build apk --debug` (at `06c0a93`, identity only) | **Built**, 79 s |
| `flutter build apk --debug` / `--release` (Phase 1, before DEC-027) | **Failed**: Kotlin incremental caches across drives |
| `flutter build apk --debug` (with DEC-027) | **Built**, 64.5 s |
| `flutter build apk --release` (with DEC-027) | **Built**: `app-release.apk`, 45.3 MB, universal (all ABIs), signed with the debug key |
| `aapt dump badging` on both APKs | See the aapt results below |
| `flutter analyze` (final) | `No issues found! (ran in 15.5s)`, exit 0 |
| `dart format --output=none --set-exit-if-changed lib test packages` | `Formatted 41 files (0 changed)`, exit 0 |
| `dart format --output=none --set-exit-if-changed .` | **Crashed**: `PathNotFoundException` in `build/` (long Gradle paths). Not a formatting issue. |
| `flutter test` (final) | `+24: All tests passed!`, exit 0 |
| Mutation check: the rail without its scroll wrapper | The phone-landscape test **failed** (RenderFlex overflow); the file was restored |

**aapt results:**

- package `com.parasshakya.smartcalculator`, versionName 1.0.0, versionCode 1
- label "Smart Calculator", minSdk 24, targetSdk 36
- the release APK has **no INTERNET permission**; its only permission is `…DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION` (AndroidX)
- the debug APK adds INTERNET, which the Flutter tooling needs

**Not run:**

- the iOS build (impossible on Windows)
- running the app on a device (not required for Phase 1)
- integration tests (none exist yet)
- web and desktop builds (not supported targets)

**The 24 tests:**

| File | Tests |
| --- | --- |
| app | 1 |
| shell | 7 |
| navigation | 2 |
| settings repository | 4 |
| theme preference | 2 |
| database | 4 |
| window size class | 1 |
| architecture | 3 |

## Known Issues

1. **`flutter pub get` fails once after a plugin change** on this machine, because Developer Mode is off and plugin symlinks can't be created (P-9). Running it again works.
2. **Kotlin incremental compilation is disabled** (DEC-027, P-10). Android builds need it on this machine.
3. **`dart format .` crashes** on long paths inside `build/`. Use `dart format lib test packages`.
4. **Release APKs are signed with the debug key.** Not scheduled; required before any distribution.
5. **Template leftovers:**
   - web and desktop identifiers
   - the web manifest and `index.html` names and descriptions
   - the project `README.md`
   - the default launcher icons (Phase 11)
6. **Provisional theme:** the seed colour and spacing are provisional (Phase 2).
7. **Landscape layout:** most phones in landscape get the expanded layout with the history panel (DEC-022). A dedicated landscape calculator layout is for Phase 3/5.
8. **The current mode isn't persisted.** The app always starts in Basic (DEC-021).
9. **No device or visual verification yet.** The layouts are checked only by widget tests. The 200% text check covers only the compact shell, not the rail or the settings page (Phase 2/11 accessibility review).
10. **`appDatabaseProvider` has no consumers yet.** It is tested, but the app never opens the database until Phase 4.

## Blockers

- **Phase 2** needs the user's approval, and its design review needs a way to view the UI on a device (P-4).
- **No technical blockers.** iOS still can't be built on Windows.

## Discrepancies Found

1. **2026-09-28, project-memory session.** The auto-memory had gone stale, and an example status template had been mistaken for real status. The approval conflicts that became P-2 and P-3 were resolved this session.
2. **2026-09-28, Phase 1.** DEC-015 said every planned package had been released within the past year. That was wrong for `path` (1.9.1, 2024-10). Corrected in DEC-015.
3. **2026-09-28, Phase 1.** Phase 0 recorded "Android debug and release builds succeed with the plugins". That held only for a project on the pub cache's drive (`C:`). On `D:` the build needed DEC-027.
4. **2026-09-28, Phase 1.** The docs listed `dart format .` as the QA command. It crashes once `build/` holds deep Gradle output. The docs now use `dart format lib test packages`.

## Last Session Summary

**2026-09-28, Phase 1 session.**

1. Followed the Context Recovery Protocol. The docs were unchanged since the previous session, and Git was not initialized.
2. Git: initialized, then made the baseline scaffold and docs commits.
3. Applied the app identity (`06c0a93`) and confirmed it with a debug build.
4. Re-verified the dependencies and added them. Hit and handled the Developer Mode symlink failure.
5. Wrote the foundation code and 24 tests. Analyzer: no issues. Tests: all passing. Checked one test with a mutation.
6. The Android build failed across drives. Fixed it with DEC-027; debug and release now build, and the APK contents were verified.
7. Committed the foundation (`7926920`), then updated the docs.

## Instructions For Next Session

1. Follow the Context Recovery Protocol in [CLAUDE.md](../CLAUDE.md). Run `git log --oneline` and expect the commits listed above.
2. **Don't start Phase 2** unless the user has explicitly approved it. If the user asks for changes to Phase 1, make them and update these docs.
3. When Phase 2 is approved:
   - Settle P-8.
   - Agree on how to view the design review (P-4; no emulator).
   - Then follow [ROADMAP.md](ROADMAP.md) Phase 2 exactly.
4. **Checks:**
   - `flutter analyze`
   - `dart format --set-exit-if-changed lib test packages`
   - `flutter test`
   - `flutter build apk --debug`

   Record the actual results. If a new plugin was added and `flutter pub get` fails with the symlink error, run it again (P-9).
5. Finish with the Session Handoff Protocol.
