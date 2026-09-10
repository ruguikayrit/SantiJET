import '../../domain/program_item.dart';

/// Dosya alışverişinde kullanılan biçimler.
enum InteropFormat {
  msProjectXml('MS Project XML', 'xml'),
  excel('Excel', 'xlsx'),
  pdf('PDF', 'pdf');

  const InteropFormat(this.label, this.extension);
  final String label;
  final String extension;
}

/// Bir dosyadan okunan faaliyetler ve okuma sırasında biriken uyarılar.
class ProgramImportResult {
  const ProgramImportResult({
    required this.items,
    this.warnings = const [],
    this.projectName,
  });

  final List<ProgramItem> items;
  final List<String> warnings;
  final String? projectName;

  bool get isEmpty => items.isEmpty;
}

/// Okunan dosya beklenen yapıda değilse atılır.
class ProgramImportException implements Exception {
  const ProgramImportException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// MS Project bir iş gününü 480 dakika sayar; süre alanları buna göre yazılır.
const int minutesPerWorkDay = 480;

/// Faaliyet kimliğini şantiye ve görev numarasından türetir; aynı dosya
/// yeniden aktarıldığında satırlar çoğalmaz, güncellenir.
String interopItemId(String santiyeId, int taskUid) {
  final slug = santiyeId
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  return 'mspdi-${slug.isEmpty ? 'santiye' : slug}-$taskUid';
}

DateTime dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

String isoDate(DateTime value) => value.toIso8601String().substring(0, 10);

String trDate(DateTime value) {
  final d = value.day.toString().padLeft(2, '0');
  final m = value.month.toString().padLeft(2, '0');
  return '$d.$m.${value.year}';
}

/// MS Project'in `PT80H0M0S` biçimli süre metnini üretir.
String msProjectDuration(int days) {
  final minutes = days * minutesPerWorkDay;
  return 'PT${minutes ~/ 60}H${minutes % 60}M0S';
}

/// `PT80H0M0S`, `P10D` ve `PT4H` gibi süre metinlerini iş gününe çevirir.
int? parseMsProjectDurationDays(String? raw) {
  if (raw == null || raw.trim().isEmpty) return null;
  final text = raw.trim().toUpperCase();
  final match = RegExp(
    r'^-?P(?:(\d+(?:\.\d+)?)Y)?(?:(\d+(?:\.\d+)?)M)?(?:(\d+(?:\.\d+)?)D)?'
    r'(?:T(?:(\d+(?:\.\d+)?)H)?(?:(\d+(?:\.\d+)?)M)?(?:(\d+(?:\.\d+)?)S)?)?$',
  ).firstMatch(text);
  if (match == null) return null;

  double part(int group) => double.tryParse(match.group(group) ?? '') ?? 0;

  final totalMinutes =
      part(3) * minutesPerWorkDay +
      part(4) * 60 +
      part(5) +
      part(6) / 60 +
      part(1) * 12 * 20 * minutesPerWorkDay +
      part(2) * 20 * minutesPerWorkDay;
  if (totalMinutes <= 0) return 0;
  return (totalMinutes / minutesPerWorkDay).round();
}

/// MS Project ve Excel dosyalarındaki tarih yazımlarını çözer.
DateTime? parseInteropDate(String? raw) {
  if (raw == null) return null;
  final text = raw.trim();
  if (text.isEmpty) return null;

  final iso = DateTime.tryParse(text);
  if (iso != null) return dateOnly(iso);

  final match = RegExp(
    r'^(\d{1,2})[.\-/](\d{1,2})[.\-/](\d{4})',
  ).firstMatch(text);
  if (match == null) return null;
  final day = int.parse(match.group(1)!);
  final month = int.parse(match.group(2)!);
  final year = int.parse(match.group(3)!);
  if (month < 1 || month > 12 || day < 1 || day > 31) return null;
  return DateTime(year, month, day);
}

/// Yüzdeyi 0–100 aralığına çeker; `0,45` gibi oranları da kabul eder.
int normalizeProgress(num? value) {
  if (value == null) return 0;
  final asDouble = value.toDouble();
  final percent = asDouble > 0 && asDouble <= 1 && asDouble != 1
      ? asDouble * 100
      : asDouble;
  return percent.round().clamp(0, 100);
}

/// İçe aktarılan ilerleme ve tarihlerden uygulama durumunu üretir.
ProgramStatus statusFromProgress({
  required int progress,
  required DateTime startDate,
  required DateTime endDate,
  DateTime? today,
}) {
  final day = dateOnly(today ?? DateTime.now());
  if (progress >= 100) return ProgramStatus.completed;
  if (day.isAfter(dateOnly(endDate))) return ProgramStatus.delayed;
  if (progress > 0 || !day.isBefore(dateOnly(startDate))) {
    return ProgramStatus.inProgress;
  }
  return ProgramStatus.planned;
}

/// Türkçe ya da İngilizce yazılmış bir durum metnini çözer.
ProgramStatus? statusFromLabel(String? raw) {
  if (raw == null) return null;
  final text = raw.trim().toLowerCase();
  if (text.isEmpty) return null;
  if (text.contains('tamam') || text.contains('complete')) {
    return ProgramStatus.completed;
  }
  if (text.contains('gecik') || text.contains('delay') || text.contains('late')) {
    return ProgramStatus.delayed;
  }
  if (text.contains('devam') || text.contains('progress')) {
    return ProgramStatus.inProgress;
  }
  if (text.contains('planla') || text.contains('plan')) {
    return ProgramStatus.planned;
  }
  return null;
}

/// MS Project öncül metninin tek bir halkası, ör. `4FS+2 gün`.
class PredecessorRef {
  const PredecessorRef({
    required this.uid,
    this.type = 'FS',
    this.lagDays = 0,
  });

  final int uid;
  final String type;
  final int lagDays;

  int get typeCode => switch (type) {
    'FF' => 0,
    'SF' => 2,
    'SS' => 3,
    _ => 1,
  };

  /// MSPDI `LinkLag` değeri: iş gününün onda biri dakika cinsinden.
  int get lagTenthsOfMinutes => lagDays * minutesPerWorkDay * 10;
}

/// `2FS+3 gün; 5SS` gibi metni Project bağlarına çevirir.
List<PredecessorRef> parsePredecessorText(String? raw) {
  if (raw == null) return const [];
  final parts = raw.split(RegExp(r'[;,]'));
  final refs = <PredecessorRef>[];
  final pattern = RegExp(
    r'^(\d+)\s*(FS|FF|SF|SS)?\s*(?:([+-]\d+)\s*(?:g[uü]n|d)?)?$',
    caseSensitive: false,
  );
  for (final part in parts) {
    final match = pattern.firstMatch(part.trim());
    if (match == null) continue;
    refs.add(
      PredecessorRef(
        uid: int.parse(match.group(1)!),
        type: (match.group(2) ?? 'FS').toUpperCase(),
        lagDays: int.tryParse(match.group(3) ?? '0') ?? 0,
      ),
    );
  }
  return refs;
}
