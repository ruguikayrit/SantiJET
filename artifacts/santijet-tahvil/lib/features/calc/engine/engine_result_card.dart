import 'package:flutter/material.dart';

import '../../../core/design_system/sj_button.dart';
import '../../../core/design_system/sj_card.dart';
import '../../../core/design_system/sj_status_badge.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/tahvil_hero_card.dart';
import '../../../domain/engine/engine.dart';

Color _verdictColor(TahvilVerdict verdict) => switch (verdict) {
      TahvilVerdict.suitable => AppColors.success,
      TahvilVerdict.notSuitable => AppColors.critical,
      TahvilVerdict.engineerReview => AppColors.warning,
    };

class EngineResultCard extends StatelessWidget {
  const EngineResultCard({
    required this.result,
    required this.onSave,
    super.key,
  });

  final TahvilResult result;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    if (!result.isValid) {
      return SJCard(
        accentColor: AppColors.critical,
        child: Text(
          result.inputError ?? 'Geçersiz giriş',
          style: AppTypography.cardBodyMedium,
        ),
      );
    }

    final color = _verdictColor(result.verdict);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TahvilHeroCard(
          title: 'Önerilen tahvil',
          badgeLabel: result.verdict.label,
          badgeColor: color,
          sourceLine: result.projectLine ?? 'Proje',
          sourceAs: result.projectAs ?? 0,
          targetLine: result.newLine ?? 'Yeni',
          targetAs: result.newAs ?? 0,
          asUnit: result.asUnit,
          footer: Text(
            result.outcomeLine,
            style: AppTypography.cardBodySmall,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.md),
              _AsSummary(result: result),
              const SizedBox(height: AppSpacing.md),
              SJButton(
                label: 'Kaydet',
                icon: Icons.bookmark_add_outlined,
                onPressed: onSave,
                expanded: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _ResultTable(rows: result.table),
        const SizedBox(height: AppSpacing.md),
        _CheckList(checks: result.checks),
        const SizedBox(height: AppSpacing.sm),
        Text(
          TahvilResult.disclaimer,
          style: AppTypography.cardBodySmall,
        ),
      ],
    );
  }
}

class EngineSuggestionsBlock extends StatelessWidget {
  const EngineSuggestionsBlock({
    required this.suggestions,
    super.key,
  });

  final List<TahvilSuggestion> suggestions;

  @override
  Widget build(BuildContext context) {
    final shown = suggestions.where((s) => s.isAcceptable).take(6).toList();
    if (shown.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Tüm öneriler', style: AppTypography.cardLabelMedium),
        const SizedBox(height: AppSpacing.sm),
        for (final item in shown)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: SJCard(
              accentColor: _verdictColor(item.result.verdict),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TahvilHeroRow(
                    donatiLine: item.result.projectLine ?? '',
                    asLabel:
                        'As ${RebarMath.formatArea(item.result.projectAs ?? 0)} ${item.result.asUnit}',
                    color: AppColors.statusInkOnCard(AppColors.electricBlue),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TahvilHeroRow(
                    donatiLine: item.label,
                    asLabel:
                        'As ${RebarMath.formatArea(item.result.newAs ?? 0)} ${item.result.asUnit}',
                    color: AppColors.statusInkOnCard(AppColors.success),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _AsSummary extends StatelessWidget {
  const _AsSummary({required this.result});

  final TahvilResult result;

  @override
  Widget build(BuildContext context) {
    final delta = result.asDelta;
    final percent = result.asDeltaPercent;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _kv('Proje As', '${RebarMath.formatArea(result.projectAs ?? 0)} ${result.asUnit}'),
        _kv('Yeni As', '${RebarMath.formatArea(result.newAs ?? 0)} ${result.asUnit}'),
        if (delta != null)
          _kv(
            'As farkı',
            '${delta >= 0 ? '+' : ''}${RebarMath.formatArea(delta)} ${result.asUnit}',
          ),
        if (percent != null)
          _kv(
            'As değişim yüzdesi',
            '${percent >= 0 ? '+' : ''}${percent.toStringAsFixed(2)} %',
          ),
        _kv('Kontrol sonucu', result.outcomeLine),
        _kv('Uygunluk', result.verdict.label),
      ],
    );
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Expanded(child: Text(k, style: AppTypography.cardBodySmall)),
          Text(v, style: AppTypography.cardTitleMedium),
        ],
      ),
    );
  }
}

class _ResultTable extends StatelessWidget {
  const _ResultTable({required this.rows});

  final List<TahvilTableRow> rows;

  @override
  Widget build(BuildContext context) {
    return SJCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Kontrol tablosu', style: AppTypography.cardLabelMedium),
          const SizedBox(height: AppSpacing.sm),
          _tableRow('Parametre', 'Proje', 'Yeni', 'Sonuç', header: true),
          for (final row in rows)
            _tableRow(row.parameter, row.project, row.replacement, row.mark),
        ],
      ),
    );
  }

  Widget _tableRow(
    String a,
    String b,
    String c,
    String d, {
    bool header = false,
  }) {
    final style = header
        ? AppTypography.cardLabelSmall
        : AppTypography.cardBodySmall;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(flex: 4, child: Text(a, style: style)),
          Expanded(flex: 3, child: Text(b, style: style)),
          Expanded(flex: 3, child: Text(c, style: style)),
          SizedBox(
            width: 36,
            child: Text(d, style: style, textAlign: TextAlign.right),
          ),
        ],
      ),
    );
  }
}

class _CheckList extends StatelessWidget {
  const _CheckList({required this.checks});

  final List<TahvilCheck> checks;

  @override
  Widget build(BuildContext context) {
    return SJCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Neden bu sonuç?', style: AppTypography.cardLabelMedium),
          const SizedBox(height: AppSpacing.sm),
          for (final check in checks) ...[
            Row(
              children: [
                SJStatusBadge(
                  label: check.status.mark,
                  color: switch (check.status) {
                    CheckStatus.passed => AppColors.success,
                    CheckStatus.failed => AppColors.critical,
                    CheckStatus.engineerReview => AppColors.warning,
                    CheckStatus.info => AppColors.textMuted,
                  },
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(check.title, style: AppTypography.cardTitleMedium),
                ),
              ],
            ),
            if (check.message != null)
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 2),
                child: Text(check.message!, style: AppTypography.cardBodySmall),
              ),
            Text(
              '${check.rule.citation} · ${check.rule.ruleCode}',
              style: AppTypography.cardLabelSmall,
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}
