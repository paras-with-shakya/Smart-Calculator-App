import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_calculator/app/theme/app_colors.dart';
import 'package:smart_calculator/core/widgets/app_bottom_sheet.dart';
import 'package:smart_calculator/core/widgets/app_button.dart';
import 'package:smart_calculator/core/widgets/app_dialog.dart';
import 'package:smart_calculator/core/widgets/app_text_field.dart';

import '../../helpers/themed.dart';

void main() {
  /// Pumps a button that runs [open] with a context below the navigator.
  Future<void> pumpOpener(
    WidgetTester tester,
    Future<void> Function(BuildContext context) open,
  ) => pumpThemed(
    tester,
    Builder(
      builder: (context) =>
          AppButton(label: 'Open', onPressed: () => open(context)),
    ),
  );

  group('showConfirmationDialog', () {
    Future<bool?> confirmWith(
      WidgetTester tester,
      Future<void> Function() respond, {
      bool isDestructive = false,
    }) async {
      bool? result;
      await pumpOpener(tester, (context) async {
        result = await showConfirmationDialog(
          context,
          title: 'Clear all history?',
          message: 'This cannot be undone.',
          confirmLabel: 'Clear all',
          isDestructive: isDestructive,
        );
      });
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await respond();
      await tester.pumpAndSettle();
      return result;
    }

    testWidgets('returns true when confirmed', (tester) async {
      final result = await confirmWith(
        tester,
        () => tester.tap(find.text('Clear all')),
      );
      expect(result, isTrue);
    });

    testWidgets("returns false on the platform's Cancel", (tester) async {
      final result = await confirmWith(
        tester,
        () => tester.tap(find.text('Cancel')),
      );
      expect(result, isFalse);
    });

    testWidgets('returns false when dismissed', (tester) async {
      final result = await confirmWith(
        tester,
        () => tester.tapAt(const Offset(4, 4)),
      );
      expect(result, isFalse);
    });

    testWidgets('a destructive confirmation uses the error colour', (
      tester,
    ) async {
      await confirmWith(tester, () async {
        final confirm = tester.widget<AppButton>(
          find.widgetWithText(AppButton, 'Clear all'),
        );
        expect(confirm.variant, AppButtonVariant.destructive);
        final fill = tester
            .widget<Material>(
              find
                  .descendant(
                    of: find.widgetWithText(AppButton, 'Clear all'),
                    matching: find.byType(Material),
                  )
                  .first,
            )
            .color;
        expect(fill, AppColors.light.error);
        await tester.tap(find.text('Clear all'));
      }, isDestructive: true);
    });
  });

  testWidgets(
    'showAppBottomSheet shows a titled sheet and returns its result',
    (tester) async {
      String? result;
      await pumpOpener(tester, (context) async {
        result = await showAppBottomSheet<String>(
          context: context,
          title: 'Modes',
          builder: (sheetContext) => AppButton(
            label: 'Pick',
            onPressed: () => Navigator.of(sheetContext).pop('picked'),
          ),
        );
      });

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(
        tester.getSemantics(find.text('Modes')),
        isSemantics(isHeader: true),
      );
      await tester.tap(find.text('Pick'));
      await tester.pumpAndSettle();

      expect(result, 'picked');
      expect(find.byType(BottomSheet), findsNothing);
    },
  );

  group('AppTextField', () {
    testWidgets('shows its label and reports changes', (tester) async {
      final changes = <String>[];
      await pumpThemed(
        tester,
        SizedBox(
          width: 300,
          child: AppTextField(label: 'Loan amount', onChanged: changes.add),
        ),
      );

      expect(find.text('Loan amount'), findsOneWidget);
      await tester.enterText(find.byType(TextField), '2500');
      expect(changes, ['2500']);
    });

    testWidgets('shows an error in the error colour', (tester) async {
      await pumpThemed(
        tester,
        const SizedBox(
          width: 300,
          child: AppTextField(
            label: 'Interest rate',
            errorText: 'Enter a rate between 0 and 100',
          ),
        ),
      );

      final error = find.text('Enter a rate between 0 and 100');
      expect(error, findsOneWidget);
      expect(
        tester.widget<Text>(error).style?.color ??
            DefaultTextStyle.of(tester.element(error)).style.color,
        AppColors.light.error,
      );
    });
  });
}
