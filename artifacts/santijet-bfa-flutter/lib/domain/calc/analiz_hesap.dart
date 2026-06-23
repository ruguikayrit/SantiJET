import '../entities/poz_analiz.dart';

/// Analiz maliyet hesabı sonucu.
class AnalizHesapSonucu {
  const AnalizHesapSonucu({
    required this.malzemeIscilikToplami,
    required this.yukleniciKarTutari,
    required this.birimFiyati,
  });

  final double malzemeIscilikToplami;
  final double yukleniciKarTutari;
  final double birimFiyati;
}

/// Analiz birim fiyat hesabı.
///
/// React Native `hesaplaAnalizToplam` ile birebir: kalem tutarları toplanır,
/// yüklenici kârı eklenir, kuruş hassasiyetinde yuvarlanır.
abstract final class AnalizHesap {
  static double _round2(double value) => (value * 100).round() / 100;

  static AnalizHesapSonucu hesapla(PozAnaliz analiz) {
    final toplam = analiz.kalemler.fold<double>(0, (sum, k) => sum + k.tutar);
    final kar = _round2(toplam * (analiz.yukleniciKarOrani / 100));
    return AnalizHesapSonucu(
      malzemeIscilikToplami: _round2(toplam),
      yukleniciKarTutari: kar,
      birimFiyati: _round2(toplam + kar),
    );
  }

  /// Metraj × birim fiyat = satır tutarı (kuruş yuvarlamalı).
  static double satirTutar(double miktar, double birimFiyati) {
    final qty = miktar.isFinite ? miktar : 0;
    return _round2(qty * birimFiyati);
  }
}
