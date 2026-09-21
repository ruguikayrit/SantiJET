import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/attendance.dart';
import '../../domain/enums/attendance_status.dart';
import 'supabase_service.dart';

/// Satır bazlı domain senkron — upsert / pull / realtime.
class SupabaseRowSync {
  SupabaseClient get _client => SupabaseService.client;

  // —— Attendance (düz kolonlar) ——

  Future<void> upsertAttendance({
    required Attendance row,
    required String userId,
  }) async {
    final now = DateTime.now().toUtc().toIso8601String();
    await _client.from('saha_attendance').upsert({
      'id': row.id,
      'project_id': row.projectId,
      'person_id': row.personId,
      'person_name': row.personName,
      'date': row.date,
      'status': row.status.jsonValue,
      'hours': row.hours,
      'overtime_hours': row.overtimeHours,
      'note': row.note,
      'updated_at': now,
      'updated_by': userId,
    });
  }

  Future<void> upsertAttendanceBatch({
    required List<Attendance> rows,
    required String userId,
  }) async {
    if (rows.isEmpty) return;
    final now = DateTime.now().toUtc().toIso8601String();
    await _client.from('saha_attendance').upsert([
      for (final row in rows)
        {
          'id': row.id,
          'project_id': row.projectId,
          'person_id': row.personId,
          'person_name': row.personName,
          'date': row.date,
          'status': row.status.jsonValue,
          'hours': row.hours,
          'overtime_hours': row.overtimeHours,
          'note': row.note,
          'updated_at': now,
          'updated_by': userId,
        },
    ]);
  }

  Future<void> deleteAttendance({
    required String projectId,
    required String personId,
    required String date,
  }) async {
    await _client
        .from('saha_attendance')
        .delete()
        .eq('project_id', projectId)
        .eq('person_id', personId)
        .eq('date', date);
  }

  Future<List<(Attendance, DateTime)>> pullAttendance(String projectId) async {
    final rows = await _client
        .from('saha_attendance')
        .select()
        .eq('project_id', projectId);
    return [
      for (final row in rows)
        (
          attendanceFromRow(Map<String, dynamic>.from(row as Map)),
          _parseTs(row['updated_at']),
        ),
    ];
  }

  static Attendance attendanceFromRow(Map<String, dynamic> row) {
    final status = AttendanceStatus.parse(row['status'] as String? ?? 'absent');
    return Attendance(
      id: row['id'] as String? ?? '',
      projectId: row['project_id'] as String,
      personId: row['person_id'] as String,
      personName: row['person_name'] as String? ?? '',
      date: row['date'] as String,
      status: status,
      hours: (row['hours'] as num?)?.toInt() ?? status.hours,
      overtimeHours: (row['overtime_hours'] as num?)?.toDouble() ?? 0,
      note: row['note'] as String? ?? '',
    );
  }

  // —— JSON payload tabloları ——

  Future<void> upsertPayloadRow({
    required String table,
    required String projectId,
    required String id,
    required Map<String, dynamic> payload,
    required String userId,
    String? date,
  }) async {
    final now = DateTime.now().toUtc().toIso8601String();
    final map = <String, dynamic>{
      'id': id,
      'project_id': projectId,
      'payload': payload,
      'updated_at': now,
      'updated_by': userId,
    };
    if (date != null) map['date'] = date;
    await _client.from(table).upsert(map);
  }

  Future<void> upsertPayloadBatch({
    required String table,
    required String projectId,
    required List<({String id, Map<String, dynamic> payload, String? date})>
        rows,
    required String userId,
    int chunkSize = 40,
  }) async {
    if (rows.isEmpty) return;
    final now = DateTime.now().toUtc().toIso8601String();
    for (var i = 0; i < rows.length; i += chunkSize) {
      final end = (i + chunkSize < rows.length) ? i + chunkSize : rows.length;
      final slice = rows.sublist(i, end);
      await _client.from(table).upsert([
        for (final r in slice)
          {
            'id': r.id,
            'project_id': projectId,
            'payload': r.payload,
            'updated_at': now,
            'updated_by': userId,
            if (r.date != null) 'date': r.date,
          },
      ]);
    }
  }

  Future<void> deletePayloadRow({
    required String table,
    required String projectId,
    required String id,
  }) async {
    await _client
        .from(table)
        .delete()
        .eq('project_id', projectId)
        .eq('id', id);
  }

  Future<List<(Map<String, dynamic>, DateTime)>> pullPayloadTable({
    required String table,
    required String projectId,
  }) async {
    final rows =
        await _client.from(table).select().eq('project_id', projectId);
    final out = <(Map<String, dynamic>, DateTime)>[];
    for (final row in rows) {
      final map = Map<String, dynamic>.from(row as Map);
      final raw = map['payload'];
      final payload = raw is Map
          ? Map<String, dynamic>.from(raw)
          : <String, dynamic>{};
      payload['projectId'] = projectId;
      if (payload['id'] == null && map['id'] != null) {
        payload['id'] = map['id'];
      }
      out.add((payload, _parseTs(map['updated_at'])));
    }
    return out;
  }

  RealtimeChannel subscribeProject({
    required String projectId,
    required void Function(String table, PostgresChangePayload payload)
        onChange,
  }) {
    final channel = _client.channel('saha-rows-$projectId');
    for (final table in const [
      'saha_attendance',
      'saha_personnel',
      'saha_production',
      'saha_tasks',
      'saha_daily_reports',
      'saha_yevmiyeli',
      'saha_uninsured_teams',
    ]) {
      channel.onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: table,
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'project_id',
          value: projectId,
        ),
        callback: (payload) => onChange(table, payload),
      );
    }
    channel.subscribe();
    return channel;
  }

  Future<void> removeChannel(RealtimeChannel channel) async {
    await _client.removeChannel(channel);
  }

  static DateTime _parseTs(Object? raw) {
    if (raw is String) {
      return DateTime.tryParse(raw)?.toUtc() ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    }
    return DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
  }
}
