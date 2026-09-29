/// Ana sayfa genel proje ilerlemesi. Kaynaklar:
/// - [plannedDurationDays], [plannedAdamGun]: iş programı planı
/// - [projectStart] → bugün: gerçekleşen süre
/// - [puantajAdamGunTotal]: puantaj kayıtları toplamı
/// - [kesifMetrajTotal], [imalatMetrajDone]: keşif metraj listesi / imalat ilerlemesi
class ProjectProgressInputs {
  const ProjectProgressInputs({
    required this.evaluatedOn,
    this.projectStart,
    this.plannedDurationDays,
    this.plannedAdamGun,
    this.puantajAdamGunTotal,
    this.kesifMetrajTotal,
    this.imalatMetrajDone,
  });

  final DateTime evaluatedOn;
  final DateTime? projectStart;
  final int? plannedDurationDays;
  final int? plannedAdamGun;
  final int? puantajAdamGunTotal;
  final double? kesifMetrajTotal;
  final double? imalatMetrajDone;
}

class ProjectProgressSnapshot {
  const ProjectProgressSnapshot({
    this.elapsedDays,
    this.plannedDurationDays,
    this.durationProgress,
    this.puantajAdamGun,
    this.plannedAdamGun,
    this.adamGunProgress,
    this.metrajProgress,
  });

  final int? elapsedDays;
  final int? plannedDurationDays;
  final double? durationProgress;
  final int? puantajAdamGun;
  final int? plannedAdamGun;
  final double? adamGunProgress;
  final double? metrajProgress;

  bool get hasData =>
      elapsedDays != null ||
      puantajAdamGun != null ||
      metrajProgress != null;

  String get sureLabel => elapsedDays == null ? '—' : '$elapsedDays gün';

  String get metrajLabel {
    if (metrajProgress == null) return '—';
    return '%${(metrajProgress! * 100).round()}';
  }

  String get adamGunLabel {
    if (puantajAdamGun == null) return '—';
    return _formatTrInt(puantajAdamGun!);
  }
}

ProjectProgressSnapshot computeProjectProgress(ProjectProgressInputs inputs) {
  final start = inputs.projectStart;
  int? elapsed;
  double? durationProgress;
  if (start != null) {
    final startDay = DateTime(start.year, start.month, start.day);
    final today = DateTime(inputs.evaluatedOn.year, inputs.evaluatedOn.month, inputs.evaluatedOn.day);
    elapsed = today.difference(startDay).inDays;
    if (elapsed < 0) elapsed = 0;
    final planned = inputs.plannedDurationDays;
    if (planned != null && planned > 0) {
      durationProgress = (elapsed / planned).clamp(0.0, 1.0);
    }
  }

  final puantaj = inputs.puantajAdamGunTotal;
  final plannedAdam = inputs.plannedAdamGun;
  double? adamProgress;
  if (puantaj != null && plannedAdam != null && plannedAdam > 0) {
    adamProgress = (puantaj / plannedAdam).clamp(0.0, 1.0);
  }

  final kesif = inputs.kesifMetrajTotal;
  final imalat = inputs.imalatMetrajDone;
  double? metrajProgress;
  if (kesif != null && kesif > 0 && imalat != null) {
    metrajProgress = (imalat / kesif).clamp(0.0, 1.0);
  }

  return ProjectProgressSnapshot(
    elapsedDays: elapsed,
    plannedDurationDays: inputs.plannedDurationDays,
    durationProgress: durationProgress,
    puantajAdamGun: puantaj,
    plannedAdamGun: plannedAdam,
    adamGunProgress: adamProgress,
    metrajProgress: metrajProgress,
  );
}

String _formatTrInt(int value) {
  final negative = value < 0;
  var digits = value.abs().toString();
  final buf = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buf.write('.');
    buf.write(digits[i]);
  }
  return negative ? '-${buf.toString()}' : buf.toString();
}

/// Demo proje ilerlemesi. Gerçek bağlantı gelince aynı [ProjectProgressInputs] doldurulacak.
abstract final class DemoProjectProgress {
  static final projectStart = DateTime(2026, 3, 1);

  /// İş programı plan bitişi 30 Ara 2026 → toplam 365 gün.
  static const plannedDurationDays = 365;

  /// İş programı planlanan toplam adam-gün.
  static const plannedAdamGun = 7200;

  /// Puantaj kayıtlarından gelen toplam kişi-gün.
  static const puantajAdamGunTotal = 4180;

  /// Keşif metraj listesi toplamı (birim karışık kalemler normalize edilmiş).
  static const kesifMetrajTotal = 100000.0;

  /// İmalat ilerlemesi metraj kayıtları toplamı.
  static const imalatMetrajDone = 62000.0;

  static ProjectProgressInputs inputs(DateTime evaluatedOn) => ProjectProgressInputs(
        evaluatedOn: evaluatedOn,
        projectStart: projectStart,
        plannedDurationDays: plannedDurationDays,
        plannedAdamGun: plannedAdamGun,
        puantajAdamGunTotal: puantajAdamGunTotal,
        kesifMetrajTotal: kesifMetrajTotal,
        imalatMetrajDone: imalatMetrajDone,
      );

  static ProjectProgressSnapshot snapshot(DateTime evaluatedOn) =>
      computeProjectProgress(inputs(evaluatedOn));
}
