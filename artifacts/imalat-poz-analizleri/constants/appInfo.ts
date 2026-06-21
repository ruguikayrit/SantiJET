import Constants from "expo-constants";

export const APP_DISPLAY_NAME = "ŞantiJET Birim Fiyat Analizleri";

export const APP_LEGAL_NAME = "ŞantiJET BFA";

export const DATA_SOURCE_LABEL = "ÇŞB YFK 2026";

export const DATA_UPDATE_LABEL = "Ocak 2026";

export const SUPPORT_EMAIL = "destek@santijet.com";

export const DISCLAIMER_LINES = [
  `${APP_LEGAL_NAME} resmi kurumlarla bağlantılı değildir.`,
  "Katalog verileri resmi kamu kaynakları referans alınarak hazırlanmıştır.",
  "Nihai doğrulama için güncel resmi yayınlar esas alınmalıdır.",
] as const;

export const LOCAL_DATA_NOTE =
  "Özel analizler, favoriler ve keşif projeleri yalnızca cihazınızda saklanır.";

export function getAppVersion(): string {
  return Constants.expoConfig?.version ?? "1.0.0";
}

export const PRIVACY_POLICY = {
  title: "Gizlilik Politikası",
  updatedAt: "21 Haziran 2026",
  sections: [
    {
      heading: "Genel",
      body: `${APP_LEGAL_NAME} hesap oluşturmayı gerektirmez. Birim fiyat analizlerini görüntüleme, düzenleme ve yönetme amacıyla kullanılır.`,
    },
    {
      heading: "Toplanan Veriler",
      body:
        "Uygulama sunucuya kişisel profil veya kullanım verisi iletmez. Özel analizler, favoriler, keşif projeleri ve tema tercihiniz yalnızca cihazınızda (AsyncStorage) saklanır.",
    },
    {
      heading: "Yedekleme",
      body:
        "Dışa ve içe aktarma işlemleri yalnızca sizin başlatmanız halinde gerçekleşir. Yedek dosyasının saklanması ve paylaşımı tamamen kullanıcı kontrolündedir.",
    },
    {
      heading: "Resmi Katalog Verisi",
      body:
        "Uygulamada yer alan birim fiyat analizleri, poz tarifleri ve referans veriler; kamu kurumları tarafından yayımlanan resmi kaynaklar esas alınarak hazırlanmıştır. Uygulama resmi kurumların yerine geçmez, yalnızca referans ve erişim kolaylığı sağlar.",
    },
    {
      heading: "Resmi Kurumlarla İlişki",
      body: `${APP_LEGAL_NAME}, Çevre, Şehircilik ve İklim Değişikliği Bakanlığı veya herhangi bir kamu kurumu tarafından geliştirilmemiş, onaylanmamış veya desteklenmemektedir.`,
    },
    {
      heading: "İletişim",
      body: `Gizlilik ile ilgili sorularınız için ${SUPPORT_EMAIL} adresine yazabilirsiniz.`,
    },
  ],
} as const;

export const TERMS_OF_USE = {
  title: "Kullanım Koşulları",
  updatedAt: "21 Haziran 2026",
  sections: [
    {
      heading: "Kapsam",
      body: `${APP_LEGAL_NAME} bilgi ve referans amacıyla sunulur. Resmi kurum yayınlarının yerine geçmez.`,
    },
    {
      heading: "Doğruluk Sorumluluğu",
      body:
        "Listelenen birim fiyatlar, poz tarifleri ve hesaplamalar yol gösterici niteliktedir. Uygulamada yer alan veriler zaman içerisinde güncelliğini yitirebilir. İhale, keşif, hakediş, sözleşme ve ödeme süreçlerinde ilgili kurumların güncel resmi yayınları esas alınmalıdır.",
    },
    {
      heading: "Kullanıcı İçeriği",
      body:
        "Oluşturduğunuz özel analizler ve keşif projeleri size aittir. Yedekleme, paylaşım ve silme sorumluluğu kullanıcıya aittir.",
    },
    {
      heading: "Sorumluluk Reddi",
      body:
        "Uygulama referans amaçlı sunulmaktadır. Veri farklılıkları, güncelleme gecikmeleri veya hesaplama sonuçlarından kaynaklanabilecek doğrudan veya dolaylı zararlardan geliştirici sorumlu tutulamaz.",
    },
    {
      heading: "Değişiklikler",
      body:
        "Bu koşullar güncellenebilir. Güncel metin, uygulama içinde yayımlandığı tarihten itibaren geçerlidir.",
    },
  ],
} as const;

export const DATA_SOURCES = {
  title: "Kaynak",
  updatedAt: "21 Haziran 2026",
  sections: [
    {
      heading: "Resmi Referans Kaynakları",
      body:
        "Bu uygulamada kullanılan katalog verileri aşağıdaki resmi yayınlar referans alınarak hazırlanmıştır.",
    },
    {
      heading: "İnşaat",
      body: "ÇŞİDB YFK İnşaat Birim Fiyat ve Analiz Yayınları",
    },
    {
      heading: "Mekanik Tesisat",
      body: "ÇŞİDB YFK Mekanik Tesisat Birim Fiyat ve Analiz Yayınları",
    },
    {
      heading: "Elektrik Tesisat",
      body: "ÇŞİDB YFK Elektrik Tesisat Birim Fiyat ve Analiz Yayınları",
    },
    {
      heading: "Güncellik",
      body: `Uygulama içi katalog son güncelleme: ${DATA_UPDATE_LABEL}.`,
    },
    {
      heading: "Önemli Uyarı",
      body:
        "Bu uygulama resmi yayınların yerine geçmez. Nihai doğrulama için ilgili kurumların güncel yayınları esas alınmalıdır.",
    },
  ],
} as const;

export type LegalDocument =
  | typeof PRIVACY_POLICY
  | typeof TERMS_OF_USE
  | typeof DATA_SOURCES;
