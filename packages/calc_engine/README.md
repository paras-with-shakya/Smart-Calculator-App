# calc_engine

The pure-Dart calculation engine for Smart Calculator. It is a member of the app's pub workspace; see the root `pubspec.yaml`.

## Rules

- **No Flutter.** Never import `package:flutter` or `dart:ui`. `test/architecture/layer_boundaries_test.dart` in the app enforces this.
- **Own types only.** The public API exposes only the engine's own types. The numeric library stays hidden behind them, so it can be replaced later (DEC-008).

## Status

This is an empty skeleton, created in Phase 1. The engine, its dependencies (`decimal`, `rational`, `test`) and its 200+ edge-case tests arrive in Phase 3. See `docs/ROADMAP.md`.
