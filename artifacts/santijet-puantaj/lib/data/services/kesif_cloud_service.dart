import 'dart:convert';

import 'package:hive/hive.dart';

import '../../domain/entities/kesif_plan.dart';

/// Keşif uygulamasından plan metraj — dosya paketi veya demo önbelleği.
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

  /// Önbellekten döner; yoksa dosya içe aktarma gerekir.
  Future<KesifSnapshot> sync({
    required String projectId,
    String? projectCode,
    String? projectName,
  }) async {
    final cached = cachedFor(projectId);
    if (cached != null && cached.items.isNotEmpty) return cached;
    throw KesifCloudException(
      'Keşif planı yok. Ayarlar’dan veya imalat formundan '
      'keşif / plan JSON dosyasını içe aktarın.',
    );
  }

  /// Geliştirme / staging: örnek keşif yanıtını önbelleğe yazar.
  Future<KesifSnapshot> syncDemo({
    required String projectId,
    String? projectName,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    final label = projectName ?? 'Demo Şantiye';
    final snap = KesifSnapshot(
      projectId: projectId,
      updatedAt: DateTime.now(),
      source: 'kesif_file_demo',
      items: [
        KesifItem(
          id: 'ks-demo-1',
          imalatId: 'im-1',
          imalatName: 'Kolon Demiri',
          plannedQty: 20,
          unit: 'ton',
          notes: '$label — bodrum kolon demiri keşfi',
        ),
        KesifItem(
          id: 'ks-demo-2',
          imalatId: 'im-2',
          imalatName: 'Kiriş Demiri',
          plannedQty: 15,
          unit: 'ton',
        ),
        KesifItem(
          id: 'ks-demo-3',
          imalatId: 'im-3',
          imalatName: 'Temel Demiri',
          plannedQty: 40,
          unit: 'ton',
        ),
        KesifItem(
          id: 'ks-demo-4',
          imalatId: 'im-4',
          imalatName: 'Alçı Sıva',
          plannedQty: 850,
          unit: 'm²',
        ),
        KesifItem(
          id: 'ks-demo-5',
          imalatId: 'im-5',
          imalatName: 'Perde Betonu',
          plannedQty: 180,
          unit: 'm³',
        ),
        KesifItem(
          id: 'ks-demo-6',
          imalatId: 'im-6',
          imalatName: 'Asansör Boşluğu Kalıbı',
          plannedQty: 120,
          unit: 'm²',
        ),
        KesifItem(
          id: 'ks-demo-7',
          imalatId: 'im-7',
          imalatName: 'Aydınlatma Hattı',
          plannedQty: 420,
          unit: 'm',
        ),
        KesifItem(
          id: 'ks-demo-8',
          imalatId: 'im-8',
          imalatName: 'Havalandırma Kanalı',
          plannedQty: 260,
          unit: 'm',
        ),
        KesifItem(
          id: 'ks-demo-9',
          imalatId: 'im-9',
          imalatName: 'Döşeme Betonu',
          plannedQty: 320,
          unit: 'm³',
        ),
        KesifItem(
          id: 'ks-demo-10',
          imalatId: 'im-10',
          imalatName: 'Yangın Sprinkler Hattı',
          plannedQty: 180,
          unit: 'm',
        ),
        KesifItem(
          id: 'ks-demo-11',
          imalatId: 'im-11',
          imalatName: 'Cephe İskelesi',
          plannedQty: 450,
          unit: 'm²',
        ),
      ],
    );
    _saveCache(snap);
    return snap;
  }
}
