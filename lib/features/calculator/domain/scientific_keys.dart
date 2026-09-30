import 'package:smart_calculator/features/calculator/domain/calculator_key.dart';

/// The scientific function-key tray's groups, in the order they appear.
/// Presentation-only concerns (labels, spoken text) live with the widgets
/// that show them, not here — this is purely which keys exist and how they
/// group and pair, so it can be tested without pumping a single widget.
enum ScientificKeyGroupName {
  /// sin, cos, tan (2nd: asin, acos, atan).
  trigonometry,

  /// sinh, cosh, tanh (no 2nd: the engine has no inverse-hyperbolic
  /// functions).
  hyperbolic,

  /// log, ln, ^ (2nd of log/ln: 10ˣ/eˣ).
  logarithmsAndPowers,

  /// sqrt, cbrt (2nd: x², x³).
  roots,

  /// abs, !, π, e (no 2nd for any of these).
  other,
}

/// One scientific key: its primary [CalculatorKey], and — for the seven
/// keys that have one — the [CalculatorKey] it becomes when 2nd is active.
/// A key with no [secondary] is unaffected by 2nd: the engine has nothing
/// to show in its place (asinh/acosh/atanh and nCr/nPr don't exist), so it
/// isn't invented.
final class ScientificKey {
  /// Creates a key. [secondary] is null when 2nd has no effect on it.
  const ScientificKey(this.primary, [this.secondary]);

  /// What this key inserts normally.
  final CalculatorKey primary;

  /// What this key inserts when 2nd is active, or null to leave it
  /// unchanged.
  final CalculatorKey? secondary;

  /// The key to actually press, given whether 2nd is active.
  CalculatorKey keyFor({required bool second}) =>
      second && secondary != null ? secondary! : primary;

  /// Whether 2nd changes anything for this key.
  bool get hasSecondary => secondary != null;
}

/// A labeled group of [ScientificKey]s, shown together in the tray.
final class ScientificKeyGroup {
  /// Creates a group.
  const ScientificKeyGroup(this.name, this.keys);

  /// Which group this is, for its label.
  final ScientificKeyGroupName name;

  /// The keys in this group, in display order.
  final List<ScientificKey> keys;
}

/// The scientific tray's full contents, left to right.
///
/// Every 2nd-mapping either reuses a [CalculatorKey] that already exists
/// (asin/acos/atan) or is one of the four composite keys
/// (`square`/`cube`/`powerOfTen`/`powerOfE`) built from existing
/// `ExpressionBuffer` operations — nothing here is a function the engine
/// doesn't actually have.
const List<ScientificKeyGroup> scientificKeyGroups = [
  ScientificKeyGroup(ScientificKeyGroupName.trigonometry, [
    ScientificKey(CalculatorKey.sin, CalculatorKey.asin),
    ScientificKey(CalculatorKey.cos, CalculatorKey.acos),
    ScientificKey(CalculatorKey.tan, CalculatorKey.atan),
  ]),
  ScientificKeyGroup(ScientificKeyGroupName.hyperbolic, [
    ScientificKey(CalculatorKey.sinh),
    ScientificKey(CalculatorKey.cosh),
    ScientificKey(CalculatorKey.tanh),
  ]),
  ScientificKeyGroup(ScientificKeyGroupName.logarithmsAndPowers, [
    ScientificKey(CalculatorKey.log, CalculatorKey.powerOfTen),
    ScientificKey(CalculatorKey.ln, CalculatorKey.powerOfE),
    ScientificKey(CalculatorKey.power),
  ]),
  ScientificKeyGroup(ScientificKeyGroupName.roots, [
    ScientificKey(CalculatorKey.sqrt, CalculatorKey.square),
    ScientificKey(CalculatorKey.cbrt, CalculatorKey.cube),
  ]),
  ScientificKeyGroup(ScientificKeyGroupName.other, [
    ScientificKey(CalculatorKey.abs),
    ScientificKey(CalculatorKey.factorial),
    ScientificKey(CalculatorKey.pi),
    ScientificKey(CalculatorKey.euler),
  ]),
];
