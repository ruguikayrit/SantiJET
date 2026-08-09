import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design_system/sj_empty_state.dart';
import '../../core/design_system/sj_filter_chips.dart';
import '../../core/design_system/sj_search_bar.dart';
import '../../core/routing/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/santijet_header.dart';
import '../../data/providers/app_data_provider.dart';
import '../../domain/entities/entities.dart';
import '../../domain/enums/request_status.dart';
import 'widgets/request_card.dart';

/// Talep & Teklif — Demir `OrdersScreen` kurgusu:
/// header → arama → durum filtreleri → kart listesi → FAB.
class TalepScreen extends ConsumerStatefulWidget {
  const TalepScreen({super.key});

  @override
  ConsumerState<TalepScreen> createState() => _TalepScreenState();
}

class _TalepScreenState extends ConsumerState<TalepScreen> {
  static const _filterLabels = [
    'Tümü',
    'Taslak',
    'Teklifte',
    'Sipariş',
    'Kısmi',
    'Kapandı',
  ];

  /// FAB + alt nav için kaydırma boşluğu (Demir AppFab.scrollClearanceOf).
  static const _fabScrollClearance = 104.0;

  String _searchQuery = '';
  int _filterIndex = 0;

  List<MaterialRequest> _applyFilters(List<MaterialRequest> all) {
    var list = all;
    if (_filterIndex > 0) {
      final status = RequestStatus.values[_filterIndex - 1];
      list = list.where((r) => r.status == status).toList();
    }
    final q = _searchQuery.trim().toLowerCase();
    if (q.isEmpty) return list;
    return list.where((r) {
      if (r.title.toLowerCase().contains(q)) return true;
      if (r.notes.toLowerCase().contains(q)) return true;
      for (final line in r.lines) {
        if (line.materialName.toLowerCase().contains(q)) return true;
        if (line.pozNo.toLowerCase().contains(q)) return true;
      }
      return false;
    }).toList();
  }

  QuoteRound? _roundFor(
    List<QuoteRound> rounds,
    MaterialRequest request,
  ) {
    for (final r in rounds) {
      if (r.requestId == request.id) return r;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final project = ref.watch(activeProjectProvider);
    final hasActiveProject = project != null;
    final allRequests = ref.watch(activeRequestsProvider);
    final rounds = ref.watch(activeQuoteRoundsProvider);
    final filtered = _applyFilters(allRequests);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SantijetHeader(subtitle: 'Talep'),
            if (hasActiveProject) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: SJSearchBar(
                  hint: 'Talep, poz, malzeme ara...',
                  onChanged: (v) => setState(() => _searchQuery = v),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: SJFilterChips(
                  labels: _filterLabels,
                  selectedIndex: _filterIndex,
                  onSelected: (i) => setState(() => _filterIndex = i),
                ),
              ),
              const SizedBox(height: 12),
            ],
            Expanded(
              child: !hasActiveProject
                  ? SJEmptyState(
                      title: 'Proje yok',
                      message: 'Talep oluşturmak için proje seçin.',
                      icon: Icons.request_quote_outlined,
                      actionLabel: 'Projeler',
                      onAction: () => context.go(AppRoutes.projeler),
                    )
                  : filtered.isEmpty
                      ? SJEmptyState(
                          title: allRequests.isEmpty
                              ? 'Talep yok'
                              : 'Sonuç yok',
                          message: allRequests.isEmpty
                              ? 'Keşif sekmesinden poz seçip talebe ekleyin.'
                              : 'Arama veya filtreyi değiştirin.',
                          icon: allRequests.isEmpty
                              ? Icons.playlist_add_outlined
                              : Icons.search_off,
                          actionLabel: allRequests.isEmpty ? 'Keşfe Git' : null,
                          onAction: allRequests.isEmpty
                              ? () => context.go(AppRoutes.kesif)
                              : null,
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.md,
                            0,
                            AppSpacing.md,
                            _fabScrollClearance,
                          ),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final req = filtered[index];
                            return RequestCard(
                              request: req,
                              project: project,
                              round: _roundFor(rounds, req),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: hasActiveProject
          ? FloatingActionButton.extended(
              onPressed: () => context.go(AppRoutes.kesif),
              icon: const Icon(Icons.add),
              label: const Text('Yeni Talep'),
            )
          : null,
    );
  }
}
