import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/interop/program_interop.dart';
import '../../state/app_state.dart';
import '../../ui/design_system.dart';

/// Okunan dosyayı yazmadan önce gösterir. Kullanıcı birleştirme ya da
/// programı değiştirme arasında seçim yapar.
class ImportPreviewScreen extends ConsumerStatefulWidget {
  const ImportPreviewScreen({required this.result, super.key});

  final ProgramImportResult result;

  @override
  ConsumerState<ImportPreviewScreen> createState() =>
      _ImportPreviewScreenState();
}

class _ImportPreviewScreenState extends ConsumerState<ImportPreviewScreen> {
  bool _replace = false;
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final items = widget.result.items;
    final sites = <String, int>{};
    for (final item in items) {
      sites[item.santiyeId] = (sites[item.santiyeId] ?? 0) + 1;
    }
    final formatter = DateFormat('dd.MM.yyyy');

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.close, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'İçe aktarım önizlemesi',
          style: AppTypography.headlineMedium.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                SJCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.result.projectName ?? 'Okunan program',
                        style: AppTypography.onCard(
                          AppTypography.cardTitleMedium,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${items.length} faaliyet · '
                        '${sites.length} şantiye',
                        style: AppTypography.cardBodySmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        sites.entries
                            .map((entry) => '${entry.key} (${entry.value})')
                            .join(' · '),
                        style: AppTypography.cardBodySmall,
                      ),
                    ],
                  ),
                ),
                if (widget.result.warnings.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  SJCard(
                    accentColor: AppColors.warning,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              size: 18,
                              color: AppColors.warning,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'UYARILAR (${widget.result.warnings.length})',
                              style: AppTypography.onCard(
                                AppTypography.labelSmall,
                              ).copyWith(fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ...widget.result.warnings.take(12).map(
                          (warning) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              '• $warning',
                              style: AppTypography.cardBodySmall,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                SJCard(
                  child: Column(
                    children: [
                      _ModeTile(
                        title: 'Birleştir',
                        subtitle:
                            'Aynı görevler güncellenir, yeniler eklenir. '
                            'Mevcut faaliyetler silinmez.',
                        selected: !_replace,
                        onTap: () => setState(() => _replace = false),
                      ),
                      Divider(height: 20, color: AppColors.border),
                      _ModeTile(
                        title: 'Programı değiştir',
                        subtitle:
                            'Cihazdaki tüm faaliyetler silinir, yalnız bu '
                            'dosya kalır.',
                        selected: _replace,
                        onTap: () => setState(() => _replace = true),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  'OKUNAN FAALİYETLER',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 10),
                ...items.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: SJCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item.wbs == null
                                      ? item.name
                                      : '${item.wbs}  ${item.name}',
                                  style: AppTypography.onCard(
                                    AppTypography.cardTitleMedium,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              ProgramStatusBadge(status: item.status),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${formatter.format(item.startDate)} → '
                            '${formatter.format(item.endDate)} · '
                            '${item.calculatedDays} gün · %${item.progress}',
                            style: AppTypography.cardBodySmall,
                          ),
                          if (item.responsible.isNotEmpty)
                            Text(
                              item.responsible,
                              style: AppTypography.cardBodySmall,
                            ),
                          if (item.predecessors != null)
                            Text(
                              'Öncül: ${item.predecessors}',
                              style: AppTypography.cardBodySmall,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(
              16,
              12,
              16,
              12 + MediaQuery.viewPaddingOf(context).bottom,
            ),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: SJButton(
              label: _replace
                  ? 'Programı değiştir (${items.length})'
                  : 'Programa ekle (${items.length})',
              icon: Icons.save_alt_rounded,
              expanded: true,
              loading: _saving,
              onPressed: _saving ? null : _commit,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _commit() async {
    setState(() => _saving = true);
    try {
      await ref
          .read(programItemsProvider.notifier)
          .importItems(widget.result.items, replace: _replace);
      final firstSite = widget.result.items.first.santiyeId;
      if (!ref
          .read(programItemsProvider)
          .any((item) => item.santiyeId == ref.read(activeSiteProvider))) {
        await ref.read(projectsProvider.notifier).selectByName(firstSite);
      }
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${widget.result.items.length} faaliyet aktarıldı.'),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Aktarım yazılamadı: $error'),
          backgroundColor: AppColors.critical,
        ),
      );
    }
  }
}

class _ModeTile extends StatelessWidget {
  const _ModeTile({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(8),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            selected
                ? Icons.radio_button_checked
                : Icons.radio_button_unchecked,
            size: 20,
            color: selected ? AppColors.electricBlue : AppColors.cardTextMuted,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.onCard(AppTypography.cardTitleMedium),
                ),
                const SizedBox(height: 3),
                Text(subtitle, style: AppTypography.cardBodySmall),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
