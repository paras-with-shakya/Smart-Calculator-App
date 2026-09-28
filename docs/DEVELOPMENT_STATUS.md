# Development Status

> **The most important file for context recovery.** Rewrite it to the current truth at the end of every meaningful session, following the Session Handoff Protocol in [CLAUDE.md](../CLAUDE.md). Every claim here must be backed by code, by Git, or by a command that was actually run.

**Last updated:** 2026-09-28, at the end of the Phase 2 session.

## At a Glance

| Question | Answer |
| --- | --- |
| Where are we? | **Phase 2 (Design system) is implemented and awaits the user's design sign-off** (P-11). Phase 3 has not started and needs explicit approval. |
| What exists in code? | The Phase 1 foundation, plus the design system: tokens, four themes, bundled Manrope, 10 reusable component files in `lib/core/widgets/`, and a debug-only component gallery. **No calculator features.** |
| What is being worked on? | Nothing. The design review is with the user. |
| What happens next? | The user reviews the screenshots (`build/design_review/`) and signs off Phase 2 or asks for changes. After that comes the Phase 3 approval. |
| Git? | `main` is ahead of `origin/main` (GitHub, the user's remote, at `01f120a`) by the Phase 2 commits. **Claude does not push**; the user pushes, or asks. |
| What must not be repeated? | See "Do NOT Repeat" |
| Known issues? | See "Known Issues" |
| Pending decisions? | P-4 to P-7 and P-9 to P-11 |

## Current Phase

**Phase 2 (Design system): implemented on 2026-09-28, awaiting the user's design sign-off.**

- The user approved Phase 2 on 2026-09-28 ("phase 2 start kro"). During the phase they added a requirement: *"reusable widgets use krna"* (DEC-034).
- **Phase 2 counts as complete only when the user signs off the design review** (ROADMAP exit criterion).
- **Phase 3 must not start without the user's explicit approval.**

## Phase Status

| Phase | Name | Status |
| --- | --- | --- |
| 0 | Project audit and architecture | Completed 2026-09-28 |
| — | Project-memory system | Completed 2026-09-28 |
| 1 | Foundation | Completed 2026-09-28 (commits `06c0a93`, `7926920`) |
| 2 | Design system | **Implemented 2026-09-28** (commit `0fc15ef`); **awaiting design sign-off** (P-11) |
| 3 | Basic calculator (engine, memory) | Not started; needs approval |
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

### Phase 0, the memory system and Phase 1 (2026-09-28)

- Phase 0: the audit, the validation and the approved architecture (DEC-001 to DEC-017).
- The project-memory system (`813533e`).
- Phase 1 foundation (`06c0a93`, `7926920`, docs `01f120a`): Git, app identity, dependencies, strict lints, the workspace and engine skeleton, startup, Riverpod, typed navigation, the adaptive shell, the theme choice, preferences, database v1, l10n, and 24 tests. Details are in ARCHITECTURE.md §1.

### Phase 2: Design system (2026-09-28, this session; commit `0fc15ef`)

Details are in [ARCHITECTURE.md](ARCHITECTURE.md) §1.7–1.9.

- **Font (DEC-028, resolves P-8):**
  - Manrope 400/500/600/700, static TTFs from `googlefonts/manrope@6f81ebe`, in `assets/fonts/`
  - `tnum` verified in each weight with a Dart check of the font files
  - the OFL is bundled and registered through `lib/app/font_licenses.dart`
- **Tokens (DEC-029):**
  - `AppColors`: 27 roles and 4 palettes
  - `AppTypography`: 11 styles, with tabular figures on the number styles
  - `AppSpacing`: xs to xxl
  - `AppRadius`: superellipse shapes
  - `AppMotion`: reduced-motion aware
- **Themes:** `AppTheme` builds four `ThemeData`s and the component themes. `MaterialApp` uses `highContrastTheme` and `highContrastDarkTheme`, and animates theme changes with the motion tokens.
- **Components (DEC-030):** `AppButton`, `AppIconButton`, `CalculatorButton`, `AppCard`, `AppBottomSheet`/`showAppBottomSheet`, `AppDialog`/`showConfirmationDialog`, `AppTextField`, `EmptyState`/`ErrorState`/`LoadingState`, `SectionHeader`, `AppHeader`.
- **Phase 1 stand-ins replaced:**
  - `PlaceholderView` was removed; `EmptyState` replaces it.
  - The settings page uses `SectionHeader` and `AppHeader`.
  - The shell header uses `AppHeader` and `AppIconButton`.
  - The mode pill is an `AppButton`.
  - The mode sheet is a grid of `AppCard` tiles.
- **Gallery (DEC-032):** `lib/main_gallery.dart` and `lib/gallery/`.
- **Design review (DEC-033):**
  - 33 screenshots generated in `build/design_review/`.
  - **Claude reviewed them** and fixed four issues before the final set: the mode sheet (tiles invisible on the sheet, a label breaking mid-word), operator symbols that looked faint (hence the new `keySymbol` style), floating text-field labels sitting on the edge (DEC-031), and cramped buttons at 200% text (vertical padding added).
- **Tests:** 24 grew to 107 (see Tests).
- **User requirements recorded:** reusable widgets only (CLAUDE.md rule 12, DEC-034), and Hinglish communication (CLAUDE.md rule 13).

## Work In Progress

None.

## Current Task

The user reviews the Phase 2 design. The screenshots are in `build/design_review/`, and the gallery can be run with `flutter run -t lib/main_gallery.dart`.

## Next Task

1. **If the user asks for design changes:** make them in the tokens or components, then regenerate and review the screenshots. Update the docs.
2. **After the user signs off Phase 2 and explicitly approves Phase 3:** do Phase 3, the basic calculator (see [ROADMAP.md](ROADMAP.md)).
   - First, settle P-6 (the engine's default behaviours).
   - Re-verify and add `decimal`, `rational` and `test` for the engine (DEC-019).
   - Build the engine test-first. The 200+ edge-case test gate applies (DEC-010).
   - Then build the keypad and display from `CalculatorButton` and the tokens only (DEC-034).

## Do NOT Repeat

- Don't redo the Phase 0 validation, or the Phase 1 setup (Git, identity, dependencies).
- **Don't re-check Manrope's `tnum` support.** It was verified on 2026-09-28 (DEC-028). Re-check only if the font files change.
- **Don't re-add `PlaceholderView`** or restyle widgets inline. Use the components (DEC-034).
- **Don't commit `build/design_review/`** images (DEC-033).
- Don't run `dart format .`; use `dart format lib test packages`.
- Don't remove `kotlin.incremental=false` (DEC-027) unless P-10 is resolved.
- Treat the first `flutter pub get` failure after a plugin change as expected (P-9) and run it again.
- Don't set up an emulator. Don't delete platform folders. **Don't push** to `origin` unless the user asks in that session (CLAUDE.md rule 10).
- **Don't start Phase 3** without the Phase 2 sign-off and explicit approval.

## Pending Decisions

| ID | Decision | Needed by | Notes |
| --- | --- | --- | --- |
| **P-4** | Viewing the UI on a device | Optional | See note P-4 below the table |
| **P-5** | iOS verification: does the user have access to a Mac? | Before any iOS claim | iOS was not built (Windows) |
| **P-6** | Engine default behaviours (percent, `−3²`, `2^3^2`, `0^0`, …) | Before Phase 3 engine work | See [PROJECT_MEMORY.md](PROJECT_MEMORY.md#calculation-correctness-principles) |
| **P-7** | App version source for the About screen | Phase 10 | `package_info_plus` or a build-time constant |
| **P-9** | Windows Developer Mode, or accept the one-time `pub get` failure after plugin changes | Whenever convenient | Symlinks for the kept desktop folders |
| **P-10** | Keep `kotlin.incremental=false`, or put the project and the pub cache on one drive | Optional | DEC-027 |
| **P-11** | **The user's sign-off of the Phase 2 design** (palette, type, shapes, components) | Before Phase 3 | Screenshots are in `build/design_review/` |

**P-4, device checks.** The design review uses generated screenshots (DEC-033). The user may also run the gallery or the app on their Android phone (`23124RN87I`); Claude has not installed anything on it.

**Resolved this session:** P-8. The fonts are Manrope, with `tnum` verified (DEC-028).

## Important Files

| File | Role |
| --- | --- |
| `lib/app/theme/app_colors.dart` | The colour roles and the four palettes |
| `lib/app/theme/app_typography.dart` | The type scale; the number styles use tabular figures |
| `lib/app/theme/app_theme.dart` | Builds the four themes from the tokens |
| `lib/app/theme/app_spacing.dart`, `app_radius.dart`, `app_motion.dart` | Spacing, shapes, motion |
| `lib/core/widgets/*` | The reusable components; screens use only these |
| `lib/gallery/*`, `lib/main_gallery.dart` | The debug-only component gallery |
| `assets/fonts/*` | Manrope and its OFL |
| `test/design_review/design_review_screenshots_test.dart`, `dart_test.yaml` | The screenshot generator, skipped by default |
| `test/gallery/gallery_accessibility_test.dart` | Accessibility guidelines over every component |
| (Phase 1 files) | See ARCHITECTURE.md §1: startup, navigation, shell, persistence, l10n, engine skeleton |

## Dependencies

- **Unchanged in Phase 2:** no packages were added or removed. The fonts are assets, not packages.
- **Actually in `pubspec.yaml` and `pubspec.lock`:**
  - app: `flutter_riverpod` 3.4.3, `shared_preferences` 2.5.5, `sqflite` 2.4.4, `path` 1.9.1, `intl` 0.20.3, `flutter_localizations`
  - dev: `flutter_test`, `flutter_lints` 6.0.0, `shared_preferences_platform_interface` 2.4.2, `sqflite_common_ffi` 2.4.3
- **`packages/calc_engine`** has no dependencies.
- **Still planned:** ARCHITECTURE.md §3.8.

## Tests

These checks were run this session, in `smart_calculator/`:

| Command | Result |
| --- | --- |
| Font check (Dart script on the 4 TTFs) | `tnum` present in all four weights; default digits proportional |
| `flutter test test/app/theme/app_colors_test.dart` (first run) | 9 passed. A temporary report showed the headroom: lowest light-palette text pair 5.15, lowest dark 6.08, high contrast ≥ 9.28. |
| Mutation check: light `textMuted` set to `#C8C4BE` | The gallery contrast test **failed** ("found 1.51, expected 4.5"); the colour was restored |
| `flutter test --tags design-review --run-skipped --update-goldens` | 33 passed; 33 PNGs written to `build/design_review/`. Run 4 times while fixing review issues. |
| `dart format --output=none --set-exit-if-changed lib test packages` (final) | `Formatted 70 files (0 changed)`, exit 0 |
| `flutter analyze` (final) | `No issues found!`, exit 0 |
| `flutter test` (final) | `+107 ~1: All tests passed!`; the 1 skip is the design-review generator |
| `flutter build apk --debug` | **Built**, 36.9 s |
| `flutter build apk --release` | **Built**, 45.7 MB (was 45.3 MB before the fonts) |
| `aapt dump badging` and `unzip -l` on the release APK | See the APK checks below |

**APK checks:**

- package `com.parasshakya.smartcalculator`, label "Smart Calculator"
- **no INTERNET permission**
- the four Manrope TTFs and `Manrope-OFL.txt` are bundled
- the Material icon font was tree-shaken to 3.5 KB

**Where the 107 tests are:**

| Area | Tests |
| --- | --- |
| Phase 1 tests | 24 |
| Palette contrast | 9 |
| Themes and motion | 7 |
| Fonts | 2 |
| AppButton | 5 |
| Cards, headers, icon buttons | 6 |
| CalculatorButton | 7 |
| Dialogs, sheets, text fields | 7 |
| Status views | 4 |
| Gallery accessibility (9 sections × 4 themes) | 36 |

**Not run:**

- the iOS build (Windows)
- running on a device or emulator (not required)
- integration tests (none yet)

## Known Issues

1. **P-9:** the first `flutter pub get` after a plugin change fails once on this machine (no symlink permission). Run it again.
2. **DEC-027:** Kotlin incremental compilation is disabled (drives `C:`/`D:`).
3. **`dart format .`** crashes on long paths inside `build/`. Use `dart format lib test packages`.
4. **Release signing:** release APKs are signed with the debug key. Not scheduled.
5. **Template leftovers:** web and desktop identifiers, the web manifest and `index.html` text, `README.md`, and the default launcher icons (Phase 11).
6. **Icons don't grow with text size,** which matches Android's behaviour. To review in Phase 11.
7. **High contrast follows only the platform setting.** The in-app switch is Phase 10.
8. **Landscape layout:** most phones in landscape get the expanded layout with the history panel (DEC-022). The Phase 3/5 design must decide the landscape calculator layout.
9. **The current mode isn't persisted** (DEC-021).
10. **No visual check on a real device yet.** The review relies on test-rendered screenshots. Test rendering differs slightly from a device: no platform text antialiasing, and no system bars.
11. **`appDatabaseProvider` has no consumers yet** (Phase 4).

## Blockers

- **Phase 3:** needs the user's Phase 2 sign-off (P-11) and explicit approval, then P-6.
- **No technical blockers.** iOS still can't be built on Windows.

## Discrepancies Found

1. **Project-memory session:** the auto-memory had gone stale, and an example status template had been mistaken for real status. Both resolved.
2. **Phase 1:**
   - DEC-015's "released within the past year" claim was wrong for `path` (corrected).
   - The Phase 0 claim that Android builds pass held only on the `C:` drive (DEC-027).
   - The docs listed `dart format .` as the QA command (replaced).
3. **Phase 2:** the master prompt's component list differs from what was built (consolidated variants, plus `LoadingState`). This is a deliberate, recorded deviation (DEC-030), not a discrepancy between docs and code.
4. **Phase 2 (Git remote):**
   - The docs said "no remote, nothing pushed". But the user had added the GitHub remote `origin` and pushed `main` up to `01f120a` after Phase 1.
   - Claude did not do this, and found it with `git branch -vv`.
   - The docs are corrected: CLAUDE.md rule 10, and DEC-006.
   - Local `main` is now **2 commits ahead** (`0fc15ef`, `4d0f07f`), plus this correction. **Not pushed.**

## Last Session Summary

**2026-09-28, Phase 2 session.**

1. The user approved Phase 2, asked for Hinglish replies (recorded in CLAUDE.md and Claude's memory) and required reusable widgets (DEC-034).
2. Fonts:
   - Downloaded Manrope from the upstream Google Fonts repo.
   - Verified `tnum` with a Dart script.
   - Bundled the fonts and registered the OFL.
3. Tokens:
   - Wrote the tokens, the four palettes and the contrast tests.
   - Checked the headroom, and confirmed with a mutation that the checks catch low contrast.
4. Built `AppTheme` and 10 component files, and replaced the Phase 1 stand-ins.
5. Built the gallery, the accessibility guideline tests and the screenshot generator.
6. Reviewed the screenshots and fixed four visual issues.
7. Checks: `flutter analyze` clean, 107 tests pass, and the debug and release APKs build.
8. Committed the code (`0fc15ef`), then updated the docs.

## Instructions For Next Session

1. Follow the Context Recovery Protocol in [CLAUDE.md](../CLAUDE.md). **Reply to the user in Hinglish** (CLAUDE.md rule 13).
2. **If P-11 (design sign-off) is still open,** ask the user for it. Apply any requested changes through the tokens and components, then regenerate the screenshots (`flutter test --tags design-review --run-skipped --update-goldens`) and review them.
3. **Don't start Phase 3** until the user signs off Phase 2 and explicitly approves Phase 3. Then settle P-6 first.
4. **Build every new screen only from `lib/core/widgets/` and the tokens** (rule 12, DEC-034).
5. **Checks:**
   - `flutter analyze`
   - `dart format --set-exit-if-changed lib test packages`
   - `flutter test`
   - `flutter build apk --debug`
   - after visual changes, the screenshots

   Record the actual results.
6. Finish with the Session Handoff Protocol.
