/// Uygulama rota yolları — Demir / BFA konvansiyonu.
abstract final class AppRoutes {
  static const splash = '/splash';
  static const home = '/';
  static const puantaj = '/puantaj';
  static const imalat = '/imalat';
  /// Eski bağımsız Verim sekmesi — İmalat hub’a yönlendirilir.
  static const verim = '/verim';
  static const gunlukRapor = '/gunluk-rapor';
  static const gorevler = '/gorevler';
  static const personel = '/personel';
  static const ayarlar = '/ayarlar';
  static const yonetim = '/ayarlar/yonetim';
  static const firma = '/ayarlar/yonetim/firma';
  static const projeler = '/ayarlar/projeler';
  static const projeKatil = '/ayarlar/projeler/katil';
  static const auth = '/ayarlar/hesap';
  static const meslekler = '/ayarlar/yonetim/meslekler';
  static const ekipler = '/ayarlar/yonetim/ekipler';
  static const gorevKategorileri = '/ayarlar/yonetim/gorev-kategorileri';
  static const hakkinda = '/ayarlar/hakkinda';

  /// Eski yol — `/personel` rotasına yönlendirilir.
  static const personelLegacy = '/ayarlar/yonetim/personel';

  static String projeUyeler(String projectId) =>
      '/ayarlar/projeler/$projectId/uyeler';
}
