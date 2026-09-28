# Roadmap

This file gives the intended development sequence. Every phase needs the user's **explicit approval before it starts**, and ends with a report followed by a stop (DEC-001). Current status is in [DEVELOPMENT_STATUS.md](DEVELOPMENT_STATUS.md).

- **Source:** the master prompt §30, adjusted by the approved plan (DEC-017).
- **Labels:** requirement text comes from the user's master prompt. Items marked *(proposed)* are Claude's design details that are not yet implemented.

## Sequence

```text
Phase 0  Audit & architecture ............ COMPLETED 2026-09-28
  —      Project-memory system ........... COMPLETED 2026-09-28 (awaiting review)
Phase 1  Foundation ...................... PENDING APPROVAL (scope approved, start not approved)
Phase 2  Design system ................... planned
Phase 3  Basic calculator + engine + memory planned
Phase 4  History + saved calculations .... planned
Phase 5  Scientific ...................... planned
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
2. `dart format` has been run.
3. All tests pass. Record the actual command output.
4. The UI has been reviewed in light and dark, on small and large screens (from Phase 2 on).
5. The docs are updated (Session Handoff Protocol).
6. One local commit has been made.
7. The report has been delivered to the user, and work stops.

---

## Completed

### Phase 0: Project audit and architecture (2026-09-28)

- Audited the template project. Planned the architecture, dependencies, UI/UX and implementation.
- Validated the key choices in a scratch project.
- Delivered the Final Architecture Decision Report, which the user approved (DEC-001 to DEC-017).
- No project files changed.

### Project-memory system (2026-09-28)

- Created `CLAUDE.md` and `docs/` (DEC-018). It awaits the user's review.

## In Progress

Nothing.

## Pending Approval

### Phase 1: Foundation

**Status:** the scope is approved (DEC-016), but **the start is not approved** (P-1). Settle P-2 (baseline commit) and P-3 (app ID timing) at the start.

**Scope: exactly these items, in this order, and nothing more:**

1. **Git setup:**
   - `git init` in `smart_calculator/`, on branch `main`
   - `.gitattributes`
   - a baseline commit of the untouched scaffold (see P-2)
2. **Dependencies:** add the planned set, each re-verified first (DEC-015), and remove `cupertino_icons`.
3. **Strict lint rules** in `analysis_options.yaml`.
4. **Pub workspace:** the root `pubspec.yaml` becomes the workspace root.
5. **Empty calculation-engine package:** `packages/calc_engine`, pure Dart, skeleton only.
6. **Folder structure:** see ARCHITECTURE.md §3.1.
7. **Startup architecture:** preload prefs → `ProviderScope` → app.
8. **Typed route layer over plain Navigator** (DEC-003).
9. **Adaptive shell with placeholder screens:** mode pill and mode sheet on phones, a rail on tablets and landscape (DEC-012).
10. **Basic theme structure.** The detailed tokens and components are Phase 2.
11. **Light/dark/system theme choice, persisted.**
12. **Settings storage:** `SharedPreferencesWithCache`.
13. **Database v1:** `sqflite` schema and migration setup.
14. **Translation (l10n) setup:** gen-l10n with ARB files.
15. **`docs/ARCHITECTURE.md`:** move what was built into §1, "Implemented". Over time, it must also document (master prompt §36):
    - features, folder structure, state management, the calculation engine, persistence and testing
    - how to add a calculator module or a conversion unit
    - build instructions
16. **Replace the default counter test.**
17. **Run formatting, analysis and tests**, and record the actual results.
18. **The Phase 1 local Git commit.** Never push.

**Not in Phase 1:**

- anything in Phase 2
- the final calculator UI and the scientific keypad
- engine logic beyond the skeleton
- design work
- the app ID change, unless the user says otherwise at P-3

**Done when:**

- The app launches with the shell and placeholder screens.
- The theme choice persists across restarts.
- The exit gate passes.

**Report:** the 9 items listed in DEC-016.

---

## Planned

### Phase 2: Design system

- **Tokens:**
  - colour roles, including operator and number keys, for light, dark and system, plus high contrast; contrast is checked
  - typography: display, expression, result, heading, body, caption, button, label
  - spacing (xs to xxl), radius and motion
- **Bundled fonts** with tabular digits (P-8).
- **Components:**
  - AppButton, AppIconButton, CalculatorButton, OperatorButton, PrimaryButton, SecondaryButton
  - AppCard, AppBottomSheet, AppDialog, AppTextField
  - EmptyState, ErrorState, SectionHeader, AppHeader
  - (`AppBottomNavigation` is dropped, by DEC-012.)
- A debug-only gallery screen showing every component *(proposed)*.
- **Done when:** every component has been reviewed in light and dark at 200% text size, and **the user has signed off the design review**. This needs an Android test device (P-4).

### Phase 3: Basic calculator (engine, state, memory)

- **Engine** (DEC-008):
  - precedence, parentheses, decimals, negatives, percent
  - floating-point handling with exact arithmetic
  - handling of invalid expressions and division by zero
  - very large and very small numbers
  - an extensible function registry
- **Default behaviours:** confirm P-6 first.
- **Screen:**
  - Header: mode, history shortcut, settings shortcut, a "more" menu.
  - Expression area: the current expression, the previous expression, the result, the cursor, and clear/delete.
  - Keypad: digits, decimal point, `=`, + − × ÷, %, clear, backspace and parentheses.
- **Memory:** MC, MR, M+, M−, MS, independent of the UI.
- **Also:** error handling, animations, haptics and keyboard support.
- *(Proposed):* token-based editing with a cursor, a live preview, a smart `( )` key, and long-pressing ⌫ to clear.
- **Done when:**
  - **More than 200 engine edge-case tests pass** (DEC-010).
  - Keypad and display widget tests pass.
  - The module is stable. Don't move on until it is.

### Phase 4: History and saved calculations

- **History:**
  - Each item stores the expression, result, timestamp and mode.
  - View, search, reuse, copy, delete an item, clear all.
  - An empty state, and confirmation before destructive actions.
  - It persists locally.
- **Saved calculations:** save, rename, edit, reuse and delete. The master prompt's examples: mortgage, BMI, tax, monthly budget.
- *(Proposed):*
  - grouping by Today, Yesterday and earlier; paging
  - swipe-to-delete with Undo, while Clear all asks for confirmation
  - a result "tape" on the calculator display
  - a retention limit and an off switch
- **Done when:** the storage tests and widget tests pass.

### Phase 5: Scientific

- **Functions:**
  - sin, cos, tan, asin, acos, atan, sinh, cosh, tanh
  - log, ln, sqrt, cbrt
  - x², xʸ, 10ˣ, eˣ
  - factorial, absolute value
  - π, e, brackets
  - degree/radian mode
- **Keypad:** a clean scientific keypad that does not overload the basic screen. It shares state with Basic (DEC-013).
- *(Proposed):* a scientific tray (pulled up from an "fx" handle in Basic, kept open in Scientific), a 2nd/inverse toggle, and a landscape layout.
- **Done when:** tests cover the edge cases of every function.

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

- **Appearance:** light, dark or system.
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
| Web and desktop as supported targets | DEC-004 | The user asks |
| `drift` | Only needed for web | Web becomes a target |
| `package_info_plus` | P-7 | Phase 10 |
| iOS build verification | No Mac (P-5) | A Mac is available |
| Extra saved-calculation tools (BMI, tax, monthly budget) | Examples in the master prompt; not in any phase's scope | After Phase 7, if the user wants them |

## Not Yet Scheduled

These need a phase assignment from the user:

| Item | Notes |
| --- | --- |
| App ID and display name change (DEC-005) | Values confirmed; timing pending (P-3) |
| Android predictive back gesture | The final report said it would be enabled, but it isn't in the Phase 1 scope list |
| Release signing configuration | The template signs release builds with the debug key; this must be fixed before any release build is distributed |
