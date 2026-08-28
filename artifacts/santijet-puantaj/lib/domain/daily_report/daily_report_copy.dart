import '../../core/utils/id_gen.dart';
import '../entities/daily_report.dart';

/// Günlük raporda dünden kopyalanabilir alanlar.
enum DailyReportCopyField {
  machines,
  vehicles,
  workTexts,
  nextDayPlan,
  orderedMaterials,
}

/// Tek seferde tekrarlayan saha kayıtları (makine/vasıta/iş/plan/sipariş).
const Set<DailyReportCopyField> kDailyReportCopyAllRepeatable = {
  DailyReportCopyField.machines,
  DailyReportCopyField.vehicles,
  DailyReportCopyField.workTexts,
  DailyReportCopyField.nextDayPlan,
  DailyReportCopyField.orderedMaterials,
};

class DailyReportCopyResult {
  const DailyReportCopyResult({
    this.machines = 0,
    this.vehicles = 0,
    this.workTexts = false,
    this.nextDayPlan = false,
    this.orderedMaterials = 0,
  });

  final int machines;
  final int vehicles;
  final bool workTexts;
  final bool nextDayPlan;
  final int orderedMaterials;

  bool get isEmpty =>
      machines == 0 &&
      vehicles == 0 &&
      !workTexts &&
      !nextDayPlan &&
      orderedMaterials == 0;

  /// Kısa snackbar metni.
  String get message {
    if (isEmpty) return 'Önceki gün için kopyalanacak kayıt bulunamadı.';
    final parts = <String>[];
    if (machines > 0) parts.add('$machines makine');
    if (vehicles > 0) parts.add('$vehicles vasıta');
    if (orderedMaterials > 0) parts.add('$orderedMaterials sipariş');
    if (workTexts) parts.add('yapılan işler');
    if (nextDayPlan) parts.add('planlı işler');
    return '${parts.join(', ')} kopyalandı.';
  }
}

class DailyReportCopyOutcome {
  const DailyReportCopyOutcome({
    required this.report,
    required this.result,
  });

  final DailyReport report;
  final DailyReportCopyResult result;
}

/// Kaynak günden hedef güne seçili alanları kopyalar (yeni id’ler).
/// Hava, foto ve puantaj özeti kopyalanmaz.
DailyReportCopyOutcome applyDailyReportCopyFromPrevious({
  required DailyReport target,
  required DailyReport source,
  required Set<DailyReportCopyField> fields,
  String Function(String prefix) makeId = IdGen.make,
}) {
  var machines = 0;
  var vehicles = 0;
  var workTexts = false;
  var nextDayPlan = false;
  var orderedMaterials = 0;

  var next = target;

  if (fields.contains(DailyReportCopyField.machines) &&
      source.machines.isNotEmpty) {
    final cloned = [
      for (final m in source.machines) m.copyWith(id: makeId('mch')),
    ];
    machines = cloned.length;
    next = next.copyWith(machines: cloned);
  }

  if (fields.contains(DailyReportCopyField.vehicles) &&
      source.vehicles.isNotEmpty) {
    final cloned = [
      for (final m in source.vehicles) m.copyWith(id: makeId('veh')),
    ];
    vehicles = cloned.length;
    next = next.copyWith(vehicles: cloned);
  }

  if (fields.contains(DailyReportCopyField.workTexts)) {
    final has = source.workConstruction.trim().isNotEmpty ||
        source.workElectrical.trim().isNotEmpty ||
        source.workMechanical.trim().isNotEmpty;
    if (has) {
      workTexts = true;
      next = next.copyWith(
        workConstruction: source.workConstruction,
        workElectrical: source.workElectrical,
        workMechanical: source.workMechanical,
      );
    }
  }

  if (fields.contains(DailyReportCopyField.nextDayPlan)) {
    final has = source.planConstruction.trim().isNotEmpty ||
        source.planElectrical.trim().isNotEmpty ||
        source.planMechanical.trim().isNotEmpty;
    if (has) {
      nextDayPlan = true;
      next = next.copyWith(
        planConstruction: source.planConstruction,
        planElectrical: source.planElectrical,
        planMechanical: source.planMechanical,
      );
    }
  }

  if (fields.contains(DailyReportCopyField.orderedMaterials) &&
      source.orderedMaterials.isNotEmpty) {
    final cloned = [
      for (final m in source.orderedMaterials)
        m.copyWith(
          id: makeId('mat'),
          // İrsaliye foto günlere özel; siparişte bağ kopar.
          irsaliyePhotoId: '',
        ),
    ];
    orderedMaterials = cloned.length;
    next = next.copyWith(orderedMaterials: cloned);
  }

  return DailyReportCopyOutcome(
    report: next,
    result: DailyReportCopyResult(
      machines: machines,
      vehicles: vehicles,
      workTexts: workTexts,
      nextDayPlan: nextDayPlan,
      orderedMaterials: orderedMaterials,
    ),
  );
}
