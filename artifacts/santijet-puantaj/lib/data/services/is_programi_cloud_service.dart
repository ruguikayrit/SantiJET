import 'dart:convert';

import 'package:hive/hive.dart';

import '../../domain/entities/work_schedule_plan.dart';

/// İş Programı uygulamasından bulut üzerinden iş programı çeker.
///
/// Verimde planlanan süre / iş gücü bu kaynaktan gelir.
/// Plan metraj Keşif bulutundan (`KesifCloudService`) gelir.
class IsProgramiCloudException implements Exception {
  IsProgramiCloudException(this.message);
  final String message;

  @override
  String toString() => message;
}

class IsProgramiCloudService {
  IsProgramiCloudService(this._cacheBox);

  final Box _cacheBox;
  static const _cachePrefix = 'schedule:';

  WorkScheduleSnapshot? cachedFor(String projectId) {
    final raw = _cacheBox.get('$_cachePrefix$projectId');
    if (raw is! String || raw.isEmpty) return null;
    try {
      return WorkScheduleSnapshot.fromJson(
        Map<String, dynamic>.from(jsonDecode(raw) as Map),
      );
    } catch (_) {
      return null;
    }
  }

  void _saveCache(WorkScheduleSnapshot snap) {
    _cacheBox.put('$_cachePrefix${snap.projectId}', jsonEncode(snap.toJson()));
  }

  /// Yedekten / harici kaynaktan gelen anlık görüntüyü önbelleğe yazar.
  void cacheSnapshot(WorkScheduleSnapshot snap) => _saveCache(snap);

  void clearCache(String projectId) {
    _cacheBox.delete('$_cachePrefix$projectId');
  }

  /// Buluttan senkronize eder; başarıda önbelleğe yazar.
  ///
  /// Gerçek API bağlandığında HTTP gövdesi buraya gelir;
  /// Verim UI ve önbellek sözleşmesi aynı kalır.
  Future<WorkScheduleSnapshot> sync({
    required String projectId,
    String? projectCode,
    String? projectName,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 700));

    // TODO: İş Programı bulut API — GET /work-schedule?projectId=…
    // final remote = await http.get(...); final snap = ...; _saveCache(snap);
    throw IsProgramiCloudException(
      'İş Programı bulut bağlantısı henüz yapılandırılmadı. '
      'Verim hesabı için İş Programı uygulamasında iş programının '
      'buluta kaydedilmesi ve senkronun etkin olması gerekir.',
    );
  }

  /// Geliştirme / staging: örnek bulut yanıtını önbelleğe yazar.
  /// Üretimde kaldırılacak veya feature-flag ile kilitlenecek.
  Future<WorkScheduleSnapshot> syncDemo({
    required String projectId,
    String? projectName,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    final today = DateTime.now();
    final start = today.subtract(const Duration(days: 3));
    final end = today.add(const Duration(days: 10));
    String iso(DateTime d) =>
        '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';

    final snap = WorkScheduleSnapshot(
      projectId: projectId,
      updatedAt: DateTime.now(),
      source: 'is_programi_cloud_demo',
      items: [
        WorkScheduleItem(
          id: 'ws-demo-1',
          imalatId: 'im-1',
          imalatName: 'Kolon demiri',
          startDate: iso(start),
          endDate: iso(end),
          plannedWorkerCount: 6,
          notes: projectName == null
              ? 'İş Programı demo verisi (süre / iş gücü)'
              : '$projectName — İş Programı demo',
        ),
        WorkScheduleItem(
          id: 'ws-demo-2',
          imalatId: 'im-2',
          imalatName: 'Kiriş demiri',
          startDate: iso(start),
          endDate: iso(end),
          plannedWorkerCount: 4,
        ),
      ],
    );
    _saveCache(snap);
    return snap;
  }
}
