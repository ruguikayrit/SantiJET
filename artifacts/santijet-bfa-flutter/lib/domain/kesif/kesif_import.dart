import '../../core/utils/tr_search.dart';
import '../entities/poz_analiz.dart';
import '../enums/app_enums.dart';

class KesifImportRow {
  const KesifImportRow({
    required this.pozNo,
    required this.analizAdi,
    required this.olcuBirimi,
    required this.miktar,
    this.birimFiyati,
    this.projeAdi,
    this.aciklama,
  });

  final String pozNo;
  final String analizAdi;
  final String olcuBirimi;
  final double miktar;
  final double? birimFiyati;
  final String? projeAdi;
  final String? aciklama;

  KesifImportRow copyWith({
    String? pozNo,
    String? analizAdi,
    String? olcuBirimi,
    double? miktar,
    double? birimFiyati,
    String? projeAdi,
    String? aciklama,
  }) {
    return KesifImportRow(
      pozNo: pozNo ?? this.pozNo,
      analizAdi: analizAdi ?? this.analizAdi,
      olcuBirimi: olcuBirimi ?? this.olcuBirimi,
      miktar: miktar ?? this.miktar,
      birimFiyati: birimFiyati ?? this.birimFiyati,
      projeAdi: projeAdi ?? this.projeAdi,
      aciklama: aciklama ?? this.aciklama,
    );
  }
}

class KesifImportParseResult {
  const KesifImportParseResult({
    required this.rows,
    required this.errors,
    required this.sourceLabel,
    this.projectName,
    this.projectAciklama,
  });

  final List<KesifImportRow> rows;
  final List<String> errors;
  final String sourceLabel;
  final String? projectName;
  final String? projectAciklama;
}

enum KesifImportValidationStatus { matched, pozTypo, bothMissing }

class ValidatedImportRow {
  const ValidatedImportRow({
    required this.row,
    required this.status,
    required this.pozNoInCatalog,
    required this.tanimInCatalog,
    this.analiz,
    this.suggestedAnaliz,
  });

  final KesifImportRow row;
  final KesifImportValidationStatus status;
  final bool pozNoInCatalog;
  final bool tanimInCatalog;
  final PozAnaliz? analiz;
  final PozAnaliz? suggestedAnaliz;
}

class KesifImportValidationResult {
  const KesifImportValidationResult({
    required this.matched,
    required this.pozTypo,
    required this.bothMissing,
  });

  final List<ValidatedImportRow> matched;
  final List<ValidatedImportRow> pozTypo;
  final List<ValidatedImportRow> bothMissing;
}

class KesifImportResolvedRow {
  const KesifImportResolvedRow({required this.row, required this.analiz});

  final KesifImportRow row;
  final PozAnaliz analiz;
}

const _headerAliases = <String, String>{
  '#': 'sira',
  'sira': 'sira',
  'sıra': 'sira',
  'no': 'sira',
  'poz no': 'pozNo',
  'poz': 'pozNo',
  'poz no.': 'pozNo',
  'pozno': 'pozNo',
  'poz_kodu': 'pozNo',
  'poz kodu': 'pozNo',
  'poz numarası': 'pozNo',
  'poz numarasi': 'pozNo',
  'tanim': 'analizAdi',
  'tanım': 'analizAdi',
  'aciklama': 'analizAdi',
  'açıklama': 'analizAdi',
  'analiz adi': 'analizAdi',
  'analiz adı': 'analizAdi',
  'kalem aciklama': 'analizAdi',
  'kalem açıklama': 'analizAdi',
  'kalem_aciklama': 'analizAdi',
  'description': 'analizAdi',
  'imalat': 'analizAdi',
  'birim': 'olcuBirimi',
  'unit': 'olcuBirimi',
  'ölçü birimi': 'olcuBirimi',
  'olcu birimi': 'olcuBirimi',
  'miktar': 'miktar',
  'metraj': 'miktar',
  'quantity': 'miktar',
  'qty': 'miktar',
  'birim fiyat': 'birimFiyati',
  'birim fiyat (tl)': 'birimFiyati',
  'birim fiyati (tl)': 'birimFiyati',
  'birim fiyatı (tl)': 'birimFiyati',
  'birim fiyati': 'birimFiyati',
  'birim fiyatı': 'birimFiyati',
  'unit price': 'birimFiyati',
  'bf': 'birimFiyati',
  'proje': 'projeAdi',
  'proje adi': 'projeAdi',
  'proje adı': 'projeAdi',
  'project': 'projeAdi',
  'not': 'aciklama',
  'notlar': 'aciklama',
  'proje aciklama': 'aciklama',
  'proje açıklama': 'aciklama',
};

const _skipRowMarkers = [
  'genel toplam',
  'toplam',
  'metraj / keşif',
  'metraj / kesif',
  'metraj / keşif cetveli',
  'metraj / kesif cetveli',
  'henüz poz',
];

const _metadataRowPrefixes = [
  'proje:',
  'proje ',
  'tarih:',
  'tarih ',
  'poz say',
  'açıklama:',
  'aciklama:',
];

String normalizeImportPozNo(String pozNo) {
  final trimmed = pozNo.trim();
  if (RegExp(r'^\d{2}\.\d{3}\.\d{4}$').hasMatch(trimmed)) return trimmed;
  final digits = trimmed.replaceAll(RegExp(r'\D'), '');
  if (digits.length >= 9) {
    return '${digits.substring(0, 2)}.${digits.substring(2, 5)}.${digits.substring(5, 9)}';
  }
  return trimmed;
}

AnalizDiscipline inferDisciplineFromPoz(String pozNo) {
  final digits = pozNo.replaceAll(RegExp(r'\D'), '');
  final prefix = digits.length >= 2 ? digits.substring(0, 2) : '';
  if (prefix == '35') return AnalizDiscipline.elektrik;
  if (prefix == '25') return AnalizDiscipline.mekanik;
  return AnalizDiscipline.insaat;
}

String normalizeImportTanim(String tanim) =>
    TrSearch.normalize(tanim).replaceAll(RegExp(r'\s+'), ' ').trim();

String _cellText(Object? value) {
  if (value == null) return '';
  return value.toString().trim();
}

String? _normalizeHeader(Object? value) {
  final text = _cellText(value).toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  return _headerAliases[text];
}

int _scoreHeaderMap(List<String?> headerMap) {
  final keys = headerMap.whereType<String>().toSet();
  var score = keys.length;
  if (keys.contains('pozNo')) score += 3;
  if (keys.contains('miktar')) score += 2;
  if (keys.contains('analizAdi')) score += 2;
  if (keys.contains('olcuBirimi')) score += 1;
  if (keys.contains('birimFiyati')) score += 1;
  return score;
}

int _findHeaderRowIndex(List<List<Object?>> matrix) {
  final scanLimit = matrix.length < 30 ? matrix.length : 30;
  var bestIdx = -1;
  var bestScore = 0;
  for (var i = 0; i < scanLimit; i++) {
    final headerMap = matrix[i].map(_normalizeHeader).toList();
    final keys = headerMap.whereType<String>().toSet();
    if (!keys.contains('pozNo')) continue;
    if (!keys.contains('miktar') && !keys.contains('analizAdi')) continue;
    final score = _scoreHeaderMap(headerMap);
    if (score > bestScore) {
      bestScore = score;
      bestIdx = i;
    }
  }
  return bestIdx;
}

({String? projectName, String? projectAciklama}) _extractMetadataBeforeHeader(
  List<List<Object?>> matrix,
  int headerIdx,
) {
  String? projectName;
  String? projectAciklama;
  for (var i = 0; i < headerIdx; i++) {
    final line = matrix[i].map(_cellText).toList();
    final joined = line.join(' ').trim();
    if (joined.isEmpty) continue;
    final first = line.isNotEmpty ? line.first : '';
    final lower = TrSearch.normalize(first);
    if (lower.startsWith('proje:') || lower.startsWith('proje ')) {
      final fromCell = first.replaceFirst(RegExp(r'^proje\s*:\s*', caseSensitive: false), '').trim();
      projectName = fromCell.isNotEmpty
          ? fromCell
          : line.skip(1).firstWhere((s) => s.isNotEmpty, orElse: () => projectName ?? '');
    }
    if ((lower.startsWith('açıklama:') || lower.startsWith('aciklama:')) &&
        projectAciklama == null) {
      projectAciklama = first
          .replaceFirst(RegExp(r'^açıklama\s*:\s*', caseSensitive: false), '')
          .replaceFirst(RegExp(r'^aciklama\s*:\s*', caseSensitive: false), '')
          .trim();
    }
  }
  return (projectName: projectName, projectAciklama: projectAciklama);
}

bool _isMetadataRow(List<String> values) {
  final first = TrSearch.normalize(values.isNotEmpty ? values.first : '');
  if (first.isEmpty) return false;
  return _metadataRowPrefixes
      .any((prefix) => first.startsWith(TrSearch.normalize(prefix)));
}

bool _isLikelyHeaderDataRow(String pozNo, String analizAdi) {
  final p = TrSearch.normalize(pozNo);
  final a = TrSearch.normalize(analizAdi);
  return p == 'poz no' ||
      p == 'poz' ||
      p == '#' ||
      a == 'tanim' ||
      a == 'tanım' ||
      a == 'miktar' ||
      a == 'birim' ||
      p == 'miktar' ||
      p == 'birim';
}

double _parseNumber(Object? value) {
  if (value is num && value.isFinite) return value.toDouble();
  final text = _cellText(value)
      .replaceAll(' ', '')
      .replaceAll('₺', '')
      .replaceAll('.', '')
      .replaceAll(',', '.');
  return double.tryParse(text) ?? 0;
}

bool _shouldSkipRow(List<String> values) {
  final joined = values.join(' ').trim();
  if (joined.isEmpty) return true;
  if (_isMetadataRow(values)) return true;
  final lower = TrSearch.normalize(joined);
  return _skipRowMarkers.any(lower.contains);
}

KesifImportParseResult mapMatrixToRows(
  List<List<Object?>> matrix,
  String sourceLabel,
) {
  final errors = <String>[];
  final rows = <KesifImportRow>[];
  if (matrix.isEmpty) {
    return KesifImportParseResult(
      rows: rows,
      errors: const ['Dosyada veri bulunamadı.'],
      sourceLabel: sourceLabel,
    );
  }

  final headerIdx = _findHeaderRowIndex(matrix);
  late List<String?> headerMap;
  late int startIdx;

  if (headerIdx >= 0) {
    headerMap = matrix[headerIdx].map(_normalizeHeader).toList();
    startIdx = headerIdx + 1;
  } else {
    final firstRow = matrix.first.map(_cellText).toList();
    final normalizedHeaders = firstRow.map(_normalizeHeader).toList();
    if (normalizedHeaders.any((h) => h != null && h != 'sira')) {
      headerMap = normalizedHeaders;
      startIdx = 1;
    } else {
      headerMap = const [
        'sira',
        'pozNo',
        'analizAdi',
        'olcuBirimi',
        'miktar',
        'birimFiyati',
        'sira',
      ];
      startIdx = 0;
    }
  }

  final metaFromSheet = headerIdx >= 0
      ? _extractMetadataBeforeHeader(matrix, headerIdx)
      : (projectName: null, projectAciklama: null);
  var projectName = metaFromSheet.projectName;
  var projectAciklama = metaFromSheet.projectAciklama;

  for (var i = startIdx; i < matrix.length; i++) {
    final rawLine = matrix[i];
    final line = rawLine.map(_cellText).toList();
    if (_shouldSkipRow(line)) continue;

    String get(String key) {
      final idx = headerMap.indexOf(key);
      if (idx < 0) return '';
      return _cellText(rawLine[idx]);
    }

    final pozNo = get('pozNo');
    final analizAdi = get('analizAdi');
    if (_isLikelyHeaderDataRow(pozNo, analizAdi)) continue;

    final olcuBirimi = get('olcuBirimi').isEmpty ? 'Ad' : get('olcuBirimi');
    final miktarRaw = headerMap.contains('miktar')
        ? rawLine[headerMap.indexOf('miktar')]
        : get('miktar');
    final miktar = _parseNumber(miktarRaw);
    final birimFiyatiRaw = get('birimFiyati');
    final birimFiyati =
        birimFiyatiRaw.isEmpty ? null : _parseNumber(birimFiyatiRaw);
    final projeAdi = get('projeAdi');
    final aciklama = get('aciklama');

    if (pozNo.isEmpty && analizAdi.isEmpty) continue;

    if (projeAdi.isNotEmpty && (projectName == null || projectName.isEmpty)) {
      projectName = projeAdi;
    }
    if (aciklama.isNotEmpty &&
        (projectAciklama == null || projectAciklama.isEmpty)) {
      projectAciklama = aciklama;
    }

    rows.add(
      KesifImportRow(
        pozNo: pozNo.isEmpty ? 'ÖZEL' : pozNo,
        analizAdi: analizAdi.isEmpty ? pozNo : analizAdi,
        olcuBirimi: olcuBirimi,
        miktar: miktar,
        birimFiyati: birimFiyati,
        projeAdi: projeAdi.isEmpty ? null : projeAdi,
        aciklama: aciklama.isEmpty ? null : aciklama,
      ),
    );
  }

  if (rows.isEmpty && errors.isEmpty) {
    errors.add('İçe aktarılabilir satır bulunamadı.');
  }

  return KesifImportParseResult(
    rows: rows,
    projectName: projectName,
    projectAciklama: projectAciklama,
    errors: errors,
    sourceLabel: sourceLabel,
  );
}

List<List<Object?>> parseCsvMatrix(String content) {
  final lines = content.split(RegExp(r'\r?\n')).where((l) => l.trim().isNotEmpty);
  String detectSep(String line) {
    if (line.contains(';')) return ';';
    if (line.contains('\t')) return '\t';
    return ',';
  }

  final result = <List<Object?>>[];
  for (final line in lines) {
    final sep = detectSep(line);
    final cells = <String>[];
    var cur = '';
    var inQuotes = false;
    for (var i = 0; i < line.length; i++) {
      final ch = line[i];
      if (ch == '"') {
        if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
          cur += '"';
          i++;
        } else {
          inQuotes = !inQuotes;
        }
      } else if (ch == sep && !inQuotes) {
        cells.add(cur);
        cur = '';
      } else {
        cur += ch;
      }
    }
    cells.add(cur);
    result.add(cells);
  }
  return result;
}

List<List<Object?>> parseHtmlTableRows(String html) {
  final rows = <List<Object?>>[];
  final trRegex = RegExp(r'<tr[^>]*>([\s\S]*?)</tr>', caseSensitive: false);
  final cellRegex = RegExp(r'<t[dh][^>]*>([\s\S]*?)</t[dh]>', caseSensitive: false);
  for (final trMatch in trRegex.allMatches(html)) {
    final cells = <String>[];
    for (final cellMatch in cellRegex.allMatches(trMatch.group(1)!)) {
      var text = cellMatch.group(1)!;
      text = text.replaceAll(RegExp(r'<[^>]+>'), ' ');
      text = text
          .replaceAll('&nbsp;', ' ')
          .replaceAll('&amp;', '&')
          .replaceAll('&lt;', '<')
          .replaceAll('&gt;', '>');
      text = text.replaceAll(RegExp(r'\s+'), ' ').trim();
      cells.add(text);
    }
    if (cells.isNotEmpty) rows.add(cells);
  }
  return rows;
}

Map<String, PozAnaliz> buildCatalogPozIndex(List<PozAnaliz> catalog) {
  return {for (final a in catalog) normalizeImportPozNo(a.pozNo): a};
}

Map<String, List<PozAnaliz>> buildCatalogTanimIndex(List<PozAnaliz> catalog) {
  final byTanim = <String, List<PozAnaliz>>{};
  for (final analiz in catalog) {
    final key = normalizeImportTanim(analiz.analizAdi);
    if (key.isEmpty) continue;
    byTanim.putIfAbsent(key, () => []).add(analiz);
  }
  return byTanim;
}

List<PozAnaliz> findCatalogByTanim(String tanim, List<PozAnaliz> catalog) {
  final key = normalizeImportTanim(tanim);
  if (key.isEmpty) return const [];

  final byTanim = buildCatalogTanimIndex(catalog);
  final exact = byTanim[key];
  if (exact != null && exact.isNotEmpty) return exact;

  if (key.length < 40) return const [];

  return catalog.where((analiz) {
    final catalogKey = normalizeImportTanim(analiz.analizAdi);
    return catalogKey.startsWith(key) || key.startsWith(catalogKey);
  }).toList();
}

PozAnaliz _pickBestTanimMatch(KesifImportRow row, List<PozAnaliz> candidates) {
  if (candidates.length == 1) return candidates.first;
  final inferred = inferDisciplineFromPoz(row.pozNo);
  final sameDiscipline =
      candidates.where((a) => (a.discipline ?? AnalizDiscipline.insaat) == inferred);
  if (sameDiscipline.length == 1) return sameDiscipline.first;
  if (sameDiscipline.isNotEmpty) return sameDiscipline.first;
  return candidates.first;
}

KesifImportValidationResult validateImportRows(
  List<KesifImportRow> rows,
  List<PozAnaliz> catalog,
) {
  final byPoz = buildCatalogPozIndex(catalog);
  final matched = <ValidatedImportRow>[];
  final pozTypo = <ValidatedImportRow>[];
  final bothMissing = <ValidatedImportRow>[];

  for (final row in rows) {
    final pozNoInCatalog = byPoz.containsKey(normalizeImportPozNo(row.pozNo));
    final tanimMatches = findCatalogByTanim(row.analizAdi, catalog);
    final tanimInCatalog = tanimMatches.isNotEmpty;

    if (pozNoInCatalog) {
      matched.add(
        ValidatedImportRow(
          row: row,
          status: KesifImportValidationStatus.matched,
          analiz: byPoz[normalizeImportPozNo(row.pozNo)],
          pozNoInCatalog: true,
          tanimInCatalog: tanimInCatalog,
        ),
      );
      continue;
    }

    if (tanimInCatalog) {
      pozTypo.add(
        ValidatedImportRow(
          row: row,
          status: KesifImportValidationStatus.pozTypo,
          suggestedAnaliz: _pickBestTanimMatch(row, tanimMatches),
          pozNoInCatalog: false,
          tanimInCatalog: true,
        ),
      );
      continue;
    }

    bothMissing.add(
      ValidatedImportRow(
        row: row,
        status: KesifImportValidationStatus.bothMissing,
        pozNoInCatalog: false,
        tanimInCatalog: false,
      ),
    );
  }

  return KesifImportValidationResult(
    matched: matched,
    pozTypo: pozTypo,
    bothMissing: bothMissing,
  );
}

List<KesifImportResolvedRow> resolveTypoImportRows(
  List<ValidatedImportRow> pozTypo,
) {
  return pozTypo
      .where((item) => item.suggestedAnaliz != null)
      .map(
        (item) => KesifImportResolvedRow(
          row: item.row.copyWith(pozNo: item.suggestedAnaliz!.pozNo),
          analiz: item.suggestedAnaliz!,
        ),
      )
      .toList();
}

List<KesifImportResolvedRow> validationToResolved(
  KesifImportValidationResult validation,
) {
  return validation.matched
      .where((item) => item.analiz != null)
      .map((item) => KesifImportResolvedRow(row: item.row, analiz: item.analiz!))
      .toList();
}

List<KesifImportRow> mergeImportRowsByPoz(List<KesifImportRow> rows) {
  final map = <String, KesifImportRow>{};
  for (final row in rows) {
    final key =
        '${normalizeImportPozNo(row.pozNo)}|${TrSearch.normalize(row.analizAdi)}';
    final existing = map[key];
    if (existing == null) {
      map[key] = row;
      continue;
    }
    map[key] = existing.copyWith(
      miktar: existing.miktar + row.miktar,
      birimFiyati: existing.birimFiyati ?? row.birimFiyati,
    );
  }
  return map.values.toList();
}

String defaultImportProjectName(String fileName, KesifImportParseResult? parsed) {
  if (parsed?.projectName?.trim().isNotEmpty == true) {
    return parsed!.projectName!.trim();
  }
  final base = fileName.replaceAll(RegExp(r'\.[^.]+$'), '').replaceAll(RegExp(r'[_-]+'), ' ').trim();
  return base.isEmpty ? 'İçe Aktarılan Keşif' : base;
}

String truncateImportText(String text, [int max = 72]) {
  final trimmed = text.trim();
  if (trimmed.length <= max) return trimmed;
  return '${trimmed.substring(0, max - 1)}…';
}

PozAnaliz buildCatalogAnalizFromImportRow(KesifImportRow row) {
  final pozNo = normalizeImportPozNo(row.pozNo);
  final normalizedPoz = pozNo.isEmpty ? row.pozNo.trim() : pozNo;
  final discipline = inferDisciplineFromPoz(normalizedPoz);
  final birimFiyati = row.birimFiyati != null && row.birimFiyati! > 0
      ? row.birimFiyati!
      : 0.0;

  return PozAnaliz(
    id: '',
    pozNo: normalizedPoz.isEmpty ? 'ÖZEL' : normalizedPoz,
    analizAdi: row.analizAdi.trim().isEmpty ? normalizedPoz : row.analizAdi.trim(),
    olcuBirimi: row.olcuBirimi.trim().isEmpty ? 'Ad' : row.olcuBirimi.trim(),
    kategori: discipline == AnalizDiscipline.elektrik
        ? 'Elektrik'
        : discipline == AnalizDiscipline.mekanik
            ? 'Mekanik Tesisat'
            : 'Diğer',
    kalemler: const [],
    malzemeIscilikToplami: birimFiyati,
    yukleniciKarOrani: 25,
    birimFiyati: birimFiyati,
    kaynakTip: KaynakTip.kullanici,
    discipline: discipline,
    notlar: 'Keşif içe aktarma ile oluşturuldu.',
  );
}
