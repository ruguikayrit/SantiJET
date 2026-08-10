import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/theme_mode_provider.dart';
import '../../core/utils/id_gen.dart';
import '../../domain/calc/analiz_hesap.dart';
import '../../domain/entities/kesif.dart';
import '../../domain/enums/app_enums.dart';
import 'kesif_provider.dart';

/// Ayarlar / ilk açılış: Metraj · Keşif · YM’yi dolduran örnek proje.
class DemoSeedController {
  DemoSeedController(this._ref);

  final Ref _ref;

  static const demoProjectName = 'Demo Konut Şantiyesi';
  static const demoProjectCode = 'DEMOMALIY01';
  static const demoSeedVersion = 1;

  Future<KesifProject> loadAll() async {
    final now = DateTime.now().toIso8601String();
    final project = KesifProject(
      id: IdGen.make('kp'),
      ad: demoProjectName,
      aciklama: 'Demo veri — İnşaat / Elektrik / Mekanik metraj cetveli örneği',
      kod: demoProjectCode,
      konum: 'Ankara / Çankaya',
      satirlar: _buildSatirlar(),
      olusturmaTarihi: now,
      guncellemeTarihi: now,
    );

    final others = _ref
        .read(kesifProvider)
        .where(
          (p) =>
              p.kod != demoProjectCode &&
              p.ad != demoProjectName,
        )
        .toList();

    _ref.read(kesifProvider.notifier).replaceAll([project, ...others]);
    _ref.read(activeKesifIdProvider.notifier).set(project.id);
    _ref.read(settingsBoxProvider).put('demoSeedVersion', demoSeedVersion);
    return project;
  }

  List<KesifSatiri> _buildSatirlar() {
    return [
      // —— İnşaat ——
      _satir(
        pozNo: '15.110.1001',
        ad: 'C30/37 beton dökümü (hazır beton)',
        birim: 'm³',
        bf: 2850,
        discipline: AnalizDiscipline.insaat,
        kalemler: [
          MetrajKalemi(
            id: IdGen.make('mk'),
            aciklama: 'Bodrum döşeme',
            tip: MetrajHesapTipi.enBoyYukseklik,
            en: 12,
            boy: 18,
            yukseklik: 0.25,
            adet: 1,
          ).withHesap(),
          MetrajKalemi(
            id: IdGen.make('mk'),
            aciklama: 'Zemin döşeme',
            tip: MetrajHesapTipi.enBoyYukseklik,
            en: 12,
            boy: 18,
            yukseklik: 0.20,
            adet: 1,
          ).withHesap(),
        ],
      ),
      _satir(
        pozNo: '15.140.1001',
        ad: 'Ahşap kalıp — düz yüzey',
        birim: 'm²',
        bf: 420,
        discipline: AnalizDiscipline.insaat,
        kalemler: [
          MetrajKalemi(
            id: IdGen.make('mk'),
            aciklama: 'Perde kalıp',
            tip: MetrajHesapTipi.enBoy,
            en: 2.8,
            boy: 48,
            adet: 2,
          ).withHesap(),
          MetrajKalemi(
            id: IdGen.make('mk'),
            aciklama: 'Döşeme altı',
            tip: MetrajHesapTipi.alan,
            alan: 216,
            adet: 1,
          ).withHesap(),
        ],
      ),
      _satir(
        pozNo: '15.210.1001',
        ad: 'Nervürlü çelik (Ø8–Ø32)',
        birim: 'kg',
        bf: 38.5,
        discipline: AnalizDiscipline.insaat,
        kalemler: [
          MetrajKalemi(
            id: IdGen.make('mk'),
            aciklama: 'Temel demiri',
            tip: MetrajHesapTipi.manuel,
            adet: 1,
            miktar: 12500,
          ).withHesap(manuelMiktar: 12500),
          MetrajKalemi(
            id: IdGen.make('mk'),
            aciklama: 'Kolon-kiriş',
            tip: MetrajHesapTipi.manuel,
            adet: 1,
            miktar: 18600,
          ).withHesap(manuelMiktar: 18600),
        ],
      ),
      _satir(
        pozNo: '18.110.1001',
        ad: 'İç cephe boyası — 2 kat',
        birim: 'm²',
        bf: 95,
        discipline: AnalizDiscipline.insaat,
        kalemler: [
          MetrajKalemi(
            id: IdGen.make('mk'),
            aciklama: 'Kat 1–4 duvar',
            tip: MetrajHesapTipi.enBoy,
            en: 2.7,
            boy: 420,
            adet: 1,
          ).withHesap(),
        ],
      ),
      // —— Elektrik ——
      _satir(
        pozNo: '35.110.1001',
        ad: 'NYA kablo 3×2,5 mm²',
        birim: 'm',
        bf: 48,
        discipline: AnalizDiscipline.elektrik,
        kalemler: [
          MetrajKalemi(
            id: IdGen.make('mk'),
            aciklama: 'Daire hatları',
            tip: MetrajHesapTipi.manuel,
            miktar: 2400,
          ).withHesap(manuelMiktar: 2400),
          MetrajKalemi(
            id: IdGen.make('mk'),
            aciklama: 'Ortak alan',
            tip: MetrajHesapTipi.manuel,
            miktar: 380,
          ).withHesap(manuelMiktar: 380),
        ],
      ),
      _satir(
        pozNo: '35.150.1001',
        ad: 'LED panel armatür 60×60',
        birim: 'ad',
        bf: 850,
        discipline: AnalizDiscipline.elektrik,
        kalemler: [
          MetrajKalemi(
            id: IdGen.make('mk'),
            aciklama: 'Ofis / ortak',
            tip: MetrajHesapTipi.manuel,
            miktar: 96,
          ).withHesap(manuelMiktar: 96),
          MetrajKalemi(
            id: IdGen.make('mk'),
            aciklama: 'Daireler',
            tip: MetrajHesapTipi.manuel,
            miktar: 144,
          ).withHesap(manuelMiktar: 144),
        ],
      ),
      _satir(
        pozNo: '35.210.1001',
        ad: 'Priz grubu (topraklı)',
        birim: 'ad',
        bf: 185,
        discipline: AnalizDiscipline.elektrik,
        kalemler: [
          MetrajKalemi(
            id: IdGen.make('mk'),
            aciklama: 'Konut',
            tip: MetrajHesapTipi.manuel,
            miktar: 320,
          ).withHesap(manuelMiktar: 320),
        ],
      ),
      // —— Mekanik ——
      _satir(
        pozNo: '25.110.1001',
        ad: 'PPR boru Ø25',
        birim: 'm',
        bf: 62,
        discipline: AnalizDiscipline.mekanik,
        kalemler: [
          MetrajKalemi(
            id: IdGen.make('mk'),
            aciklama: 'Sıcak su',
            tip: MetrajHesapTipi.manuel,
            miktar: 540,
          ).withHesap(manuelMiktar: 540),
          MetrajKalemi(
            id: IdGen.make('mk'),
            aciklama: 'Soğuk su',
            tip: MetrajHesapTipi.manuel,
            miktar: 610,
          ).withHesap(manuelMiktar: 610),
        ],
      ),
      _satir(
        pozNo: '25.160.1001',
        ad: 'Split klima 12000 BTU',
        birim: 'ad',
        bf: 18500,
        discipline: AnalizDiscipline.mekanik,
        kalemler: [
          MetrajKalemi(
            id: IdGen.make('mk'),
            aciklama: 'Daire salon',
            tip: MetrajHesapTipi.manuel,
            miktar: 24,
          ).withHesap(manuelMiktar: 24),
        ],
      ),
      _satir(
        pozNo: '25.180.1001',
        ad: 'Yangın dolabı + hortum',
        birim: 'ad',
        bf: 4200,
        discipline: AnalizDiscipline.mekanik,
        kalemler: [
          MetrajKalemi(
            id: IdGen.make('mk'),
            aciklama: 'Kat sahanlıkları',
            tip: MetrajHesapTipi.manuel,
            miktar: 8,
          ).withHesap(manuelMiktar: 8),
        ],
      ),
    ];
  }

  KesifSatiri _satir({
    required String pozNo,
    required String ad,
    required String birim,
    required double bf,
    required AnalizDiscipline discipline,
    required List<MetrajKalemi> kalemler,
  }) {
    final prepared = kalemler.map((k) => k.withHesap()).toList();
    final miktar = prepared.fold<double>(0, (s, k) => s + k.miktar);
    return KesifSatiri(
      id: IdGen.make('ks'),
      analizId: 'demo-$pozNo',
      pozNo: pozNo,
      analizAdi: ad,
      olcuBirimi: birim,
      birimFiyati: bf,
      miktar: miktar,
      tutar: AnalizHesap.satirTutar(miktar, bf),
      fiyatKaynagi: KesifFiyatKaynagi.katalog,
      discipline: discipline,
      metrajKalemleri: prepared,
      metrajNotu: 'Demo cetvel',
    );
  }
}

final demoSeedProvider = Provider<DemoSeedController>((ref) {
  return DemoSeedController(ref);
});

/// İlk frame’de içerik yoksa demo proje yükler.
void seedDemoIfEmpty(WidgetRef ref) {
  final projects = ref.read(kesifProvider);
  if (projects.any((p) => p.satirlar.isNotEmpty)) return;
  ref.read(demoSeedProvider).loadAll();
}
