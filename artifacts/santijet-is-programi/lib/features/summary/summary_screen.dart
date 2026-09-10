import 'dart:convert';
import 'dart:typed_data';

import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../domain/program_item.dart';
import '../../state/app_state.dart';
import '../../ui/design_system.dart';

class SummaryScreen extends ConsumerWidget {
  const SummaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final site = ref.watch(activeSiteProvider);
    final items = ref
        .watch(programItemsProvider)
        .where((item) => item.santiyeId == site)
        .toList();
    final delayed = items
        .where((item) => item.effectiveStatus() == ProgramStatus.delayed)
        .toList();

    return Scaffold(
      body: Column(
        children: [
          SantijetHeader(
            title: 'ÖZET',
            subtitle: site,
            onSettings: () => context.push('/settings'),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
              children: [
                SJCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'DURUM KIRILIMI',
                        style: TextStyle(
                          fontFamily: AppTypography.displayFont,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ...ProgramStatus.values.map((status) {
                        final count = items
                            .where((item) => item.effectiveStatus() == status)
                            .length;
                        return _BreakdownRow(
                          status: status,
                          count: count,
                          total: items.length,
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SJCard(
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'ORTALAMA İLERLEME',
                              style: TextStyle(
                                fontFamily: AppTypography.displayFont,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              items.isEmpty
                                  ? '%0'
                                  : '%${items.map((e) => e.progress).reduce((a, b) => a + b) ~/ items.length}',
                              style: const TextStyle(
                                color: AppColors.electricBlue,
                                fontFamily: AppTypography.displayFont,
                                fontSize: 34,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SJButton(
                        label: 'CSV Aktar',
                        icon: Icons.download_rounded,
                        onPressed: items.isEmpty
                            ? null
                            : () => _exportCsv(context, site, items),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  'GECİKENLER (${delayed.length})',
                  style: const TextStyle(
                    fontFamily: AppTypography.displayFont,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 10),
                if (delayed.isEmpty)
                  const SJCard(child: Text('Geciken faaliyet bulunmuyor.'))
                else
                  ...delayed.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: SJCard(
                        child: Row(
                          children: [
                            const Icon(
                              Icons.warning_amber_rounded,
                              color: AppColors.danger,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    '${DateFormat('dd.MM.yyyy').format(item.endDate)} · '
                                    '%${item.progress} · ${item.responsible}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall,
                                  ),
                                ],
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

  Future<void> _exportCsv(
    BuildContext context,
    String site,
    List<ProgramItem> items,
  ) async {
    final rows = <String>[
      'Şantiye,Faaliyet,Başlangıç,Bitiş,Planlanan Gün,İlerleme,Durum,Sorumlu,Not',
      ...items.map(
        (item) => [
          site,
          item.name,
          _date(item.startDate),
          _date(item.endDate),
          item.calculatedDays,
          item.progress,
          item.effectiveStatus().label,
          item.responsible,
          item.notes ?? '',
        ].map(_csvCell).join(','),
      ),
    ];
    final bytes = Uint8List.fromList(utf8.encode('\uFEFF${rows.join('\n')}'));
    await FileSaver.instance.saveFile(
      name: 'santijet-is-programi-${_date(DateTime.now())}',
      bytes: bytes,
      fileExtension: 'csv',
      mimeType: MimeType.csv,
    );
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('CSV dosyası hazırlandı.')));
    }
  }

  String _csvCell(Object value) {
    final text = value.toString().replaceAll('"', '""');
    return '"$text"';
  }

  String _date(DateTime value) => value.toIso8601String().substring(0, 10);
}

class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow({
    required this.status,
    required this.count,
    required this.total,
  });
  final ProgramStatus status;
  final int count;
  final int total;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 13),
    child: Row(
      children: [
        SizedBox(width: 105, child: SJStatusBadge(status: status)),
        const SizedBox(width: 10),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: total == 0 ? 0 : count / total,
              minHeight: 9,
              backgroundColor: AppColors.line,
            ),
          ),
        ),
        SizedBox(
          width: 34,
          child: Text(
            '$count',
            textAlign: TextAlign.end,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
}
