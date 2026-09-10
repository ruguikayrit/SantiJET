import 'package:file_picker/file_picker.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/services.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../domain/program_item.dart';
import 'msproject_xml_codec.dart';
import 'program_excel_codec.dart';
import 'program_interop.dart';
import 'program_pdf_report.dart';

/// Dosya seçme, okuma ve kaydetme işlerini tek yerde toplar.
class ProgramInteropService {
  ProgramInteropService();

  final MsProjectXmlCodec _xml = const MsProjectXmlCodec();
  final ProgramExcelCodec _excel = const ProgramExcelCodec();
  pw.Font? _pdfFont;

  /// Kaydedilen dosyanın adı (uzantısız).
  String fileName({required String projectName, DateTime? now}) {
    final slug = projectName
        .toLowerCase()
        .replaceAll('ş', 's')
        .replaceAll('ç', 'c')
        .replaceAll('ğ', 'g')
        .replaceAll('ı', 'i')
        .replaceAll('ö', 'o')
        .replaceAll('ü', 'u')
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    final stamp = isoDate(now ?? DateTime.now());
    return '${slug.isEmpty ? 'is-programi' : slug}-$stamp';
  }

  /// Seçilen biçimde dosya üretip cihaza kaydeder ve dosya adını döndürür.
  Future<String> export(
    InteropFormat format,
    List<ProgramItem> items, {
    required String projectName,
    DateTime? now,
  }) async {
    if (items.isEmpty) {
      throw const ProgramImportException('Aktarılacak faaliyet yok.');
    }

    final name = fileName(projectName: projectName, now: now);
    final (bytes, mime) = switch (format) {
      InteropFormat.msProjectXml => (
        _xml.encode(items, projectName: projectName, now: now),
        MimeType.xml,
      ),
      InteropFormat.excel => (
        _excel.encode(items, today: now),
        MimeType.microsoftExcel,
      ),
      InteropFormat.pdf => (
        await _buildPdf(items, projectName: projectName, now: now),
        MimeType.pdf,
      ),
    };

    await FileSaver.instance.saveFile(
      name: name,
      bytes: bytes,
      fileExtension: format.extension,
      mimeType: mime,
    );
    return '$name.${format.extension}';
  }

  /// MS Project XML veya Excel dosyası seçtirir ve faaliyetlere çevirir.
  /// Kullanıcı seçimi iptal ederse `null` döner.
  Future<ProgramImportResult?> pickAndDecode({
    required String fallbackSite,
    DateTime? today,
  }) async {
    final file = await FilePicker.pickFile(
      dialogTitle: 'İş programı dosyası seç',
      type: FileType.custom,
      allowedExtensions: const ['xml', 'xlsx', 'xlsm'],
    );
    if (file == null) return null;

    return decodeBytes(
      await file.readAsBytes(),
      extension: (file.extension ?? '').toLowerCase(),
      fallbackSite: fallbackSite,
      today: today,
    );
  }

  ProgramImportResult decodeBytes(
    Uint8List bytes, {
    required String extension,
    required String fallbackSite,
    DateTime? today,
  }) => switch (extension) {
    'xml' => _xml.decode(bytes, fallbackSite: fallbackSite, today: today),
    'xlsx' || 'xlsm' => _excel.decode(
      bytes,
      fallbackSite: fallbackSite,
      today: today,
    ),
    'mpp' => throw const ProgramImportException(
      '.mpp dosyası doğrudan okunamaz. MS Project içinde '
      '"Dosya → Farklı Kaydet → MS Project XML (*.xml)" ile kaydedip '
      'o dosyayı seçin.',
    ),
    'pdf' => throw const ProgramImportException(
      'PDF yalnız dışa aktarım biçimidir. İçe aktarım için MS Project XML '
      'veya Excel dosyası seçin.',
    ),
    _ => throw ProgramImportException(
      'Desteklenmeyen dosya türü: .$extension',
    ),
  };

  Future<Uint8List> _buildPdf(
    List<ProgramItem> items, {
    required String projectName,
    DateTime? now,
  }) async {
    final font = await _loadPdfFont();
    return ProgramPdfReport(regular: font, bold: font).build(
      items,
      projectName: projectName,
      today: now,
    );
  }

  /// PDF'de Türkçe karakterlerin doğru çıkması için uygulama yazı tipini gömer.
  /// PDF standart yazı tipleri `İ`, `ş` ve `ı` çizemediği için yazı tipi
  /// yüklenemezse bozuk dosya üretmek yerine hata verilir.
  Future<pw.Font> _loadPdfFont() async {
    final cached = _pdfFont;
    if (cached != null) return cached;
    try {
      final data = await rootBundle.load('assets/fonts/Inter-Variable.ttf');
      return _pdfFont = pw.Font.ttf(data);
    } catch (error) {
      throw ProgramImportException(
        'PDF yazı tipi yüklenemedi, Türkçe karakterler bozuk çıkardı. '
        'Excel ya da MS Project XML deneyin. ($error)',
      );
    }
  }
}
