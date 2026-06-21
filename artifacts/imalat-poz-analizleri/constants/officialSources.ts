/** Resmi kaynak bağlantıları — güncelleme için yalnızca bu dosyayı düzenleyin. */

export const OFFICIAL_SOURCE_UPDATED_AT = "21 Haziran 2026";

/** Veri doğrulama ve genel yönlendirme — YFK birim fiyatlar portalı */
export const OFFICIAL_SOURCE_PORTAL_URL = "https://yfk.csb.gov.tr/birim-fiyatlar-100468";

export const SOURCE_OPEN_CONFIRM_MESSAGE = "Resmi kurum yayını açılacaktır.";

export const SOURCE_DISTRIBUTION_NOTICE =
  "ŞantiJET BFA resmi kurum yayınlarını yeniden dağıtmaz. Kaynak gösterimi amacıyla resmi yayın bağlantıları sunulmaktadır.";

export const SOURCE_VERIFICATION_TEXT =
  "Analiz, poz ve birim fiyat bilgilerinin nihai doğrulaması için ilgili kurumların güncel resmi yayınları esas alınmalıdır.";

export const OFFICIAL_SOURCE_EDITION = "ÇŞİDB YFK 2026 Yayınları";

export interface OfficialSourceLink {
  id: "insaat" | "mekanik" | "elektrik";
  title: string;
  subtitle: string;
  url: string;
}

export const OFFICIAL_SOURCE_LINKS: OfficialSourceLink[] = [
  {
    id: "insaat",
    title: "İnşaat Birim Fiyat ve Analizleri",
    subtitle: OFFICIAL_SOURCE_EDITION,
    url: OFFICIAL_SOURCE_PORTAL_URL,
  },
  {
    id: "mekanik",
    title: "Mekanik Tesisat Birim Fiyat ve Analizleri",
    subtitle: OFFICIAL_SOURCE_EDITION,
    url: OFFICIAL_SOURCE_PORTAL_URL,
  },
  {
    id: "elektrik",
    title: "Elektrik Tesisat Birim Fiyat ve Analizleri",
    subtitle: OFFICIAL_SOURCE_EDITION,
    url: OFFICIAL_SOURCE_PORTAL_URL,
  },
];
