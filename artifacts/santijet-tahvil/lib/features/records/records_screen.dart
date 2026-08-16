import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/design_system/sj_card.dart';
import '../../core/design_system/sj_empty_state.dart';
import '../../core/design_system/sj_status_badge.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/santijet_header.dart';
import '../../data/records_store.dart';
import '../../domain/tahvil_record.dart';

/// Yerel kayıtlar — hesap, cihazda kalır.
class RecordsScreen extends ConsumerWidget {
  const RecordsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final records = ref.watch(tahvilRecordsProvider);
    final dateFmt = DateFormat('dd.MM.yyyy  HH:mm');

    return ColoredBox(
      color: AppColors.canvas,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const SantijetHeader(subtitle: 'Kayıtlar'),
            Expanded(
              child: records.isEmpty
                  ? SJEmptyState(
                      icon: Icons.bookmark_border,
                      title: 'Kayıt yok',
                      message:
                          'Hesap’taki önerilen tahvili Kaydet ile buraya alın. '
                          'Hesaplar bu cihazda durur; hesap gerekmez.',
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                      itemCount: records.length,
                      itemBuilder: (context, index) {
                        final record = records[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Dismissible(
                            key: ValueKey(record.id),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 16),
                              color: AppColors.critical,
                              child: const Icon(
                                Icons.delete_outline,
                                color: Colors.white,
                              ),
                            ),
                            onDismissed: (_) => ref
                                .read(tahvilRecordsProvider.notifier)
                                .remove(record.id),
                            child: _RecordCard(
                              record: record,
                              dateLabel: dateFmt.format(record.createdAt),
                            ),
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
}

class _RecordCard extends StatelessWidget {
  const _RecordCard({
    required this.record,
    required this.dateLabel,
  });

  final TahvilRecord record;
  final String dateLabel;

  @override
  Widget build(BuildContext context) {
    return SJCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(record.basis, style: AppTypography.cardLabelMedium),
              const Spacer(),
              SJStatusBadge(
                label: record.isAllowed ? 'UYGUN' : 'HAYIR',
                color:
                    record.isAllowed ? AppColors.success : AppColors.critical,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(record.summary, style: AppTypography.cardTitleMedium),
          const SizedBox(height: 4),
          Text(record.detail, style: AppTypography.cardBodySmall),
          const SizedBox(height: AppSpacing.sm),
          Text(dateLabel, style: AppTypography.cardLabelSmall),
        ],
      ),
    );
  }
}
