import 'package:calc_engine/calc_engine.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_calculator/app/modes/calculator_mode.dart';
import 'package:smart_calculator/core/persistence/app_database.dart';
import 'package:smart_calculator/core/persistence/database_providers.dart';
import 'package:smart_calculator/features/history/application/history_notifier.dart';
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

    expect(await container.read(historyProvider.future), isEmpty);
  });

  test('add prepends the new entry and returns once saved', () async {
    final container = newContainer();
    await container.read(historyProvider.future);

    await container
        .read(historyProvider.notifier)
        .add(
          expression: '5+3',
          result: CalcValue.fromInt(8),
          mode: CalculatorMode.basic,
        );
    await container
        .read(historyProvider.notifier)
        .add(
          expression: '2+2',
          result: CalcValue.fromInt(4),
          mode: CalculatorMode.basic,
        );

    final entries = container.read(historyProvider).requireValue;
    expect(entries, hasLength(2));
    expect(entries.first.expression, '2+2');
    expect(entries.last.expression, '5+3');
  });

  test('delete removes just that entry from the state', () async {
    final container = newContainer();
    final notifier = container.read(historyProvider.notifier);
    await container.read(historyProvider.future);
    await notifier.add(
      expression: '1',
      result: CalcValue.fromInt(1),
      mode: CalculatorMode.basic,
    );
    await notifier.add(
      expression: '2',
      result: CalcValue.fromInt(2),
      mode: CalculatorMode.basic,
    );
    final toKeep = container.read(historyProvider).requireValue.last;

    await notifier.delete(
      container.read(historyProvider).requireValue.first.id,
    );

    expect(container.read(historyProvider).requireValue, [toKeep]);
  });

  test('clear empties the state and the storage', () async {
    final container = newContainer();
    final notifier = container.read(historyProvider.notifier);
    await container.read(historyProvider.future);
    await notifier.add(
      expression: '1',
      result: CalcValue.fromInt(1),
      mode: CalculatorMode.basic,
    );

    await notifier.clear();

    expect(container.read(historyProvider).requireValue, isEmpty);
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
    await first.read(historyProvider.future);
    await first
        .read(historyProvider.notifier)
        .add(
          expression: '9',
          result: CalcValue.fromInt(9),
          mode: CalculatorMode.basic,
        );
    first.dispose();

    final second = ProviderContainer.test(
      overrides: [appDatabaseProvider.overrideWith((ref) async => database)],
    );
    expect((await second.read(historyProvider.future)).single.expression, '9');
  });
}
