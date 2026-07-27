import 'package:santijet_demir/data/remote/supabase_service.dart';
import 'package:santijet_demir/domain/entities/puantaj_progress_cloud.dart';

class PuantajProgressCloudException implements Exception {
  PuantajProgressCloudException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Puantaj uygulamasındaki imalat ilerlemesini buluttan çeker.
///
/// Anahtar: kullanıcı e-postası + proje kodu.
/// Beklenen Supabase tablo/view: `puantaj_imalat_progress`
/// kolonlar: account_email, project_code, project_name, imalat_id,
/// imalat_name, progress_percent, updated_at
class PuantajProgressCloudService {
  static const tableName = 'puantaj_imalat_progress';

  /// Buluttan e-posta + proje koduna göre ilerleme çeker.
  Future<PuantajProgressSnapshot> sync({
    required String accountEmail,
    required String projectCode,
    String? projectName,
  }) async {
    final email = accountEmail.trim().toLowerCase();
    final code = projectCode.trim();
    if (email.isEmpty) {
      throw PuantajProgressCloudException(
        'Bulut aktarımı için oturum e-postası gerekli.',
      );
    }
    if (code.isEmpty) {
      throw PuantajProgressCloudException(
        'Aktarım için aktif projenin iş kodu gerekli.',
      );
    }

    if (!SupabaseService.isReady) {
      throw PuantajProgressCloudException(
        'Bulut bağlantısı hazır değil. Giriş yaptığınızdan ve '
        'ağ bağlantınızın açık olduğundan emin olun.',
      );
    }

    try {
      final rows = await SupabaseService.client
          .from(tableName)
          .select(
            'account_email, project_code, project_name, imalat_id, '
            'imalat_name, progress_percent, updated_at',
          )
          .eq('account_email', email)
          .eq('project_code', code);

      final list = (rows as List<dynamic>)
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      if (list.isEmpty) {
        throw PuantajProgressCloudException(
          'Bu e-posta ($email) ve iş kodu ($code) için Puantaj bulutunda '
          'imalat ilerleme verisi bulunamadı. Puantaj uygulamasında aynı '
          'hesap ve proje ile ilerlemenin buluta kaydedildiğinden emin olun.',
        );
      }

      DateTime latest = DateTime.fromMillisecondsSinceEpoch(0);
      final items = <PuantajImalatProgressItem>[];
      var remoteProjectName = projectName ?? '';

      for (final row in list) {
        final item = PuantajImalatProgressItem.fromJson(row);
        if (item.imalatName.isEmpty) continue;
        items.add(item);
        final name = row['project_name'] as String?;
        if (name != null && name.trim().isNotEmpty) {
          remoteProjectName = name.trim();
        }
        final updated = DateTime.tryParse(row['updated_at'] as String? ?? '');
        if (updated != null && updated.isAfter(latest)) {
          latest = updated;
        }
      }

      if (items.isEmpty) {
        throw PuantajProgressCloudException(
          'Buluttan kayıt geldi ancak eşleşecek imalat adı yok.',
        );
      }

      return PuantajProgressSnapshot(
        accountEmail: email,
        projectCode: code,
        projectName: remoteProjectName,
        updatedAt: latest.millisecondsSinceEpoch == 0 ? DateTime.now() : latest,
        items: items,
        source: 'supabase:$tableName',
      );
    } on PuantajProgressCloudException {
      rethrow;
    } catch (error) {
      final text = error.toString().toLowerCase();
      if (text.contains('could not find the table') ||
          text.contains('42p01') ||
          (text.contains('relation') && text.contains('does not exist'))) {
        throw PuantajProgressCloudException(
          'Puantaj–Demir bulut aktarım tablosu henüz yapılandırılmadı. '
          'Aynı e-posta hesabıyla her iki uygulamada da oturum açıldığında '
          'imalat ilerlemesi bulut üzerinden paylaşılacak.',
        );
      }
      throw PuantajProgressCloudException(
        'Buluttan ilerleme alınamadı. Lütfen tekrar deneyin.',
      );
    }
  }
}
