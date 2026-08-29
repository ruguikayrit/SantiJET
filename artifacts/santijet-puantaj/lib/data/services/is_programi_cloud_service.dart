import 'dart:convert';

import 'package:hive/hive.dart';

import '../../domain/entities/work_schedule_plan.dart';

/// İş Programı uygulamasından süre / iş gücü — dosya paketi veya demo önbelleği.
///
/// Plan metraj Keşif paketinden (`KesifCloudService`) gelir.
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

  /// Önbellekten döner; yoksa dosya içe aktarma gerekir.
  Future<WorkScheduleSnapshot> sync({
    required String projectId,
    String? projectCode,
    String? projectName,
  }) async {
    final cached = cachedFor(projectId);
    if (cached != null && cached.items.isNotEmpty) return cached;
    throw IsProgramiCloudException(
      'İş programı yok. Ayarlar’dan veya imalat formundan '
      'iş programı / plan JSON dosyasını içe aktarın.',
    );
  }

  /// Geliştirme / staging: örnek programı önbelleğe yazar.
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
      source: 'program_file_demo',
      items: [
        WorkScheduleItem(
          id: 'ws-demo-1',
          imalatId: 'im-1',
          imalatName: 'Kolon demiri',
          startDate: iso(start),
          endDate: iso(end),
          plannedWorkerCount: 6,
          notes: projectName == null
              ? 'İş Programı demo — kolon demiri'
              : '$projectName — Kolon demiri programı',
        ),
        WorkScheduleItem(
          id: 'ws-demo-2',
          imalatId: 'im-2',
          imalatName: 'Kiriş demiri',
          startDate: iso(start),
          endDate: iso(end),
          plannedWorkerCount: 4,
        ),
        WorkScheduleItem(
          id: 'ws-demo-3',
          imalatId: 'im-3',
          imalatName: 'Temel demiri',
          startDate: iso(start),
          endDate: iso(end),
          plannedWorkerCount: 8,
        ),
        WorkScheduleItem(
          id: 'ws-demo-4',
          imalatId: 'im-4',
          imalatName: 'Alçı sıva',
          startDate: iso(start),
          endDate: iso(end),
          plannedWorkerCount: 5,
        ),
      ],
    );
    _saveCache(snap);
    return snap;
  }
}
