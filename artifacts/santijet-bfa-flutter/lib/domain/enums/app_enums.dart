// BFA alan modeli enum'ları — React Native tip birliğiyle birebir.

/// Kaydın kaynağı (`PozAnaliz.kaynakTip`).
enum KaynakTip {
  sistem,
  kullanici,
  kopya;

  String get jsonValue => name;

  static KaynakTip fromJson(String? value) => switch (value) {
        'kullanici' => KaynakTip.kullanici,
        'kopya' => KaynakTip.kopya,
        _ => KaynakTip.sistem,
      };
}

/// Analiz disiplini (`discipline`).
enum AnalizDiscipline {
  insaat,
  mekanik,
  elektrik;

  String get jsonValue => name;

  String get label => switch (this) {
        AnalizDiscipline.insaat => 'İnşaat',
        AnalizDiscipline.mekanik => 'Mekanik Tesisat',
        AnalizDiscipline.elektrik => 'Elektrik Tesisat',
      };

  /// Keşif / metraj / YM bölüm başlıkları.
  String get isBasligi => switch (this) {
        AnalizDiscipline.insaat => 'İnşaat İşleri',
        AnalizDiscipline.mekanik => 'Mekanik İşler',
        AnalizDiscipline.elektrik => 'Elektrik İşleri',
      };

  static const List<AnalizDiscipline> kesifSirasi = [
    AnalizDiscipline.insaat,
    AnalizDiscipline.elektrik,
    AnalizDiscipline.mekanik,
  ];

  static AnalizDiscipline fromJson(String? value) => switch (value) {
        'mekanik' => AnalizDiscipline.mekanik,
        'elektrik' => AnalizDiscipline.elektrik,
        _ => AnalizDiscipline.insaat,
      };

  /// Poz no önekine göre disiplin (35=elektrik, 25=mekanik, aksi inşaat).
  static AnalizDiscipline fromPozNo(String pozNo) {
    final digits = pozNo.replaceAll(RegExp(r'\D'), '');
    final prefix = digits.length >= 2 ? digits.substring(0, 2) : '';
    if (prefix == '35') return AnalizDiscipline.elektrik;
    if (prefix == '25') return AnalizDiscipline.mekanik;
    return AnalizDiscipline.insaat;
  }
}

/// Analiz kalemi tipi.
enum AnalizKalemTip {
  malzeme,
  iscilik,
  ekipman;

  String get jsonValue => name;

  static AnalizKalemTip fromJson(String? value) => switch (value) {
        'iscilik' => AnalizKalemTip.iscilik,
        'ekipman' => AnalizKalemTip.ekipman,
        _ => AnalizKalemTip.malzeme,
      };
}
