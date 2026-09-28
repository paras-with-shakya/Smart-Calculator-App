// Enforces the architecture's dependency rules (docs/ARCHITECTURE.md):
// the calculation engine and every domain layer are plain Dart.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

final RegExp _flutterImport = RegExp(
  r'''^\s*(import|export)\s+['"](package:flutter|dart:ui)''',
  multiLine: true,
);

List<File> _dartFilesIn(String directory) => [
  for (final entity in Directory(directory).listSync(recursive: true))
    if (entity is File && entity.path.endsWith('.dart')) entity,
];

List<String> _pathsImportingFlutter(Iterable<File> files) => [
  for (final file in files)
    if (_flutterImport.hasMatch(file.readAsStringSync())) file.path,
];

void main() {
  test('calc_engine does not declare a Flutter dependency', () {
    final pubspec = File('packages/calc_engine/pubspec.yaml')
        .readAsStringSync();

    expect(
      RegExp(
        r'^\s+(flutter\w*|sdk: flutter)\b',
        multiLine: true,
      ).hasMatch(pubspec),
      isFalse,
    );
  });

  test('calc_engine sources do not import Flutter', () {
    final files = _dartFilesIn('packages/calc_engine');

    expect(files, isNotEmpty);
    expect(_pathsImportingFlutter(files), isEmpty);
  });

  test('domain layers do not import Flutter', () {
    final domainFiles = _dartFilesIn('lib')
        .where((file) => file.uri.pathSegments.contains('domain'));

    expect(domainFiles, isNotEmpty);
    expect(_pathsImportingFlutter(domainFiles), isEmpty);
  });
}
