import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../domain/entities/kesif.dart';
import '../../domain/entities/poz_analiz.dart';

const backupVersion = 1;

/// ŞantiJET BFA yedek dosyası.
class BfaBackup {
  const BfaBackup({
    required this.exportedAt,
    required this.userAnalizleri,
    required this.favoriteIds,
    required this.recentIds,
    required this.kesifProjects,
    required this.themeMode,
  });

  final String exportedAt;
  final List<PozAnaliz> userAnalizleri;
  final List<String> favoriteIds;
  final List<String> recentIds;
  final List<KesifProject> kesifProjects;
  final String themeMode;

  Map<String, dynamic> toJson() => {
        'version': backupVersion,
        'app': 'santijet-bfa-flutter',
        'exportedAt': exportedAt,
        'userAnalizleri': userAnalizleri.map((a) => a.toJson()).toList(),
        'favoriteIds': favoriteIds,
        'recentIds': recentIds,
        'kesifProjects': kesifProjects.map((p) => p.toJson()).toList(),
        'themeMode': themeMode,
      };

  factory BfaBackup.fromJson(Map<dynamic, dynamic> json) {
    if (json['app'] != 'santijet-bfa-flutter' &&
        json['app'] != 'santijet-bfa') {
      throw const FormatException('Geçersiz ŞantiJET BFA yedek dosyası.');
    }

    List<T> parseList<T>(Object? value, T Function(Map<dynamic, dynamic>) f) {
      if (value is! List) return const [];
      return value.whereType<Map<dynamic, dynamic>>().map(f).toList();
    }

    return BfaBackup(
      exportedAt:
          json['exportedAt'] as String? ?? DateTime.now().toIso8601String(),
      userAnalizleri: parseList(
        json['userAnalizleri'] ?? json['pozAnalizleri'],
        PozAnaliz.fromJson,
      ),
      favoriteIds:
          (json['favoriteIds'] as List?)?.whereType<String>().toList() ??
              const [],
      recentIds: (json['recentIds'] as List?)?.whereType<String>().toList() ??
          const [],
      kesifProjects: parseList(json['kesifProjects'], KesifProject.fromJson),
      themeMode: json['themeMode'] as String? ?? 'system',
    );
  }
}

class BackupService {
  Future<void> share(BfaBackup backup) async {
    final jsonText =
        const JsonEncoder.withIndent('  ').convert(backup.toJson());
    final bytes = Uint8List.fromList(utf8.encode(jsonText));
    final fileName =
        'santijet_bfa_yedek_${DateTime.now().toIso8601String().substring(0, 10)}.json';

    if (kIsWeb) {
      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile.fromData(bytes, name: fileName, mimeType: 'application/json'),
          ],
        ),
      );
      return;
    }

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes);
    await SharePlus.instance.share(
      ShareParams(
        text: fileName,
        files: [XFile(file.path, mimeType: 'application/json')],
      ),
    );
  }

  Future<BfaBackup?> pickAndParse() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: true,
    );
    final file = result?.files.single;
    if (file == null) return null;

    Uint8List? bytes = file.bytes;
    if (bytes == null && file.path != null) {
      bytes = await File(file.path!).readAsBytes();
    }
    if (bytes == null) return null;

    final decoded = json.decode(utf8.decode(bytes));
    if (decoded is! Map) {
      throw const FormatException('Yedek dosyası JSON nesnesi değil.');
    }
    return BfaBackup.fromJson(decoded);
  }
}

final backupService = BackupService();
