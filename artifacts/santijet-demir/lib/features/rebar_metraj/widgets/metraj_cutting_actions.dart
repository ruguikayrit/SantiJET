import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:santijet_demir/core/routing/app_routes.dart';
import 'package:santijet_demir/domain/entities/rebar_metraj.dart';
import 'package:santijet_demir/features/analysis/cutting_bending_calculator.dart';
import 'package:santijet_demir/features/analysis/providers/cutting_bending_provider.dart';
import 'package:santijet_demir/features/projects/providers/project_provider.dart';

Future<void> sendMetrajRecordToCuttingBending(
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

  final batch = buildCuttingBendingBatchFromResults(
    title: record.displayTitle,
    sourceMetrajRecordIds: [record.id],
    results: [record.result],
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
    SnackBar(content: Text('"${record.displayTitle}" Kesme-Bükme listesine aktarıldı.')),
  );
  context.go(AppRoutes.analysis);
}

Future<void> sendSelectedMetrajRecordsToCuttingBending(
  BuildContext context,
  WidgetRef ref,
  List<SavedRebarMetraj> records,
) async {
  if (records.isEmpty) return;

  if (ref.read(activeProjectIdProvider) == null) {
    if (context.mounted) {
      context.push(AppRoutes.projects);
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
        const SnackBar(content: Text('Seçili kayıtlarda parça verisi yok.')),
      );
    }
    return;
  }

  await ref.read(cuttingBendingBatchesProvider.notifier).addBatch(batch);

  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('"$title" Kesme-Bükme\'ye gönderildi.')),
  );
  context.go(AppRoutes.analysis);
}

Future<void> sendMetrajResultToCuttingBending(
  BuildContext context,
  WidgetRef ref,
  RebarMetrajResult result, {
  String? title,
}) async {
  if (ref.read(activeProjectIdProvider) == null) {
    if (context.mounted) {
      context.push(AppRoutes.projects);
    }
    return;
  }

  final batch = buildCuttingBendingBatch(
    title: title ?? result.fileName,
    sourceMetrajRecordIds: const [],
    textDetails: result.textDetails,
  );

  if (batch.pieceLines.isEmpty) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Parse sonucunda parça verisi yok.')),
      );
    }
    return;
  }

  await ref.read(cuttingBendingBatchesProvider.notifier).addBatch(batch);

  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Metraj Kesme-Bükme listesine aktarıldı.')),
  );
  context.go(AppRoutes.analysis);
}
