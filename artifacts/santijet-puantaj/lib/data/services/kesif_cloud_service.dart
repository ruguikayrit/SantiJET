import 'dart:convert';

import 'package:hive/hive.dart';

import '../../domain/entities/kesif_plan.dart';

/// Keşif uygulamasından bulut üzerinden plan metraj çeker.
///
/// Verimde planlanan miktar yalnızca bu kaynaktan gelir.
class KesifCloudException implements Exception {
  KesifCloudException(this.message);
  final String message;

  @override
  String toString() => message;
}

class KesifCloudService {
  KesifCloudService(this._cacheBox);

  final Box _cacheBox;
  static const _cachePrefix = 'kesif:';

  KesifSnapshot? cachedFor(String projectId) {
    final raw = _cacheBox.get('$_cachePrefix$projectId');
    if (raw is! String || raw.isEmpty) return null;
    try {
      return KesifSnapshot.fromJson(
        Map<String, dynamic>.from(jsonDecode(raw) as Map),
      );
    } catch (_) {
      return null;
    }
  }

  void _saveCache(KesifSnapshot snap) {
    _cacheBox.put('$_cachePrefix${snap.projectId}', jsonEncode(snap.toJson()));
  }

  void cacheSnapshot(KesifSnapshot snap) => _saveCache(snap);

  void clearCache(String projectId) {
    _cacheBox.delete('$_cachePrefix$projectId');
  }

  /// Buluttan senkronize eder; başarıda önbelleğe yazar.
  Future<KesifSnapshot> sync({
    required String projectId,
    String? projectCode,
    String? projectName,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 700));

    // TODO: Keşif bulut API — GET /kesif?projectId=…
    throw KesifCloudException(
      'Keşif bulut bağlantısı henüz yapılandırılmadı. '
      'Plan metraj için Keşif uygulamasında keşfin buluta '
      'kaydedilmesi ve senkronun etkin olması gerekir.',
    );
  }

  /// Geliştirme / staging: örnek keşif yanıtını önbelleğe yazar.
  Future<KesifSnapshot> syncDemo({
    required String projectId,
    String? projectName,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    final snap = KesifSnapshot(
      projectId: projectId,
      updatedAt: DateTime.now(),
      source: 'kesif_cloud_demo',
      items: [
        KesifItem(
          id: 'ks-demo-1',
          imalatId: 'im-1',
          imalatName: 'Kolon demiri',
          plannedQty: 12,
          unit: 'ton',
          notes: projectName == null
              ? 'Keşif demo verisi'
              : '$projectName — Keşif demo',
        ),
        KesifItem(
          id: 'ks-demo-2',
          imalatId: 'im-2',
          imalatName: 'Kiriş demiri',
          plannedQty: 8,
          unit: 'ton',
        ),
      ],
    );
    _saveCache(snap);
    return snap;
  }
}
