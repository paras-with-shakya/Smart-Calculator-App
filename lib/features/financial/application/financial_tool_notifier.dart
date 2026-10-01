import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_calculator/features/financial/domain/financial_tool.dart';
import 'package:smart_calculator/features/settings/data/preferences_settings_repository.dart';

/// Which financial tool tile is currently selected.
final NotifierProvider<FinancialToolNotifier, FinancialToolId>
financialToolProvider =
    NotifierProvider<FinancialToolNotifier, FinancialToolId>(
      FinancialToolNotifier.new,
    );

/// Holds the selected financial tool and saves every change. Mirrors
/// `AngleModeNotifier`'s shape exactly — there's no shared amount/unit
/// state to carry here either, only "which tile is selected" (DEC-052).
class FinancialToolNotifier extends Notifier<FinancialToolId> {
  @override
  FinancialToolId build() =>
      ref.watch(settingsRepositoryProvider).lastFinancialTool ??
      FinancialToolId.emi;

  /// Selects [tool] at once, then saves it.
  Future<void> selectTool(FinancialToolId tool) async {
    if (tool == state) return;
    state = tool;
    await ref.read(settingsRepositoryProvider).setLastFinancialTool(tool);
  }
}
