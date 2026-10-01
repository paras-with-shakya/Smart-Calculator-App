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
import 'package:smart_calculator/core/widgets/app_choice_group.dart';
import 'package:smart_calculator/core/widgets/app_date_field.dart';
import 'package:smart_calculator/core/widgets/app_dialog.dart';
import 'package:smart_calculator/core/widgets/app_header.dart';
import 'package:smart_calculator/core/widgets/app_icon_button.dart';
import 'package:smart_calculator/core/widgets/app_text_field.dart';
import 'package:smart_calculator/core/widgets/calculator_button.dart';
import 'package:smart_calculator/core/widgets/display_text.dart';
import 'package:smart_calculator/core/widgets/result_row.dart';
import 'package:smart_calculator/core/widgets/section_header.dart';
import 'package:smart_calculator/core/widgets/share_of_whole_bar.dart';
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

  /// The scientific tray's key tones, and the 2nd toggle's selected state.
  scientificKeys('Scientific keys'),

  /// DisplayText: shrinking, wrapping and the caret.
  display('Display text'),

  /// AppCard and SectionHeader.
  cards('Cards'),

  /// AppTextField and AppChoiceGroup.
  inputs('Inputs and choices'),

  /// EmptyState, ErrorState and LoadingState.
  states('States'),

  /// AppHeader, AppBottomSheet and AppDialog.
  overlays('Header, sheet and dialog'),

  /// The converter's category tiles and a From/To card pair.
  converter('Converter'),

  /// The financial tool picker and a ShareOfWholeBar sample.
  financial('Financial'),

  /// A date field and a result card.
  date('Date');

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
          GallerySection.scientificKeys => const _ScientificKeysSection(),
          GallerySection.display => const _DisplaySection(),
          GallerySection.cards => const _CardsSection(),
          GallerySection.inputs => const _InputsSection(),
          GallerySection.states => const _StatesSection(),
          GallerySection.overlays => const _OverlaysSection(),
          GallerySection.converter => const _ConverterSection(),
          GallerySection.financial => const _FinancialSection(),
          GallerySection.date => const _DateSection(),
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

/// A static sample of the key tones, with the memory row above. The working
/// keypad is `CalculatorKeypad`; these keys do nothing.
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

  static const List<(String, String)> _memoryKeys = [
    ('MC', 'Memory clear'),
    ('MR', 'Memory recall'),
    ('M+', 'Memory add'),
    ('M−', 'Memory subtract'),
    ('MS', 'Memory store'),
  ];

  @override
  Widget build(BuildContext context) => Column(
    children: [
      SizedBox(
        height: kMinInteractiveDimension,
        child: Row(
          children: [
            for (final (index, (label, semantics)) in _memoryKeys.indexed) ...[
              if (index > 0) const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: CalculatorButton(
                  kind: CalculatorButtonKind.memory,
                  label: label,
                  semanticLabel: semantics,
                  // MC and MR are shown disabled, as with an empty memory.
                  onPressed: index < 2 ? null : _noop,
                ),
              ),
            ],
          ],
        ),
      ),
      const SizedBox(height: AppSpacing.sm),
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

/// A static sample of the scientific tray's key tones, plus the DEG/RAD
/// and 2nd toggles (both states, so the 2nd-selected tone is checked
/// against the guidelines in every theme). The working tray is
/// `ScientificFunctionTray`; these keys do nothing.
class _ScientificKeysSection extends StatelessWidget {
  const _ScientificKeysSection();

  static void _noop() {}

  static const List<(String, String)> _sample = [
    ('sin', 'Sine'),
    ('cos', 'Cosine'),
    ('√', 'Square root'),
    ('log', 'Log base 10'),
    ('π', 'Pi'),
  ];

  @override
  Widget build(BuildContext context) => Column(
    children: [
      const _KeyRow(
        children: [
          CalculatorButton(
            kind: CalculatorButtonKind.function,
            label: 'DEG',
            semanticLabel: 'Angle mode, degrees',
            onPressed: _noop,
          ),
          CalculatorButton(
            kind: CalculatorButtonKind.function,
            label: '2nd',
            semanticLabel: 'Second function',
            onPressed: _noop,
          ),
          CalculatorButton(
            kind: CalculatorButtonKind.function,
            label: '2nd',
            semanticLabel: 'Second function (selected)',
            selected: true,
            onPressed: _noop,
          ),
        ],
      ),
      const SizedBox(height: AppSpacing.sm),
      _KeyRow(
        children: [
          for (final (label, semantics) in _sample)
            CalculatorButton(
              kind: CalculatorButtonKind.function,
              label: label,
              semanticLabel: semantics,
              onPressed: _noop,
            ),
        ],
      ),
    ],
  );
}

/// DisplayText lines as the calculator display uses them.
class _DisplaySection extends StatelessWidget {
  const _DisplaySection();

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final typography = AppTypography.of(context);
    return AppCard(
      child: Column(
        crossAxisAlignment: .stretch,
        children: [
          Text('Full size', style: typography.caption),
          DisplayText(
            '1,234×5',
            style: typography.result,
            color: colors.textPrimary,
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Shrinks to fit', style: typography.caption),
          DisplayText(
            '12,34,56,789×9,87,654',
            style: typography.result,
            color: colors.textPrimary,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Wraps after an operator at half size',
            style: typography.caption,
          ),
          DisplayText(
            '12,34,56,78,90,123×​98,76,54,32,10,987+​12,345',
            style: typography.result,
            color: colors.textPrimary,
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Caret', style: typography.caption),
          DisplayText(
            '12,345+678',
            style: typography.result,
            color: colors.textPrimary,
            caretOffset: 4,
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Preview and error', style: typography.caption),
          DisplayText(
            '13,023',
            style: typography.expression,
            color: colors.textMuted,
          ),
          DisplayText(
            "Can't divide by zero",
            style: typography.expression,
            color: colors.error,
          ),
        ],
      ),
    );
  }
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
  String _period = 'month';

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
      const SizedBox(height: AppSpacing.md),
      AppChoiceGroup<String>(
        options: const [
          AppChoice(value: 'week', label: 'Week'),
          AppChoice(value: 'month', label: 'Month'),
          AppChoice(value: 'year', label: 'Year'),
        ],
        selected: _period,
        onChanged: (value) => setState(() => _period = value),
      ),
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

/// A static sample of the converter's category tiles and a From/To card
/// pair. The working screen is `ConverterView`; these do nothing.
class _ConverterSection extends StatelessWidget {
  const _ConverterSection();

  static void _noop() {}

  static const double _tileWidth = 96;

  static const List<(IconData, String)> _categories = [
    (Icons.straighten, 'Length'),
    (Icons.scale, 'Weight'),
    (Icons.thermostat, 'Temperature'),
    (Icons.crop_square, 'Area'),
    (Icons.local_drink_outlined, 'Volume'),
    (Icons.schedule, 'Time'),
    (Icons.currency_exchange, 'Currency'),
  ];

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    return Column(
      crossAxisAlignment: .stretch,
      children: [
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final (index, (icon, label)) in _categories.indexed)
              SizedBox(
                width: _tileWidth,
                child: AppCard(
                  selected: index == 0,
                  onTap: _noop,
                  child: Column(
                    children: [
                      Icon(icon),
                      const SizedBox(height: AppSpacing.xs),
                      Text(label, textAlign: .center, style: t.label),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        AppCard(
          onTap: _noop,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: .start,
                  children: [
                    Text('From', style: t.caption),
                    const SizedBox(height: AppSpacing.xs),
                    Text('5', style: t.display),
                    const SizedBox(height: AppSpacing.xs),
                    Text('m', style: t.label),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        const Center(
          child: AppIconButton(
            icon: Icons.swap_horiz,
            tooltip: 'Swap units',
            variant: AppIconButtonVariant.tonal,
            onPressed: _noop,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        AppCard(
          onTap: _noop,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: .start,
                  children: [
                    Text('To', style: t.caption),
                    const SizedBox(height: AppSpacing.xs),
                    Text('0.005', style: t.display),
                    const SizedBox(height: AppSpacing.xs),
                    Text('km', style: t.label),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A static sample of the financial tool picker and a `ShareOfWholeBar`
/// (EMI's principal-vs-interest split). The working screen is
/// `FinancialView`; these tiles do nothing.
class _FinancialSection extends StatelessWidget {
  const _FinancialSection();

  static void _noop() {}

  static const List<(IconData, String)> _tools = [
    (Icons.payments_outlined, 'EMI'),
    (Icons.trending_up, 'Simple interest'),
    (Icons.show_chart, 'Compound interest'),
    (Icons.receipt_long_outlined, 'GST'),
    (Icons.sell_outlined, 'Discount'),
    (Icons.room_service_outlined, 'Tip'),
    (Icons.percent, 'Percentage'),
  ];

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    return Column(
      crossAxisAlignment: .stretch,
      children: [
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final (index, (icon, label)) in _tools.indexed)
              SizedBox(
                width: 96,
                child: AppCard(
                  selected: index == 0,
                  onTap: _noop,
                  child: Column(
                    children: [
                      Icon(icon),
                      const SizedBox(height: AppSpacing.xs),
                      Text(label, textAlign: .center, style: t.label),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        AppCard(
          child: Column(
            crossAxisAlignment: .start,
            children: [
              Text('Monthly EMI', style: t.caption),
              const SizedBox(height: AppSpacing.xs),
              Text('₹8,791.59', style: t.display),
              const SizedBox(height: AppSpacing.md),
              const ShareOfWholeBar(
                baseLabel: 'Principal',
                baseValue: 100000,
                baseValueText: '₹1,00,000.00',
                addedLabel: 'Interest',
                addedValue: 5499.08,
                addedValueText: '₹5,499.08',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A sample date field (which opens the real calendar picker) and a result
/// card built from `ResultRow`s. The working screen is `DateCalculatorView`.
class _DateSection extends StatefulWidget {
  const _DateSection();

  @override
  State<_DateSection> createState() => _DateSectionState();
}

class _DateSectionState extends State<_DateSection> {
  DateTime _date = DateTime.utc(2026, 3, 8);

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: .stretch,
    children: [
      AppDateField(
        label: 'Start date',
        value: _date,
        format: (date) =>
            '${date.year}-${date.month.toString().padLeft(2, '0')}-'
            '${date.day.toString().padLeft(2, '0')}',
        pickerHelpText: 'Select date',
        firstDate: DateTime.utc(1900),
        lastDate: DateTime.utc(2200, 12, 31),
        onChanged: (date) => setState(() => _date = date),
      ),
      const SizedBox(height: AppSpacing.md),
      const AppCard(
        child: Column(
          crossAxisAlignment: .stretch,
          children: [
            ResultRow(
              label: 'Difference',
              value: '1 year, 2 months, 3 days',
              emphasized: true,
              wrapValue: true,
            ),
            ResultRow(label: 'Total days', value: '428 days'),
          ],
        ),
      ),
    ],
  );
}
