import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design_system/sj_empty_state.dart';
import '../../core/design_system/sj_fab.dart';
import '../../core/design_system/sj_filter_chips.dart';
import '../../core/design_system/sj_search_bar.dart';
import '../../core/routing/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/santijet_header.dart';
import '../../core/widgets/swipe_to_delete_row.dart';
import '../../data/providers/app_data_provider.dart';
import 'providers/requests_list_provider.dart';
import 'widgets/request_card.dart';

/// Talep — ŞantiJET Pro RN `malzeme` → Tab Talep kurgusu.
class TalepScreen extends ConsumerStatefulWidget {
  const TalepScreen({super.key});

  @override
  ConsumerState<TalepScreen> createState() => _TalepScreenState();
}

class _TalepScreenState extends ConsumerState<TalepScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final project = ref.watch(activeProjectProvider);
    final hasActiveProject = project != null;
    final requests = ref.watch(filteredRequestsProvider);
    final filterLabels = ref.watch(requestFilterLabelsProvider);
    final rawFilterIndex = ref.watch(requestFilterProvider);
    final filterIndex = rawFilterIndex.clamp(0, filterLabels.length - 1);
    if (rawFilterIndex != filterIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref.read(requestFilterProvider.notifier).state = filterIndex;
      });
    }
    final allRequests = ref.watch(activeRequestsProvider);
    final projects = ref.watch(projectsProvider);

    String projectName(String id) {
      for (final p in projects) {
        if (p.id == id) return p.name;
      }
      return 'Proje';
    }

    final q = _searchQuery.trim().toLowerCase();
    final filtered = q.isEmpty
        ? requests
        : requests
            .where(
              (r) =>
                  r.displayName.toLowerCase().contains(q) ||
                  r.requestedBy.toLowerCase().contains(q) ||
                  r.category.toLowerCase().contains(q) ||
                  r.pozCode.toLowerCase().contains(q) ||
                  r.note.toLowerCase().contains(q),
            )
            .toList();

    // Malzeme adı chip’leri (RN matFilters).
    final nameCounts = <String, int>{};
    for (final r in allRequests) {
      final n = r.displayName;
      if (n.isEmpty) continue;
      nameCounts[n] = (nameCounts[n] ?? 0) + 1;
    }
    final nameKeys = nameCounts.keys.toList()..sort();

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SantijetHeader(subtitle: 'Talep'),
          if (hasActiveProject) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: SJSearchBar(
                hint: 'Malzeme, talep eden, poz ara...',
                onChanged: (v) => setState(() => _searchQuery = v),
              ),
            ),
            const SizedBox(height: 12),
            SJFilterChips(
              labels: filterLabels,
              selectedIndex: filterIndex,
              onSelected: (i) =>
                  ref.read(requestFilterProvider.notifier).state = i,
            ),
            if (nameKeys.isNotEmpty) ...[
              const SizedBox(height: 8),
              SizedBox(
                height: 36,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  children: [
                    _NameChip(
                      label: 'Tümü (${allRequests.length})',
                      selected: _searchQuery.isEmpty,
                      onTap: () => setState(() => _searchQuery = ''),
                    ),
                    for (final name in nameKeys)
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: _NameChip(
                          label: '$name (${nameCounts[name]})',
                          selected: _searchQuery == name,
                          onTap: () => setState(() => _searchQuery = name),
                        ),
                      ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
          ],
          Expanded(
            child: !hasActiveProject
                ? SJEmptyState(
                    title: 'Önce proje ekleyin',
                    message: 'Malzeme talebi için aktif bir proje gerekir.',
                    icon: Icons.apartment_outlined,
                    actionLabel: 'Projelere Git',
                    onAction: () => context.go(AppRoutes.projeler),
                  )
                : filtered.isEmpty
                    ? SJEmptyState(
                        title: allRequests.isEmpty
                            ? 'Malzeme talebi yok'
                            : 'Arama sonucu yok',
                        message: allRequests.isEmpty
                            ? 'Yeni malzeme taleplerini buraya ekleyin'
                            : 'Filtreleri değiştirin',
                        icon: Icons.assignment_outlined,
                        actionLabel:
                            allRequests.isEmpty ? 'Talep Ekle' : null,
                        onAction: allRequests.isEmpty
                            ? () => context.go(AppRoutes.kesif)
                            : null,
                      )
                    : ListView.builder(
                        padding: EdgeInsets.fromLTRB(
                          16,
                          0,
                          16,
                          SJFab.scrollClearanceOf(context),
                        ),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final r = filtered[index];
                          return SwipeToDeleteRow(
                            itemKey: ValueKey('req-${r.id}'),
                            title: 'Talebi sil',
                            message:
                                '"${r.displayName}" talebi silinsin mi?',
                            onDelete: () async {
                              ref
                                  .read(requestsProvider.notifier)
                                  .delete(r.id);
                            },
                            child: RequestCard(
                              request: r,
                              projectName: projectName(r.projectId),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: hasActiveProject
          ? SJFab(
              label: 'Talep Ekle',
              onPressed: () => context.go(AppRoutes.kesif),
            )
          : null,
    );
  }
}

class _NameChip extends StatelessWidget {
  const _NameChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      selected: selected,
      onSelected: (_) => onTap(),
      showCheckmark: false,
      selectedColor: AppColors.electricBlue.withValues(alpha: 0.22),
      backgroundColor: AppColors.surfaceElevated,
      side: BorderSide(
        color: selected ? AppColors.electricBlue : AppColors.border,
      ),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: selected ? AppColors.textPrimary : AppColors.textSecondary,
      ),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: const EdgeInsets.symmetric(horizontal: 10),
    );
  }
}
