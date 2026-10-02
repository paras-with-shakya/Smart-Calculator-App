/// What the About section says about the app itself.
///
/// [version] and [buildNumber] repeat `pubspec.yaml`'s `version:` line;
/// `test/core/app_info_test.dart` fails if the two ever differ.
abstract final class AppInfo {
  /// The version people read, such as `1.0.0`.
  static const String version = '1.0.0';

  /// The build number that follows the `+` in `pubspec.yaml`'s version.
  static const int buildNumber = 1;

  /// The version as About shows it: `1.0.0 (1)`.
  static const String displayVersion = '$version ($buildNumber)';
}
