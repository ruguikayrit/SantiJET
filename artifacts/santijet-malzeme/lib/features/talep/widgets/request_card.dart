import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design_system/sj_status_badge.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/app_date.dart';
import '../../../data/providers/app_data_provider.dart';
import '../../../data/services/quote_pdf_service.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/enums/request_status.dart';

Color requestStatusColor(RequestStatus status) => switch (status) {
      RequestStatus.taslak => AppColors.textSecondary,
      RequestStatus.teklifte => AppColors.info,
      RequestStatus.siparis => AppColors.success,
      RequestStatus.kismi => AppColors.warning,
      RequestStatus.kapandi => AppColors.textMuted,
    };

/// Demir `OrderCard` düzeni — sol durum şeridi + özet + aksiyonlar.
class RequestCard extends ConsumerStatefulWidget {
  const RequestCard({
    super.key,
    required this.request,
    required this.project,
    this.round,
  });

  final MaterialRequest request;
  final Project project;
  final QuoteRound? round;

  @override
  ConsumerState<RequestCard> createState() => _RequestCardState();
}

class _RequestCardState extends ConsumerState<RequestCard> {
  bool _expanded = false;
  bool _busy = false;

  MaterialRequest get request => widget.request;
  QuoteRound? get round => widget.round;

  Future<void> _sharePdf() async {
    setState(() => _busy = true);
    try {
      await QuotePdfService().shareQuoteForm(
        project: widget.project,
        request: request,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = requestStatusColor(request.status);
    final dateStr = request.createdAt != null
        ? AppDate.format(request.createdAt!)
        : '—';
    final linePreview = request.lines
        .take(2)
        .map((l) => l.materialName)
        .where((s) => s.isNotEmpty)
        .join(' · ');
    final supplierPreview = round == null || round!.quotes.isEmpty
        ? 'Teklif yok'
        : round!.quotes.map((q) => q.supplierName).join(' · ');
    final quoteCount = round?.quotes.length ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: AppRadii.md,
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: AppColors.cardElevation,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          request.title,
                          style: AppTypography.titleMedium.copyWith(
                            color: AppColors.cardTextPrimary,
                          ),
                        ),
                      ),
                      SJStatusBadge(
                        label: request.status.label,
                        color: statusColor,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    dateStr,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.cardTextMuted,
                    ),
                  ),
                  if (linePreview.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      linePreview +
                          (request.lines.length > 2
                              ? ' · +${request.lines.length - 2}'
                              : ''),
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.cardTextPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${request.lines.length} kalem',
                        style: AppTypography.kpiValue.copyWith(
                          fontSize: 22,
                          color: AppColors.cardTextPrimary,
                        ),
                      ),
                      Flexible(
                        child: Text(
                          quoteCount == 0
                              ? supplierPreview
                              : '$quoteCount firma',
                          textAlign: TextAlign.end,
                          style: AppTypography.labelMedium.copyWith(
                            color: AppColors.electricBlueLight,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (quoteCount > 0) ...[
                    const SizedBox(height: 4),
                    Text(
                      supplierPreview,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.cardTextMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.end,
                      children: [
                        FilledButton(
                          onPressed: _busy ? null : _sharePdf,
                          child: Text(_busy ? '…' : 'Teklif PDF'),
                        ),
                        OutlinedButton(
                          onPressed: () {
                            setState(() => _expanded = !_expanded);
                          },
                          child: Text(
                            _expanded ? 'Mukayeseyi gizle' : 'Mukayese',
                          ),
                        ),
                        TextButton(
                          onPressed: () => context.go(AppRoutes.kutuphane),
                          child: const Text('TDS'),
                        ),
                      ],
                    ),
                  ),
                  if (_expanded) ...[
                    const SizedBox(height: 14),
                    _ComparisonPanel(round: round, request: request),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
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
        'Bu talep için henüz firma teklifi yok.',
        style: AppTypography.bodySmall.copyWith(
          color: AppColors.cardTextMuted,
        ),
      );
    }

    final quotes = round!.quotes;
    final lineIds = request.lines.map((l) => l.id).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Fiyat mukayesesi',
          style: AppTypography.labelLarge.copyWith(
            color: AppColors.cardTextPrimary,
          ),
        ),
        const SizedBox(height: 8),
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
              style: TextStyle(color: AppColors.cardTextPrimary),
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
                    : AppColors.cardTextPrimary,
              ),
            ),
          ),
        DataCell(
          DropdownButton<String>(
            value: selectedSupplierId,
            hint: const Text('Kazanan'),
            underline: const SizedBox.shrink(),
            dropdownColor: AppColors.cardSurface,
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
