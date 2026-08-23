import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/santijet_header.dart';
import '../../core/widgets/tahvil_hero_card.dart';
import '../../core/design_system/sj_empty_state.dart';
import '../../data/records_store.dart';
import '../../domain/tahvil_record.dart';
import '../../domain/tahvil_record_display.dart';

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
    final display = TahvilRecordDisplay.from(record);

    return TahvilHeroCard(
      title: display.headerLabel,
      badgeLabel: display.isAllowed ? 'Optimum Uygunluk' : 'HAYIR',
      badgeColor:
          display.isAllowed ? AppColors.success : AppColors.critical,
      sourceLine: display.sourceLine,
      sourceAs: display.sourceAs,
      targetLine: display.targetLine,
      targetAs: display.targetAs,
      asUnit: display.asUnit,
      footer: Text(dateLabel, style: AppTypography.cardLabelSmall),
    );
  }
}
