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
                    _EntryTable(
                      items: items,
                      row: row,
                      onTap: (item) => context.push('/form', extra: item),
                    ),
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

class _EntryTable extends StatelessWidget {
  const _EntryTable({
    required this.items,
    required this.row,
    required this.onTap,
  });

  final List<ProgramItem> items;
  final ManDayProgress Function(ProgramItem item) row;
  final ValueChanged<ProgramItem> onTap;

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('dd.MM.yyyy');
    return SJCard(
      padding: EdgeInsets.zero,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          showCheckboxColumn: false,
          headingTextStyle: AppTypography.cardBodySmall.copyWith(
            fontWeight: FontWeight.w700,
          ),
          dataTextStyle: AppTypography.cardBodySmall,
          columnSpacing: 18,
          columns: const [
            DataColumn(label: Text('ID')),
            DataColumn(label: Text('Ad')),
            DataColumn(label: Text('Süre')),
            DataColumn(label: Text('Başlangıç')),
            DataColumn(label: Text('Bitiş')),
            DataColumn(label: Text('Öncüller')),
            DataColumn(label: Text('Kaynak Adları')),
            DataColumn(label: Text('% Tamamlanma')),
          ],
          rows: [
            for (var index = 0; index < items.length; index++)
              DataRow(
                onSelectChanged: (_) => onTap(items[index]),
                cells: [
                  DataCell(Text('${index + 1}')),
                  DataCell(
                    SizedBox(
                      width: 160,
                      child: Text(
                        items[index].name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  DataCell(
                    Text(
                      items[index].isMilestone
                          ? '0 gün'
                          : '${items[index].calculatedDays} gün',
                    ),
                  ),
                  DataCell(Text(date.format(items[index].startDate))),
                  DataCell(Text(date.format(items[index].endDate))),
                  DataCell(Text(items[index].predecessors ?? '')),
                  DataCell(Text(items[index].responsible)),
                  DataCell(Text('%${row(items[index]).progress}')),
                ],
              ),
          ],
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
