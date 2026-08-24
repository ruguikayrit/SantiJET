import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/period_site_report_builder.dart';
import '../services/puantaj_report_builder.dart';
import 'app_data_provider.dart';
import 'production_provider.dart';
import 'uninsured_teams_provider.dart';
import 'verim_provider.dart';

/// Haftalık / aylık birleşik rapor anahtarı.
typedef PeriodSiteReportKey = ({
  String projectId,
  String anchorDate,
  PuantajReportPeriod period,
});

final periodSiteReportProvider =
    Provider.family<PeriodSiteReportData?, PeriodSiteReportKey>((ref, key) {
  final project = ref.watch(activeProjectProvider);
  if (project == null || project.id != key.projectId) return null;

  final people = ref.watch(personnelProvider);
  final attendance = ref.watch(attendanceProvider);
  final uninsured = ref.watch(uninsuredTeamsProvider);
  final productions = ref.watch(productionProvider);
  final verim = ref.watch(verimProvider);

  return PeriodSiteReportBuilder.build(
    projectId: project.id,
    projectName: project.name,
    people: people,
    attendance: attendance,
    uninsuredTeams: uninsured,
    productions: productions,
    verim: verim,
    period: key.period,
    anchorDate: key.anchorDate,
  );
});
