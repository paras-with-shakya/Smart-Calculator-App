import 'package:flutter/material.dart';
import 'package:smart_calculator/app/theme/app_colors.dart';
import 'package:smart_calculator/app/theme/app_spacing.dart';
import 'package:smart_calculator/app/theme/app_typography.dart';
import 'package:smart_calculator/core/layout/layout_limits.dart';
import 'package:smart_calculator/core/widgets/app_choice_group.dart';
import 'package:smart_calculator/features/date_calculator/presentation/date_difference_tool_view.dart';
import 'package:smart_calculator/features/date_calculator/presentation/date_offset_tool_view.dart';
import 'package:smart_calculator/l10n/app_localizations.dart';

/// Which date tool is showing.
enum DateTool { difference, offset }

/// The date calculator: a choice of tool above whichever tool is selected.
///
/// One scrollable column in portrait and landscape alike, for the same
/// reason as the financial screen (DEC-052): the amount field raises the
/// system keyboard, which already covers much of a short landscape screen.
class DateCalculatorView extends StatefulWidget {
  /// Creates the date calculator screen.
  const DateCalculatorView({super.key});

  /// The widest the content column gets.
  static const double maxContentWidth = LayoutLimits.maxContentWidth;

  @override
  State<DateCalculatorView> createState() => _DateCalculatorViewState();
}

class _DateCalculatorViewState extends State<DateCalculatorView> {
  DateTool _tool = DateTool.difference;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: DateCalculatorView.maxContentWidth,
          ),
          child: Column(
            crossAxisAlignment: .stretch,
            children: [
              Text(
                l10n.dateToolPickerLabel,
                style: AppTypography.of(context).label
                    .copyWith(color: AppColors.of(context).textMuted),
              ),
              const SizedBox(height: AppSpacing.xs),
              AppChoiceGroup<DateTool>(
                options: [
                  AppChoice(
                    value: DateTool.difference,
                    label: l10n.dateToolDifference,
                  ),
                  AppChoice(value: DateTool.offset, label: l10n.dateToolOffset),
                ],
                selected: _tool,
                onChanged: (tool) => setState(() => _tool = tool),
              ),
              const SizedBox(height: AppSpacing.md),
              switch (_tool) {
                DateTool.difference => const DateDifferenceToolView(),
                DateTool.offset => const DateOffsetToolView(),
              },
            ],
          ),
        ),
      ),
    );
  }
}
