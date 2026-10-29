import 'package:hive/hive.dart';

/// Her proje için ayrı veri alanı — şimdilik proje kimliği ile ayrıştırılmış
/// depolama anahtarları. İleride bulut senkronizasyonu bu katmana bağlanır.
class ProjectDataRepository {
  ProjectDataRepository(this._box);

  final Box _box;

  static const projectDomains = [
    'survey',
    'orders',
    'deliveries',
    'field_counts',
    'rebar_metraj',
    'cutting_bending',
  ];

  String _key(String projectId, String domain) => 'pdata:$projectId:$domain';

  Map<String, Map<String, dynamic>> exportDomains(String projectId) {
    final out = <String, Map<String, dynamic>>{};
    for (final domain in projectDomains) {
      final data = readDomain(projectId, domain);
      if (data != null) {
        out[domain] = data;
      }
    }
    return out;
  }

  Future<void> importDomains(
    String projectId,
    Map<String, Map<String, dynamic>> domains,
  ) async {
    for (final entry in domains.entries) {
      if (!projectDomains.contains(entry.key)) continue;
      await writeDomain(projectId, entry.key, entry.value);
    }
  }

  bool isSeeded(String projectId) {
    return _box.get(_key(projectId, 'seeded'), defaultValue: false) as bool;
  }

  Future<void> markSeeded(String projectId) async {
    await _box.put(_key(projectId, 'seeded'), true);
  }

  Map<String, dynamic>? readDomain(String projectId, String domain) {
    final raw = _box.get(_key(projectId, domain));
    if (raw is Map) {
      return raw.map((key, value) => MapEntry(key.toString(), value));
    }
    return null;
  }

  Future<void> writeDomain(
    String projectId,
    String domain,
    Map<String, dynamic> data,
  ) async {
    await _box.put(_key(projectId, domain), data);
  }
}
