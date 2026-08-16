/// GitHub Pages aynı origin’de IndexedDB kutu adı paylaşır.
/// `settings` Beton / Puantaj / Malzeme ile çakışır; hepsi `tahvil_` önekli.
abstract final class TahvilHive {
  static const nativeSubdir = 'santijet_tahvil';

  static const settings = 'tahvil_settings';
  static const records = 'tahvil_records';

  static const all = <String>[settings, records];
}
