import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../domain/man_day_progress.dart';
import '../../domain/program_item.dart';
import '../../state/app_state.dart';
import '../../ui/design_system.dart';

class SummaryScreen extends ConsumerWidget {
  const SummaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final site = ref.watch(activeSiteProvider);
    final logs = ref.watch(dailyCrewProvider);
    final items = ref
        .watch(programItemsProvider)
        .where((item) => item.santiyeId == site)
        .toList();
    final totals = SiteManDaySummary.of(items, logs);
    ManDayProgress row(ProgramItem item) => ManDayProgress.of(item, logs);
    final delayed = items
        .where((item) => row(item).effectiveStatus == ProgramStatus.delayed)
        .toList();
    final behind = items.where((item) {
      final progress = row(item);
      return progress.hasLogs && progress.varianceToDate < 0;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const SantijetHeader(subtitle: 'Özet'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                children: [
                  SJCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PLAN / GERÇEKLEŞEN',
                          style: AppTypography.onCard(
                            AppTypography.labelSmall,
                          ).copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.1,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: _AgKpi(
                                label: 'PLAN',
                                value: totals.planned,
                              ),
                            ),
                            Expanded(
                              child: _AgKpi(
                                label: 'GERÇEK',
                                value: totals.realized,
                                color: AppColors.electricBlue,
                              ),
                            ),
                            Expanded(
                              child: _AgKpi(
                                label: 'KALAN',
                                value: totals.remaining,
                                color: AppColors.warning,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          totals.varianceToDate < 0
                              ? 'Bugüne kadar planın ${-totals.varianceToDate} adam-gün gerisinde.'
                              : 'Bugüne kadar plan ${totals.plannedToDate} AG, gerçekleşen ${totals.realized} AG.',
                          style: AppTypography.cardBodySmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  SJCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'İŞÇİLİK HAKEDIŞ SİNYALİ',
                          style: AppTypography.onCard(
                            AppTypography.labelSmall,
                          ).copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Gerçekleşen ${totals.realized} adam-gün işçilik hakedişine, '
                          'kalan ${totals.remaining} adam-gün ise sıradaki malzeme '
                          'alımı ve nakit ihtiyacına işaret eder. Ödeme veya satınalma '
                          'bu üründe tutulmaz.',
                          style: AppTypography.cardBodySmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  SJCard(
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ORTALAMA İLERLEME',
                                style: AppTypography.onCard(
                                  AppTypography.labelSmall,
                                ).copyWith(
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.1,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                '%${totals.progress}',
                                style: AppTypography.kpiValue.copyWith(
                                  color: AppColors.electricBlue,
                                  fontSize: 34,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SJButton(
                          label: 'Aktar',
                          icon: Icons.swap_vert_rounded,
                          variant: SJButtonVariant.secondary,
                          onPressed: () => context.push('/aktar'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  SJCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'DURUM KIRILIMI',
                          style: AppTypography.onCard(
                            AppTypography.labelSmall,
                          ).copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.1,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ...ProgramStatus.values.map((status) {
                          final count = items
                              .where((item) => row(item).effectiveStatus == status)
                              .length;
                          return _BreakdownRow(
                            status: status,
                            count: count,
                            total: items.length,
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    'PLANIN GERİSİNDE (${behind.length})',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (behind.isEmpty)
                    const SJCard(
                      child: Text('Bugüne kadar planın gerisinde imalat yok.'),
                    )
                  else
                    ...behind.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _GapCard(progress: row(item)),
                      ),
                    ),
                  const SizedBox(height: 22),
                  Text(
                    'GECİKENLER (${delayed.length})',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (delayed.isEmpty)
                    const SJCard(child: Text('Süresi dolup bitmeyen imalat yok.'))
                  else
                    ...delayed.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: SJCard(
                          child: Row(
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                color: AppColors.critical,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    Text(
                                      '${DateFormat('dd.MM.yyyy').format(item.endDate)} · '
                                      '${row(item).realizedManDays}/${row(item).plannedManDays} AG',
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AgKpi extends StatelessWidget {
  const _AgKpi({required this.label, required this.value, this.color});
  final String label;
  final int value;
  final Color? color;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: AppTypography.cardBodySmall),
      const SizedBox(height: 4),
      Text(
        '$value',
        style: AppTypography.kpiValue.copyWith(
          fontSize: 26,
          color: color ?? AppColors.cardTextPrimary,
        ),
      ),
      Text('AG', style: AppTypography.cardBodySmall),
    ],
  );
}

class _GapCard extends StatelessWidget {
  const _GapCard({required this.progress});
  final ManDayProgress progress;

  @override
  Widget build(BuildContext context) => SJCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(progress.item.name, style: AppTypography.cardTitleMedium),
        const SizedBox(height: 4),
        Text(
          'Plan ${progress.plannedToDate} AG · Gerçek ${progress.realizedManDays} AG · '
          '${-progress.varianceToDate} AG açık',
          style: AppTypography.cardBodySmall,
        ),
      ],
    ),
  );
}

class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow({
    required this.status,
    required this.count,
    required this.total,
  });
  final ProgramStatus status;
  final int count;
  final int total;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 13),
    child: Row(
      children: [
        SizedBox(width: 105, child: ProgramStatusBadge(status: status)),
        const SizedBox(width: 10),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: total == 0 ? 0 : count / total,
              minHeight: 9,
              backgroundColor: AppColors.cardBorder,
            ),
          ),
        ),
        SizedBox(
          width: 34,
          child: Text(
            '$count',
            textAlign: TextAlign.end,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
}
