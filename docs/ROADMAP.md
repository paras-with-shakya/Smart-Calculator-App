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
Phase 5  Scientific ...................... in progress (engine module done 2026-09-29, not committed; keypad and input logic not started)
Phase 6  Converters ...................... planned
Phase 7  Financial ....................... planned
Phase 8  Date calculator ................. planned
Phase 9  Programmer calculator ........... planned
Phase 10 Settings screen ................. planned
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
  - a retention limit and an off switch
- **Done when:** the storage tests and widget tests pass. **Done** — `test/features/history/` and `test/features/saved_calculations/` (repository, notifier, widget, 48 tests together) plus the engine-side `ExpressionBuffer.toCanonicalText` tests, all passing; verified again on the user's phone.

---

### Phase 5: Scientific (in progress — engine module done 2026-09-29, not committed)

The user approved Phase 5 on 2026-09-29 ("phase 5 start"). ARCHITECTURE.md §1.12 describes the engine; DEC-047 records the decisions, including a flagged deviation (the P-6 defaults below were implemented before being put back to the user, not after — see DEC-047's "Deviation" note and DEVELOPMENT_STATUS.md).

| Scope item | Result |
| --- | --- |
| Functions: sin, cos, tan, asin, acos, atan, sinh, cosh, tanh, log, ln, sqrt, cbrt, abs | **Done** (engine) |
| x², xʸ | **Done**, both via the general `^` operator — no separate x² key/node; the keypad (Module 3) will just insert `^2`. |
| 10ˣ, eˣ | Not yet — no dedicated function/node; achievable as `10^x` / `e^x` once Module 2/3 exist, or as dedicated keypad buttons that insert that text. Revisit if the user wants a one-key `10ˣ`/`eˣ`. |
| factorial, absolute value | **Done** (engine): `!` postfix operator, `abs` function |
| π, e, brackets | **Done** (engine): always the constants, never a variable (DEC-047) |
| degree/radian mode | **Done in the engine** (`AngleMode`, `CalcEngine.evaluate`'s new parameter); **not yet in the app** — no UI toggle or persisted setting (Module 2/3) |
| Engine: an extensible function registry | **Done** — `CalcFunction` enum + a name→function lookup map in the parser; adding a function needs no grammar changes, just a new enum case and evaluator branch. |
| Engine: approximate values for irrational results | **Done** — `CalcValue` is now a sealed exact/approximate hierarchy (DEC-047) |
| Engine: the remaining P-6 defaults (`−3²`, `2^3^2`, `0^0`, `(−8)^(1/3)`, `tan 90°`) | **Implemented** (DEC-047) — **awaiting the user's explicit review**, since this was built before asking, not after (see the deviation note) |
| Keypad: a clean scientific keypad, sharing state with Basic (DEC-013) | **Not started** (Module 3) |
| Calculator input logic: buffer support for `^`/`!`/function calls, angle-mode state | **Not started** (Module 2) |
| *(Proposed)* a scientific tray, a 2nd/inverse toggle, a landscape layout | Not started; still proposed, not committed to |
| **Done when:** tests cover the edge cases of every function | **Done for the engine** — 117 new tests in `test/scientific_test.dart` (377 total in `packages/calc_engine`); the fuzz test's alphabet now also covers `^ ! π e` and function-name letters. App-level (Module 2/3) tests don't exist yet, since that code doesn't either. |

### Phase 6: Converters

A modular conversion system where new categories are easy to add.

| Category | Units |
| --- | --- |
| Length | m, km, cm, mm, mile, yard, foot, inch |
| Weight | kg, g, mg, lb, oz |
| Temperature | °C, °F, K |
| Area | m², km², ft², acre, hectare |
| Volume | L, mL, gallon, m³ |
| Time | s, min, h, day, week |

- **Currency:** a design for currency conversion, with no network yet.
- **Open question:** US or imperial gallon. The master prompt doesn't say; decide during Phase 6 design.
- *(Proposed):*
  - category chips, and From and To cards with a swap button
  - an in-app number pad
  - an "all units" list
- **Done when:** round-trip conversion tests pass.

### Phase 7: Financial

- **Tools:**
  - EMI: inputs are loan amount, interest rate and tenure; outputs are the monthly EMI, total interest and total payment
  - simple interest and compound interest
  - GST: percentage, inclusive or exclusive, CGST/SGST/IGST
  - discount, tip and percentage
- Charts where they genuinely help understanding.
- *(Proposed):*
  - results update as you type
  - sliders for rate and tenure
  - an EMI donut chart and amortization chart, and a compound-interest growth chart (custom painted)
  - save and reuse
- **Done when:** results match published reference values.

### Phase 8: Date calculator

- **Date difference** in days, weeks, months and years.
- **Add or subtract** (for example, +90 days or −6 months).
- No time-zone bugs.
- *(Proposed):* calendar-date arithmetic in UTC, with add-month clamping to the month end.
- **Done when:** tests pass for leap years, month ends and daylight-saving dates.

### Phase 9: Programmer calculator

- **Bases:** BIN, OCT, DEC and HEX, with easy conversion between them.
- **Operations:** AND, OR, XOR, NOT, shift left and shift right.
- *(Proposed):*
  - word size and signed/unsigned selectors
  - a tappable bit grid
  - digits that are invalid in the current base are disabled, and screen readers announce them as disabled
- **Done when:** the two's complement and overflow tests pass.

### Phase 10: Settings screen

- **Appearance:** light, dark or system. Phase 1 built the theme choice itself; this phase builds the full screen around it.
- **Calculator:** default mode, haptics, sound, decimal precision, angle mode.
- **History:** history settings, clear history.
- **Accessibility:** larger buttons, text scaling, high contrast.
- **About:** app version (P-7), developer information (the content must come from the user), privacy information and licenses.
- **Done when:** the widget tests pass.

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
| `package_info_plus` | P-7 | Phase 10 |
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
