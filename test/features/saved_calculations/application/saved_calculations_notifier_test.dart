import 'package:calc_engine/calc_engine.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_calculator/core/persistence/app_database.dart';
import 'package:smart_calculator/core/persistence/database_providers.dart';
import 'package:smart_calculator/features/saved_calculations/application/saved_calculations_notifier.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(sqfliteFfiInit);

  ProviderContainer newContainer() => ProviderContainer.test(
    overrides: [
      appDatabaseProvider.overrideWith(
        (ref) => AppDatabase.open(
          databaseFactoryFfiNoIsolate,
          inMemoryDatabasePath,
          singleInstance: false,
        ),
      ),
    ],
  );

  test('starts empty', () async {
    final container = newContainer();

    expect(await container.read(savedCalculationsProvider.future), isEmpty);
  });

  test('add prepends the new entry', () async {
    final container = newContainer();
    await container.read(savedCalculationsProvider.future);
    final notifier = container.read(savedCalculationsProvider.notifier);

    await notifier.add(
      name: 'First',
      expression: '1+1',
      result: CalcValue.fromInt(2),
    );
    await notifier.add(
      name: 'Second',
      expression: '2+2',
      result: CalcValue.fromInt(4),
    );

    final entries = container.read(savedCalculationsProvider).requireValue;
    expect(entries, hasLength(2));
    expect(entries.first.name, 'Second');
    expect(entries.last.name, 'First');
  });

  test('rename updates the state and re-sorts it', () async {
    final container = newContainer();
    await container.read(savedCalculationsProvider.future);
    final notifier = container.read(savedCalculationsProvider.notifier);
    await notifier.add(
      name: 'First',
      expression: '1',
      result: CalcValue.fromInt(1),
    );
    await notifier.add(
      name: 'Second',
      expression: '2',
      result: CalcValue.fromInt(2),
    );
    final firstId = container
        .read(savedCalculationsProvider)
        .requireValue
        .last
        .id;

    await notifier.rename(firstId, 'Renamed');

    final entries = container.read(savedCalculationsProvider).requireValue;
    expect(entries.first.id, firstId);
    expect(entries.first.name, 'Renamed');
  });

  test('delete removes just that entry from the state', () async {
    final container = newContainer();
    await container.read(savedCalculationsProvider.future);
    final notifier = container.read(savedCalculationsProvider.notifier);
    await notifier.add(
      name: 'First',
      expression: '1',
      result: CalcValue.fromInt(1),
    );
    await notifier.add(
      name: 'Second',
      expression: '2',
      result: CalcValue.fromInt(2),
    );
    final toKeep = container.read(savedCalculationsProvider).requireValue.last;

    await notifier.delete(
      container.read(savedCalculationsProvider).requireValue.first.id,
    );

    expect(container.read(savedCalculationsProvider).requireValue, [toKeep]);
  });

  test('clear empties the state and the storage', () async {
    final container = newContainer();
    await container.read(savedCalculationsProvider.future);
    final notifier = container.read(savedCalculationsProvider.notifier);
    await notifier.add(
      name: 'First',
      expression: '1',
      result: CalcValue.fromInt(1),
    );

    await notifier.clear();

    expect(container.read(savedCalculationsProvider).requireValue, isEmpty);
  });

  test('reloading (a fresh container) sees what was added', () async {
    final database = await AppDatabase.open(
      databaseFactoryFfiNoIsolate,
      inMemoryDatabasePath,
      singleInstance: false,
    );
    addTearDown(database.close);

    final first = ProviderContainer.test(
      overrides: [appDatabaseProvider.overrideWith((ref) async => database)],
    );
    await first.read(savedCalculationsProvider.future);
    await first
        .read(savedCalculationsProvider.notifier)
        .add(name: 'Kept', expression: '9', result: CalcValue.fromInt(9));
    first.dispose();

    final second = ProviderContainer.test(
      overrides: [appDatabaseProvider.overrideWith((ref) async => database)],
    );
    expect(
      (await second.read(savedCalculationsProvider.future)).single.name,
      'Kept',
    );
  });
}
