import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_calculator/core/persistence/preferences.dart';
import 'package:smart_calculator/features/financial/application/financial_tool_notifier.dart';
import 'package:smart_calculator/features/financial/domain/financial_tool.dart';

import '../../../helpers/test_app.dart';

void main() {
  late SharedPreferencesWithCache preferences;
  late ProviderContainer container;

  ProviderContainer newContainer() => ProviderContainer.test(
    overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
  );

  setUp(() async {
    useInMemoryPreferences();
    preferences = await openPreferences();
    container = newContainer();
  });

  FinancialToolNotifier notifier() =>
      container.read(financialToolProvider.notifier);

  test('defaults to EMI when nothing is saved', () {
    expect(container.read(financialToolProvider), FinancialToolId.emi);
  });

  test('selectTool updates the state', () async {
    await notifier().selectTool(FinancialToolId.gst);

    expect(container.read(financialToolProvider), FinancialToolId.gst);
  });

  test('a fresh container picks up the saved tool after a restart', () async {
    await notifier().selectTool(FinancialToolId.tip);

    final restarted = newContainer();
    addTearDown(restarted.dispose);

    expect(restarted.read(financialToolProvider), FinancialToolId.tip);
  });
}
