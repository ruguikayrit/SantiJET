import 'package:flutter/material.dart';
import 'package:santijet_demir/core/theme/app_colors.dart';
import 'package:santijet_demir/data/services/rebar_weight_calculator.dart';
import 'package:santijet_demir/core/theme/app_radii.dart';
import 'package:santijet_demir/core/theme/app_typography.dart';
import 'package:santijet_demir/domain/tahvil/tahvil_calculator_modes.dart';
import 'package:santijet_demir/domain/tahvil/tahvil_rules.dart';

enum _FieldAccent { source, target }

class TahvilCalculatorSection extends StatefulWidget {
  const TahvilCalculatorSection({super.key, this.hideHeader = false});

  final bool hideHeader;

  @override
  State<TahvilCalculatorSection> createState() => _TahvilCalculatorSectionState();
}

class _TahvilCalculatorSectionState extends State<TahvilCalculatorSection> {
  TahvilCalculatorBasis _basis = TahvilCalculatorBasis.spacing;
  TahvilQuantityKind _quantityKind = TahvilQuantityKind.single;

  final _spacingSource = _DiameterSpacingFields();
  final _singleSource = _DiameterQuantityFields();
  final _dualSourceA = _DiameterQuantityFields();
  final _dualSourceB = _DiameterQuantityFields();
  final _dualTargetA = _DiameterQuantityFields();
  final _dualTargetB = _DiameterQuantityFields();

  @override
  void dispose() {
    _spacingSource.dispose();
    _singleSource.dispose();
    _dualSourceA.dispose();
    _dualSourceB.dispose();
    _dualTargetA.dispose();
    _dualTargetB.dispose();
    super.dispose();
  }

  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!widget.hideHeader) ...[
          Text('Tahvil Hesaplayıcı', style: AppTypography.headlineMedium),
          const SizedBox(height: 4),
          Text(
            'Aralığa veya adede göre donatı tahvili — Excel tablosu ile aynı mantık.',
            style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: 14),
        ],
        _ModeSegmentedControl<TahvilCalculatorBasis>(
          values: TahvilCalculatorBasis.values,
          selected: _basis,
          labelBuilder: (value) => value.label,
          onSelected: (value) => setState(() => _basis = value),
        ),
        if (_basis == TahvilCalculatorBasis.quantity) ...[
          const SizedBox(height: 10),
          _ModeSegmentedControl<TahvilQuantityKind>(
            values: TahvilQuantityKind.values,
            selected: _quantityKind,
            labelBuilder: (value) => value.label,
            onSelected: (value) => setState(() => _quantityKind = value),
            compact: true,
          ),
        ],
        const SizedBox(height: 14),
        _TahvilRulesHint(basis: _basis, quantityKind: _quantityKind),
        const SizedBox(height: 12),
        switch (_basis) {
          TahvilCalculatorBasis.spacing => _SpacingModePanel(
              fields: _spacingSource,
              onChanged: _refresh,
            ),
          TahvilCalculatorBasis.quantity =>
            _quantityKind == TahvilQuantityKind.single
                ? _SingleQuantityModePanel(
                    fields: _singleSource,
                    onChanged: _refresh,
                  )
                : _DualQuantityModePanel(
                    sourceA: _dualSourceA,
                    sourceB: _dualSourceB,
                    targetA: _dualTargetA,
                    targetB: _dualTargetB,
                    onChanged: _refresh,
                  ),
        },
      ],
    );
  }
}

class _ModeSegmentedControl<T> extends StatelessWidget {
  const _ModeSegmentedControl({
    required this.values,
    required this.selected,
    required this.labelBuilder,
    required this.onSelected,
    this.compact = false,
  });

  final List<T> values;
  final T selected;
  final String Function(T value) labelBuilder;
  final ValueChanged<T> onSelected;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.canvas,
        borderRadius: AppRadii.md,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          for (var i = 0; i < values.length; i++) ...[
            if (i > 0) const SizedBox(width: 4),
            Expanded(
              child: _ModeSegmentButton(
                label: labelBuilder(values[i]),
                selected: values[i] == selected,
                compact: compact,
                onTap: () => onSelected(values[i]),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ModeSegmentButton extends StatelessWidget {
  const _ModeSegmentButton({
    required this.label,
    required this.selected,
    required this.onTap,
    this.compact = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? AppColors.electricBlueLight.withValues(alpha: 0.18)
          : Colors.transparent,
      borderRadius: AppRadii.sm,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.sm,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 8 : 10,
            vertical: compact ? 10 : 12,
          ),
          decoration: BoxDecoration(
            borderRadius: AppRadii.sm,
            border: Border.all(
              color: selected
                  ? AppColors.electricBlueLight.withValues(alpha: 0.55)
                  : Colors.transparent,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: (compact ? AppTypography.labelMedium : AppTypography.bodyMedium)
                .copyWith(
              color: selected ? AppColors.electricBlueLight : AppColors.textMuted,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _TahvilRulesHint extends StatelessWidget {
  const _TahvilRulesHint({
    required this.basis,
    required this.quantityKind,
  });

  final TahvilCalculatorBasis basis;
  final TahvilQuantityKind quantityKind;

  @override
  Widget build(BuildContext context) {
    final description = switch (basis) {
      TahvilCalculatorBasis.spacing =>
        'Kaynak çap ve aralığı girin. Hedef çapta eşdeğer aralık ve As (mm²/m) hesaplanır.',
      TahvilCalculatorBasis.quantity =>
        quantityKind == TahvilQuantityKind.single
            ? 'Kaynak adet ve çap girin. Hedef çapta eşdeğer adet ve kesit alanı gösterilir.'
            : 'İki kaynak ve iki hedef satırı girin. Toplam kesit alanı mukayese edilir.',
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: AppRadii.sm,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(description, style: AppTypography.bodySmall),
          const SizedBox(height: 6),
          Text(
            'Kurallar: ±$tahvilMaxDiameterDiffMm mm çap · '
            '≤${tahvilMaxSpacingCm.toStringAsFixed(0)} cm aralık · '
            '≤%${(tahvilMaxAreaDeviationRatio * 100).toStringAsFixed(0)} kesit sapması',
            style: AppTypography.labelSmall.copyWith(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

class _SpacingModePanel extends StatelessWidget {
  const _SpacingModePanel({
    required this.fields,
    required this.onChanged,
  });

  final _DiameterSpacingFields fields;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final diameter = fields.diameter;
    final spacingMm = fields.spacingMm;
    final isReady = diameter != null && spacingMm != null;
    final results = isReady
        ? computeSpacingTahvilResults(
            sourceDiameter: diameter!,
            sourceSpacingMm: spacingMm!,
          )
        : const <TahvilSpacingResult>[];
    final allowed = results.where((item) => item.isAllowed).toList();
    final sourceAs = isReady
        ? computeAsPerMeterMm2(diameter!, spacingMm!)
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ExcelStyleTable(
          title: 'Kaynak donatı',
          accentColor: AppColors.warning,
          children: [
            _InputRow(
              labels: const ['ÇAP (mm)', 'ARALIK (mm)'],
              fields: [
                _NumericField(
                  controller: fields.diameterController,
                  hint: '16',
                  onChanged: onChanged,
                ),
                _NumericField(
                  controller: fields.spacingController,
                  hint: '250',
                  decimal: true,
                  onChanged: onChanged,
                ),
              ],
            ),
          ],
        ),
        if (sourceAs != null) ...[
          const SizedBox(height: 8),
          _AsBadge(
            label: 'Kaynak As',
            value: '${formatAreaMm2(sourceAs)} mm²/m',
          ),
        ],
        if (!isReady) ...[
          const SizedBox(height: 12),
          Text(
            'Hesap için çap ve aralık alanlarını doldurun.',
            style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
          ),
        ] else if (results.isEmpty) ...[
          const SizedBox(height: 12),
          Text(
            'Girilen değerler için tahvil hesabı yapılamadı.',
            style: AppTypography.bodySmall.copyWith(color: AppColors.critical),
          ),
        ] else ...[
          const SizedBox(height: 14),
          Text('Hedef tahvil seçenekleri', style: AppTypography.titleMedium),
          const SizedBox(height: 8),
          ...results.map(
            (result) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _SpacingResultCard(
                sourceDiameter: diameter!,
                sourceSpacingMm: spacingMm!,
                result: result,
                isOptimal: allowed.isNotEmpty &&
                    result.isAllowed &&
                    result.targetDiameter == allowed.first.targetDiameter,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _SingleQuantityModePanel extends StatelessWidget {
  const _SingleQuantityModePanel({
    required this.fields,
    required this.onChanged,
  });

  final _DiameterQuantityFields fields;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final diameter = fields.diameter;
    final quantity = fields.quantity;
    final isReady = diameter != null && quantity != null;
    final results = isReady
        ? computeSingleQuantityTahvilResults(
            sourceDiameter: diameter!,
            sourceQuantity: quantity!,
          )
        : const <TahvilSingleQuantityResult>[];
    final allowed = results.where((item) => item.isAllowed).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ExcelStyleTable(
          title: 'Kaynak donatı',
          accentColor: AppColors.warning,
          children: [
            _InputRow(
              labels: const ['ADET', 'ÇAP (mm)'],
              fields: [
                _NumericField(
                  controller: fields.quantityController,
                  hint: '3',
                  onChanged: onChanged,
                ),
                _NumericField(
                  controller: fields.diameterController,
                  hint: '16',
                  onChanged: onChanged,
                ),
              ],
            ),
          ],
        ),
        if (!isReady) ...[
          const SizedBox(height: 12),
          Text(
            'Hesap için adet ve çap alanlarını doldurun.',
            style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
          ),
        ] else if (results.isEmpty) ...[
          const SizedBox(height: 12),
          Text(
            'Girilen değerler için tahvil hesabı yapılamadı.',
            style: AppTypography.bodySmall.copyWith(color: AppColors.critical),
          ),
        ] else ...[
          const SizedBox(height: 8),
          _AsBadge(
            label: 'Kaynak As',
            value:
                '${formatAreaMm2(crossSectionAreaMm2(diameter!) * quantity!)} mm²',
          ),
          const SizedBox(height: 14),
          Text('Hedef tahvil seçenekleri', style: AppTypography.titleMedium),
          const SizedBox(height: 8),
          ...results.map(
            (result) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _SingleQuantityResultCard(
                sourceDiameter: diameter!,
                sourceQuantity: quantity!,
                result: result,
                isOptimal: allowed.isNotEmpty &&
                    result.isAllowed &&
                    result.targetDiameter == allowed.first.targetDiameter,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _DualQuantityModePanel extends StatefulWidget {
  const _DualQuantityModePanel({
    required this.sourceA,
    required this.sourceB,
    required this.targetA,
    required this.targetB,
    required this.onChanged,
  });

  final _DiameterQuantityFields sourceA;
  final _DiameterQuantityFields sourceB;
  final _DiameterQuantityFields targetA;
  final _DiameterQuantityFields targetB;
  final VoidCallback onChanged;

  @override
  State<_DualQuantityModePanel> createState() => _DualQuantityModePanelState();
}

class _DualQuantityModePanelState extends State<_DualQuantityModePanel> {
  String? _selectedSuggestionId;
  bool _manualEntry = false;

  _DiameterQuantityFields get sourceA => widget.sourceA;
  _DiameterQuantityFields get sourceB => widget.sourceB;
  _DiameterQuantityFields get targetA => widget.targetA;
  _DiameterQuantityFields get targetB => widget.targetB;

  bool get _sourceReady =>
      sourceA.quantity != null &&
      sourceA.diameter != null &&
      sourceB.quantity != null &&
      sourceB.diameter != null;

  List<TahvilDualSuggestion> get _suggestions {
    if (!_sourceReady) return const [];
    return computeDualQuantityTahvilSuggestions(
      sourceQuantityA: sourceA.quantity!,
      sourceDiameterA: sourceA.diameter!,
      sourceQuantityB: sourceB.quantity!,
      sourceDiameterB: sourceB.diameter!,
    );
  }

  TahvilDualQuantityComparison? get _manualComparison {
    final values = [
      sourceA.quantity,
      sourceA.diameter,
      sourceB.quantity,
      sourceB.diameter,
      targetA.quantity,
      targetA.diameter,
      targetB.quantity,
      targetB.diameter,
    ];
    if (values.any((value) => value == null)) return null;

    return computeDualQuantityComparison(
      sourceQuantityA: sourceA.quantity!,
      sourceDiameterA: sourceA.diameter!,
      sourceQuantityB: sourceB.quantity!,
      sourceDiameterB: sourceB.diameter!,
      targetQuantityA: targetA.quantity!,
      targetDiameterA: targetA.diameter!,
      targetQuantityB: targetB.quantity!,
      targetDiameterB: targetB.diameter!,
    );
  }

  void _handleSourceChanged() {
    _selectedSuggestionId = null;
    widget.onChanged();
  }

  void _applySuggestion(TahvilDualSuggestion suggestion) {
    targetA.setValues(
      quantity: suggestion.legA.targetQuantity,
      diameter: suggestion.legA.targetDiameter,
    );
    targetB.setValues(
      quantity: suggestion.legB.targetQuantity,
      diameter: suggestion.legB.targetDiameter,
    );
    setState(() {
      _selectedSuggestionId = suggestion.id;
      _manualEntry = true;
    });
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final suggestions = _suggestions;
    final allowedSuggestions =
        suggestions.where((item) => item.isAllowed).toList();
    final manualComparison = _manualComparison;
    final sourceArea = _sourceReady
        ? crossSectionAreaMm2(sourceA.diameter!) * sourceA.quantity! +
            crossSectionAreaMm2(sourceB.diameter!) * sourceB.quantity!
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ExcelStyleTable(
          title: 'Kaynak donatı',
          accentColor: AppColors.warning,
          children: [
            _DualInputRow(
              rowLabel: '1. çeşit',
              fields: sourceA,
              accent: _FieldAccent.source,
              onChanged: _handleSourceChanged,
            ),
            const SizedBox(height: 6),
            _DualInputRow(
              rowLabel: '2. çeşit',
              fields: sourceB,
              accent: _FieldAccent.source,
              onChanged: _handleSourceChanged,
            ),
          ],
        ),
        if (sourceArea != null) ...[
          const SizedBox(height: 8),
          _AsBadge(
            label: 'Kaynak As',
            value: '${formatAreaMm2(sourceArea)} mm²',
          ),
        ],
        if (!_sourceReady) ...[
          const SizedBox(height: 12),
          Text(
            'Tahvil önerileri için kaynak adet ve çap alanlarını doldurun.',
            style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
          ),
        ] else ...[
          const SizedBox(height: 14),
          Row(
            children: [
              Icon(
                Icons.arrow_downward,
                size: 18,
                color: AppColors.electricBlueLight.withValues(alpha: 0.8),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Hedef tahvil',
                  style: AppTypography.titleMedium.copyWith(
                    color: AppColors.electricBlueLight,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (suggestions.isEmpty)
            Text(
              'Kaynak veriler için kurala uygun tahvil önerisi bulunamadı.',
              style: AppTypography.bodySmall.copyWith(color: AppColors.critical),
            )
          else ...[
            Text('Tahvil önerileri', style: AppTypography.labelMedium),
            const SizedBox(height: 4),
            Text(
              'Öneriye dokunarak hedef alanları doldurun veya manuel giriş yapın.',
              style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: 8),
            ...suggestions.map(
              (suggestion) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _DualSuggestionCard(
                  suggestion: suggestion,
                  selected: _selectedSuggestionId == suggestion.id,
                  isOptimal: allowedSuggestions.isNotEmpty &&
                      suggestion.isAllowed &&
                      suggestion.id == allowedSuggestions.first.id,
                  onTap: () => _applySuggestion(suggestion),
                ),
              ),
            ),
          ],
          const SizedBox(height: 10),
          _ManualTargetToggle(
            expanded: _manualEntry,
            onChanged: (value) => setState(() => _manualEntry = value),
          ),
          if (_manualEntry) ...[
            const SizedBox(height: 8),
            _ExcelStyleTable(
              title: 'Manuel hedef donatı',
              accentColor: AppColors.electricBlueLight,
              children: [
                _DualManualTargetRow(
                  rowLabel: '1. çeşit',
                  fields: targetA,
                  sourceDiameter: sourceA.diameter,
                  onChanged: () {
                    _selectedSuggestionId = null;
                    widget.onChanged();
                  },
                ),
                const SizedBox(height: 8),
                _DualManualTargetRow(
                  rowLabel: '2. çeşit',
                  fields: targetB,
                  sourceDiameter: sourceB.diameter,
                  onChanged: () {
                    _selectedSuggestionId = null;
                    widget.onChanged();
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (manualComparison == null)
              Text(
                'Mukayese için hedef adet ve çap alanlarını doldurun.',
                style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
              )
            else
              _DualComparisonCard(comparison: manualComparison),
          ],
        ],
      ],
    );
  }
}

class _ManualTargetToggle extends StatelessWidget {
  const _ManualTargetToggle({
    required this.expanded,
    required this.onChanged,
  });

  final bool expanded;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => onChanged(!expanded),
      icon: Icon(
        expanded ? Icons.edit_outlined : Icons.edit_note_outlined,
        size: 18,
      ),
      label: Text(
        expanded ? 'Manuel girişi gizle' : 'Manuel hedef girişi',
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.electricBlueLight,
        side: BorderSide(
          color: AppColors.electricBlueLight.withValues(alpha: 0.45),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }
}

class _DualSuggestionCard extends StatelessWidget {
  const _DualSuggestionCard({
    required this.suggestion,
    required this.selected,
    required this.isOptimal,
    required this.onTap,
  });

  final TahvilDualSuggestion suggestion;
  final bool selected;
  final bool isOptimal;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final comparison = suggestion.comparison;
    final accent = suggestion.isAllowed ? AppColors.success : AppColors.warning;

    return Material(
      color: selected
          ? AppColors.electricBlueLight.withValues(alpha: 0.1)
          : suggestion.isAllowed
              ? AppColors.success.withValues(alpha: 0.05)
              : AppColors.surfaceElevated,
      borderRadius: AppRadii.md,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.md,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: AppRadii.md,
            border: Border.all(
              color: selected
                  ? AppColors.electricBlueLight.withValues(alpha: 0.55)
                  : accent.withValues(alpha: 0.35),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      suggestion.summary,
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (isOptimal)
                    const _StatusBadge(label: 'Optimum', color: AppColors.success)
                  else if (!suggestion.isAllowed)
                    const _StatusBadge(
                      label: 'Uygun değil',
                      color: AppColors.warning,
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Hedef As: ${formatAreaMm2(comparison.targetAreaMm2)} mm² · '
                'Sapma %${comparison.areaDeviationPercent.toStringAsFixed(2)}',
                style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
              ),
              if (selected) ...[
                const SizedBox(height: 4),
                Text(
                  'Seçili öneri — hedef alanlara uygulandı',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.electricBlueLight,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DualManualTargetRow extends StatelessWidget {
  const _DualManualTargetRow({
    required this.rowLabel,
    required this.fields,
    required this.sourceDiameter,
    required this.onChanged,
  });

  final String rowLabel;
  final _DiameterQuantityFields fields;
  final int? sourceDiameter;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final diameter = fields.diameter;
    final diameterValid = isStandardTahvilDiameter(diameter);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            SizedBox(
              width: 56,
              child: Text(
                rowLabel,
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ),
            Expanded(
              child: _InputRow(
                labels: const ['ADET', 'ÇAP (mm)'],
                fields: [
                  _NumericField(
                    controller: fields.quantityController,
                    hint: '5',
                    accent: _FieldAccent.target,
                    onChanged: onChanged,
                  ),
                  _NumericField(
                    controller: fields.diameterController,
                    hint: '14',
                    accent: _FieldAccent.target,
                    onChanged: onChanged,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final option in RebarWeightCalculator.standardDiameters)
              _DiameterChip(
                diameter: option,
                selected: diameter == option,
                enabled: sourceDiameter == null ||
                    option == sourceDiameter ||
                    isTahvilDiameterAllowed(sourceDiameter!, option),
                onTap: () {
                  fields.setDiameter(option);
                  onChanged();
                },
              ),
          ],
        ),
        if (diameter != null && !diameterValid) ...[
          const SizedBox(height: 4),
          Text(
            'Standart çap değil. Önerilen: '
            '${RebarWeightCalculator.standardDiameters.join(', ')} mm',
            style: AppTypography.labelSmall.copyWith(color: AppColors.warning),
          ),
        ],
      ],
    );
  }
}

class _DiameterChip extends StatelessWidget {
  const _DiameterChip({
    required this.diameter,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final int diameter;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = enabled
        ? AppColors.diameterColor(diameter)
        : AppColors.textDisabled;

    return Material(
      color: selected
          ? color.withValues(alpha: 0.2)
          : AppColors.canvas,
      borderRadius: AppRadii.full,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: AppRadii.full,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: AppRadii.full,
            border: Border.all(
              color: selected
                  ? color.withValues(alpha: 0.7)
                  : AppColors.border,
            ),
          ),
          child: Text(
            'Ø$diameter',
            style: AppTypography.labelSmall.copyWith(
              color: enabled ? color : AppColors.textDisabled,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}


class _ExcelStyleTable extends StatelessWidget {
  const _ExcelStyleTable({
    required this.title,
    required this.accentColor,
    required this.children,
  });

  final String title;
  final Color accentColor;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: AppRadii.md,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
              border: Border(
                bottom: BorderSide(color: accentColor.withValues(alpha: 0.25)),
              ),
            ),
            child: Text(
              title,
              style: AppTypography.labelMedium.copyWith(color: accentColor),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }
}

class _InputRow extends StatelessWidget {
  const _InputRow({
    required this.labels,
    required this.fields,
  });

  final List<String> labels;
  final List<Widget> fields;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < labels.length; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          Expanded(
            child: Column(
              children: [
                Text(
                  labels[i],
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textMuted,
                    fontSize: 10,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                fields[i],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _DualInputRow extends StatelessWidget {
  const _DualInputRow({
    required this.rowLabel,
    required this.fields,
    required this.onChanged,
    this.accent = _FieldAccent.source,
  });

  final String rowLabel;
  final _DiameterQuantityFields fields;
  final VoidCallback onChanged;
  final _FieldAccent accent;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 56,
          child: Text(
            rowLabel,
            style: AppTypography.labelSmall.copyWith(color: AppColors.textMuted),
          ),
        ),
        Expanded(
          child: _InputRow(
            labels: const ['ADET', 'ÇAP (mm)'],
            fields: [
              _NumericField(
                controller: fields.quantityController,
                hint: '3',
                accent: accent,
                onChanged: onChanged,
              ),
              _NumericField(
                controller: fields.diameterController,
                hint: '16',
                accent: accent,
                onChanged: onChanged,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _NumericField extends StatelessWidget {
  const _NumericField({
    required this.controller,
    required this.hint,
    required this.onChanged,
    this.decimal = false,
    this.accent = _FieldAccent.source,
  });

  final TextEditingController controller;
  final String hint;
  final VoidCallback onChanged;
  final bool decimal;
  final _FieldAccent accent;

  @override
  Widget build(BuildContext context) {
    final fieldColor = accent == _FieldAccent.source
        ? AppColors.warning
        : AppColors.electricBlueLight;

    return TextField(
      controller: controller,
      keyboardType: decimal
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.number,
      textAlign: TextAlign.center,
      style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: fieldColor.withValues(alpha: 0.12),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadii.sm,
          borderSide: BorderSide(
            color: fieldColor.withValues(alpha: 0.45),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadii.sm,
          borderSide: BorderSide(
            color: fieldColor.withValues(alpha: 0.8),
            width: 1.5,
          ),
        ),
      ),
      onChanged: (_) => onChanged(),
    );
  }
}

class _AsBadge extends StatelessWidget {
  const _AsBadge({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.canvas,
        borderRadius: AppRadii.sm,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Text(label, style: AppTypography.labelMedium),
          const Spacer(),
          Text(
            value,
            style: AppTypography.titleMedium.copyWith(
              color: AppColors.electricBlueLight,
            ),
          ),
        ],
      ),
    );
  }
}

class _SpacingResultCard extends StatelessWidget {
  const _SpacingResultCard({
    required this.sourceDiameter,
    required this.sourceSpacingMm,
    required this.result,
    required this.isOptimal,
  });

  final int sourceDiameter;
  final double sourceSpacingMm;
  final TahvilSpacingResult result;
  final bool isOptimal;

  @override
  Widget build(BuildContext context) {
    return _ResultCardShell(
      title: 'Ø$sourceDiameter @ ${formatSpacingMm(sourceSpacingMm)} mm  →  '
          'Ø${result.targetDiameter} @ ${formatSpacingMm(result.resultingSpacingMm)} mm',
      isAllowed: result.isAllowed,
      isOptimal: isOptimal,
      rejectReason: result.rejectReason,
      targetDiameter: result.targetDiameter,
      children: [
        Text(
          'As = ${formatAreaMm2(result.asPerMeterMm2)} mm²/m',
          style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text(
          'Yeni aralık: ${formatSpacingMm(result.resultingSpacingMm)} mm '
          '(${(result.resultingSpacingMm / 10).toStringAsFixed(1)} cm)',
          style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
        ),
      ],
    );
  }
}

class _SingleQuantityResultCard extends StatelessWidget {
  const _SingleQuantityResultCard({
    required this.sourceDiameter,
    required this.sourceQuantity,
    required this.result,
    required this.isOptimal,
  });

  final int sourceDiameter;
  final int sourceQuantity;
  final TahvilSingleQuantityResult result;
  final bool isOptimal;

  @override
  Widget build(BuildContext context) {
    final symbol = crossSectionComparisonSymbol(
      result.sourceAreaMm2,
      result.targetAreaMm2,
    );

    return _ResultCardShell(
      title:
          '$sourceQuantity×Ø$sourceDiameter  →  ${result.equivalentQuantity}×Ø${result.targetDiameter}',
      isAllowed: result.isAllowed,
      isOptimal: isOptimal,
      rejectReason: result.rejectReason,
      targetDiameter: result.targetDiameter,
      children: [
        Text(
          'As: ${formatAreaMm2(result.sourceAreaMm2)} mm² '
          '$symbol ${formatAreaMm2(result.targetAreaMm2)} mm²',
          style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text(
          result.isAllowed
              ? 'Sapma %${result.areaDeviationPercent.toStringAsFixed(2)} (uygun)'
              : 'Sapma %${result.areaDeviationPercent.toStringAsFixed(2)}',
          style: AppTypography.bodySmall.copyWith(
            color: result.isAllowed ? AppColors.success : AppColors.critical,
          ),
        ),
      ],
    );
  }
}

class _DualComparisonCard extends StatelessWidget {
  const _DualComparisonCard({required this.comparison});

  final TahvilDualQuantityComparison comparison;

  @override
  Widget build(BuildContext context) {
    final symbol = crossSectionComparisonSymbol(
      comparison.sourceAreaMm2,
      comparison.targetAreaMm2,
    );
    final accent = comparison.isAllowed ? AppColors.success : AppColors.warning;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.06),
        borderRadius: AppRadii.md,
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Kesit alanı mukayesesı', style: AppTypography.titleMedium),
          const SizedBox(height: 8),
          Text(
            'Kaynak As: ${formatAreaMm2(comparison.sourceAreaMm2)} mm²',
            style: AppTypography.bodyMedium,
          ),
          Text(
            'Hedef As: ${formatAreaMm2(comparison.targetAreaMm2)} mm²',
            style: AppTypography.bodyMedium,
          ),
          const SizedBox(height: 6),
          Text(
            '$symbol  Sapma %${comparison.areaDeviationPercent.toStringAsFixed(2)}',
            style: AppTypography.bodyMedium.copyWith(
              color: accent,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            comparison.isAllowed
                ? 'Kesit sapması kabul limiti içinde.'
                : comparison.diameterRuleViolations.isNotEmpty
                    ? comparison.diameterRuleViolations.join(' · ')
                    : 'Kesit sapması %${(tahvilMaxAreaDeviationRatio * 100).toStringAsFixed(0)} limitini aşıyor.',
            style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

class _ResultCardShell extends StatelessWidget {
  const _ResultCardShell({
    required this.title,
    required this.isAllowed,
    required this.isOptimal,
    required this.targetDiameter,
    required this.children,
    this.rejectReason,
  });

  final String title;
  final bool isAllowed;
  final bool isOptimal;
  final int targetDiameter;
  final List<Widget> children;
  final String? rejectReason;

  @override
  Widget build(BuildContext context) {
    final targetColor = AppColors.diameterColor(targetDiameter);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isOptimal
            ? AppColors.success.withValues(alpha: 0.06)
            : !isAllowed
                ? AppColors.critical.withValues(alpha: 0.04)
                : AppColors.surfaceElevated,
        borderRadius: AppRadii.md,
        border: Border.all(
          color: isOptimal
              ? AppColors.success.withValues(alpha: 0.35)
              : !isAllowed
                  ? AppColors.critical.withValues(alpha: 0.25)
                  : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.titleMedium.copyWith(
                    color: isAllowed
                        ? targetColor
                        : targetColor.withValues(alpha: 0.55),
                  ),
                ),
              ),
              if (isOptimal)
                const _StatusBadge(label: 'Optimum', color: AppColors.success)
              else if (!isAllowed)
                const _StatusBadge(
                  label: 'Uygun değil',
                  color: AppColors.critical,
                ),
            ],
          ),
          if (!isAllowed && rejectReason != null) ...[
            const SizedBox(height: 6),
            Text(
              rejectReason!,
              style: AppTypography.bodySmall.copyWith(color: AppColors.critical),
            ),
          ],
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AppTypography.labelMedium.copyWith(color: color),
      ),
    );
  }
}

class _DiameterSpacingFields {
  final diameterController = TextEditingController();
  final spacingController = TextEditingController();

  int? get diameter => int.tryParse(diameterController.text.trim());
  double? get spacingMm {
    final raw = spacingController.text.trim().replaceAll(',', '.');
    return double.tryParse(raw);
  }

  void dispose() {
    diameterController.dispose();
    spacingController.dispose();
  }
}

class _DiameterQuantityFields {
  final quantityController = TextEditingController();
  final diameterController = TextEditingController();

  int? get quantity => int.tryParse(quantityController.text.trim());
  int? get diameter => int.tryParse(diameterController.text.trim());

  void setValues({required int quantity, required int diameter}) {
    quantityController.text = '$quantity';
    diameterController.text = '$diameter';
  }

  void setDiameter(int diameter) {
    diameterController.text = '$diameter';
  }

  void dispose() {
    quantityController.dispose();
    diameterController.dispose();
  }
}
