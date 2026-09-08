/// GitHub Pages aynı origin’de IndexedDB kutu adı paylaşır.
/// Çıplak `settings` açma — hepsi `kasa_` önekli.
abstract final class KasaHive {
  static const nativeSubdir = 'santijet_kasa';

  static const settings = 'kasa_settings';
  static const hareketler = 'kasa_hareketler';
  static const santiyeler = 'kasa_santiyeler';

  static const all = <String>[settings, hareketler, santiyeler];
}
