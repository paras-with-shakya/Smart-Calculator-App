# Development Status

> **The most important file for context recovery.** Rewrite it to the current truth at the end of every meaningful session, following the Session Handoff Protocol in [CLAUDE.md](../CLAUDE.md). Every claim here must be backed by code, by Git, or by a command that was actually run.

**Last updated:** 2026-09-28, at the end of the Phase 3 final-audit session.

## At a Glance

| Question | Answer |
| --- | --- |
| Where are we? | **Phase 3 (Basic calculator) is implemented, audited and awaits the user's approval to start Phase 4.** Phases 0–2 are complete. |
| What exists in code? | The foundation, the design system, the calculation engine (`packages/calc_engine`), and a working basic calculator: display, keypad, memory, region number format, keyboard, portrait and landscape. Other modes still show an empty state. |
| What is being worked on? | Nothing. A strict Phase 3 audit (2026-09-28, this session) is with the user; see "Phase 3 Audit" below. |
| What happens next? | The user reviews the audit and approves Phase 4, history and saved calculations. |
| Git? | `main` is ahead of `origin/main` (the user's GitHub remote); `git status -sb` shows by how much. The Phase 3 docs are in `a5fa8fd` (committed by the user from the working tree) and `d114dbb`. **Claude never pushes; the user pushes themselves.** |
| What must not be repeated? | See "Do NOT Repeat" |
| Known issues? | See "Known Issues" |
| Pending decisions? | P-5, the rest of P-6 (Phase 5), P-7, P-9, P-10 |

## Current Phase

**Phase 3 (Basic calculator): implemented on 2026-09-28, audited on 2026-09-28, awaiting the user's approval to start Phase 4.**

- The user approved Phase 2's design and Phase 3 on 2026-09-28 ("phase 2 approv and start phase 3").
- Their decisions: smart percent (DEC-036) and number formatting that follows the phone's region (DEC-037).
- **Phase 4 must not start without the user's explicit approval.**

## Phase 3 Audit (2026-09-28)

A strict final audit, requested by the user before approving Phase 4. Everything below was checked against the actual code, tests and a fresh build in this session, not recalled from the earlier Phase 3 session.

- **Re-ran every QA command:** `flutter analyze` (clean), `dart format --set-exit-if-changed lib test packages` (0 changed), `flutter test` (408 passed, 1 skipped), `dart test` in `packages/calc_engine` (260 passed), `flutter build apk --debug` (built). See "Tests" below for the updated counts.
- **Read the engine source** (`lexer`, `parser`, `eval/evaluator.dart`, `number/calc_value.dart`) and confirmed by direct evaluation that the checklist behaviours hold: `0.1+0.2−0.3` = 0, `(1÷3)×3` = 1, `6÷2(1+2)` = 9 (one evaluator, so the same rule applies everywhere it's used), operator precedence, parentheses, implicit multiplication, smart percent, negative numbers, division by zero (including `0÷0`), invalid/incomplete expressions, overflow at 10¹⁰⁰, and 12-significant-digit formatting with scientific notation. `test/architecture/layer_boundaries_test.dart` and the engine's own `pubspec.yaml` confirm the engine still has no Flutter dependency.
- **Repeated `=`:** confirmed (`calculator_notifier_test.dart`, "pressed again keeps the result") that pressing `=` again after a result is a no-op — it does **not** repeat the last operation the way some phone calculators do. This is intentional (DEC-040's "after `=`" rules), but DEC-040 doesn't spell this specific case out; worth a one-line addition next time DEC-040 is touched.
- **Memory persistence:** confirmed (`calculator_notifier_test.dart`, "survives a restart, exactly") that the memory reloads exactly from a fresh `ProviderContainer`, matching the on-device test in the Phase 3 report.
- **Indian number grouping and region formatting:** read `LocalizedNumberFormat`, which derives grouping from `intl`'s locale data rather than hardcoding India's 2-3 pattern, so it generalizes to any region `intl` knows. 33 tests cover en_US, en_IN and de_DE.
- **`6÷2(1+2)` = 9:** confirmed in the engine tests and by direct evaluation. Implied multiplication has the same precedence as `×` ÷ everywhere, because there is exactly one evaluator (`CalcEngine.evaluate`) and the UI never re-implements precedence; the buffer only assembles the input string.
- **Invalid expression editing (`5×+3`-style):** investigated in depth — see the corrected "Calculator limitations" entry below. The previous description of this behaviour was wrong; it's corrected here, and two regression tests were added (`calculator_notifier_test.dart`, group "editing in the middle"; `expression_buffer_test.dart`, group "editing at the cursor"). **Judgment: acceptable for Phase 3** — every case fails safely (a typed, recoverable error) or evaluates to a mathematically correct result; nothing crashes, shows `NaN`, or corrupts state. Not a correctness or safety issue, so the input system was not redesigned, per the user's instruction.
- **Touch copy/paste:** confirmed absent (no `ClipboardData` writes, no context menu wiring in `lib/features/calculator/`); only Ctrl+V via a hardware keyboard works, matching the docs. **Treated as deferred, not a defect**, per the user's instruction.
- **Haptics:** confirmed always on (`HapticFeedback.selectionClick()` / `.mediumImpact()` called unconditionally in `calculator_keypad.dart` and `calculator_memory_keys.dart`, with no setting to check). **Left as is**, deferred to Phase 10 per the user's instruction.
- **Reusable components:** `DisplayText` and `CalculatorButtonKind.memory` are genuinely reused (the display's three lines and the memory row) and have gallery entries and dedicated tests (12 and part of the `CalculatorButton` suite). No hardcoded colours, text styles or dimensions found in `lib/features/calculator/presentation/` — grepped for `Color(0x`, `TextStyle(`, `fontSize:`, `EdgeInsets.all(`, `BorderRadius.circular(`: no matches. No new widget was added beyond what's genuinely shared.
- **Landscape key height and memory badge semantics:** both fixes are covered by automated tests, not just the manual device test. `calculator_view_test.dart` — "landscape under a status bar keeps 48 dp keys" — simulates a 34 dp status bar and asserts every key still meets the touch-target guideline. The memory-badge test asserts its semantics node's `rect.height` is under `kMinInteractiveDimension` (48 dp), i.e. it's a small node, not a screen-sized one.
- **Security/privacy:** `android/app/src/main/AndroidManifest.xml` (the release manifest) declares no `INTERNET` permission; only the debug/profile manifests do (Flutter tooling). Nothing in Phase 3 added network code or a new manifest permission.
- **Test-quality gap found and fixed:** the exact `5×+3` scenario named in the user's checklist wasn't reproduced by any existing test (only a buffer-level DSL and a formatter-level error-message mapping existed separately, never chained together). Traced the code path, verified the actual behaviour by direct evaluation, corrected the documentation, and added 4 targeted tests (2 in `expression_buffer_test.dart`, 2 in `calculator_notifier_test.dart`) that reproduce it end to end. No other high-value gaps were found; the existing 260 engine and (now) 408 app tests already exercise precedence, brackets, percent, negatives, division by zero, overflow, formatting and persistence thoroughly. Nothing was added just to raise the count.

## Phase Status

| Phase | Name | Status |
| --- | --- | --- |
| 0 | Project audit and architecture | Completed 2026-09-28 |
| — | Project-memory system | Completed 2026-09-28 |
| 1 | Foundation | Completed 2026-09-28 (commits `06c0a93`, `7926920`) |
| 2 | Design system | Completed 2026-09-28 (commit `0fc15ef`; device fix `950493b`); design approved by the user |
| 3 | Basic calculator (engine, memory) | **Implemented and audited 2026-09-28** (commits `4fec0b6`, `57a1e73`, `85c6c84`); **awaiting the user's approval for Phase 4** |
| 4 | History and saved calculations | Not started; needs approval |
| 5 | Scientific | Not started |
| 6 | Converters | Not started |
| 7 | Financial | Not started |
| 8 | Date calculator | Not started |
| 9 | Programmer calculator | Not started |
| 10 | Settings screen | Not started |
| 11 | Polish | Not started |
| 12 | QA | Not started |

## Completed Work

### Phases 0–2 (2026-09-28)

- **Phase 0:** the audit, the validation and the approved architecture (DEC-001 to DEC-017).
- **Project-memory system** (`813533e`).
- **Phase 1** (`06c0a93`, `7926920`, docs `01f120a`): Git, app identity, dependencies, strict lints, the workspace and engine skeleton, startup, Riverpod, typed navigation, the adaptive shell, the theme choice, preferences, database v1 and l10n.
- **Phase 2** (`0fc15ef`, `950493b`): Manrope with verified `tnum` (DEC-028); tokens and four palettes (DEC-029); `AppTheme`; the reusable components (DEC-030, DEC-035); the gallery (DEC-032); the design review (DEC-033). It was tested on the user's phone, and the user signed off the design.
- Details: [ARCHITECTURE.md](ARCHITECTURE.md) §1.1–1.11.

### Phase 3: Basic calculator (2026-09-28, this session)

Details: [ARCHITECTURE.md](ARCHITECTURE.md) §1.12 (engine) and §1.13 (calculator); decisions DEC-036 to DEC-043.

- **Module 1, the engine** (`4fec0b6`):
  - an exact `CalcValue` on `rational` (DEC-038)
  - lexer → parser → evaluator, with smart percent and implied multiplication
  - typed errors, and the limits: overflow at 10¹⁰⁰, 100 nested brackets, 1000 tokens (DEC-039)
  - 260 tests
- **Module 2, the logic** (`57a1e73`):
  - `ExpressionBuffer`, with its input rules and exact value units (DEC-040)
  - `CalculatorNotifier`
  - `MemoryNotifier` and `PreferencesMemoryRepository`
  - `LocalizedNumberFormat` and `numberFormatProvider` (DEC-037)
  - 228 tests
- **Module 3, the screen** (`85c6c84`):
  - `CalculatorView`, with layouts and keyboard support (DEC-042)
  - `CalculatorDisplay`, `CalculatorKeypad`, `CalculatorMemoryKeys` and `CalculatorDisplayFormatter`
  - the new components `DisplayText` and `CalculatorButtonKind.memory` (DEC-043), both in the gallery
  - 37 strings
  - the shell's short-window rule (DEC-042)
- **Review:**
  - 50 design-review screenshots generated and reviewed by Claude. Two fixes: line breaks inside numbers, and the tablet-landscape keypad alignment.
  - Tested on the user's phone. Two more fixes: landscape keys under 48 dp, and the memory badge's screen-reader label (see below).
- **Not built, by decision:**
  - the engine's function registry (no functions until Phase 5; ROADMAP updated)
  - the roadmap's "more" menu, which would be empty (DEC-041)

### Test on the user's phone (2026-09-28, this session)

The phone was connected by USB, as it was for the Phase 2 test at the user's request.

- **Device:** `23124RN87I`, Android 15, 360×800 dp, region en-IN, dark system theme.
- **Method:** the release APK installed with `adb install -r`; taps with `adb shell input`; the UI read through `uiautomator dump`; screenshots with `screencap`.

| Check | Result |
| --- | --- |
| Keys | All 25 keys exposed with their names ("Divide", "Memory store", …); about 76×75 dp in portrait |
| `1234567×8+90` | Shows `12,34,567×8+90` with the preview `98,76,626`; `=` shows the result `98,76,626` under the expression |
| Smart percent | `50+10%` previews 55 |
| Memory | MS, then `2×` MR shows `2×98,76,626` (preview `1,97,53,252`); the "M 98,76,626" badge shows |
| Error | `5÷0=` shows "Can't divide by zero" under the expression |
| Restart | After a force-stop and relaunch, the memory is still there |
| Landscape | The keypad is beside the display. **Found:** keys 47.6 dp tall. **Found:** the memory badge's label covered the whole screen. Both fixed, re-installed and re-checked: keys 49 dp, badge label on its own small node. |
| Hold ⌫ | Clears the display to 0 |
| Screen reader text | The expression reads as "1 plus 2" |

- **Phone settings:** only the rotation was changed (for landscape), and it was restored: auto-rotate off, rotation 0. Font scale 1.0 and locale en-IN were not touched. The screenshots on the phone were deleted after pulling them.

## Work In Progress

None.

## Current Task

The user reviews the Phase 3 audit (see "Phase 3 Audit" above).

- **Screenshots:** `build/design_review/calc_*.png` (15 calculator screens) and `gallery_display_*.png`. They are local only, not committed. Not regenerated this session, since nothing visual changed (only two test files and this doc set).
- **On the phone:** the release build from the Phase 3 session is installed; not reinstalled this session.

## Next Task

1. **If the user asks for changes after the audit:** make them, re-run the checks, regenerate and review the screenshots if anything visual changed, and update the docs.
2. **After the user explicitly approves Phase 4:** do Phase 4, history and saved calculations (see [ROADMAP.md](ROADMAP.md)).
   - First, confirm the v1 table columns (DEC-023).
   - Each `=` result becomes a history item (expression, result, time, mode).

## Do NOT Repeat

- Don't redo the Phase 0 validation, the Phase 1 setup or the Phase 2 design system.
- **Don't re-check Manrope's `tnum` support** (verified, DEC-028).
- **Don't add `decimal` to the engine** (DEC-038). Don't bump `test` to 1.32 in the engine: it needs a newer `test_api` than the Flutter SDK pins.
- **Don't re-add `PlaceholderView`** or restyle widgets inline. Use the components (DEC-034).
- **Don't commit `build/design_review/`** images (DEC-033).
- Don't run `dart format .`; use `dart format lib test packages`.
- Don't remove `kotlin.incremental=false` (DEC-027) unless P-10 is resolved.
- Treat the first `flutter pub get` failure after a plugin change as expected (P-9) and run it again.
- Don't set up an emulator. Don't delete platform folders. **Never push**: the user pushes their code to GitHub themselves (CLAUDE.md rule 10).
- **Don't start Phase 4** without the user's explicit approval.

## Pending Decisions

| ID | Decision | Needed by | Notes |
| --- | --- | --- | --- |
| **P-5** | iOS verification: does the user have access to a Mac? | Before any iOS claim | iOS was not built (Windows) |
| **P-6** | The rest of the engine defaults: `−3²`, `2^3^2`, `0^0`, `(−8)^(1/3)`, `tan 90°` | Before Phase 5 | Percent is settled (DEC-036). See [PROJECT_MEMORY.md](PROJECT_MEMORY.md#calculation-correctness-principles). |
| **P-7** | App version source for the About screen | Phase 10 | `package_info_plus` or a build-time constant |
| **P-9** | Windows Developer Mode, or accept the one-time `pub get` failure after plugin changes | Whenever convenient | Symlinks for the kept desktop folders |
| **P-10** | Keep `kotlin.incremental=false`, or put the project and the pub cache on one drive | Optional | DEC-027 |

**Open to the user's review** (adopted by Claude during Phase 3): DEC-038 to DEC-043. The ones the user is most likely to have a view on:

- implied multiplication has the same precedence as `×`, so `6÷2(1+2)` = 9 (DEC-039)
- the memory row is always visible, and there is no "more" menu (DEC-041)
- no history panel on phones in landscape (DEC-042)

**Device testing.** The user's phone (`23124RN87I`) is used when it is connected and a test is natural or requested. Restore any phone setting a test changes.

**Resolved this session:**

- P-11 (the Phase 2 design sign-off): approved by the user.
- P-6, percent part: DEC-036.

## Important Files

| File | Role |
| --- | --- |
| `packages/calc_engine/lib/src/number/calc_value.dart` | Exact values, canonical decimal text, storage format |
| `packages/calc_engine/lib/src/{lexer,parser,eval}/` | The engine pipeline |
| `packages/calc_engine/lib/src/calc_engine.dart` | `CalcEngine.evaluate`, the token limit |
| `lib/features/calculator/domain/expression_buffer.dart` | The expression units, the cursor and the input rules |
| `lib/features/calculator/application/calculator_notifier.dart` | Key presses → `CalculatorState`; memory actions |
| `lib/features/calculator/application/memory_notifier.dart`, `data/preferences_memory_repository.dart` | Memory, saved exactly |
| `lib/features/calculator/presentation/*` | View (layout, keyboard), display, keypad, memory row, display formatter |
| `lib/core/formatting/*` | Region number format (DEC-037) |
| `lib/core/widgets/display_text.dart` | Shrink-then-wrap display text with a caret |
| `lib/app/shell/app_shell.dart` | Basic mode → `CalculatorView`; the short-window rule |
| `lib/app/theme/*`, `lib/core/widgets/*` | Tokens and the reusable components; screens use only these |
| `test/design_review/design_review_screenshots_test.dart` | The screenshot generator, skipped by default |
| (Phase 1 files) | See ARCHITECTURE.md §1: startup, navigation, shell, persistence, l10n |

## Dependencies

- **Added in Phase 3:**
  - app: `calc_engine` (path `packages/calc_engine`)
  - engine: `rational` ^2.2.3 (locked 2.2.3); dev `test` ^1.31.1 (locked 1.31.1)
- **Actually in `pubspec.yaml` and `pubspec.lock`:**
  - app: `flutter_riverpod` 3.4.3, `shared_preferences` 2.5.5, `sqflite` 2.4.4, `path` 1.9.1, `intl` 0.20.3, `flutter_localizations`, `calc_engine`
  - dev: `flutter_test`, `flutter_lints` 6.0.0, `shared_preferences_platform_interface` 2.4.2, `sqflite_common_ffi` 2.4.3
- **Not added:** `decimal` (DEC-038).
- **Still planned:** ARCHITECTURE.md §3.8.

## Tests

**Re-run and reverified in the Phase 3 audit session (2026-09-28), in `smart_calculator/`:**

| Command | Result |
| --- | --- |
| `flutter analyze` | `No issues found!` |
| `dart format --set-exit-if-changed lib test packages` | `Formatted 104 files (0 changed)`, exit 0 |
| `dart test` (in `packages/calc_engine`) | `+260: All tests passed!` (unchanged; the engine wasn't touched this session) |
| `flutter test` | `+408 ~1: All tests passed!` (404 from the Phase 3 session + 4 new regression tests added this session; the 1 skip is the design-review generator) |
| `flutter build apk --debug` | **Built** (Gradle `assembleDebug`, 26.4 s) |
| Direct engine evaluation (ad hoc, via a scratch `bin/probe.dart` in `packages/calc_engine`, deleted after use) | Verified `0.1+0.2−0.3`, `6÷2(1+2)`, and the exact behaviour of `5×+3` / `5×%`; the last one corrected a documentation error (see "Phase 3 Audit" above) |

**From the original Phase 3 implementation session (2026-09-28), not re-run this session** (design-review screenshots and on-device behaviour don't change by reading code, and nothing visual changed):

| Command | Result |
| --- | --- |
| Engine mutation checks (Module 1) | Plain percent: 13 failures. Truncating instead of rounding: 10 failures. Both restored. |
| Mutation checks on the Module 2 tests (6 mutations, each restored and verified by hash) | Each caught: leading-zero rule, closing-bracket rule, bracketed variables, incomplete-error mapping, rejected-key handling, Indian grouping |
| Landscape regression test with the old padding | **Failed**, as it should; passes with the fix |
| `flutter test --tags design-review --run-skipped --update-goldens` | `+50: All tests passed!`; 50 PNGs in `build/design_review/`, reviewed |
| `flutter build apk --release` | **Built**, 46.6 MB |
| `aapt dump badging` on the release APK | package `com.parasshakya.smartcalculator`, label "Smart Calculator"; **no INTERNET permission** (the only permission is AndroidX's `DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION`); **re-checked by reading `android/app/src/main/AndroidManifest.xml` directly this session — still no `INTERNET` permission** |
| On the user's phone | See "Test on the user's phone" |

**Where the tests are:**

| Area | Tests |
| --- | --- |
| Engine (`packages/calc_engine`) | 260 |
| Expression buffer | 140 (+2 this session: `5+3LL×`, `5%L×` — see "Phase 3 Audit") |
| Calculator notifier and memory | 61 (+2 this session: "editing in the middle") |
| Number format | 33 |
| Calculator screen | 24 |
| Display formatter | 18 |
| `DisplayText` | 12 |
| Gallery accessibility (10 sections × 4 themes) | 40 |
| Earlier app tests (Phases 1–2), including 2 new `CalculatorButton` tests, 1 new app test and 1 new shell test | 80 |
| **App total** (`flutter test`) | **408** |

**Not run:**

- the iOS build (Windows)
- an emulator (the user doesn't want one; the app was tested on the user's phone)
- integration tests (none yet)
- the release build and the design-review screenshots, this session (see above; nothing visual changed)

## Known Issues

1. **P-9:** the first `flutter pub get` after a plugin change fails once on this machine (no symlink permission). Run it again.
2. **DEC-027:** Kotlin incremental compilation is disabled (drives `C:`/`D:`).
3. **`dart format .`** crashes on long paths inside `build/`. Use `dart format lib test packages`.
4. **Release signing:** release APKs are signed with the debug key. Not scheduled.
5. **Template leftovers:** web and desktop identifiers, the web manifest and `index.html` text, `README.md`, and the default launcher icons (Phase 11).
6. **Icons don't grow with text size,** which matches Android's behaviour. To review in Phase 11.
7. **High contrast follows only the platform setting.** The in-app switch is Phase 10.
8. **The current mode isn't persisted** (DEC-021).
9. **Only checked on one device:** one phone (Android 15, 360 dp), plus test-rendered screenshots. No tablet or iOS device yet.
10. **`appDatabaseProvider` has no consumers yet** (Phase 4).
11. **Calculator limitations (Phase 3):**
    - **Editing in the middle** can build an expression the input rules didn't intend, because a new operator is only collapsed with the unit *right before* the cursor, never the unit after it. Typing `×` right before an existing `+` (cursor between `5` and `+` in `5+3`) does **not** error: `5×+3` is valid (`+` is a no-op unary plus), so `=` silently gives `15`, not the `3×3` a user probably meant. **Verified during the Phase 3 audit** (2026-09-28) to differ from what this file previously claimed (that it always fails as "Invalid expression"); that claim was wrong and is corrected here. A syntax error **is** reachable the same way, for example `5×%` (`×` before `5`'s `%`, which cannot be unary): `=` then shows "Invalid expression", and the expression stays editable. Both paths are now covered by regression tests (`calculator_notifier_test.dart`, group "editing in the middle").
    - **Two values next to each other:** deleting the `×` between two inserted values (results or memory) leaves them adjacent. They still multiply, but on screen they read as one number. This needs cursor editing to happen.
    - **The region format is read at startup.** A region change applies after the app restarts.
    - **Paste** works only through a hardware keyboard (Ctrl+V). There is no touch copy or paste menu yet.
    - **Haptics are always on.** There is no setting until Phase 10.
12. **Review findings, not changed (awaiting the user's decision):**
    - The high-contrast outline expression is repeated in 3 places (the theme, `AppCard`, `CalculatorButton`); it could become one `AppColors` getter.
    - `AppTextField` passes through parameters that nothing uses yet.
    - `AppTextField`, `AppDialog`, `ErrorState` and `LoadingState` are used only by the gallery and tests until Phases 4–7.

## Blockers

- **Phase 4:** needs the user's review of Phase 3 and explicit approval.
- **No technical blockers.** iOS still can't be built on Windows.

## Discrepancies Found

1. **Project-memory session:** the auto-memory had gone stale, and an example status template had been mistaken for real status. Both resolved.
2. **Phase 1:** DEC-015's "released within the past year" claim was wrong for `path`; the claim that Android builds pass held only on the `C:` drive (DEC-027); the docs listed `dart format .` as the QA command. All corrected.
3. **Phase 2:** the component list differs from the master prompt's by design (DEC-030). The docs said "no remote", but the user had added `origin` and pushed; corrected (CLAUDE.md rule 10, DEC-006).
4. **Phase 3:**
   - **ROADMAP.md** showed Phase 2 as COMPLETED in its sequence, but its section was still under "In Progress" (the start-of-Phase-3 update had missed it). Moved to "Completed".
   - **DEC-021** pointed to ARCHITECTURE.md §1.13 for adding pages; that section is now §1.16. Corrected.
   - **Deviations from the plan, recorded rather than silent:** no `decimal` (DEC-038); no function registry and no "more" menu (ROADMAP Phase 3 table, DEC-041).
5. **Phase 3 audit (2026-09-28):** the "Calculator limitations" known issue (#11 above) claimed that editing `5+3` into `5×+3` always shows "Invalid expression". Verified by direct engine evaluation that this is wrong: `5×+3` is valid (unary `+` is a no-op) and silently evaluates to `15`. A genuinely invalid case exists too (`5×%`), but it's a different example than the one the docs gave. Corrected, and both paths now have regression tests. This was the only discrepancy the audit found; every other checked claim (test counts once updated, the engine's independence from Flutter, the release manifest's permissions, the landscape and memory-badge fixes) held up against the code.

## Last Session Summary

**2026-09-28, Phase 3 final-audit session** (for the Phase 3 implementation session, see [CHANGELOG.md](CHANGELOG.md)).

1. The user asked for a strict, code-level audit of Phase 3 before approving Phase 4 (see "Phase 3 Audit" above for the full checklist and findings).
2. Re-ran every QA command from a clean state: `flutter analyze`, `dart format --set-exit-if-changed`, `flutter test`, `dart test` (engine), `flutter build apk --debug`. All passed, matching the Phase 3 session's claims.
3. Read the engine's lexer, parser, evaluator and `CalcValue`, and confirmed the requested behaviours (exactness, precedence, `6÷2(1+2)` = 9, percent, division by zero, overflow, formatting) by direct evaluation, not just by reading test names.
4. Found and corrected one real discrepancy: the "Calculator limitations" known issue's `5×+3` example was wrong (see "Discrepancies Found" #5). Traced the actual behaviour, verified it by direct evaluation, corrected the doc, and added 4 regression tests (2 in `expression_buffer_test.dart`, 2 in `calculator_notifier_test.dart`) so the corrected behaviour — and the genuine error case (`5×%`) — stay covered. **408 app tests now pass** (was 404).
5. Confirmed repeated `=`, memory persistence across a restart, Indian/regional number grouping, the engine's independence from Flutter (both the architecture test and the pubspec), the release manifest's lack of an `INTERNET` permission, and that the landscape-key and memory-badge fixes are covered by automated tests, not only the earlier manual device test.
6. Judged the deferred items (invalid-expression editing at large, touch copy/paste, always-on haptics) acceptable for Phase 3 as instructed, and did not redesign the input system or make any UI/design changes.
7. **Docs:** this file, ARCHITECTURE.md (test counts) and CHANGELOG.md updated. No changes to PROJECT_MEMORY.md, DECISIONS.md or ROADMAP.md were needed — nothing they claim was contradicted by the code.

**2026-09-28, Phase 3 implementation session** (kept for context; see CHANGELOG.md for the full entry):

1. The user approved the Phase 2 design and Phase 3. They chose smart percent (DEC-036) and the region number format (DEC-037).
2. **Module 1, the engine:**
   - re-verified and added `rational` and `test`
   - built it test-first: 224 table cases, a fuzz test and `CalcValue` tests, 260 in all, plus two mutation checks
   - committed as `4fec0b6`
3. **Module 2, the logic:**
   - the expression buffer, the notifier, memory and the region number format
   - while reviewing it, fixed ambiguous displays: values next to numbers, and leading zeros at the cursor
   - 228 tests and 6 mutation checks
   - committed as `57a1e73`
4. **Module 3, the screen:**
   - the view, the display, the keypad, the memory row and keyboard support
   - the new components `DisplayText` and the memory key kind
   - the shell's short-window rule
   - 15 calculator screenshots reviewed, with 2 fixes
   - committed as `85c6c84`
5. **On the user's phone:** the main flows pass. Two issues were found in landscape (keys under 48 dp, and the badge's screen-reader label). Both were fixed, covered by tests, and re-checked on the phone. The rotation setting was restored.
6. **Final checks:** analyze clean, formatting clean, 404 app tests and 260 engine tests pass, 50 screenshots, and the debug and release APKs build.
7. **Docs:** DEC-038 to DEC-043 recorded; ARCHITECTURE, ROADMAP, CHANGELOG, PROJECT_MEMORY and CLAUDE.md updated.

## Instructions For Next Session

1. Follow the Context Recovery Protocol in [CLAUDE.md](../CLAUDE.md). **Reply to the user in Hinglish** (CLAUDE.md rule 13).
2. **If the user hasn't approved Phase 4 yet,** ask for it (the audit is done; see "Phase 3 Audit" above). Apply any requested changes through the components and tokens, then re-run the checks and regenerate the screenshots if anything visual changed.
3. **Don't start Phase 4** until the user explicitly approves it. Then confirm the history table columns first (DEC-023).
4. **Build every new screen only from `lib/core/widgets/` and the tokens** (rule 12, DEC-034).
5. **Checks:**
   - `flutter analyze`
   - `dart format --set-exit-if-changed lib test packages`
   - `flutter test`
   - `dart test` in `packages/calc_engine`
   - `flutter build apk --debug`
   - after visual changes, the screenshots

   Record the actual results.
6. Finish with the Session Handoff Protocol.
