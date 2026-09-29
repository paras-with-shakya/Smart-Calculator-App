# Development Status

> **The most important file for context recovery.** Rewrite it to the current truth at the end of every meaningful session, following the Session Handoff Protocol in [CLAUDE.md](../CLAUDE.md). Every claim here must be backed by code, by Git, or by a command that was actually run.

**Last updated:** 2026-09-29, mid Phase 4 (History complete, committed and phone-tested; saved calculations starting).

## At a Glance

| Question | Answer |
| --- | --- |
| Where are we? | **Phase 3 is complete and audited. Phase 4's History module is complete, committed and tested on the user's phone. Saved calculations is starting now** (the user delegated the UI design to Claude — "jaisa tum karo, waha karo", 2026-09-29). |
| What exists in code? | Everything from Phase 3, plus a working calculation history: every successful `=` is logged, with view, search, reuse, copy, delete and clear-all. See ARCHITECTURE.md §1.17. |
| What is being worked on? | Saved calculations (domain/data/application, then the UI Claude is designing). |
| What happens next? | Build saved calculations, then the same QA gate (analyze, format, test, build, and a phone test if the user connects the phone again), then a report and a stop before Phase 5. |
| Git? | `main` is ahead of `origin/main`. The Phase 3 audit (`453af28`) and the Phase 4 History module are both committed locally — see "Completed Work" for the commit hash. **Claude never pushes; the user pushes themselves.** |
| What must not be repeated? | See "Do NOT Repeat" |
| Known issues? | See "Known Issues". #13 (the stray scaffold) is **resolved** — the user deleted it 2026-09-29. |
| Pending decisions? | P-5, the rest of P-6 (Phase 5), P-7, P-9, P-10. **P-12 resolved:** the user asked Claude to design the saved-calculations entry point. |

## Current Phase

**Phase 4 (History and saved calculations): approved 2026-09-29. History is complete; saved calculations is being built now.**

- The user approved Phase 3 (after its audit) and Phase 4 on 2026-09-29 ("phaes 4 start").
- History: view, search, reuse (inserts the exact result, like MR), copy, delete, clear all — DEC-044. Verified on the user's phone (2026-09-29).
- The user resolved P-12 by delegating the saved-calculations UI to Claude's judgement ("jaisa tum karo, waha karo").
- **Phase 5 must not start without the user's explicit approval.**

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

## Phase 4: History module (2026-09-29, this session)

The user approved Phase 4 with "phaes 4 start". Full detail: ARCHITECTURE.md §1.17; decisions: DEC-044 (what history stores and what reuse/copy do), DEC-045 (test database isolation).

- **Domain, data, application** (`lib/features/history/`): `HistoryEntry`, `HistoryRepository`, `SqfliteHistoryRepository` (over the existing `history` table, no migration needed), `HistoryNotifier` (`AsyncNotifier<List<HistoryEntry>>`).
- **Presentation:** `HistoryContent`, replacing the Phase 1 placeholders in both `HistoryPage` and `HistoryPanel`: search, an entry list (reuse on tap, copy and delete actions), an empty state, a search-with-no-matches state, and a confirmed clear-all.
- **Calculator wiring:** `CalculatorNotifier._evaluate()` logs every successful `=` (not errors); a new `useHistoryResult` inserts a reused entry's result at the cursor, exactly like MR. **No change to the approved calculator screen's layout or any existing widget's visible behaviour.**
- **A real bug found and fixed along the way:** widget tests using `pumpApp` at an expanded window size (the history panel is always visible there) started hanging or throwing `sharedPreferencesProvider must be overridden`, because wrapping `AppRoot` in a second `ProviderScope` doesn't work the way it looks like it should — Riverpod resolves unscoped providers at the app's one root scope, not the nearest ancestor with an override. Fixed by giving `AppRoot` its own `overrides` parameter instead (DEC-045). Also found and fixed: `sqflite`'s single-instance-per-path caching meant every test in `calculator_notifier_test.dart` was sharing one in-memory database until `AppDatabase.open` gained a `singleInstance: false` option for tests; and the copy feature's widget tests hung until a clipboard mock was added (the same pattern `calculator_view_test.dart`'s paste tests already use — nothing new, just first use of it for this file).
- **Tests:** `test/features/history/` (repository: 9; notifier: 5; widget: 10), plus `ExpressionBuffer.toCanonicalText` (3, in `expression_buffer_test.dart`) — 27 new History-specific tests. All pass.
- **Not built, by decision (DEC-044):** history grouping, paging, swipe-to-delete-with-undo, a result "tape," a retention limit — all `(Proposed)` in ROADMAP.md, not required by the "Done when" gate.
- **Saved calculations: not started.** It needs a new tap target on the calculator screen to trigger a save, which touches the approved Phase 2/3 design — flagged for the user rather than added silently (P-12).

### A blocking accident this session: a stray Flutter app inside `packages/calc_engine`

During this session, a full `flutter create`-style scaffold appeared inside `packages/calc_engine/` (`lib/main.dart` importing `package:flutter/material.dart`, an `android/` folder, `.metadata`, `analysis_options.yaml`, `.gitignore`, `.idea/`, `calc_engine.iml`) — all untracked, all created within the same second. The exact triggering command isn't confirmed with certainty; the leading theory is a `flutter` command run with a stale working directory inside `packages/calc_engine` from earlier in the session, though that's not proven. `packages/calc_engine/pubspec.yaml` and every real engine source file are confirmed **unmodified** (`git diff` is empty for the former; the latter still pass all 260 engine tests).

This is exactly what `test/architecture/layer_boundaries_test.dart` exists to catch, and it did: it's the **only** failure in the whole suite (438 passed, 1 skipped, 1 failed, of 440). Claude attempted to delete the stray files and was correctly refused by the sandbox's safety layer (an `rm` touching a directory), which is why this is now the user's decision, not a silent fix. See "Known Issues" #13 for the exact file list and Known Issues for what's confirmed unaffected.

## Phase Status

| Phase | Name | Status |
| --- | --- | --- |
| 0 | Project audit and architecture | Completed 2026-09-28 |
| — | Project-memory system | Completed 2026-09-28 |
| 1 | Foundation | Completed 2026-09-28 (commits `06c0a93`, `7926920`) |
| 2 | Design system | Completed 2026-09-28 (commit `0fc15ef`; device fix `950493b`); design approved by the user |
| 3 | Basic calculator (engine, memory) | **Complete and audited** (commits `4fec0b6`, `57a1e73`, `85c6c84`; audit `453af28`) |
| 4 | History and saved calculations | **In progress.** History implemented 2026-09-29 (not yet committed — see Known Issues #13). Saved calculations not started (blocked, P-12). |
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

### Phase 4: History (2026-09-29, this session, not yet committed)

Details: [ARCHITECTURE.md](ARCHITECTURE.md) §1.17; decisions DEC-044, DEC-045. See "Phase 4: History module" above for the full narrative.

- Domain, data and application layers over the existing `history` table (no migration needed).
- `HistoryContent`, replacing the Phase 1 placeholders in `HistoryPage` and `HistoryPanel`.
- `CalculatorNotifier` logs every successful `=` and gained `useHistoryResult`; no other change to the calculator.
- 27 new tests, all passing; fixed two test-infrastructure bugs found along the way (`AppRoot`/`ProviderScope` nesting, and sqflite's single-instance database caching across tests) — see DEC-045.
- Not yet committed: see "Known Issues" #13.

### Test on the user's phone (2026-09-29, this session)

The phone was connected by USB at the user's request, after the History module was built (the debug build works despite the stray `packages/calc_engine` scaffold, since nothing imports it — see Known Issues #13).

- **Device:** `23124RN87I`, Android 15, 360×800 dp. **Method:** `adb install -r` (debug build), `adb shell input tap` and `input text`, `screencap`.
- **Method note:** this was a fresh, direct on-device pass (tap and screenshot), not the `uiautomator dump` label-reading method earlier phone tests used.

| Check | Result |
| --- | --- |
| `5+3=` then `8−5=` | Both computed correctly; History showed both, newest first, right after computing |
| Copy | Tapping the copy icon on an entry showed a "Copied 3" confirmation |
| Delete | Removed just that one entry, immediately, no confirmation (as designed) |
| Reuse | Tapping an entry's body returned to the calculator with its exact result (`3`) loaded, ready to continue |
| `5÷0=` (an error) | Showed "Can't divide by zero"; opening History afterwards confirmed **no entry was added** for it |
| Search | Typing `0.25` filtered the list down to the one matching entry |
| Clear all → Cancel | Left every entry in place |
| Clear all → Clear all | Emptied the list; the "No history yet" empty state appeared |
| Memory (MR) regression check | Recalled an earlier memory value into a new expression and multiplied it; computed correctly — the History changes didn't disturb memory |

- **Found and fixed on this pass:** none — every check passed on the first try.
- **Phone settings:** auto-rotate was found **on** after the test session (`accelerometer_rotation=1`), though it had been off at the start; not clear which step changed it (no landscape testing was done this session, so it's unlikely to be caused by this app). Restored to off (`accelerometer_rotation=0`, `user_rotation=0`), matching the state before the test. All screenshots taken during the test were deleted from the phone afterwards.

## Work In Progress

**Blocked, mid Phase 4, but verified working on the user's phone.** The History module is implemented, its automated tests pass, and it was also exercised directly on the user's device this session (see "Test on the user's phone" above) — every check passed. Two things still need the user before this session can close out cleanly:

1. Delete the stray scaffold files inside `packages/calc_engine/` (see "Known Issues" #13 for the exact list). Claude's sandbox correctly refused to do this itself.
2. Decide how saving a calculation should be triggered on the calculator screen (P-12), so saved calculations can start.

Nothing has been committed this session yet (the working tree currently contains the stray files, which must not be committed).

## Current Task

Waiting on the user for the two items above.

- **Screenshots:** the design-review generator wasn't regenerated this session (History's UI has no design-system status yet; nothing on the *approved* calculator screen changed). Direct on-device screenshots were taken and reviewed as part of the phone test instead (see above), then deleted from the phone.
- **On the phone:** the debug build from this session is installed (`23124RN87I`); the calculator and memory were left cleared and rotation settings restored.

## Next Task

1. **Once the user deletes the stray `packages/calc_engine` files:** re-run `flutter analyze`, `dart format --set-exit-if-changed`, `flutter test` (expect 439 passed, 1 skipped, 0 failed), `dart test` in the engine, and `flutter build apk --debug`. Then make the local commit for the History module.
2. **Once the user decides the saved-calculations UI entry point (P-12):** build `SavedCalculation`, `SavedCalculationRepository`, `SqfliteSavedCalculationRepository` and a notifier (same shape as History's, ARCHITECTURE.md §1.17), then the UI the user chose.
3. **After both are done:** update the docs (this file, CHANGELOG.md, ROADMAP.md's Phase 4 status), report, and stop for the user's review before Phase 5.

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
- **Don't wrap `AppRoot` in a second `ProviderScope`** to add test overrides (breaks its own preferences override; DEC-045). Add to `AppRoot.overrides` / `pumpApp` instead.
- **Any test opening an in-memory database more than once in a process** (one per test) must pass `AppDatabase.open(..., singleInstance: false)`, or sqflite hands back the same cached database and tests leak into each other (DEC-045).
- **Don't add a "save" button to the calculator screen** without the user's decision (P-12) — it touches the approved Phase 2/3 design.
- **Watch the working directory before running `flutter`/`dart` commands.** A stray `flutter create`-style scaffold appeared inside `packages/calc_engine/` this session from (probably) a command run with the wrong cwd; see "Known Issues" #13.

## Pending Decisions

| ID | Decision | Needed by | Notes |
| --- | --- | --- | --- |
| **P-5** | iOS verification: does the user have access to a Mac? | Before any iOS claim | iOS was not built (Windows) |
| **P-6** | The rest of the engine defaults: `−3²`, `2^3^2`, `0^0`, `(−8)^(1/3)`, `tan 90°` | Before Phase 5 | Percent is settled (DEC-036). See [PROJECT_MEMORY.md](PROJECT_MEMORY.md#calculation-correctness-principles). |
| **P-7** | App version source for the About screen | Phase 10 | `package_info_plus` or a build-time constant |
| **P-9** | Windows Developer Mode, or accept the one-time `pub get` failure after plugin changes | Whenever convenient | Symlinks for the kept desktop folders |
| **P-10** | Keep `kotlin.incremental=false`, or put the project and the pub cache on one drive | Optional | DEC-027 |
| **P-12** | How should saving a calculation be triggered from the calculator screen? | Before saved calculations can start | Needs a new tap target on the approved Phase 2/3 UI; Claude won't add one silently |

**Open to the user's review** (adopted by Claude during Phase 3): DEC-038 to DEC-043. The ones the user is most likely to have a view on:

- implied multiplication has the same precedence as `×`, so `6÷2(1+2)` = 9 (DEC-039)
- the memory row is always visible, and there is no "more" menu (DEC-041)
- no history panel on phones in landscape (DEC-042)

**Open to the user's review** (adopted by Claude during Phase 4): DEC-044 (what history stores; reuse inserts the exact result rather than restoring the editable expression; no dedup), DEC-045 (test infrastructure only, no product-facing effect).

**Device testing.** The user's phone (`23124RN87I`) is used when it is connected and a test is natural or requested. Restore any phone setting a test changes.

**Resolved this session (2026-09-28, the audit):**

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
| `lib/features/history/*` | History: domain, data (`SqfliteHistoryRepository`), application (`HistoryNotifier`), presentation (`HistoryContent`) |
| `lib/app/modes/calculator_mode.dart` | Now also `CalculatorModeStorage`, the mode's fixed storage id |
| `test/helpers/test_app.dart` | `pumpApp` now also gives every widget test an isolated in-memory database (DEC-045) |
| `test/design_review/design_review_screenshots_test.dart` | The screenshot generator, skipped by default |
| (Phase 1 files) | See ARCHITECTURE.md §1: startup, navigation, shell, persistence, l10n |

## Dependencies

- **Added in Phase 3:**
  - app: `calc_engine` (path `packages/calc_engine`)
  - engine: `rational` ^2.2.3 (locked 2.2.3); dev `test` ^1.31.1 (locked 1.31.1)
- **Added in Phase 4 (History):**
  - app: `riverpod` ^3.4.3 (DEC-045) — already resolved transitively through `flutter_riverpod`, same publisher; needed only so `AppRoot.overrides` can be typed `List<Override>`, which `flutter_riverpod` doesn't re-export.
- **Actually in `pubspec.yaml` and `pubspec.lock`:**
  - app: `flutter_riverpod` 3.4.3, `riverpod` 3.4.3, `shared_preferences` 2.5.5, `sqflite` 2.4.4, `path` 1.9.1, `intl` 0.20.3, `flutter_localizations`, `calc_engine`
  - dev: `flutter_test`, `flutter_lints` 6.0.0, `shared_preferences_platform_interface` 2.4.2, `sqflite_common_ffi` 2.4.3
- **Not added:** `decimal` (DEC-038).
- **Still planned:** ARCHITECTURE.md §3.8.

## Tests

**Run in the Phase 4 History session (2026-09-29), in `smart_calculator/`:**

| Command | Result |
| --- | --- |
| `flutter analyze` | `No issues found!` |
| `flutter test` (final, whole suite) | **438 passed, 1 skipped, 1 failed** (`layer_boundaries_test.dart`, caused entirely by the stray `packages/calc_engine` scaffold — see "Known Issues" #13; not a Phase 4 code issue) |
| `flutter test test/features/history/` and `test/features/calculator/domain/expression_buffer_test.dart` | All pass in isolation (27 new tests) |
| `dart test` in `packages/calc_engine` | `+260: All tests passed!` (unchanged; the engine wasn't touched) |
| `flutter build apk --debug` | **Built** (93.6 s). Works despite the stray scaffold below — nothing imports it, so it doesn't reach the build. Installed and tested on the user's phone; see "Test on the user's phone" above. |

**Expected once the user removes the stray files (not yet confirmed):** `flutter test` → 439 passed, 1 skipped, 0 failed. (The build and the phone test do **not** need to wait for this — only `flutter analyze`/`flutter test` and the eventual commit do.)

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
| Expression buffer | 143 (140 after the Phase 3 audit, +3 this session: `toCanonicalText`, for history) |
| Calculator notifier and memory | 66 (61 after the Phase 3 audit, +5 this session: writing history on `=`, reusing a history entry) |
| Number format | 33 |
| Calculator screen | 24 |
| Display formatter | 18 |
| `DisplayText` | 12 |
| Gallery accessibility (10 sections × 4 themes) | 40 |
| Earlier app tests (Phases 1–2), including 2 new `CalculatorButton` tests, 1 new app test and 1 new shell test | 80 |
| History repository | 9 |
| History notifier | 5 |
| History widget (`HistoryContent`) | 10 |
| **App total** (`flutter test`) | **439 once the stray-file cleanup lands** (438 passing + 1 currently failing for the reason in "Known Issues" #13) |

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
10. ~~`appDatabaseProvider` has no consumers yet~~ **Resolved in Phase 4:** `historyRepositoryProvider` reads it now (ARCHITECTURE.md §1.17).
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
13. **Blocking: a stray Flutter app inside `packages/calc_engine`** (2026-09-29, this session). A full `flutter create`-style scaffold appeared there — `lib/main.dart` (imports `package:flutter/material.dart`), `android/`, `.metadata`, `analysis_options.yaml`, `.gitignore`, `.idea/`, `calc_engine.iml` — all untracked, all created in the same second. The triggering command isn't confirmed with certainty. **Confirmed unaffected:** `packages/calc_engine/pubspec.yaml` (`git diff` is empty) and every real engine source file (all 260 engine tests still pass). This is the sole cause of `layer_boundaries_test.dart`'s one failure (see "Tests"). Claude tried to delete the files; the sandbox's safety layer correctly refused (a destructive operation on a directory), so **the user needs to delete the paths above** before the History module can be committed and the QA gate closed.

## Blockers

- **Phase 4, saved calculations:** needs the user's decision on the save-button UI entry point (P-12).
- **Phase 4, closing out History:** needs the user to delete the stray `packages/calc_engine` scaffold files (Known Issue #13) before a clean QA gate and a commit.
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

**2026-09-29, Phase 4 History session** (for earlier sessions, see below and [CHANGELOG.md](CHANGELOG.md)).

1. The user approved Phase 4 ("phaes 4 start").
2. Built the History module end to end: domain, data (`SqfliteHistoryRepository`, over the existing schema — no migration needed), application (`HistoryNotifier`), presentation (`HistoryContent`, replacing the Phase 1 placeholders in `HistoryPage` and `HistoryPanel`). Wired `CalculatorNotifier` to log every successful `=` and to reuse a history entry's exact result (`useHistoryResult`, the same mechanism MR uses). See "Phase 4: History module" above and DEC-044.
3. **Found and fixed two real test-infrastructure bugs**, not assumed away:
   - Wrapping `AppRoot` in a second `ProviderScope` to add a test-only database override broke `AppRoot`'s *own* `sharedPreferencesProvider` override — reproduced, root-caused (Riverpod resolves unscoped providers at the app's one root scope, not the nearest ancestor with an override), and fixed by giving `AppRoot` an `overrides` parameter instead (DEC-045).
   - Every widget test in `calculator_notifier_test.dart` was sharing one in-memory database (sqflite caches by path when `singleInstance` isn't set to `false`), so history from one test leaked into the next; fixed with a new `AppDatabase.open(..., singleInstance: false)` option (DEC-045).
   - The clipboard-copy tests hung indefinitely until a mock `SystemChannels.platform` handler was added (the same pattern the existing paste tests already use).
4. 27 new tests (repository, notifier, widget, plus `ExpressionBuffer.toCanonicalText`), all passing. Full suite: 438 passed, 1 skipped, 1 failed — the failure is unrelated to History (see point 5).
5. **A blocking accident, reported rather than worked around:** a full Flutter app got scaffolded inside `packages/calc_engine` at some point this session (root cause not confirmed with certainty). Confirmed the engine's own `pubspec.yaml` and source files untouched. Attempted to delete the stray files; the sandbox correctly refused. Stopped and asked the user, rather than trying another way around the refusal.
6. Asked the user how saving a calculation should be triggered from the calculator screen (P-12), rather than adding a new button to the approved Phase 2/3 design without asking.
7. **Docs:** this file, ARCHITECTURE.md (§1.17, provider table, test counts), ROADMAP.md (Phase 3 moved to Completed, Phase 4 moved to In Progress), DECISIONS.md (DEC-044, DEC-045) updated. **Not committed yet** — see Known Issues #13.

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
2. **Check whether the stray `packages/calc_engine` files are gone** (`git status -s packages/calc_engine/` should be empty; see Known Issues #13 for the exact list). If they're still there, this is still the first thing blocking a clean QA gate — don't try to delete them; ask again if needed.
3. **Once they're gone:** re-run the full QA gate (`flutter analyze`, `dart format --set-exit-if-changed`, `flutter test` — expect 439 passed, 1 skipped, 0 failed —, `dart test` in the engine, `flutter build apk --debug`), then make the local commit for the History module.
4. **Check whether the user has answered P-12** (how to trigger saving a calculation). If yes, build saved calculations (domain/data/application first, the same shape as History's; then the UI). If not, ask, and don't add a save button on your own guess — it touches the approved Phase 2/3 design.
5. **Build every new screen only from `lib/core/widgets/` and the tokens** (rule 12, DEC-034).
6. **Checks:**
   - `flutter analyze`
   - `dart format --set-exit-if-changed lib test packages`
   - `flutter test`
   - `dart test` in `packages/calc_engine`
   - `flutter build apk --debug`
   - after visual changes, the screenshots

   Record the actual results.
7. Finish with the Session Handoff Protocol.
