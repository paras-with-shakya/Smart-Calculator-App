/// Pure-Dart calculation engine for Smart Calculator.
///
/// This package must never depend on Flutter (`package:flutter` or
/// `dart:ui`), so it can be tested with plain `dart test` and reused
/// outside the app. Its public API exposes only the engine's own types; the
/// numeric library used internally stays hidden behind them
/// (docs/DECISIONS.md, DEC-008).
///
/// ```dart
/// const engine = CalcEngine();
/// final result = engine.evaluate('0.1+0.2−0.3'); // CalcSuccess(0)
/// ```
library;

export 'src/calc_engine.dart' show CalcEngine;
export 'src/calc_result.dart'
    show CalcError, CalcFailure, CalcResult, CalcSuccess;
export 'src/number/calc_value.dart' show CalcValue;
