import 'package:flutter/material.dart';
import 'package:santijet_demir/core/widgets/app_toast.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:santijet_demir/core/animations/app_animations.dart';
import 'package:santijet_demir/core/routing/app_routes.dart';
import 'package:santijet_demir/core/theme/app_colors.dart';
import 'package:santijet_demir/core/theme/app_radii.dart';
import 'package:santijet_demir/core/theme/app_typography.dart';
import 'package:santijet_demir/core/widgets/app_bottom_nav_bar.dart';
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
  ScaffoldMessenger.of(context).showAppSnackBar(
    SnackBar(
      content: Text(
        '"${record.displayTitle}" analiz için onaylandı. '
        'Hesap ve Analiz sayfasından yükleyebilirsiniz.',
      ),
    ),
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
    ScaffoldMessenger.of(context).showAppSnackBar(
      const SnackBar(
        content: Text(
          'Onaylı ön imalat kaydı yok. Keşif → Ön İmalat sekmesinden onay verin.',
        ),
      ),
    );
    context.push(AppRoutes.surveyMetrajRecords);
    return;
  }

  final selected = await Navigator.of(context).push<List<SavedRebarMetraj>>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (context) => _PreProductionImportPage(records: approved),
    ),
  );

  if (selected == null || selected.isEmpty || !context.mounted) return;

  var merge = false;
  if (selected.length > 1) {
    final mergeChoice = await _askMergePreProductionRecords(
      context,
      selected.length,
    );
    if (!context.mounted || mergeChoice == null) return;
    merge = mergeChoice;
  }

  await _importMetrajRecordsToAnalysis(
    context,
    ref,
    selected,
    merge: merge,
  );
}

Future<bool?> _askMergePreProductionRecords(
  BuildContext context,
  int recordCount,
) {
  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Kayıtları birleştirilsin mi?'),
      content: Text(
        'Seçilen $recordCount kayıt tek analiz dosyasında birleştirilebilir '
        'veya her biri ayrı dosya olarak eklenebilir.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Ayrı ekle'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Birleştir'),
        ),
      ],
    ),
  );
}

Future<void> _importMetrajRecordsToAnalysis(
  BuildContext context,
  WidgetRef ref,
  List<SavedRebarMetraj> records, {
  bool merge = true,
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
      ScaffoldMessenger.of(context).showAppSnackBar(
        const SnackBar(
          content: Text('Yalnızca onaylı ön imalat kayıtları aktarılabilir.'),
        ),
      );
    }
    return;
  }

  if (records.length > 1 && !merge) {
    var addedCount = 0;
    var skippedCount = 0;
    for (final record in records) {
      final batch = buildCuttingBendingBatchFromResults(
        title: record.displayTitle,
        sourceMetrajRecordIds: [record.id],
        results: [record.result],
      );
      if (batch.pieceLines.isEmpty) {
        skippedCount++;
        continue;
      }
      await ref.read(cuttingBendingBatchesProvider.notifier).addBatch(batch);
      addedCount++;
    }

    if (!context.mounted) return;
    if (addedCount == 0) {
      ScaffoldMessenger.of(context).showAppSnackBar(
        const SnackBar(
          content: Text('Gönderilecek parça verisi bulunamadı (CAD etiketleri).'),
        ),
      );
      return;
    }

    final message = skippedCount > 0
        ? '$addedCount kayıt ayrı ayrı aktarıldı ($skippedCount kayıt atlandı).'
        : '$addedCount kayıt ayrı ayrı Hesap ve Analiz listesine aktarıldı.';
    ScaffoldMessenger.of(context).showAppSnackBar(
      SnackBar(content: Text(message)),
    );
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
      ScaffoldMessenger.of(context).showAppSnackBar(
        const SnackBar(
          content: Text('Gönderilecek parça verisi bulunamadı (CAD etiketleri).'),
        ),
      );
    }
    return;
  }

  await ref.read(cuttingBendingBatchesProvider.notifier).addBatch(batch);

  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showAppSnackBar(
    SnackBar(content: Text('"$title" Hesap ve Analiz listesine aktarıldı.')),
  );
}

class _PreProductionImportPage extends StatefulWidget {
  const _PreProductionImportPage({required this.records});

  final List<SavedRebarMetraj> records;

  @override
  State<_PreProductionImportPage> createState() =>
      _PreProductionImportPageState();
}

class _PreProductionImportPageState extends State<_PreProductionImportPage> {
  final _selectedIds = <String>{};

  void _confirmSelection() {
    final selected = widget.records
        .where((record) => _selectedIds.contains(record.id))
        .toList();
    Navigator.pop(context, selected);
  }

  @override
  Widget build(BuildContext context) {
    final hasSelection = _selectedIds.isNotEmpty;
    final navBarInset = AppBottomNavBar.totalHeightOf(context);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ön İmalattan Veri Al',
                    style: AppTypography.headlineMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Analiz onayı verilmiş kayıtları Hesap ve Analiz\'e aktarın.',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
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
                          color: AppColors.surfaceElevated,
                          borderRadius: AppRadii.sm,
                          border: Border.all(
                            color: selected
                                ? AppColors.electricBlueLight
                                : AppColors.border,
                          ),
                        ),
                        child: Row(
                          children: [
                            AppAnimatedCheckbox(
                              value: selected,
                              onChanged: (_) {
                                setState(() {
                                  if (selected) {
                                    _selectedIds.remove(record.id);
                                  } else {
                                    _selectedIds.add(record.id);
                                  }
                                });
                              },
                            ),
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
          Container(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + navBarInset),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.diameter28,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor:
                          AppColors.diameter28.withValues(alpha: 0.38),
                      disabledForegroundColor:
                          Colors.white.withValues(alpha: 0.72),
                      elevation: 0,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: AppRadii.sm,
                      ),
                    ),
                    child: Text(
                      'İptal',
                      style: AppTypography.labelMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: hasSelection ? _confirmSelection : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.electricBlue,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor:
                          AppColors.electricBlue.withValues(alpha: 0.38),
                      disabledForegroundColor:
                          Colors.white.withValues(alpha: 0.72),
                      elevation: 0,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: AppRadii.sm,
                      ),
                    ),
                    child: Text(
                      hasSelection
                          ? 'Onayla (${_selectedIds.length})'
                          : 'Onayla',
                      style: AppTypography.labelMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
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
}
