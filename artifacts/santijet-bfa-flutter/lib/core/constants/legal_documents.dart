import 'app_info.dart';

/// Hukuki belge bölümü.
class LegalSection {
  const LegalSection({required this.heading, required this.body});

  final String heading;
  final String body;
}

/// Hukuki belge modeli.
class LegalDocument {
  const LegalDocument({
    required this.id,
    required this.title,
    required this.updatedAt,
    required this.sections,
  });

  final String id;
  final String title;
  final String updatedAt;
  final List<LegalSection> sections;
}

const privacyPolicy = LegalDocument(
  id: 'privacy',
  title: 'Gizlilik Politikası',
  updatedAt: '21 Haziran 2026',
  sections: [
    LegalSection(
      heading: 'Genel',
      body:
          '${AppInfo.legalName} hesap oluşturmayı gerektirmez. Birim fiyat analizlerini görüntüleme, düzenleme ve yönetme amacıyla kullanılır.',
    ),
    LegalSection(
      heading: 'Toplanan Veriler',
      body:
          'Uygulama sunucuya kişisel profil veya kullanım verisi iletmez. Özel analizler, favoriler, keşif projeleri ve tema tercihiniz yalnızca cihazınızda saklanır.',
    ),
    LegalSection(
      heading: 'Yedekleme',
      body:
          'Dışa ve içe aktarma işlemleri yalnızca sizin başlatmanız halinde gerçekleşir. Yedek dosyasının saklanması ve paylaşımı tamamen kullanıcı kontrolündedir.',
    ),
    LegalSection(
      heading: 'Resmi Katalog Verisi',
      body:
          'Uygulamada yer alan birim fiyat analizleri, poz tarifleri ve referans veriler; kamu kurumları tarafından yayımlanan resmi kaynaklar esas alınarak hazırlanmıştır. Uygulama resmi kurumların yerine geçmez, yalnızca referans ve erişim kolaylığı sağlar.',
    ),
    LegalSection(
      heading: 'Resmi Kurumlarla İlişki',
      body:
          '${AppInfo.legalName}, Çevre, Şehircilik ve İklim Değişikliği Bakanlığı veya herhangi bir kamu kurumu tarafından geliştirilmemiş, onaylanmamış veya desteklenmemektedir.',
    ),
    LegalSection(
      heading: 'İletişim',
      body:
          'Gizlilik ile ilgili sorularınız için ${AppInfo.supportEmail} adresine yazabilirsiniz.',
    ),
  ],
);

const termsOfUse = LegalDocument(
  id: 'terms',
  title: 'Kullanım Koşulları',
  updatedAt: '21 Haziran 2026',
  sections: [
    LegalSection(
      heading: 'Kapsam',
      body:
          '${AppInfo.legalName} bilgi ve referans amacıyla sunulur. Resmi kurum yayınlarının yerine geçmez.',
    ),
    LegalSection(
      heading: 'Doğruluk Sorumluluğu',
      body:
          'Listelenen birim fiyatlar, poz tarifleri ve hesaplamalar yol gösterici niteliktedir. İhale, keşif, hakediş, sözleşme ve ödeme süreçlerinde ilgili kurumların güncel resmi yayınları esas alınmalıdır.',
    ),
    LegalSection(
      heading: 'Kullanıcı İçeriği',
      body:
          'Oluşturduğunuz özel analizler ve keşif projeleri size aittir. Yedekleme, paylaşım ve silme sorumluluğu kullanıcıya aittir.',
    ),
    LegalSection(
      heading: 'Sorumluluk Reddi',
      body:
          'Uygulama referans amaçlı sunulmaktadır. Veri farklılıkları, güncelleme gecikmeleri veya hesaplama sonuçlarından kaynaklanabilecek doğrudan veya dolaylı zararlardan geliştirici sorumlu tutulamaz.',
    ),
    LegalSection(
      heading: 'Değişiklikler',
      body:
          'Bu koşullar güncellenebilir. Güncel metin, uygulama içinde yayımlandığı tarihten itibaren geçerlidir.',
    ),
  ],
);

LegalDocument? legalDocumentById(String id) => switch (id) {
      'privacy' => privacyPolicy,
      'terms' => termsOfUse,
      _ => null,
    };
