import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:santijet_demir/features/field_count/providers/field_count_provider.dart';
import 'package:santijet_demir/features/incoming_rebar/providers/incoming_rebar_provider.dart';
import 'package:santijet_demir/features/prediction/providers/prediction_provider.dart';
import 'package:santijet_demir/features/prediction/providers/work_schedule_provider.dart';
import 'package:santijet_demir/features/projects/providers/project_provider.dart';
import 'package:santijet_demir/features/settings/providers/profile_provider.dart';
import 'package:santijet_demir/features/shell/morning_briefing.dart';

final morningBriefingProvider = Provider<MorningBriefing>((ref) {
  final now = DateTime.now();
  final hasProject = ref.watch(activeProjectProvider) != null;
  final name = ref.watch(profileDisplayNameProvider);
  ref.watch(workScheduleProvider);
  final today = ref.read(workScheduleProvider.notifier).dayFor(now);

  return const MorningBriefingBuilder().build(
    now: now,
    displayName: name,
    todaySchedule: today,
    snapshot: ref.watch(predictionSnapshotProvider),
    inTransitOrders: ref.watch(inTransitOrdersProvider),
    reconciliation: ref.watch(reconciliationRowsProvider),
    hasActiveProject: hasProject,
  );
});
