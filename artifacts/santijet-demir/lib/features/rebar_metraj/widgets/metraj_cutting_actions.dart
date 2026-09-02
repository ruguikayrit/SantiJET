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
import 'package:santijet_demir/domain/entities/survey.dart';
import 'package:santijet_demir/features/analysis/cutting_bending_calculator.dart';
import 'package:santijet_demir/features/analysis/providers/cutting_bending_provider.dart';
import 'package:santijet_demir/features/projects/providers/project_provider.dart';
import 'package:santijet_demir/features/rebar_metraj/providers/rebar_metraj_storage_provider.dart';
import 'package:santijet_demir/features/survey/providers/survey_provider.dart';

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

/// Analiz: imalat listesinden CAD metrajı bağlı kayıtları aktarır.
Future<void> showImalatAnalysisImportSheet(
  BuildContext context,
  WidgetRef ref,
) async {
  if (ref.read(activeProjectIdProvider) == null) {
    context.push(AppRoutes.projects);
    return;
  }

  final imalats = ref.read(surveyProjectProvider).imalats;
  final records = ref.read(savedRebarMetrajProvider);

  final options = <_ImalatImportOption>[];
  for (final imalat in imalats) {
    final linked = records
        .where((record) => record.surveyImalatId == imalat.id)
        .toList();
    options.add(_ImalatImportOption(imalat: imalat, linkedRecords: linked));
  }

  final importable = options.where((o) => o.hasPieceData).toList();

  if (!context.mounted) return;

  if (importable.isEmpty) {
    ScaffoldMessenger.of(context).showAppSnackBar(
      const SnackBar(
        content: Text(
          'İmalata bağlı CAD metrajı yok. '
          'Otomatik Metraj’dan imalata gönderin.',
        ),
      ),
    );
    context.push(AppRoutes.surveyMetraj);
    return;
  }

  final selected = await Navigator.of(context).push<List<SavedRebarMetraj>>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (context) => _ImalatImportPage(options: importable),
    ),
  );

  if (selected == null || selected.isEmpty || !context.mounted) return;

  var merge = false;
  if (selected.length > 1) {
    final mergeChoice = await _askMergeImalatRecords(
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

/// Geriye dönük alias — Analiz artık imalattan veri alır.
Future<void> showPreProductionAnalysisImportSheet(
  BuildContext context,
  WidgetRef ref,
) =>
    showImalatAnalysisImportSheet(context, ref);

Future<bool?> _askMergeImalatRecords(
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
      : '${records.length} imalat birleşik';

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

class _ImalatImportOption {
  const _ImalatImportOption({
    required this.imalat,
    required this.linkedRecords,
  });

  final SurveyImalat imalat;
  final List<SavedRebarMetraj> linkedRecords;

  bool get hasPieceData => linkedRecords.any(
        (record) => record.result.textDetails.any((d) => d.included),
      );

  double get linkedTonnage =>
      linkedRecords.fold<double>(0, (sum, r) => sum + r.result.totalTonnage);
}

class _ImalatImportPage extends StatefulWidget {
  const _ImalatImportPage({required this.options});

  final List<_ImalatImportOption> options;

  @override
  State<_ImalatImportPage> createState() => _ImalatImportPageState();
}

class _ImalatImportPageState extends State<_ImalatImportPage> {
  final _selectedIds = <String>{};

  void _confirmSelection() {
    final selected = <SavedRebarMetraj>[];
    for (final option in widget.options) {
      if (!_selectedIds.contains(option.imalat.id)) continue;
      selected.addAll(option.linkedRecords);
    }
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
                    'İmalattan Veri Al',
                    style: AppTypography.headlineMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'CAD metrajı bağlı imalatları Hesap ve Analiz’e aktarın.',
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
              itemCount: widget.options.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final option = widget.options[index];
                final selected = _selectedIds.contains(option.imalat.id);
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        if (selected) {
                          _selectedIds.remove(option.imalat.id);
                        } else {
                          _selectedIds.add(option.imalat.id);
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
                                  _selectedIds.remove(option.imalat.id);
                                } else {
                                  _selectedIds.add(option.imalat.id);
                                }
                              });
                            },
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  option.imalat.name,
                                  style: AppTypography.titleMedium,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${option.linkedRecords.length} CAD kayıt · '
                                  '${option.linkedTonnage.toStringAsFixed(2)} t',
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
            padding: EdgeInsets.fromLTRB(16, 8, 16, navBarInset),
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
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: AppRadii.sm,
                      ),
                    ),
                    child: Text(
                      'İptal',
                      style: AppTypography.titleLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
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
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: AppRadii.sm,
                      ),
                    ),
                    child: Text(
                      hasSelection
                          ? 'Onayla (${_selectedIds.length})'
                          : 'Onayla',
                      style: AppTypography.titleLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
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
