/// Resmi kaynak bağlantıları.
abstract final class OfficialSources {
  static const updatedAt = '21 Haziran 2026';
  static const edition = 'ÇŞİDB YFK 2026 Yayınları';
  static const portalUrl = 'https://yfk.csb.gov.tr/birim-fiyatlar-100468';
  static const distributionNotice =
      'ŞantiJET BFA resmi kurum yayınlarını yeniden dağıtmaz. Kaynak gösterimi amacıyla resmi yayın bağlantıları sunmaktadır.';
  static const verificationText =
      'Analiz, poz ve birim fiyat bilgilerinin nihai doğrulaması için ilgili kurumların güncel resmi yayınları esas alınmalıdır.';
}

class OfficialSourceLink {
  const OfficialSourceLink({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.url,
  });

  final String id;
  final String title;
  final String subtitle;
  final String url;
}

const officialSourceLinks = [
  OfficialSourceLink(
    id: 'insaat',
    title: 'İnşaat Birim Fiyat ve Analizleri',
    subtitle: OfficialSources.edition,
    url: OfficialSources.portalUrl,
  ),
  OfficialSourceLink(
    id: 'mekanik',
    title: 'Mekanik Tesisat Birim Fiyat ve Analizleri',
    subtitle: OfficialSources.edition,
    url: OfficialSources.portalUrl,
  ),
  OfficialSourceLink(
    id: 'elektrik',
    title: 'Elektrik Tesisat Birim Fiyat ve Analizleri',
    subtitle: OfficialSources.edition,
    url: OfficialSources.portalUrl,
  ),
];
