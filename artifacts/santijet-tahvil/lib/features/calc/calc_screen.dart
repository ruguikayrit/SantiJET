import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design_system/sj_card.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/santijet_header.dart';
import '../../core/widgets/tahvil_hero_card.dart';
import '../../data/rebar_weight.dart';
import '../../data/records_store.dart';
import '../../domain/tahvil_calculator.dart';
import '../../domain/tahvil_record.dart';
import '../../domain/tahvil_rules.dart';

/// Saha tahvil hesaplayıcısı — canlı sonuç, tek dokunuşla kayıt.
class CalcScreen extends ConsumerStatefulWidget {
  const CalcScreen({super.key});

  @override
  ConsumerState<CalcScreen> createState() => _CalcScreenState();
}

class _CalcScreenState extends ConsumerState<CalcScreen> {
  TahvilBarKind _kind = TahvilBarKind.one;
  TahvilMeasure _measure = TahvilMeasure.spacing;

  int _oneDiameter = 16;
  int _twoDiameterA = 16;
  int _twoDiameterB = 12;

  late final TextEditingController _oneSpacingCtrl;
  late final TextEditingController _oneQuantityCtrl;
  late final TextEditingController _twoSpacingACtrl;
  late final TextEditingController _twoSpacingBCtrl;
  late final TextEditingController _twoQuantityACtrl;
  late final TextEditingController _twoQuantityBCtrl;

  @override
  void initState() {
    super.initState();
    _oneSpacingCtrl = TextEditingController(text: '15');
    _oneQuantityCtrl = TextEditingController(text: '10');
    _twoSpacingACtrl = TextEditingController(text: '15');
    _twoSpacingBCtrl = TextEditingController(text: '20');
    _twoQuantityACtrl = TextEditingController(text: '10');
    _twoQuantityBCtrl = TextEditingController(text: '8');
  }

  @override
  void dispose() {
    _oneSpacingCtrl.dispose();
    _oneQuantityCtrl.dispose();
    _twoSpacingACtrl.dispose();
    _twoSpacingBCtrl.dispose();
    _twoQuantityACtrl.dispose();
    _twoQuantityBCtrl.dispose();
    super.dispose();
  }

  void _refresh() => setState(() {});

  Future<void> _save({
    required String summary,
    required String detail,
    required bool allowed,
    required String sourceLine,
    required String targetLine,
    required double sourceAs,
    required double targetAs,
    required String asUnit,
  }) async {
    final record = TahvilRecord(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      createdAt: DateTime.now(),
      basis: '${_kind.label} · ${_measure.label}',
      summary: summary,
      detail: detail,
      isAllowed: allowed,
      sourceLine: sourceLine,
      targetLine: targetLine,
      sourceAs: sourceAs,
      targetAs: targetAs,
      asUnit: asUnit,
    );
    await ref.read(tahvilRecordsProvider.notifier).add(record);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Kayıtlara eklendi'),
        backgroundColor: AppColors.surfaceElevated,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.canvas,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const SantijetHeader(showWordmark: true),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                children: [
                  _KindHeadings(
                    selected: _kind,
                    onChanged: (value) => setState(() => _kind = value),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _MeasureBar(
                    selected: _measure,
                    onChanged: (value) => setState(() => _measure = value),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  switch ((_kind, _measure)) {
                    (TahvilBarKind.one, TahvilMeasure.spacing) =>
                      _SpacingPanel(
                        diameter: _oneDiameter,
                        spacingCtrl: _oneSpacingCtrl,
                        onDiameter: (d) => setState(() => _oneDiameter = d),
                        onChanged: _refresh,
                        onSave: _save,
                      ),
                    (TahvilBarKind.one, TahvilMeasure.quantity) =>
                      _QuantityPanel(
                        diameter: _oneDiameter,
                        quantityCtrl: _oneQuantityCtrl,
                        onDiameter: (d) => setState(() => _oneDiameter = d),
                        onChanged: _refresh,
                        onSave: _save,
                      ),
                    (TahvilBarKind.two, TahvilMeasure.spacing) =>
                      _DualSpacingPanel(
                        diameterA: _twoDiameterA,
                        diameterB: _twoDiameterB,
                        spacingACtrl: _twoSpacingACtrl,
                        spacingBCtrl: _twoSpacingBCtrl,
                        onDiameterA: (d) =>
                            setState(() => _twoDiameterA = d),
                        onDiameterB: (d) =>
                            setState(() => _twoDiameterB = d),
                        onChanged: _refresh,
                        onSave: _save,
                      ),
                    (TahvilBarKind.two, TahvilMeasure.quantity) =>
                      _DualPanel(
                        diameterA: _twoDiameterA,
                        diameterB: _twoDiameterB,
                        quantityACtrl: _twoQuantityACtrl,
                        quantityBCtrl: _twoQuantityBCtrl,
                        onDiameterA: (d) =>
                            setState(() => _twoDiameterA = d),
                        onDiameterB: (d) =>
                            setState(() => _twoDiameterB = d),
                        onChanged: _refresh,
                        onSave: _save,
                      ),
                  },
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KindHeadings extends StatelessWidget {
  const _KindHeadings({required this.selected, required this.onChanged});

  final TahvilBarKind selected;
  final ValueChanged<TahvilBarKind> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final kind in TahvilBarKind.values)
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onChanged(kind),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Column(
                  children: [
                    Text(
                      kind.label,
                      textAlign: TextAlign.center,
                      style: AppTypography.headlineMedium.copyWith(
                        color: selected == kind
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      height: 3,
                      decoration: BoxDecoration(
                        color: selected == kind
                            ? AppColors.electricBlue
                            : Colors.transparent,
                        borderRadius: AppRadii.xs,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _MeasureBar extends StatelessWidget {
  const _MeasureBar({required this.selected, required this.onChanged});

  final TahvilMeasure selected;
  final ValueChanged<TahvilMeasure> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.sm,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          for (final measure in TahvilMeasure.values)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onChanged(measure),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: selected == measure
                        ? AppColors.electricBlue
                        : Colors.transparent,
                    borderRadius: AppRadii.xs,
                  ),
                  child: Text(
                    measure.label,
                    textAlign: TextAlign.center,
                    style: AppTypography.labelLarge.copyWith(
                      color: selected == measure
                          ? Colors.white
                          : AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

typedef _SaveFn = Future<void> Function({
  required String summary,
  required String detail,
  required bool allowed,
  required String sourceLine,
  required String targetLine,
  required double sourceAs,
  required double targetAs,
  required String asUnit,
});

double _areaExcessPercent(double sourceAs, double targetAs) {
  if (sourceAs <= 0) return double.infinity;
  return ((targetAs - sourceAs) / sourceAs) * 100;
}

List<TahvilSpacingResult> _allowedSpacingAscending(
  List<TahvilSpacingResult> results,
) {
  final allowed = results.where((r) => r.isAllowed).toList()
    ..sort((a, b) => a.targetDiameter.compareTo(b.targetDiameter));
  return allowed;
}

TahvilSpacingResult? _optimalSpacing(
  List<TahvilSpacingResult> allowed,
  int sourceDiameter,
) {
  if (allowed.isEmpty) return null;
  final ranked = [...allowed]..sort((a, b) {
      final excess = _areaExcessPercent(
        a.sourceAsPerMeterMm2,
        a.targetAsPerMeterMm2,
      ).compareTo(
        _areaExcessPercent(b.sourceAsPerMeterMm2, b.targetAsPerMeterMm2),
      );
      if (excess != 0) return excess;
      return (sourceDiameter - a.targetDiameter)
          .abs()
          .compareTo((sourceDiameter - b.targetDiameter).abs());
    });
  return ranked.first;
}

List<TahvilSingleQuantityResult> _allowedQuantityAscending(
  List<TahvilSingleQuantityResult> results,
) {
  final allowed = results.where((r) => r.isAllowed).toList()
    ..sort((a, b) => a.targetDiameter.compareTo(b.targetDiameter));
  return allowed;
}

TahvilSingleQuantityResult? _optimalQuantity(
  List<TahvilSingleQuantityResult> allowed,
  int sourceDiameter,
) {
  if (allowed.isEmpty) return null;
  final ranked = [...allowed]..sort((a, b) {
      final excess =
          a.areaDeviationPercent.compareTo(b.areaDeviationPercent);
      if (excess != 0) return excess;
      return (sourceDiameter - a.targetDiameter)
          .abs()
          .compareTo((sourceDiameter - b.targetDiameter).abs());
    });
  return ranked.first;
}

List<TahvilDualSpacingSuggestion> _allowedDualSpacingAscending(
  List<TahvilDualSpacingSuggestion> suggestions,
) {
  final allowed = suggestions.where((s) => s.isAllowed).toList()
    ..sort((a, b) {
      final byA =
          a.legA.targetDiameter.compareTo(b.legA.targetDiameter);
      if (byA != 0) return byA;
      return a.legB.targetDiameter.compareTo(b.legB.targetDiameter);
    });
  return allowed;
}

TahvilDualSpacingSuggestion? _optimalDualSpacing(
  List<TahvilDualSpacingSuggestion> allowed,
) {
  if (allowed.isEmpty) return null;
  final ranked = [...allowed]
    ..sort((a, b) => a.areaDeviationPercent.compareTo(b.areaDeviationPercent));
  return ranked.first;
}

List<TahvilDualSuggestion> _allowedDualQuantityAscending(
  List<TahvilDualSuggestion> suggestions,
) {
  final allowed = suggestions.where((s) => s.isAllowed).toList()
    ..sort((a, b) {
      final byA =
          a.legA.targetDiameter.compareTo(b.legA.targetDiameter);
      if (byA != 0) return byA;
      return a.legB.targetDiameter.compareTo(b.legB.targetDiameter);
    });
  return allowed;
}

TahvilDualSuggestion? _optimalDualQuantity(
  List<TahvilDualSuggestion> allowed,
) {
  if (allowed.isEmpty) return null;
  final ranked = [...allowed]
    ..sort((a, b) => a.areaDeviationPercent.compareTo(b.areaDeviationPercent));
  return ranked.first;
}

class _SuggestionsHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Text(
      'Tüm öneriler',
      style: AppTypography.titleMedium.copyWith(
        color: AppColors.textPrimary,
      ),
    );
  }
}

class _SpacingPanel extends StatelessWidget {
  const _SpacingPanel({
    required this.diameter,
    required this.spacingCtrl,
    required this.onDiameter,
    required this.onChanged,
    required this.onSave,
  });

  final int diameter;
  final TextEditingController spacingCtrl;
  final ValueChanged<int> onDiameter;
  final VoidCallback onChanged;
  final _SaveFn onSave;

  @override
  Widget build(BuildContext context) {
    final spacingCm = double.tryParse(spacingCtrl.text.replaceAll(',', '.'));
    final results = spacingCm != null && spacingCm > 0
        ? computeSpacingTahvilResults(
            sourceDiameter: diameter,
            sourceSpacingMm: spacingCm * 10,
          )
        : const <TahvilSpacingResult>[];
    final allowed = _allowedSpacingAscending(results);
    final recommended = _optimalSpacing(allowed, diameter);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _InputCard(
          title: 'Proje donatısı',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _DiameterChips(selected: diameter, onSelected: onDiameter),
              const SizedBox(height: AppSpacing.md),
              _YellowField(
                label: 'Aralık (cm)',
                controller: spacingCtrl,
                onChanged: (_) => onChanged(),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (recommended != null)
          TahvilHeroSaveCard(
            sourceLine: 'Ø$diameter / ${formatCm(spacingCm!)} cm',
            sourceAs: recommended.sourceAsPerMeterMm2,
            targetLine:
                'Ø${recommended.targetDiameter} / '
                '${formatCm(displayTargetSpacingCm(recommended.resultingSpacingMm))} cm',
            targetAs: displayTargetAsPerMeterMm2(
              diameterMm: recommended.targetDiameter,
              spacingMm: recommended.resultingSpacingMm,
            ),
            asUnit: 'mm²/m',
            onSave: () {
              final targetSpacing =
                  formatCm(displayTargetSpacingCm(recommended.resultingSpacingMm));
              final targetAs = displayTargetAsPerMeterMm2(
                diameterMm: recommended.targetDiameter,
                spacingMm: recommended.resultingSpacingMm,
              );
              onSave(
                summary:
                    'Ø$diameter/${formatCm(spacingCm)} cm → '
                    'Ø${recommended.targetDiameter}/$targetSpacing cm',
                detail:
                    'Aralık tahvili · As ${formatAreaMm2(recommended.sourceAsPerMeterMm2)} → '
                    '${formatAreaMm2(targetAs)} mm²/m',
                allowed: true,
                sourceLine: 'Ø$diameter / ${formatCm(spacingCm)} cm',
                targetLine:
                    'Ø${recommended.targetDiameter} / $targetSpacing cm',
                sourceAs: recommended.sourceAsPerMeterMm2,
                targetAs: targetAs,
                asUnit: 'mm²/m',
              );
            },
          )
        else
          const _NeedInputCard(
            text: 'Çap seçin, aralığı yazın — uygun tahvil anında çıkar.',
          ),
        if (allowed.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          _SuggestionsHeader(),
          const SizedBox(height: AppSpacing.sm),
          for (final result in allowed)
            _SuggestionLineTile(
              sourceLine: 'Ø$diameter / ${formatCm(spacingCm!)} cm',
              sourceAs:
                  'As ${formatAreaMm2(result.sourceAsPerMeterMm2)} mm²/m',
              targetLine:
                  'Ø${result.targetDiameter} / '
                  '${formatCm(displayTargetSpacingCm(result.resultingSpacingMm))} cm',
              targetAs:
                  'As ${formatAreaMm2(displayTargetAsPerMeterMm2(
                    diameterMm: result.targetDiameter,
                    spacingMm: result.resultingSpacingMm,
                  ))} mm²/m',
            ),
        ],
      ],
    );
  }
}

class _QuantityPanel extends StatelessWidget {
  const _QuantityPanel({
    required this.diameter,
    required this.quantityCtrl,
    required this.onDiameter,
    required this.onChanged,
    required this.onSave,
  });

  final int diameter;
  final TextEditingController quantityCtrl;
  final ValueChanged<int> onDiameter;
  final VoidCallback onChanged;
  final _SaveFn onSave;

  @override
  Widget build(BuildContext context) {
    final quantity = int.tryParse(quantityCtrl.text);
    final results = quantity != null && quantity > 0
        ? computeSingleQuantityTahvilResults(
            sourceDiameter: diameter,
            sourceQuantity: quantity,
          )
        : const <TahvilSingleQuantityResult>[];
    final allowed = _allowedQuantityAscending(results);
    final recommended = _optimalQuantity(allowed, diameter);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _InputCard(
          title: 'Proje donatısı',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _DiameterChips(selected: diameter, onSelected: onDiameter),
              const SizedBox(height: AppSpacing.md),
              _YellowField(
                label: 'Adet',
                controller: quantityCtrl,
                onChanged: (_) => onChanged(),
                integer: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (recommended != null)
          TahvilHeroSaveCard(
            sourceLine: '$quantity×Ø$diameter',
            sourceAs: recommended.sourceAreaMm2,
            targetLine:
                '${recommended.equivalentQuantity}×Ø${recommended.targetDiameter}',
            targetAs: recommended.targetAreaMm2,
            asUnit: 'mm²',
            onSave: () => onSave(
              summary:
                  '$quantity×Ø$diameter → ${recommended.equivalentQuantity}×Ø${recommended.targetDiameter}',
              detail: formatCrossSectionComparison(
                fromDiameter: diameter,
                fromQuantity: quantity!,
                toDiameter: recommended.targetDiameter,
                toQuantity: recommended.equivalentQuantity,
              ),
              allowed: true,
              sourceLine: '$quantity×Ø$diameter',
              targetLine:
                  '${recommended.equivalentQuantity}×Ø${recommended.targetDiameter}',
              sourceAs: recommended.sourceAreaMm2,
              targetAs: recommended.targetAreaMm2,
              asUnit: 'mm²',
            ),
          )
        else
          const _NeedInputCard(
            text: 'Çap ve adet girin — eşdeğer adet hemen hesaplanır.',
          ),
        if (allowed.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          _SuggestionsHeader(),
          const SizedBox(height: AppSpacing.sm),
          for (final result in allowed)
            _SuggestionLineTile(
              sourceLine: '$quantity×Ø$diameter',
              sourceAs: 'As ${formatAreaMm2(result.sourceAreaMm2)} mm²',
              targetLine:
                  '${result.equivalentQuantity}×Ø${result.targetDiameter}',
              targetAs: 'As ${formatAreaMm2(result.targetAreaMm2)} mm²',
            ),
        ],
      ],
    );
  }
}

class _DualSpacingPanel extends StatelessWidget {
  const _DualSpacingPanel({
    required this.diameterA,
    required this.diameterB,
    required this.spacingACtrl,
    required this.spacingBCtrl,
    required this.onDiameterA,
    required this.onDiameterB,
    required this.onChanged,
    required this.onSave,
  });

  final int diameterA;
  final int diameterB;
  final TextEditingController spacingACtrl;
  final TextEditingController spacingBCtrl;
  final ValueChanged<int> onDiameterA;
  final ValueChanged<int> onDiameterB;
  final VoidCallback onChanged;
  final _SaveFn onSave;

  @override
  Widget build(BuildContext context) {
    final spacingA = double.tryParse(spacingACtrl.text.replaceAll(',', '.'));
    final spacingB = double.tryParse(spacingBCtrl.text.replaceAll(',', '.'));
    final suggestions =
        spacingA != null && spacingA > 0 && spacingB != null && spacingB > 0
            ? computeDualSpacingTahvilSuggestions(
                sourceDiameterA: diameterA,
                sourceSpacingMmA: spacingA * 10,
                sourceDiameterB: diameterB,
                sourceSpacingMmB: spacingB * 10,
              )
            : const <TahvilDualSpacingSuggestion>[];
    final allowed = _allowedDualSpacingAscending(suggestions);
    final recommended = _optimalDualSpacing(allowed);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _InputCard(
          title: '1. donatı',
          child: Column(
            children: [
              _DiameterChips(selected: diameterA, onSelected: onDiameterA),
              const SizedBox(height: AppSpacing.md),
              _YellowField(
                label: 'Aralık (cm)',
                controller: spacingACtrl,
                onChanged: (_) => onChanged(),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        _InputCard(
          title: '2. donatı',
          child: Column(
            children: [
              _DiameterChips(selected: diameterB, onSelected: onDiameterB),
              const SizedBox(height: AppSpacing.md),
              _YellowField(
                label: 'Aralık (cm)',
                controller: spacingBCtrl,
                onChanged: (_) => onChanged(),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (recommended != null)
          TahvilHeroSaveCard(
            sourceLine:
                '${_spacingLegSource(recommended.legA)} · '
                '${_spacingLegSource(recommended.legB)}',
            sourceAs: recommended.sourceAsPerMeterMm2,
            targetLine:
                '${_spacingLegTarget(recommended.legA)} · '
                '${_spacingLegTarget(recommended.legB)}',
            targetAs: displayDualSpacingTargetAsPerMeterMm2(
              legA: recommended.legA,
              legB: recommended.legB,
            ),
            asUnit: 'mm²/m',
            onSave: () {
              final targetAs = displayDualSpacingTargetAsPerMeterMm2(
                legA: recommended.legA,
                legB: recommended.legB,
              );
              onSave(
                summary: recommended.summary,
                detail:
                    '2 çeşit aralık · As ${formatAreaMm2(recommended.sourceAsPerMeterMm2)} → '
                    '${formatAreaMm2(targetAs)} mm²/m',
                allowed: true,
                sourceLine:
                    '${_spacingLegSource(recommended.legA)} · '
                    '${_spacingLegSource(recommended.legB)}',
                targetLine:
                    '${_spacingLegTarget(recommended.legA)} · '
                    '${_spacingLegTarget(recommended.legB)}',
                sourceAs: recommended.sourceAsPerMeterMm2,
                targetAs: targetAs,
                asUnit: 'mm²/m',
              );
            },
          )
        else
          const _NeedInputCard(
            text:
                'İki donatı çapını ve aralığını girin — birlikte tahvil önerilir.',
          ),
        if (allowed.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          _SuggestionsHeader(),
          const SizedBox(height: AppSpacing.sm),
          for (final item in allowed)
            _SuggestionLineTile(
              sourceLine:
                  '${_spacingLegSource(item.legA)} · '
                  '${_spacingLegSource(item.legB)}',
              sourceAs:
                  'As ${formatAreaMm2(item.sourceAsPerMeterMm2)} mm²/m',
              targetLine:
                  '${_spacingLegTarget(item.legA)} · '
                  '${_spacingLegTarget(item.legB)}',
              targetAs:
                  'As ${formatAreaMm2(displayDualSpacingTargetAsPerMeterMm2(
                    legA: item.legA,
                    legB: item.legB,
                  ))} mm²/m',
            ),
        ],
      ],
    );
  }
}

class _DualPanel extends StatelessWidget {
  const _DualPanel({
    required this.diameterA,
    required this.diameterB,
    required this.quantityACtrl,
    required this.quantityBCtrl,
    required this.onDiameterA,
    required this.onDiameterB,
    required this.onChanged,
    required this.onSave,
  });

  final int diameterA;
  final int diameterB;
  final TextEditingController quantityACtrl;
  final TextEditingController quantityBCtrl;
  final ValueChanged<int> onDiameterA;
  final ValueChanged<int> onDiameterB;
  final VoidCallback onChanged;
  final _SaveFn onSave;

  @override
  Widget build(BuildContext context) {
    final qtyA = int.tryParse(quantityACtrl.text);
    final qtyB = int.tryParse(quantityBCtrl.text);
    final suggestions = qtyA != null && qtyA > 0 && qtyB != null && qtyB > 0
        ? computeDualQuantityTahvilSuggestions(
            sourceQuantityA: qtyA,
            sourceDiameterA: diameterA,
            sourceQuantityB: qtyB,
            sourceDiameterB: diameterB,
          )
        : const <TahvilDualSuggestion>[];
    final allowed = _allowedDualQuantityAscending(suggestions);
    final recommended = _optimalDualQuantity(allowed);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _InputCard(
          title: '1. donatı',
          child: Column(
            children: [
              _DiameterChips(selected: diameterA, onSelected: onDiameterA),
              const SizedBox(height: AppSpacing.md),
              _YellowField(
                label: 'Adet',
                controller: quantityACtrl,
                onChanged: (_) => onChanged(),
                integer: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        _InputCard(
          title: '2. donatı',
          child: Column(
            children: [
              _DiameterChips(selected: diameterB, onSelected: onDiameterB),
              const SizedBox(height: AppSpacing.md),
              _YellowField(
                label: 'Adet',
                controller: quantityBCtrl,
                onChanged: (_) => onChanged(),
                integer: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (recommended != null)
          TahvilHeroSaveCard(
            sourceLine:
                '${recommended.legA.sourceQuantity}×Ø${recommended.legA.sourceDiameter} · '
                '${recommended.legB.sourceQuantity}×Ø${recommended.legB.sourceDiameter}',
            sourceAs: recommended.sourceAreaMm2,
            targetLine:
                '${recommended.legA.targetQuantity}×Ø${recommended.legA.targetDiameter} · '
                '${recommended.legB.targetQuantity}×Ø${recommended.legB.targetDiameter}',
            targetAs: recommended.targetAreaMm2,
            asUnit: 'mm²',
            onSave: () => onSave(
              summary: recommended.summary,
              detail:
                  '2 çeşit · As ${formatAreaMm2(recommended.sourceAreaMm2)} → '
                  '${formatAreaMm2(recommended.targetAreaMm2)} mm²',
              allowed: true,
              sourceLine:
                  '${recommended.legA.sourceQuantity}×Ø${recommended.legA.sourceDiameter} · '
                  '${recommended.legB.sourceQuantity}×Ø${recommended.legB.sourceDiameter}',
              targetLine:
                  '${recommended.legA.targetQuantity}×Ø${recommended.legA.targetDiameter} · '
                  '${recommended.legB.targetQuantity}×Ø${recommended.legB.targetDiameter}',
              sourceAs: recommended.sourceAreaMm2,
              targetAs: recommended.targetAreaMm2,
              asUnit: 'mm²',
            ),
          )
        else
          const _NeedInputCard(
            text: 'İki çeşit donatıyı girin — birlikte tahvil önerilir.',
          ),
        if (allowed.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          _SuggestionsHeader(),
          const SizedBox(height: AppSpacing.sm),
          for (final item in allowed)
            _SuggestionLineTile(
              sourceLine:
                  '${item.legA.sourceQuantity}×Ø${item.legA.sourceDiameter} · '
                  '${item.legB.sourceQuantity}×Ø${item.legB.sourceDiameter}',
              sourceAs: 'As ${formatAreaMm2(item.sourceAreaMm2)} mm²',
              targetLine:
                  '${item.legA.targetQuantity}×Ø${item.legA.targetDiameter} · '
                  '${item.legB.targetQuantity}×Ø${item.legB.targetDiameter}',
              targetAs: 'As ${formatAreaMm2(item.targetAreaMm2)} mm²',
            ),
        ],
      ],
    );
  }
}

class _InputCard extends StatelessWidget {
  const _InputCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SJCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: AppTypography.cardLabelMedium),
          const SizedBox(height: AppSpacing.sm),
          child,
        ],
      ),
    );
  }
}

class _NeedInputCard extends StatelessWidget {
  const _NeedInputCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return SJCard(
      child: Text(text, style: AppTypography.cardBodyMedium),
    );
  }
}

String _spacingLegSource(TahvilDualSpacingLeg leg) =>
    'Ø${leg.sourceDiameter} / ${formatCm(leg.sourceSpacingMm / 10)} cm';

String _spacingLegTarget(TahvilDualSpacingLeg leg) =>
    'Ø${leg.targetDiameter} / '
    '${formatCm(displayTargetSpacingCm(leg.targetSpacingMm))} cm';

class _SuggestionLineTile extends StatelessWidget {
  const _SuggestionLineTile({
    required this.sourceLine,
    required this.sourceAs,
    required this.targetLine,
    required this.targetAs,
  });

  final String sourceLine;
  final String sourceAs;
  final String targetLine;
  final String targetAs;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SJCard(
        accentColor: AppColors.success,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TahvilHeroRow(
              donatiLine: sourceLine,
              asLabel: sourceAs,
              color: AppColors.statusInkOnCard(AppColors.electricBlue),
            ),
            const SizedBox(height: AppSpacing.sm),
            TahvilHeroRow(
              donatiLine: targetLine,
              asLabel: targetAs,
              color: AppColors.statusInkOnCard(AppColors.success),
            ),
          ],
        ),
      ),
    );
  }
}

class _DiameterChips extends StatelessWidget {
  const _DiameterChips({
    required this.selected,
    required this.onSelected,
  });

  final int selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final d in RebarWeight.standardDiameters)
          GestureDetector(
            onTap: () => onSelected(d),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: d == selected
                    ? AppColors.electricBlue
                    : AppColors.cardInsetSurface,
                borderRadius: AppRadii.sm,
                border: Border.all(
                  color: d == selected
                      ? AppColors.electricBlue
                      : AppColors.cardBorder,
                ),
              ),
              child: Text(
                'Ø$d',
                style: AppTypography.cardLabelLarge.copyWith(
                  color: d == selected
                      ? Colors.white
                      : AppColors.cardTextPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Excel sarı hücre — düzenlenebilir girdi.
class _YellowField extends StatelessWidget {
  const _YellowField({
    required this.label,
    required this.controller,
    required this.onChanged,
    this.integer = false,
  });

  static const _fill = Color(0xFFFFF8E1);
  static const _ink = Color(0xFF0B1220);

  final String label;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final bool integer;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.cardLabelMedium),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(
              integer ? RegExp(r'[0-9]') : RegExp(r'[0-9.,]'),
            ),
          ],
          onChanged: onChanged,
          style: AppTypography.titleLarge.copyWith(color: _ink),
          decoration: InputDecoration(
            filled: true,
            fillColor: _fill,
            isDense: true,
            hintText: integer ? 'adet' : 'cm',
            hintStyle: AppTypography.bodyMedium.copyWith(
              color: const Color(0xFF6B7A90),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: AppRadii.sm,
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: AppRadii.sm,
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: AppRadii.sm,
              borderSide: const BorderSide(color: AppColors.electricBlue),
            ),
          ),
        ),
      ],
    );
  }
}
