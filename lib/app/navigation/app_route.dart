/// A full-screen page pushed over the shell.
///
/// Calculator modes are not routes: switching modes changes state
/// (`currentModeProvider`). The class is sealed, and `AppNavigator` builds
/// each route's page with an exhaustive switch, so a route cannot be added
/// without a page.
sealed class AppRoute {
  const AppRoute();

  /// Unique route name, reported as the route's `RouteSettings.name`.
  String get name;
}

/// The calculation history page.
final class HistoryRoute extends AppRoute {
  const HistoryRoute();

  @override
  String get name => '/history';
}

/// The settings page.
final class SettingsRoute extends AppRoute {
  const SettingsRoute();

  @override
  String get name => '/settings';
}
