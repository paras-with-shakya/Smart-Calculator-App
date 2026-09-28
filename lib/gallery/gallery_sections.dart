// The component gallery is a debug-only developer tool (lib/main_gallery.dart).
// It is not part of the app, so its demo copy is not localized.
import 'package:flutter/material.dart';
import 'package:smart_calculator/app/theme/app_colors.dart';
import 'package:smart_calculator/app/theme/app_radius.dart';
import 'package:smart_calculator/app/theme/app_spacing.dart';
import 'package:smart_calculator/app/theme/app_typography.dart';
import 'package:smart_calculator/core/widgets/app_bottom_sheet.dart';
import 'package:smart_calculator/core/widgets/app_button.dart';
import 'package:smart_calculator/core/widgets/app_card.dart';
import 'package:smart_calculator/core/widgets/app_dialog.dart';
import 'package:smart_calculator/core/widgets/app_header.dart';
import 'package:smart_calculator/core/widgets/app_icon_button.dart';
import 'package:smart_calculator/core/widgets/app_text_field.dart';
import 'package:smart_calculator/core/widgets/calculator_button.dart';
import 'package:smart_calculator/core/widgets/section_header.dart';
import 'package:smart_calculator/core/widgets/status_views.dart';

/// The gallery's sections, in display order.
enum GallerySection {
  /// Colour roles.
  colors('Colours'),

  /// Text styles.
  typography('Typography'),

  /// Spacing scale and corner radii.
  spacingAndShape('Spacing and shape'),

  /// AppButton and AppIconButton.
  buttons('Buttons'),

  /// CalculatorButton kinds.
  keys('Calculator keys'),

  /// AppCard and SectionHeader.
  cards('Cards'),

  /// AppTextField.
  inputs('Text fields'),

  /// EmptyState, ErrorState and LoadingState.
  states('States'),

  /// AppHeader, AppBottomSheet and AppDialog.
  overlays('Header, sheet and dialog');

  const GallerySection(this.title);

  /// The section's heading.
  final String title;
}

/// One gallery section: its heading and its content.
class GallerySectionView extends StatelessWidget {
  /// Creates the view of [section].
  const GallerySectionView(this.section, {super.key});

  /// The section shown.
  final GallerySection section;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: .stretch,
    children: [
      SectionHeader(section.title),
      Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          AppSpacing.lg,
        ),
        child: switch (section) {
          GallerySection.colors => const _ColorsSection(),
          GallerySection.typography => const _TypographySection(),
          GallerySection.spacingAndShape => const _SpacingAndShapeSection(),
          GallerySection.buttons => const _ButtonsSection(),
          GallerySection.keys => const _KeysSection(),
          GallerySection.cards => const _CardsSection(),
          GallerySection.inputs => const _InputsSection(),
          GallerySection.states => const _StatesSection(),
          GallerySection.overlays => const _OverlaysSection(),
        },
      ),
    ],
  );
}

class _ColorsSection extends StatelessWidget {
  const _ColorsSection();

  static const double _swatchSize = 40;
  static const double _tileWidth = 172;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final typography = AppTypography.of(context);
    final roles = <(String, Color)>[
      ('background', c.background),
      ('surface', c.surface),
      ('card', c.card),
      ('surfaceMuted', c.surfaceMuted),
      ('textPrimary', c.textPrimary),
      ('textMuted', c.textMuted),
      ('primary', c.primary),
      ('onPrimary', c.onPrimary),
      ('primaryContainer', c.primaryContainer),
      ('onPrimaryContainer', c.onPrimaryContainer),
      ('secondary', c.secondary),
      ('success', c.success),
      ('warning', c.warning),
      ('error', c.error),
      ('divider', c.divider),
      ('outline', c.outline),
      ('digitKey', c.digitKey),
      ('operatorKey', c.operatorKey),
      ('onOperatorKey', c.onOperatorKey),
      ('equalsKey', c.equalsKey),
    ];
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final (name, color) in roles)
          SizedBox(
            width: _tileWidth,
            child: Row(
              children: [
                DecoratedBox(
                  decoration: ShapeDecoration(
                    color: color,
                    shape: AppRadius.shape(
                      AppRadius.sm,
                      side: BorderSide(color: c.divider),
                    ),
                  ),
                  child: const SizedBox.square(dimension: _swatchSize),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: .start,
                    children: [
                      Text(
                        name,
                        style: typography.caption.copyWith(
                          color: c.textPrimary,
                        ),
                      ),
                      Text(
                        _hex(color),
                        style: typography.caption.copyWith(color: c.textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  static String _hex(Color color) =>
      '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
}

class _TypographySection extends StatelessWidget {
  const _TypographySection();

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final c = AppColors.of(context);
    final samples = <(String, TextStyle, String)>[
      ('result · 48 · tabular', t.result, '1,234,567.89'),
      ('display · 40 · tabular', t.display, '₹ 18,420.50'),
      ('expression · 24 · tabular', t.expression, '1,250 × 12% + 7'),
      ('key · 28 · tabular', t.key, '7 8 9 ÷'),
      ('heading · 22', t.heading, 'Loan calculator'),
      ('title · 17', t.title, 'Monthly payment'),
      ('body · 16', t.body, 'Results update as you type.'),
      ('button · 16', t.button, 'Save calculation'),
      ('label · 14', t.label, 'Appearance'),
      ('caption · 13', t.caption, 'Rates are fixed for the whole term.'),
    ];
    return Column(
      crossAxisAlignment: .start,
      children: [
        for (final (name, style, sample) in samples) ...[
          Text(name, style: t.caption.copyWith(color: c.textMuted)),
          Text(sample, style: style.copyWith(color: c.textPrimary)),
          const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }
}

class _SpacingAndShapeSection extends StatelessWidget {
  const _SpacingAndShapeSection();

  static const double _barHeight = 12;
  static const double _shapeSize = 56;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final caption = AppTypography.of(context).caption
        .copyWith(color: c.textMuted);
    const spacing = <(String, double)>[
      ('xs', AppSpacing.xs),
      ('sm', AppSpacing.sm),
      ('md', AppSpacing.md),
      ('lg', AppSpacing.lg),
      ('xl', AppSpacing.xl),
      ('xxl', AppSpacing.xxl),
    ];
    const radii = <(String, double)>[
      ('sm', AppRadius.sm),
      ('md', AppRadius.md),
      ('lg', AppRadius.lg),
      ('xl', AppRadius.xl),
    ];
    return Column(
      crossAxisAlignment: .start,
      children: [
        for (final (name, value) in spacing)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: Row(
              children: [
                SizedBox(
                  width: AppSpacing.xxl,
                  child: Text('$name ${value.toInt()}', style: caption),
                ),
                Container(width: value, height: _barHeight, color: c.primary),
              ],
            ),
          ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.md,
          children: [
            for (final (name, radius) in radii)
              Column(
                children: [
                  DecoratedBox(
                    decoration: ShapeDecoration(
                      color: c.primaryContainer,
                      shape: AppRadius.shape(radius),
                    ),
                    child: const SizedBox.square(dimension: _shapeSize),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text('$name ${radius.toInt()}', style: caption),
                ],
              ),
          ],
        ),
      ],
    );
  }
}

class _ButtonsSection extends StatelessWidget {
  const _ButtonsSection();

  static void _noop() {}

  @override
  Widget build(BuildContext context) => const Column(
    crossAxisAlignment: .stretch,
    children: [
      Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: [
          AppButton(label: 'Primary', onPressed: _noop),
          AppButton(
            label: 'Secondary',
            variant: AppButtonVariant.secondary,
            onPressed: _noop,
          ),
          AppButton(
            label: 'Text',
            variant: AppButtonVariant.text,
            onPressed: _noop,
          ),
          AppButton(
            label: 'Delete',
            variant: AppButtonVariant.destructive,
            onPressed: _noop,
          ),
        ],
      ),
      SizedBox(height: AppSpacing.sm),
      Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: [
          AppButton(label: 'Disabled', onPressed: null),
          AppButton(label: 'Saving', isLoading: true, onPressed: _noop),
          AppButton(
            label: 'With icon',
            icon: Icons.bookmark_add_outlined,
            variant: AppButtonVariant.secondary,
            onPressed: _noop,
          ),
        ],
      ),
      SizedBox(height: AppSpacing.sm),
      AppButton(label: 'Full width', expand: true, onPressed: _noop),
      SizedBox(height: AppSpacing.md),
      Wrap(
        spacing: AppSpacing.sm,
        children: [
          AppIconButton(
            icon: Icons.history,
            tooltip: 'History',
            onPressed: _noop,
          ),
          AppIconButton(
            icon: Icons.content_copy_outlined,
            tooltip: 'Copy result',
            variant: AppIconButtonVariant.tonal,
            onPressed: _noop,
          ),
          AppIconButton(
            icon: Icons.delete_outline,
            tooltip: 'Delete (disabled)',
            onPressed: null,
          ),
        ],
      ),
    ],
  );
}

/// A static sample of the key tones. The working keypad is built in
/// Phase 3; these keys do nothing.
class _KeysSection extends StatelessWidget {
  const _KeysSection();

  static void _noop() {}

  static const List<List<(String, String, CalculatorButtonKind)>> _rows = [
    [
      ('AC', 'All clear', CalculatorButtonKind.function),
      ('( )', 'Brackets', CalculatorButtonKind.function),
      ('%', 'Percent', CalculatorButtonKind.function),
      ('÷', 'Divide', CalculatorButtonKind.operator),
    ],
    [
      ('7', '7', CalculatorButtonKind.digit),
      ('8', '8', CalculatorButtonKind.digit),
      ('9', '9', CalculatorButtonKind.digit),
      ('×', 'Multiply', CalculatorButtonKind.operator),
    ],
    [
      ('4', '4', CalculatorButtonKind.digit),
      ('5', '5', CalculatorButtonKind.digit),
      ('6', '6', CalculatorButtonKind.digit),
      ('−', 'Minus', CalculatorButtonKind.operator),
    ],
    [
      ('1', '1', CalculatorButtonKind.digit),
      ('2', '2', CalculatorButtonKind.digit),
      ('3', '3', CalculatorButtonKind.digit),
      ('+', 'Plus', CalculatorButtonKind.operator),
    ],
  ];

  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (final row in _rows) ...[
        _KeyRow(
          children: [
            for (final (label, semantics, kind) in row)
              CalculatorButton(
                kind: kind,
                label: label,
                semanticLabel: semantics,
                onPressed: _noop,
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
      ],
      const _KeyRow(
        children: [
          CalculatorButton(
            kind: CalculatorButtonKind.digit,
            label: '0',
            semanticLabel: '0',
            onPressed: _noop,
          ),
          CalculatorButton(
            kind: CalculatorButtonKind.digit,
            label: '.',
            semanticLabel: 'Decimal point',
            onPressed: _noop,
          ),
          CalculatorButton(
            kind: CalculatorButtonKind.function,
            icon: Icons.backspace_outlined,
            semanticLabel: 'Backspace',
            onPressed: _noop,
          ),
          CalculatorButton(
            kind: CalculatorButtonKind.equals,
            label: '=',
            semanticLabel: 'Equals',
            onPressed: _noop,
          ),
        ],
      ),
    ],
  );
}

/// Square keys in a row, separated by the standard gap.
class _KeyRow extends StatelessWidget {
  const _KeyRow({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      for (final (index, key) in children.indexed) ...[
        if (index > 0) const SizedBox(width: AppSpacing.sm),
        Expanded(child: AspectRatio(aspectRatio: 1, child: key)),
      ],
    ],
  );
}

class _CardsSection extends StatefulWidget {
  const _CardsSection();

  @override
  State<_CardsSection> createState() => _CardsSectionState();
}

class _CardsSectionState extends State<_CardsSection> {
  int _selected = 0;

  static const List<(IconData, String)> _choices = [
    (Icons.calculate_outlined, 'Basic'),
    (Icons.functions, 'Scientific'),
    (Icons.savings_outlined, 'Finance'),
  ];

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final c = AppColors.of(context);
    return Column(
      crossAxisAlignment: .stretch,
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: .start,
            children: [
              Text('Monthly payment', style: t.title),
              const SizedBox(height: AppSpacing.xs),
              Text('₹ 18,420.50', style: t.display),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Total interest ₹ 2,10,460 over 20 years',
                style: t.caption.copyWith(color: c.textMuted),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: .stretch,
            children: [
              for (final (index, (icon, label)) in _choices.indexed) ...[
                if (index > 0) const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: AppCard(
                    selected: index == _selected,
                    onTap: () => setState(() => _selected = index),
                    child: Column(
                      children: [
                        Icon(icon),
                        const SizedBox(height: AppSpacing.sm),
                        Text(label, textAlign: .center, style: t.label),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _InputsSection extends StatefulWidget {
  const _InputsSection();

  @override
  State<_InputsSection> createState() => _InputsSectionState();
}

class _InputsSectionState extends State<_InputsSection> {
  final TextEditingController _amount = TextEditingController(
    text: '25,00,000',
  );
  final TextEditingController _rate = TextEditingController(text: '8.5');

  @override
  void dispose() {
    _amount.dispose();
    _rate.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      AppTextField(
        label: 'Loan amount',
        controller: _amount,
        prefixText: '₹ ',
        helperText: 'Up to ₹ 10 crore',
        keyboardType: TextInputType.number,
      ),
      const SizedBox(height: AppSpacing.md),
      AppTextField(
        label: 'Interest rate',
        controller: _rate,
        suffixText: '%',
        errorText: 'Enter a rate between 0 and 100',
      ),
      const SizedBox(height: AppSpacing.md),
      const AppTextField(label: 'Tenure', hint: 'In years'),
      const SizedBox(height: AppSpacing.md),
      const AppTextField(label: 'Disabled', enabled: false),
    ],
  );
}

class _StatesSection extends StatelessWidget {
  const _StatesSection();

  static const double _frameHeight = 300;

  static void _noop() {}

  @override
  Widget build(BuildContext context) => const Column(
    children: [
      _StateFrame(
        child: EmptyState(
          icon: Icons.history,
          title: 'No calculations yet',
          message: 'Results you calculate appear here.',
          action: AppButton(
            label: 'Start calculating',
            variant: AppButtonVariant.secondary,
            onPressed: _noop,
          ),
        ),
      ),
      SizedBox(height: AppSpacing.sm),
      _StateFrame(
        child: ErrorState(
          title: "Couldn't load history",
          message: 'Something went wrong while reading your history.',
          action: AppButton(label: 'Try again', onPressed: _noop),
        ),
      ),
      SizedBox(height: AppSpacing.sm),
      _StateFrame(child: LoadingState(message: 'Loading history…')),
    ],
  );
}

/// A card-coloured frame of fixed height around a status view.
class _StateFrame extends StatelessWidget {
  const _StateFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => SizedBox(
    // Grows with the text size, so large-text reviews show the whole view.
    height: MediaQuery.textScalerOf(context).scale(_StatesSection._frameHeight),
    child: AppCard(padding: EdgeInsets.zero, child: child),
  );
}

class _OverlaysSection extends StatelessWidget {
  const _OverlaysSection();

  static void _noop() {}

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: .stretch,
    children: [
      const AppCard(
        padding: EdgeInsets.zero,
        child: AppHeader(
          title: Text('Header'),
          primary: false,
          automaticallyImplyLeading: false,
          actions: [
            AppIconButton(
              icon: Icons.history,
              tooltip: 'History',
              onPressed: _noop,
            ),
            AppIconButton(
              icon: Icons.settings_outlined,
              tooltip: 'Settings',
              onPressed: _noop,
            ),
          ],
        ),
      ),
      const SizedBox(height: AppSpacing.md),
      Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: [
          AppButton(
            label: 'Bottom sheet',
            variant: AppButtonVariant.secondary,
            onPressed: () => showAppBottomSheet<void>(
              context: context,
              title: 'Bottom sheet',
              builder: (sheetContext) => Column(
                crossAxisAlignment: .stretch,
                children: [
                  Text(
                    'Sheets hold short choices and details. They grow with '
                    'their content and scroll when it is taller than the '
                    'screen.',
                    style: AppTypography.of(sheetContext).body,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppButton(
                    label: 'Done',
                    expand: true,
                    onPressed: () => Navigator.of(sheetContext).pop(),
                  ),
                ],
              ),
            ),
          ),
          AppButton(
            label: 'Dialog',
            variant: AppButtonVariant.secondary,
            onPressed: () => showConfirmationDialog(
              context,
              title: 'Save calculation?',
              message: 'It will appear under Saved.',
              confirmLabel: 'Save',
            ),
          ),
          AppButton(
            label: 'Destructive dialog',
            variant: AppButtonVariant.secondary,
            onPressed: () => showConfirmationDialog(
              context,
              title: 'Clear all history?',
              message: 'This removes every saved result. It cannot be undone.',
              confirmLabel: 'Clear all',
              isDestructive: true,
            ),
          ),
        ],
      ),
    ],
  );
}
