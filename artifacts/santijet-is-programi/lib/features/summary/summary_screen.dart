import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../domain/program_item.dart';
import '../../state/app_state.dart';
import '../../ui/design_system.dart';

class SummaryScreen extends ConsumerWidget {
  const SummaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final site = ref.watch(activeSiteProvider);
    final items = ref
        .watch(programItemsProvider)
        .where((item) => item.santiyeId == site)
        .toList();
    final delayed = items
        .where((item) => item.effectiveStatus() == ProgramStatus.delayed)
        .toList();

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
                        const Text(
                          'DURUM KIRILIMI',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ...ProgramStatus.values.map((status) {
                          final count = items
                              .where((item) => item.effectiveStatus() == status)
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
                  const SizedBox(height: 12),
                  SJCard(
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'ORTALAMA İLERLEME',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                items.isEmpty
                                    ? '%0'
                                    : '%${items.map((e) => e.progress).reduce((a, b) => a + b) ~/ items.length}',
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
                    const SJCard(child: Text('Geciken faaliyet bulunmuyor.'))
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
                                      '%${item.progress} · ${item.responsible}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall,
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
