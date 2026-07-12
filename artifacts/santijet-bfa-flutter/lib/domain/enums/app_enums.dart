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

  static AnalizDiscipline fromJson(String? value) => switch (value) {
        'mekanik' => AnalizDiscipline.mekanik,
        'elektrik' => AnalizDiscipline.elektrik,
        _ => AnalizDiscipline.insaat,
      };
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
