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
    final start = today.subtract(const Duration(days: 21));
    final end = today.add(const Duration(days: 28));
    String iso(DateTime d) =>
        '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';

    WorkScheduleItem item({
      required String id,
      required String name,
      required int plannedDays,
      required int workers,
      String? notes,
    }) {
      final itemStart = start;
      final itemEnd = start.add(Duration(days: plannedDays - 1));
      return WorkScheduleItem(
        id: id,
        imalatId: id,
        imalatName: name,
        startDate: iso(itemStart),
        endDate: iso(itemEnd.isAfter(end) ? end : itemEnd),
        plannedDays: plannedDays,
        plannedWorkerCount: workers,
        notes: notes,
      );
    }

    final label = projectName ?? 'Demo Şantiye';
    final snap = WorkScheduleSnapshot(
      projectId: projectId,
      updatedAt: DateTime.now(),
      source: 'program_file_demo',
      items: [
        item(
          id: 'ws-demo-1',
          name: 'Kolon Demiri',
          plannedDays: 7,
          workers: 6,
          notes: '$label — kolon demiri programı',
        ),
        item(
          id: 'ws-demo-2',
          name: 'Kiriş Demiri',
          plannedDays: 10,
          workers: 4,
        ),
        item(
          id: 'ws-demo-3',
          name: 'Temel Demiri',
          plannedDays: 14,
          workers: 8,
        ),
        item(
          id: 'ws-demo-4',
          name: 'Alçı Sıva',
          plannedDays: 12,
          workers: 5,
        ),
        item(
          id: 'ws-demo-5',
          name: 'Perde Betonu',
          plannedDays: 5,
          workers: 10,
        ),
        item(
          id: 'ws-demo-6',
          name: 'Asansör Boşluğu Kalıbı',
          plannedDays: 4,
          workers: 6,
        ),
        item(
          id: 'ws-demo-7',
          name: 'Aydınlatma Hattı',
          plannedDays: 8,
          workers: 3,
        ),
        item(
          id: 'ws-demo-8',
          name: 'Havalandırma Kanalı',
          plannedDays: 9,
          workers: 4,
        ),
        item(
          id: 'ws-demo-9',
          name: 'Döşeme Betonu',
          plannedDays: 6,
          workers: 12,
        ),
        item(
          id: 'ws-demo-10',
          name: 'Yangın Sprinkler Hattı',
          plannedDays: 7,
          workers: 3,
        ),
        item(
          id: 'ws-demo-11',
          name: 'Cephe İskelesi',
          plannedDays: 10,
          workers: 8,
        ),
      ],
    );
    _saveCache(snap);
    return snap;
  }
}
