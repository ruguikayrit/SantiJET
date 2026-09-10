import 'kasa_hareket.dart';
import 'kasa_lookups.dart';

/// İçe aktarım öncesi satır uyarısı.
enum ImportIssue {
  tarihSupheli,
  tutarYok,
  odemeBilinmiyor,
  belgeBilinmiyor,
  aciklamaKisa,
  mukerrer,
}

extension ImportIssueLabel on ImportIssue {
  String get label => switch (this) {
        ImportIssue.tarihSupheli => 'Tarih okunamamış olabilir',
        ImportIssue.tutarYok => 'Tutar yok',
        ImportIssue.odemeBilinmiyor => 'Ödeme şekli tanınmadı',
        ImportIssue.belgeBilinmiyor => 'Belge türü tanınmadı',
        ImportIssue.aciklamaKisa => 'Açıklama çok kısa',
        ImportIssue.mukerrer => 'Kasada aynısı var',
      };
}

String _fold(String s) => s
    .toLowerCase()
    .replaceAll('ı', 'i')
    .replaceAll('İ', 'i')
    .replaceAll('ş', 's')
    .replaceAll('ğ', 'g')
    .replaceAll('ü', 'u')
    .replaceAll('ö', 'o')
    .replaceAll('ç', 'c')
    .replaceAll(RegExp(r'[^a-z0-9]'), '');

String _dupKey(KasaHareket h) {
  final d = '${h.tarih.year}-${h.tarih.month}-${h.tarih.day}';
  final amount = h.tutar.toStringAsFixed(2);
  final name = _fold(h.tedarikci.isEmpty ? h.aciklama : h.tedarikci);
  return '$d|$amount|$name';
}

/// Her satır için uyarı kümesi — sıra `rows` ile birebir.
///
/// `existing` kasadaki hareketler; parti içi tekrarlar da işaretlenir.
List<Set<ImportIssue>> analyzeImportRows({
  required List<KasaHareket> rows,
  List<KasaHareket> existing = const [],
  DateTime? now,
}) {
  final stamp = now ?? DateTime.now();
  final today = DateTime(stamp.year, stamp.month, stamp.day);
  final seen = existing.map(_dupKey).toSet();

  return rows.map((h) {
    final issues = <ImportIssue>{};

    final d = DateTime(h.tarih.year, h.tarih.month, h.tarih.day);
    // OCR tarihi okuyamayınca içe aktarım anına düşer.
    if (!d.isBefore(today)) issues.add(ImportIssue.tarihSupheli);

    if (h.tutar <= 0) issues.add(ImportIssue.tutarYok);
    if (h.aciklama.trim().length < 3) issues.add(ImportIssue.aciklamaKisa);
    if (!OdemeSekli.all.contains(h.odemeSekli)) {
      issues.add(ImportIssue.odemeBilinmiyor);
    }
    if (!BelgeTuru.all.contains(h.belgeTuru)) {
      issues.add(ImportIssue.belgeBilinmiyor);
    }

    final key = _dupKey(h);
    if (!seen.add(key)) issues.add(ImportIssue.mukerrer);

    return issues;
  }).toList();
}
