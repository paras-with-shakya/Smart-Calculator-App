import 'package:calc_engine/calc_engine.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_calculator/app/modes/calculator_mode.dart';
import 'package:smart_calculator/core/persistence/app_database.dart';
import 'package:smart_calculator/features/history/data/sqflite_history_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(sqfliteFfiInit);

  Future<SqfliteHistoryRepository> newRepository() async {
    final database = await AppDatabase.open(
      databaseFactoryFfiNoIsolate,
      inMemoryDatabasePath,
      singleInstance: false,
    );
    addTearDown(database.close);
    return SqfliteHistoryRepository(() async => database);
  }

  test('starts empty', () async {
    final repository = await newRepository();

    expect(await repository.list(), isEmpty);
  });

  test('adds an entry with an assigned id and the current time', () async {
    final repository = await newRepository();
    final before = DateTime.now().toUtc();

    final entry = await repository.add(
      expression: '5+3',
      result: CalcValue.fromInt(8),
      mode: CalculatorMode.basic,
    );

    expect(entry.id, isNotNull);
    expect(entry.expression, '5+3');
    expect(entry.result, CalcValue.fromInt(8));
    expect(entry.mode, CalculatorMode.basic);
    expect(
      entry.createdAt.isAfter(before.subtract(const Duration(seconds: 1))),
      isTrue,
    );
    expect(await repository.list(), [entry]);
  });

  test('keeps the result exact', () async {
    final repository = await newRepository();
    final third = CalcValue.fromInt(1) / CalcValue.fromInt(3);

    final entry = await repository.add(
      expression: '1÷3',
      result: third,
      mode: CalculatorMode.basic,
    );

    expect((await repository.list()).single.result, third);
    expect(entry.result, third);
  });

  test('lists newest first', () async {
    final repository = await newRepository();

    final first = await repository.add(
      expression: '1+1',
      result: CalcValue.fromInt(2),
      mode: CalculatorMode.basic,
    );
    final second = await repository.add(
      expression: '2+2',
      result: CalcValue.fromInt(4),
      mode: CalculatorMode.basic,
    );

    expect(await repository.list(), [second, first]);
  });

  test('records the mode', () async {
    final repository = await newRepository();

    final entry = await repository.add(
      expression: '5',
      result: CalcValue.fromInt(5),
      mode: CalculatorMode.scientific,
    );

    expect((await repository.list()).single.mode, CalculatorMode.scientific);
    expect(entry.mode, CalculatorMode.scientific);
  });

  test('deletes one entry by id, leaving the rest', () async {
    final repository = await newRepository();
    final first = await repository.add(
      expression: '1',
      result: CalcValue.fromInt(1),
      mode: CalculatorMode.basic,
    );
    final second = await repository.add(
      expression: '2',
      result: CalcValue.fromInt(2),
      mode: CalculatorMode.basic,
    );

    await repository.delete(first.id);

    expect(await repository.list(), [second]);
  });

  test('deleting an id that is not there does nothing', () async {
    final repository = await newRepository();
    final entry = await repository.add(
      expression: '1',
      result: CalcValue.fromInt(1),
      mode: CalculatorMode.basic,
    );

    await repository.delete(entry.id + 1000);

    expect(await repository.list(), [entry]);
  });

  test('clear removes every entry', () async {
    final repository = await newRepository();
    await repository.add(
      expression: '1',
      result: CalcValue.fromInt(1),
      mode: CalculatorMode.basic,
    );
    await repository.add(
      expression: '2',
      result: CalcValue.fromInt(2),
      mode: CalculatorMode.basic,
    );

    await repository.clear();

    expect(await repository.list(), isEmpty);
  });

  test('an unrecognized stored mode falls back to basic', () async {
    final database = await AppDatabase.open(
      databaseFactoryFfiNoIsolate,
      inMemoryDatabasePath,
      singleInstance: false,
    );
    addTearDown(database.close);
    await database.insert('history', {
      'expression': '1+1',
      'result': '2',
      'mode': 'not-a-real-mode',
      'created_at': 0,
    });
    final repository = SqfliteHistoryRepository(() async => database);

    expect((await repository.list()).single.mode, CalculatorMode.basic);
  });
}
