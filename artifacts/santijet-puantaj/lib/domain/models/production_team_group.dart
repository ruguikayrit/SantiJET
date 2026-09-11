import '../entities/production.dart';

/// İmalat / Verim ekip özeti — aynı ekip adı + aynı metraj birimi birlikte özetlenir.
class ProductionTeamGroup {
  const ProductionTeamGroup({
    required this.teamName,
    required this.unit,
  });

  final String teamName;
  final String unit;

  /// Filtre ve gruplama anahtarı.
  String get groupKey => '$teamName|$unit';

  /// Kart başlığı — geniş disiplin adları (Elektrik / Mekanik) gösterilmez.
  String get cardTitle {
    if (isBroadDisciplineTeam(teamName)) {
      return '$unit · özet';
    }
    return teamName;
  }

  static const broadDisciplineTeams = {
    'elektrik',
    'mekanik',
    'mekanik / havalandırma',
  };

  static bool isBroadDisciplineTeam(String name) =>
      broadDisciplineTeams.contains(name.trim().toLowerCase());

  static String normalizeTeamName(Production p) {
    final t = p.teamName.trim();
    return t.isEmpty ? 'Ekip seçilmedi' : t;
  }

  static String normalizeUnit(Production p) {
    final u = p.unit.trim();
    return u.isEmpty ? 'adet' : u;
  }

  static ProductionTeamGroup fromProduction(Production p) {
    return ProductionTeamGroup(
      teamName: normalizeTeamName(p),
      unit: normalizeUnit(p),
    );
  }

  static bool matchesProduction(Production p, String groupKey) =>
      fromProduction(p).groupKey == groupKey;
}
