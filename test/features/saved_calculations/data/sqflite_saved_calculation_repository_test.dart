import 'package:calc_engine/calc_engine.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_calculator/core/persistence/app_database.dart';
import 'package:smart_calculator/features/saved_calculations/data/sqflite_saved_calculation_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(sqfliteFfiInit);

  Future<SqfliteSavedCalculationRepository> newRepository() async {
    final database = await AppDatabase.open(
      databaseFactoryFfiNoIsolate,
      inMemoryDatabasePath,
      singleInstance: false,
    );
    addTearDown(database.close);
    return SqfliteSavedCalculationRepository(() async => database);
  }

  test('starts empty', () async {
    final repository = await newRepository();

    expect(await repository.list(), isEmpty);
  });

  test('adds an entry with an assigned id and the current time', () async {
    final repository = await newRepository();
    final before = DateTime.now().toUtc();

    final saved = await repository.add(
      name: 'Rent budget',
      expression: '5+3',
      result: CalcValue.fromInt(8),
    );

    expect(saved.id, isNotNull);
    expect(saved.name, 'Rent budget');
    expect(saved.expression, '5+3');
    expect(saved.result, CalcValue.fromInt(8));
    expect(
      saved.createdAt.isAfter(before.subtract(const Duration(seconds: 1))),
      isTrue,
    );
    expect(saved.updatedAt, saved.createdAt);
    expect(await repository.list(), [saved]);
  });

  test('keeps the result exact', () async {
    final repository = await newRepository();
    final third = CalcValue.fromInt(1) / CalcValue.fromInt(3);

    await repository.add(name: 'Third', expression: '1÷3', result: third);

    expect((await repository.list()).single.result, third);
  });

  test('lists most recently updated first', () async {
    final repository = await newRepository();

    final first = await repository.add(
      name: 'First',
      expression: '1+1',
      result: CalcValue.fromInt(2),
    );
    final second = await repository.add(
      name: 'Second',
      expression: '2+2',
      result: CalcValue.fromInt(4),
    );

    expect(await repository.list(), [second, first]);
  });

  test('rename updates the name and moves it to the top', () async {
    final repository = await newRepository();
    final first = await repository.add(
      name: 'First',
      expression: '1+1',
      result: CalcValue.fromInt(2),
    );
    final second = await repository.add(
      name: 'Second',
      expression: '2+2',
      result: CalcValue.fromInt(4),
    );

    await repository.rename(first.id, 'Renamed');

    final entries = await repository.list();
    expect(entries.first.id, first.id);
    expect(entries.first.name, 'Renamed');
    expect(entries.last.id, second.id);
  });

  test('renaming an id that is not there does nothing', () async {
    final repository = await newRepository();
    final saved = await repository.add(
      name: 'First',
      expression: '1',
      result: CalcValue.fromInt(1),
    );

    await repository.rename(saved.id + 1000, 'Nope');

    expect((await repository.list()).single.name, 'First');
  });

  test('deletes one entry by id, leaving the rest', () async {
    final repository = await newRepository();
    final first = await repository.add(
      name: 'First',
      expression: '1',
      result: CalcValue.fromInt(1),
    );
    final second = await repository.add(
      name: 'Second',
      expression: '2',
      result: CalcValue.fromInt(2),
    );

    await repository.delete(first.id);

    expect(await repository.list(), [second]);
  });

  test('clear removes every entry', () async {
    final repository = await newRepository();
    await repository.add(
      name: 'First',
      expression: '1',
      result: CalcValue.fromInt(1),
    );
    await repository.add(
      name: 'Second',
      expression: '2',
      result: CalcValue.fromInt(2),
    );

    await repository.clear();

    expect(await repository.list(), isEmpty);
  });
}
