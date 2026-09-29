import 'package:calc_engine/calc_engine.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_calculator/app/modes/calculator_mode.dart';
import 'package:smart_calculator/core/persistence/database_providers.dart';
import 'package:smart_calculator/features/history/domain/history_entry.dart';
import 'package:smart_calculator/features/history/domain/history_repository.dart';
import 'package:sqflite/sqflite.dart';

/// The app's [HistoryRepository], backed by the `history` table (schema v1,
/// DEC-023).
final Provider<HistoryRepository> historyRepositoryProvider =
    Provider<HistoryRepository>(
      (ref) =>
          SqfliteHistoryRepository(() => ref.watch(appDatabaseProvider.future)),
    );

/// Stores history in the `history` table.
///
/// The expression is stored as typed (locale-neutral); the result is stored
/// exactly, the same way the calculator memory is (DEC-041).
final class SqfliteHistoryRepository implements HistoryRepository {
  /// Creates a repository over the database `openDatabase` resolves, opened
  /// on first use.
  const SqfliteHistoryRepository(this._database);

  final Future<Database> Function() _database;

  static const String _table = 'history';

  @override
  Future<List<HistoryEntry>> list() async {
    final db = await _database();
    final rows = await db.query(_table, orderBy: 'created_at DESC, id DESC');
    return [for (final row in rows) _entryFrom(row)];
  }

  @override
  Future<HistoryEntry> add({
    required String expression,
    required CalcValue result,
    required CalculatorMode mode,
  }) async {
    final db = await _database();
    // Millisecond precision, matching what's stored and read back (DEC-023):
    // otherwise this method's return value wouldn't equal what `list()`
    // reads straight after.
    final createdAt = DateTime.fromMillisecondsSinceEpoch(
      DateTime.now().toUtc().millisecondsSinceEpoch,
      isUtc: true,
    );
    final id = await db.insert(_table, {
      'expression': expression,
      'result': result.toStorageString(),
      'mode': mode.storageId,
      'created_at': createdAt.millisecondsSinceEpoch,
    });
    return HistoryEntry(
      id: id,
      expression: expression,
      result: result,
      mode: mode,
      createdAt: createdAt,
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

  static HistoryEntry _entryFrom(Map<String, Object?> row) => HistoryEntry(
    id: row['id']! as int,
    expression: row['expression']! as String,
    result:
        CalcValue.tryParseStorage(row['result']! as String) ?? CalcValue.zero,
    mode: CalculatorModeStorage.fromStorageId(row['mode']! as String),
    createdAt: DateTime.fromMillisecondsSinceEpoch(
      row['created_at']! as int,
      isUtc: true,
    ),
  );
}
