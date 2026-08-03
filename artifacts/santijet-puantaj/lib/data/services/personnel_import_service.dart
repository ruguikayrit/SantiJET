import 'dart:convert';
import 'dart:typed_data';

import 'package:excel/excel.dart';

import '../../core/utils/id_gen.dart';
import '../../domain/entities/person.dart';

/// İçe aktarılan tek satır (henüz kaydedilmemiş).
class PersonnelImportRow {
  const PersonnelImportRow({
    required this.company,
    required this.profession,
    required this.team,
    required this.tc,
    required this.phone,
    required this.hireDate,
    required this.leaveDate,
    required this.address,
  });

  final String company;
  final String profession;
  final String team;
  final String tc;
  final String phone;
  final String hireDate;
  final String leaveDate;
  final String address;

  bool get isEmpty =>
      company.isEmpty &&
      profession.isEmpty &&
      team.isEmpty &&
      tc.isEmpty &&
      phone.isEmpty &&
      hireDate.isEmpty &&
      leaveDate.isEmpty &&
      address.isEmpty;

  /// Görünen ad: TC varsa TC, yoksa telefon / firma.
  String get displayName {
    if (tc.isNotEmpty) return tc;
    if (phone.isNotEmpty) return phone;
    if (company.isNotEmpty) return company;
    return 'Personel';
  }

  Person toPerson(String projectId) {
    final left = leaveDate.trim().isNotEmpty;
    return Person(
      id: IdGen.make('per'),
      projectId: projectId,
      name: displayName,
      company: company,
      profession: profession,
      team: team,
      tc: tc,
      phone: phone,
      hireDate: hireDate,
      leaveDate: leaveDate,
      address: address,
      active: !left,
    );
  }
}

/// Örnek liste satırı — yüklemeden önce önizleme.
class PersonnelImportSample {
  static const headers = [
    'Firma adı',
    'Meslek',
    'Ekip',
    'TC',
    'Telefon',
    'İşe giriş',
    'İşten çıkış',
    'Adres',
  ];

  static const rows = [
    [
      'Örnek İnşaat A.Ş.',
      'Usta',
      'Demir',
      '12345678901',
      '05321234567',
      '2024-03-01',
      '',
      'Ankara / Çankaya',
    ],
    [
      'Örnek İnşaat A.Ş.',
      'Saha Düz İşçi',
      'Kalıp',
      '10987654321',
      '05329876543',
      '2024-06-15',
      '2025-12-31',
      'Ankara / Yenimahalle',
    ],
  ];
}

enum PersonnelImportColumn {
  company,
  profession,
  team,
  tc,
  phone,
  hireDate,
  leaveDate,
  address,
}

/// Excel / CSV / PDF personel listesi içe aktarma.
class PersonnelImportService {
  static const allowedExtensions = ['xlsx', 'xls', 'csv', 'pdf'];

  List<PersonnelImportRow> parseBytes({
    required Uint8List bytes,
    required String fileName,
  }) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.csv')) {
      return _parseDelimited(utf8.decode(bytes, allowMalformed: true));
    }
    if (lower.endsWith('.pdf')) {
      return _parsePdf(bytes);
    }
    if (lower.endsWith('.xlsx') || lower.endsWith('.xls')) {
      return _parseExcel(bytes);
    }
    throw PersonnelImportException(
      'Desteklenen formatlar: Excel (.xlsx), CSV, PDF.',
    );
  }

  List<PersonnelImportRow> _parseExcel(Uint8List bytes) {
    final book = Excel.decodeBytes(bytes);
    if (book.tables.isEmpty) {
      throw PersonnelImportException('Excel dosyasında sayfa yok.');
    }
    final sheet = book.tables.values.first;
    final matrix = <List<String>>[];
    for (final row in sheet.rows) {
      matrix.add([
        for (final cell in row) (cell?.value?.toString() ?? '').trim(),
      ]);
    }
    return _parseMatrix(matrix);
  }

  List<PersonnelImportRow> _parseDelimited(String text) {
    final lines = text
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .split('\n')
        .where((l) => l.trim().isNotEmpty)
        .toList();
    if (lines.isEmpty) {
      throw PersonnelImportException('Dosya boş.');
    }
    final sep = lines.first.contains(';') ? ';' : ',';
    final matrix = [
      for (final line in lines) _splitCsvLine(line, sep),
    ];
    return _parseMatrix(matrix);
  }

  List<String> _splitCsvLine(String line, String sep) {
    // Basit ayırıcı; tırnak içi ayırıcı desteklenir.
    final out = <String>[];
    final buf = StringBuffer();
    var inQuotes = false;
    for (var i = 0; i < line.length; i++) {
      final ch = line[i];
      if (ch == '"') {
        inQuotes = !inQuotes;
        continue;
      }
      if (!inQuotes && ch == sep) {
        out.add(buf.toString().trim());
        buf.clear();
        continue;
      }
      buf.write(ch);
    }
    out.add(buf.toString().trim());
    return out;
  }

  List<PersonnelImportRow> _parsePdf(Uint8List bytes) {
    final raw = latin1.decode(bytes, allowInvalid: true);
    final extracted = StringBuffer();
    // PDF string literals: (text) Tj / TJ
    final re = RegExp(r'\(([^)\\]*(?:\\.[^)\\]*)*)\)\s*Tj', dotAll: true);
    for (final m in re.allMatches(raw)) {
      var s = m.group(1) ?? '';
      s = s
          .replaceAll(r'\n', '\n')
          .replaceAll(r'\r', '')
          .replaceAll(r'\t', '\t')
          .replaceAll(r'\(', '(')
          .replaceAll(r'\)', ')');
      extracted.writeln(s);
    }
    // Ayrıca satır sonu ile ayrılmış düz metin blokları
    final text = extracted.toString();
    if (text.trim().isEmpty) {
      throw PersonnelImportException(
        'PDF’den tablo okunamadı. Excel (.xlsx) veya CSV yükleyin.',
      );
    }
    // Önce tab/pipe, sonra satır bazlı CSV dene
    final lines = text
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    final matrix = <List<String>>[];
    for (final line in lines) {
      if (line.contains('\t')) {
        matrix.add(line.split('\t').map((e) => e.trim()).toList());
      } else if (line.contains('|')) {
        matrix.add(
          line.split('|').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
        );
      } else if (line.contains(';')) {
        matrix.add(_splitCsvLine(line, ';'));
      } else if (line.contains(',')) {
        matrix.add(_splitCsvLine(line, ','));
      }
    }
    if (matrix.length < 2) {
      throw PersonnelImportException(
        'PDF tablo formatı tanınmadı. Excel (.xlsx) kullanın.',
      );
    }
    return _parseMatrix(matrix);
  }

  List<PersonnelImportRow> _parseMatrix(List<List<String>> matrix) {
    if (matrix.isEmpty) {
      throw PersonnelImportException('Dosya boş.');
    }
    // Başlık satırını bul
    var headerIndex = -1;
    Map<PersonnelImportColumn, int>? map;
    for (var i = 0; i < matrix.length && i < 10; i++) {
      final m = _mapHeaders(matrix[i]);
      if (m.isNotEmpty) {
        headerIndex = i;
        map = m;
        break;
      }
    }
    if (headerIndex < 0 || map == null || map.isEmpty) {
      throw PersonnelImportException(
        'Başlık satırı bulunamadı. Beklenen sütunlar: '
        '${PersonnelImportSample.headers.join(', ')}',
      );
    }

    final rows = <PersonnelImportRow>[];
    for (var r = headerIndex + 1; r < matrix.length; r++) {
      final cells = matrix[r];
      String cell(PersonnelImportColumn c) {
        final idx = map![c];
        if (idx == null || idx < 0 || idx >= cells.length) return '';
        return cells[idx].trim();
      }

      final row = PersonnelImportRow(
        company: cell(PersonnelImportColumn.company),
        profession: cell(PersonnelImportColumn.profession),
        team: cell(PersonnelImportColumn.team),
        tc: _normalizeTc(cell(PersonnelImportColumn.tc)),
        phone: cell(PersonnelImportColumn.phone),
        hireDate: _normalizeDate(cell(PersonnelImportColumn.hireDate)),
        leaveDate: _normalizeDate(cell(PersonnelImportColumn.leaveDate)),
        address: cell(PersonnelImportColumn.address),
      );
      if (!row.isEmpty) rows.add(row);
    }
    if (rows.isEmpty) {
      throw PersonnelImportException('İçe aktarılacak satır bulunamadı.');
    }
    return rows;
  }

  Map<PersonnelImportColumn, int> _mapHeaders(List<String> header) {
    final map = <PersonnelImportColumn, int>{};
    for (var i = 0; i < header.length; i++) {
      final key = _normHeader(header[i]);
      if (key.isEmpty) continue;
      final col = _matchColumn(key);
      if (col != null && !map.containsKey(col)) {
        map[col] = i;
      }
    }
    // En az TC veya telefon veya firma beklenir
    final hasIdentity = map.containsKey(PersonnelImportColumn.tc) ||
        map.containsKey(PersonnelImportColumn.phone) ||
        map.containsKey(PersonnelImportColumn.company);
    if (!hasIdentity) return {};
    return map;
  }

  String _normHeader(String raw) {
    return raw
        .toLowerCase()
        .replaceAll('ı', 'i')
        .replaceAll('ğ', 'g')
        .replaceAll('ü', 'u')
        .replaceAll('ş', 's')
        .replaceAll('ö', 'o')
        .replaceAll('ç', 'c')
        .replaceAll(RegExp(r'[^a-z0-9]+'), '');
  }

  PersonnelImportColumn? _matchColumn(String key) {
    // Yalnızca izin verilen sütunlar — diğerleri yok sayılır.
    if (key.contains('firma')) return PersonnelImportColumn.company;
    if (key.contains('meslek')) return PersonnelImportColumn.profession;
    if (key.contains('ekip') || key == 'team') {
      return PersonnelImportColumn.team;
    }
    if (key == 'tc' ||
        key.contains('tckimlik') ||
        key.contains('kimlikno') ||
        key == 'tckn') {
      return PersonnelImportColumn.tc;
    }
    if (key.contains('telefon') || key == 'tel' || key == 'gsm') {
      return PersonnelImportColumn.phone;
    }
    if (key.contains('isegiris') || key.contains('giristarih')) {
      return PersonnelImportColumn.hireDate;
    }
    if (key.contains('istencikis') ||
        key.contains('cikistarih') ||
        key.contains('istenayril')) {
      return PersonnelImportColumn.leaveDate;
    }
    if (key.contains('adres')) return PersonnelImportColumn.address;
    return null;
  }

  String _normalizeTc(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    return digits;
  }

  String _normalizeDate(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return '';
    // yyyy-MM-dd
    final iso = RegExp(r'^(\d{4})-(\d{2})-(\d{2})');
    final mIso = iso.firstMatch(t);
    if (mIso != null) {
      return '${mIso[1]}-${mIso[2]}-${mIso[3]}';
    }
    // dd.MM.yyyy or dd/MM/yyyy
    final tr = RegExp(r'^(\d{1,2})[./](\d{1,2})[./](\d{4})');
    final mTr = tr.firstMatch(t);
    if (mTr != null) {
      final d = mTr[1]!.padLeft(2, '0');
      final m = mTr[2]!.padLeft(2, '0');
      final y = mTr[3]!;
      return '$y-$m-$d';
    }
    // Excel serial roughly skipped — keep raw truncated
    return t.length > 32 ? t.substring(0, 32) : t;
  }
}

class PersonnelImportException implements Exception {
  PersonnelImportException(this.message);
  final String message;

  @override
  String toString() => message;
}
