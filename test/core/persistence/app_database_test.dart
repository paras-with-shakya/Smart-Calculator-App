import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:smart_calculator/core/persistence/app_database.dart';
import 'package:smart_calculator/core/persistence/database_providers.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(sqfliteFfiInit);
  final factory = databaseFactoryFfiNoIsolate;

  Future<Database> openInMemory() async {
    final database = await AppDatabase.open(
      factory,
      inMemoryDatabasePath,
      singleInstance: false,
    );
    addTearDown(database.close);
    return database;
  }

  Future<Directory> createTempDirectory() async {
    final directory = await Directory.systemTemp.createTemp('smart_calc_db_');
    addTearDown(() => directory.delete(recursive: true));
    return directory;
  }

  Future<List<String>> columnsOf(Database database, String table) async => [
    for (final column in await database.rawQuery('PRAGMA table_info($table)'))
      column['name']! as String,
  ];

  test('a new database is created at the current schema version', () async {
    final database = await openInMemory();

    expect(await database.getVersion(), AppDatabase.schemaVersion);
  });

  test('schema v1 creates the history and saved-calculation tables', () async {
    final database = await openInMemory();

    expect(await columnsOf(database, 'history'), [
      'id',
      'expression',
      'result',
      'mode',
      'created_at',
    ]);
    expect(await columnsOf(database, 'saved_calculations'), [
      'id',
      'name',
      'kind',
      'inputs_json',
      'created_at',
      'updated_at',
    ]);
    final indexes = await database.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'index'",
    );
    expect(
      [for (final index in indexes) index['name']],
      containsAll([
        'idx_history_created_at',
        'idx_saved_calculations_updated_at',
      ]),
    );
  });

  test('reopening an existing database keeps its data and version', () async {
    final directory = await createTempDirectory();
    final path = p.join(directory.path, AppDatabase.fileName);

    final first = await AppDatabase.open(factory, path);
    await first.insert('history', {
      'expression': '6×7',
      'result': '42',
      'mode': 'basic',
      'created_at': 0,
    });
    await first.close();

    final reopened = await AppDatabase.open(factory, path);
    addTearDown(reopened.close);
    expect(await reopened.getVersion(), AppDatabase.schemaVersion);
    expect(await reopened.query('history'), hasLength(1));
  });

  test('appDatabaseProvider opens the database file in the databases '
      'directory and closes it when disposed', () async {
    final directory = await createTempDirectory();
    await factory.setDatabasesPath(directory.path);
    final container = ProviderContainer(
      overrides: [databaseFactoryProvider.overrideWithValue(factory)],
    );

    final database = await container.read(appDatabaseProvider.future);
    expect(database.path, p.join(directory.path, AppDatabase.fileName));
    expect(database.isOpen, isTrue);

    container.dispose();
    await pumpEventQueue();
    expect(database.isOpen, isFalse);
  });
}
