import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';

/// Excel (.xlsx) dosyasına OOXML çizim/medya olarak gömülü fotoğraf ekler.
///
/// [placements] satır/sütun (0-tabanlı) hücre köşesine sabitlenen görsellerdir.
List<int> embedImagesInXlsx({
  required List<int> xlsxBytes,
  required String sheetName,
  required List<XlsxImagePlacement> placements,
  int imageWidthPx = 120,
  int imageHeightPx = 90,
}) {
  if (placements.isEmpty) return xlsxBytes;

  final archive = ZipDecoder().decodeBytes(xlsxBytes, verify: true);
  final files = <String, ArchiveFile>{
    for (final f in archive.files)
      if (f.isFile) f.name.replaceAll('\\', '/'): f,
  };

  final workbookXml = _readUtf8(files['xl/workbook.xml']);
  final workbookRelsXml = _readUtf8(files['xl/_rels/workbook.xml.rels']);
  if (workbookXml == null || workbookRelsXml == null) return xlsxBytes;

  final sheetPath = _sheetPathForName(
    workbookXml: workbookXml,
    workbookRelsXml: workbookRelsXml,
    sheetName: sheetName,
  );
  if (sheetPath == null) return xlsxBytes;

  final sheetXml = _readUtf8(files[sheetPath]);
  if (sheetXml == null) return xlsxBytes;

  final sheetRelsPath =
      '${sheetPath.replaceFirst('xl/worksheets/', 'xl/worksheets/_rels/')}.rels';
  final existingSheetRels = _readUtf8(files[sheetRelsPath]) ??
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
          '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
          '</Relationships>';

  final drawingId = _nextRelId(existingSheetRels);
  final drawingPath = 'xl/drawings/drawing_santijet_photos.xml';
  final drawingRelsPath = 'xl/drawings/_rels/drawing_santijet_photos.xml.rels';

  final mediaEntries = <String, List<int>>{};
  final drawingRelParts = StringBuffer();
  final anchors = StringBuffer();

  // EMU: 914400 per inch; at 96 dpi → 9525 EMU/px
  const emuPerPx = 9525;
  final cx = imageWidthPx * emuPerPx;
  final cy = imageHeightPx * emuPerPx;

  for (var i = 0; i < placements.length; i++) {
    final p = placements[i];
    final imgBytes = p.bytes;
    if (imgBytes.isEmpty) continue;
    final ext = _imageExt(imgBytes);
    final mediaName = 'image_santijet_${i + 1}.$ext';
    final mediaPath = 'xl/media/$mediaName';
    mediaEntries[mediaPath] = imgBytes;

    final rid = 'rId${i + 1}';
    drawingRelParts.write(
      '<Relationship Id="$rid" '
      'Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/image" '
      'Target="../media/$mediaName"/>',
    );

    anchors.write(
      '<xdr:oneCellAnchor>'
      '<xdr:from>'
      '<xdr:col>${p.column}</xdr:col><xdr:colOff>9525</xdr:colOff>'
      '<xdr:row>${p.row}</xdr:row><xdr:rowOff>9525</xdr:rowOff>'
      '</xdr:from>'
      '<xdr:ext cx="$cx" cy="$cy"/>'
      '<xdr:pic>'
      '<xdr:nvPicPr>'
      '<xdr:cNvPr id="${i + 1}" name="Foto ${i + 1}"/>'
      '<xdr:cNvPicPr><a:picLocks noChangeAspect="1"/></xdr:cNvPicPr>'
      '</xdr:nvPicPr>'
      '<xdr:blipFill>'
      '<a:blip xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" r:embed="$rid"/>'
      '<a:stretch><a:fillRect/></a:stretch>'
      '</xdr:blipFill>'
      '<xdr:spPr>'
      '<a:xfrm><a:off x="0" y="0"/><a:ext cx="$cx" cy="$cy"/></a:xfrm>'
      '<a:prstGeom prst="rect"><a:avLst/></a:prstGeom>'
      '</xdr:spPr>'
      '</xdr:pic>'
      '<xdr:clientData/>'
      '</xdr:oneCellAnchor>',
    );
  }

  if (mediaEntries.isEmpty) return xlsxBytes;

  final drawingXml =
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
      '<xdr:wsDr xmlns:xdr="http://schemas.openxmlformats.org/drawingml/2006/spreadsheetDrawing" '
      'xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main">'
      '${anchors.toString()}'
      '</xdr:wsDr>';

  final drawingRelsXml =
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
      '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
      '${drawingRelParts.toString()}'
      '</Relationships>';

  final updatedSheetRels = _upsertRelationship(
    existingSheetRels,
    id: drawingId,
    type:
        'http://schemas.openxmlformats.org/officeDocument/2006/relationships/drawing',
    target: '../drawings/drawing_santijet_photos.xml',
  );

  final updatedSheetXml = _ensureDrawingReference(sheetXml, drawingId);

  var contentTypes = _readUtf8(files['[Content_Types].xml']);
  if (contentTypes != null) {
    var ct = contentTypes;
    ct = _ensureContentType(
      ct,
      partName: '/$drawingPath',
      contentType:
          'application/vnd.openxmlformats-officedocument.drawing+xml',
    );
    for (final path in mediaEntries.keys) {
      final ext = path.split('.').last.toLowerCase();
      final mime = ext == 'png' ? 'image/png' : 'image/jpeg';
      ct = _ensureDefaultContentType(
        ct,
        extension: ext,
        contentType: mime,
      );
    }
    contentTypes = ct;
  }

  final out = Archive();
  final written = <String>{};

  void addBytes(String name, List<int> bytes) {
    out.addFile(ArchiveFile(name, bytes.length, bytes));
    written.add(name);
  }

  void addUtf8(String name, String text) {
    final bytes = utf8.encode(text);
    addBytes(name, bytes);
  }

  for (final entry in files.entries) {
    if (entry.key == sheetPath) {
      addUtf8(sheetPath, updatedSheetXml);
    } else if (entry.key == sheetRelsPath) {
      addUtf8(sheetRelsPath, updatedSheetRels);
    } else if (entry.key == '[Content_Types].xml' && contentTypes != null) {
      addUtf8('[Content_Types].xml', contentTypes);
    } else {
      addBytes(entry.key, entry.value.content);
    }
  }

  if (!written.contains(sheetRelsPath)) {
    addUtf8(sheetRelsPath, updatedSheetRels);
  }
  addUtf8(drawingPath, drawingXml);
  addUtf8(drawingRelsPath, drawingRelsXml);
  for (final e in mediaEntries.entries) {
    addBytes(e.key, e.value);
  }

  return ZipEncoder().encode(out)!;
}

class XlsxImagePlacement {
  const XlsxImagePlacement({
    required this.row,
    required this.column,
    required this.bytes,
  });

  final int row;
  final int column;
  final Uint8List bytes;
}

String? _readUtf8(ArchiveFile? file) {
  if (file == null) return null;
  return utf8.decode(file.content as List<int>, allowMalformed: true);
}

String? _sheetPathForName({
  required String workbookXml,
  required String workbookRelsXml,
  required String sheetName,
}) {
  final sheetRe = RegExp(
    'name="${RegExp.escape(sheetName)}"[^>]*r:id="(rId\\d+)"'
    '|'
    'r:id="(rId\\d+)"[^>]*name="${RegExp.escape(sheetName)}"',
  );
  final m = sheetRe.firstMatch(workbookXml);
  final rid = m?.group(1) ?? m?.group(2);
  if (rid == null) return null;

  final relRe = RegExp(
    'Id="$rid"[^>]*Target="([^"]+)"'
    '|'
    'Target="([^"]+)"[^>]*Id="$rid"',
  );
  final rm = relRe.firstMatch(workbookRelsXml);
  final target = rm?.group(1) ?? rm?.group(2);
  if (target == null) return null;
  final normalized = target.replaceAll('\\', '/');
  if (normalized.startsWith('/xl/')) return normalized.substring(1);
  if (normalized.startsWith('xl/')) return normalized;
  return 'xl/$normalized';
}

String _nextRelId(String relsXml) {
  final ids = RegExp(r'Id="rId(\d+)"')
      .allMatches(relsXml)
      .map((m) => int.parse(m.group(1)!))
      .toList();
  final next = ids.isEmpty ? 1 : (ids.reduce((a, b) => a > b ? a : b) + 1);
  return 'rId$next';
}

String _upsertRelationship(
  String relsXml, {
  required String id,
  required String type,
  required String target,
}) {
  final cleaned = relsXml.replaceAll(
    RegExp('<Relationship[^>]*Id="$id"[^>]*/>'),
    '',
  );
  final rel =
      '<Relationship Id="$id" Type="$type" Target="$target"/>';
  if (cleaned.contains('</Relationships>')) {
    return cleaned.replaceFirst('</Relationships>', '$rel</Relationships>');
  }
  return '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
      '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
      '$rel</Relationships>';
}

String _ensureDrawingReference(String sheetXml, String drawingId) {
  var xml = sheetXml.replaceAll(RegExp(r'<drawing[^>]*/>'), '');

  // drawing r:id için relationships ad alanı gerekli.
  if (!xml.contains('xmlns:r=')) {
    xml = xml.replaceFirst(
      '<worksheet ',
      '<worksheet xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" ',
    );
  }

  final drawing = '<drawing r:id="$drawingId"/>';
  if (xml.contains('<pageMargins')) {
    return xml.replaceFirst('<pageMargins', '$drawing<pageMargins');
  }
  if (xml.contains('<pageSetup')) {
    return xml.replaceFirst('<pageSetup', '$drawing<pageSetup');
  }
  if (xml.contains('</worksheet>')) {
    return xml.replaceFirst('</worksheet>', '$drawing</worksheet>');
  }
  return xml;
}

String _ensureContentType(
  String contentTypes, {
  required String partName,
  required String contentType,
}) {
  if (contentTypes.contains('PartName="$partName"')) return contentTypes;
  final override =
      '<Override PartName="$partName" ContentType="$contentType"/>';
  return contentTypes.replaceFirst('</Types>', '$override</Types>');
}

String _ensureDefaultContentType(
  String contentTypes, {
  required String extension,
  required String contentType,
}) {
  if (contentTypes.contains('Extension="$extension"')) return contentTypes;
  final def =
      '<Default Extension="$extension" ContentType="$contentType"/>';
  return contentTypes.replaceFirst('</Types>', '$def</Types>');
}

String _imageExt(Uint8List bytes) {
  if (bytes.length >= 8 &&
      bytes[0] == 0x89 &&
      bytes[1] == 0x50 &&
      bytes[2] == 0x4E &&
      bytes[3] == 0x47) {
    return 'png';
  }
  return 'jpeg';
}
