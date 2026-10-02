import 'package:calc_engine/calc_engine.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_calculator/app/modes/calculator_mode.dart';
import 'package:smart_calculator/core/persistence/app_database.dart';
import 'package:smart_calculator/core/persistence/database_providers.dart';
import 'package:smart_calculator/core/persistence/preferences.dart';
import 'package:smart_calculator/features/calculator/application/calculator_notifier.dart';
import 'package:smart_calculator/features/calculator/domain/calculator_key.dart';
import 'package:smart_calculator/features/history/application/history_notifier.dart';
import 'package:smart_calculator/features/history/data/sqflite_history_repository.dart';
import 'package:smart_calculator/features/settings/application/app_settings_notifier.dart';
import 'package:smart_calculator/features/settings/domain/app_settings.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../helpers/test_app.dart';

void main() {
  setUpAll(sqfliteFfiInit);

  late SharedPreferencesWithCache preferences;

  setUp(() async {
    useInMemoryPreferences();
    preferences = await openPreferences();
  });

  Future<Database> openDatabase() async {
    final database = await AppDatabase.open(
      databaseFactoryFfiNoIsolate,
      inMemoryDatabasePath,
      singleInstance: false,
    );
    addTearDown(database.close);
    return database;
  }

  Future<void> addEntries(
    SqfliteHistoryRepository repository,
    int count,
  ) async {
    for (var i = 1; i <= count; i++) {
      await repository.add(
        expression: '$i+0',
        result: CalcValue.fromInt(i),
        mode: CalculatorMode.basic,
      );
    }
  }

  group('SqfliteHistoryRepository.trimTo', () {
    test('keeps only the newest entries, newest first', () async {
      final database = await openDatabase();
      final repository = SqfliteHistoryRepository(() async => database);
      await addEntries(repository, 10);

      await repository.trimTo(3);

      final entries = await repository.list();
      expect([for (final e in entries) e.expression], ['10+0', '9+0', '8+0']);
    });

    test('does nothing when there are fewer entries than the limit', () async {
      final database = await openDatabase();
      final repository = SqfliteHistoryRepository(() async => database);
      await addEntries(repository, 2);

      await repository.trimTo(50);

      expect(await repository.list(), hasLength(2));
    });

    test('keeps exactly the limit, one at the edge', () async {
      final database = await openDatabase();
      final repository = SqfliteHistoryRepository(() async => database);
      await addEntries(repository, 5);

      await repository.trimTo(5);
      expect(await repository.list(), hasLength(5));
      await repository.trimTo(4);
      expect(await repository.list(), hasLength(4));
      await repository.trimTo(1);
      expect([for (final e in await repository.list()) e.expression], ['5+0']);
    });

    test('keeps the same entries list() shows first, even if the clock '
        'went backwards', () async {
      final database = await openDatabase();
      final repository = SqfliteHistoryRepository(() async => database);
      // Newest by time is the one with the SMALLER id.
      await database.insert('history', {
        'expression': 'newest',
        'result': '1',
        'mode': 'basic',
        'created_at': 3000,
      });
      await database.insert('history', {
        'expression': 'older',
        'result': '2',
        'mode': 'basic',
        'created_at': 2000,
      });
      await database.insert('history', {
        'expression': 'oldest',
        'result': '3',
        'mode': 'basic',
        'created_at': 1000,
      });

      await repository.trimTo(2);

      expect(
        [for (final e in await repository.list()) e.expression],
        ['newest', 'older'],
      );
    });
  });

  group('HistoryNotifier', () {
    ProviderContainer container(Database database) => ProviderContainer.test(
      overrides: [appDatabaseProvider.overrideWith((ref) async => database)],
    );

    test('add with keepLast trims and shows what is left', () async {
      final database = await openDatabase();
      final c = container(database);
      await c.read(historyProvider.future);
      final notifier = c.read(historyProvider.notifier);

      for (var i = 1; i <= 5; i++) {
        await notifier.add(
          expression: '$i+0',
          result: CalcValue.fromInt(i),
          mode: CalculatorMode.basic,
          keepLast: 3,
        );
      }

      final shown = c.read(historyProvider).requireValue;
      expect([for (final e in shown) e.expression], ['5+0', '4+0', '3+0']);
      expect(
        await SqfliteHistoryRepository(() async => database).list(),
        shown,
      );
    });

    test('add without keepLast keeps everything', () async {
      final database = await openDatabase();
      final c = container(database);
      await c.read(historyProvider.future);

      for (var i = 1; i <= 4; i++) {
        await c
            .read(historyProvider.notifier)
            .add(
              expression: '$i+0',
              result: CalcValue.fromInt(i),
              mode: CalculatorMode.basic,
            );
      }

      expect(c.read(historyProvider).requireValue, hasLength(4));
    });

    test('trimTo shows the trimmed list even before it was loaded', () async {
      final database = await openDatabase();
      final repository = SqfliteHistoryRepository(() async => database);
      await addEntries(repository, 6);
      final c = container(database);

      // The history has never been read, as when Settings opens first.
      await c.read(historyProvider.notifier).trimTo(2);

      expect(c.read(historyProvider).requireValue, hasLength(2));
    });
  });

  group('the calculator and the history settings', () {
    ProviderContainer container(Database database) => ProviderContainer.test(
      overrides: [
        appDatabaseProvider.overrideWith((ref) async => database),
        sharedPreferencesProvider.overrideWithValue(preferences),
      ],
    );

    Future<void> calculate(ProviderContainer c, int a, int b) async {
      final notifier = c.read(calculatorProvider.notifier);
      for (final key in [
        for (final digit in '$a'.split(''))
          CalculatorKey.digit(int.parse(digit)),
        CalculatorKey.add,
        for (final digit in '$b'.split(''))
          CalculatorKey.digit(int.parse(digit)),
        CalculatorKey.equals,
      ]) {
        notifier.press(key);
      }
      // The save is not awaited by the calculator.
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }

    test('a calculation is saved by default', () async {
      final database = await openDatabase();
      final c = container(database);
      await c.read(historyProvider.future);

      await calculate(c, 2, 3);

      expect(c.read(historyProvider).requireValue, hasLength(1));
    });

    test('with history off nothing new is saved, old entries stay', () async {
      final database = await openDatabase();
      final repository = SqfliteHistoryRepository(() async => database);
      await addEntries(repository, 2);
      final c = container(database);
      await c.read(historyProvider.future);
      await c
          .read(appSettingsProvider.notifier)
          .setHistoryEnabled(enabled: false);

      await calculate(c, 2, 3);

      expect(await repository.list(), hasLength(2));
      expect(c.read(historyProvider).requireValue, hasLength(2));
    });

    test('turning it back on saves again', () async {
      final database = await openDatabase();
      final c = container(database);
      await c.read(historyProvider.future);
      final settings = c.read(appSettingsProvider.notifier);
      await settings.setHistoryEnabled(enabled: false);
      await settings.setHistoryEnabled(enabled: true);

      await calculate(c, 4, 4);

      expect(c.read(historyProvider).requireValue, hasLength(1));
    });

    test('a calculation trims the history to the limit', () async {
      final database = await openDatabase();
      final repository = SqfliteHistoryRepository(() async => database);
      await addEntries(repository, 60);
      final c = container(database);
      await c.read(historyProvider.future);
      await c
          .read(appSettingsProvider.notifier)
          .setHistoryLimit(HistoryLimit.fifty);

      await calculate(c, 1, 1);

      final entries = await repository.list();
      expect(entries, hasLength(50));
      expect(entries.first.expression, '1+1');
    });

    test('unlimited keeps everything', () async {
      final database = await openDatabase();
      final repository = SqfliteHistoryRepository(() async => database);
      await addEntries(repository, 60);
      final c = container(database);
      await c.read(historyProvider.future);

      await calculate(c, 1, 1);

      expect(await repository.list(), hasLength(61));
    });
  });
}
