# CLAUDE.md — Smart Calculator

This is the entry point for every Claude Code session on this project. Read it first, then follow the **Context Recovery Protocol** below before doing any work.

**Snapshot (2026-09-30):** Phases 1–5 are all complete, committed and phone-tested. **Phase 5 (Scientific):** the engine (Module 1, `ef7b0ba`), the input logic (Module 2, `856d175`, audited and fixed, `d42fa5f`) and the scientific keypad (Module 3, `8096bb4`, DEC-050 — built from a written, independently-reviewed, user-approved plan) are all built, tested (387 engine + 645 app tests) and phone-tested. **Don't start Phase 6 (or any phase) without the user's explicit choice and approval.** One pre-existing Basic bug was found (not caused) while testing Module 3: `CalculatorMemoryKeys` narrows below 48 dp in landscape at 200% text — reported, not fixed (Known Issues #16). **Note: this project has been worked on by more than one Claude Code session concurrently at least once** (`856d175`) — always check `git log --oneline -10` before trusting a prior session's summary of what's built. If this line disagrees with [docs/DEVELOPMENT_STATUS.md](docs/DEVELOPMENT_STATUS.md), check `git log` and the code, then fix the docs.

## Source of truth

**The repository documentation is the persistent source of truth for project state.** Conversation history must never be treated as the only source of project memory. Assume the previous conversation is not available.

| File | What it answers |
| --- | --- |
| [docs/PROJECT_MEMORY.md](docs/PROJECT_MEMORY.md) | What the project is; its stable principles, constraints and "do not want" list |
| [docs/DEVELOPMENT_STATUS.md](docs/DEVELOPMENT_STATUS.md) | Where we are, what's done, what's next, what must not be repeated. **The most important file for recovery.** |
| [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | What is implemented vs. confirmed vs. proposed vs. pending |
| [docs/DECISIONS.md](docs/DECISIONS.md) | Why each decision was made, and what was rejected and why |
| [docs/ROADMAP.md](docs/ROADMAP.md) | The phase order, each phase's scope and exit criteria |
| [docs/CHANGELOG.md](docs/CHANGELOG.md) | What actually changed, by date |

## Context Recovery Protocol

```text
NEW CLAUDE SESSION
        ↓
Read CLAUDE.md
        ↓
Read docs/PROJECT_MEMORY.md
        ↓
Read docs/DEVELOPMENT_STATUS.md
        ↓
Read docs/ARCHITECTURE.md
        ↓
Read docs/DECISIONS.md
        ↓
Read docs/ROADMAP.md
        ↓
Read docs/CHANGELOG.md
        ↓
Check Git status
        ↓
Inspect relevant source files
        ↓
Compare documentation with actual code
        ↓
Identify current task
        ↓
Continue from documented state
```

> **Never assume that the previous conversation is available. Recover project state from the repository.**

Notes on the steps:

- **Check Git status:** run `git status`, `git log --oneline -15` and `git status -sb`, which shows how far `main` is ahead of `origin/main`. The repository was initialized on 2026-09-28 on branch `main`. The user later added the GitHub remote `origin` (`github.com/paras-with-shakya/Smart-Calculator-App`) and pushes to it themselves. The latest commits are listed in DEVELOPMENT_STATUS.md.
- **Inspect source / compare:** read `pubspec.yaml`, `lib/`, `test/` and `packages/`. The docs say what *should* be true; the code says what *is* true.
- **Identify current task:** use "Current Task" and "Next Task" in DEVELOPMENT_STATUS.md. If the next task needs the user's approval (every new phase does), stop and ask. Don't start it.

## Working rules

1. **Never redo completed work without a reason.** Check "Completed Work" and "Do NOT repeat" in DEVELOPMENT_STATUS.md first.
2. **Never silently change an architectural decision.** To change one, explain the issue, the proposed solution and why it is better. Get the user's approval, then record a superseding entry in DECISIONS.md.
3. **Never remove an existing feature or decision without documenting why.** Mark the old decision `Superseded` or `Rejected` in DECISIONS.md and keep the entry.
4. **Before large changes,** check ARCHITECTURE.md and DECISIONS.md.
5. **After completing a meaningful task,** update the affected docs.
6. **Before ending a phase or session,** update DEVELOPMENT_STATUS.md (see the Session Handoff Protocol).
7. **If the code differs from the docs,** inspect the code and Git history and correct the docs. Don't guess.
8. **Never invent completed work.** Never claim tests passed unless they were actually run; record the command, the date and the result.
9. **Phase gates:** work one phase and one module at a time. Stop at every phase boundary with a report and wait for explicit approval. Never batch phases.
10. **Never push, and never add or change remotes (user instruction, 2026-09-28).** The user pushes their code to GitHub (`origin`) themselves. Don't offer to push. Local commits are fine.
11. **Never invent product facts** (IDs, names, prices, legal text, developer info). Ask.
12. **Reusable widgets only (user requirement, 2026-09-28).**
    - Build every screen from the shared design-system widgets in `lib/core/widgets/` and the theme tokens in `lib/app/theme/`.
    - Before writing a new widget, check whether an existing one can be used or extended.
    - Never copy styling (colours, sizes, shapes, text styles) into feature code.
    - A widget needed by more than one screen belongs in `lib/core/widgets/`.
13. **Language (user requirement, 2026-09-28).** Talk to the user in **Hinglish** (Roman-script Hindi mixed with English). Code, repository docs and commit messages stay in English unless the user asks otherwise.

## Session Handoff Protocol (mandatory)

Before ending any meaningful session (one that changed files, made or changed a decision, or ran checks whose results matter):

1. Update `docs/DEVELOPMENT_STATUS.md`: rewrite it to the current truth.
2. Update `docs/CHANGELOG.md`: add what actually changed today.
3. Update `docs/DECISIONS.md` if a decision was made or changed.
4. Update `docs/ARCHITECTURE.md` if the architecture changed, or when something moves from proposed to implemented.
5. Update `docs/ROADMAP.md` if a phase or task status changed.
6. Record the tests and checks actually executed: command, date and result.
7. Record known issues.
8. Record the exact next task.
9. Record anything the next session must NOT repeat.
10. Update the Snapshot line at the top of this file.

## Accuracy Rules

Truth comes before completeness. Never:

- invent implementation details
- claim a feature exists when it does not
- claim tests passed without running them
- claim a dependency is installed without checking `pubspec.yaml` / `pubspec.lock`
- claim an architecture decision is final when it is still pending
- overwrite useful existing documentation without reading it first
- rely on conversation memory when repository evidence is available

If documentation and code disagree:

1. Inspect the code.
2. Inspect Git history and status when useful.
3. Determine the actual state.
4. Correct the documentation.
5. Record the discrepancy under "Discrepancies Found" in DEVELOPMENT_STATUS.md.

Status labels used across the docs:

| Label | Meaning |
| --- | --- |
| `CONFIRMED` | Decided by the user |
| `PROPOSED` | Claude's design, not yet implemented; refining it during implementation must be explained |
| `PENDING` | Needs the user's decision |
| `REJECTED` / `SUPERSEDED` | No longer used; the entry stays so the reason isn't lost |

"Implemented" is used only when the code exists and has been checked.

## Quick reference

- **Flutter app root:** this directory (`smart_calculator/`). This is also the Git root.
- **Toolchain:** Flutter 3.47.5 stable, Dart 3.13.4 (verified 2026-09-28).
- **QA commands** (run from this directory):
  - `flutter analyze`
  - `dart format --set-exit-if-changed lib test packages` (**not** `dart format .`, which crashes on long paths under `build/`)
  - `flutter test`
  - `flutter build apk --debug`
  - `dart test` inside `packages/calc_engine` (the engine's 260 tests)
- **Design review:**
  - Screenshots: `flutter test --tags design-review --run-skipped --update-goldens` writes PNGs to `build/design_review/`. Never commit them. Look at them after any visual change.
  - Gallery of every component: `flutter run -t lib/main_gallery.dart`.
- **Design system:** tokens are in `lib/app/theme/`, and the reusable components in `lib/core/widgets/` (see rule 12).
- **Machine:** Windows 11; PowerShell and Git Bash are available.
  - There is no real Python. The `python` on PATH is the Microsoft Store stub, so write helper scripts in Dart or PowerShell.
  - No Visual Studio, so no Windows desktop builds.
  - iOS can't be built here.
  - Developer Mode is off. The first `flutter pub get` after the plugin list changes fails with "requires symlink support"; **run it again**, and it succeeds (P-9).
  - `android/gradle.properties` sets `kotlin.incremental=false`, because the pub cache (`C:`) and the project (`D:`) are on different drives (DEC-027). Keep it.
  - No emulator. The user doesn't want one set up.
- **Per-phase exit gate:** `flutter analyze` clean → formatting check passes → all tests pass → Android debug build → UI review (from Phase 2 on) → docs updated → local commits → report → stop.

## How to maintain the docs

- **DEVELOPMENT_STATUS.md:** rewrite it to the current truth each session. It is not a log.
- **CHANGELOG.md:** append-only, newest date first, real changes only.
- **DECISIONS.md:** append-only. Change a decision's status; never delete its entry. New IDs continue the sequence.
- **ARCHITECTURE.md:** move items from Proposed to Implemented only once the code exists.
- **ROADMAP.md:** move phases between sections as their status changes. Never mark a phase complete before its exit criteria have been verified.
- **PROJECT_MEMORY.md:** stable facts only. Change it only when the user changes a principle or a constraint.
