import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_calculator/app/theme/app_spacing.dart';
import 'package:smart_calculator/features/financial/application/financial_tool_notifier.dart';
import 'package:smart_calculator/features/financial/domain/financial_tool.dart';
import 'package:smart_calculator/features/financial/presentation/compound_interest_tool_view.dart';
import 'package:smart_calculator/features/financial/presentation/discount_tool_view.dart';
import 'package:smart_calculator/features/financial/presentation/emi_tool_view.dart';
import 'package:smart_calculator/features/financial/presentation/financial_tool_picker.dart';
import 'package:smart_calculator/features/financial/presentation/gst_tool_view.dart';
import 'package:smart_calculator/features/financial/presentation/percentage_tool_view.dart';
import 'package:smart_calculator/features/financial/presentation/simple_interest_tool_view.dart';
import 'package:smart_calculator/features/financial/presentation/tip_tool_view.dart';

/// The financial calculators: a tool picker above whichever tool is
/// selected.
///
/// One scrollable column, the same in portrait and landscape — a
/// deliberate departure from the converter screen's 2-column landscape
/// split (DEC-052): every field here pops the *system* numeric keyboard
/// (there's no on-screen keypad the way Basic/Scientific/Converter have),
/// which on a real landscape phone already covers a large share of an
/// already-short screen. Forcing a 50/50 split would also leave the
/// 7-tile picker at half-width even while mid-form. A single column
/// reflows to whatever width it's given and never manufactures a cramped
/// two-column form.
class FinancialView extends ConsumerWidget {
  /// Creates the financial screen.
  const FinancialView({super.key});

  /// The widest the content column gets.
  static const double maxContentWidth = 480;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tool = ref.watch(financialToolProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: maxContentWidth),
          child: Column(
            crossAxisAlignment: .stretch,
            children: [
              const FinancialToolPicker(),
              const SizedBox(height: AppSpacing.md),
              switch (tool) {
                FinancialToolId.emi => const EmiToolView(),
                FinancialToolId.simpleInterest =>
                  const SimpleInterestToolView(),
                FinancialToolId.compoundInterest =>
                  const CompoundInterestToolView(),
                FinancialToolId.gst => const GstToolView(),
                FinancialToolId.discount => const DiscountToolView(),
                FinancialToolId.tip => const TipToolView(),
                FinancialToolId.percentage => const PercentageToolView(),
              },
            ],
          ),
        ),
      ),
    );
  }
}
