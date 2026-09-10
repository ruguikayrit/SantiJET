import 'dart:convert';
import 'dart:typed_data';

import '../../domain/daily_crew_entry.dart';
import '../../domain/program_item.dart';
import '../../domain/program_project.dart';

class ProgramBackup {
  const ProgramBackup({
    required this.projects,
    required this.items,
    required this.dailyCrew,
    required this.profile,
    this.activeProjectId,
    this.themeMode,
  });

  final List<ProgramProject> projects;
  final List<ProgramItem> items;
  final List<DailyCrewEntry> dailyCrew;
  final LocalProfile profile;
  final String? activeProjectId;
  final String? themeMode;

  Map<String, dynamic> toJson() => {
    'app': 'santijet_is_programi',
    'version': 1,
    'projects': projects.map((project) => project.toJson()).toList(),
    'items': items.map((item) => item.toJson()).toList(),
    'dailyCrew': dailyCrew.map((entry) => entry.toJson()).toList(),
    'profile': profile.toJson(),
    'activeProjectId': activeProjectId,
    'themeMode': themeMode,
  };

  factory ProgramBackup.fromJson(Map<String, dynamic> json) {
    if (json['app'] != 'santijet_is_programi') {
      throw const FormatException(
        'Bu dosya ŞantiJET İş Programı yedeği değil.',
      );
    }
    List<Map<String, dynamic>> list(String key) =>
        ((json[key] as List?) ?? const [])
            .whereType<Map>()
            .map((raw) => Map<String, dynamic>.from(raw))
            .toList();

    return ProgramBackup(
      projects: list('projects').map(ProgramProject.fromJson).toList(),
      items: list('items').map(ProgramItem.fromJson).toList(),
      dailyCrew: list('dailyCrew').map(DailyCrewEntry.fromJson).toList(),
      profile: LocalProfile.fromJson(
        json['profile'] is Map
            ? Map<String, dynamic>.from(json['profile'] as Map)
            : null,
      ),
      activeProjectId: json['activeProjectId'] as String?,
      themeMode: json['themeMode'] as String?,
    );
  }

  Uint8List encode() =>
      Uint8List.fromList(utf8.encode(const JsonEncoder.withIndent('  ').convert(toJson())));

  static ProgramBackup decode(Uint8List bytes) {
    final raw = jsonDecode(utf8.decode(bytes));
    if (raw is! Map) {
      throw const FormatException('Yedek dosyası okunamadı.');
    }
    return ProgramBackup.fromJson(Map<String, dynamic>.from(raw));
  }
}
