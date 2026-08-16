/// GitHub Pages aynı origin’de IndexedDB kutu adı paylaşır.
/// `settings` / `projects` Beton ve Puantaj ile çakışır; hepsi `malzeme_` önekli.
/// `Hive.initFlutter` alt klasörü yalnızca native’de işe yarar; web’de kutu adı yeter.
abstract final class MalzemeHive {
  static const nativeSubdir = 'santijet_malzeme';

  static const settings = 'malzeme_settings';
  static const projects = 'malzeme_projects';
  static const kesif = 'malzeme_kesif';
  static const requests = 'malzeme_requests';
  static const quotes = 'malzeme_quotes';
  static const deliveries = 'malzeme_deliveries';
  static const library = 'malzeme_library';
  static const unitConsumptions = 'malzeme_unit_consumptions';

  static const all = <String>[
    settings,
    projects,
    kesif,
    requests,
    quotes,
    deliveries,
    library,
    unitConsumptions,
  ];
}
