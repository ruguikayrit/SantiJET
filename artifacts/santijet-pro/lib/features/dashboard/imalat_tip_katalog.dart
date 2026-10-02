part of 'dashboard_screen.dart';

/// İmalat grubu (İnşaat · Elektrik · Mekanik) sabittir; tipler bu listeden seçilir.
/// İmalat listesinde yalnızca en az bir kaydı olan tipler görünür.
class _ImalatAltTurTanim {
  const _ImalatAltTurTanim({
    required this.id,
    required this.label,
    required this.ana,
    required this.bolum,
    this.isKalemleri = const [],
  });

  final String id;
  final String label;
  final _ImalatAnaTur ana;
  final String bolum;
  final List<String> isKalemleri;
}

const _imalatAltTurKatalog = <_ImalatAltTurTanim>[
  // İnşaat · Hazırlık ve toprak işleri
  _ImalatAltTurTanim(id: 'yikim', label: 'Yıkım ve Söküm', ana: _ImalatAnaTur.insaat, bolum: 'Hazırlık ve Toprak İşleri'),
  _ImalatAltTurTanim(id: 'kazi', label: 'Kazı', ana: _ImalatAnaTur.insaat, bolum: 'Hazırlık ve Toprak İşleri'),
  _ImalatAltTurTanim(id: 'dolgu', label: 'Dolgu ve Sıkıştırma', ana: _ImalatAnaTur.insaat, bolum: 'Hazırlık ve Toprak İşleri'),
  _ImalatAltTurTanim(id: 'iksa', label: 'İksa ve Fore Kazık', ana: _ImalatAnaTur.insaat, bolum: 'Hazırlık ve Toprak İşleri'),
  _ImalatAltTurTanim(id: 'zemin_iyilestirme', label: 'Zemin İyileştirme', ana: _ImalatAnaTur.insaat, bolum: 'Hazırlık ve Toprak İşleri'),

  // İnşaat · Kaba yapı
  _ImalatAltTurTanim(id: 'grobeton', label: 'Grobeton', ana: _ImalatAnaTur.insaat, bolum: 'Kaba Yapı'),
  _ImalatAltTurTanim(id: 'kalip', label: 'Kalıp', ana: _ImalatAnaTur.insaat, bolum: 'Kaba Yapı'),
  _ImalatAltTurTanim(id: 'demir', label: 'Donatı', ana: _ImalatAnaTur.insaat, bolum: 'Kaba Yapı'),
  _ImalatAltTurTanim(id: 'beton_dokum', label: 'Beton Dökümü', ana: _ImalatAnaTur.insaat, bolum: 'Kaba Yapı'),
  _ImalatAltTurTanim(id: 'iskele', label: 'İskele', ana: _ImalatAnaTur.insaat, bolum: 'Kaba Yapı'),
  _ImalatAltTurTanim(id: 'prekast', label: 'Prekast Montaj', ana: _ImalatAnaTur.insaat, bolum: 'Kaba Yapı'),
  _ImalatAltTurTanim(id: 'celik_konstruksiyon', label: 'Çelik Konstrüksiyon', ana: _ImalatAnaTur.insaat, bolum: 'Kaba Yapı'),

  // İnşaat · Duvar
  _ImalatAltTurTanim(id: 'duvar', label: 'Duvar', ana: _ImalatAnaTur.insaat, bolum: 'Duvar'),
  _ImalatAltTurTanim(id: 'alcipan_bolme', label: 'Alçıpan Bölme Duvar', ana: _ImalatAnaTur.insaat, bolum: 'Duvar'),
  _ImalatAltTurTanim(id: 'lento_hatil', label: 'Lento ve Hatıl', ana: _ImalatAnaTur.insaat, bolum: 'Duvar'),

  // İnşaat · Yalıtım
  _ImalatAltTurTanim(id: 'su_yalitimi', label: 'Su Yalıtımı', ana: _ImalatAnaTur.insaat, bolum: 'Yalıtım'),
  _ImalatAltTurTanim(id: 'islak_hacim_yalitimi', label: 'Islak Hacim Yalıtımı', ana: _ImalatAnaTur.insaat, bolum: 'Yalıtım'),
  _ImalatAltTurTanim(id: 'mantolama', label: 'Mantolama', ana: _ImalatAnaTur.insaat, bolum: 'Yalıtım'),
  _ImalatAltTurTanim(id: 'ses_yalitimi', label: 'Ses Yalıtımı', ana: _ImalatAnaTur.insaat, bolum: 'Yalıtım'),

  // İnşaat · Sıva ve alçı
  _ImalatAltTurTanim(id: 'kaba_siva', label: 'Kaba Sıva', ana: _ImalatAnaTur.insaat, bolum: 'Sıva ve Alçı'),
  _ImalatAltTurTanim(id: 'alcisiva', label: 'Alçı Sıva', ana: _ImalatAnaTur.insaat, bolum: 'Sıva ve Alçı'),
  _ImalatAltTurTanim(id: 'saten_alci', label: 'Saten Alçı', ana: _ImalatAnaTur.insaat, bolum: 'Sıva ve Alçı'),
  _ImalatAltTurTanim(id: 'dis_cephe_siva', label: 'Dış Cephe Sıvası', ana: _ImalatAnaTur.insaat, bolum: 'Sıva ve Alçı'),

  // İnşaat · Şap ve zemin kaplama
  _ImalatAltTurTanim(id: 'sap', label: 'Şap', ana: _ImalatAnaTur.insaat, bolum: 'Şap ve Zemin Kaplama'),
  _ImalatAltTurTanim(id: 'seramik', label: 'Seramik Kaplama', ana: _ImalatAnaTur.insaat, bolum: 'Şap ve Zemin Kaplama'),
  _ImalatAltTurTanim(id: 'fayans', label: 'Fayans Kaplama', ana: _ImalatAnaTur.insaat, bolum: 'Şap ve Zemin Kaplama'),
  _ImalatAltTurTanim(id: 'granit_mermer', label: 'Granit ve Mermer', ana: _ImalatAnaTur.insaat, bolum: 'Şap ve Zemin Kaplama'),
  _ImalatAltTurTanim(id: 'parke', label: 'Parke ve Laminat', ana: _ImalatAnaTur.insaat, bolum: 'Şap ve Zemin Kaplama'),
  _ImalatAltTurTanim(id: 'epoksi', label: 'Epoksi Zemin', ana: _ImalatAnaTur.insaat, bolum: 'Şap ve Zemin Kaplama'),
  _ImalatAltTurTanim(id: 'supurgelik', label: 'Süpürgelik', ana: _ImalatAnaTur.insaat, bolum: 'Şap ve Zemin Kaplama'),
  _ImalatAltTurTanim(id: 'merdiven_kaplama', label: 'Merdiven Kaplama', ana: _ImalatAnaTur.insaat, bolum: 'Şap ve Zemin Kaplama'),

  // İnşaat · Boya ve tavan
  _ImalatAltTurTanim(id: 'ic_boya', label: 'İç Cephe Boya', ana: _ImalatAnaTur.insaat, bolum: 'Boya ve Tavan'),
  _ImalatAltTurTanim(id: 'dis_boya', label: 'Dış Cephe Boya', ana: _ImalatAnaTur.insaat, bolum: 'Boya ve Tavan'),
  _ImalatAltTurTanim(id: 'asma_tavan', label: 'Asma Tavan', ana: _ImalatAnaTur.insaat, bolum: 'Boya ve Tavan'),
  _ImalatAltTurTanim(id: 'kartonpiyer', label: 'Kartonpiyer', ana: _ImalatAnaTur.insaat, bolum: 'Boya ve Tavan'),

  // İnşaat · Doğrama ve cephe
  _ImalatAltTurTanim(id: 'pencere_dograma', label: 'PVC / Alüminyum Doğrama', ana: _ImalatAnaTur.insaat, bolum: 'Doğrama ve Cephe'),
  _ImalatAltTurTanim(id: 'ic_kapi', label: 'İç Kapı', ana: _ImalatAnaTur.insaat, bolum: 'Doğrama ve Cephe'),
  _ImalatAltTurTanim(id: 'celik_kapi', label: 'Çelik ve Yangın Kapısı', ana: _ImalatAnaTur.insaat, bolum: 'Doğrama ve Cephe'),
  _ImalatAltTurTanim(id: 'giydirme_cephe', label: 'Giydirme Cephe', ana: _ImalatAnaTur.insaat, bolum: 'Doğrama ve Cephe'),
  _ImalatAltTurTanim(id: 'cephe_kaplama', label: 'Cephe Kaplama', ana: _ImalatAnaTur.insaat, bolum: 'Doğrama ve Cephe'),
  _ImalatAltTurTanim(id: 'korkuluk', label: 'Korkuluk ve Küpeşte', ana: _ImalatAnaTur.insaat, bolum: 'Doğrama ve Cephe'),

  // İnşaat · Çatı
  _ImalatAltTurTanim(id: 'cati_konstruksiyon', label: 'Çatı Konstrüksiyonu', ana: _ImalatAnaTur.insaat, bolum: 'Çatı'),
  _ImalatAltTurTanim(id: 'cati_kaplama', label: 'Çatı Kaplama', ana: _ImalatAnaTur.insaat, bolum: 'Çatı'),
  _ImalatAltTurTanim(id: 'cati_yalitimi', label: 'Çatı Yalıtımı', ana: _ImalatAnaTur.insaat, bolum: 'Çatı'),
  _ImalatAltTurTanim(id: 'cati_deresi', label: 'Çatı Deresi ve Yağmur İnişi', ana: _ImalatAnaTur.insaat, bolum: 'Çatı'),

  // İnşaat · Çevre ve altyapı
  _ImalatAltTurTanim(id: 'drenaj', label: 'Drenaj', ana: _ImalatAnaTur.insaat, bolum: 'Çevre ve Altyapı'),
  _ImalatAltTurTanim(id: 'cevre_duvari', label: 'Çevre Duvarı', ana: _ImalatAnaTur.insaat, bolum: 'Çevre ve Altyapı'),
  _ImalatAltTurTanim(id: 'bordur', label: 'Bordür', ana: _ImalatAnaTur.insaat, bolum: 'Çevre ve Altyapı'),
  _ImalatAltTurTanim(id: 'kilit_tasi', label: 'Kilit Taşı', ana: _ImalatAnaTur.insaat, bolum: 'Çevre ve Altyapı'),
  _ImalatAltTurTanim(id: 'asfalt', label: 'Asfalt', ana: _ImalatAnaTur.insaat, bolum: 'Çevre ve Altyapı'),
  _ImalatAltTurTanim(id: 'peyzaj', label: 'Peyzaj', ana: _ImalatAnaTur.insaat, bolum: 'Çevre ve Altyapı'),

  // Elektrik
  _ImalatAltTurTanim(id: 'kablo', label: 'Kablo', ana: _ImalatAnaTur.elektrik, bolum: 'Elektrik'),
  _ImalatAltTurTanim(id: 'pano', label: 'Pano', ana: _ImalatAnaTur.elektrik, bolum: 'Elektrik'),
  _ImalatAltTurTanim(id: 'aydinlatma', label: 'Aydınlatma', ana: _ImalatAnaTur.elektrik, bolum: 'Elektrik'),

  // Mekanik
  _ImalatAltTurTanim(id: 'hvac', label: 'HVAC', ana: _ImalatAnaTur.mekanik, bolum: 'Mekanik'),
  _ImalatAltTurTanim(id: 'sihhi', label: 'Sıhhi Tesisat', ana: _ImalatAnaTur.mekanik, bolum: 'Mekanik'),
  _ImalatAltTurTanim(id: 'yangin', label: 'Yangın Tesisatı', ana: _ImalatAnaTur.mekanik, bolum: 'Mekanik'),
];

_ImalatAltTurTanim? _imalatAltTurBul(String id, [List<_ImalatAltTurTanim> ozel = const []]) {
  for (final t in _imalatAltTurKatalog) {
    if (t.id == id) return t;
  }
  for (final t in ozel) {
    if (t.id == id) return t;
  }
  return null;
}

List<_ImalatAltTurTanim> _imalatAltTurlerAna(_ImalatAnaTur ana, [List<_ImalatAltTurTanim> ozel = const []]) => [
      ..._imalatAltTurKatalog.where((t) => t.ana == ana),
      ...ozel.where((t) => t.ana == ana),
    ];

/// Hazır bölümler, ardından elle eklenen imalat tipleri.
List<String> _imalatBolumAdlari(_ImalatAnaTur ana, [List<_ImalatAltTurTanim> ozel = const []]) {
  final adlar = <String>[];
  for (final t in _imalatAltTurlerAna(ana, ozel)) {
    if (adlar.contains(t.bolum)) continue;
    adlar.add(t.bolum);
  }
  return adlar;
}

/// Yazılan ad hazır listedeyse katalogdaki yazımı döner.
String? _imalatBolumEsle(String ad, _ImalatAnaTur ana, [List<_ImalatAltTurTanim> ozel = const []]) {
  final hedef = ad.trim().toLowerCase();
  if (hedef.isEmpty) return null;
  for (final bolum in _imalatBolumAdlari(ana, ozel)) {
    if (bolum.toLowerCase() == hedef) return bolum;
  }
  return null;
}

/// Katalog sırasını koruyarak bölüm → tipler.
Map<String, List<_ImalatAltTurTanim>> _imalatTipBolumleri(_ImalatAnaTur ana, [List<_ImalatAltTurTanim> ozel = const []]) {
  final bolumler = <String, List<_ImalatAltTurTanim>>{};
  for (final t in _imalatAltTurlerAna(ana, ozel)) {
    bolumler.putIfAbsent(t.bolum, () => []).add(t);
  }
  return bolumler;
}

String _imalatVarsayilanTip(_ImalatAnaTur ana, [List<_ImalatAltTurTanim> ozel = const []]) {
  if (ana == _ImalatAnaTur.insaat) return 'kalip';
  final liste = _imalatAltTurlerAna(ana, ozel);
  return liste.isEmpty ? 'kablo' : liste.first.id;
}

List<_ImalatAltTurTanim> _imalatAcikAltTurler(
  List<_ImalatKayit> kayitlar,
  _ImalatAnaTur ana, [
  List<_ImalatAltTurTanim> ozel = const [],
]) {
  final ids = kayitlar.where((k) => k.anaTur == ana).map((k) => k.altTurId).toSet();
  return _imalatAltTurlerAna(ana, ozel).where((t) => ids.contains(t.id)).toList();
}

String _imalatOzelTipId() => 'ozel-${DateTime.now().microsecondsSinceEpoch}';
