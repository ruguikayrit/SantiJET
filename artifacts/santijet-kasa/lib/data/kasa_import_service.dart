import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';

import '../domain/kasa_hareket.dart';
import '../domain/kasa_import_format.dart';
import '../domain/kasa_lookups.dart';
import '../domain/kasa_rules.dart';
import '../domain/kasa_transfer_format.dart';
import '../domain/money_format.dart';
import 'kasa_export_service.dart';

/// JPG / PDF belge seçimi sonucu — form taslağı.
class BelgeImportDraft {
  const BelgeImportDraft({
    required this.format,
    required this.fileName,
    required this.aciklama,
    required this.ekAciklama,
    required this.belgeTuru,
  });

  final KasaTransferFormat format;
  final String fileName;
  final String aciklama;
  final String ekAciklama;
  final String belgeTuru;
}

/// Excel içe aktarım sonucu.
class ExcelImportResult {
  const ExcelImportResult({
    required this.hareketler,
    required this.skipped,
  });

  final List<KasaHareket> hareketler;
  final int skipped;
}

/// JPG / PDF / Excel içe aktarım.
class KasaImportService {
  Future<FilePickerResult?> pick(KasaTransferFormat format) {
    return switch (format) {
      KasaTransferFormat.jpg => FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp'],
          withData: true,
        ),
      KasaTransferFormat.pdf => FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: const ['pdf'],
          withData: true,
        ),
      KasaTransferFormat.excel => FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: const ['xlsx', 'xls'],
          withData: true,
        ),
    };
  }

  /// JPG veya PDF → OCR bulunamazsa form taslağı.
  BelgeImportDraft draftFromBelge({
    required KasaTransferFormat format,
    required String fileName,
  }) {
    final base = fileName.contains('.')
        ? fileName.substring(0, fileName.lastIndexOf('.'))
        : fileName;
    final isPdf = format == KasaTransferFormat.pdf;
    return BelgeImportDraft(
      format: format,
      fileName: fileName,
      aciklama: base.trim().isEmpty ? fileName : base.trim(),
      ekAciklama: 'İçe aktarılan ${isPdf ? 'PDF' : 'JPG'}: $fileName',
      belgeTuru: isPdf ? BelgeTuru.fatura : BelgeTuru.fis,
    );
  }

  ExcelImportResult parseExcelBytes(
    Uint8List bytes, {
    DateTime? now,
    String defaultSantiye = 'İZMİT/EFSANE',
  }) {
    final excel = Excel.decodeBytes(bytes);
    if (excel.tables.isEmpty) {
      return const ExcelImportResult(hareketler: [], skipped: 0);
    }
    final sheet = excel.tables[excel.tables.keys.first];
    if (sheet == null || sheet.rows.isEmpty) {
      return const ExcelImportResult(hareketler: [], skipped: 0);
    }

    final headerIndex = _findHeaderRow(sheet.rows);
    if (headerIndex < 0) {
      throw StateError(
        'Excel’de başlık satırı bulunamadı. '
        'Beklenen sütunlar: ${KasaImportFormat.headers.join(', ')}',
      );
    }

    final headerCells = sheet.rows[headerIndex];
    final map = _columnMap(headerCells);
    final stamp = now ?? DateTime.now();
    const uuid = Uuid();
    final out = <KasaHareket>[];
    var skipped = 0;

    for (var r = headerIndex + 1; r < sheet.rows.length; r++) {
      final row = sheet.rows[r];
      final aciklama = _cell(row, map['aciklama']).trim();
      final gelir = MoneyFormat.tryParse(_cell(row, map['gelir']));
      final gider = MoneyFormat.tryParse(_cell(row, map['gider']));
      final err = validateHareket(
        aciklama: aciklama.isEmpty ? '—' : aciklama,
        gelir: gelir,
        gider: gider,
      );
      // Boş satır atla
      if (aciklama.isEmpty &&
          (gelir == null || gelir <= 0) &&
          (gider == null || gider <= 0)) {
        skipped++;
        continue;
      }
      if (err != null || aciklama.isEmpty) {
        skipped++;
        continue;
      }

      final hasGelir = gelir != null && gelir > 0;
      out.add(
        KasaHareket(
          id: uuid.v4(),
          tarih: _parseDate(_cell(row, map['tarih'])) ?? stamp,
          tedarikci: _cell(row, map['tedarikci']).trim(),
          aciklama: aciklama,
          gelir: hasGelir ? gelir : null,
          gider: hasGelir ? null : gider,
          odemeSekli: _cell(row, map['odeme']).trim().isEmpty
              ? OdemeSekli.havale
              : _cell(row, map['odeme']).trim(),
          belgeTuru: _cell(row, map['belge']).trim().isEmpty
              ? BelgeTuru.yok
              : _cell(row, map['belge']).trim(),
          santiye: _cell(row, map['santiye']).trim().isEmpty
              ? defaultSantiye
              : _cell(row, map['santiye']).trim(),
          ekAciklama: _cell(row, map['ek']).trim(),
          createdAt: stamp,
          updatedAt: stamp,
        ),
      );
    }

    return ExcelImportResult(hareketler: out, skipped: skipped);
  }

  int _findHeaderRow(List<List<Data?>> rows) {
    for (var i = 0; i < rows.length && i < 12; i++) {
      final joined = rows[i]
          .map((c) => (c?.value?.toString() ?? '').toLowerCase())
          .join('|');
      if (joined.contains('tarih') &&
          (joined.contains('açıklama') || joined.contains('aciklama')) &&
          (joined.contains('gelir') || joined.contains('gider'))) {
        return i;
      }
    }
    // Dışa aktarım formatı: başlık 5. satır civarı
    for (var i = 0; i < rows.length && i < 12; i++) {
      final joined = rows[i]
          .map((c) => (c?.value?.toString() ?? '').toLowerCase())
          .join('|');
      if (joined.contains('tarih') && joined.contains('tedarik')) {
        return i;
      }
    }
    return -1;
  }

  Map<String, int> _columnMap(List<Data?> header) {
    final map = <String, int>{};
    for (var i = 0; i < header.length; i++) {
      final raw = (header[i]?.value?.toString() ?? '').toLowerCase().trim();
      if (raw.contains('tarih')) map.putIfAbsent('tarih', () => i);
      if (raw.contains('tedarik')) map.putIfAbsent('tedarikci', () => i);
      if (raw.contains('açıklama') || raw.contains('aciklama')) {
        if (raw.contains('ek')) {
          map.putIfAbsent('ek', () => i);
        } else {
          map.putIfAbsent('aciklama', () => i);
        }
      }
      if (raw == 'gelir' || raw.startsWith('gelir')) {
        map.putIfAbsent('gelir', () => i);
      }
      if (raw == 'gider' || raw.startsWith('gider')) {
        map.putIfAbsent('gider', () => i);
      }
      if (raw.contains('ödeme') || raw.contains('odeme')) {
        map.putIfAbsent('odeme', () => i);
      }
      if (raw.contains('belge')) map.putIfAbsent('belge', () => i);
      if (raw.contains('şantiye') || raw.contains('santiye')) {
        map.putIfAbsent('santiye', () => i);
      }
      if (raw.contains('ek açıklama') || raw.contains('ek aciklama')) {
        map.putIfAbsent('ek', () => i);
      }
    }
    return map;
  }

  String _cell(List<Data?> row, int? index) {
    if (index == null || index < 0 || index >= row.length) return '';
    final v = row[index]?.value;
    if (v == null) return '';
    return v.toString();
  }

  DateTime? _parseDate(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return null;
    final iso = DateTime.tryParse(t);
    if (iso != null) return iso;
    final parts = t.split(RegExp(r'[./-]'));
    if (parts.length >= 3) {
      final d = int.tryParse(parts[0]);
      final m = int.tryParse(parts[1]);
      final y = int.tryParse(parts[2]);
      if (d != null && m != null && y != null) {
        return DateTime(y < 100 ? 2000 + y : y, m, d);
      }
    }
    return null;
  }
}

final kasaImportService = KasaImportService();

/// Export başlıklarıyla aynı sütun sırası — test/referans.
List<String> get kasaExcelHeaders => KasaExportService.headers;
