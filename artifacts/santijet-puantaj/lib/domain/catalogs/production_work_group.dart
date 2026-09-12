import '../entities/production.dart';
import 'task_tags.dart';

/// İmalat iş grubu — grup özeti (İnşaat / Elektrik / Mekanik).
abstract final class ProductionWorkGroupCatalog {
  static String get defaultGroup => TaskTagCatalog.insaat;

  static String normalize(String? raw) {
    final n = TaskTagCatalog.normalize(raw ?? '');
    return n.isEmpty ? defaultGroup : n;
  }

  /// Kayıtlı grup veya eski veri için ekip adından tahmin.
  static String resolve(Production p) {
    if (p.workGroup.trim().isNotEmpty) {
      return normalize(p.workGroup);
    }
    return inferFromTeamName(p.teamName);
  }

  static String inferFromTeamName(String teamName) {
    final t = teamName.trim().toLowerCase();
    if (t.isEmpty) return defaultGroup;
    const elektrikHints = [
      'elektrik',
      'aydınlatma',
      'kablo',
      'zayıf',
      'pano',
    ];
    const mekanikHints = [
      'mekanik',
      'havalandırma',
      'klima',
      'ısıtma',
      'isitma',
      'sıhhi',
      'sihhi',
      'yangın',
      'yangin',
      'su tesisat',
      'tesisat',
    ];
    for (final h in elektrikHints) {
      if (t.contains(h)) return TaskTagCatalog.elektrik;
    }
    for (final h in mekanikHints) {
      if (t.contains(h)) return TaskTagCatalog.mekanik;
    }
    return TaskTagCatalog.insaat;
  }

  static String displayTitle(String group) {
    final g = normalize(group);
    return g;
  }

  static bool matches(Production p, String groupKey) =>
      resolve(p) == normalize(groupKey);
}
