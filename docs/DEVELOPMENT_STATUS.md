# Development Status

> **The most important file for context recovery.** Rewrite it to the current truth at the end of every meaningful session, following the Session Handoff Protocol in [CLAUDE.md](../CLAUDE.md). Every claim here must be backed by code, by Git, or by a command that was actually run.

**Last updated:** 2026-09-29, end of Phase 4 (both History and saved calculations complete, phone-tested; not yet committed).

## At a Glance

| Question | Answer |
| --- | --- |
| Where are we? | **Phase 3 and Phase 4 are both complete.** Phase 4: calculation history (every `=` logged: view, search, reuse, copy, delete, clear all) and saved calculations (save, rename, reuse, delete, clear all), both phone-tested. |
| What exists in code? | Everything from Phase 3, plus history and saved calculations, behind a tab toggle inside the History screen (page and panel). See ARCHITECTURE.md §1.17–1.18. |
| What is being worked on? | Nothing. Phase 4 is done and awaits the user's review before Phase 5. |
| What happens next? | The user reviews Phase 4, then explicitly approves Phase 5 (Scientific). |
| Git? | `main` is ahead of `origin/main`. The Phase 3 audit (`453af28`) and the History module (`1604248`) are committed. **Saved calculations is not committed yet** — it's this session's newest work; see "Completed Work". **Claude never pushes; the user pushes themselves.** |
| What must not be repeated? | See "Do NOT Repeat" |
| Known issues? | See "Known Issues". #13 (the stray scaffold) is **resolved** — the user deleted it 2026-09-29. |
| Pending decisions? | P-5, the rest of P-6 (Phase 5), P-7, P-9, P-10. **P-12 resolved:** the user delegated the saved-calculations UI to Claude ("jaisa tum karo, waha karo") — see DEC-046 for what was built. |

## Current Phase

**Phase 4 (History and saved calculations): approved 2026-09-29. Both halves complete and phone-tested.**

- The user approved Phase 3 (after its audit) and Phase 4 on 2026-09-29 ("phaes 4 start").
- History: view, search, reuse (inserts the exact result, like MR), copy, delete, clear all — DEC-044. Verified on the user's phone.
- Saved calculations: a History/Saved tab toggle; saving is a history-entry action, not new UI on the calculator screen — DEC-046 (the user's UI decision, delegated to Claude). Verified on the user's phone.
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

### Phase 4: History (2026-09-29, commit `1604248`)

Details: [ARCHITECTURE.md](ARCHITECTURE.md) §1.17; decisions DEC-044, DEC-045. See "Phase 4: History module" above for the full narrative.

- Domain, data and application layers over the existing `history` table (no migration needed).
- `HistoryContent`, replacing the Phase 1 placeholders in `HistoryPage` and `HistoryPanel`.
- `CalculatorNotifier` logs every successful `=` and gained `useHistoryResult`; no other change to the calculator.
- 27 new tests, all passing; fixed two test-infrastructure bugs found along the way (`AppRoot`/`ProviderScope` nesting, and sqflite's single-instance database caching across tests) — see DEC-045.

### Phase 4: Saved calculations (2026-09-29, this session, not yet committed)

Details: [ARCHITECTURE.md](ARCHITECTURE.md) §1.18; decision DEC-046 (the user delegated this design to Claude — "jaisa tum karo, waha karo").

- Domain, data and application layers over the existing `saved_calculations` table (no migration needed; `kind` is always `'basic'` for now).
- `HistoryContent` gained a History/Saved tab toggle (`AppChoiceGroup`); the Saved tab has its own search and clear-all.
- Saving is a new third action on a history entry (a bookmark icon, alongside copy and delete), opening a name sheet (`lib/features/saved_calculations/presentation/save_name_sheet.dart`, reused for renaming).
- **No change to the calculator screen or the app shell** — the design was kept entirely inside the screen History already owns, per DEC-046's reasoning.
- 24 new tests, all passing (23 saved-calculations tests, plus 1 checking the history tile's new 3-action row fits at 200% text).

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

### Test on the user's phone: saved calculations (2026-09-29, this session)

Same device and method as the History phone test above, after building and installing the debug APK with saved calculations.

| Check | Result |
| --- | --- |
| Opening History | The History/Saved tab toggle renders correctly (a segmented button); old history entries from the earlier test session were still there, correctly, since the app was updated in place, not reinstalled clean |
| Save (bookmark icon on a history entry) | Opened a "Save calculation" sheet; the Save button was disabled until a name was typed, then enabled |
| Confirming Save | Showed a `Saved "Rent budget"` confirmation |
| Switching to the Saved tab | Showed the one saved entry: name, result and expression, with its own "Search saved calculations" label |
| Rename | Opened a pre-filled "Rename" sheet; changing the name and confirming updated it in place |
| Reuse (tapping the entry) | Returned to the calculator with its exact result loaded |
| Delete | Removed the entry; the "No saved calculations yet" empty state appeared, and the clear-all icon was disabled |

- **Found and fixed on this pass:** none.
- **Not separately re-tested on the phone:** search and clear-all-with-confirmation on the Saved tab specifically (only one entry existed by the time of this test); both are covered by the automated widget tests, and both are the same code path already verified for History.
- **Phone settings:** auto-rotate was found on again after this pass; restored to off once more. No rotation-related action was taken in this test (nor in the previous one), so this doesn't appear to be caused by the app; still flagged here for the next session in case a pattern emerges.

## Work In Progress

None. Phase 4 (both History and saved calculations) is complete, its full QA gate is clean, and both halves were verified on the user's phone. **Saved calculations is not committed yet** — that's the only remaining step, and it doesn't require the user (see "Next Task").

## Current Task

The user reviews Phase 4 (History and saved calculations), then decides on Phase 5.

- **Screenshots:** the design-review generator wasn't regenerated this session (neither feature added anything to the design system; nothing on the *approved* calculator screen changed). Direct on-device screenshots were taken and reviewed as part of both phone tests instead (see above), then deleted from the phone.
- **On the phone:** the debug build with saved calculations is installed (`23124RN87I`); the calculator was left showing `8` (the last reused result) and rotation settings restored.

## Next Task

1. **Commit saved calculations locally** (History is already committed, `1604248`). Nothing blocks this.
2. **If the user asks for changes to either feature:** make them, re-run the checks, and re-test on the phone if the user connects it.
3. **After the user explicitly approves Phase 5 (Scientific):** see ROADMAP.md for its scope (functions, the engine's function registry, the remaining P-6 defaults).

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
- **Don't add a "save" button (or any new affordance) to the calculator screen or the app shell** without the user's explicit say-so — DEC-046 kept saved calculations entirely inside the History screen for exactly this reason.
- **Watch the working directory before running `flutter`/`dart` commands.** A stray `flutter create`-style scaffold appeared inside `packages/calc_engine/` in the Phase 4 session from (probably) a command run with the wrong cwd; see "Known Issues" #13 (resolved, but watch for a repeat).

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

**Open to the user's review** (adopted by Claude during Phase 4): DEC-044 (what history stores; reuse inserts the exact result rather than restoring the editable expression; no dedup), DEC-045 (test infrastructure only, no product-facing effect), DEC-046 (the History/Saved tab toggle, and saving as a history-entry action — the user's own P-12 answer was to let Claude decide this).

**Device testing.** The user's phone (`23124RN87I`) is used when it is connected and a test is natural or requested. Restore any phone setting a test changes. **Unexplained:** auto-rotate (`accelerometer_rotation`) has turned itself on during the last two phone-test sessions, with no rotation-related action taken in either. Restored to off both times. Not yet linked to anything this app does; worth watching, not yet worth chasing further.

**Resolved this session (2026-09-29):**

- P-12: the user delegated the saved-calculations UI design to Claude ("jaisa tum karo, waha karo") — see DEC-046.

**Resolved in the audit session (2026-09-28):**

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
| `lib/features/history/*` | History: domain, data (`SqfliteHistoryRepository`), application (`HistoryNotifier`), presentation (`HistoryContent`, now also the History/Saved tab toggle) |
| `lib/features/saved_calculations/*` | Saved calculations: domain, data (`SqfliteSavedCalculationRepository`), application (`SavedCalculationsNotifier`), presentation (`save_name_sheet.dart`'s `promptForName`, used for both saving and renaming) |
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

**Final, run in the Phase 4 session (2026-09-29) after the user deleted the stray `packages/calc_engine` scaffold, in `smart_calculator/`:**

| Command | Result |
| --- | --- |
| `flutter analyze` | `No issues found!` |
| `dart format --set-exit-if-changed lib test packages` | `Formatted 119 files (0 changed)`, exit 0 |
| `flutter test` (whole suite) | `+464 ~1: All tests passed!` (464 passed, 1 skipped — the design-review generator; 0 failed) |
| `dart test` in `packages/calc_engine` | `+260: All tests passed!` (unchanged; the engine wasn't touched) |
| `flutter build apk --debug` | **Built** twice this session (once for History alone, 93.6 s; once more with saved calculations added, 40.2 s). Both installed and tested on the user's phone; see the two "Test on the user's phone" entries above. |

**Earlier in the same session, before the cleanup (kept for the record):** `flutter test` reported 438 passed, 1 skipped, 1 failed — the failure was `layer_boundaries_test.dart`, caused entirely by the stray scaffold (it correctly detected a Flutter import inside `packages/calc_engine`), not by any Phase 4 code. `flutter analyze` independently flagged the same file with a `depend_on_referenced_packages` lint. Both were re-run clean after the cleanup, above.

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
| History widget (`HistoryContent`), including the 3-action row at 200% text | 11 |
| Saved-calculations repository | 8 |
| Saved-calculations notifier | 6 |
| Saved-calculations widget (saving, the Saved tab, rename, reuse, delete, search, clear all) | 9 |
| **App total** (`flutter test`) | **464 passed, 1 skipped, 0 failed** |

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
13. ~~Blocking: a stray Flutter app inside `packages/calc_engine`~~ **Resolved 2026-09-29.** A full `flutter create`-style scaffold appeared there during this session — `lib/main.dart` (imports `package:flutter/material.dart`), `android/`, `.metadata`, `analysis_options.yaml`, `.gitignore`, `.idea/`, `calc_engine.iml` — all untracked, all created in the same second. The triggering command was never confirmed with certainty. `packages/calc_engine/pubspec.yaml` and every real engine source file were confirmed unaffected throughout (`git diff` empty; all 260 engine tests kept passing). Claude tried to delete the files and was correctly refused by the sandbox's safety layer (a destructive operation on a directory); the user deleted them ("okay delete"). `flutter analyze` and `flutter test` are both clean afterwards (see "Tests"). **Watch for a repeat** — the exact cause is still unknown.

## Blockers

None. Phase 4 is complete; the next blocker will be whatever Phase 5 needs from the user (see ROADMAP.md and P-6). No technical blockers remain either — iOS still can't be built on Windows, as always.

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

**2026-09-29, Phase 4 session** (for earlier sessions, see below and [CHANGELOG.md](CHANGELOG.md)).

1. The user approved Phase 4 ("phaes 4 start").
2. Built the History module end to end: domain, data (`SqfliteHistoryRepository`, over the existing schema — no migration needed), application (`HistoryNotifier`), presentation (`HistoryContent`, replacing the Phase 1 placeholders in `HistoryPage` and `HistoryPanel`). Wired `CalculatorNotifier` to log every successful `=` and to reuse a history entry's exact result (`useHistoryResult`, the same mechanism MR uses). See ARCHITECTURE.md §1.17 and DEC-044.
3. **Found and fixed two real test-infrastructure bugs**, not assumed away:
   - Wrapping `AppRoot` in a second `ProviderScope` to add a test-only database override broke `AppRoot`'s *own* `sharedPreferencesProvider` override — reproduced, root-caused (Riverpod resolves unscoped providers at the app's one root scope, not the nearest ancestor with an override), and fixed by giving `AppRoot` an `overrides` parameter instead (DEC-045).
   - Every widget test in `calculator_notifier_test.dart` was sharing one in-memory database (sqflite caches by path when `singleInstance` isn't set to `false`), so history from one test leaked into the next; fixed with a new `AppDatabase.open(..., singleInstance: false)` option (DEC-045).
   - The clipboard-copy tests hung indefinitely until a mock `SystemChannels.platform` handler was added (the same pattern the existing paste tests already use).
4. **A blocking accident, reported rather than worked around:** a full Flutter app got scaffolded inside `packages/calc_engine` at some point this session (root cause not confirmed with certainty). Confirmed the engine's own `pubspec.yaml` and source files untouched. Attempted to delete the stray files; the sandbox correctly refused. Stopped and asked the user, rather than trying another way around the refusal.
5. **Phone-tested History** at the user's request (USB-connected): computing, viewing, search, copy, delete, reuse, clear-all (cancel and confirm), the empty state, and that a division-by-zero error isn't logged. Every check passed.
6. The user said "okay delete" (the stray files) and delegated the saved-calculations UI design ("jaisa tum karo, waha karo" — P-12 resolved). Deleted the stray files, re-ran the full QA gate clean (464 passed, 1 skipped, 0 failed), and committed the History module (`1604248`).
7. **Designed and built saved calculations** (DEC-046): a History/Saved tab toggle inside the screen History already owns, rather than any new UI on the calculator screen or the shell. Saving is a new third action on a history entry (a bookmark icon), opening a name sheet also reused for renaming. 24 new tests, all passing.
8. **Phone-tested saved calculations**: saving a history entry (including that the Save button requires a name), the Saved tab, rename, reuse and delete, and the empty state. Every check passed on the first try.
9. **Docs:** this file, ARCHITECTURE.md (§1.17–1.18, provider table, test counts), ROADMAP.md (Phase 4 moved to Completed), DECISIONS.md (DEC-044, DEC-045, DEC-046) updated. **Saved calculations is not committed yet** — the only remaining step, and it needs no further input from the user.

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
2. **If saved calculations still isn't committed** (`git status -s` shows `lib/features/saved_calculations/` and the `HistoryContent` changes as uncommitted), commit it — nothing blocks this, it was just the last thing built this session.
3. **If the user hasn't reviewed Phase 4 yet,** ask for the review. Apply any requested changes through the components and tokens, then re-run the checks (and re-test on the phone if they connect it).
4. **Don't start Phase 5** until the user explicitly approves it. Then settle the rest of P-6 (the power and trigonometry defaults) before building the engine's function registry.
5. **Watch for the stray-scaffold issue recurring** (Known Issues #13, resolved but cause unconfirmed): check `git status -s packages/calc_engine/` is empty before trusting `flutter analyze`/`flutter test`.
6. **Build every new screen only from `lib/core/widgets/` and the tokens** (rule 12, DEC-034). Don't add anything to the calculator screen or the app shell without the user asking for it first — see DEC-046 for why that mattered this phase.
7. **Checks:**
   - `flutter analyze`
   - `dart format --set-exit-if-changed lib test packages`
   - `flutter test`
   - `dart test` in `packages/calc_engine`
   - `flutter build apk --debug`
   - after visual changes, the screenshots

   Record the actual results.
8. Finish with the Session Handoff Protocol.
