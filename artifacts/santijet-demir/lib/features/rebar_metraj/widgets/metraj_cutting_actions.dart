import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:santijet_demir/core/routing/app_routes.dart';
import 'package:santijet_demir/core/theme/app_colors.dart';
import 'package:santijet_demir/core/theme/app_radii.dart';
import 'package:santijet_demir/core/theme/app_typography.dart';
import 'package:santijet_demir/domain/entities/rebar_metraj.dart';
import 'package:santijet_demir/features/analysis/cutting_bending_calculator.dart';
import 'package:santijet_demir/features/analysis/providers/cutting_bending_provider.dart';
import 'package:santijet_demir/features/projects/providers/project_provider.dart';
import 'package:santijet_demir/features/rebar_metraj/providers/rebar_metraj_storage_provider.dart';

Future<void> approveMetrajRecordForAnalysis(
  BuildContext context,
  WidgetRef ref,
  SavedRebarMetraj record,
) async {
  if (ref.read(activeProjectIdProvider) == null) {
    if (context.mounted) {
      context.push(AppRoutes.projects);
    }
    return;
  }

  await ref.read(savedRebarMetrajProvider.notifier).approveForAnalysis(record.id);

  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('"${record.displayTitle}" Hesap ve Analiz için onaylandı.'),
    ),
  );
}

Future<void> sendMetrajRecordToAnalysis(
  BuildContext context,
  WidgetRef ref,
  SavedRebarMetraj record,
) async {
  if (!record.isApprovedForAnalysis) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Önce ön imalat kaydına analiz onayı verin.'),
        ),
      );
    }
    return;
  }

  await _importMetrajRecordsToAnalysis(
    context,
    ref,
    [record],
    navigateToAnalysis: true,
  );
}

Future<void> sendSelectedMetrajRecordsToAnalysis(
  BuildContext context,
  WidgetRef ref,
  List<SavedRebarMetraj> records,
) async {
  if (records.isEmpty) return;

  final approved =
      records.where((record) => record.isApprovedForAnalysis).toList();
  if (approved.isEmpty) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Seçili kayıtlarda analiz onayı bulunamadı.'),
        ),
      );
    }
    return;
  }

  if (approved.length < records.length && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${records.length - approved.length} kayıt onaysız olduğu için atlandı.',
        ),
      ),
    );
  }

  await _importMetrajRecordsToAnalysis(
    context,
    ref,
    approved,
    navigateToAnalysis: true,
  );
}

Future<void> showPreProductionAnalysisImportSheet(
  BuildContext context,
  WidgetRef ref,
) async {
  if (ref.read(activeProjectIdProvider) == null) {
    context.push(AppRoutes.projects);
    return;
  }

  final records = ref.read(savedRebarMetrajProvider);
  final approved =
      records.where((record) => record.isApprovedForAnalysis).toList();

  if (!context.mounted) return;

  if (approved.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Onaylı ön imalat kaydı yok. Keşif → Ön İmalat sekmesinden onay verin.',
        ),
      ),
    );
    context.push(AppRoutes.surveyMetrajRecords);
    return;
  }

  final selected = await showModalBottomSheet<List<SavedRebarMetraj>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surfaceElevated,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) => _PreProductionImportSheet(records: approved),
  );

  if (selected == null || selected.isEmpty || !context.mounted) return;
  await _importMetrajRecordsToAnalysis(context, ref, selected);
}

Future<void> _importMetrajRecordsToAnalysis(
  BuildContext context,
  WidgetRef ref,
  List<SavedRebarMetraj> records, {
  bool navigateToAnalysis = false,
}) async {
  if (records.isEmpty) return;

  if (ref.read(activeProjectIdProvider) == null) {
    if (context.mounted) {
      context.push(AppRoutes.projects);
    }
    return;
  }

  final unapproved =
      records.where((record) => !record.isApprovedForAnalysis).toList();
  if (unapproved.isNotEmpty) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Yalnızca onaylı ön imalat kayıtları aktarılabilir.'),
        ),
      );
    }
    return;
  }

  final title = records.length == 1
      ? records.first.displayTitle
      : '${records.length} ön imalat birleşik';

  final batch = buildCuttingBendingBatchFromResults(
    title: title,
    sourceMetrajRecordIds: records.map((r) => r.id).toList(),
    results: records.map((r) => r.result),
  );

  if (batch.pieceLines.isEmpty) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gönderilecek parça verisi bulunamadı (CAD etiketleri).'),
        ),
      );
    }
    return;
  }

  await ref.read(cuttingBendingBatchesProvider.notifier).addBatch(batch);

  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('"$title" Hesap ve Analiz listesine aktarıldı.')),
  );
  if (navigateToAnalysis) {
    context.go(AppRoutes.analysis);
  }
}

class _PreProductionImportSheet extends StatefulWidget {
  const _PreProductionImportSheet({required this.records});

  final List<SavedRebarMetraj> records;

  @override
  State<_PreProductionImportSheet> createState() =>
      _PreProductionImportSheetState();
}

class _PreProductionImportSheetState extends State<_PreProductionImportSheet> {
  final _selectedIds = <String>{};

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + bottomInset),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: AppRadii.full,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text('Ön İmalattan Veri Al', style: AppTypography.titleMedium),
            const SizedBox(height: 4),
            Text(
              'Analiz onayı verilmiş kayıtları Hesap ve Analiz\'e aktarın.',
              style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: widget.records.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final record = widget.records[index];
                  final selected = _selectedIds.contains(record.id);
                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          if (selected) {
                            _selectedIds.remove(record.id);
                          } else {
                            _selectedIds.add(record.id);
                          }
                        });
                      },
                      borderRadius: AppRadii.sm,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.canvas,
                          borderRadius: AppRadii.sm,
                          border: Border.all(
                            color: selected
                                ? AppColors.electricBlueLight
                                : AppColors.border,
                          ),
                        ),
                        child: Row(
                          children: [
                            Checkbox(value: selected, onChanged: (_) {
                              setState(() {
                                if (selected) {
                                  _selectedIds.remove(record.id);
                                } else {
                                  _selectedIds.add(record.id);
                                }
                              });
                            }),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    record.displayTitle,
                                    style: AppTypography.titleMedium,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${record.result.totalBarCount} çubuk · '
                                    '${record.result.totalTonnage.toStringAsFixed(2)} t',
                                    style: AppTypography.bodySmall.copyWith(
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _selectedIds.isEmpty
                  ? null
                  : () {
                      final selected = widget.records
                          .where((record) => _selectedIds.contains(record.id))
                          .toList();
                      Navigator.pop(context, selected);
                    },
              child: Text(
                _selectedIds.isEmpty
                    ? 'Kayıt seçin'
                    : '${_selectedIds.length} kaydı aktar',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
