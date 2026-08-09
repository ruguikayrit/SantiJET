import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design_system/sj_button.dart';
import '../../core/design_system/sj_card.dart';
import '../../core/design_system/sj_empty_state.dart';
import '../../core/design_system/sj_status_badge.dart';
import '../../core/routing/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/santijet_header.dart';
import '../../data/providers/app_data_provider.dart';
import '../../data/services/quote_pdf_service.dart';
import '../../domain/entities/entities.dart';
import '../../domain/enums/request_status.dart';
import '../projects/widgets/project_switcher.dart';

/// Talep & Teklif — liste, PDF formu, fiyat mukayesesi kabuğu.
class TalepScreen extends ConsumerStatefulWidget {
  const TalepScreen({super.key});

  @override
  ConsumerState<TalepScreen> createState() => _TalepScreenState();
}

class _TalepScreenState extends ConsumerState<TalepScreen> {
  String? _expandedRequestId;
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final project = ref.watch(activeProjectProvider);
    final requests = ref.watch(activeRequestsProvider);
    final rounds = ref.watch(activeQuoteRoundsProvider);

    if (project == null) {
      return Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              const SantijetHeader(subtitle: 'Talep & Teklif'),
              Expanded(
                child: SJEmptyState(
                  title: 'Proje yok',
                  message: 'Talep oluşturmak için proje seçin.',
                  icon: Icons.request_quote_outlined,
                  actionLabel: 'Projeler',
                  onAction: () => context.go(AppRoutes.projeler),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SantijetHeader(subtitle: 'Talep & Teklif'),
            const Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.md,
                0,
                AppSpacing.md,
                AppSpacing.sm,
              ),
              child: ProjectSwitcher(),
            ),
            Expanded(
              child: requests.isEmpty
                  ? SJEmptyState(
                      title: 'Talep yok',
                      message:
                          'Keşif sekmesinden poz seçip «Talebe ekle» ile başlayın.',
                      icon: Icons.playlist_add_outlined,
                      actionLabel: 'Keşfe Git',
                      onAction: () => context.go(AppRoutes.kesif),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md,
                        0,
                        AppSpacing.md,
                        AppSpacing.xxl,
                      ),
                      itemCount: requests.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, index) {
                        final req = requests[index];
                        final round = rounds.cast<QuoteRound?>().firstWhere(
                              (r) => r?.requestId == req.id,
                              orElse: () => null,
                            );
                        final expanded = _expandedRequestId == req.id;
                        return SJCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      req.title,
                                      style: AppTypography.titleMedium.copyWith(
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                  SJStatusBadge(
                                    label: req.status.label,
                                    color: _colorFor(req.status),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                '${req.lines.length} kalem'
                                '${round == null ? '' : ' · ${round.quotes.length} firma teklifi'}',
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Wrap(
                                spacing: AppSpacing.sm,
                                runSpacing: AppSpacing.sm,
                                children: [
                                  SJButton(
                                    label: 'Teklif PDF',
                                    variant: SJButtonVariant.secondary,
                                    loading: _busy,
                                    onPressed: () => _sharePdf(project, req),
                                  ),
                                  SJButton(
                                    label: expanded
                                        ? 'Mukayeseyi gizle'
                                        : 'Fiyat mukayesesi',
                                    variant: SJButtonVariant.ghost,
                                    onPressed: () {
                                      setState(() {
                                        _expandedRequestId =
                                            expanded ? null : req.id;
                                      });
                                    },
                                  ),
                                  SJButton(
                                    label: 'TDS',
                                    variant: SJButtonVariant.ghost,
                                    onPressed: () =>
                                        context.go(AppRoutes.kutuphane),
                                  ),
                                ],
                              ),
                              if (expanded) ...[
                                const SizedBox(height: AppSpacing.md),
                                _ComparisonPanel(round: round, request: req),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Color _colorFor(RequestStatus status) {
    return switch (status) {
      RequestStatus.taslak => AppColors.textSecondary,
      RequestStatus.teklifte => AppColors.info,
      RequestStatus.siparis => AppColors.success,
      RequestStatus.kismi => AppColors.warning,
      RequestStatus.kapandi => AppColors.textMuted,
    };
  }

  Future<void> _sharePdf(Project project, MaterialRequest request) async {
    setState(() => _busy = true);
    try {
      await QuotePdfService().shareQuoteForm(
        project: project,
        request: request,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

class _ComparisonPanel extends ConsumerWidget {
  const _ComparisonPanel({required this.round, required this.request});

  final QuoteRound? round;
  final MaterialRequest request;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (round == null || round!.quotes.isEmpty) {
      return Text(
        'Bu talep için henüz firma teklifi yok. MVP’de manuel giriş sonraki adım.',
        style: AppTypography.bodySmall.copyWith(
          color: AppColors.textSecondary,
        ),
      );
    }

    final quotes = round!.quotes;
    final lineIds = request.lines.map((l) => l.id).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Satır × firma',
          style: AppTypography.labelLarge.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStatePropertyAll(
              AppColors.surfaceElevated,
            ),
            columns: [
              const DataColumn(label: Text('Kalem')),
              for (final q in quotes) DataColumn(label: Text(q.supplierName)),
              const DataColumn(label: Text('Seç')),
            ],
            rows: [
              for (final lineId in lineIds)
                _row(ref, request, round!, lineId, quotes),
            ],
          ),
        ),
      ],
    );
  }

  DataRow _row(
    WidgetRef ref,
    MaterialRequest request,
    QuoteRound round,
    String lineId,
    List<SupplierQuote> quotes,
  ) {
    final reqLine = request.lines.firstWhere((l) => l.id == lineId);
    final prices = <String, double>{};
    for (final q in quotes) {
      for (final ql in q.lines) {
        if (ql.requestLineId == lineId) {
          prices[q.id] = ql.unitPrice;
        }
      }
    }
    final lowest = prices.values.isEmpty
        ? null
        : prices.values.reduce((a, b) => a < b ? a : b);

    String? selectedSupplierId;
    for (final q in quotes) {
      for (final ql in q.lines) {
        if (ql.requestLineId == lineId && ql.selected) {
          selectedSupplierId = q.id;
        }
      }
    }

    return DataRow(
      cells: [
        DataCell(
          SizedBox(
            width: 140,
            child: Text(
              reqLine.materialName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        for (final q in quotes)
          DataCell(
            Text(
              prices[q.id] == null ? '—' : prices[q.id]!.toStringAsFixed(2),
              style: TextStyle(
                fontWeight: prices[q.id] == lowest && lowest != null
                    ? FontWeight.w700
                    : FontWeight.w400,
                color: prices[q.id] == lowest && lowest != null
                    ? AppColors.success
                    : AppColors.textPrimary,
              ),
            ),
          ),
        DataCell(
          DropdownButton<String>(
            value: selectedSupplierId,
            hint: const Text('Kazanan'),
            underline: const SizedBox.shrink(),
            items: [
              for (final q in quotes)
                DropdownMenuItem(value: q.id, child: Text(q.supplierName)),
            ],
            onChanged: (supplierId) {
              if (supplierId == null) return;
              final updatedQuotes = [
                for (final q in quotes)
                  q.copyWith(
                    lines: [
                      for (final ql in q.lines)
                        if (ql.requestLineId == lineId)
                          ql.copyWith(selected: q.id == supplierId)
                        else
                          ql,
                    ],
                  ),
              ];
              ref.read(quotesProvider.notifier).upsert(
                    round.copyWith(quotes: updatedQuotes),
                  );
            },
          ),
        ),
      ],
    );
  }
}
