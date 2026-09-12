import '../regulation/regulation_rule.dart';

enum CheckStatus {
  passed('Sağlandı', '✓'),
  failed('Sağlanmadı', '✕'),
  engineerReview('Mühendis kontrolü', '⚠'),
  info('Bilgi', '—');

  const CheckStatus(this.label, this.mark);
  final String label;
  final String mark;
}

enum TahvilVerdict {
  suitable('UYGUN'),
  notSuitable('UYGUN DEĞİL'),
  engineerReview('MÜHENDİS KONTROLÜ GEREKLİ');

  const TahvilVerdict(this.label);
  final String label;
}

class TahvilCheck {
  const TahvilCheck({
    required this.id,
    required this.title,
    required this.rule,
    required this.status,
    this.projectValue,
    this.newValue,
    this.message,
  });

  final String id;
  final String title;
  final RegulationRule rule;
  final CheckStatus status;
  final String? projectValue;
  final String? newValue;
  final String? message;
}

class TahvilTableRow {
  const TahvilTableRow({
    required this.parameter,
    this.project = '—',
    this.replacement = '—',
    this.mark = '—',
  });

  final String parameter;
  final String project;
  final String replacement;
  final String mark;
}

class TahvilResult {
  const TahvilResult({
    required this.verdict,
    required this.checks,
    required this.table,
    required this.asUnit,
    this.isValid = true,
    this.inputError,
    this.projectAs,
    this.newAs,
    this.projectLine,
    this.newLine,
    this.notes = const [],
  });

  factory TahvilResult.invalid(String message) {
    return TahvilResult(
      isValid: false,
      inputError: message,
      verdict: TahvilVerdict.notSuitable,
      checks: const [],
      table: const [],
      asUnit: 'mm²',
    );
  }

  final bool isValid;
  final String? inputError;
  final TahvilVerdict verdict;
  final List<TahvilCheck> checks;
  final List<TahvilTableRow> table;
  final double? projectAs;
  final double? newAs;
  final String asUnit;
  final String? projectLine;
  final String? newLine;
  final List<String> notes;

  double? get asDelta =>
      projectAs == null || newAs == null ? null : newAs! - projectAs!;

  double? get asDeltaPercent {
    if (projectAs == null || newAs == null || projectAs! <= 0) return null;
    return ((newAs! - projectAs!) / projectAs!) * 100;
  }

  static const disclaimer =
      'Otomatik tahvil kontrolleri sonucudur. Bu sonuç statik projenin, '
      'ilgili yönetmeliklerin ve proje müellifi onayının yerine geçmez.';

  String get outcomeLine => switch (verdict) {
        TahvilVerdict.suitable =>
          'Otomatik tahvil kontrolleri sonucunda UYGUN',
        TahvilVerdict.notSuitable =>
          'Otomatik tahvil kontrolleri sonucunda UYGUN DEĞİL',
        TahvilVerdict.engineerReview =>
          'MÜHENDİS KONTROLÜ GEREKLİ',
      };
}

TahvilVerdict verdictFromChecks(List<TahvilCheck> checks) {
  if (checks.any((c) => c.status == CheckStatus.failed)) {
    return TahvilVerdict.notSuitable;
  }
  if (checks.any((c) => c.status == CheckStatus.engineerReview)) {
    return TahvilVerdict.engineerReview;
  }
  return TahvilVerdict.suitable;
}

class TahvilSuggestion {
  const TahvilSuggestion({
    required this.label,
    required this.result,
    required this.excessAs,
  });

  final String label;
  final TahvilResult result;
  final double excessAs;

  bool get isAcceptable =>
      result.isValid && result.verdict != TahvilVerdict.notSuitable;
}
