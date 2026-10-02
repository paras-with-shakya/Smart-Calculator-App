import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'launcher_icon_spec.dart';

/// The width, height and colour type from a PNG's header.
({int width, int height, int colourType}) _pngHeader(String path) {
  final bytes = File(path).readAsBytesSync();
  expect(bytes.sublist(1, 4), 'PNG'.codeUnits, reason: '$path is not a PNG');
  final header = ByteData.sublistView(bytes, 16, 26);
  return (
    width: header.getUint32(0),
    height: header.getUint32(4),
    colourType: header.getUint8(9),
  );
}

void main() {
  test('the logo the icons are made from is in the repository', () {
    expect(File(LauncherIconSpec.sourcePath).existsSync(), isTrue);
  });

  group('Android', () {
    for (final MapEntry(key: folder, value: scale)
        in LauncherIconSpec.androidDensities.entries) {
      test('$folder has the legacy icon and the adaptive foreground', () {
        final res = '${LauncherIconSpec.androidRes}/$folder';

        final legacy = _pngHeader('$res/${LauncherIconSpec.legacyFile}');
        final legacySize = (LauncherIconSpec.legacyDp * scale).round();
        expect((legacy.width, legacy.height), (legacySize, legacySize));

        final foreground = _pngHeader(
          '$res/${LauncherIconSpec.foregroundFile}',
        );
        final foregroundSize = (LauncherIconSpec.adaptiveDp * scale).round();
        expect(
          (foreground.width, foreground.height),
          (foregroundSize, foregroundSize),
        );
      });

      test(
        '${LauncherIconSpec.drawableFolder(folder)} has the splash icon',
        () {
          final splash = _pngHeader(
            '${LauncherIconSpec.androidRes}/'
            '${LauncherIconSpec.drawableFolder(folder)}/'
            '${LauncherIconSpec.splashFile}',
          );
          final splashSize = (LauncherIconSpec.splashCanvasDp * scale).round();
          expect((splash.width, splash.height), (splashSize, splashSize));
        },
      );
    }

    test('the Android 12+ splash screen uses the splash icon', () {
      for (final folder in ['values-v31', 'values-night-v31']) {
        expect(
          File('${LauncherIconSpec.androidRes}/$folder/styles.xml')
              .readAsStringSync(),
          contains(
            '<item name="android:windowSplashScreenAnimatedIcon">'
            '@drawable/splash_icon</item>',
          ),
          reason: folder,
        );
      }
    });

    test('the adaptive icon uses the generated layers', () {
      final adaptive = File(
        '${LauncherIconSpec.androidRes}/mipmap-anydpi-v26/ic_launcher.xml',
      ).readAsStringSync();
      expect(adaptive, contains('@color/ic_launcher_background'));
      expect(adaptive, contains('@mipmap/ic_launcher_foreground'));
      expect(
        File(LauncherIconSpec.backgroundColourPath).readAsStringSync(),
        matches(RegExp(r'name="ic_launcher_background">#[0-9A-F]{6}<')),
      );
    });

    test('the manifest uses the launcher icon', () {
      expect(
        File('android/app/src/main/AndroidManifest.xml').readAsStringSync(),
        contains('android:icon="@mipmap/ic_launcher"'),
      );
    });
  });

  group('iOS', () {
    final icons = iosAppIcons();

    test('the icon set lists every size', () {
      expect(icons, hasLength(19));
    });

    for (final icon in icons) {
      test('${icon.filename} is ${icon.pixels} px and has no alpha', () {
        final header = _pngHeader(
          '${LauncherIconSpec.iosIconSet}/${icon.filename}',
        );
        expect((header.width, header.height), (icon.pixels, icon.pixels));
        // Colour type 2 is RGB; the App Store refuses an icon with alpha.
        expect(header.colourType, 2);
      });
    }
  });
}
