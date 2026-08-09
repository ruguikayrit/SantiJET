import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design_system/sj_button.dart';
import '../../core/design_system/sj_card.dart';
import '../../core/design_system/sj_empty_state.dart';
import '../../core/routing/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/id_gen.dart';
import '../../core/widgets/santijet_header.dart';
import '../../data/providers/app_data_provider.dart';
import '../../domain/entities/entities.dart';
import '../../domain/enums/main_discipline.dart';
import '../../domain/enums/request_status.dart';
import '../projects/widgets/project_switcher.dart';

/// Keşif / Gruplar — Ana → alt → poz ağacı; talebe çoklu ekleme.
class KesifScreen extends ConsumerStatefulWidget {
  const KesifScreen({super.key});

  @override
  ConsumerState<KesifScreen> createState() => _KesifScreenState();
}

class _KesifScreenState extends ConsumerState<KesifScreen> {
  final Set<String> _selected = {};

  @override
  Widget build(BuildContext context) {
    final project = ref.watch(activeProjectProvider);
    final kesif = ref.watch(activeKesifProvider);

    if (project == null) {
      return Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              const SantijetHeader(subtitle: 'Keşif / Gruplar'),
              Expanded(
                child: SJEmptyState(
                  title: 'Proje yok',
                  message: 'Keşif yüklemek için önce proje seçin.',
                  icon: Icons.apartment_outlined,
                  actionLabel: 'Projeler',
                  onAction: () => context.go(AppRoutes.projeler),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (kesif == null || kesif.lines.isEmpty) {
      return Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              const SantijetHeader(subtitle: 'Keşif / Gruplar'),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: ProjectSwitcher(),
              ),
              Expanded(
                child: SJEmptyState(
                  title: 'Keşif yok',
                  message:
                      'Demo seed veya JSON/elle import ile keşif yükleyin. '
                      'Bulut senkron sonraki faz.',
                  icon: Icons.account_tree_outlined,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final tree = kesif.groupedTree();
    final disciplineOrder = MainDiscipline.values
        .where((d) => tree.containsKey(d))
        .toList();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SantijetHeader(subtitle: 'Keşif / Gruplar'),
            const Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.md,
                0,
                AppSpacing.md,
                AppSpacing.sm,
              ),
              child: ProjectSwitcher(),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      kesif.name,
                      style: AppTypography.titleMedium.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Text(
                    '${_selected.length} seçili',
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  0,
                  AppSpacing.md,
                  AppSpacing.xxl,
                ),
                children: [
                  for (final discipline in disciplineOrder) ...[
                    Text(
                      discipline.label,
                      style: AppTypography.titleMedium.copyWith(
                        color: AppColors.electricBlueLight,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    for (final entry in tree[discipline]!.entries) ...[
                      Padding(
                        padding: const EdgeInsets.only(
                          left: AppSpacing.sm,
                          top: AppSpacing.sm,
                          bottom: AppSpacing.xs,
                        ),
                        child: Text(
                          entry.key.isEmpty ? 'Genel' : entry.key,
                          style: AppTypography.labelLarge.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      for (final line in entry.value)
                        _KesifLineTile(
                          line: line,
                          selected: _selected.contains(line.id),
                          onToggle: () {
                            setState(() {
                              if (_selected.contains(line.id)) {
                                _selected.remove(line.id);
                              } else {
                                _selected.add(line.id);
                              }
                            });
                          },
                        ),
                    ],
                    const SizedBox(height: AppSpacing.md),
                  ],
                ],
              ),
            ),
            if (_selected.isNotEmpty)
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: SJButton(
                    label: 'Talebe ekle (${_selected.length})',
                    expanded: true,
                    onPressed: () => _addToRequest(kesif, project.id),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _addToRequest(KesifSnapshot kesif, String projectId) {
    final lines = kesif.lines.where((l) => _selected.contains(l.id)).toList();
    if (lines.isEmpty) return;

    final request = MaterialRequest(
      id: IdGen.make('req'),
      projectId: projectId,
      title: 'Talep — ${lines.length} kalem',
      kesifSnapshotId: kesif.id,
      status: RequestStatus.taslak,
      createdAt: DateTime.now(),
      lines: [
        for (final l in lines)
          MaterialRequestLine(
            id: IdGen.make('rln'),
            materialName:
                l.materialHint.isNotEmpty ? l.materialHint : l.tanim,
            birim: l.birim,
            miktar: l.miktar,
            kesifLineId: l.id,
            pozNo: l.pozNo,
          ),
      ],
    );

    ref.read(requestsProvider.notifier).add(request);
    setState(() => _selected.clear());
    context.go(AppRoutes.talep);
  }
}

class _KesifLineTile extends StatelessWidget {
  const _KesifLineTile({
    required this.line,
    required this.selected,
    required this.onToggle,
  });

  final KesifLine line;
  final bool selected;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: SJCard(
        onTap: onToggle,
        child: Row(
          children: [
            Checkbox(
              value: selected,
              onChanged: (_) => onToggle(),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${line.pozNo} · ${line.tanim}',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${line.miktar} ${line.birim}'
                    '${line.materialHint.isEmpty ? '' : ' · ${line.materialHint}'}',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
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
