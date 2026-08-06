import 'dart:convert';
import 'dart:typed_data';

import 'package:excel/excel.dart';

import '../../core/utils/id_gen.dart';
import '../../domain/entities/person.dart';

/// İçe aktarılan tek satır (henüz kaydedilmemiş).
class PersonnelImportRow {
  const PersonnelImportRow({
    required this.company,
    required this.name,
    required this.profession,
    required this.team,
    required this.tc,
    required this.phone,
    required this.address,
    required this.iban,
    required this.bankName,
    required this.hireDate,
    required this.leaveDate,
  });

  final String company;
  final String name;
  final String profession;
  final String team;
  final String tc;
  final String phone;
  final String address;
  final String iban;
  final String bankName;
  final String hireDate;
  final String leaveDate;

  bool get isEmpty =>
      company.isEmpty &&
      name.isEmpty &&
      profession.isEmpty &&
      team.isEmpty &&
      tc.isEmpty &&
      phone.isEmpty &&
      address.isEmpty &&
      iban.isEmpty &&
      bankName.isEmpty &&
      hireDate.isEmpty &&
      leaveDate.isEmpty;

  /// Görünen ad: Ad Soyad öncelikli.
  String get displayName {
    if (name.isNotEmpty) return name;
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
      address: address,
      iban: iban.toUpperCase(),
      bankName: bankName,
      hireDate: hireDate,
      leaveDate: leaveDate,
      active: !left,
    );
  }
}

/// Örnek liste satırı — yüklemeden önce önizleme.
class PersonnelImportSample {
  static const headers = [
    'Firma adı',
    'Ad Soyad',
    'Meslek',
    'Ekip',
    'TC No',
    'Telefon',
    'Adres',
    'IBAN No',
    'Banka adı',
    'İşe giriş',
    'İşten çıkış',
  ];

  static const rows = [
    [
      'Örnek İnşaat A.Ş.',
      'Ali Yılmaz',
      'Usta',
      'Demir',
      '12345678901',
      '05321234567',
      'Ankara / Çankaya',
      'TR330006100519786457841326',
      'Ziraat Bankası',
      '2024-03-01',
      '',
    ],
    [
      'Örnek İnşaat A.Ş.',
      'Ayşe Demir',
      'Saha Düz İşçi',
      'Kalıp',
      '10987654321',
      '05329876543',
      'Ankara / Yenimahalle',
      '',
      '',
      '2024-06-15',
      '2025-12-31',
    ],
  ];
}

enum PersonnelImportColumn {
  company,
  name,
  profession,
  team,
  tc,
  phone,
  address,
  iban,
  bankName,
  hireDate,
  leaveDate,
}

/// Excel / CSV personel listesi içe aktarma.
class PersonnelImportService {
  static const allowedExtensions = ['xlsx', 'xls', 'csv'];

  List<PersonnelImportRow> parseBytes({
    required Uint8List bytes,
    required String fileName,
  }) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.csv')) {
      return _parseDelimited(utf8.decode(bytes, allowMalformed: true));
    }
    if (lower.endsWith('.xlsx') || lower.endsWith('.xls')) {
      return _parseExcel(bytes);
    }
    throw PersonnelImportException(
      'Desteklenen formatlar: Excel (.xlsx, .xls) veya CSV.',
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

  List<PersonnelImportRow> _parseMatrix(List<List<String>> matrix) {
    if (matrix.isEmpty) {
      throw PersonnelImportException('Dosya boş.');
    }
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
        name: cell(PersonnelImportColumn.name),
        profession: cell(PersonnelImportColumn.profession),
        team: cell(PersonnelImportColumn.team),
        tc: _normalizeTc(cell(PersonnelImportColumn.tc)),
        phone: cell(PersonnelImportColumn.phone),
        address: cell(PersonnelImportColumn.address),
        iban: _normalizeIban(cell(PersonnelImportColumn.iban)),
        bankName: cell(PersonnelImportColumn.bankName),
        hireDate: _normalizeDate(cell(PersonnelImportColumn.hireDate)),
        leaveDate: _normalizeDate(cell(PersonnelImportColumn.leaveDate)),
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
    final hasIdentity = map.containsKey(PersonnelImportColumn.name) ||
        map.containsKey(PersonnelImportColumn.tc) ||
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
    if (key.contains('adsoyad') ||
        key == 'ad' ||
        key == 'soyad' ||
        key == 'isim' ||
        key == 'name') {
      return PersonnelImportColumn.name;
    }
    if (key.contains('meslek')) return PersonnelImportColumn.profession;
    if (key.contains('ekip') || key == 'team') {
      return PersonnelImportColumn.team;
    }
    if (key == 'tc' ||
        key == 'tcno' ||
        key.contains('tckimlik') ||
        key.contains('kimlikno') ||
        key == 'tckn') {
      return PersonnelImportColumn.tc;
    }
    if (key.contains('telefon') || key == 'tel' || key == 'gsm') {
      return PersonnelImportColumn.phone;
    }
    if (key.contains('adres')) return PersonnelImportColumn.address;
    if (key.contains('iban')) return PersonnelImportColumn.iban;
    if (key.contains('banka')) return PersonnelImportColumn.bankName;
    if (key.contains('isegiris') || key.contains('giristarih')) {
      return PersonnelImportColumn.hireDate;
    }
    if (key.contains('istencikis') ||
        key.contains('cikistarih') ||
        key.contains('istenayril')) {
      return PersonnelImportColumn.leaveDate;
    }
    return null;
  }

  String _normalizeTc(String raw) {
    return raw.replaceAll(RegExp(r'\D'), '');
  }

  String _normalizeIban(String raw) {
    return raw.replaceAll(RegExp(r'\s+'), '').toUpperCase();
  }

  String _normalizeDate(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return '';
    final iso = RegExp(r'^(\d{4})-(\d{2})-(\d{2})');
    final mIso = iso.firstMatch(t);
    if (mIso != null) {
      return '${mIso[1]}-${mIso[2]}-${mIso[3]}';
    }
    final tr = RegExp(r'^(\d{1,2})[./](\d{1,2})[./](\d{4})');
    final mTr = tr.firstMatch(t);
    if (mTr != null) {
      final d = mTr[1]!.padLeft(2, '0');
      final m = mTr[2]!.padLeft(2, '0');
      final y = mTr[3]!;
      return '$y-$m-$d';
    }
    return t.length > 32 ? t.substring(0, 32) : t;
  }
}

class PersonnelImportException implements Exception {
  PersonnelImportException(this.message);
  final String message;

  @override
  String toString() => message;
}
