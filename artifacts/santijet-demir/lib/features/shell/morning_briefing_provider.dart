import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:santijet_demir/features/field_count/providers/field_count_provider.dart';
import 'package:santijet_demir/features/prediction/providers/prediction_provider.dart';
import 'package:santijet_demir/features/projects/providers/project_provider.dart';
import 'package:santijet_demir/features/settings/providers/profile_provider.dart';
import 'package:santijet_demir/features/shell/morning_briefing.dart';
import 'package:santijet_demir/features/shell/project_progress_provider.dart';

final morningBriefingProvider = Provider<MorningBriefing>((ref) {
  final now = DateTime.now();
  final hasProject = ref.watch(activeProjectProvider) != null;
  final name = ref.watch(profileDisplayNameProvider);
  final progress = ref.watch(projectProgressSummaryProvider);
  final counts = ref.watch(fieldCountsProvider);
  final latestCount = counts.isEmpty ? null : counts.first;
  final kalan = (progress.totalPlanned - progress.totalExpected)
      .clamp(0.0, double.infinity)
      .toDouble();

  return const MorningBriefingBuilder().build(
    now: now,
    displayName: name,
    hasActiveProject: hasProject,
    ops: DailyOpsBriefingInput(
      kesifTonnage: progress.totalPlanned,
      gerceklesenImalat: progress.totalExpected,
      kalanImalat: kalan,
      overallProgressPercent: progress.overallProgressPercent,
      latestCount: latestCount,
      reconciliation: ref.watch(reconciliationRowsProvider),
      snapshot: ref.watch(predictionSnapshotProvider),
    ),
  );
});
