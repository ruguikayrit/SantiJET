import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Yedek kapsamı — tam proje veya yalnızca keşif.
enum BackupScope {
  project('project'),
  survey('survey'),
  full('full');

  const BackupScope(this.value);
  final String value;

  static BackupScope? fromValue(String? raw) {
    if (raw == null) return null;
    for (final scope in BackupScope.values) {
      if (scope.value == raw) return scope;
    }
    return null;
  }
}

class BackupPayload {
  const BackupPayload({
    required this.scope,
    required this.version,
    required this.exportedAt,
    required this.projectId,
    required this.projectName,
    required this.domains,
    this.settings,
  });

  final BackupScope scope;
  final int version;
  final DateTime exportedAt;
  final String? projectId;
  final String? projectName;
  final Map<String, Map<String, dynamic>> domains;
  final Map<String, dynamic>? settings;

  Map<String, dynamic> toJson() => {
        'format': backupFormatId,
        'scope': scope.value,
        'version': version,
        'exportedAt': exportedAt.toIso8601String(),
        if (projectId != null) 'projectId': projectId,
        if (projectName != null) 'projectName': projectName,
        'domains': domains,
        if (settings != null) 'settings': settings,
      };

  String toJsonString() => const JsonEncoder.withIndent('  ').convert(toJson());
}

const backupFormatId = 'santijet-demir-backup';
const backupVersion = 1;

class BackupParseException implements Exception {
  BackupParseException(this.message);
  final String message;

  @override
  String toString() => message;
}

BackupPayload parseBackupPayload(String raw) {
  final dynamic decoded = jsonDecode(raw);
  if (decoded is! Map) {
    throw BackupParseException('Geçersiz yedek dosyası');
  }

  final map = decoded.map((key, value) => MapEntry(key.toString(), value));
  if (map['format'] != backupFormatId) {
    throw BackupParseException('Bu dosya ŞantiJET DEMİR yedeği değil');
  }

  final version = (map['version'] as num?)?.toInt() ?? 0;
  if (version > backupVersion) {
    throw BackupParseException(
      'Yedek sürümü ($version) uygulama sürümünden ($backupVersion) yeni',
    );
  }

  final scope = BackupScope.fromValue(map['scope'] as String?);
  if (scope == null) {
    throw BackupParseException('Yedek kapsamı tanınmıyor');
  }

  final exportedAtRaw = map['exportedAt'] as String?;
  final exportedAt = exportedAtRaw != null
      ? DateTime.tryParse(exportedAtRaw) ?? DateTime.now()
      : DateTime.now();

  final domainsRaw = map['domains'];
  if (domainsRaw is! Map || domainsRaw.isEmpty) {
    throw BackupParseException('Yedekte veri alanı bulunamadı');
  }

  final domains = <String, Map<String, dynamic>>{};
  for (final entry in domainsRaw.entries) {
    if (entry.value is Map) {
      domains[entry.key.toString()] = (entry.value as Map)
          .map((key, value) => MapEntry(key.toString(), value));
    }
  }

  if (domains.isEmpty) {
    throw BackupParseException('Yedekte okunabilir veri yok');
  }

  Map<String, dynamic>? settings;
  final settingsRaw = map['settings'];
  if (settingsRaw is Map) {
    settings = settingsRaw.map((key, value) => MapEntry(key.toString(), value));
  }

  return BackupPayload(
    scope: scope,
    version: version,
    exportedAt: exportedAt,
    projectId: map['projectId'] as String?,
    projectName: map['projectName'] as String?,
    domains: domains,
    settings: settings,
  );
}

class ProjectBackupService {
  Future<void> shareBackup(BackupPayload payload) async {
    final bytes = utf8.encode(payload.toJsonString());
    final fileName = _buildFileName(payload);

    if (kIsWeb) {
      await Share.shareXFiles(
        [
          XFile.fromData(
            Uint8List.fromList(bytes),
            name: fileName,
            mimeType: 'application/json',
          ),
        ],
        text: 'ŞantiJET DEMİR yedeği',
      );
      return;
    }

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes);
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/json')],
      text: 'ŞantiJET DEMİR yedeği',
    );
  }

  Future<BackupPayload?> pickAndParseBackup() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['json'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return null;

    final file = result.files.first;
    final String? raw;
    if (file.bytes != null) {
      raw = utf8.decode(file.bytes!);
    } else if (file.path != null && !kIsWeb) {
      raw = await File(file.path!).readAsString();
    } else {
      throw BackupParseException('Dosya okunamadı');
    }

    return parseBackupPayload(raw);
  }

  String _buildFileName(BackupPayload payload) {
    final name = _safeFileName(payload.projectName ?? 'proje');
    final scope = payload.scope == BackupScope.survey ? 'kesif' : 'proje';
    final date = payload.exportedAt;
    final stamp =
        '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';
    return 'santijet-demir-$scope-$name-$stamp.json';
  }

  String _safeFileName(String input) {
    return input
        .toLowerCase()
        .replaceAll(RegExp(r'[çÇ]'), 'c')
        .replaceAll(RegExp(r'[ğĞ]'), 'g')
        .replaceAll(RegExp(r'[ıİ]'), 'i')
        .replaceAll(RegExp(r'[öÖ]'), 'o')
        .replaceAll(RegExp(r'[şŞ]'), 's')
        .replaceAll(RegExp(r'[üÜ]'), 'u')
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }
}

final projectBackupService = ProjectBackupService();
