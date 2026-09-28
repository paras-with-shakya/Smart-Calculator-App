# Roadmap

This file gives the intended development sequence. Every phase needs the user's **explicit approval before it starts**, and ends with a report followed by a stop (DEC-001). Current status is in [DEVELOPMENT_STATUS.md](DEVELOPMENT_STATUS.md).

- **Source:** the master prompt §30, adjusted by the approved plan (DEC-017).
- **Labels:** requirement text comes from the user's master prompt. Items marked *(proposed)* are Claude's design details that are not yet implemented.

## Sequence

```text
Phase 0  Audit & architecture ............ COMPLETED 2026-09-28
  —      Project-memory system ........... COMPLETED 2026-09-28
Phase 1  Foundation ...................... COMPLETED 2026-09-28 (awaiting the user's review)
Phase 2  Design system ................... PENDING APPROVAL
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
2. Formatting passes: `dart format --set-exit-if-changed lib test packages`. Don't run `dart format .`; see CLAUDE.md.
3. All tests pass. Record the actual command output.
4. The Android build passes.
5. The UI has been reviewed in light and dark, on small and large screens (from Phase 2 on).
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

## In Progress

Nothing.

## Pending Approval

### Phase 2: Design system

**Status:** not started, and **needs the user's explicit approval.**

- **Tokens:**
  - colour roles, including operator and number keys, for light, dark and system, plus high contrast; contrast is checked
  - typography: display, expression, result, heading, body, caption, button, label
  - spacing (xs to xxl; Phase 1 has only sm, md and lg), radius and motion
- **Bundled fonts** with tabular digits (P-8).
- **Components:**
  - AppButton, AppIconButton, CalculatorButton, OperatorButton, PrimaryButton, SecondaryButton
  - AppCard, AppBottomSheet, AppDialog, AppTextField
  - EmptyState, ErrorState, SectionHeader, AppHeader
  - (`AppBottomNavigation` is dropped, by DEC-012.)
- **Phase 1 stand-ins to replace or absorb:**
  - `PlaceholderView`
  - the settings page's private section header
  - the provisional seed colour and spacing
  - the mode sheet's plain list (the audit proposed a grid)
- A debug-only gallery screen showing every component *(proposed)*.
- **Done when:** every component has been reviewed in light and dark at 200% text size, and **the user has signed off the design review**. This needs an Android test device (P-4).

---

## Planned

### Phase 3: Basic calculator (engine, state, memory)

- **First:** add and re-verify `decimal`, `rational` and `test` for the engine (DEC-019), and confirm the default behaviours (P-6).
- **Engine** (DEC-008):
  - precedence, parentheses, decimals, negatives, percent
  - floating-point handling with exact arithmetic
  - handling of invalid expressions and division by zero
  - very large and very small numbers
  - an extensible function registry
- **Screen:**
  - Header: mode, history shortcut, settings shortcut, a "more" menu.
  - Expression area: the current expression, the previous expression, the result, the cursor, and clear/delete.
  - Keypad: digits, decimal point, `=`, + − × ÷, %, clear, backspace and parentheses.
- **Memory:** MC, MR, M+, M−, MS, independent of the UI.
- **Also:** error handling, animations, haptics and keyboard support.
- **Landscape:** decide the phone-landscape calculator layout (DEC-022).
- *(Proposed):* token-based editing with a cursor, a live preview, a smart `( )` key, and long-pressing ⌫ to clear.
- **Done when:**
  - **More than 200 engine edge-case tests pass** (DEC-010).
  - Keypad and display widget tests pass.
  - The module is stable. Don't move on until it is.

### Phase 4: History and saved calculations

- **Start by** confirming the v1 table columns (DEC-023) before anything writes to them.
- **History:**
  - Each item stores the expression, result, timestamp and mode.
  - View, search, reuse, copy, delete an item, clear all.
  - An empty state, and confirmation before destructive actions.
  - It persists locally. The history panel and page replace their Phase 1 placeholders.
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
