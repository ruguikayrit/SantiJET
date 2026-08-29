import '../../domain/entities/kesif_plan.dart';
import '../../domain/entities/santijet_plan_pack.dart';
import '../../domain/entities/work_schedule_plan.dart';

String _norm(String s) => s
    .trim()
    .toLowerCase()
    .replaceAll(RegExp(r'\s+'), ' ');

/// Önce [imalatId], sonra ad (tam / kısmi) ile eşleştirir.
KesifItem? matchKesifItem(
  List<KesifItem> items, {
  String imalatId = '',
  String name = '',
}) {
  final id = imalatId.trim();
  if (id.isNotEmpty) {
    for (final item in items) {
      if (item.imalatId.trim() == id || item.id.trim() == id) return item;
    }
  }
  final target = _norm(name);
  if (target.isEmpty) return null;
  for (final item in items) {
    if (_norm(item.imalatName) == target) return item;
  }
  for (final item in items) {
    final n = _norm(item.imalatName);
    if (n.contains(target) || target.contains(n)) return item;
  }
  return null;
}

WorkScheduleItem? matchScheduleItem(
  List<WorkScheduleItem> items, {
  String imalatId = '',
  String name = '',
}) {
  final id = imalatId.trim();
  if (id.isNotEmpty) {
    for (final item in items) {
      if (item.imalatId.trim() == id || item.id.trim() == id) return item;
    }
  }
  final target = _norm(name);
  if (target.isEmpty) return null;
  for (final item in items) {
    if (_norm(item.imalatName) == target) return item;
  }
  for (final item in items) {
    final n = _norm(item.imalatName);
    if (n.contains(target) || target.contains(n)) return item;
  }
  return null;
}

/// Form alanlarına plan değerlerini uygular.
class PlanFormApplyResult {
  const PlanFormApplyResult({
    this.plannedQty,
    this.unit,
    this.plannedDays,
    this.plannedLabor,
    this.parts = const [],
  });

  final double? plannedQty;
  final String? unit;
  final int? plannedDays;
  final double? plannedLabor;
  final List<String> parts;

  bool get anyApplied =>
      plannedQty != null ||
      plannedDays != null ||
      plannedLabor != null ||
      (unit != null && unit!.isNotEmpty);
}

PlanFormApplyResult applyPlanToForm({
  required PlanFieldApplyMode mode,
  required double currentQty,
  required String currentUnit,
  required int currentDays,
  required double currentLabor,
  KesifItem? kesif,
  WorkScheduleItem? schedule,
}) {
  final parts = <String>[];
  double? qty;
  String? unit;
  int? days;
  double? labor;

  bool takeQty(double v) {
    if (v <= 0) return false;
    if (mode == PlanFieldApplyMode.overwrite || currentQty <= 0) {
      qty = v;
      return true;
    }
    return false;
  }

  bool takeDays(int v) {
    if (v <= 0) return false;
    if (mode == PlanFieldApplyMode.overwrite || currentDays <= 0) {
      days = v;
      return true;
    }
    return false;
  }

  bool takeLabor(double v) {
    if (v <= 0) return false;
    if (mode == PlanFieldApplyMode.overwrite || currentLabor <= 0) {
      labor = v;
      return true;
    }
    return false;
  }

  if (schedule != null) {
    final d = schedule.durationDays;
    if (d != null && takeDays(d)) {
      parts.add(
        'süre $d gün'
        '${schedule.startDate != null && schedule.endDate != null ? ' (${schedule.startDate} → ${schedule.endDate})' : ''}',
      );
    } else if (d == null || d <= 0) {
      parts.add('İş Programı’nda süre yok');
    } else {
      parts.add('süre korundu (manuel)');
    }
    final workers = schedule.plannedWorkerCount;
    if (workers != null && takeLabor(workers.toDouble())) {
      parts.add('iş gücü $workers kişi');
    } else if (workers == null || workers <= 0) {
      parts.add('İş Programı’nda iş gücü yok');
    } else {
      parts.add('iş gücü korundu (manuel)');
    }
  } else {
    parts.add('İş Programı eşleşmedi');
  }

  if (kesif != null && kesif.plannedQty > 0) {
    if (takeQty(kesif.plannedQty)) {
      final q = qty!;
      final u = kesif.unit.trim();
      if (u.isNotEmpty &&
          (mode == PlanFieldApplyMode.overwrite ||
              currentUnit.trim().isEmpty)) {
        unit = u;
      }
      parts.add(
        'metraj ${q == q.roundToDouble() ? q.toStringAsFixed(0) : q.toStringAsFixed(1)}'
        '${unit != null && unit.isNotEmpty ? ' $unit' : (kesif.unit.trim().isNotEmpty ? ' ${kesif.unit.trim()}' : '')}',
      );
    } else {
      parts.add('metraj korundu (manuel)');
    }
  } else {
    parts.add('Keşif metraj eşleşmedi');
  }

  return PlanFormApplyResult(
    plannedQty: qty,
    unit: unit,
    plannedDays: days,
    plannedLabor: labor,
    parts: parts,
  );
}
