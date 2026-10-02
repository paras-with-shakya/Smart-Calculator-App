// The privacy summary in Settings > About makes factual claims about the app.
// These tests check the ones that can be checked from the repository, so the
// text cannot quietly go stale: if one fails, either the change is wrong or
// the summary (the `settingsPrivacy*` strings in app_en.arb) must be revised.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

List<File> dartFilesIn(String directory) => [
  for (final entity in Directory(directory).listSync(recursive: true))
    if (entity is File && entity.path.endsWith('.dart')) entity,
];

/// The package names listed under the top-level `dependencies:` key of
/// pubspec.yaml.
Set<String> directDependencies() {
  final lines = File('pubspec.yaml').readAsLinesSync();
  final start = lines.indexOf('dependencies:');
  expect(start, isNonNegative);
  final names = <String>{};
  for (final line in lines.skip(start + 1)) {
    if (line.isNotEmpty && !line.startsWith(' ') && !line.startsWith('#')) {
      break; // the next top-level key
    }
    final match = RegExp(r'^  ([a-z_][a-z0-9_]*):').firstMatch(line);
    if (match != null) names.add(match.group(1)!);
  }
  return names;
}

void main() {
  test('"no internet permission": the Android app manifest asks for none', () {
    final manifest = File('android/app/src/main/AndroidManifest.xml')
        .readAsStringSync();

    expect(manifest, isNot(contains('android.permission.INTERNET')));
    // (The debug and profile manifests add INTERNET for Flutter's tooling;
    // the release build, which the summary is about, merges only this one.)
    expect(manifest, isNot(contains('<uses-permission')));
  });

  test('no code in the app or the engine opens a network connection', () {
    final files = [
      ...dartFilesIn('lib'),
      ...dartFilesIn('packages/calc_engine/lib'),
    ];
    expect(files, isNotEmpty);

    final offenders = [
      for (final file in files)
        if (RegExp(
          r'''^\s*(import|export)\s+['"](dart:io|dart:html|package:http/|package:dio/|package:web_socket)''',
          multiLine: true,
        ).hasMatch(file.readAsStringSync()))
          file.path,
    ];
    expect(offenders, isEmpty);
  });

  test('the direct dependencies are the ones the summary was written for', () {
    // None of these talks to a network or reports usage. A new dependency
    // fails this test on purpose: check what it does, then update both this
    // list and the privacy summary if needed.
    expect(directDependencies(), {
      'flutter',
      'calc_engine',
      'flutter_localizations',
      'flutter_riverpod',
      'riverpod',
      'intl',
      'path',
      'shared_preferences',
      'sqflite',
    });
  });

  test('currency rates are not fetched: a rate is stored from the editor', () {
    // The summary says rates start from built-in sample values you can edit.
    final tables = File('lib/features/converter/domain/conversion_tables.dart')
        .readAsStringSync();
    expect(tables, contains('defaultCurrencyRatesPerUsd'));
  });
}
