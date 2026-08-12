import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/app_date.dart';
import '../../../data/providers/app_data_provider.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/enums/request_status.dart';

/// Pro RN Talep kartı — miktar kutuları, Teslim Alındı, 3 onay.
class RequestCard extends ConsumerStatefulWidget {
  const RequestCard({
    super.key,
    required this.request,
    required this.projectName,
  });

  final MaterialRequest request;
  final String projectName;

  @override
  ConsumerState<RequestCard> createState() => _RequestCardState();
}

class _RequestCardState extends ConsumerState<RequestCard> {
  late final TextEditingController _receivedCtrl;

  @override
  void initState() {
    super.initState();
    _receivedCtrl = TextEditingController(text: widget.request.receivedBy);
  }

  @override
  void didUpdateWidget(covariant RequestCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.request.receivedBy != widget.request.receivedBy &&
        widget.request.receivedBy.isNotEmpty) {
      _receivedCtrl.text = widget.request.receivedBy;
    }
  }

  @override
  void dispose() {
    _receivedCtrl.dispose();
    super.dispose();
  }

  MaterialRequest get item => widget.request;

  @override
  Widget build(BuildContext context) {
    final st = item.status;
    final statusColor = Color(st.colorValue);
    final allChecked = item.approvals.allApproved;
    final delivered = st == RequestStatus.delivered;
    final canDeliver =
        allChecked || st == RequestStatus.approved || delivered;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: AppRadii.md,
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: AppColors.cardElevation,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.projectName,
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.statusInkOnCard(
                          AppColors.electricBlueLight,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.displayName,
                      style: AppTypography.cardTitleMedium,
                    ),
                    if (item.category.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        item.category,
                        style: AppTypography.cardLabelSmall.copyWith(
                          color: AppColors.cardTextMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: AppRadii.full,
                ),
                child: Text(
                  st.label,
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.statusInkOnCard(statusColor),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoBox(
                label: 'Miktar',
                value: _fmtQty(item.quantity, item.unit),
              ),
              if (item.requestedBy.isNotEmpty)
                _InfoBox(label: 'Talep Eden', value: item.requestedBy),
              if (item.requestDate != null)
                _InfoBox(
                  label: 'Tarih',
                  value: AppDate.format(item.requestDate!),
                ),
              if (item.receivedBy.isNotEmpty)
                _InfoBox(
                  label: 'Teslim Alan',
                  value: item.receivedBy,
                  valueColor: const Color(0xFF2563EB),
                ),
            ],
          ),
          if (item.usageLocation.isNotEmpty) ...[
            const SizedBox(height: 8),
            _MetaRow(icon: Icons.place_outlined, text: item.usageLocation),
          ],
          if (item.note.isNotEmpty) ...[
            const SizedBox(height: 4),
            _MetaRow(icon: Icons.notes_outlined, text: item.note),
          ],
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.only(top: 10),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: AppColors.cardBorder),
              ),
            ),
            child: Opacity(
              opacity: canDeliver ? 1 : 0.4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    onTap: canDeliver
                        ? () {
                            if (!delivered) {
                              final name = _receivedCtrl.text.trim();
                              if (name.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Teslim alan adı girilmeden teslim alınamaz.',
                                    ),
                                  ),
                                );
                                return;
                              }
                              ref
                                  .read(requestsProvider.notifier)
                                  .markDelivered(item.id, name);
                            } else {
                              ref
                                  .read(requestsProvider.notifier)
                                  .unmarkDelivered(item.id);
                            }
                          }
                        : null,
                    child: Row(
                      children: [
                        _CheckBox(
                          checked: delivered,
                          color: const Color(0xFF2563EB),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Teslim Alındı',
                          style: AppTypography.labelLarge.copyWith(
                            color: delivered
                                ? const Color(0xFF2563EB)
                                : AppColors.cardTextPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (!canDeliver) ...[
                          const SizedBox(width: 8),
                          Text(
                            '(önce onay gerekli)',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.cardTextMuted,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (canDeliver && !delivered) ...[
                    const SizedBox(height: 8),
                    TextField(
                      controller: _receivedCtrl,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.cardTextPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Teslim Alan Ad Soyad',
                        isDense: true,
                        filled: true,
                        fillColor: AppColors.cardInsetSurface,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.only(top: 10),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: AppColors.cardBorder),
              ),
            ),
            child: Row(
              children: [
                for (final entry in const [
                  ('sef', 'Şantiye Şefi'),
                  ('mudur', 'Proje Müdürü'),
                  ('satinAlma', 'Satın Alma'),
                ])
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        final a = item.approvals;
                        ref.read(requestsProvider.notifier).setApproval(
                              item.id,
                              sef: entry.$1 == 'sef' ? !a.sef : null,
                              mudur: entry.$1 == 'mudur' ? !a.mudur : null,
                              satinAlma:
                                  entry.$1 == 'satinAlma' ? !a.satinAlma : null,
                            );
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            _CheckBox(
                              checked: switch (entry.$1) {
                                'sef' => item.approvals.sef,
                                'mudur' => item.approvals.mudur,
                                _ => item.approvals.satinAlma,
                              },
                              color: AppColors.electricBlue,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                entry.$2,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.cardTextSecondary,
                                ),
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
    );
  }

  String _fmtQty(double q, String unit) {
    final n = q == q.roundToDouble() ? q.toInt().toString() : q.toStringAsFixed(1);
    return unit.isEmpty ? n : '$n $unit';
  }
}

class _InfoBox extends StatelessWidget {
  const _InfoBox({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    // Kart içi inset — chrome surfaceElevated + cardText* hibritte çakışır.
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.cardInsetSurface,
        borderRadius: AppRadii.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.cardLabelSmall,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppTypography.cardLabelLarge.copyWith(
              color: valueColor ?? AppColors.cardTextPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.cardTextMuted),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.cardTextMuted,
            ),
          ),
        ),
      ],
    );
  }
}

class _CheckBox extends StatelessWidget {
  const _CheckBox({required this.checked, required this.color});

  final bool checked;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: checked ? color : AppColors.cardBorder,
          width: 1.5,
        ),
        color: checked ? color : Colors.transparent,
      ),
      child: checked
          ? const Icon(Icons.check, size: 12, color: Colors.white)
          : null,
    );
  }
}
