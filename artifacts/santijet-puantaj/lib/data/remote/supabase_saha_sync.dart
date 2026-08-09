import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_service.dart';

/// Proje domain verisini `saha_snapshots` üzerinden paylaşır.
class SupabaseSahaSync {
  SupabaseClient get _client => SupabaseService.client;

  static const kinds = [
    'personnel',
    'attendance',
    'production',
    'tasks',
    'daily_reports',
  ];

  Future<void> pushSnapshots({
    required String projectId,
    required String userId,
    required Map<String, List<Map<String, dynamic>>> byKind,
  }) async {
    final now = DateTime.now().toUtc().toIso8601String();
    for (final kind in kinds) {
      final payload = byKind[kind] ?? const <Map<String, dynamic>>[];
      await _client.from('saha_snapshots').upsert({
        'project_id': projectId,
        'kind': kind,
        'payload': payload,
        'updated_at': now,
        'updated_by': userId,
      });
    }
  }

  Future<Map<String, List<Map<String, dynamic>>>> pullSnapshots(
    String projectId,
  ) async {
    final rows = await _client
        .from('saha_snapshots')
        .select()
        .eq('project_id', projectId);

    final out = <String, List<Map<String, dynamic>>>{};
    for (final row in rows) {
      final kind = row['kind'] as String? ?? '';
      final raw = row['payload'];
      final list = <Map<String, dynamic>>[];
      if (raw is List) {
        for (final item in raw) {
          if (item is Map) {
            list.add(Map<String, dynamic>.from(item));
          }
        }
      }
      out[kind] = list;
    }
    return out;
  }
}
