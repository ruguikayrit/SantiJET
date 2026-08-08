import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../core/theme/theme_mode_provider.dart';
import '../../core/utils/id_gen.dart';
import '../../core/utils/puantaj_date.dart';
import '../../domain/catalogs/turkey_cities.dart';
import '../../domain/daily_report/attendance_snapshot_builder.dart';
import '../../domain/daily_report/daily_report_copy.dart';
import '../../domain/entities/daily_report.dart';
import '../services/weather_service.dart';
import 'app_data_provider.dart';

final dailyReportsBoxProvider = Provider<Box>(
  (ref) =>
      throw UnimplementedError('dailyReportsBoxProvider override edilmeli'),
);

List<Map<String, dynamic>> _readList(Box box, String key) {
  final raw = box.get(key);
  if (raw is String && raw.isNotEmpty) {
    final decoded = jsonDecode(raw);
    if (decoded is List) {
      return decoded
          .cast<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
  }
  if (raw is List) {
    return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }
  return [];
}

void _writeList(Box box, String key, List<Map<String, dynamic>> items) {
  box.put(key, jsonEncode(items));
}

class DailyReportsNotifier extends StateNotifier<List<DailyReport>> {
  DailyReportsNotifier(this._box) : super(_load(_box));

  final Box _box;
  static const _key = 'items';

  static List<DailyReport> _load(Box box) =>
      _readList(box, _key).map(DailyReport.fromJson).toList();

  void _persist() =>
      _writeList(_box, _key, state.map((e) => e.toJson()).toList());

  DailyReport? find({required String projectId, required String date}) {
    for (final r in state) {
      if (r.projectId == projectId && r.date == date) return r;
    }
    return null;
  }

  /// Yoksa boş taslak oluşturup saklar.
  DailyReport ensureDraft({
    required String projectId,
    required String date,
  }) {
    final existing = find(projectId: projectId, date: date);
    if (existing != null) return existing;
    final now = DateTime.now();
    final draft = DailyReport(
      id: IdGen.make('drp'),
      projectId: projectId,
      date: date,
      createdAt: now,
      updatedAt: now,
    );
    state = [...state, draft];
    _persist();
    return draft;
  }

  DailyReport upsert(DailyReport report) {
    final now = DateTime.now();
    final withMeta = report.copyWith(updatedAt: now);
    final idx = state.indexWhere(
      (r) =>
          r.id == withMeta.id ||
          (r.projectId == withMeta.projectId && r.date == withMeta.date),
    );
    if (idx >= 0) {
      state = [
        for (var i = 0; i < state.length; i++)
          if (i == idx) withMeta else state[i],
      ];
    } else {
      state = [
        ...state,
        withMeta.copyWith(createdAt: withMeta.createdAt ?? now),
      ];
    }
    _persist();
    return withMeta;
  }

  void deleteForProject(String projectId) {
    state = state.where((r) => r.projectId != projectId).toList();
    _persist();
  }

  void replaceAll(List<DailyReport> items) {
    state = List<DailyReport>.from(items);
    _persist();
  }

  /// Önceki günden seçili alanları kopyalar. Dönüş: kopya özeti.
  DailyReportCopyResult copyFromPreviousDay({
    required String projectId,
    required String date,
    required String previousDate,
    required Set<DailyReportCopyField> fields,
  }) {
    if (fields.isEmpty) return const DailyReportCopyResult();
    final source = find(projectId: projectId, date: previousDate);
    if (source == null) return const DailyReportCopyResult();

    final target = ensureDraft(projectId: projectId, date: date);
    final outcome = applyDailyReportCopyFromPrevious(
      target: target,
      source: source,
      fields: fields,
    );
    if (outcome.result.isEmpty) return outcome.result;
    upsert(outcome.report);
    return outcome.result;
  }
}

final dailyReportsProvider =
    StateNotifierProvider<DailyReportsNotifier, List<DailyReport>>((ref) {
  return DailyReportsNotifier(ref.watch(dailyReportsBoxProvider));
});

/// Seçili gün (TR format) — günlük rapor ekranı.
final dailyReportSelectedDateProvider =
    StateProvider<String>((ref) => PuantajDate.today());

/// Aktif proje + seçili gün için kayıtlı rapor (yoksa null; ekran taslak açar).
final activeDailyReportProvider = Provider<DailyReport?>((ref) {
  final project = ref.watch(activeProjectProvider);
  if (project == null) return null;
  final date = ref.watch(dailyReportSelectedDateProvider);
  final reports = ref.watch(dailyReportsProvider);
  for (final r in reports) {
    if (r.projectId == project.id && r.date == date) return r;
  }
  return null;
});

/// Canlı puantaj snapshot (ekranda gösterim; kayıtta persist edilir).
final liveAttendanceSnapshotProvider =
    Provider<DailyReportAttendanceSnapshot?>((ref) {
  final project = ref.watch(activeProjectProvider);
  if (project == null) return null;
  final date = ref.watch(dailyReportSelectedDateProvider);
  final attendance = ref.watch(attendanceProvider);
  final people = ref.watch(activePersonnelProvider);
  return AttendanceSnapshotBuilder.build(
    projectId: project.id,
    date: date,
    attendance: attendance,
    activePeople: people,
  );
});

/// Bugünün raporu — ana sayfa kartı.
final todayDailyReportProvider = Provider<DailyReport?>((ref) {
  final project = ref.watch(activeProjectProvider);
  if (project == null) return null;
  final today = PuantajDate.today();
  final reports = ref.watch(dailyReportsProvider);
  for (final r in reports) {
    if (r.projectId == project.id && r.date == today) return r;
  }
  return null;
});

final weatherServiceProvider = Provider<WeatherService>((ref) => weatherService);

/// Son seçilen hava ili (plaka kodu) — Hive settings.
class WeatherCityNotifier extends StateNotifier<String?> {
  WeatherCityNotifier(this._box) : super(_read(_box));

  final Box _box;
  static const _key = 'weatherCityId';

  static String? _read(Box box) {
    final raw = box.get(_key);
    if (raw is String && raw.trim().isNotEmpty) return raw.trim();
    return null;
  }

  void set(String? cityId) {
    final id = cityId?.trim();
    if (id == null || id.isEmpty) {
      state = null;
      _box.delete(_key);
      return;
    }
    state = id;
    _box.put(_key, id);
  }

  TurkeyCity? get city => turkeyCityById(state);
}

final weatherCityIdProvider =
    StateNotifierProvider<WeatherCityNotifier, String?>((ref) {
  return WeatherCityNotifier(ref.watch(settingsBoxProvider));
});

final selectedWeatherCityProvider = Provider<TurkeyCity?>((ref) {
  return turkeyCityById(ref.watch(weatherCityIdProvider));
});

/// Hava çek + rapora yaz (otomatik; `isManual: false`).
///
/// Geçmiş günde kilitli otomatik kayıt varken yenileme yapılmaz.
Future<DailyReportWeather?> refreshReportWeather(
  WidgetRef ref, {
  required DailyReport report,
  required TurkeyCity city,
  bool force = false,
}) async {
  final previous = report.weather;
  if (!force &&
      previous != null &&
      previous.isAutoLocked(report.date)) {
    return previous;
  }

  ref.read(weatherCityIdProvider.notifier).set(city.id);
  final weather =
      await ref.read(weatherServiceProvider).fetchForCity(city);
  if (!weather.synced && previous != null && previous.synced) {
    final merged = previous.copyWith(
      synced: false,
      offlineNote: weather.offlineNote.isNotEmpty
          ? weather.offlineNote
          : 'Hava durumu senkron edilemedi. Son bilinen değerler gösteriliyor.',
      fetchedAt: previous.fetchedAt,
      locationLabel: city.name,
      isManual: previous.isManual,
    );
    ref.read(dailyReportsProvider.notifier).upsert(
          report.copyWith(weather: merged),
        );
    return merged;
  }
  final saved = weather.copyWith(isManual: false);
  ref.read(dailyReportsProvider.notifier).upsert(
        report.copyWith(weather: saved),
      );
  return saved;
}

/// Canlı snapshot’ı rapora yazar (`report.date` baz alınır).
DailyReport syncAttendanceIntoReport(WidgetRef ref, DailyReport report) {
  final snap = AttendanceSnapshotBuilder.build(
    projectId: report.projectId,
    date: report.date,
    attendance: ref.read(attendanceProvider),
    activePeople: ref.read(activePersonnelProvider),
  );
  return ref.read(dailyReportsProvider.notifier).upsert(
        report.copyWith(attendanceSnapshot: snap),
      );
}

/// Manuel hava girişi / müdahale — kilidi açar.
DailyReport saveManualWeather(
  WidgetRef ref, {
  required DailyReport report,
  required DailyReportWeather weather,
}) {
  final saved = weather.copyWith(
    isManual: true,
    synced: true,
    offlineNote: '',
    fetchedAt: weather.fetchedAt ?? DateTime.now(),
  );
  return ref.read(dailyReportsProvider.notifier).upsert(
        report.copyWith(weather: saved),
      );
}
