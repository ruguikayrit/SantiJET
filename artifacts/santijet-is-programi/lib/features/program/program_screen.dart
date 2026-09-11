import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../domain/man_day_progress.dart';
import '../../domain/program_item.dart';
import '../../state/app_state.dart';
import '../../ui/design_system.dart';

class ProgramScreen extends ConsumerWidget {
  const ProgramScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final all = ref.watch(programItemsProvider);
    final logs = ref.watch(dailyCrewProvider);
    final selectedSite = ref.watch(activeSiteProvider);
    final project = ref.watch(activeProjectProvider);
    final items = all.where((item) => item.santiyeId == selectedSite).toList();
    ManDayProgress row(ProgramItem item) =>
        ManDayProgress.of(item, logs);
    final delayed = items
        .where((item) => row(item).effectiveStatus == ProgramStatus.delayed)
        .length;
    final active = items
        .where((item) => row(item).effectiveStatus == ProgramStatus.inProgress)
        .length;
    final summary = SiteManDaySummary.of(items, logs);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const SantijetHeader(showWordmark: true),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                children: [
                  SJCard(
                    onTap: () => context.push('/settings/projeler'),
                    child: Row(
                      children: [
                        Icon(
                          Icons.apartment_rounded,
                          color: AppColors.electricBlue,
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                project?.name ?? selectedSite,
                                style: AppTypography.cardTitleMedium,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                project == null
                                    ? 'Proje seç veya oluştur'
                                    : 'İş kodu ${project.code}',
                                style: AppTypography.cardBodySmall,
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          color: AppColors.cardTextMuted,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: _Kpi(
                          label: 'İş',
                          value: summary.planned,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _Kpi(
                          label: 'Fiili İş',
                          value: summary.realized,
                          color: AppColors.electricBlue,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _Kpi(
                          label: 'Geciken',
                          value: delayed,
                          color: AppColors.critical,
                        ),
                      ),
                    ],
                  ),
                  if (active > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        '$active görev devam ediyor',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'GİRİŞ',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (items.isEmpty)
                    const _EmptyProgram()
                  else
                    ...[
                      for (var index = 0; index < items.length; index++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _EntryCard(
                            index: index + 1,
                            item: items[index],
                            progress: row(items[index]),
                            onTap: () =>
                                context.push('/form', extra: items[index]),
                          ),
                        ),
                    ],
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/form'),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Ekle'),
      ),
    );
  }
}

class _Kpi extends StatelessWidget {
  const _Kpi({required this.label, required this.value, this.color});
  final String label;
  final int value;
  final Color? color;

  @override
  Widget build(BuildContext context) => SJCard(
    padding: const EdgeInsets.all(14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$value',
          style: AppTypography.kpiValue.copyWith(
            color: color ?? AppColors.cardTextPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: AppTypography.cardBodySmall),
      ],
    ),
  );
}

class _EntryCard extends StatelessWidget {
  const _EntryCard({
    required this.index,
    required this.item,
    required this.progress,
    required this.onTap,
  });

  final int index;
  final ProgramItem item;
  final ManDayProgress progress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('dd.MM');
    final status = progress.effectiveStatus;
    final color = programStatusColor(status);
    final duration = item.isMilestone ? '0g' : '${item.calculatedDays}g';
    final predecessors = (item.predecessors ?? '').trim();
    final resource = item.responsible.trim();
    final meta = [
      if (predecessors.isNotEmpty) predecessors,
      if (resource.isNotEmpty) resource,
    ].join('  ·  ');

    return SJCard(
      onTap: onTap,
      accentColor: color,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 22,
                child: Text(
                  '$index',
                  style: AppTypography.cardBodySmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.cardTextMuted,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  item.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.cardTitleMedium,
                ),
              ),
              const SizedBox(width: 8),
              _PercentPill(value: progress.progress, color: color),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '$duration  ·  ${date.format(item.startDate)} – '
            '${date.format(item.endDate)}',
            style: AppTypography.cardBodySmall,
          ),
          if (meta.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              meta,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.cardBodySmall.copyWith(
                color: AppColors.cardTextMuted,
              ),
            ),
          ],
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: AppRadii.sm,
            child: LinearProgressIndicator(
              value: progress.progress / 100,
              minHeight: 5,
              backgroundColor: AppColors.cardBorder,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _PercentPill extends StatelessWidget {
  const _PercentPill({required this.value, required this.color});

  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: AppRadii.full,
      ),
      child: Text(
        '%$value',
        style: AppTypography.cardBodySmall.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _EmptyProgram extends StatelessWidget {
  const _EmptyProgram();

  @override
  Widget build(BuildContext context) => SJCard(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Icon(
            Icons.event_note_rounded,
            size: 38,
            color: AppColors.cardTextMuted,
          ),
          const SizedBox(height: 10),
          Text(
            'Bu şantiye için henüz görev yok.',
            style: AppTypography.cardBodyMedium,
          ),
        ],
      ),
    ),
  );
}
