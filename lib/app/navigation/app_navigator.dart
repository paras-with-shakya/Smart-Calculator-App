import 'package:flutter/material.dart';
import 'package:smart_calculator/app/navigation/app_route.dart';
import 'package:smart_calculator/features/history/presentation/history_page.dart';
import 'package:smart_calculator/features/settings/presentation/settings_page.dart';

/// Typed navigation over the standard [Navigator].
///
/// Pages are pushed only through [pushRoute]. Going back, and closing sheets
/// or dialogs, use the standard `Navigator.pop`.
extension AppNavigator on BuildContext {
  /// Pushes the page for [route] onto the nearest navigator.
  ///
  /// [MaterialPageRoute] gives each platform its native transition, including
  /// the iOS back-swipe gesture.
  Future<T?> pushRoute<T>(AppRoute route) => Navigator.of(this).push<T>(
    MaterialPageRoute<T>(
      settings: RouteSettings(name: route.name),
      builder: (_) => _pageFor(route),
    ),
  );
}

Widget _pageFor(AppRoute route) => switch (route) {
  HistoryRoute() => const HistoryPage(),
  SettingsRoute() => const SettingsPage(),
};
