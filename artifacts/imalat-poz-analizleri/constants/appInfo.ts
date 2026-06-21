import Constants from "expo-constants";

export const APP_DISPLAY_NAME = "ŞantiJET Birim Fiyat Analizleri";

export const DATA_SOURCE_LABEL = "ÇŞB YFK 2026";

export const DATA_UPDATE_LABEL = "Ocak 2026";

export const SUPPORT_EMAIL = "destek@santijet.com";

export const DISCLAIMER_LINES = [
  "Bu uygulama resmi kurumlarla bağlantılı değildir.",
  "Veriler kamu kurumlarının yayımladığı resmi kaynaklardan derlenmiştir.",
  "Nihai doğrulama için ilgili kurumların güncel yayınları esas alınmalıdır.",
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
      body: `${APP_DISPLAY_NAME} hesap oluşturmayı gerektirmez. Uygulama, birim fiyat analizlerini görüntüleme ve yönetme aracıdır.`,
    },
    {
      heading: "Toplanan Veriler",
      body:
        "Uygulama sunucuya kişisel profil veya kullanım verisi göndermez. Oluşturduğunuz özel analizler, favoriler, keşif projeleri ve tema tercihiniz cihazınızda yerel olarak (AsyncStorage) saklanır.",
    },
    {
      heading: "Yedekleme",
      body:
        "Dışa aktarma ve içe aktarma işlemleri yalnızca sizin başlattığınızda gerçekleşir. JSON yedek dosyasını nereye kaydedeceğiniz veya kimlerle paylaşacağınız tamamen sizin kontrolünüzdedir.",
    },
    {
      heading: "Resmi Katalog Verisi",
      body:
        "İnşaat, mekanik ve elektrik birim fiyat analizleri kamu kurumlarının yayımladığı kaynaklardan derlenmiş referans verilerdir; uygulama bu kaynakları satmaz ve resmi kurum adına hareket etmez.",
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
      body: `${APP_DISPLAY_NAME} bilgi amaçlı bir referans uygulamasıdır. Resmi kurumların güncel yayınlarının yerine geçmez.`,
    },
    {
      heading: "Doğruluk Sorumluluğu",
      body:
        "Listelenen birim fiyatlar, poz tarifleri ve hesaplamalar yol gösterici niteliktedir. İhale, keşif, sözleşme ve ödeme süreçlerinde nihai kontrol kullanıcıya aittir.",
    },
    {
      heading: "Kullanıcı İçeriği",
      body:
        "Oluşturduğunuz özel analizler ve keşif projeleri size aittir. Yedekleme, paylaşım ve silme sorumluluğu kullanıcıdadır.",
    },
    {
      heading: "Sorumluluk Reddi",
      body:
        "Uygulama “olduğu gibi” sunulur. Veri hatası, güncellik eksikliği veya hesaplama farklarından doğabilecek zararlardan geliştirici sorumlu tutulamaz.",
    },
    {
      heading: "Değişiklikler",
      body:
        "Bu koşullar güncellenebilir. Güncel metin uygulama içinde yayımlandığı tarihten itibaren geçerlidir.",
    },
  ],
} as const;

export const DATA_SOURCE_FULL_NAME =
  "Çevre, Şehircilik ve İklim Değişikliği Bakanlığı Yüksek Fen Kurulu";

export const DATA_SOURCES = {
  title: "Kaynak",
  updatedAt: "21 Haziran 2026",
  sections: [
    {
      heading: "ÇŞB YFK",
      body: `${DATA_SOURCE_FULL_NAME} (ÇŞB YFK) tarafından yayımlanan resmi birim fiyat analizi kitapları referans alınmıştır.`,
    },
    {
      heading: "İnşaat",
      body: `${DATA_SOURCE_LABEL} Cilt 1-2 PDF kamuya açık kaynaklardan derlenmiştir.`,
    },
    {
      heading: "Mekanik Tesisat",
      body: `${DATA_SOURCE_LABEL} Cilt 1-3 PDF kamuya açık kaynaklardan derlenmiştir.`,
    },
    {
      heading: "Elektrik Tesisat",
      body: `${DATA_SOURCE_LABEL} Cilt 1-3 PDF kamuya açık kaynaklardan derlenmiştir.`,
    },
    {
      heading: "Güncellik",
      body: `Uygulama içi katalog son güncelleme: ${DATA_UPDATE_LABEL}. Nihai doğrulama için ilgili kurumların güncel yayınları esas alınmalıdır.`,
    },
    {
      heading: "Not",
      body:
        "Bu uygulama resmi kurumlarla bağlantılı değildir; yalnızca kamuya açık kaynaklardan derlenen referans veriler sunar.",
    },
  ],
} as const;

export type LegalDocument =
  | typeof PRIVACY_POLICY
  | typeof TERMS_OF_USE
  | typeof DATA_SOURCES;
