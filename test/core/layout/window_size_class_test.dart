import 'package:flutter_test/flutter_test.dart';
import 'package:smart_calculator/core/layout/window_size_class.dart';

void main() {
  test('uses the Material 3 breakpoints of 600 and 840 dp', () {
    expect(WindowSizeClass.fromWidth(0), WindowSizeClass.compact);
    expect(WindowSizeClass.fromWidth(599.9), WindowSizeClass.compact);
    expect(WindowSizeClass.fromWidth(600), WindowSizeClass.medium);
    expect(WindowSizeClass.fromWidth(839.9), WindowSizeClass.medium);
    expect(WindowSizeClass.fromWidth(840), WindowSizeClass.expanded);
    expect(WindowSizeClass.fromWidth(1600), WindowSizeClass.expanded);
  });
}
