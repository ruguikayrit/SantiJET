import 'kesif_plan.dart';
import 'work_schedule_plan.dart';

/// Uygulamalar arası offline plan paketi — bulut gerekmez.
///
/// Formatlar:
/// - `santijet-kesif-pack` → plan metraj
/// - `santijet-program-pack` → plan gün / iş gücü
/// - `santijet-plan-pack` → ikisi birden
abstract final class SantijetPlanPackFormats {
  static const kesif = 'santijet-kesif-pack';
  static const program = 'santijet-program-pack';
  static const combined = 'santijet-plan-pack';
  static const version = 1;

  static bool isKnown(String format) =>
      format == kesif || format == program || format == combined;
}

enum SantijetPlanPackKind { kesif, program, combined }

/// Dosyadan okunan plan paketi (ham JSON sözleşmesi).
class SantijetPlanPack {
  const SantijetPlanPack({
    required this.format,
    required this.version,
    required this.exportedAt,
    required this.kind,
    this.projectCode = '',
    this.projectName = '',
    this.sourceApp = '',
    this.kesifItems = const [],
    this.programItems = const [],
  });

  final String format;
  final int version;
  final DateTime exportedAt;
  final SantijetPlanPackKind kind;
  final String projectCode;
  final String projectName;
  final String sourceApp;
  final List<KesifItem> kesifItems;
  final List<WorkScheduleItem> programItems;

  bool get hasKesif => kesifItems.isNotEmpty;
  bool get hasProgram => programItems.isNotEmpty;

  Map<String, dynamic> toJson() {
    final base = <String, dynamic>{
      'format': format,
      'version': version,
      'exportedAt': exportedAt.toIso8601String(),
      if (projectCode.isNotEmpty) 'projectCode': projectCode,
      if (projectName.isNotEmpty) 'projectName': projectName,
      if (sourceApp.isNotEmpty) 'sourceApp': sourceApp,
    };
    switch (kind) {
      case SantijetPlanPackKind.kesif:
        return {
          ...base,
          'items': kesifItems.map((e) => e.toJson()).toList(),
        };
      case SantijetPlanPackKind.program:
        return {
          ...base,
          'items': programItems.map((e) => e.toJson()).toList(),
        };
      case SantijetPlanPackKind.combined:
        return {
          ...base,
          'kesif': {
            'items': kesifItems.map((e) => e.toJson()).toList(),
          },
          'program': {
            'items': programItems.map((e) => e.toJson()).toList(),
          },
        };
    }
  }

  factory SantijetPlanPack.fromJson(Map<String, dynamic> json) {
    final format = (json['format'] as String? ?? '').trim();
    if (!SantijetPlanPackFormats.isKnown(format)) {
      throw SantijetPlanPackException(
        'Bilinmeyen paket formatı: "$format". '
        'Beklenen: keşif / iş programı / birleşik plan paketi.',
      );
    }
    final version = (json['version'] as num?)?.toInt() ?? 0;
    if (version < 1 || version > SantijetPlanPackFormats.version) {
      throw SantijetPlanPackException(
        'Desteklenmeyen paket sürümü: $version '
        '(en fazla ${SantijetPlanPackFormats.version}).',
      );
    }

    final exportedAt = DateTime.tryParse(json['exportedAt'] as String? ?? '') ??
        DateTime.now();
    final projectCode = (json['projectCode'] as String? ?? '').trim();
    final projectName = (json['projectName'] as String? ?? '').trim();
    final sourceApp = (json['sourceApp'] as String? ?? '').trim();

    if (format == SantijetPlanPackFormats.kesif) {
      return SantijetPlanPack(
        format: format,
        version: version,
        exportedAt: exportedAt,
        kind: SantijetPlanPackKind.kesif,
        projectCode: projectCode,
        projectName: projectName,
        sourceApp: sourceApp,
        kesifItems: _parseKesifItems(json['items']),
      );
    }
    if (format == SantijetPlanPackFormats.program) {
      return SantijetPlanPack(
        format: format,
        version: version,
        exportedAt: exportedAt,
        kind: SantijetPlanPackKind.program,
        projectCode: projectCode,
        projectName: projectName,
        sourceApp: sourceApp,
        programItems: _parseProgramItems(json['items']),
      );
    }

    final kesifRaw = json['kesif'];
    final programRaw = json['program'];
    final kesifMap = kesifRaw is Map
        ? Map<String, dynamic>.from(kesifRaw)
        : const <String, dynamic>{};
    final programMap = programRaw is Map
        ? Map<String, dynamic>.from(programRaw)
        : const <String, dynamic>{};

    return SantijetPlanPack(
      format: format,
      version: version,
      exportedAt: exportedAt,
      kind: SantijetPlanPackKind.combined,
      projectCode: projectCode,
      projectName: projectName,
      sourceApp: sourceApp,
      kesifItems: _parseKesifItems(kesifMap['items'] ?? json['kesifItems']),
      programItems:
          _parseProgramItems(programMap['items'] ?? json['programItems']),
    );
  }

  static List<KesifItem> _parseKesifItems(dynamic raw) {
    if (raw is! List) return const [];
    final out = <KesifItem>[];
    for (final e in raw) {
      if (e is Map) {
        out.add(KesifItem.fromJson(Map<String, dynamic>.from(e)));
      }
    }
    return out;
  }

  static List<WorkScheduleItem> _parseProgramItems(dynamic raw) {
    if (raw is! List) return const [];
    final out = <WorkScheduleItem>[];
    for (final e in raw) {
      if (e is Map) {
        out.add(WorkScheduleItem.fromJson(Map<String, dynamic>.from(e)));
      }
    }
    return out;
  }
}

class SantijetPlanPackException implements Exception {
  SantijetPlanPackException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// İçe aktarımda form alanlarına yazma politikası.
enum PlanFieldApplyMode {
  /// Yalnızca boş / sıfır alanları doldur (manuel girişi korur).
  fillEmpty,

  /// Eşleşen plan alanlarını paket değerleriyle üzerine yaz.
  overwrite,
}
