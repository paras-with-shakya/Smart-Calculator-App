import 'package:sqflite/sqflite.dart';

/// The app's SQLite database: its file name, schema version and migrations.
///
/// This class owns only the schema. Each feature reads and writes its own
/// tables through a repository in its data layer.
abstract final class AppDatabase {
  /// Name of the database file inside the platform's databases directory.
  static const String fileName = 'smart_calculator.db';

  /// The schema version this build of the app expects.
  static int get schemaVersion => _migrations.length;

  /// Opens the database at [path] with [factory], creating it or migrating it
  /// to [schemaVersion].
  static Future<Database> open(DatabaseFactory factory, String path) =>
      factory.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: schemaVersion,
          onCreate: (db, version) => _migrate(db, 0, version),
          onUpgrade: _migrate,
        ),
      );

  /// Applies the migrations that take the schema from [fromVersion] to
  /// [toVersion]. sqflite runs this inside a transaction.
  static Future<void> _migrate(
    Database db,
    int fromVersion,
    int toVersion,
  ) async {
    final batch = db.batch();
    for (final statement
        in _migrations
            .sublist(fromVersion, toVersion)
            .expand((migration) => migration)) {
      batch.execute(statement);
    }
    await batch.commit(noResult: true);
  }
}

/// Schema migrations in order: `_migrations[n]` upgrades version n to n + 1.
///
/// Once a version has shipped, never edit its migration; append a new one.
const List<List<String>> _migrations = [_version1];

/// Version 1: calculation history and saved calculations.
///
/// Timestamps are UTC milliseconds since the Unix epoch. `mode` and `kind`
/// hold stable identifiers, not display names.
const List<String> _version1 = [
  '''
  CREATE TABLE history (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    expression TEXT NOT NULL,
    result TEXT NOT NULL,
    mode TEXT NOT NULL,
    created_at INTEGER NOT NULL
  )''',
  'CREATE INDEX idx_history_created_at ON history (created_at)',
  '''
  CREATE TABLE saved_calculations (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    kind TEXT NOT NULL,
    inputs_json TEXT NOT NULL,
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL
  )''',
  '''
  CREATE INDEX idx_saved_calculations_updated_at
    ON saved_calculations (updated_at)''',
];
