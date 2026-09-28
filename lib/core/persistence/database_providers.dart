import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:smart_calculator/core/persistence/app_database.dart';
import 'package:sqflite/sqflite.dart';

/// The SQLite implementation used to open the app database.
///
/// The app uses the sqflite plugin (Android, iOS). Tests override this with a
/// factory that runs SQLite on the host machine.
final Provider<DatabaseFactory> databaseFactoryProvider =
    Provider<DatabaseFactory>((ref) => databaseFactorySqflitePlugin);

/// The open app database.
///
/// It is opened on first use, not at startup, and closed when the provider
/// container is disposed.
final FutureProvider<Database> appDatabaseProvider = FutureProvider<Database>((
  ref,
) async {
  final factory = ref.watch(databaseFactoryProvider);
  final directory = await factory.getDatabasesPath();
  final database = await AppDatabase.open(
    factory,
    p.join(directory, AppDatabase.fileName),
  );
  ref.onDispose(database.close);
  return database;
});
