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
        _TahvilCalculatorModePanel(
          basis: _basis,
          quantityKind: _quantityKind,
          onBasisChanged: (value) => setState(() => _basis = value),
          onQuantityKindChanged: (value) => setState(() => _quantityKind = value),
        ),
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

class _TahvilCalculatorModePanel extends StatelessWidget {
  const _TahvilCalculatorModePanel({
    required this.basis,
    required this.quantityKind,
    required this.onBasisChanged,
    required this.onQuantityKindChanged,
  });

  final TahvilCalculatorBasis basis;
  final TahvilQuantityKind quantityKind;
  final ValueChanged<TahvilCalculatorBasis> onBasisChanged;
  final ValueChanged<TahvilQuantityKind> onQuantityKindChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.surfaceElevated,
            AppColors.surfaceHighlight.withValues(alpha: 0.28),
          ],
        ),
        borderRadius: AppRadii.md,
        border: Border.all(
          color: AppColors.borderSubtle.withValues(alpha: 0.65),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ModeSegmentedControl<TahvilCalculatorBasis>(
            title: 'Hesaplama yöntemi',
            values: TahvilCalculatorBasis.values,
            selected: basis,
            labelBuilder: (value) => value.label,
            onSelected: onBasisChanged,
          ),
          if (basis == TahvilCalculatorBasis.quantity) ...[
            const SizedBox(height: 12),
            Divider(
              height: 1,
              color: AppColors.border.withValues(alpha: 0.75),
            ),
            const SizedBox(height: 12),
            _ModeSegmentedControl<TahvilQuantityKind>(
              title: 'Donatı yapısı',
              values: TahvilQuantityKind.values,
              selected: quantityKind,
              labelBuilder: (value) => value.label,
              onSelected: onQuantityKindChanged,
              dense: true,
            ),
          ],
        ],
      ),
    );
  }
}

class _ModeSegmentedControl<T> extends StatelessWidget {
  const _ModeSegmentedControl({
    required this.values,
    required this.selected,
    required this.labelBuilder,
    required this.onSelected,
    this.title,
    this.dense = false,
  });

  final List<T> values;
  final T selected;
  final String Function(T value) labelBuilder;
  final ValueChanged<T> onSelected;
  final String? title;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (title != null) ...[
          Text(
            title!,
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.35,
            ),
          ),
          const SizedBox(height: 8),
        ],
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: AppColors.canvas,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppColors.borderSubtle.withValues(alpha: 0.85),
            ),
          ),
          child: Row(
            children: [
              for (var i = 0; i < values.length; i++)
                Expanded(
                  child: _ModeSegmentButton(
                    label: labelBuilder(values[i]),
                    selected: values[i] == selected,
                    dense: dense,
                    onTap: () => onSelected(values[i]),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ModeSegmentButton extends StatelessWidget {
  const _ModeSegmentButton({
    required this.label,
    required this.selected,
    required this.onTap,
    this.dense = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        splashColor: AppColors.electricBlueLight.withValues(alpha: 0.12),
        highlightColor: AppColors.electricBlueLight.withValues(alpha: 0.06),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(
            horizontal: dense ? 6 : 8,
            vertical: dense ? 9 : 11,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: selected ? AppColors.electricBlue : Colors.transparent,
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppColors.electricBlue.withValues(alpha: 0.32),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.labelMedium.copyWith(
              color: selected ? Colors.white : AppColors.textMuted,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              fontSize: dense ? 12 : 13,
              height: 1.2,
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
        'Proje çap ve aralığı girin. Manuel hedef girin veya olumlu seçenekleri görüntüleyin.',
      TahvilCalculatorBasis.quantity =>
        quantityKind == TahvilQuantityKind.single
            ? 'Proje adet ve çap girin. Manuel hedef girin veya olumlu seçenekleri görüntüleyin.'
            : 'İki proje donatı girin. Manuel hedef veya olumlu seçeneklerden tahvil yapın.',
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
            'hedef As ≥ proje As · '
            '≤%${(tahvilMaxAreaDeviationRatio * 100).toStringAsFixed(0)} fazla kesit',
            style: AppTypography.labelSmall.copyWith(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

class _SpacingModePanel extends StatefulWidget {
  const _SpacingModePanel({
    required this.fields,
    required this.onChanged,
  });

  final _DiameterSpacingFields fields;
  final VoidCallback onChanged;

  @override
  State<_SpacingModePanel> createState() => _SpacingModePanelState();
}

class _SpacingModePanelState extends State<_SpacingModePanel> {
  TahvilSpacingTargetKind _targetKind = TahvilSpacingTargetKind.diameter;
  bool _showPositiveOptions = false;
  final _targetDiameterController = TextEditingController();
  final _targetSpacingController = TextEditingController();

  @override
  void dispose() {
    _targetDiameterController.dispose();
    _targetSpacingController.dispose();
    super.dispose();
  }

  void _handleChanged() {
    widget.onChanged();
    setState(() {});
  }

  void _onTargetKindChanged(TahvilSpacingTargetKind kind) {
    setState(() {
      _targetKind = kind;
      if (kind == TahvilSpacingTargetKind.diameter) {
        _targetSpacingController.clear();
      } else {
        _targetDiameterController.clear();
      }
    });
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final fields = widget.fields;
    final diameter = fields.diameter;
    final spacingMm = fields.spacingMm;
    final sourceReady = diameter != null && spacingMm != null;
    final sourceAs = sourceReady
        ? computeAsPerMeterMm2(diameter!, spacingMm!)
        : null;

    final targetDiameterInput = int.tryParse(_targetDiameterController.text.trim());
    final targetSpacingInput = double.tryParse(
      _targetSpacingController.text.trim().replaceAll(',', '.'),
    );

    final result = sourceReady
        ? computeSpacingTahvilTarget(
            sourceDiameter: diameter!,
            sourceSpacingMm: spacingMm!,
            inputKind: _targetKind,
            inputTargetDiameter: _targetKind == TahvilSpacingTargetKind.diameter
                ? targetDiameterInput
                : null,
            inputTargetSpacingMm: _targetKind == TahvilSpacingTargetKind.spacing
                ? targetSpacingInput
                : null,
          )
        : null;

    final targetInputReady = _targetKind == TahvilSpacingTargetKind.diameter
        ? targetDiameterInput != null && targetDiameterInput > 0
        : targetSpacingInput != null && targetSpacingInput > 0;

    final positiveSpacingOptions = sourceReady
        ? _adequateSpacingOptions(diameter!, spacingMm!)
        : const <TahvilSpacingTargetResult>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ExcelStyleTable(
          title: 'Proje donatı',
          accentColor: AppColors.warning,
          children: [
            _InputRow(
              labels: const ['ÇAP (mm)', 'ARALIK (mm)'],
              fields: [
                _NumericField(
                  controller: fields.diameterController,
                  hint: '16',
                  onChanged: _handleChanged,
                ),
                _NumericField(
                  controller: fields.spacingController,
                  hint: '250',
                  decimal: true,
                  onChanged: _handleChanged,
                ),
              ],
            ),
          ],
        ),
        if (sourceAs != null) ...[
          const SizedBox(height: 8),
          _AsBadge(
            label: 'Proje As',
            value: '${formatAreaMm2(sourceAs)} mm²/m',
          ),
        ],
        if (!sourceReady) ...[
          const SizedBox(height: 12),
          Text(
            'Hesap için proje çap ve aralık alanlarını doldurun.',
            style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
          ),
        ] else ...[
          const SizedBox(height: 12),
          Text('Manuel hedef girişi', style: AppTypography.titleMedium),
          const SizedBox(height: 8),
          _ModeSegmentedControl<TahvilSpacingTargetKind>(
            title: 'Hedef girdisi',
            values: TahvilSpacingTargetKind.values,
            selected: _targetKind,
            labelBuilder: (value) => value.label,
            onSelected: _onTargetKindChanged,
            dense: true,
          ),
          const SizedBox(height: 10),
          _ExcelStyleTable(
            title: 'Hedef donatı',
            accentColor: AppColors.electricBlueLight,
            children: [
              if (_targetKind == TahvilSpacingTargetKind.diameter) ...[
                _InputRow(
                  labels: const ['HEDEF ÇAP (mm)', 'HESAPLANAN ARALIK (mm)'],
                  fields: [
                    _NumericField(
                      controller: _targetDiameterController,
                      hint: '14',
                      accent: _FieldAccent.target,
                      onChanged: _handleChanged,
                    ),
                    _ComputedField(
                      value: result != null
                          ? formatDiameterSpacingLabel(
                              result.targetDiameter,
                              result.targetSpacingMm,
                            )
                          : null,
                      hint: '—',
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final option in RebarWeightCalculator.standardDiameters)
                      if (option != diameter)
                        _DiameterChip(
                          diameter: option,
                          selected: targetDiameterInput == option,
                          enabled: isTahvilDiameterAllowed(diameter!, option),
                          onTap: () {
                            _targetDiameterController.text = '$option';
                            _handleChanged();
                          },
                        ),
                  ],
                ),
              ] else ...[
                _InputRow(
                  labels: const ['HEDEF ARALIK (mm)', 'HESAPLANAN ÇAP (mm)'],
                  fields: [
                    _NumericField(
                      controller: _targetSpacingController,
                      hint: '191',
                      decimal: true,
                      accent: _FieldAccent.target,
                      onChanged: _handleChanged,
                    ),
                    _ComputedField(
                      value: result != null
                          ? formatDiameterSpacingLabel(
                              result.targetDiameter,
                              result.targetSpacingMm,
                            )
                          : null,
                      hint: '—',
                    ),
                  ],
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          if (!targetInputReady)
            Text(
              _targetKind == TahvilSpacingTargetKind.diameter
                  ? 'Hedef çap girin — optimum aralık hesaplanacak.'
                  : 'Hedef aralık girin — optimum çap hesaplanacak.',
              style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
            )
          else if (result == null)
            Text(
              'Girilen hedef için tahvil hesabı yapılamadı.',
              style: AppTypography.bodySmall.copyWith(color: AppColors.critical),
            )
          else
            _SpacingTargetResultCard(result: result),
          const SizedBox(height: 12),
          _PositiveOptionsButton(
            expanded: _showPositiveOptions,
            optionCount: positiveSpacingOptions.length,
            onPressed: positiveSpacingOptions.isEmpty
                ? null
                : () => setState(
                      () => _showPositiveOptions = !_showPositiveOptions,
                    ),
          ),
          if (_showPositiveOptions && positiveSpacingOptions.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Olumlu tahvil seçenekleri', style: AppTypography.labelMedium),
            const SizedBox(height: 8),
            ...positiveSpacingOptions.map(
              (option) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _SpacingOptionCard(
                  result: option,
                  selected: _targetKind == TahvilSpacingTargetKind.diameter &&
                      targetDiameterInput == option.targetDiameter,
                  onTap: () {
                    setState(() {
                      _targetKind = TahvilSpacingTargetKind.diameter;
                      _targetSpacingController.clear();
                      _targetDiameterController.text =
                          '${option.targetDiameter}';
                    });
                    _handleChanged();
                  },
                ),
              ),
            ),
          ],
        ],
      ],
    );
  }

  List<TahvilSpacingTargetResult> _adequateSpacingOptions(
    int sourceDiameter,
    double sourceSpacingMm,
  ) {
    final options = <TahvilSpacingTargetResult>[];
    for (final targetDiameter in RebarWeightCalculator.standardDiameters) {
      if (targetDiameter == sourceDiameter) continue;
      final option = computeSpacingTahvilTarget(
        sourceDiameter: sourceDiameter,
        sourceSpacingMm: sourceSpacingMm,
        inputKind: TahvilSpacingTargetKind.diameter,
        inputTargetDiameter: targetDiameter,
      );
      if (option != null && option.isAdequate) {
        options.add(option);
      }
    }
    options.sort((a, b) {
      if (a.isOptimal != b.isOptimal) return a.isOptimal ? -1 : 1;
      return (sourceDiameter - a.targetDiameter)
          .abs()
          .compareTo((sourceDiameter - b.targetDiameter).abs());
    });
    return options;
  }
}

class _ComputedField extends StatelessWidget {
  const _ComputedField({
    required this.value,
    required this.hint,
  });

  final String? value;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null && value!.isNotEmpty;

    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
      decoration: BoxDecoration(
        color: hasValue
            ? AppColors.electricBlueLight.withValues(alpha: 0.12)
            : AppColors.canvas,
        borderRadius: AppRadii.sm,
        border: Border.all(
          color: hasValue
              ? AppColors.electricBlueLight.withValues(alpha: 0.45)
              : AppColors.border,
        ),
      ),
      child: Text(
        hasValue ? value! : hint,
        textAlign: TextAlign.center,
        style: AppTypography.bodySmall.copyWith(
          fontWeight: FontWeight.w700,
          color: hasValue ? AppColors.electricBlueLight : AppColors.textMuted,
        ),
      ),
    );
  }
}

class _SpacingTargetResultCard extends StatelessWidget {
  const _SpacingTargetResultCard({required this.result});

  final TahvilSpacingTargetResult result;

  @override
  Widget build(BuildContext context) {
    final accent = result.isOptimal
        ? AppColors.success
        : result.isAdequateButNotOptimal
            ? AppColors.info
            : AppColors.critical;
    final targetColor = AppColors.diameterColor(result.targetDiameter);

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
          Row(
            children: [
              Expanded(
                child: Text(
                  '${formatDiameterSpacingLabel(result.sourceDiameter, result.sourceSpacingMm)}  →  '
                  '${formatDiameterSpacingLabel(result.targetDiameter, result.targetSpacingMm)}',
                  style: AppTypography.titleMedium.copyWith(color: targetColor),
                ),
              ),
              if (result.isOptimal)
                const _StatusBadge(label: 'Optimum', color: AppColors.success)
              else if (result.isAdequateButNotOptimal) ...[
                const _StatusBadge(label: 'Uygun', color: AppColors.success),
                const SizedBox(width: 6),
                const _StatusBadge(
                  label: 'Optimum değil',
                  color: AppColors.warning,
                ),
              ] else
                const _StatusBadge(
                  label: 'Uygun değil',
                  color: AppColors.critical,
                ),
            ],
          ),
          if (result.rejectReason != null && !result.isOptimal) ...[
            const SizedBox(height: 6),
            Text(
              result.rejectReason!,
              style: AppTypography.bodySmall.copyWith(color: AppColors.critical),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            'As: ${formatAreaMm2(result.sourceAsPerMeterMm2)} mm²/m → '
            '${formatAreaMm2(result.targetAsPerMeterMm2)} mm²/m',
            style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            result.isOptimal
                ? 'Tahvil uygundur — hedef '
                    '${formatDiameterSpacingLabel(result.targetDiameter, result.targetSpacingMm)} '
                    '(${(result.targetSpacingMm / 10).toStringAsFixed(1)} cm)'
                : result.isAdequateButNotOptimal
                    ? 'Tahvil uygundur — hedef As proje Asa eşit veya büyük, '
                        'ancak fazla kesit limiti nedeniyle optimum değil.'
                    : 'Tahvil koşulları sağlanmıyor.',
            style: AppTypography.bodySmall.copyWith(color: accent),
          ),
        ],
      ),
    );
  }
}

class _SingleQuantityModePanel extends StatefulWidget {
  const _SingleQuantityModePanel({
    required this.fields,
    required this.onChanged,
  });

  final _DiameterQuantityFields fields;
  final VoidCallback onChanged;

  @override
  State<_SingleQuantityModePanel> createState() =>
      _SingleQuantityModePanelState();
}

class _SingleQuantityModePanelState extends State<_SingleQuantityModePanel> {
  bool _showPositiveOptions = false;
  final _targetDiameterController = TextEditingController();

  @override
  void dispose() {
    _targetDiameterController.dispose();
    super.dispose();
  }

  void _handleChanged() {
    widget.onChanged();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final fields = widget.fields;
    final diameter = fields.diameter;
    final quantity = fields.quantity;
    final isReady = diameter != null && quantity != null;
    final results = isReady
        ? computeSingleQuantityTahvilResults(
            sourceDiameter: diameter!,
            sourceQuantity: quantity!,
          )
        : const <TahvilSingleQuantityResult>[];
    final positiveResults = results.where((item) => item.isAdequate).toList();
    final targetDiameterInput =
        int.tryParse(_targetDiameterController.text.trim());
    TahvilSingleQuantityResult? manualResult;
    if (isReady && targetDiameterInput != null) {
      for (final result in results) {
        if (result.targetDiameter == targetDiameterInput) {
          manualResult = result;
          break;
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ExcelStyleTable(
          title: 'Proje donatı',
          accentColor: AppColors.warning,
          children: [
            _InputRow(
              labels: const ['ADET', 'ÇAP (mm)'],
              fields: [
                _NumericField(
                  controller: fields.quantityController,
                  hint: '3',
                  onChanged: _handleChanged,
                ),
                _NumericField(
                  controller: fields.diameterController,
                  hint: '16',
                  onChanged: _handleChanged,
                ),
              ],
            ),
          ],
        ),
        if (isReady) ...[
          const SizedBox(height: 8),
          _AsBadge(
            label: 'Proje As',
            value:
                '${formatAreaMm2(crossSectionAreaMm2(diameter!) * quantity!)} mm²',
          ),
        ],
        if (!isReady) ...[
          const SizedBox(height: 12),
          Text(
            'Hesap için adet ve çap alanlarını doldurun.',
            style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
          ),
        ] else ...[
          const SizedBox(height: 12),
          Text('Manuel hedef girişi', style: AppTypography.titleMedium),
          const SizedBox(height: 8),
          _ExcelStyleTable(
            title: 'Hedef donatı',
            accentColor: AppColors.electricBlueLight,
            children: [
              _InputRow(
                labels: const ['HEDEF ÇAP (mm)', 'HESAPLANAN ADET'],
                fields: [
                  _NumericField(
                    controller: _targetDiameterController,
                    hint: '14',
                    accent: _FieldAccent.target,
                    onChanged: _handleChanged,
                  ),
                  _ComputedField(
                    value: manualResult != null
                        ? '${manualResult.equivalentQuantity}'
                        : null,
                    hint: '—',
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final option in RebarWeightCalculator.standardDiameters)
                    if (option != diameter)
                      _DiameterChip(
                        diameter: option,
                        selected: targetDiameterInput == option,
                        enabled: isTahvilDiameterAllowed(diameter!, option),
                        onTap: () {
                          _targetDiameterController.text = '$option';
                          _handleChanged();
                        },
                      ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (targetDiameterInput == null)
            Text(
              'Hedef çap girin — eşdeğer adet hesaplanacak.',
              style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
            )
          else if (manualResult == null)
            Text(
              'Girilen hedef için tahvil hesabı yapılamadı.',
              style: AppTypography.bodySmall.copyWith(color: AppColors.critical),
            )
          else
            _SingleQuantityResultCard(
              sourceDiameter: diameter!,
              sourceQuantity: quantity!,
              result: manualResult,
              isOptimal: positiveResults.isNotEmpty &&
                  manualResult.isAllowed &&
                  manualResult.targetDiameter ==
                      positiveResults.first.targetDiameter,
            ),
          const SizedBox(height: 12),
          _PositiveOptionsButton(
            expanded: _showPositiveOptions,
            optionCount: positiveResults.length,
            onPressed: positiveResults.isEmpty
                ? null
                : () => setState(
                      () => _showPositiveOptions = !_showPositiveOptions,
                    ),
          ),
          if (_showPositiveOptions && positiveResults.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Olumlu tahvil seçenekleri', style: AppTypography.labelMedium),
            const SizedBox(height: 8),
            ...positiveResults.map(
              (result) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _SingleQuantityResultCard(
                  sourceDiameter: diameter!,
                  sourceQuantity: quantity!,
                  result: result,
                  isOptimal: positiveResults.isNotEmpty &&
                      result.isAllowed &&
                      result.targetDiameter ==
                          positiveResults.first.targetDiameter,
                  selected: targetDiameterInput == result.targetDiameter,
                  onTap: () {
                    _targetDiameterController.text = '${result.targetDiameter}';
                    _handleChanged();
                  },
                ),
              ),
            ),
          ],
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
  bool _showPositiveOptions = false;

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
    _showPositiveOptions = false;
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
    });
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final positiveSuggestions =
        _suggestions.where((item) => item.isAdequate).toList();
    final optimalSuggestions =
        positiveSuggestions.where((item) => item.isOptimal).toList();
    final manualComparison = _manualComparison;
    final sourceArea = _sourceReady
        ? crossSectionAreaMm2(sourceA.diameter!) * sourceA.quantity! +
            crossSectionAreaMm2(sourceB.diameter!) * sourceB.quantity!
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ExcelStyleTable(
          title: 'Proje donatı',
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
            label: 'Proje As',
            value: '${formatAreaMm2(sourceArea)} mm²',
          ),
        ],
        if (!_sourceReady) ...[
          const SizedBox(height: 12),
          Text(
            'Tahvil için proje adet ve çap alanlarını doldurun.',
            style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
          ),
        ] else ...[
          const SizedBox(height: 12),
          Text('Manuel hedef girişi', style: AppTypography.titleMedium),
          const SizedBox(height: 8),
          _ExcelStyleTable(
            title: 'Hedef donatı',
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
          const SizedBox(height: 12),
          _PositiveOptionsButton(
            expanded: _showPositiveOptions,
            optionCount: positiveSuggestions.length,
            onPressed: positiveSuggestions.isEmpty
                ? null
                : () => setState(
                      () => _showPositiveOptions = !_showPositiveOptions,
                    ),
          ),
          if (_showPositiveOptions && positiveSuggestions.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Olumlu tahvil seçenekleri', style: AppTypography.labelMedium),
            const SizedBox(height: 4),
            Text(
              'Öneriye dokunarak hedef alanları doldurun.',
              style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: 8),
            ...positiveSuggestions.map(
              (suggestion) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _DualSuggestionCard(
                  suggestion: suggestion,
                  selected: _selectedSuggestionId == suggestion.id,
                  isOptimal: optimalSuggestions.isNotEmpty &&
                      suggestion.isOptimal &&
                      suggestion.id == optimalSuggestions.first.id,
                  onTap: () => _applySuggestion(suggestion),
                ),
              ),
            ),
          ],
        ],
      ],
    );
  }
}

class _PositiveOptionsButton extends StatelessWidget {
  const _PositiveOptionsButton({
    required this.expanded,
    required this.optionCount,
    required this.onPressed,
  });

  final bool expanded;
  final int optionCount;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final label = !enabled
        ? 'Olumlu tahvil seçeneği yok'
        : expanded
            ? 'Olumlu seçenekleri gizle ($optionCount)'
            : 'Olumlu tahvil seçeneklerini göster ($optionCount)';

    return FilledButton.tonalIcon(
      onPressed: onPressed,
      icon: Icon(
        expanded ? Icons.expand_less : Icons.playlist_add_check_outlined,
        size: 20,
      ),
      label: Text(label),
      style: FilledButton.styleFrom(
        foregroundColor:
            enabled ? AppColors.success : AppColors.textMuted,
        backgroundColor: enabled
            ? AppColors.success.withValues(alpha: 0.12)
            : AppColors.canvas,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        alignment: Alignment.centerLeft,
      ),
    );
  }
}

class _SpacingOptionCard extends StatelessWidget {
  const _SpacingOptionCard({
    required this.result,
    required this.selected,
    required this.onTap,
  });

  final TahvilSpacingTargetResult result;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? AppColors.electricBlueLight.withValues(alpha: 0.1)
          : result.isOptimal
              ? AppColors.success.withValues(alpha: 0.05)
              : AppColors.info.withValues(alpha: 0.06),
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
                  : result.isOptimal
                      ? AppColors.success.withValues(alpha: 0.35)
                      : AppColors.info.withValues(alpha: 0.35),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${formatDiameterSpacingLabel(result.sourceDiameter, result.sourceSpacingMm)}  →  '
                      '${formatDiameterSpacingLabel(result.targetDiameter, result.targetSpacingMm)}',
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (result.isOptimal)
                    const _StatusBadge(
                      label: 'Optimum',
                      color: AppColors.success,
                    )
                  else ...[
                    const _StatusBadge(
                      label: 'Uygun',
                      color: AppColors.success,
                    ),
                    const SizedBox(width: 6),
                    const _StatusBadge(
                      label: 'Optimum değil',
                      color: AppColors.warning,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'As: ${formatAreaMm2(result.sourceAsPerMeterMm2)} → '
                '${formatAreaMm2(result.targetAsPerMeterMm2)} mm²/m',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
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
    final accent = suggestion.isOptimal
        ? AppColors.success
        : suggestion.isAdequate
            ? AppColors.info
            : comparison.hasAreaDeficit
                ? AppColors.critical
                : AppColors.warning;

    return Material(
      color: selected
          ? AppColors.electricBlueLight.withValues(alpha: 0.1)
          : suggestion.isOptimal
              ? AppColors.success.withValues(alpha: 0.05)
              : suggestion.isAdequate
                  ? AppColors.info.withValues(alpha: 0.06)
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
                  else if (suggestion.isAdequate) ...[
                    const _StatusBadge(label: 'Uygun', color: AppColors.success),
                    const SizedBox(width: 6),
                    const _StatusBadge(
                      label: 'Optimum değil',
                      color: AppColors.warning,
                    ),
                  ] else if (comparison.hasAreaDeficit)
                    const _StatusBadge(
                      label: 'Yetersiz As',
                      color: AppColors.critical,
                    )
                  else
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
    final hasValue = controller.text.trim().isNotEmpty;
    final activeColor =
        hasValue ? AppColors.success : fieldColor;

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
        fillColor: activeColor.withValues(alpha: hasValue ? 0.18 : 0.12),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadii.sm,
          borderSide: BorderSide(
            color: activeColor.withValues(alpha: hasValue ? 0.65 : 0.45),
            width: hasValue ? 1.5 : 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadii.sm,
          borderSide: BorderSide(
            color: activeColor.withValues(alpha: 0.85),
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

class _SingleQuantityResultCard extends StatelessWidget {
  const _SingleQuantityResultCard({
    required this.sourceDiameter,
    required this.sourceQuantity,
    required this.result,
    required this.isOptimal,
    this.selected = false,
    this.onTap,
  });

  final int sourceDiameter;
  final int sourceQuantity;
  final TahvilSingleQuantityResult result;
  final bool isOptimal;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final symbol = crossSectionComparisonSymbol(
      result.sourceAreaMm2,
      result.targetAreaMm2,
    );

    final card = _ResultCardShell(
      title:
          '$sourceQuantity×Ø$sourceDiameter  →  ${result.equivalentQuantity}×Ø${result.targetDiameter}',
      isAllowed: result.isAllowed,
      isAdequate: result.isAdequate,
      isOptimal: isOptimal,
      rejectReason: result.rejectReason,
      targetDiameter: result.targetDiameter,
      selected: selected,
      children: [
        Text(
          'As: ${formatAreaMm2(result.sourceAreaMm2)} mm² '
          '$symbol ${formatAreaMm2(result.targetAreaMm2)} mm²',
          style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text(
          result.isAllowed
              ? 'Fazla kesit %${result.areaDeviationPercent.toStringAsFixed(2)} (optimum)'
              : result.isAdequate
                  ? 'Tahvil uygun — fazla kesit %${result.areaDeviationPercent.toStringAsFixed(2)} '
                      '(optimum değil, limit %${(tahvilMaxAreaDeviationRatio * 100).toStringAsFixed(0)})'
                  : result.targetAreaMm2 + 1e-6 < result.sourceAreaMm2
                      ? 'Hedef As proje Astan küçük — tahvil uygun değil'
                      : 'Fazla kesit %${result.areaDeviationPercent.toStringAsFixed(2)}',
          style: AppTypography.bodySmall.copyWith(
            color: result.isAllowed
                ? AppColors.success
                : result.isAdequate
                    ? AppColors.info
                    : AppColors.critical,
          ),
        ),
      ],
    );

    if (onTap == null) return card;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.md,
        child: card,
      ),
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
    final accent = comparison.isOptimal
        ? AppColors.success
        : comparison.isAdequateButNotOptimal
            ? AppColors.info
            : comparison.hasAreaDeficit
                ? AppColors.critical
                : AppColors.warning;

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
          Row(
            children: [
              Expanded(
                child: Text(
                  'Kesit alanı mukayesesı',
                  style: AppTypography.titleMedium,
                ),
              ),
              if (comparison.isOptimal)
                const _StatusBadge(label: 'Optimum', color: AppColors.success)
              else if (comparison.isAdequateButNotOptimal) ...[
                const _StatusBadge(label: 'Uygun', color: AppColors.success),
                const SizedBox(width: 6),
                const _StatusBadge(
                  label: 'Optimum değil',
                  color: AppColors.warning,
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Proje As: ${formatAreaMm2(comparison.sourceAreaMm2)} mm²',
            style: AppTypography.bodyMedium,
          ),
          Text(
            'Hedef As: ${formatAreaMm2(comparison.targetAreaMm2)} mm²',
            style: AppTypography.bodyMedium,
          ),
          const SizedBox(height: 6),
          Text(
            '$symbol  Fazla kesit %${comparison.areaDeviationPercent.toStringAsFixed(2)}',
            style: AppTypography.bodyMedium.copyWith(
              color: accent,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            comparison.isOptimal
                ? 'Tahvil uygundur ve optimum aralıkta.'
                : comparison.isAdequateButNotOptimal
                    ? 'Tahvil uygundur — hedef As proje Asa eşit veya büyük. '
                        'Fazla kesit %${comparison.areaDeviationPercent.toStringAsFixed(1)} '
                        'ile optimum değil (limit %${(tahvilMaxAreaDeviationRatio * 100).toStringAsFixed(0)}).'
                    : comparison.hasAreaDeficit
                        ? comparison.areaRejectReason ??
                            'Hedef As proje Astan küçük — tahvil uygun değil.'
                        : comparison.diameterRuleViolations.isNotEmpty
                            ? comparison.diameterRuleViolations.join(' · ')
                            : comparison.areaRejectReason ??
                                'Tahvil koşulları sağlanmıyor.',
            style: AppTypography.bodySmall.copyWith(
              color: comparison.isOptimal
                  ? AppColors.success
                  : comparison.isAdequateButNotOptimal
                      ? AppColors.info
                      : comparison.hasAreaDeficit
                          ? AppColors.critical
                          : AppColors.textMuted,
            ),
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
    this.isAdequate = false,
    this.rejectReason,
    this.selected = false,
  });

  final String title;
  final bool isAllowed;
  final bool isAdequate;
  final bool isOptimal;
  final int targetDiameter;
  final List<Widget> children;
  final String? rejectReason;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final targetColor = AppColors.diameterColor(targetDiameter);
    final accent = isOptimal
        ? AppColors.success
        : isAdequate
            ? AppColors.info
            : !isAllowed
                ? AppColors.critical
                : AppColors.border;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: selected
            ? AppColors.electricBlueLight.withValues(alpha: 0.1)
            : isOptimal
                ? AppColors.success.withValues(alpha: 0.06)
                : isAdequate
                    ? AppColors.info.withValues(alpha: 0.06)
                    : !isAllowed
                        ? AppColors.critical.withValues(alpha: 0.04)
                        : AppColors.surfaceElevated,
        borderRadius: AppRadii.md,
        border: Border.all(
          color: selected
              ? AppColors.electricBlueLight.withValues(alpha: 0.55)
              : accent.withValues(alpha: isOptimal || isAdequate || !isAllowed ? 0.35 : 1),
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
                    color: isAllowed || isAdequate
                        ? targetColor
                        : targetColor.withValues(alpha: 0.55),
                  ),
                ),
              ),
              if (isOptimal)
                const _StatusBadge(label: 'Optimum', color: AppColors.success)
              else if (isAdequate) ...[
                const _StatusBadge(label: 'Uygun', color: AppColors.success),
                const SizedBox(width: 6),
                const _StatusBadge(
                  label: 'Optimum değil',
                  color: AppColors.warning,
                ),
              ] else if (!isAllowed)
                const _StatusBadge(
                  label: 'Uygun değil',
                  color: AppColors.critical,
                ),
            ],
          ),
          if (!isAllowed && !isAdequate && rejectReason != null) ...[
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
