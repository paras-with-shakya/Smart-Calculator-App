import 'package:smart_calculator/features/calculator/domain/expression_buffer.dart';

/// [buffer] as text for assertions: values as `{n/d}`, the cursor as `|`.
String show(ExpressionBuffer buffer) {
  final parts = [
    for (final unit in buffer.units)
      switch (unit) {
        SymbolUnit(:final symbol) => symbol,
        ValueUnit(:final value) => '{${value.toStorageString()}}',
      },
  ]..insert(buffer.cursor, '|');
  return parts.join();
}
