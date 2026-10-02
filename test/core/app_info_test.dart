import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:smart_calculator/core/app_info.dart';

/// The text of `pubspec.yaml`'s top-level `version:` line, split into the
/// version and the build number.
({String version, int build}) pubspecVersion() {
  final pubspec = File('pubspec.yaml').readAsStringSync();
  final match = RegExp(
    r'^version:\s*(\d+\.\d+\.\d+)\+(\d+)\s*$',
    multiLine: true,
  ).firstMatch(pubspec);
  expect(
    match,
    isNotNull,
    reason: 'pubspec.yaml has a "version: x.y.z+n" line',
  );
  return (version: match!.group(1)!, build: int.parse(match.group(2)!));
}

void main() {
  test('the About version is the pubspec.yaml version', () {
    final pubspec = pubspecVersion();

    expect(AppInfo.version, pubspec.version);
    expect(AppInfo.buildNumber, pubspec.build);
  });

  test('it is shown as version (build)', () {
    expect(
      AppInfo.displayVersion,
      '${AppInfo.version} (${AppInfo.buildNumber})',
    );
  });

  test('Android takes its version from pubspec.yaml too', () {
    // If the build ever hard-codes one, this is where to find out.
    final gradle = File('android/app/build.gradle.kts').readAsStringSync();
    expect(gradle, contains('flutter.versionName'));
    expect(gradle, contains('flutter.versionCode'));
  });
}
