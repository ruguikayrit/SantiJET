import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';

import '../../domain/kesif/kesif_import.dart';

/// Keşif Excel/CSV dosyalarını okur ve satır matrisine çevirir.
abstract final class KesifImportFileService {
  static Future<({Uint8List bytes, String name})?> pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const [
        'xlsx',
        'xls',
        'csv',
        'txt',
        'htm',
        'html',
      ],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return null;
    final file = result.files.first;
    final bytes = file.bytes;
    if (bytes == null || bytes.isEmpty) return null;
    return (bytes: bytes, name: file.name);
  }

  static KesifImportParseResult parseBytes(Uint8List bytes, String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.csv') ||
        lower.endsWith('.txt') ||
        lower.endsWith('.htm') ||
        lower.endsWith('.html')) {
      final text = utf8.decode(bytes, allowMalformed: true).trim();
      if (text.startsWith('<') && text.toLowerCase().contains('<table')) {
        return mapMatrixToRows(parseHtmlTableRows(text), fileName);
      }
      return mapMatrixToRows(parseCsvMatrix(text), fileName);
    }

    final textAttempt = utf8.decode(bytes, allowMalformed: true).trim();
    if (textAttempt.startsWith('<') &&
        textAttempt.toLowerCase().contains('<table')) {
      return mapMatrixToRows(parseHtmlTableRows(textAttempt), fileName);
    }

    try {
      final matrix = _parseXlsxBytes(bytes);
      return mapMatrixToRows(matrix, fileName);
    } catch (_) {
      if (textAttempt.isNotEmpty && !textAttempt.startsWith('PK')) {
        return mapMatrixToRows(parseCsvMatrix(textAttempt), fileName);
      }
      return KesifImportParseResult(
        rows: const [],
        errors: const ['Excel dosyası okunamadı.'],
        sourceLabel: fileName,
      );
    }
  }

  static List<List<Object?>> _parseXlsxBytes(Uint8List bytes) {
    final archive = ZipDecoder().decodeBytes(bytes);
    final sharedStrings = _readSharedStrings(archive);
    ArchiveFile? sheetFile;
    for (final file in archive.files) {
      if (file.name == 'xl/worksheets/sheet1.xml') {
        sheetFile = file;
        break;
      }
    }
    sheetFile ??= archive.files.firstWhere(
      (f) => f.name.startsWith('xl/worksheets/sheet') && f.name.endsWith('.xml'),
      orElse: () => throw FormatException('sheet missing'),
    );
    final xml = utf8.decode(sheetFile.content as List<int>, allowMalformed: true);
    return _sheetXmlToMatrix(xml, sharedStrings);
  }

  static List<String> _readSharedStrings(Archive archive) {
    final file = archive.files.where((f) => f.name == 'xl/sharedStrings.xml').toList();
    if (file.isEmpty) return const [];
    final xml = utf8.decode(file.first.content as List<int>, allowMalformed: true);
    final strings = <String>[];
    final siRegex = RegExp(r'<si>([\s\S]*?)</si>', caseSensitive: false);
    final tRegex = RegExp(r'<t[^>]*>([\s\S]*?)</t>', caseSensitive: false);
    for (final si in siRegex.allMatches(xml)) {
      final parts = <String>[];
      for (final t in tRegex.allMatches(si.group(1)!)) {
        parts.add(_decodeXml(t.group(1)!));
      }
      strings.add(parts.join());
    }
    return strings;
  }

  static List<List<Object?>> _sheetXmlToMatrix(
    String xml,
    List<String> sharedStrings,
  ) {
    final rowRegex = RegExp(r'<row[^>]*>([\s\S]*?)</row>', caseSensitive: false);
    final cellRegex = RegExp(
      r'<c[^>]* r="([A-Z]+)(\d+)"[^>]*(?: t="([^"]*)")?[^>]*>(?:<v>([\s\S]*?)</v>)?',
      caseSensitive: false,
    );

    final rowsByIndex = <int, Map<int, Object?>>{};
    var maxCol = 0;

    for (final rowMatch in rowRegex.allMatches(xml)) {
      final rowXml = rowMatch.group(1)!;
      final rowNumMatch = RegExp(r'r="(\d+)"').firstMatch(rowMatch.group(0)!);
      final rowIndex = rowNumMatch != null
          ? (int.tryParse(rowNumMatch.group(1)!) ?? 1) - 1
          : rowsByIndex.length;
      final cols = rowsByIndex.putIfAbsent(rowIndex, () => {});

      for (final cell in cellRegex.allMatches(rowXml)) {
        final colLetters = cell.group(1)!;
        final colIndex = _colLettersToIndex(colLetters);
        final type = cell.group(3);
        final rawValue = cell.group(4);
        if (rawValue == null) continue;
        Object? value = _decodeXml(rawValue);
        if (type == 's') {
          final idx = int.tryParse(rawValue) ?? -1;
          if (idx >= 0 && idx < sharedStrings.length) {
            value = sharedStrings[idx];
          }
        }
        cols[colIndex] = value;
        if (colIndex > maxCol) maxCol = colIndex;
      }
    }

    if (rowsByIndex.isEmpty) return const [];

    final maxRow = rowsByIndex.keys.reduce((a, b) => a > b ? a : b);
    final matrix = <List<Object?>>[];
    for (var r = 0; r <= maxRow; r++) {
      final cols = rowsByIndex[r] ?? {};
      final row = List<Object?>.filled(maxCol + 1, '');
      cols.forEach((c, v) => row[c] = v);
      matrix.add(row);
    }
    return matrix;
  }

  static int _colLettersToIndex(String letters) {
    var index = 0;
    for (var i = 0; i < letters.length; i++) {
      index = index * 26 + (letters.codeUnitAt(i) - 64);
    }
    return index - 1;
  }

  static String _decodeXml(String value) {
    return value
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&apos;', "'")
        .replaceAll('&quot;', '"');
  }
}
