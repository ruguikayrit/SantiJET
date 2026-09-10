import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:santijet_is_programi/data/interop/program_excel_codec.dart';
import 'package:santijet_is_programi/data/interop/program_interop.dart';
import 'package:santijet_is_programi/domain/program_item.dart';

const codec = ProgramExcelCodec();
final today = DateTime(2026, 3, 10);

final sample = <ProgramItem>[
  ProgramItem(
    id: 'a1',
    santiyeId: 'Merkez Şantiyesi',
    name: 'Hafriyat',
    startDate: DateTime(2026, 3, 2),
    endDate: DateTime(2026, 3, 11),
    progress: 100,
    status: ProgramStatus.completed,
    responsible: 'Saha Ekibi',
    notes: 'Kot kontrolü yapıldı.',
    wbs: '1.1',
  ),
  ProgramItem(
    id: 'a2',
    santiyeId: 'Merkez Şantiyesi',
    name: 'Radye donatısı',
    startDate: DateTime(2026, 3, 12),
    endDate: DateTime(2026, 3, 21),
    progress: 40,
    status: ProgramStatus.inProgress,
    responsible: 'Ahmet Usta',
    wbs: '1.2',
    predecessors: '2FS+1 gün',
  ),
];

String? cell(Sheet sheet, int column, int row) {
  final value = sheet
      .cell(CellIndex.indexByColumnRow(columnIndex: column, rowIndex: row))
      .value;
  if (value is TextCellValue) return value.value.text;
  if (value is IntCellValue) return '${value.value}';
  return value?.toString();
}

void main() {
  group('Excel yazımı', () {
    test('sayfa adı ve başlıklar Project alan adlarıyla yazılır', () {
      final book = Excel.decodeBytes(codec.encode(sample, today: today));
      expect(book.tables.keys, contains('Task_Table'));

      final sheet = book.tables['Task_Table']!;
      final header = [
        for (var column = 0; column < 15; column++) cell(sheet, column, 0),
      ];
      expect(header, [
        'ID',
        'Name',
        'Duration',
        'Start',
        'Finish',
        '% Complete',
        'Resource Names',
        'Predecessors',
        'Outline Level',
        'WBS',
        'Milestone',
        'Text1',
        'Text2',
        'Notes',
        'Number1',
      ]);
    });

    test('satırlar başlık düzeniyle hizalı yazılır', () {
      final sheet = Excel.decodeBytes(
        codec.encode(sample, today: today),
      ).tables['Task_Table']!;

      expect(cell(sheet, 1, 1), 'Hafriyat');
      expect(cell(sheet, 2, 1), '10');
      expect(cell(sheet, 5, 1), '100');
      expect(cell(sheet, 6, 1), 'Saha Ekibi');
      expect(cell(sheet, 9, 1), '1.1');
      expect(cell(sheet, 11, 1), 'Tamamlandı');
      expect(cell(sheet, 12, 1), 'Merkez Şantiyesi');
      expect(cell(sheet, 13, 1), 'Kot kontrolü yapıldı.');
    });

    test('özet sayfası eklenir', () {
      final book = Excel.decodeBytes(codec.encode(sample, today: today));
      expect(book.tables.keys, contains('Ozet'));
      expect(cell(book.tables['Ozet']!, 1, 1), '2');
    });
  });

  group('Excel okuması', () {
    test('yazılan dosya kayıpsız geri okunur', () {
      final decoded = codec.decode(
        codec.encode(sample, today: today),
        fallbackSite: 'Varsayılan',
        today: today,
      );

      expect(decoded.items, hasLength(2));
      final hafriyat = decoded.items.first;
      expect(hafriyat.name, 'Hafriyat');
      expect(hafriyat.santiyeId, 'Merkez Şantiyesi');
      expect(hafriyat.startDate, DateTime(2026, 3, 2));
      expect(hafriyat.endDate, DateTime(2026, 3, 11));
      expect(hafriyat.calculatedDays, 10);
      expect(hafriyat.progress, 100);
      expect(hafriyat.status, ProgramStatus.completed);
      expect(hafriyat.responsible, 'Saha Ekibi');
      expect(hafriyat.notes, 'Kot kontrolü yapıldı.');
      expect(hafriyat.wbs, '1.1');

      final radye = decoded.items.last;
      expect(radye.predecessors, '2FS+1 gün');
      expect(radye.status, ProgramStatus.inProgress);
    });

    test('Türkçe başlıklı ve sütun sırası farklı dosya okunur', () {
      final decoded = codec.decode(
        _turkishSheet(),
        fallbackSite: 'Varsayılan Şantiye',
        today: today,
      );

      expect(decoded.items, hasLength(2));
      final first = decoded.items.first;
      expect(first.name, 'Kalıp sökümü');
      expect(first.startDate, DateTime(2026, 3, 4));
      expect(first.endDate, DateTime(2026, 3, 9));
      expect(first.progress, 45);
      expect(first.responsible, 'Kalıp Ekibi');
      // Şantiye sütunu olmadığı için etkin şantiye kullanılır.
      expect(first.santiyeId, 'Varsayılan Şantiye');
    });

    test('bitişi olmayan satır süreden hesaplanır ve uyarı üretir', () {
      final decoded = codec.decode(
        _turkishSheet(),
        fallbackSite: 'Varsayılan Şantiye',
        today: today,
      );
      final second = decoded.items.last;
      expect(second.name, 'Tesisat kaba işi');
      expect(second.startDate, DateTime(2026, 3, 10));
      // 4 günlük süre, bitiş dahil.
      expect(second.endDate, DateTime(2026, 3, 13));
      expect(decoded.warnings, isNotEmpty);
    });

    test('ad sütunu olmayan dosya anlaşılır hatayla reddedilir', () {
      final book = Excel.createExcel();
      final sheet = book[book.getDefaultSheet()!];
      sheet
              .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0))
              .value =
          TextCellValue('Bir Şey');
      sheet
              .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1))
              .value =
          TextCellValue('Değer');

      expect(
        () => codec.decode(
          Uint8List.fromList(book.encode()!),
          fallbackSite: 'Varsayılan',
        ),
        throwsA(isA<ProgramImportException>()),
      );
    });
  });
}

/// Elle hazırlanmış, Türkçe başlıklı ve sütun sırası farklı bir sayfa.
Uint8List _turkishSheet() {
  final book = Excel.createExcel();
  book.rename(book.getDefaultSheet()!, 'Program');
  final sheet = book['Program'];

  void write(int column, int row, CellValue value) => sheet
      .cell(CellIndex.indexByColumnRow(columnIndex: column, rowIndex: row))
      .value = value;

  const header = [
    'Sorumlu',
    'Faaliyet Adı',
    'Başlangıç Tarihi',
    'Bitiş Tarihi',
    'İlerleme',
    'Süre',
  ];
  for (var column = 0; column < header.length; column++) {
    write(column, 0, TextCellValue(header[column]));
  }

  write(0, 1, TextCellValue('Kalıp Ekibi'));
  write(1, 1, TextCellValue('Kalıp sökümü'));
  write(2, 1, TextCellValue('04.03.2026'));
  write(3, 1, TextCellValue('09.03.2026'));
  write(4, 1, TextCellValue('%45'));
  write(5, 1, IntCellValue(6));

  write(0, 2, TextCellValue('Tesisat Ekibi'));
  write(1, 2, TextCellValue('Tesisat kaba işi'));
  write(2, 2, TextCellValue('10.03.2026'));
  write(4, 2, TextCellValue('0'));
  write(5, 2, IntCellValue(4));

  return Uint8List.fromList(book.encode()!);
}
