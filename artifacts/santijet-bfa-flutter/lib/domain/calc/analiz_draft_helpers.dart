import '../../core/constants/poz_constants.dart';
import '../../core/utils/id_gen.dart';
import '../entities/analiz_kalemi.dart';
import '../entities/poz_analiz.dart';
import '../enums/app_enums.dart';
import 'analiz_hesap.dart';

/// Analiz düzenleme/yeni kayıt yardımcıları.
abstract final class AnalizDraftHelpers {
  static double parseNum(String raw) {
    final normalized = raw.trim().replaceAll('.', '').replaceAll(',', '.');
    return double.tryParse(normalized) ?? 0;
  }

  static AnalizKalemi recalcKalem(AnalizKalemi kalem) {
    final miktar = kalem.miktar.isFinite ? kalem.miktar : 0.0;
    final bf = kalem.birimFiyati.isFinite ? kalem.birimFiyati : 0.0;
    return kalem.copyWith(tutar: AnalizHesap.satirTutar(miktar, bf));
  }

  static PozAnaliz applyTotals(PozAnaliz analiz) {
    final kalemler = analiz.kalemler.map(recalcKalem).toList();
    final hesap = AnalizHesap.hesapla(analiz.copyWith(kalemler: kalemler));
    return analiz.copyWith(
      kalemler: kalemler,
      malzemeIscilikToplami: hesap.malzemeIscilikToplami,
      yukleniciKarTutari: hesap.yukleniciKarTutari,
      birimFiyati: hesap.birimFiyati,
    );
  }

  static PozAnaliz emptyTemplate(AnalizDiscipline discipline) {
    final now = DateTime.now().toIso8601String();
    return PozAnaliz(
      id: '',
      pozNo: '',
      analizAdi: '',
      olcuBirimi: 'm²',
      kategori: PozConstants.kategoriler.first,
      kalemler: const [],
      yukleniciKarOrani: PozConstants.defaultYukleniciKarOrani,
      kaynakTip: KaynakTip.kullanici,
      discipline: discipline,
      olusturmaTarihi: now,
      guncellemeTarihi: now,
    );
  }

  static AnalizKalemi newKalem(AnalizKalemTip tip) {
    return AnalizKalemi(
      id: IdGen.make('k'),
      tip: tip,
      pozNo: '',
      tanim: '',
      olcuBirimi: '',
      miktar: 0,
      birimFiyati: 0,
      tutar: 0,
    );
  }
}
