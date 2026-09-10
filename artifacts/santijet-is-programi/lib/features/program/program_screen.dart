import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../domain/program_item.dart';
import '../../state/app_state.dart';
import '../../ui/design_system.dart';

class ProgramScreen extends ConsumerWidget {
  const ProgramScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final all = ref.watch(programItemsProvider);
    final selectedSite = ref.watch(activeSiteProvider);
    final sites = {selectedSite, ...all.map((item) => item.santiyeId)}.toList()
      ..sort();
    final items = all.where((item) => item.santiyeId == selectedSite).toList();
    final delayed = items
        .where((item) => item.effectiveStatus() == ProgramStatus.delayed)
        .length;
    final active = items
        .where((item) => item.effectiveStatus() == ProgramStatus.inProgress)
        .length;

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
                  DropdownButtonFormField<String>(
                    initialValue: selectedSite,
                    decoration: const InputDecoration(
                      labelText: 'Aktif şantiye',
                      prefixIcon: Icon(Icons.apartment_rounded),
                    ),
                    items: sites
                        .map(
                          (site) =>
                              DropdownMenuItem(value: site, child: Text(site)),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        ref.read(activeSiteProvider.notifier).select(value);
                      }
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: _Kpi(label: 'Toplam', value: items.length),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _Kpi(
                          label: 'Devam',
                          value: active,
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
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'FAALİYETLER',
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
                    ...items.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _ProgramItemCard(
                          item: item,
                          onTap: () => context.push('/form', extra: item),
                        ),
                      ),
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

class _ProgramItemCard extends StatelessWidget {
  const _ProgramItemCard({required this.item, required this.onTap});
  final ProgramItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('dd.MM');
    final status = item.effectiveStatus();
    return SJCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(item.name, style: AppTypography.cardTitleMedium),
              ),
              const SizedBox(width: 8),
              ProgramStatusBadge(status: status),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: AppRadii.sm,
            child: LinearProgressIndicator(
              value: item.progress / 100,
              minHeight: 7,
              backgroundColor: AppColors.cardBorder,
              color: programStatusColor(status),
            ),
          ),
          const SizedBox(height: 9),
          Row(
            children: [
              Text('%${item.progress}', style: AppTypography.cardTitleMedium),
              const Spacer(),
              Icon(
                Icons.person_outline,
                size: 15,
                color: AppColors.cardTextMuted,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  item.responsible.isEmpty ? 'Atanmadı' : item.responsible,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.cardBodySmall,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${date.format(item.startDate)} – ${date.format(item.endDate)}',
                style: AppTypography.cardBodySmall,
              ),
            ],
          ),
        ],
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
            'Bu şantiye için henüz faaliyet yok.',
            style: AppTypography.cardBodyMedium,
          ),
        ],
      ),
    ),
  );
}
