import 'dart:convert';

import 'backup_file_access_stub.dart'
    if (dart.library.html) 'backup_file_access_web.dart'
    if (dart.library.io) 'backup_file_access_io.dart' as file_access;

const puantajBackupFormatId = 'santijet-puantaj-backup';
const puantajBackupVersion = 2;

class PuantajBackupException implements Exception {
  PuantajBackupException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Tüm uygulama verisinin JSON yedeği.
class PuantajBackupPayload {
  const PuantajBackupPayload({
    required this.version,
    required this.exportedAt,
    required this.projects,
    required this.personnel,
    required this.attendance,
    required this.productions,
    required this.professions,
    required this.teams,
    this.activeProjectId,
    this.workSchedule,
    this.kesif,
    this.tasks = const [],
    this.dailyReports = const [],
    this.yevmiyeliIs = const [],
    this.uninsuredTeams = const [],
    this.taskCategories = const [],
    this.companyInfo,
    this.dailyReportExportSections,
    this.workSchedulesByProject = const {},
    this.kesifByProject = const {},
  });

  final int version;
  final DateTime exportedAt;
  final List<Map<String, dynamic>> projects;
  final List<Map<String, dynamic>> personnel;
  final List<Map<String, dynamic>> attendance;
  final List<Map<String, dynamic>> productions;
  final List<String> professions;
  final List<String> teams;
  final String? activeProjectId;
  final Map<String, dynamic>? workSchedule;
  final Map<String, dynamic>? kesif;
  final List<Map<String, dynamic>> tasks;
  final List<Map<String, dynamic>> dailyReports;
  final List<Map<String, dynamic>> yevmiyeliIs;
  final List<Map<String, dynamic>> uninsuredTeams;
  final List<String> taskCategories;
  final Map<String, dynamic>? companyInfo;
  final Map<String, dynamic>? dailyReportExportSections;
  final Map<String, Map<String, dynamic>> workSchedulesByProject;
  final Map<String, Map<String, dynamic>> kesifByProject;

  Map<String, dynamic> toJson() => {
        'format': puantajBackupFormatId,
        'version': version,
        'exportedAt': exportedAt.toIso8601String(),
        if (activeProjectId != null) 'activeProjectId': activeProjectId,
        'projects': projects,
        'personnel': personnel,
        'attendance': attendance,
        'productions': productions,
        'professions': professions,
        'teams': teams,
        if (workSchedule != null) 'workSchedule': workSchedule,
        if (kesif != null) 'kesif': kesif,
        'tasks': tasks,
        'dailyReports': dailyReports,
        'yevmiyeliIs': yevmiyeliIs,
        'uninsuredTeams': uninsuredTeams,
        'taskCategories': taskCategories,
        if (companyInfo != null) 'companyInfo': companyInfo,
        if (dailyReportExportSections != null)
          'dailyReportExportSections': dailyReportExportSections,
        if (workSchedulesByProject.isNotEmpty)
          'workSchedulesByProject': workSchedulesByProject,
        if (kesifByProject.isNotEmpty) 'kesifByProject': kesifByProject,
      };

  String toJsonString() =>
      const JsonEncoder.withIndent('  ').convert(toJson());

  factory PuantajBackupPayload.fromJson(Map<String, dynamic> json) {
    if (json['format'] != puantajBackupFormatId) {
      throw PuantajBackupException(
        'Bu dosya ŞantiJET Puantaj yedeği değil',
      );
    }
    final version = (json['version'] as num?)?.toInt() ?? 0;
    if (version > puantajBackupVersion) {
      throw PuantajBackupException(
        'Yedek sürümü ($version) uygulama sürümünden '
        '($puantajBackupVersion) yeni',
      );
    }

    List<Map<String, dynamic>> listOfMaps(String key) {
      final raw = json[key];
      if (raw is! List) return const [];
      return raw
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }

    List<String> listOfStrings(String key) {
      final raw = json[key];
      if (raw is! List) return const [];
      return raw
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }

    final exportedAtRaw = json['exportedAt'] as String?;
    final workRaw = json['workSchedule'];
    final kesifRaw = json['kesif'];
    final companyRaw = json['companyInfo'];
    final sectionsRaw = json['dailyReportExportSections'];

    Map<String, Map<String, dynamic>> mapOfMaps(String key) {
      final raw = json[key];
      if (raw is! Map) return const {};
      final out = <String, Map<String, dynamic>>{};
      raw.forEach((k, v) {
        if (v is Map) {
          out[k.toString()] = Map<String, dynamic>.from(v);
        }
      });
      return out;
    }

    return PuantajBackupPayload(
      version: version,
      exportedAt: exportedAtRaw != null
          ? DateTime.tryParse(exportedAtRaw) ?? DateTime.now()
          : DateTime.now(),
      activeProjectId: json['activeProjectId'] as String?,
      projects: listOfMaps('projects'),
      personnel: listOfMaps('personnel'),
      attendance: listOfMaps('attendance'),
      productions: listOfMaps('productions'),
      professions: listOfStrings('professions'),
      teams: listOfStrings('teams'),
      workSchedule: workRaw is Map
          ? Map<String, dynamic>.from(workRaw)
          : null,
      kesif: kesifRaw is Map ? Map<String, dynamic>.from(kesifRaw) : null,
      tasks: listOfMaps('tasks'),
      dailyReports: listOfMaps('dailyReports'),
      yevmiyeliIs: listOfMaps('yevmiyeliIs'),
      uninsuredTeams: listOfMaps('uninsuredTeams'),
      taskCategories: listOfStrings('taskCategories'),
      companyInfo:
          companyRaw is Map ? Map<String, dynamic>.from(companyRaw) : null,
      dailyReportExportSections: sectionsRaw is Map
          ? Map<String, dynamic>.from(sectionsRaw)
          : null,
      workSchedulesByProject: mapOfMaps('workSchedulesByProject'),
      kesifByProject: mapOfMaps('kesifByProject'),
    );
  }

  static PuantajBackupPayload parse(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      throw PuantajBackupException('Geçersiz yedek dosyası');
    }
    return PuantajBackupPayload.fromJson(
      Map<String, dynamic>.from(decoded),
    );
  }
}

class PuantajBackupService {
  Future<void> exportBackup(PuantajBackupPayload payload) async {
    final bytes = utf8.encode(payload.toJsonString());
    final stamp = payload.exportedAt;
    final fileName =
        'santijet-puantaj-yedek-'
        '${stamp.year}'
        '${stamp.month.toString().padLeft(2, '0')}'
        '${stamp.day.toString().padLeft(2, '0')}'
        '.json';

    await file_access.downloadJsonFile(
      fileName: fileName,
      bytes: bytes,
    );
  }

  Future<PuantajBackupPayload?> pickAndParse() async {
    final raw = await file_access.pickJsonText();
    if (raw == null || raw.trim().isEmpty) return null;
    return PuantajBackupPayload.parse(raw);
  }
}

final puantajBackupService = PuantajBackupService();
