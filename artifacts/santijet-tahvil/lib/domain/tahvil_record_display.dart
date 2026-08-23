import 'tahvil_record.dart';

/// Kayıt kartında gösterilecek özet satırları (yeni ve eski kayıtlar).
class TahvilRecordDisplay {
  const TahvilRecordDisplay({
    required this.headerLabel,
    required this.sourceLine,
    required this.targetLine,
    required this.sourceAs,
    required this.targetAs,
    required this.asUnit,
    required this.isAllowed,
  });

  final String headerLabel;
  final String sourceLine;
  final String targetLine;
  final double sourceAs;
  final double targetAs;
  final String asUnit;
  final bool isAllowed;

  factory TahvilRecordDisplay.from(TahvilRecord record) {
    if (record.hasStructuredDisplay) {
      return TahvilRecordDisplay(
        headerLabel: record.basis,
        sourceLine: record.sourceLine!,
        targetLine: record.targetLine!,
        sourceAs: record.sourceAs!,
        targetAs: record.targetAs!,
        asUnit: record.asUnit ?? 'mm²',
        isAllowed: record.isAllowed,
      );
    }
    return _fromLegacy(record);
  }

  static TahvilRecordDisplay _fromLegacy(TahvilRecord record) {
    final asParsed = _parseAsFromDetail(record.detail);
    final lines = _parseLinesFromSummary(record.summary);

    return TahvilRecordDisplay(
      headerLabel: record.basis,
      sourceLine: lines?.source ?? record.summary,
      targetLine: lines?.target ?? record.summary,
      sourceAs: asParsed?.source ?? 0,
      targetAs: asParsed?.target ?? 0,
      asUnit: asParsed?.unit ?? 'mm²',
      isAllowed: record.isAllowed,
    );
  }

  static ({double source, double target, String unit})? _parseAsFromDetail(
    String detail,
  ) {
    final match = RegExp(
      r'As\s+([\d.]+)\s*→\s*([\d.]+)\s*(mm²/m|mm²)',
    ).firstMatch(detail);
    if (match == null) return null;
    final source = double.tryParse(match.group(1)!);
    final target = double.tryParse(match.group(2)!);
    if (source == null || target == null) return null;
    return (
      source: source,
      target: target,
      unit: match.group(3) ?? 'mm²',
    );
  }

  static ({String source, String target})? _parseLinesFromSummary(
    String summary,
  ) {
    if (summary.contains('→') && summary.contains(' · ')) {
      return _parseDualLegSummary(summary);
    }
    if (summary.contains('→')) {
      final parts = summary.split('→');
      if (parts.length != 2) return null;
      return (source: parts[0].trim(), target: parts[1].trim());
    }
    return null;
  }

  static ({String source, String target}) _parseDualLegSummary(String summary) {
    final sources = <String>[];
    final targets = <String>[];
    for (final leg in summary.split(' · ')) {
      final trimmed = leg.trim();
      if (trimmed.contains('→')) {
        final parts = trimmed.split('→');
        sources.add(parts[0].trim());
        targets.add(parts[1].trim().replaceAll(' (aynı)', ''));
      } else {
        final same = trimmed.replaceAll(' (aynı)', '');
        sources.add(same);
        targets.add(same);
      }
    }
    return (source: sources.join(' · '), target: targets.join(' · '));
  }
}
