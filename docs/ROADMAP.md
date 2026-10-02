# Roadmap

This file gives the intended development sequence. Every phase needs the user's **explicit approval before it starts**, and ends with a report followed by a stop (DEC-001). Current status is in [DEVELOPMENT_STATUS.md](DEVELOPMENT_STATUS.md).

- **Source:** the master prompt §30, adjusted by the approved plan (DEC-017).
- **Labels:** requirement text comes from the user's master prompt. Items marked *(proposed)* are Claude's design details that are not yet implemented.

## Sequence

```text
Phase 0  Audit & architecture ............ COMPLETED 2026-09-28
  —      Project-memory system ........... COMPLETED 2026-09-28
Phase 1  Foundation ...................... COMPLETED 2026-09-28
Phase 2  Design system ................... COMPLETED 2026-09-28 (design approved)
Phase 3  Basic calculator + engine + memory COMPLETED 2026-09-28, audited 2026-09-28
Phase 4  History + saved calculations .... COMPLETED 2026-09-29 (both halves; phone-tested)
Phase 5  Scientific ...................... COMPLETED 2026-09-30 (all 3 modules built, audited, phone-tested)
Phase 6  Converters ...................... COMPLETED 2026-09-30
Phase 7  Financial ....................... COMPLETED 2026-10-01, phone-tested
Phase 8  Date calculator ................. COMPLETED 2026-10-01, phone-tested
Phase 9  Programmer calculator ........... COMPLETED 2026-10-01, phone-tested
Phase 10 Settings screen ................. COMPLETED 2026-10-02, phone-tested
Phase 11 Polish .......................... planned
Phase 12 QA .............................. planned
```

**Exit gate for every phase:**

1. `flutter analyze` finds no issues.
2. Formatting passes: `dart format --set-exit-if-changed lib test packages`. Don't run `dart format .`; see CLAUDE.md.
3. All tests pass. Record the actual command output.
4. The Android build passes.
5. The UI has been reviewed in light and dark, on small and large screens (from Phase 2 on). Use the design-review screenshots (`flutter test --tags design-review --run-skipped --update-goldens`, DEC-033).
6. The docs are updated (Session Handoff Protocol).
7. Local commits have been made.
8. The report has been delivered to the user, and work stops.

---

## Completed

### Phase 0: Project audit and architecture (2026-09-28)

- Audited the template project. Planned the architecture, dependencies, UI/UX and implementation.
- Validated the key choices in a scratch project.
- Delivered the Final Architecture Decision Report, which the user approved (DEC-001 to DEC-017).
- No project files changed.

### Project-memory system (2026-09-28)

- Created `CLAUDE.md` and `docs/` (DEC-018).

### Phase 1: Foundation (2026-09-28)

The user approved it on 2026-09-28. It was built exactly to the approved scope (DEC-016), and it awaits the user's review. What was built is described in [ARCHITECTURE.md](ARCHITECTURE.md) §1.

| # | Scope item | Result |
| --- | --- | --- |
| 1 | Git setup | Done. Repository on `main`, with `.gitattributes`; the baseline scaffold and docs are separate commits (DEC-006). |
| 2 | Dependencies | Done. Each was re-verified first; `cupertino_icons` was removed. The engine's dependencies are deferred to Phase 3 (DEC-019). |
| 3 | Strict lint rules | Done (DEC-020) |
| 4 | Pub workspace | Done (`workspace: [packages/calc_engine]`) |
| 5 | Empty calculation-engine package | Done: skeleton only |
| 6 | Folder structure | Done for the folders Phase 1 uses. No empty placeholder folders (DEC-019). |
| 7 | Startup architecture | Done (preferences preloaded, then `AppRoot`) |
| 8 | Typed route layer over plain Navigator | Done (DEC-021) |
| 9 | Adaptive shell with placeholder screens | Done (DEC-022) |
| 10 | Basic theme structure | Done (provisional seed colour and spacing) |
| 11 | Light/dark/system choice, persisted | Done; a test covers a restart |
| 12 | Settings storage | Done (`SharedPreferencesWithCache`) |
| 13 | Database v1 | Done (schema v1 and migration setup; DEC-023) |
| 14 | Translation (l10n) setup | Done (DEC-024) |
| 15 | `docs/ARCHITECTURE.md` | Updated to the implemented state |
| 16 | Replace the default counter test | Done. 24 foundation tests. |
| 17 | Format, analyze, test | Done; results in DEVELOPMENT_STATUS.md |
| 18 | Local Git commits | Done; nothing pushed |
| — | App ID and display name | Done on Android and iOS; the user approved including it (DEC-025) |

**Build fix outside the original scope:** `kotlin.incremental=false` (DEC-027). The Android build failed without it on this machine.

### Phase 2: Design system (2026-09-28; design approved by the user)

The user approved the phase and, on 2026-09-28, the design review (P-11 resolved). The code is in commit `0fc15ef`, and ARCHITECTURE.md §1.7–1.9 describes it.

| Scope item | Result |
| --- | --- |
| Colour tokens (incl. operator and number keys), light/dark/system, high contrast, contrast checked | Done: `AppColors`, 27 roles, 4 palettes, WCAG tests (DEC-029) |
| Typography tokens | Done: `AppTypography`, 11 styles (display, result, expression, key, keySymbol, heading, title, body, caption, button, label) |
| Spacing (xs to xxl), radius, motion | Done: `AppSpacing`, `AppRadius` (superellipse), `AppMotion` (reduced motion) |
| Bundled fonts with tabular digits (P-8) | Done: Manrope, `tnum` verified (DEC-028) |
| AppButton, PrimaryButton, SecondaryButton | Done as one `AppButton` with variants (DEC-030) |
| AppIconButton | Done; the tooltip is required |
| CalculatorButton, OperatorButton | Done as one `CalculatorButton` with kinds (DEC-030) |
| AppCard, AppBottomSheet, AppDialog, AppTextField | Done (`showAppBottomSheet`, `showConfirmationDialog`) |
| EmptyState, ErrorState, SectionHeader, AppHeader | Done, plus `LoadingState` |
| `AppBottomNavigation` | Dropped (DEC-012) |
| Replace the Phase 1 stand-ins | Done: `PlaceholderView` removed, section header, provisional seed and spacing, the mode sheet as a grid |
| Debug-only gallery | Done: `lib/main_gallery.dart` (DEC-032) |
| Review in light and dark at 200% text | Done by Claude on 33 generated screenshots (DEC-033), with 4 issues fixed. Tested on the user's phone, where 1 more issue was found and fixed (DEC-035). **Signed off by the user.** |

### Phase 3: Basic calculator (implemented and audited 2026-09-28)

The user approved it on 2026-09-28 ("phase 2 approv and start phase 3"), and chose smart percent (DEC-036) and the region number format (DEC-037). The code is in commits `4fec0b6`, `57a1e73` and `85c6c84`; ARCHITECTURE.md §1.12–1.13 describes it. A strict code-level audit (2026-09-28) found one documentation error (corrected) and no code bugs; see DEVELOPMENT_STATUS.md's "Phase 3 Audit". **Complete**, and the user approved Phase 4 on 2026-09-29.

| Scope item | Result |
| --- | --- |
| Engine dependencies, re-verified (DEC-019) | `rational` ^2.2.3 and dev `test` ^1.31.1. `decimal` not added (DEC-038). |
| Default behaviours (P-6) | Percent settled (DEC-036); the rest (powers and trigonometry) implemented in Phase 5, DEC-047 |
| Precedence, parentheses, decimals, negatives, percent | Done (DEC-039) |
| Exact arithmetic instead of floating point | Done: exact fractions; `0.1+0.2−0.3` = 0, `1÷3×3` = 1 |
| Invalid expressions and division by zero | Done: typed errors with translated messages |
| Very large and very small numbers | Done: 12 significant digits, scientific notation, overflow at 10¹⁰⁰ |
| An extensible function registry | **Not built.** There are no functions until Phase 5; it moves there (ARCHITECTURE.md §3.3). |
| Header: mode, history, settings, a "more" menu | Mode, history and settings. **No "more" menu**: it would be empty (DEC-041). |
| Expression area: current and previous expression, result, cursor, clear/delete | Done (DEC-043) |
| Keypad from `CalculatorButton` | Done: AC ( ) % ÷ / 7 8 9 × / 4 5 6 − / 1 2 3 + / 0 . ⌫ = |
| Memory MC, MR, M+, M−, MS, independent of the UI | Done; saved exactly, survives restarts (DEC-041) |
| Error handling, animations, haptics, keyboard | Done (DEC-040, DEC-043; `CalculatorView`) |
| Phone-landscape layout (DEC-022) | Decided and built (DEC-042) |
| *(Proposed)* token editing with a cursor, live preview, smart `( )`, hold ⌫ | Done (DEC-040) |
| **Done when:** more than 200 engine edge-case tests pass | **260 pass** |
| **Done when:** keypad and display widget tests pass | Pass (404 app tests in all) |
| Review | 50 screenshots reviewed (2 layout fixes); tested on the user's phone (2 more fixes) |

---

### Phase 4: History and saved calculations (complete, 2026-09-29)

The user approved Phase 4 on 2026-09-29. ARCHITECTURE.md §1.17 (history) and §1.18 (saved calculations) describe it; DEC-044, DEC-045 and DEC-046 record the decisions. Phone-tested on the user's device: computing, viewing, search, copy, delete, reuse, clear-all (cancel and confirm), the empty states, saving a history entry, renaming a saved one, and reusing it.

- **Start by** confirming the v1 table columns (DEC-023) before anything writes to them. **Done:** the existing schema (`expression`, `result`, `mode`, `created_at`; `name`, `kind`, `inputs_json`, `created_at`, `updated_at`) fit both features without a migration; see DEC-044 and DEC-046 for what each column holds.
- **History:**
  - Each item stores the expression, result, timestamp and mode. **Done.**
  - View, search, reuse, copy, delete an item, clear all. **Done** (DEC-044): reuse inserts the exact result, like MR; delete is a button, not swipe.
  - An empty state, and confirmation before destructive actions. **Done**: two empty states (no history; a search with no matches), and `showConfirmationDialog` before Clear all.
  - It persists locally. The history panel and page replace their Phase 1 placeholders. **Done.**
- **Saved calculations:** save, rename, edit, reuse and delete. The master prompt's examples: mortgage, BMI, tax, monthly budget. **Done**, for the one calculator that exists (Basic): a History/Saved tab toggle inside the same screen, saving triggered from a history entry rather than the calculator screen (DEC-046, the user's UI decision delegated to Claude — "jaisa tum karo, waha karo"). "Rename" covers "edit" for now, since a basic saved calculation has no other input to change. The master prompt's example *tools* (mortgage, BMI, tax) don't exist until Phase 7 (see "Deferred" below); saving one of those will need `SavedCalculation` to grow beyond `kind: 'basic'`.
- *(Proposed, not built, deferred by decision — DEC-044)*:
  - grouping by Today, Yesterday and earlier; paging
  - swipe-to-delete with Undo (a labelled delete button was used instead, for discoverability and easier accessibility)
  - a result "tape" on the calculator display
  - ~~a retention limit and an off switch~~ built in Phase 10 (DEC-055)
- **Done when:** the storage tests and widget tests pass. **Done** — `test/features/history/` and `test/features/saved_calculations/` (repository, notifier, widget, 48 tests together) plus the engine-side `ExpressionBuffer.toCanonicalText` tests, all passing; verified again on the user's phone.

---

### Phase 5: Scientific (complete, 2026-09-30; phone-tested)

The user approved Phase 5 on 2026-09-29 ("phase 5 start"). ARCHITECTURE.md §1.12–1.13 describe the engine, input logic and keypad; DEC-047 records the engine decisions (Module 1, `ef7b0ba`, including the now-resolved deviation), DEC-048 the input-logic decisions (Module 2, `856d175`, built by a separate concurrent session), DEC-049 the user's formal, by-name confirmation of the five P-6 defaults plus the Module 2 audit and the orphaned-`×` fix, and DEC-050 the scientific keypad (Module 3) — built from a detailed plan the user reviewed and approved before any code was written.

| Scope item | Result |
| --- | --- |
| Functions: sin, cos, tan, asin, acos, atan, sinh, cosh, tanh, log, ln, sqrt, cbrt, abs | **Done**, engine and keypad (grouped into the scientific tray, DEC-050) |
| x², xʸ | **Done.** xʸ via the general `^` operator; x² (and x³) is a dedicated 2nd-of-√/∛ tray key, via a new composite `ExpressionBuffer` insert (DEC-050) — not just "insert `^2`" as originally sketched, since that alone silently breaks in a few positions (DEC-050's insert methods). |
| 10ˣ, eˣ | **Done** — dedicated 2nd-of-log/ln tray keys, each a small atomic `ExpressionBuffer` insert (DEC-050), not achieved via literal text insertion as first proposed. |
| factorial, absolute value | **Done**, engine and keypad: `!` postfix operator, `abs` function, both in the tray's "Other" group |
| π, e, brackets | **Done** (engine): always the constants, never a variable (DEC-047); π/e are keypad tray keys too |
| degree/radian mode | **Done end to end**: `AngleMode`; `angleModeProvider`, saved under `settings.angle_mode` (DEC-048); a compact DEG/RAD toggle key on the scientific screen (DEC-050) |
| Engine: an extensible function registry | **Done** — `CalcFunction` enum + a name→function lookup map in the parser; adding a function needs no grammar changes, just a new enum case and evaluator branch. |
| Engine: approximate values for irrational results | **Done** — `CalcValue` is now a sealed exact/approximate hierarchy (DEC-047) |
| Engine: the remaining P-6 defaults (`−3²`, `2^3^2`, `0^0`, `(−8)^(1/3)`, `tan 90°`) | **Implemented** (DEC-047) and **formally, explicitly approved by the user by name**, binding across future phases too (DEC-049) |
| Keypad: a clean scientific keypad, sharing state with Basic (DEC-013) | **Done** (Module 3, DEC-050): a horizontally-scrollable, grouped function tray, reusing Basic's display/memory row/keypad unchanged, in both portrait and landscape |
| Calculator input logic: buffer support for `^`/`!`/function calls, angle-mode state | **Done, audited, and one bug fixed** (Module 2, DEC-048 + DEC-049): keys, input rules, persisted angle mode, robust handling of wrong input (21-case error table, 2 fuzz tests), backspacing a constant/function/value never leaves a stranded `×`. |
| A 2nd/inverse toggle | **Done** (DEC-050): 7 engine-backed pairs (sin↔asin, cos↔acos, tan↔atan, sqrt↔square, cbrt↔cube, log↔powerOfTen, ln↔powerOfE); the other tray keys have no 2nd role, since the engine has no inverse-hyperbolic functions or nCr/nPr to map to — nothing was invented to fill that gap |
| *(Proposed)* a scientific tray pulled up from an "fx" handle | Not built; a single always-visible scrollable row was built instead as the smaller first pass (DEC-050). Could still happen later as a presentation-only refinement. |
| **Done when:** tests cover the edge cases of every function | **Done** — 387 engine tests, 645 app tests, phone-tested (mode switching, every function group, both toggles, the composite keys, both layouts). |

**Found along the way, not part of this phase's scope:** a pre-existing Basic-calculator touch-target gap (`CalculatorMemoryKeys` narrows below 48 dp in landscape at 200% text) — reported, not fixed, since it belongs to the already-approved Basic screen (DEC-050, DEVELOPMENT_STATUS.md Known Issues).

### Phase 6: Converters — COMPLETED 2026-09-30

A modular conversion system where new categories are easy to add: every category is a `const ConversionCategory` (a list of units, each just `(id, symbol, scale, offset)`) over one shared affine transform, so a new category is new data, not new code (DEC-051).

| Category | Units |
| --- | --- |
| Length | m, km, cm, mm, mile, yard, foot, inch |
| Weight | kg, g, mg, lb, oz |
| Temperature | °C, °F, K |
| Area | m², km², ft², acre, hectare |
| Volume | L, mL, gallon (US), m³ |
| Time | s, min, h, day, week |
| Currency | USD, INR, EUR, GBP — user-editable rate, persisted locally, never fetched |

- **Currency:** built as a real, working category (not a placeholder) — a short, curated list, USD the fixed base, every other rate typed in and persisted locally. No network call anywhere, matching the app's no-`INTERNET`-permission build (DEC-051).
- **Resolved:** US gallon, not imperial — id `gallonUs`, labeled "(US)" (DEC-051).
- *(Proposed, all built):*
  - category chips (an `AppCard` grid), and From and To cards with a swap button
  - an in-app number pad (`ConverterKeypad`, built directly from `CalculatorButton`)
  - an "all units" list (the searchable unit-picker sheet, mirroring `history_content.dart`'s own search pattern)
- **Done when:** round-trip conversion tests pass. **Done** — fixed-point temperature checks, exact integer cross-checks (mile/ft/yd, acre/ft², US gallon/in³, hour/s, …), per-unit and full pairwise round-trip tests across every category, all with a combined absolute+relative floating-point tolerance.

### Phase 7: Financial — COMPLETED 2026-10-01

Seven independent calculators — EMI, simple interest, compound interest, GST, discount, tip, percentage — each a small, pure, independently-tested domain function, unified only at the presentation layer by a tool picker (DEC-052).

- **Tools:**
  - EMI: inputs are loan amount, interest rate and tenure; outputs are the monthly EMI, total interest and total payment. **Done** — verified to the cent against a commonly published reference example (₹100,000 at 10% for 12 months → EMI ₹8,791.59).
  - simple interest and compound interest. **Done** — compound interest's compounding frequency (annual/semi-annual/quarterly/monthly) is a required, user-selectable choice, never hardcoded.
  - GST: percentage, inclusive or exclusive, CGST/SGST/IGST. **Done** — CGST/SGST/IGST is a presentation split over one computed GST amount (never a different total), toggled by an intra-state/inter-state choice.
  - discount, tip and percentage. **Done** — percentage is one flexible tool with three operations ("X% of Y", "X is what % of Y", "increase/decrease Y by X%"), reasoned as the roadmap's own lighter, grouped sibling to discount/tip rather than a request for separate full calculators.
- Charts where they genuinely help understanding. **Done**, via one reusable `ShareOfWholeBar` (a proportional bar, not a donut — a 2-segment donut is a documented anti-pattern for this exact data shape), used for EMI's principal/interest split and GST's base/GST split.
- *(Proposed)* "results update as you type": **done** — every tool recomputes live on each keystroke (no "Calculate" button), which turned out to be zero extra work given the chosen state shape (a `ListenableBuilder` over plain `TextEditingController`s), not an added feature.
- *(Proposed, not built):*
  - sliders for rate and tenure — every input is a plain text field instead, matching the gallery's own existing loan-amount/interest-rate precedent
  - an EMI donut chart (replaced by the bar, above) and amortization chart, and a compound-interest growth chart (custom painted) — different, higher-effort chart forms; the mandatory "charts where they help" bar is already met
  - save and reuse
- **Done when:** results match published reference values. **Done** — every formula independently re-derived and checked against known reference values twice (once during planning, once during an independent adversarial review), plus verified end to end on the user's phone.

### Phase 8: Date calculator — COMPLETED 2026-10-01 (DEC-053), phone-tested

- **Date difference** in days, weeks, months and years.
- **Add or subtract** (for example, +90 days or −6 months).
- No time-zone bugs.
- *(Proposed):* calendar-date arithmetic in UTC, with add-month clamping to the month end.
- **Done when:** tests pass for leap years, month ends and daylight-saving dates. **Done** — 1429 app tests pass, including leap-year, month-end, negative-month, range-limit and daylight-saving-date cases and property tests that the difference and add tools agree. Phone-tested too (both tools, the month-end case, landscape with the keyboard open); one UX gap found, not fixed (Known Issues #17).

### Phase 9: Programmer calculator — COMPLETED 2026-10-01 (DEC-054), phone-tested

- **Bases:** BIN, OCT, DEC and HEX, with easy conversion between them. **Done** — the number shows in all four bases at once; tapping a row selects the base it is typed in.
- **Operations:** AND, OR, XOR, NOT, shift left and shift right. **Done**, plus `+ − × ÷` and `±` as supporting operations (overflow cannot be shown without arithmetic). Execution is immediate and left to right, with no precedence (DEC-054).
- *(Proposed):*
  - word size and signed/unsigned selectors. **Done** — 8/16/32/64 bits, signed (two's complement) or unsigned, chosen in two sheets; defaults 32-bit signed.
  - a tappable bit grid. **Not built** (DEC-054, optional). The binary row shows every bit of the word, zero-padded, in a monospaced font.
  - digits that are invalid in the current base are disabled, and screen readers announce them as disabled. **Done** — also disabled once a number would no longer fit the word.
- **Also built, supporting:** an overflow notice (arithmetic wraps and says so), division by zero, the bundled JetBrains Mono (DEC-028 had scheduled it for this phase).
- **Not built, by decision (DEC-054):** rotations, NAND/NOR, modulo, byte swap, a separate shift-type selector, precedence and brackets, history/saved/memory integration, persistence, hardware-keyboard and paste input.
- **Done when:** the two's complement and overflow tests pass. **Done** — 446 engine tests (59 new) check every operation against Dart's typed-data lists and native `int` operations as an independent oracle, plus hand-computed reference tables; 1552 app tests; phone-tested (every base, signed and unsigned, 8 and 64 bits, shifts, overflow, divide by zero, portrait, landscape, 200% text, rotation).

### Phase 10: Settings screen — COMPLETED 2026-10-02 (DEC-055), phone-tested

- **Appearance:** light, dark or system. **Done** (the Phase 1 choice, now one section of the full screen).
- **Calculator:** default mode, haptics, sound, decimal precision, angle mode. **Done** — *opens in* (applies at the next start), haptic feedback, **key sounds** (the calculator keys' click; it follows the device's touch-sounds setting), **decimal places** (Auto, 2, 4, 6, 8: only the fraction of Basic and Scientific results is rounded), angle unit.
- **History:** history settings, clear history. **Done** — Save history on or off, keep the latest 50 / 100 / 500 / all (default all), Clear history with a confirmation.
- **Accessibility:** larger buttons, text scaling, high contrast. **Done** — text size 100 / 115 / 130% on top of the device's, **larger controls** (x1.25 on buttons and fixed-height rows; the Basic and Scientific key grids already fill the screen and do not change), high contrast.
- **About:** app version (P-7), developer information (the content must come from the user), privacy information and licenses. **Done, except developer information**: the version (a constant checked against `pubspec.yaml`; P-7 resolved, `package_info_plus` rejected), a factual privacy summary (checked by tests; not a legal policy), and the open-source licences page. **Developer information is not shown: the user said not now** (the content has to come from the user).
- **Not built, by decision (DEC-055):** developer information; a legal privacy policy or a link to one; language choice; per-mode angle defaults; haptic strength; sound choices; accent colours; backup or export.
- **Done when:** the widget tests pass. **Done** — 1681 app and 459 engine tests (DEVELOPMENT_STATUS.md, "Tests"); phone-tested (every section, portrait and landscape, the accessibility switches, the default mode across a restart, the history off state, the licences page). Not judged on the device: the key click and vibration themselves, and the Settings page at 200% device text (widget tests only).

### Phase 11: Polish

- App icon, splash screen, motion, and screen-reader passes.
- Tablet and dark-mode passes.
- **Done when:** the master prompt's §29 UI checklist passes:
  - alignment, spacing, typography, button sizing, icon consistency
  - colours, contrast, radius, shadows
  - responsive behaviour, dark mode
  - empty, error and loading states
  - accessibility

### Phase 12: QA

- End-to-end (integration) tests.
- A release build and an app-size check.
- A check for unnecessary rebuilds.
- The final audit from master prompt §37: architecture, UI, UX, performance, security, accessibility, testing, maintainability and scalability.

---

## Deferred

| Item | Why it's deferred | Revisit when |
| --- | --- | --- |
| Live currency rates (network) | Offline and privacy first; needs `http` and a service design | The user asks for live rates |
| `go_router` / deep links | DEC-003 | Deep links or web become requirements |
| Web and desktop as supported targets, and their identifiers | DEC-004, DEC-025 | The user asks |
| `drift` | Only needed for web | Web becomes a target |
| ~~`package_info_plus`~~ | Rejected (P-7 resolved, DEC-055) | — |
| iOS build verification | No Mac (P-5) | A Mac is available |
| Extra saved-calculation tools (BMI, tax, monthly budget) | Examples in the master prompt; not in any phase's scope | After Phase 7, if the user wants them |

## Not Yet Scheduled

These need a phase assignment from the user:

| Item | Notes |
| --- | --- |
| Android predictive back gesture | The final report said it would be enabled, but it isn't in any phase's scope |
| Release signing configuration | The template signs release builds with the debug key; this must be fixed before any release build is distributed |
| Persisting the last-used mode | In the persistence plan, but not in the Phase 1 scope (DEC-021). Relates to the Phase 10 "default mode" setting. |
| Project `README.md` | Still the `flutter create` template text |
