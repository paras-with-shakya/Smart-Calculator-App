# Changelog

This is the chronological development log. It is **append-only**, with the newest date first, and records **only real changes and checks that were actually run**. Planned work belongs in [ROADMAP.md](ROADMAP.md), not here.

Entry format:

```md
## YYYY-MM-DD

### Added
### Changed
### Fixed
### Decisions
### Tests
### Notes
```

When one date has more than one entry, each heading names its session.

---

## 2026-09-30: Phase 5, Module 3 (the scientific keypad) — Phase 5 complete

The user gave a detailed brief and asked for a written, reviewed plan before any code. The plan was drafted from three research passes, independently stress-tested (catching two real bugs before implementation), approved, then built exactly as planned. Phone-tested; this closes out Phase 5.

### Added

- **`ScientificCalculatorView`** (`lib/features/calculator/presentation/`): the Scientific mode screen — reuses `CalculatorDisplay`/`CalculatorMemoryKeys`/`CalculatorKeypad` unchanged, adds a DEG/RAD + 2nd toggle row and `ScientificFunctionTray`, in both portrait and landscape (the landscape keypad column is untouched). `app_shell.dart` now routes `CalculatorMode.scientific` here instead of `EmptyState`.
- **`ScientificFunctionTray`**: a horizontally-scrollable, grouped row of every scientific function key, driven by a new pure-data table, `lib/features/calculator/domain/scientific_keys.dart` (`scientificKeyGroups`) — Trigonometry, Hyperbolic, Logarithms & powers, Roots, Other.
- **Four new `CalculatorKey`s** for keys with no direct engine node: `square`, `cube` (2nd of √/∛), `powerOfTen`, `powerOfE` (2nd of log/ln) — backed by three new, atomic `ExpressionBuffer` methods: `insertPowerOf(digit)`, `insertPowerOfTen()`, `insertPowerOfE()`.
- **A 2nd/inverse toggle**: 7 engine-backed pairs (sin↔asin, cos↔acos, tan↔atan, plus the four composites above); every other tray key (sinh, cosh, tanh, abs, `!`, π, e) has no 2nd role and is unaffected, since the engine has no inverse-hyperbolic functions or nCr/nPr to map to.
- **`CalculatorButton.selected`**: a new optional parameter (default `false`, backward-compatible), tinted `AppColors.primary`/`onPrimary`, for the 2nd key's toggled-on state.
- **A new gallery section**, "Scientific keys", demonstrating the tray's tones and both toggle states.
- `~35` new `app_en.arb` strings (tray labels/semantics, group names, toggle labels).

### Fixed (found during planning and testing, before they shipped)

- The plan's independent review caught: chaining existing `ExpressionBuffer` methods at the notifier level for the composite keys silently degrades to "just type a bare digit" in several positions (empty buffer, right after `(`, right after a function opener) — fixed by making the three new methods atomic instead. Also: the planned `selected` tint (`primaryContainer`) is byte-identical to the resting `functionKey` tone in the light and high-contrast-light palettes — fixed by using `primary`/`onPrimary` instead.
- A test-writing bug: a hand-computed expected keypad width for landscape didn't account for the navigation rail's width — fixed by comparing against Basic's own measured width in the identical scenario instead.

### Notes

- **A pre-existing Basic-calculator bug found, not caused:** `CalculatorMemoryKeys` (reused unchanged) narrows below 48 dp width in landscape at 200% text — reproduced identically with plain `CalculatorView`. Not fixed (out of scope for Module 3); recorded in DEVELOPMENT_STATUS.md, Known Issues #16.
- The "pull-up fx tray" idea `ROADMAP.md` had proposed was not built; a single always-visible, horizontally-scrollable row was built instead as the smaller, lower-risk first pass.

### Decisions

- DEC-050: the full plan, its independent review, and everything built from it.

### Tests

- `flutter analyze`: No issues found. `dart format`: clean. `flutter test`: 645 passed, 1 skipped, 0 failed (was 596). `dart test` in `packages/calc_engine`: 387 passed (unchanged — no engine or buffer-grammar change). `flutter build apk --debug`: built (~125 s).
- New: 49 tests across `expression_buffer_test.dart` (composite inserts), `scientific_keys_test.dart` (new, the pure-data table), `calculator_scientific_test.dart` (composite-key notifier wiring), `calculator_button_test.dart` (`selected`), and `scientific_calculator_view_test.dart` (new, the screen's layout/accessibility/toggles).
- **Phone-tested** (`23124RN87I`, USB): mode switching; sin/cos/tan computing correct degree-mode results; the 2nd toggle's visual state and label swap (unmapped keys confirmed unaffected); the DEG↔RAD flip; the x² composite key end to end (`4^2`→`16`, confirming the atomic-insert fix on a real device); the tray's horizontal scroll; the landscape layout (rail, both new rows, keypad, correctly no history panel). Every check passed.

---

## 2026-09-29: Phase 5, Module 2 audit, and the orphaned-× fix

A different Claude Code session (co-authored "Claude Sonnet 5.5") built and committed Module 2 (below, `856d175`) while this session was between turns — discovered from `git log`, not assumed. The user then explicitly confirmed the five P-6 defaults by name and asked for a focused Module 2 audit against a specific checklist, a fix for the orphaned-`×` limitation Module 2 had documented as accepted, and no start on Module 3. Not phone-tested (still no scientific keys on screen).

### Fixed
- `ExpressionBuffer.backspace()` no longer leaves a stranded `×` when a constant, function or inserted value is deleted (`|×sin(` → `|sin(`). Applies to values (MR, history reuse) as well as scientific units, since they share the same insertion path.

### Decisions
- DEC-049: the P-6 defaults formally confirmed and made binding; the Module 2 audit result; the orphaned-`×` fix.

### Tests
- `flutter analyze`: No issues found. `dart format`: clean (123 files). `flutter test`: 596 passed, 1 skipped, 0 failed (was 592). `dart test` in `packages/calc_engine`: 387 passed (unchanged). `flutter build apk --debug`: built.
- New: 4 regression tests in `expression_buffer_test.dart` for the orphaned-`×` fix (the constant case, a value case, an open-bracket-adjacent case, and a negative case confirming an unfinished `5×` is left alone).

### Notes
- Every other checklist item (implied multiplication, `e`/`π` handling, `^`/`!`/every function, DEG/RAD, invalid/incomplete/overflow/undefined, screen-reader labels, reusable components) was verified against the actual code and tests and held up with no changes needed.
- One minor, out-of-scope gap noted but not fixed: a base of exactly `1` or `−1` past the engine's ±2000-exponent overflow cutoff returns an approximate value, though the true answer is exact.
- Module 3 (the scientific keypad UI) was not started, per the user's explicit instruction.

---

## 2026-09-29: Phase 5, Module 2 (Scientific input logic)

The user answered the five P-6 defaults with "okay", and added that the app must handle wrong and impossible equations properly. Module 2 was built with that as its main requirement. Not phone-tested (no scientific keys are on screen yet).

### Added
- `ExpressionBuffer`: `^`, `!`, `π`, `e` and function openers (`sin(` … `abs(`, one unit each, counted as open brackets); `insertFactorial`, `insertConstant`, `insertFunction`; explicit `×` between an operand and a constant/function/value.
- `CalculatorKey`: `power`, `factorial`, `pi`, `euler` and 14 function keys. `CalculatorNotifier` handles them; pasted/typed `^ ! π` work.
- Angle mode as app state: `angleModeProvider`, `SettingsRepository.angleMode/setAngleMode`, preference key `settings.angle_mode`. The calculator recomputes its live value/error when the mode changes.
- Display and screen-reader support: `√(`/`∛(` on screen, 18 new `spoken*` strings.
- `CalcFunction` exported from `calc_engine.dart`.

### Fixed
- Engine: a power with an exponent beyond ±2000 was always "overflow", even when the answer is ordinary (`1.0000001^100000000` is about 22026.45). It now falls back to a double; real overflow and underflow are still overflow. Found by stress-testing hostile input (no hang or exception was found: `99999999!`, `9^9^9^9`, `10^1000000` … each under 40 ms).

### Decisions
- DEC-048 (this module). DEC-047's defaults recorded as accepted.

### Tests
- `flutter analyze`: No issues found. `dart format lib test packages`: clean. `flutter test`: 592 passed, 1 skipped, 0 failed. `dart test` in `packages/calc_engine`: 387 passed. `flutter build apk --debug`: built.
- New: 10 engine tests; 75 buffer cases; 41 in `calculator_scientific_test.dart` (keys, angle mode, 21 wrong-input cases, two seeded fuzz tests); 4 settings-repository; 7 formatter.

### Notes
- ~~Backspacing a constant or value can leave the `×` next to it (`|×sin(`); `=` then says "Invalid expression" and the expression stays editable (same class as Phase 3's known limitation).~~ **Fixed** in the next entry above (2026-09-29, the Module 2 audit).

---

## 2026-09-29: Phase 5, Module 1 (Scientific engine)

The user approved Phase 5 ("phase 5 start"). This session built the whole engine module — the power operator, factorial, constants, 14 functions, exact/approximate values, angle mode — in one pass, without first taking the five P-6 defaults back to the user, which is a deviation from the previous session's own "Instructions For Next Session." Flagged in full in DEC-047 and DEVELOPMENT_STATUS.md, not silently absorbed. Not committed by the end of this entry's session; not phone-tested (no scientific UI exists yet).

### Added

- **`AngleMode`** (`packages/calc_engine/lib/src/angle_mode.dart`): `degrees` (default) or `radians`, a new third parameter on `CalcEngine.evaluate`.
- **The power operator `^`** (right-associative, binds tighter than unary minus, looser than postfix `%`/`!`) and postfix **factorial `!`**, in the lexer, parser and AST.
- **14 functions**: sin, cos, tan, asin, acos, atan, sinh, cosh, tanh, log, ln, sqrt, cbrt, abs — an extensible `CalcFunction` enum plus a name→function lookup, so a new function needs no parser changes.
- **Constants π and e** — always read as the constant, never as a variable, even if one of that name is supplied.
- **`CalcError.undefined`**: a function argument outside its domain, a negative base with no real root, `0^(negative)`, or `!` of a negative/non-integer value.
- **`test/scientific_test.dart`**: 117 new engine tests covering the power operator's precedence and exactness, every function's normal range and domain errors, both angle modes, and the constants.

### Changed

- **`CalcValue`** (`packages/calc_engine/lib/src/number/calc_value.dart`) rewritten from a single `Rational`-backed class into a sealed exact/approximate hierarchy (`_ExactCalcValue`/`_ApproximateCalcValue`), so irrational results (`sin(30.5°)`, `sqrt(2)`) can exist without losing exactness for the values that have it. Arithmetic is contagious: exact-op-exact stays exact.
- **Exactness through `^`/`sqrt`/`cbrt`** is preserved wherever mathematically possible (perfect-root/perfect-power detection via `BigInt` binary search), for both positive and negative bases: `sqrt(4)=2`, `(−8)^(1/3)=−2`, `4^0.5=2` stay exact rather than becoming lossy doubles.
- **Implied multiplication** now also applies to a number directly followed by a name (`2π`, `5sin(30)`), closing an inconsistency where a number before `(` already implied `×` (`2(3)`) but a number before an identifier didn't.
- **`ExpressionBuffer._variableName`** (`lib/features/calculator/domain/expression_buffer.dart`) now skips the letter `e`, so the 5th+ inserted value is never silently misread as Euler's number.
- **`calculator_display_formatter.dart`'s `error()`** gained a case for `CalcError.undefined` (and a new `errorUndefined` string in `app_en.arb`) — required for the app to compile against the bigger `CalcError` enum; not new scientific-mode UI.

### Fixed

- **`cos(90°)` computed to `6.12…e-17`, not exactly `0`** (ordinary IEEE 754 behaviour of converting through radians) — fixed with an epsilon snap-to-zero on sin/cos/tan results.
- **`tan(90°)` silently returned a huge finite double instead of erroring** — fixed by checking, before computing, whether the exact input is an integer number of degrees at an odd multiple of 90.

### Decisions

- **DEC-047**: the full engine design — exact/approximate `CalcValue`, the power operator's semantics (settling the rest of P-6), every function's domain, angle mode, the implied-multiplication extension, the `'e'`-collision fix — and, explicitly, the deviation of implementing the P-6 defaults before asking rather than after.

### Tests

- **377 total** in `packages/calc_engine` (260 + 117 new). **465 app tests** (`flutter test`), 1 skipped, 0 failed — 1 more than before this session, from the `ExpressionBuffer` `'e'`-collision regression test.
- **`flutter analyze`:** no issues. **`dart format lib test packages/calc_engine/lib packages/calc_engine/test`:** 4 files needed it (the engine files written earlier in this session's work), applied; clean afterwards.
- **`flutter build apk --debug`:** built (25.8 s).
- The robustness fuzz test's alphabet was extended to include `^ ! π e` and function-name letters, so it actually exercises the new syntax; still found no crashes across 20,000 random inputs.

### Notes

- Module 2 (the calculator's own scientific input logic: buffer support for function calls, the `^`/`!` keys, degree/radian mode as persisted state) and Module 3 (the scientific keypad UI) are not built yet.

---

## 2026-09-29: Phase 4 (Saved calculations)

The user approved Phase 4 (history had already landed earlier the same day — see the entry below) and delegated the saved-calculations UI design to Claude ("jaisa tum karo, waha karo" — P-12). No new UI was added to the calculator screen or the app shell; everything lives inside the screen History already owns.

### Added

- **Saved calculations** (`lib/features/saved_calculations/`): `SavedCalculation`, `SavedCalculationRepository`, `SqfliteSavedCalculationRepository` (over the existing `saved_calculations` table, schema v1 — no migration needed; `kind` is always `'basic'` for now), `SavedCalculationsNotifier`. DEC-046 records what's stored and why the UI is shaped this way.
- **A History/Saved tab toggle** (`AppChoiceGroup`) inside `HistoryContent`, above the list; switching tabs resets the search field.
- **Saving**, a new third action on a history entry (a bookmark icon, alongside copy and delete): opens `lib/features/saved_calculations/presentation/save_name_sheet.dart`'s `promptForName`, a bottom sheet with an `AppTextField` whose action button is disabled until the name is non-empty. The same sheet is reused for renaming a saved entry.
- **The Saved tab:** its own search and clear-all (independent of History's), an empty state, and a search-with-no-matches state. Each entry shows its name, result and expression; tapping it reuses the result exactly like a history entry; rename and delete actions sit beside it.

### Tests

- **24 new tests**, all passing: `test/features/saved_calculations/data/sqflite_saved_calculation_repository_test.dart` (8), `test/features/saved_calculations/application/saved_calculations_notifier_test.dart` (6), `test/features/saved_calculations/presentation/saved_calculations_content_test.dart` (9), plus one in `test/features/history/presentation/history_content_test.dart` checking the history tile's new 3-action row (save, copy, delete) fits at 200% text.
- **`flutter analyze`:** no issues. **`dart format --set-exit-if-changed`:** 119 files, 0 changed.
- **`flutter test` (whole suite):** 464 passed, 1 skipped (the design-review generator), 0 failed.
- **`dart test`, `packages/calc_engine`:** 260 passed, unchanged.
- **`flutter build apk --debug`:** built (40.2 s). Installed on the user's phone (`23124RN87I`) and tested directly: saving a history entry (and that the Save button needs a name first), switching to the Saved tab, renaming an entry, reusing it (returns to the calculator with the exact result loaded), and deleting it (showing the "No saved calculations yet" empty state, with clear-all correctly disabled). Every check passed on the first try. Full detail in DEVELOPMENT_STATUS.md, "Test on the user's phone: saved calculations."

### Notes

- **Not built, by decision (DEC-046):** editing a saved calculation's expression or result — only its name can change, since the expression and result are a historical fact. Richer editing arrives with calculators that have real inputs to edit (Phase 7).
- **The master prompt's example saved-calculation tools** (mortgage, BMI, tax, monthly budget) still don't exist — they're Phase 7 tools. `kind: 'basic'` is the only kind so far; a future kind will need `SavedCalculation` and its repository to grow.
- Not yet committed as of this entry; see the "History module" entry below for the commit this built on top of.

---

## 2026-09-29: Phase 4 (History module)

The user approved Phase 4 ("phaes 4 start"). This entry covers the History half; see the entry above for saved calculations, built later the same day. Committed as `1604248`, after the user deleted a stray scaffold accidentally created inside `packages/calc_engine` this session (see "Notes").

### Added

- **History** (`lib/features/history/`): `HistoryEntry`, `HistoryRepository`, `SqfliteHistoryRepository` (over the existing `history` table, schema v1 — no migration needed), `HistoryNotifier` (`AsyncNotifier<List<HistoryEntry>>`), `HistoryContent` (search, the entry list, an empty state, a no-matches state, clear-all with confirmation). DEC-044 records what's stored and what reuse/copy do.
- `ExpressionBuffer.toCanonicalText()`: locale-neutral display text for a history entry, never re-parsed.
- `CalculatorModeStorage`: a fixed-string storage id for `CalculatorMode` (the same convention `ThemePreference` uses).
- `CalculatorNotifier.useHistoryResult`: inserts a history entry's exact result at the cursor, the same way MR inserts the memory.
- `AppDatabase.open` gained an optional `singleInstance` parameter (default `true`; tests pass `false` for isolation). `AppRoot` gained an optional `overrides` parameter. Both are test-infrastructure additions; DEC-045 explains why.

### Changed

- **`CalculatorNotifier._evaluate()`:** every successful `=` now also adds a history entry (not on an error).
- **`HistoryPage` and `HistoryPanel`:** now show `HistoryContent` instead of the Phase 1 placeholder. `HistoryPlaceholder` removed.
- **`test/helpers/test_app.dart`:** `pumpApp` now gives every widget test an isolated in-memory database.
- **Dependencies:** added `riverpod` ^3.4.3 directly (DEC-045; already resolved transitively through `flutter_riverpod`).

### Fixed

Found while building this module, before anything was committed:

- **Test hang / wrong-container error:** wrapping `AppRoot` in a second `ProviderScope` to add a database override broke `AppRoot`'s own `sharedPreferencesProvider` override, because Riverpod resolves unscoped providers at the app's one root scope, not the nearest ancestor with an override. Fixed via `AppRoot.overrides` instead of a wrapping scope.
- **Cross-test data leakage:** every test in `calculator_notifier_test.dart` was sharing one in-memory database, because sqflite caches a database by path unless `singleInstance: false` is passed. Fixed by adding that option to `AppDatabase.open` and using it in every test that opens more than one in-memory database per process.
- **Test hang on clipboard copy:** `Clipboard.setData`/`getData` never resolve in the test environment without a mock `SystemChannels.platform` handler (the existing paste tests in `calculator_view_test.dart` already needed this; the new copy tests needed the same fix).

### Tests

- **27 new tests**, all passing: `test/features/history/data/sqflite_history_repository_test.dart` (9), `test/features/history/application/history_notifier_test.dart` (5), `test/features/history/presentation/history_content_test.dart` (10), `test/features/calculator/domain/expression_buffer_test.dart` (+3, `toCanonicalText`), `test/features/calculator/application/calculator_notifier_test.dart` (+5, writing and reusing history).
- **`flutter analyze`:** no issues.
- **`flutter test` (whole suite):** 438 passed, 1 skipped, 1 failed at first — the failure was `layer_boundaries_test.dart`, caused entirely by an unrelated environmental accident (see "Notes"), not by anything in this entry. Clean (464 passed, 1 skipped, 0 failed — the higher count includes the saved-calculations entry above) once the user removed the stray files.
- **`dart test`, `packages/calc_engine`:** 260 passed, unchanged (the engine wasn't touched).
- **`flutter build apk --debug`:** built successfully despite the stray scaffold below (nothing imports `packages/calc_engine/lib/main.dart`, so it doesn't affect the build). Installed on the user's phone (`23124RN87I`, Android 15) at the user's request and tested directly: computing results, viewing history, copy, delete, reuse (loads the exact result back into the calculator and returns), search, clear-all (cancel and confirm), the empty state, and confirming a division-by-zero error does **not** get logged. Every check passed. A memory (MR) regression check confirmed History didn't disturb the existing memory feature. Full detail in DEVELOPMENT_STATUS.md, "Test on the user's phone."

### Notes

- **An accident, reported rather than worked around, now resolved:** at some point this session, a full `flutter create`-style scaffold appeared inside `packages/calc_engine/` — `lib/main.dart` (imports `package:flutter/material.dart`), `android/`, `.metadata`, `analysis_options.yaml`, `.gitignore`, `.idea/`, `calc_engine.iml`, all untracked, all created within the same second. The triggering command isn't confirmed with certainty. Confirmed **unaffected**: `packages/calc_engine/pubspec.yaml` (`git diff` empty) and every real engine source file (all 260 engine tests still pass). Claude tried to delete the stray files; the sandbox's safety layer correctly refused a destructive operation on a directory. The user deleted them ("okay delete"); see DEVELOPMENT_STATUS.md's Known Issues #13.
- **Not built, by decision (DEC-044):** history grouping (Today/Yesterday/earlier), paging, swipe-to-delete with Undo, a result "tape," a retention limit — all `(Proposed)` in ROADMAP.md, not required by Phase 4's "Done when" gate.

---

## 2026-09-28: Phase 3 final audit

A strict, code-level audit requested by the user before approving Phase 4. No feature code changed; the input system was not redesigned, per the user's instruction.

### Added

- Two regression tests in `test/features/calculator/domain/expression_buffer_test.dart` ("editing at the cursor"): `5+3LL×` → `5×|+3`, and `5%L×` → `5×|%`.
- Two regression tests in `test/features/calculator/application/calculator_notifier_test.dart` (new group "editing in the middle"): confirm that editing an operator in before an existing one can either silently reinterpret the expression as a valid one (`5×+3` = 15, since unary `+` is a no-op) or produce a genuine, safely-handled syntax error (`5×%`).

### Fixed

- **Documentation error found during the audit:** `DEVELOPMENT_STATUS.md`'s "Calculator limitations" known issue claimed editing `5+3` into `5×+3` always shows "Invalid expression". Verified by direct engine evaluation that `5×+3` is actually valid input (unary `+` is a no-op) and evaluates to `15`; the claim was wrong. Corrected, with a verified example (`5×%`) of the genuine error case, and both paths now have regression tests.

### Tests

- `flutter analyze`: no issues. `dart format --set-exit-if-changed lib test packages`: 104 files, 0 changed.
- `dart test` (`packages/calc_engine`): 260 passed (unchanged; the engine wasn't touched).
- `flutter test`: **408 passed**, 1 skipped (up from 404; the 4 new tests above).
- `flutter build apk --debug`: built (Gradle `assembleDebug`, 26.4 s).
- Verified by direct evaluation (`CalcEngine().evaluate(...)`, via a scratch script deleted after use): `0.1+0.2−0.3` = 0, `(1÷3)×3` = 1, `6÷2(1+2)` = 9, `5×+3` = 15, `5×%` → syntax error.
- Re-read `android/app/src/main/AndroidManifest.xml` (the release manifest): still no `INTERNET` permission.
- Re-read `test/architecture/layer_boundaries_test.dart` and `packages/calc_engine/pubspec.yaml`: the engine still declares and imports no Flutter dependency.

### Notes

- Judged acceptable for Phase 3, per the user's explicit instruction not to redesign without a genuine correctness or safety issue: invalid-expression editing in general (every reachable case fails safely or evaluates to a mathematically correct result), the absence of touch copy/paste (Ctrl+V still works via a hardware keyboard), and always-on haptics (no setting exists before Phase 10).
- Confirmed, not just re-stated: repeated `=` is a no-op (doesn't repeat the last operation); the memory survives a restart exactly; regional number grouping (including India's 12,34,567 pattern) comes from `intl`'s locale data, not a hardcoded rule; the landscape-key-height and memory-badge-semantics fixes from the Phase 3 session are each covered by an automated test, not only the original manual device test.
- Docs updated: this file, `DEVELOPMENT_STATUS.md`, `ARCHITECTURE.md` (test counts). `PROJECT_MEMORY.md`, `DECISIONS.md` and `ROADMAP.md` needed no changes — nothing they claim was contradicted by the code.

---

## 2026-09-28: Phase 3 (Basic calculator)

### Added

- **Engine** (`packages/calc_engine`, commit `4fec0b6`): exact evaluation with `rational` (DEC-038). It has a lexer, a recursive-descent parser, a syntax tree and an evaluator, with smart percent (DEC-036), implied multiplication, typed errors, overflow at 10¹⁰⁰, and nesting and token limits (DEC-039). Results use 12 significant digits and switch to scientific notation from 10¹² and below 10⁻⁶.
- **Calculator logic** (commit `57a1e73`):
  - `ExpressionBuffer`: units with a cursor and the input rules (DEC-040)
  - `CalculatorNotifier`: live value, `=`, continuing from the exact result, errors, cursor moves, paste
  - memory (MC MR M+ M− MS), saved exactly under `calculator.memory` (DEC-041)
  - `LocalizedNumberFormat` and `numberFormatProvider`: numbers in the device region's format (DEC-037)
- **Calculator screen** (commit `85c6c84`):
  - `CalculatorView` with portrait and landscape layouts (DEC-042) and hardware keyboard support
  - `CalculatorDisplay`, `CalculatorKeypad`, `CalculatorMemoryKeys` and `CalculatorDisplayFormatter` (DEC-043)
  - haptic ticks on key presses; hold ⌫ to clear everything
- **Components:** `DisplayText`, and `CalculatorButtonKind.memory` (DEC-043). The gallery has a new "Display text" section and a memory row in the keys section.
- **Strings:** 37 new, for key labels, what screen readers say, and the error messages (55 in all).

### Changed

- **Basic mode** shows the calculator instead of the empty state.
- **Shell:** an expanded window shorter than 480 dp (a phone in landscape) shows no history panel; the history action opens the page instead (DEC-042).
- **App dependencies:** `calc_engine` (path). **Engine dependencies:** `rational` ^2.2.3; dev `test` ^1.31.1.
- **Design-review screenshots:** 17 more (15 calculator screens, and the gallery's display section in light and dark), 50 in all.

### Fixed

Found during this phase, before the commits:

- **Screenshots:** a long expression broke inside a number. It now wraps only after an operator.
- **Screenshots:** the tablet-landscape keypad floated in the middle. It is now aligned to the bottom.
- **On the user's phone, in landscape:** keys were 47.6 dp tall under the 34 dp status bar. Tighter vertical padding in short windows makes them 49 dp. A regression test covers it.
- **On the user's phone:** the memory badge's screen-reader label was attached to the whole screen. It is now its own node.

### Decisions

- DEC-036 (smart percent) and DEC-037 (region number format) are implemented.
- New: DEC-038 to DEC-043. DEC-008, DEC-010 and DEC-022 are updated.

### Tests

- **Engine** (`dart test` in `packages/calc_engine`): **260 passed.** That is 224 table-driven cases, `CalcValue` tests, and a 20,000-input fuzz test. Mutation checks: plain percent caused 13 failures, and truncating instead of rounding caused 10. Both were restored.
- **App** (`flutter test`): **404 passed**, 1 skipped (the design-review generator). There are 292 new tests:
  - expression buffer 138, notifier and memory 59, number format 33
  - `DisplayText` 12, display formatter 18, screen 24
  - `CalculatorButton` +2, app +1, shell +1, gallery accessibility +4
- **Mutation checks** on the new tests, all caught and then restored: leading-zero rule, closing-bracket rule, bracketed variables, incomplete-error mapping, rejected-key handling, Indian grouping. The landscape regression test fails with the old padding.
- **`flutter analyze`:** no issues. **Formatting:** 104 files, 0 changed.
- **Design review:** 50 screenshots generated and reviewed.
- **Builds:** `flutter build apk --debug` built (85.9 s). `flutter build apk --release` built, 46.6 MB. `aapt`: package `com.parasshakya.smartcalculator`, label "Smart Calculator", **no INTERNET permission**.
- **On the user's phone** (`23124RN87I`, Android 15, 360×800 dp, region en-IN; release APK):
  - every key is exposed with its name
  - `1234567×8+90` shows `12,34,567×8+90`, preview `98,76,626`, then the result `98,76,626`
  - `50+10%` previews 55
  - MS, then `2×` MR shows `2×98,76,626` (preview `1,97,53,252`)
  - `5÷0=` shows "Can't divide by zero"
  - the memory survives a force-stop and relaunch
  - landscape: the keypad is beside the display
  - holding ⌫ clears the display
  - the rotation setting, changed for the landscape test, was restored (auto-rotate off, rotation 0). No other setting was changed.

### Notes

- **Not built in Phase 3:** the engine's function registry (there are no functions until Phase 5), and the roadmap's "more" menu (DEC-041).

---
## 2026-09-28: Test on the user's phone

### Added

- `AppChoiceGroup` / `AppChoice` (`lib/core/widgets/app_choice_group.dart`). It shows a segmented button when every label fits on one line, and a radio list otherwise (DEC-035).
- Tests:
  - `test/core/widgets/app_choice_group_test.dart` (4 tests, measured with the real font)
  - a settings regression test at 200% text on a 360 dp phone

### Changed

- **Settings page:** the theme control is an `AppChoiceGroup`, outside the list tile, so it gets the full content width.
- **Gallery:** the inputs section is renamed "Inputs and choices" and shows `AppChoiceGroup`.
- **Screenshot harness:** it paints sections on a `Material` instead of a `ColoredBox`.

### Fixed

- **Settings theme control at 200% system font on a 360 dp phone:** "System" was broken as "Syste/m". It was found on the user's phone and fixed in `950493b`.

### Tests

- **On the user's phone** (`23124RN87I`, Android 15, 360×800 dp; release APK installed with `adb`):
  - cold start 1126 ms (then 621–1080 ms)
  - launch screen, mode sheet, mode switch, history page and system back all correct
  - Dark survives a force-stop and relaunch
  - 200% font: the mode sheet uses 2 columns; the theme control bug above was found, then fixed and re-tested
  - landscape: rail layout, with scrolling
  - accessibility labels present in `uiautomator dump`
  - no errors in `logcat`
  - phone settings restored afterwards
- **`flutter analyze`:** no issues.
- **Formatting:** 72 files, 0 changed.
- **`flutter test`:** 112 passed.
- **Design-review screenshots:** 33 regenerated.
- **Mutation check:** without the `Material` wrapper, the coloured-background test fails.
- **`flutter build apk --release`:** built, 46.1 MB.

### Decisions

- DEC-035 was adopted.
- P-4 is resolved: the user's phone is used for device tests when it is connected and the user asks.

### Notes

- Phase 2 still awaits the user's design sign-off (P-11).
- Nothing was pushed (the user pushes to GitHub themselves).

---

## 2026-09-28: Phase 2 (Design system)

### Added

- **Design tokens** (`lib/app/theme/`):
  - `AppColors`: 27 roles; light "porcelain", dark "graphite", and high-contrast light and dark palettes
  - `AppTypography`: 11 styles, with tabular figures on the number styles
  - `AppRadius`: superellipse shapes
  - `AppMotion`: reduced-motion aware
  - `AppSpacing`: extended to xs–xxl
- **Themes:** `AppTheme` builds four themes and the Material component themes. `MaterialApp` gets `highContrastTheme`, `highContrastDarkTheme` and a theme-change animation.
- **Manrope font** (400/500/600/700, `googlefonts/manrope@6f81ebe`) in `assets/fonts/`, with its OFL, registered through `lib/app/font_licenses.dart`.
- **Reusable components** (`lib/core/widgets/`): `AppButton`, `AppIconButton`, `CalculatorButton`, `AppCard`, `AppBottomSheet`/`showAppBottomSheet`, `AppDialog`/`showConfirmationDialog`, `AppTextField`, `EmptyState`, `ErrorState`, `LoadingState`, `SectionHeader`, `AppHeader`.
- **Component gallery:** `lib/main_gallery.dart` and `lib/gallery/`.
- **Tests:**
  - palette contrast (WCAG)
  - theme, font and motion tests
  - component tests
  - Flutter accessibility guidelines over every gallery section in four themes
  - the design-review screenshot generator (tag `design-review`, skipped by default through `dart_test.yaml`)
  - helpers: `themed.dart`, `real_fonts.dart`

### Changed

- **Shell:**
  - The header uses `AppHeader` and `AppIconButton`.
  - The mode pill is an `AppButton`.
  - The mode sheet is a grid of `AppCard` tiles, with the current mode selected.
- **Placeholders:** the mode, history page and history panel placeholders use `EmptyState`.
- **Settings page:** uses `AppHeader` and `SectionHeader`.
- **Startup:** `main.dart` registers the font licences.
- **`pubspec.yaml`:** the fonts and the licence asset.
- **`CLAUDE.md`:** rule 12 (reusable widgets only) and rule 13 (Hinglish replies), plus the design-review commands.

### Removed

- `lib/core/widgets/placeholder_view.dart` (replaced by `EmptyState`).

### Fixed

Found in Claude's review of the screenshots, and fixed before the final set:

- **Mode sheet:**
  - Tiles were invisible on the white sheet. Sheets now use the page background.
  - "Programmer" broke mid-word. There is less tile padding, 2 columns from 115% text, and a one-line label.
- **Keys:** operator and `=` symbols looked faint. There is a new `keySymbol` style.
- **Text fields:** the floating label sat on the field's edge. Filled fields now use `UnderlineInputBorder` (DEC-031).
- **Buttons:** they were cramped at 200% text. Vertical padding added.

### Decisions

- The user approved Phase 2 and required reusable widgets (DEC-034).
- DEC-028 to DEC-033 were adopted:
  - DEC-028: the font; resolves P-8
  - DEC-029: the tokens
  - DEC-030: the consolidated components
  - DEC-031: the filled fields
  - DEC-032: the gallery entry point
  - DEC-033: the screenshot review
- New pending decision: P-11, the user's design sign-off.

### Tests

- **Font check:** `tnum` is present in all four Manrope weights.
- **Mutation check:** a low-contrast `textMuted` made the gallery contrast test fail. Restored.
- **`flutter analyze`:** no issues.
- **Formatting:** 70 files, 0 changed.
- **`flutter test`:** 107 passed, and 1 skipped (the screenshot generator).
- **Screenshot generator:** 33 passed; screenshots written to `build/design_review/`.
- **`flutter build apk --debug`:** built. **`--release`:** built, 45.7 MB, no INTERNET permission, fonts bundled.

### Notes

- **Phase 2 awaits the user's design sign-off.** Phase 3 has not started.
- **Commits:** `0fc15ef` (code), then the docs update.

---

## 2026-09-28: Phase 1 (Foundation)

### Added

- **Git repository** in `smart_calculator/` on `main`, with a `.gitattributes` file. Commits:
  - `8ca813c` baseline scaffold
  - `813533e` project-memory docs
  - `06c0a93` app identity
  - `7926920` Phase 1 foundation
  - then the docs update
- **Pub workspace**, with the empty pure-Dart package `packages/calc_engine` (`pubspec.yaml`, `lib/calc_engine.dart`, `README.md`).
- **Dependencies:**
  - app: `flutter_riverpod` 3.4.3, `shared_preferences` 2.5.5, `sqflite` 2.4.4, `path` 1.9.1, `intl` 0.20.3 (SDK-pinned), `flutter_localizations`
  - dev: `sqflite_common_ffi` 2.4.3, `shared_preferences_platform_interface` 2.4.2
- **Startup:** `main` preloads the preferences, then `AppRoot` builds a `ProviderScope` (with overrides, automatic retry off) around `SmartCalculatorApp`.
- **Typed navigation:** the sealed `AppRoute` (`/history`, `/settings`) and `context.pushRoute`.
- **Adaptive shell** with placeholder screens:
  - compact windows: the mode pill and mode sheet
  - medium windows: a navigation rail
  - expanded windows: the rail plus a history panel
  - no bottom navigation
- **Mode registry:** the `CalculatorMode` enum, with icons and translated names; the current mode is held in `currentModeProvider`.
- **Theme foundation:** light and dark themes from a provisional seed colour, provisional spacing, and a persisted system/light/dark choice on the settings page.
- **Persistence foundation:**
  - `SharedPreferencesWithCache` with the key allow-list `PreferenceKeys`
  - `SettingsRepository` and its preferences implementation
  - `AppDatabase` schema v1 (`history` and `saved_calculations`, with indexes) and its migration setup
  - `appDatabaseProvider`, which opens the database lazily
- **Localization:** `l10n.yaml`, `lib/l10n/app_en.arb` (18 strings, each with a description) and the generated `app_localizations*.dart`.
- **24 tests** in 8 files, plus `test/helpers/test_app.dart`.

### Changed

- **Android:** `namespace` and `applicationId` are now `com.parasshakya.smartcalculator`; `MainActivity` moved to the matching package; the label is "Smart Calculator".
- **iOS:** the bundle ID is `com.parasshakya.smartcalculator` (tests: `.RunnerTests`), and `CFBundleName` is "Smart Calculator".
- **`pubspec.yaml`:** the real description, the workspace, the dependencies, and `flutter: generate: true`. The template comments and `cupertino_icons` were removed.
- **`analysis_options.yaml`:** strict analyzer modes, 26 extra lint rules, and `depend_on_referenced_packages` raised to an error.
- **`lib/main.dart`:** the counter demo was replaced by the real startup.
- **`macos/Flutter/GeneratedPluginRegistrant.swift`:** regenerated by Flutter for the new plugins.
- **Docs:** ARCHITECTURE.md now describes the implemented state; DECISIONS.md, ROADMAP.md, DEVELOPMENT_STATUS.md, PROJECT_MEMORY.md and CLAUDE.md were updated.

### Removed

- `test/widget_test.dart`, the template counter test.

### Fixed

- **Android build across drives:** `kotlin.incremental=false` in `android/gradle.properties` (DEC-027). Without it, `compileDebugKotlin` and `compileReleaseKotlin` failed with "this and base files have different roots".
- **Kotlin session data:** `android/.gitignore` now ignores `/.kotlin/`, so the Kotlin 2.x session files stay out of Git.
- **DEC-015:** corrected the claim that every planned package was released within the past year (`path` 1.9.1 dates from 2024-10).

### Decisions

- The user approved Phase 1, which resolved P-1, P-2 and P-3.
- DEC-019 to DEC-027 were adopted during implementation:
  - DEC-019: the dependency set and deferrals
  - DEC-020: the lint configuration and boundary checks
  - DEC-021: the navigation and mode-state implementation
  - DEC-022: the shell breakpoints
  - DEC-023: the persistence details
  - DEC-024: the l10n setup
  - DEC-025: the identity scope
  - DEC-026: the Riverpod conventions
  - DEC-027: the Kotlin incremental setting
- New pending decisions: P-9 (Windows Developer Mode) and P-10 (the drives for the project and pub cache).

### Tests

- **`flutter analyze`:** no issues.
- **`dart format --set-exit-if-changed lib test packages`:** 41 files, 0 changed.
- **`flutter test`:** 24 passed.
- **`flutter build apk --debug`:** built. **`flutter build apk --release`:** built, 45.3 MB. This was after DEC-027; both failed before it.
- **`aapt`:** checked the package, label, SDK levels and permissions. The release build has no INTERNET permission.
- **Mutation check:** without its scroll wrapper, the rail made the phone-landscape test fail, as it should.
- **Not run:** the iOS build, running on a device, integration tests.

### Notes

- **Phase 1 is complete** and awaits the user's review. **Phase 2 has not started.**
- **Build quirks on this machine** (P-9): the first `flutter pub get` after a plugin change fails once (no symlink permission), and `dart format .` crashes on long paths under `build/`.

---

## 2026-09-28: Phase 0 and the project-memory system

### Added

- **The project-memory system (DEC-018):**
  - `CLAUDE.md` is the session entry point. It contains the Context Recovery Protocol, the Session Handoff Protocol and the accuracy rules.
  - `docs/PROJECT_MEMORY.md`, `docs/DEVELOPMENT_STATUS.md`, `docs/ARCHITECTURE.md`, `docs/DECISIONS.md`, `docs/ROADMAP.md` and `docs/CHANGELOG.md`.
- `../CLAUDE.md` (in the workspace folder `SmartCalculator/`, outside the planned Git repo): a pointer, so that sessions opened in the parent folder find this project's memory.

### Changed

- Nothing. No application code, configuration or dependencies changed.

### Fixed

- Nothing.

### Decisions

Phase 0 was an audit and planning phase, and the user approved its results.

- DEC-001: phased, approval-gated workflow
- DEC-002: framework Material, not `material_ui`
- DEC-003: plain Navigator with a typed route layer, not `go_router`
- DEC-004: Android and iOS are primary; the other platform folders are kept
- DEC-005: app ID `com.parasshakya.smartcalculator` and display name "Smart Calculator" (not applied yet)
- DEC-006: local Git, never pushed (not initialized yet)
- DEC-007: Riverpod 3 without code generation
- DEC-008: a pure-Dart `packages/calc_engine` with exact arithmetic
- DEC-009: `SharedPreferencesWithCache` and `sqflite`
- DEC-010: the 200+ engine-test gate
- DEC-011: the "quiet precision" UI direction
- DEC-012: no bottom navigation on phones
- DEC-013: shared basic and scientific state
- DEC-014: offline first and privacy first
- DEC-015: the dependency policy
- DEC-016: Phase 1 is foundation only
- DEC-017: roadmap adjustments
- DEC-018: the repository docs are the source of truth

### Tests

Run in `smart_calculator/` on the untouched template:

- `flutter analyze`: `No issues found! (ran in 26.7s)`
- `flutter test`: `+1: All tests passed!` (the template "Counter increments smoke test")

Phase 0 validation ran in a throwaway scratch project outside the repository. Those results support DEC-002, DEC-003, DEC-008, DEC-009 and DEC-015, but they are not tests of this repository:

- dependency resolution
- runtime smoke tests
- exact-arithmetic checks
- in-memory SQLite
- the pub workspace
- Android debug and release builds
- the go_router and APK-size comparison

### Notes

- Phase 0 (audit and architecture) is complete.
- **Phase 1 has not started and is not yet approved to start.**
- Git is not initialized yet, so this entry has no commit hash.
