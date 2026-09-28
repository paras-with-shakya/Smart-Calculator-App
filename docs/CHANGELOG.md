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

---

## 2026-09-28

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
