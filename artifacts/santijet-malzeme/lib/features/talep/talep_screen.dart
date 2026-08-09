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
import '../../data/providers/app_data_provider.dart';
import 'providers/requests_list_provider.dart';
import 'widgets/request_card.dart';

/// Talep listesi — Demir `OrdersScreen` kurgu + tasarım birebir.
class TalepScreen extends ConsumerStatefulWidget {
  const TalepScreen({super.key});

  @override
  ConsumerState<TalepScreen> createState() => _TalepScreenState();
}

class _TalepScreenState extends ConsumerState<TalepScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final hasActiveProject = ref.watch(activeProjectProvider) != null;
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

    final filtered = _searchQuery.isEmpty
        ? requests
        : requests
            .where(
              (r) =>
                  r.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                  r.notes.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                  r.lines.any(
                    (l) =>
                        l.materialName
                            .toLowerCase()
                            .contains(_searchQuery.toLowerCase()) ||
                        l.pozNo
                            .toLowerCase()
                            .contains(_searchQuery.toLowerCase()),
                  ),
            )
            .toList();

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
                hint: 'Talep no, malzeme, poz ara...',
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
            const SizedBox(height: 12),
          ],
          Expanded(
            child: !hasActiveProject
                ? SJEmptyState(
                    title: 'Proje Seçilmedi',
                    message:
                        'Talep görmek için bir proje seçin veya yeni proje oluşturun.',
                    icon: Icons.apartment_outlined,
                    actionLabel: 'Projeler',
                    onAction: () => context.go(AppRoutes.projeler),
                  )
                : filtered.isEmpty
                    ? SJEmptyState(
                        title: allRequests.isEmpty
                            ? 'Talep Yok'
                            : 'Arama Sonucu Yok',
                        message: allRequests.isEmpty
                            ? 'Henüz talep oluşturulmadı. Yeni talep ekleyerek başlayın.'
                            : 'Aramanızla eşleşen kayıt bulunamadı. Filtreleri değiştirin.',
                        icon: allRequests.isEmpty
                            ? Icons.receipt_long_outlined
                            : Icons.manage_search_outlined,
                        actionLabel:
                            allRequests.isEmpty ? 'Yeni Talep' : null,
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
                          return RequestCard(request: filtered[index]);
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: hasActiveProject
          ? SJFab(
              label: 'Yeni Talep',
              onPressed: () => context.go(AppRoutes.kesif),
            )
          : null,
    );
  }
}
