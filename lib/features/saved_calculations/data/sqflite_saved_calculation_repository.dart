import 'dart:convert';

import 'package:calc_engine/calc_engine.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_calculator/core/persistence/database_providers.dart';
import 'package:smart_calculator/features/saved_calculations/domain/saved_calculation.dart';
import 'package:smart_calculator/features/saved_calculations/domain/saved_calculation_repository.dart';
import 'package:sqflite/sqflite.dart';

/// The app's `SavedCalculationRepository`, backed by the
/// `saved_calculations` table (schema v1, DEC-023).
final Provider<SavedCalculationRepository> savedCalculationRepositoryProvider =
    Provider<SavedCalculationRepository>(
      (ref) => SqfliteSavedCalculationRepository(
        () => ref.watch(appDatabaseProvider.future),
      ),
    );

/// Stores saved calculations in the `saved_calculations` table.
///
/// Every row is `kind = 'basic'` for now (see `SavedCalculation`); the
/// expression and result live in `inputs_json` as `{"expression": ...,
/// "result": ...}`, the same values a history entry holds.
final class SqfliteSavedCalculationRepository
    implements SavedCalculationRepository {
  /// Creates a repository over the database `openDatabase` resolves, opened
  /// on first use.
  const SqfliteSavedCalculationRepository(this._database);

  final Future<Database> Function() _database;

  static const String _table = 'saved_calculations';
  static const String _basicKind = 'basic';

  @override
  Future<List<SavedCalculation>> list() async {
    final db = await _database();
    final rows = await db.query(_table, orderBy: 'updated_at DESC, id DESC');
    return [for (final row in rows) _entryFrom(row)];
  }

  @override
  Future<SavedCalculation> add({
    required String name,
    required String expression,
    required CalcValue result,
  }) async {
    final db = await _database();
    final now = _nowMillis();
    final id = await db.insert(_table, {
      'name': name,
      'kind': _basicKind,
      'inputs_json': _encodeInputs(expression, result),
      'created_at': now,
      'updated_at': now,
    });
    return SavedCalculation(
      id: id,
      name: name,
      expression: expression,
      result: result,
      createdAt: DateTime.fromMillisecondsSinceEpoch(now, isUtc: true),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(now, isUtc: true),
    );
  }

  @override
  Future<void> rename(int id, String name) async {
    final db = await _database();
    await db.update(
      _table,
      {'name': name, 'updated_at': _nowMillis()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> delete(int id) async {
    final db = await _database();
    await db.delete(_table, where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<void> clear() async {
    final db = await _database();
    await db.delete(_table);
  }

  /// Milliseconds since the epoch, matching what's stored and read back:
  /// otherwise a caller's `DateTime` (with microsecond precision) wouldn't
  /// equal what `list()` reads straight after.
  static int _nowMillis() => DateTime.now().toUtc().millisecondsSinceEpoch;

  static String _encodeInputs(String expression, CalcValue result) =>
      jsonEncode({
        'expression': expression,
        'result': result.toStorageString(),
      });

  static SavedCalculation _entryFrom(Map<String, Object?> row) {
    final inputs =
        jsonDecode(row['inputs_json']! as String) as Map<String, Object?>;
    return SavedCalculation(
      id: row['id']! as int,
      name: row['name']! as String,
      expression: inputs['expression']! as String,
      result:
          CalcValue.tryParseStorage(inputs['result']! as String) ??
          CalcValue.zero,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        row['created_at']! as int,
        isUtc: true,
      ),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        row['updated_at']! as int,
        isUtc: true,
      ),
    );
  }
}
