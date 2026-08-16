import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_info.dart';
import '../../core/design_system/sj_button.dart';
import '../../core/design_system/sj_card.dart';
import '../../core/design_system/sj_status_badge.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/santijet_header.dart';
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
  TahvilCalculatorBasis _basis = TahvilCalculatorBasis.spacing;

  int _sourceDiameter = 16;
  int _sourceDiameterB = 12;

  late final TextEditingController _spacingCtrl;
  late final TextEditingController _quantityCtrl;
  late final TextEditingController _quantityBCtrl;

  @override
  void initState() {
    super.initState();
    _spacingCtrl = TextEditingController(text: '15');
    _quantityCtrl = TextEditingController(text: '10');
    _quantityBCtrl = TextEditingController(text: '8');
  }

  @override
  void dispose() {
    _spacingCtrl.dispose();
    _quantityCtrl.dispose();
    _quantityBCtrl.dispose();
    super.dispose();
  }

  void _refresh() => setState(() {});

  Future<void> _save({
    required String summary,
    required String detail,
    required bool allowed,
  }) async {
    final record = TahvilRecord(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      createdAt: DateTime.now(),
      basis: _basis.label,
      summary: summary,
      detail: detail,
      isAllowed: allowed,
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
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                children: [
                  Text(
                    AppInfo.tagline,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _RuleStrip(),
                  const SizedBox(height: AppSpacing.md),
                  _ModeBar(
                    selected: _basis,
                    onChanged: (value) => setState(() => _basis = value),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  switch (_basis) {
                    TahvilCalculatorBasis.spacing => _SpacingPanel(
                        diameter: _sourceDiameter,
                        spacingCtrl: _spacingCtrl,
                        onDiameter: (d) =>
                            setState(() => _sourceDiameter = d),
                        onChanged: _refresh,
                        onSave: _save,
                      ),
                    TahvilCalculatorBasis.quantity => _QuantityPanel(
                        diameter: _sourceDiameter,
                        quantityCtrl: _quantityCtrl,
                        onDiameter: (d) =>
                            setState(() => _sourceDiameter = d),
                        onChanged: _refresh,
                        onSave: _save,
                      ),
                    TahvilCalculatorBasis.dual => _DualPanel(
                        diameterA: _sourceDiameter,
                        diameterB: _sourceDiameterB,
                        quantityACtrl: _quantityCtrl,
                        quantityBCtrl: _quantityBCtrl,
                        onDiameterA: (d) =>
                            setState(() => _sourceDiameter = d),
                        onDiameterB: (d) =>
                            setState(() => _sourceDiameterB = d),
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

class _RuleStrip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.sm,
        border: Border.all(
          color: AppColors.electricBlue.withValues(alpha: 0.22),
        ),
      ),
      child: Text(
        '±$tahvilMaxDiameterDiffMm mm çap  ·  kesit ≥ proje  ·  '
        'fazla ≤ %${(tahvilMaxAreaDeviationRatio * 100).toStringAsFixed(0)}  ·  '
        'aralık ≤ ${tahvilMaxSpacingCm.toStringAsFixed(0)} cm',
        style: AppTypography.labelSmall.copyWith(
          color: AppColors.textSecondary,
          letterSpacing: 0.1,
          height: 1.35,
        ),
      ),
    );
  }
}

class _ModeBar extends StatelessWidget {
  const _ModeBar({required this.selected, required this.onChanged});

  final TahvilCalculatorBasis selected;
  final ValueChanged<TahvilCalculatorBasis> onChanged;

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
          for (final mode in TahvilCalculatorBasis.values)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onChanged(mode),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: selected == mode
                        ? AppColors.electricBlue
                        : Colors.transparent,
                    borderRadius: AppRadii.xs,
                  ),
                  child: Text(
                    mode.label,
                    textAlign: TextAlign.center,
                    style: AppTypography.labelLarge.copyWith(
                      color: selected == mode
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
});

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
    final allowed = results.where((r) => r.isAllowed).toList();
    final recommended = allowed.isEmpty ? null : allowed.first;

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
          _HeroResult(
            fromLabel: 'Ø$diameter / ${formatCm(spacingCm!)} cm',
            toLabel:
                'Ø${recommended.targetDiameter} / ${formatCm(recommended.resultingSpacingCm)} cm',
            meta:
                'As ${formatAreaMm2(recommended.sourceAsPerMeterMm2)} → '
                '${formatAreaMm2(recommended.targetAsPerMeterMm2)} mm²/m',
            allowed: true,
            onSave: () => onSave(
              summary:
                  'Ø$diameter/${formatCm(spacingCm)} cm → '
                  'Ø${recommended.targetDiameter}/${formatCm(recommended.resultingSpacingCm)} cm',
              detail:
                  'Aralık tahvili · As ${formatAreaMm2(recommended.sourceAsPerMeterMm2)} → '
                  '${formatAreaMm2(recommended.targetAsPerMeterMm2)} mm²/m',
              allowed: true,
            ),
          )
        else
          const _NeedInputCard(
            text: 'Çap seçin, aralığı yazın — uygun tahvil anında çıkar.',
          ),
        if (results.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          Text('Tüm çaplar', style: AppTypography.titleMedium.copyWith(
            color: AppColors.textPrimary,
          )),
          const SizedBox(height: AppSpacing.sm),
          for (final result in results)
            _ResultTile(
              title:
                  'Ø${result.targetDiameter} / ${formatCm(result.resultingSpacingCm)} cm',
              subtitle: result.rejectReason ??
                  'As ${formatAreaMm2(result.targetAsPerMeterMm2)} mm²/m',
              allowed: result.isAllowed,
              adequate: result.isAdequate,
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
    final allowed = results.where((r) => r.isAllowed).toList();
    final recommended = allowed.isEmpty ? null : allowed.first;

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
          _HeroResult(
            fromLabel: '$quantity×Ø$diameter',
            toLabel: '${recommended.equivalentQuantity}×Ø${recommended.targetDiameter}',
            meta: formatCrossSectionComparison(
              fromDiameter: diameter,
              fromQuantity: quantity!,
              toDiameter: recommended.targetDiameter,
              toQuantity: recommended.equivalentQuantity,
            ),
            allowed: true,
            onSave: () => onSave(
              summary:
                  '$quantity×Ø$diameter → ${recommended.equivalentQuantity}×Ø${recommended.targetDiameter}',
              detail: formatCrossSectionComparison(
                fromDiameter: diameter,
                fromQuantity: quantity,
                toDiameter: recommended.targetDiameter,
                toQuantity: recommended.equivalentQuantity,
              ),
              allowed: true,
            ),
          )
        else
          const _NeedInputCard(
            text: 'Çap ve adet girin — eşdeğer adet hemen hesaplanır.',
          ),
        if (results.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          Text('Tüm çaplar', style: AppTypography.titleMedium.copyWith(
            color: AppColors.textPrimary,
          )),
          const SizedBox(height: AppSpacing.sm),
          for (final result in results)
            _ResultTile(
              title: '${result.equivalentQuantity}×Ø${result.targetDiameter}',
              subtitle: result.rejectReason ??
                  'Sapma %${result.areaDeviationPercent.toStringAsFixed(1)}',
              allowed: result.isAllowed,
              adequate: result.isAdequate,
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
    final allowedDual = suggestions.where((s) => s.isAllowed);
    final recommended = allowedDual.isEmpty ? null : allowedDual.first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _InputCard(
          title: '1. çeşit',
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
          title: '2. çeşit',
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
          _HeroResult(
            fromLabel: recommended.legA.label.split(' → ').first,
            toLabel: recommended.summary,
            meta:
                'As ${formatAreaMm2(recommended.sourceAreaMm2)} → '
                '${formatAreaMm2(recommended.targetAreaMm2)} mm²',
            allowed: true,
            onSave: () => onSave(
              summary: recommended.summary,
              detail:
                  '2 çeşit · As ${formatAreaMm2(recommended.sourceAreaMm2)} → '
                  '${formatAreaMm2(recommended.targetAreaMm2)} mm²',
              allowed: true,
            ),
          )
        else
          const _NeedInputCard(
            text: 'İki çeşit donatıyı girin — birlikte tahvil önerilir.',
          ),
        if (suggestions.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          Text('Öneriler', style: AppTypography.titleMedium.copyWith(
            color: AppColors.textPrimary,
          )),
          const SizedBox(height: AppSpacing.sm),
          for (final item in suggestions)
            _ResultTile(
              title: item.summary,
              subtitle: item.isAllowed
                  ? 'Sapma %${item.areaDeviationPercent.toStringAsFixed(1)}'
                  : 'Kural dışı veya fazla kesit',
              allowed: item.isAllowed,
              adequate: item.isAdequate,
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

class _HeroResult extends StatelessWidget {
  const _HeroResult({
    required this.fromLabel,
    required this.toLabel,
    required this.meta,
    required this.allowed,
    required this.onSave,
  });

  final String fromLabel;
  final String toLabel;
  final String meta;
  final bool allowed;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return SJCard(
      accentColor: allowed ? AppColors.success : AppColors.critical,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text('Önerilen tahvil', style: AppTypography.cardLabelMedium),
              const Spacer(),
              SJStatusBadge(
                label: allowed ? 'UYGUN' : 'UYGUN DEĞİL',
                color: allowed ? AppColors.success : AppColors.critical,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            fromLabel,
            style: AppTypography.cardBodySmall,
          ),
          const SizedBox(height: 4),
          Icon(
            Icons.south,
            size: 18,
            color: AppColors.statusInkOnCard(AppColors.electricBlueLight),
          ),
          const SizedBox(height: 4),
          Text(
            toLabel,
            style: AppTypography.onCard(
              AppTypography.kpiValue,
              color: AppColors.statusInkOnCard(AppColors.electricBlue),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(meta, style: AppTypography.cardBodySmall),
          const SizedBox(height: AppSpacing.md),
          SJButton(
            label: 'Kaydet',
            icon: Icons.bookmark_add_outlined,
            onPressed: onSave,
            expanded: true,
          ),
        ],
      ),
    );
  }
}

class _ResultTile extends StatelessWidget {
  const _ResultTile({
    required this.title,
    required this.subtitle,
    required this.allowed,
    required this.adequate,
  });

  final String title;
  final String subtitle;
  final bool allowed;
  final bool adequate;

  @override
  Widget build(BuildContext context) {
    final color = allowed
        ? AppColors.success
        : adequate
            ? AppColors.warning
            : AppColors.critical;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SJCard(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTypography.cardTitleMedium),
                  const SizedBox(height: 2),
                  Text(subtitle, style: AppTypography.cardBodySmall),
                ],
              ),
            ),
            const SizedBox(width: 8),
            SJStatusBadge(
              label: allowed
                  ? 'UYGUN'
                  : adequate
                      ? 'FAZLA'
                      : 'HAYIR',
              color: color,
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
