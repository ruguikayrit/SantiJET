import '../enums/main_discipline.dart';

/// Alt başlık katalog seed — Hive veya const; ayarlardan genişletilebilir.
abstract final class DisciplineSubgroups {
  static const Map<MainDiscipline, List<String>> defaults = {
    MainDiscipline.insaat: [
      'Kaba yapı',
      'İnce işler',
      'Yalıtım',
      'Kaplama / seramik',
      'Boyalar',
      'Doğrama',
    ],
    MainDiscipline.elektrik: [
      'Güç dağıtım',
      'Aydınlatma',
      'Zayıf akım',
      'Topraklama',
      'Pano / kablo',
    ],
    MainDiscipline.mekanik: [
      'Sıhhi tesisat',
      'Isıtma',
      'Havalandırma',
      'Yangın',
      'İzolasyon',
    ],
  };

  static List<String> forDiscipline(MainDiscipline d) =>
      List<String>.from(defaults[d] ?? const []);
}
