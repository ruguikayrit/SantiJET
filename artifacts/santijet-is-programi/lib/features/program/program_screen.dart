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
      body: Column(
        children: [
          SantijetHeader(
            title: 'İŞ PROGRAMI',
            subtitle: 'Planla · Takip et · Gecikmeyi gör',
            onSettings: () => context.push('/settings'),
          ),
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
                const SizedBox(height: 16),
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
                        color: AppColors.danger,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                Text(
                  'FAALİYETLER',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontFamily: AppTypography.displayFont,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w700,
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
          style: TextStyle(
            fontFamily: AppTypography.displayFont,
            fontSize: 29,
            height: 1,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
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
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: SJCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    item.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SJStatusBadge(status: status),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: item.progress / 100,
                minHeight: 7,
                backgroundColor: AppColors.line,
              ),
            ),
            const SizedBox(height: 9),
            Row(
              children: [
                Text(
                  '%${item.progress}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                Icon(
                  Icons.person_outline,
                  size: 15,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    item.responsible.isEmpty ? 'Atanmadı' : item.responsible,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${date.format(item.startDate)} – ${date.format(item.endDate)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
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
  Widget build(BuildContext context) => const SJCard(
    child: Padding(
      padding: EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Icon(Icons.event_note_rounded, size: 38),
          SizedBox(height: 10),
          Text('Bu şantiye için henüz faaliyet yok.'),
        ],
      ),
    ),
  );
}
