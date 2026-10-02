import 'dart:io';

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_calculator/app/theme/app_colors.dart';

import 'launcher_icon_spec.dart';

String _read(String relative) =>
    File('${LauncherIconSpec.androidRes}/$relative').readAsStringSync();

String _hex(Color colour) {
  String channel(double v) =>
      (v * 255).round().toRadixString(16).padLeft(2, '0').toUpperCase();
  return '#${channel(colour.r)}${channel(colour.g)}${channel(colour.b)}';
}

String _launchBackground(String colorsFile) =>
    RegExp(r'<color name="launch_background">(#[0-9A-Fa-f]{6})</color>')
        .firstMatch(_read(colorsFile))!
        .group(1)!
        .toUpperCase();

void main() {
  group('the Android launch screen is the app background', () {
    test('light', () {
      expect(
        _launchBackground('values/colors.xml'),
        _hex(AppColors.light.background),
      );
    });

    test('dark (the system dark mode)', () {
      expect(
        _launchBackground('values-night/colors.xml'),
        _hex(AppColors.dark.background),
      );
    });
  });

  test('every launch and window background uses that colour', () {
    for (final file in [
      'drawable/launch_background.xml',
      'drawable-v21/launch_background.xml',
    ]) {
      expect(
        _read(file),
        contains('android:drawable="@color/launch_background"'),
        reason: file,
      );
    }
    for (final file in ['values/styles.xml', 'values-night/styles.xml']) {
      expect(
        _read(file),
        contains(
          '<item name="android:windowBackground">'
          '@color/launch_background</item>',
        ),
        reason: '$file NormalTheme',
      );
    }
    for (final file in [
      'values-v31/styles.xml',
      'values-night-v31/styles.xml',
    ]) {
      expect(
        _read(file),
        contains(
          '<item name="android:windowSplashScreenBackground">'
          '@color/launch_background</item>',
        ),
        reason: file,
      );
    }
  });
}
