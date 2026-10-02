import 'dart:convert';
import 'dart:io';

/// What the launcher icons are made from and the sizes they must have.
/// Shared by the generator (`generate_launcher_icons_test.dart`) and the
/// guard test (`launcher_icons_test.dart`).
abstract final class LauncherIconSpec {
  /// The user's logo (the PNG embedded in their `smart_calculator_logo.svg`,
  /// byte for byte). Not bundled into the app.
  static const String sourcePath = 'assets/brand/smart_calculator_logo.png';

  static const String androidRes = 'android/app/src/main/res';

  static const String iosIconSet =
      'ios/Runner/Assets.xcassets/AppIcon.appiconset';

  static const String legacyFile = 'ic_launcher.png';

  static const String foregroundFile = 'ic_launcher_foreground.png';

  static const String backgroundColourPath =
      '$androidRes/values/ic_launcher_background.xml';

  /// Android density folders and their scale over mdpi.
  static const Map<String, double> androidDensities = {
    'mipmap-mdpi': 1,
    'mipmap-hdpi': 1.5,
    'mipmap-xhdpi': 2,
    'mipmap-xxhdpi': 3,
    'mipmap-xxxhdpi': 4,
  };

  /// A legacy (Android 7) launcher icon is 48 dp square ...
  static const double legacyDp = 48;

  /// ... and the logo's tile fills it but for a 2 dp margin.
  static const double legacyTileDp = 44;

  /// An adaptive icon layer is 108 dp square; launchers show the middle
  /// 72 dp through their mask, and only a 66 dp circle is never cut.
  static const double adaptiveDp = 108;

  static const double safeZoneDp = 66;

  /// The Android 12+ splash icon (`drawable-*/splash_icon.png`): a 288 dp
  /// canvas, of which AOSP shows a 192 dp circle and some launchers (HyperOS)
  /// show all of it. The tile is small enough that its corners stay inside
  /// that circle (120 × √2 < 192), so it looks the same either way.
  static const String splashFile = 'splash_icon.png';

  static const double splashCanvasDp = 288;

  static const double splashTileDp = 120;

  /// Android drawable density folders for [splashFile], matching
  /// [androidDensities].
  static String drawableFolder(String mipmapFolder) =>
      mipmapFolder.replaceFirst('mipmap', 'drawable');

  /// The band just inside the tile's edge (in source pixels) whose average
  /// is the adaptive background colour, and inside which the artwork is
  /// looked for.
  static const int edgeBandStart = 4;
  static const int edgeBandEnd = 30;

  /// Pixels lighter than this (0–255) count as artwork rather than the
  /// tile's dark background.
  static const double artworkLuminance = 90;
}

/// One entry of the iOS app icon set.
typedef IosAppIcon = ({String filename, int pixels});

/// Every image the iOS icon set's `Contents.json` lists, with its size in
/// pixels.
List<IosAppIcon> iosAppIcons() {
  final contents = jsonDecode(
    File('${LauncherIconSpec.iosIconSet}/Contents.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  return [
    for (final image in contents['images'] as List<dynamic>)
      if (image case {
        'size': final String size,
        'scale': final String scale,
        'filename': final String filename,
      })
        (
          filename: filename,
          pixels:
              (double.parse(size.split('x').first) *
                      int.parse(scale.replaceAll('x', '')))
                  .round(),
        ),
  ];
}
