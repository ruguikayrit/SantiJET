import 'dart:convert';

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

const surveyImportFormatHint =
    'Kabul edilen format: Excel veya CSV. İlk satır başlıkları '
    'İmalat, Çap, Miktar (ton) olmalıdır. Çaplar 8, 10, 12, 14, 16, 18, '
    '20, 22, 25, 28 veya 32 olabilir.';

/// İmalat listesini Excel/CSV tablosundan okur. Format uymuyorsa hata verir.
List<SurveyImalat> parseSurveyImport({
  required String fileName,
  required List<int> bytes,
}) {
  final lower = fileName.toLowerCase();
  final table = lower.endsWith('.csv')
      ? _rowsFromCsv(bytes)
      : lower.endsWith('.xlsx') || lower.endsWith('.xls')
          ? _rowsFromExcel(bytes)
          : throw SurveyImportException(surveyImportFormatHint);

  if (table.isEmpty) {
    throw SurveyImportException(surveyImportFormatHint);
  }

  final header = table.first.map(_normalizeHeader).toList();
  final imalatIndex = header.indexWhere((cell) => cell == 'imalat');
  final diameterIndex = header.indexWhere((cell) => cell == 'cap');
  final amountIndex = header.indexWhere(
    (cell) => cell == 'miktar' || cell == 'ton' || cell == 'tonaj',
  );
  if (imalatIndex < 0 || diameterIndex < 0 || amountIndex < 0) {
    throw SurveyImportException(surveyImportFormatHint);
  }

  final grouped = <String, Map<int, double>>{};
  final order = <String>[];
  for (var rowIndex = 1; rowIndex < table.length; rowIndex++) {
    final row = table[rowIndex];
    if (row.every((cell) => cell.trim().isEmpty)) continue;

    final name = _cell(row, imalatIndex).trim();
    final diameter = _parseDiameter(_cell(row, diameterIndex), rowIndex + 1);
    final amount = _parseAmount(_cell(row, amountIndex), rowIndex + 1);
    if (name.isEmpty) {
      throw SurveyImportException(
        'Satır ${rowIndex + 1}: imalat adı boş. $surveyImportFormatHint',
      );
    }
    if (!RebarWeightCalculator.standardDiameters.contains(diameter)) {
      throw SurveyImportException(
        'Satır ${rowIndex + 1}: Ø$diameter kabul edilmiyor. '
        '$surveyImportFormatHint',
      );
    }
    if (amount <= 0) {
      throw SurveyImportException(
        'Satır ${rowIndex + 1}: miktar sıfırdan büyük olmalı.',
      );
    }

    final amounts = grouped.putIfAbsent(name, () {
      order.add(name);
      return <int, double>{};
    });
    amounts[diameter] = (amounts[diameter] ?? 0) + amount;
  }

  if (order.isEmpty) {
    throw SurveyImportException(
      'Dosyada imalat satırı yok. $surveyImportFormatHint',
    );
  }

  final usedIds = <String>{};
  final imalats = <SurveyImalat>[];
  for (final name in order) {
    final base = RebarSurveyMapper.slugifyImalatId(name);
    var id = base;
    var suffix = 1;
    while (!usedIds.add(id)) {
      id = '$base-$suffix';
      suffix++;
    }
    imalats.add(
      RebarSurveyMapper.imalatFromPlanned(
        id: id,
        name: name,
        plannedByDiameter: grouped[name]!,
      ),
    );
  }
  return imalats;
}

List<List<String>> _rowsFromCsv(List<int> bytes) {
  final text = utf8.decode(bytes, allowMalformed: true).replaceAll('\r\n', '\n');
  final lines = text
      .split('\n')
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .toList();
  if (lines.isEmpty) return const [];
  final delimiter = lines.first.contains(';') ? ';' : ',';
  return lines.map((line) => line.split(delimiter)).toList();
}

List<List<String>> _rowsFromExcel(List<int> bytes) {
  final excel = Excel.decodeBytes(bytes);
  if (excel.tables.isEmpty) {
    throw SurveyImportException(surveyImportFormatHint);
  }
  final sheet = excel.tables.values.first;
  return [
    for (final row in sheet.rows)
      [for (final cell in row) _excelCell(cell?.value)],
  ];
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

String _cell(List<String> row, int index) {
  if (index < 0 || index >= row.length) return '';
  return row[index];
}

String _normalizeHeader(String raw) {
  return raw
      .trim()
      .toLowerCase()
      .replaceAll('ç', 'c')
      .replaceAll('ğ', 'g')
      .replaceAll('ı', 'i')
      .replaceAll('ö', 'o')
      .replaceAll('ş', 's')
      .replaceAll('ü', 'u')
      .replaceAll(RegExp(r'[^a-z]'), '');
}

int _parseDiameter(String raw, int rowNumber) {
  final cleaned = raw.replaceAll(RegExp(r'[^0-9]'), '');
  final diameter = int.tryParse(cleaned);
  if (diameter == null) {
    throw SurveyImportException(
      'Satır $rowNumber: çap okunamadı. $surveyImportFormatHint',
    );
  }
  return diameter;
}

double _parseAmount(String raw, int rowNumber) {
  final cleaned = raw
      .trim()
      .toLowerCase()
      .replaceAll('ton', '')
      .replaceAll('t', '')
      .replaceAll(' ', '')
      .replaceAll(',', '.');
  final amount = double.tryParse(cleaned);
  if (amount == null) {
    throw SurveyImportException(
      'Satır $rowNumber: miktar okunamadı. $surveyImportFormatHint',
    );
  }
  return amount;
}
