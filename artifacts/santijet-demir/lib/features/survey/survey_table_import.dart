import 'package:excel/excel.dart';
import 'package:santijet_demir/data/services/rebar_survey_mapper.dart';
import 'package:santijet_demir/data/services/rebar_weight_calculator.dart';
import 'package:santijet_demir/domain/entities/survey.dart';

class SurveyImportException implements Exception {
  SurveyImportException(this.message);

  final String message;

  @override
  String toString() => message;
}

class SurveyImportMerge {
  const SurveyImportMerge({
    required this.imalats,
    required this.added,
    required this.updated,
  });

  final List<SurveyImalat> imalats;
  final int added;
  final int updated;
}

/// Referans Excel sayfa adı — başka sayfa okunmaz.
const surveyImportSheetName = 'Keşif';
const surveyImportRulesSheetName = 'Kurallar';
const surveyImportTemplateFileName = 'santijet-demir-kesif-sablon.xlsx';

const surveyImportFormatHint =
    'Dosya, ŞantiJET DEMİR keşif şablonuna uymalıdır. '
    'Sayfa adı «Keşif» olmalı; 1. satır başlıkları '
    'İmalat, Ø8, Ø10, Ø12, Ø14, Ø16, Ø18, Ø20, Ø22, Ø25, Ø28, Ø32 '
    'sırasıyla değişmemelidir. Hücreler ton cinsinden sayıdır.';

List<String> get surveyImportHeaders => [
      'İmalat',
      ...RebarWeightCalculator.standardDiameters.map((diameter) => 'Ø$diameter'),
    ];

List<String> get _expectedNormalizedHeaders => [
      'imalat',
      ...RebarWeightCalculator.standardDiameters.map((diameter) => '$diameter'),
    ];

/// Kullanıcının dolduracağı resmi şablon (Keşif + Kurallar).
List<int> buildSurveyImportTemplateBytes({
  List<SurveyImalat> examples = const [],
}) {
  final excel = Excel.createExcel();
  final rules = excel[surveyImportRulesSheetName];
  final sheet = excel[surveyImportSheetName];
  excel.setDefaultSheet(surveyImportSheetName);
  if (excel.sheets.containsKey('Sheet1')) {
    excel.delete('Sheet1');
  }

  for (final line in _surveyImportRulesLines) {
    rules.appendRow([TextCellValue(line)]);
  }

  sheet.appendRow(surveyImportHeaders.map(TextCellValue.new).toList());
  for (final imalat in examples) {
    sheet.appendRow(_imalatTemplateRow(imalat));
  }

  final encoded = excel.encode();
  if (encoded == null || encoded.isEmpty) {
    throw StateError('Keşif şablonu oluşturulamadı');
  }
  return encoded;
}

/// Excel içe aktarır. Yalnızca referans şablon düzeni kabul edilir.
List<SurveyImalat> parseSurveyImport({
  required String fileName,
  required List<int> bytes,
}) {
  final lower = fileName.toLowerCase();
  if (lower.contains('.') && !lower.endsWith('.xlsx')) {
    throw SurveyImportException(
      'Yalnızca .xlsx dosyası kabul edilir. $surveyImportFormatHint',
    );
  }
  return parseSurveyImportWorkbook(bytes);
}

List<SurveyImalat> parseSurveyImportWorkbook(List<int> bytes) {
  final excel = Excel.decodeBytes(bytes);
  if (excel.tables.isEmpty) {
    throw SurveyImportException(surveyImportFormatHint);
  }

  Sheet? sheet;
  for (final name in excel.tables.keys) {
    if (_normalizeToken(name) == 'kesif') {
      sheet = excel.tables[name];
      break;
    }
  }
  if (sheet == null) {
    throw SurveyImportException(
      '«Keşif» sayfası bulunamadı. $surveyImportFormatHint',
    );
  }

  final table = [
    for (final row in sheet.rows)
      [for (final cell in row) _excelCell(cell?.value)],
  ];
  return parseSurveyImportRows(table);
}

/// Test / şablon doğrulama — başlık satırı + veri satırları.
List<SurveyImalat> parseSurveyImportRows(List<List<String>> table) {
  if (table.isEmpty || table.every((row) => row.every((cell) => cell.trim().isEmpty))) {
    throw SurveyImportException(surveyImportFormatHint);
  }

  _assertHeaderRow(table.first);

  final grouped = <String, Map<int, double>>{};
  final order = <String>[];
  final seenNames = <String>{};

  for (var i = 1; i < table.length; i++) {
    final rowNumber = i + 1;
    if (table[i].every((cell) => cell.trim().isEmpty)) continue;
    final row = _paddedRow(table[i], surveyImportHeaders.length);
    _rejectExtraCells(row, rowNumber);

    final name = row.first.trim();
    final amounts = <int, double>{};
    var hasValue = false;
    for (var col = 1; col < surveyImportHeaders.length; col++) {
      final diameter = RebarWeightCalculator.standardDiameters[col - 1];
      final amount = _parseAmount(row[col], rowNumber, diameter);
      if (amount > 0) {
        amounts[diameter] = amount;
        hasValue = true;
      }
    }

    if (name.isEmpty) {
      if (hasValue) {
        throw SurveyImportException(
          'Satır $rowNumber: imalat adı boş. $surveyImportFormatHint',
        );
      }
      continue;
    }
    if (!hasValue) {
      throw SurveyImportException(
        'Satır $rowNumber: «$name» için en az bir çapta 0’dan büyük ton girin.',
      );
    }

    final folded = _foldName(name);
    if (!seenNames.add(folded)) {
      throw SurveyImportException(
        'Satır $rowNumber: «$name» dosyada birden fazla. Her imalat tek satır olmalı.',
      );
    }

    order.add(name);
    grouped[name] = amounts;
  }

  if (order.isEmpty) {
    throw SurveyImportException(
      'Dosyada imalat satırı yok. $surveyImportFormatHint',
    );
  }

  return [
    for (final name in order)
      RebarSurveyMapper.imalatFromPlanned(
        id: RebarSurveyMapper.slugifyImalatId(name),
        name: name,
        plannedByDiameter: grouped[name]!,
      ),
  ];
}

/// Gelen satırları mevcut keşfe uygular: aynı isim güncellenir, yeni eklenir.
SurveyImportMerge mergeImportedImalats({
  required List<SurveyImalat> existing,
  required List<SurveyImalat> incoming,
}) {
  final result = List<SurveyImalat>.from(existing);
  var added = 0;
  var updated = 0;
  final usedIds = {for (final imalat in existing) imalat.id};

  for (final incomingImalat in incoming) {
    final folded = _foldName(incomingImalat.name);
    final index = result.indexWhere((item) => _foldName(item.name) == folded);
    if (index >= 0) {
      final current = result[index];
      result[index] = RebarSurveyMapper.rebuildImalat(
        imalat: current.copyWith(blocks: const []),
        diameterLines: incomingImalat.diameterLines,
      );
      updated++;
      continue;
    }

    var id = incomingImalat.id;
    var suffix = 1;
    while (!usedIds.add(id)) {
      id = '${incomingImalat.id}-$suffix';
      suffix++;
    }
    result.add(incomingImalat.copyWith(id: id));
    added++;
  }

  return SurveyImportMerge(imalats: result, added: added, updated: updated);
}

void _assertHeaderRow(List<String> header) {
  final padded = _paddedRow(header, surveyImportHeaders.length);
  _rejectExtraCells(padded, 1);
  final actual = [
    for (var i = 0; i < surveyImportHeaders.length; i++)
      _normalizeToken(padded[i]),
  ];
  for (var i = 0; i < _expectedNormalizedHeaders.length; i++) {
    if (actual[i] != _expectedNormalizedHeaders[i]) {
      throw SurveyImportException(
        '1. satır başlığı şablona uymuyor '
        '(beklenen «${surveyImportHeaders[i]}», bulunan «${padded[i]}»). '
        '$surveyImportFormatHint',
      );
    }
  }
}

List<String> _paddedRow(List<String> row, int length) {
  if (row.length >= length) return row;
  return [...row, ...List<String>.filled(length - row.length, '')];
}

void _rejectExtraCells(List<String> row, int rowNumber) {
  if (row.length <= surveyImportHeaders.length) return;
  final extra = row.skip(surveyImportHeaders.length);
  if (extra.any((cell) => cell.trim().isNotEmpty)) {
    throw SurveyImportException(
      'Satır $rowNumber: fazla sütun var. $surveyImportFormatHint',
    );
  }
}

List<CellValue> _imalatTemplateRow(SurveyImalat imalat) {
  final byDiameter = {
    for (final line in imalat.diameterLines) line.diameter: line.planned,
  };
  return [
    TextCellValue(imalat.name),
    for (final diameter in RebarWeightCalculator.standardDiameters)
      _numericCell(byDiameter[diameter] ?? 0),
  ];
}

CellValue _numericCell(double value) {
  if (value == 0) return TextCellValue('');
  if (value == value.roundToDouble()) {
    return IntCellValue(value.round());
  }
  return DoubleCellValue(value);
}

String _excelCell(CellValue? value) {
  return switch (value) {
    null => '',
    TextCellValue(:final value) => value.toString(),
    IntCellValue(:final value) => value.toString(),
    DoubleCellValue(:final value) => value.toString(),
    _ => value.toString(),
  };
}

double _parseAmount(String raw, int rowNumber, int diameter) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return 0;
  final cleaned = trimmed
      .toLowerCase()
      .replaceAll('ton', '')
      .replaceAll(' ', '')
      .replaceAll(',', '.');
  final amount = double.tryParse(cleaned);
  if (amount == null) {
    throw SurveyImportException(
      'Satır $rowNumber Ø$diameter: sayı okunamadı («$raw»). '
      '$surveyImportFormatHint',
    );
  }
  if (amount < 0) {
    throw SurveyImportException(
      'Satır $rowNumber Ø$diameter: negatif ton kabul edilmez.',
    );
  }
  return amount;
}

String _normalizeToken(String raw) {
  return _foldName(raw).replaceAll(RegExp(r'[^a-z0-9]'), '');
}

String _foldName(String raw) {
  const map = {
    'ş': 's',
    'Ş': 's',
    'ı': 'i',
    'I': 'i',
    'İ': 'i',
    'i': 'i',
    'ö': 'o',
    'Ö': 'o',
    'ü': 'u',
    'Ü': 'u',
    'ğ': 'g',
    'Ğ': 'g',
    'ç': 'c',
    'Ç': 'c',
  };
  final buffer = StringBuffer();
  for (final rune in raw.trim().runes) {
    final char = String.fromCharCode(rune);
    buffer.write(map[char] ?? char.toLowerCase());
  }
  return buffer.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
}

const _surveyImportRulesLines = [
  'ŞantiJET DEMİR — Keşif Excel şablonu',
  '',
  'Keşif sayfasını bu kurallara göre doldurun, sonra uygulamada İçe Aktar ile yükleyin.',
  '',
  '1. Sayfa adı: Keşif',
  '2. 1. satır başlıkları değişmez: İmalat, Ø8, Ø10, Ø12, Ø14, Ø16, Ø18, Ø20, Ø22, Ø25, Ø28, Ø32',
  '3. Sütun eklemeyin, silmeyin veya yerini değiştirmeyin',
  '4. Her satır bir imalattır; A sütunu imalat adıdır',
  '5. Çap hücreleri ton cinsinden sayıdır (örnek: 12,5). Boş hücre = 0',
  '6. Her imalatta en az bir çap 0’dan büyük olmalıdır',
  '7. Negatif sayı yok',
  '8. Yalnız standart çaplar: 8, 10, 12, 14, 16, 18, 20, 22, 25, 28, 32',
  '9. Aynı imalat adı ikinci kez yazılmaz',
  '10. Kurallar sayfası uygulamaya aktarılmaz',
];
