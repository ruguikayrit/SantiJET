import 'daily_crew_entry.dart';
import 'program_item.dart';

/// MS Project'in varsayılan sabit birimli görevinin giriş ve izleme hesabı.
///
/// Takvim yedi günü de çalışma günü sayar. İş = Süre × Birim.
/// "% Tamamlanma güncellenince kaynak durumu da güncellenir" açıktır.
class ProjectTracking {
  const ProjectTracking({
    required this.start,
    required this.finish,
    required this.duration,
    required this.units,
    required this.milestone,
    required this.percentComplete,
    required this.actualStart,
    required this.actualFinish,
    required this.actualDuration,
    required this.remainingDuration,
    required this.work,
    required this.actualWork,
    required this.remainingWork,
  });

  final DateTime start;
  final DateTime finish;

  /// Süre (gün). Kilometre taşında 0.
  final int duration;

  /// Atama birimi (adam). Project'te Units.
  final int units;
  final bool milestone;
  final int percentComplete;
  final DateTime? actualStart;
  final DateTime? actualFinish;
  final int actualDuration;
  final int remainingDuration;

  /// İş (adam-gün). Project'te Work.
  final int work;
  final int actualWork;
  final int remainingWork;

  factory ProjectTracking.fromItem(
    ProgramItem item, {
    List<DailyCrewEntry> logs = const [],
  }) {
    final milestone = item.isMilestone;
    final duration = milestone ? 0 : item.calculatedDays;
    final units = item.plannedCrew < 1 ? 1 : item.plannedCrew;
    final work = milestone ? 0 : duration * units;
    final start = _day(item.startDate);
    final finish = milestone ? start : _day(item.endDate);

    final logged = logs
        .where((entry) => entry.itemId == item.id)
        .fold<int>(0, (sum, entry) => sum + entry.workers);
    final hasLogs = logs.any((entry) => entry.itemId == item.id);

    var percent = item.progress.clamp(0, 100);
    var actualWork = item.actualWork;
    var remainingWork = item.remainingWork;
    var actualDuration = item.actualDuration;
    var remainingDuration = item.remainingDuration;

    if (actualWork == null && remainingWork == null && hasLogs) {
      actualWork = logged;
      remainingWork = (work - logged).clamp(0, work);
      percent = work == 0
          ? (logged > 0 ? 100 : 0)
          : ((logged / work) * 100).round().clamp(0, 100);
    }

    actualWork ??= _share(work, percent);
    remainingWork ??= (work - actualWork).clamp(0, work);
    actualDuration ??= _share(duration, percent);
    remainingDuration ??= (duration - actualDuration).clamp(0, duration);

    return ProjectTracking(
      start: start,
      finish: finish,
      duration: duration,
      units: units,
      milestone: milestone,
      percentComplete: percent,
      actualStart: percent == 0 ? null : (item.actualStart ?? start),
      actualFinish: percent >= 100 ? (item.actualFinish ?? finish) : null,
      actualDuration: actualDuration,
      remainingDuration: remainingDuration,
      work: work,
      actualWork: actualWork,
      remainingWork: remainingWork,
    );
  }

  ProgramItem applyTo(ProgramItem item, {DateTime? today}) => item.copyWith(
    startDate: start,
    endDate: finish,
    plannedDays: milestone ? 0 : duration,
    plannedCrew: units,
    progress: percentComplete,
    status: status(today: today),
    isStatusManual: false,
    isMilestone: milestone,
    actualStart: actualStart,
    actualFinish: actualFinish,
    actualDuration: actualDuration,
    remainingDuration: remainingDuration,
    actualWork: actualWork,
    remainingWork: remainingWork,
  );

  ProgramStatus status({DateTime? today}) {
    final day = _day(today ?? DateTime.now());
    if (percentComplete >= 100) return ProgramStatus.completed;
    if (day.isAfter(finish)) return ProgramStatus.delayed;
    if (percentComplete > 0 || !day.isBefore(start)) {
      return ProgramStatus.inProgress;
    }
    return ProgramStatus.planned;
  }

  ProjectTracking applyStart(DateTime value) {
    final start = _day(value);
    return _copy(
      start: start,
      finish: ProgramItem.endDateFromDuration(start, duration),
      actualStart: percentComplete == 0 ? null : (actualStart ?? start),
      actualFinish: percentComplete >= 100
          ? ProgramItem.endDateFromDuration(start, duration)
          : null,
    );
  }

  ProjectTracking applyFinish(DateTime value) {
    if (milestone) return applyStart(value);
    final finish = _day(value);
    if (finish.isBefore(start)) {
      return applyDuration(1)._copy(finish: start);
    }
    final days = finish.difference(start).inDays + 1;
    return applyDuration(days);
  }

  ProjectTracking applyDuration(int days) {
    if (milestone) {
      return _copy(
        duration: 0,
        finish: start,
        work: 0,
        actualDuration: 0,
        remainingDuration: 0,
        actualWork: 0,
        remainingWork: 0,
      );
    }
    final duration = days < 1 ? 1 : days;
    final work = duration * units;
    return _withPercent(
      percent: percentComplete,
      duration: duration,
      finish: ProgramItem.endDateFromDuration(start, duration),
      work: work,
      units: units,
    );
  }

  ProjectTracking applyUnits(int value) {
    final units = value < 1 ? 1 : value;
    if (milestone) return _copy(units: units);
    return _withPercent(
      percent: percentComplete,
      duration: duration,
      finish: finish,
      work: duration * units,
      units: units,
    );
  }

  ProjectTracking applyMilestone(bool value) {
    if (value == milestone) return this;
    if (value) {
      return _copy(
        milestone: true,
        duration: 0,
        finish: start,
        work: 0,
        actualDuration: 0,
        remainingDuration: 0,
        actualWork: 0,
        remainingWork: 0,
        percentComplete: percentComplete >= 100 ? 100 : 0,
        actualStart: percentComplete >= 100 ? start : null,
        actualFinish: percentComplete >= 100 ? start : null,
      );
    }
    return _copy(milestone: false).applyDuration(duration < 1 ? 1 : duration);
  }

  /// Project: % Tamamlanma fiili / kalan süre ve işi birlikte günceller.
  ProjectTracking applyPercentComplete(int value) {
    return _withPercent(percent: value.clamp(0, 100));
  }

  ProjectTracking applyActualStart(DateTime? value) {
    if (value == null) {
      return percentComplete == 0
          ? _copy(actualStart: null)
          : _copy(actualStart: start);
    }
    return _copy(
      actualStart: _day(value),
      percentComplete: percentComplete == 0 ? 1 : percentComplete,
    );
  }

  ProjectTracking applyActualFinish(DateTime? value) {
    if (value == null) {
      return percentComplete >= 100
          ? applyPercentComplete(99)
          : _copy(actualFinish: null);
    }
    return applyPercentComplete(100)._copy(actualFinish: _day(value));
  }

  /// Fiili süre Duration'ı aşarsa Project süreyi uzatır.
  ProjectTracking applyActualDuration(int days) {
    final actual = days < 0 ? 0 : days;
    if (milestone) {
      return applyPercentComplete(actual > 0 ? 100 : 0);
    }
    if (actual > duration) {
      final next = applyDuration(actual);
      return next._withPercent(percent: 100, duration: actual, work: next.work);
    }
    final percent = duration == 0 ? 100 : ((actual / duration) * 100).round();
    return _withPercent(percent: percent);
  }

  /// Kalan süre yazılınca Süre = Fiili + Kalan olur.
  ProjectTracking applyRemainingDuration(int days) {
    final remaining = days < 0 ? 0 : days;
    if (milestone) {
      return applyPercentComplete(
        remaining == 0 && percentComplete >= 100 ? 100 : 0,
      );
    }
    final next = actualDuration + remaining;
    if (next < 1) return applyDuration(1).applyPercentComplete(0);
    return applyDuration(next).applyPercentComplete(
      ((actualDuration / next) * 100).round(),
    );
  }

  ProjectTracking applyActualWork(int value) {
    final actual = value < 0 ? 0 : value;
    if (milestone) return applyPercentComplete(actual > 0 ? 100 : 0);
    if (actual > work) {
      final duration = units < 1 ? actual : (actual / units).round().clamp(1, 3650);
      return applyDuration(duration)._withPercent(percent: 100);
    }
    final percent = work == 0 ? 0 : ((actual / work) * 100).round();
    return _withPercent(percent: percent);
  }

  ProjectTracking applyRemainingWork(int value) {
    final remaining = value < 0 ? 0 : value;
    if (milestone) return applyPercentComplete(remaining == 0 ? 100 : 0);
    final work = actualWork + remaining;
    final duration = units < 1 ? work.clamp(1, 3650) : (work / units).round();
    final safeDuration = duration < 1 && work > 0 ? 1 : duration;
    final percent = work == 0
        ? 0
        : ((actualWork / work) * 100).round().clamp(0, 100);
    return applyDuration(safeDuration < 1 ? 1 : safeDuration)._withPercent(
      percent: percent,
    );
  }

  ProjectTracking _withPercent({
    required int percent,
    int? duration,
    DateTime? finish,
    int? work,
    int? units,
  }) {
    final nextDuration = duration ?? this.duration;
    final nextWork = work ?? (milestone ? 0 : nextDuration * (units ?? this.units));
    final pct = percent.clamp(0, 100);
    final actualDuration = _share(nextDuration, pct);
    final actualWork = _share(nextWork, pct);
    final nextFinish = finish ?? this.finish;
    return _copy(
      duration: nextDuration,
      finish: nextFinish,
      units: units ?? this.units,
      work: nextWork,
      percentComplete: pct,
      actualDuration: actualDuration,
      remainingDuration: (nextDuration - actualDuration).clamp(0, nextDuration),
      actualWork: actualWork,
      remainingWork: (nextWork - actualWork).clamp(0, nextWork),
      actualStart: pct == 0 ? null : (actualStart ?? start),
      actualFinish: pct >= 100 ? (actualFinish ?? nextFinish) : null,
    );
  }

  ProjectTracking _copy({
    DateTime? start,
    DateTime? finish,
    int? duration,
    int? units,
    bool? milestone,
    int? percentComplete,
    Object? actualStart = _keep,
    Object? actualFinish = _keep,
    int? actualDuration,
    int? remainingDuration,
    int? work,
    int? actualWork,
    int? remainingWork,
  }) => ProjectTracking(
    start: start ?? this.start,
    finish: finish ?? this.finish,
    duration: duration ?? this.duration,
    units: units ?? this.units,
    milestone: milestone ?? this.milestone,
    percentComplete: percentComplete ?? this.percentComplete,
    actualStart: identical(actualStart, _keep)
        ? this.actualStart
        : actualStart as DateTime?,
    actualFinish: identical(actualFinish, _keep)
        ? this.actualFinish
        : actualFinish as DateTime?,
    actualDuration: actualDuration ?? this.actualDuration,
    remainingDuration: remainingDuration ?? this.remainingDuration,
    work: work ?? this.work,
    actualWork: actualWork ?? this.actualWork,
    remainingWork: remainingWork ?? this.remainingWork,
  );

  static const _keep = Object();

  static DateTime _day(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  static int _share(int total, int percent) {
    if (total <= 0) return 0;
    return ((total * percent.clamp(0, 100)) / 100).round().clamp(0, total);
  }

}
