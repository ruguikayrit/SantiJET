import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:santijet_is_programi/data/interop/program_pdf_report.dart';
import 'package:santijet_is_programi/domain/program_item.dart';

final today = DateTime(2026, 3, 10);

final sample = <ProgramItem>[
  ProgramItem(
    id: 'a1',
    santiyeId: 'Merkez Şantiyesi',
    name: 'Hafriyat ve zemin tesviyesi',
    startDate: DateTime(2026, 3, 2),
    endDate: DateTime(2026, 3, 11),
    progress: 100,
    status: ProgramStatus.completed,
    responsible: 'Saha Ekibi',
    wbs: '1.1',
  ),
  ProgramItem(
    id: 'a2',
    santiyeId: 'Depo Şantiyesi',
    name: 'Çelik kolon montajı · ğüşıöç',
    startDate: DateTime(2026, 2, 20),
    endDate: DateTime(2026, 3, 5),
    progress: 30,
    status: ProgramStatus.inProgress,
    responsible: 'Montaj Ekibi',
    wbs: '2.1',
  ),
];

/// Uygulamanın PDF'e gömdüğü yazı tipi. Türkçe `İ`, `ş`, `ı` bu yazı tipinden
/// gelir; PDF standart yazı tipleri bu karakterleri çizemez.
pw.Font loadInter() {
  final file = File('assets/fonts/Inter-Variable.ttf');
  expect(
    file.existsSync(),
    isTrue,
    reason: 'PDF Türkçe karakterleri için Inter gerekiyor.',
  );
  return pw.Font.ttf(
    ByteData.view(Uint8List.fromList(file.readAsBytesSync()).buffer),
  );
}

void main() {
  test('Türkçe karakterli program PDF olarak üretilir', () async {
    final font = loadInter();
    final pdf = await ProgramPdfReport(regular: font, bold: font).build(
      sample,
      projectName: 'Merkez Şantiyesi',
      today: today,
    );

    expect(String.fromCharCodes(pdf.take(5)), '%PDF-');
    expect(pdf.length, greaterThan(2000));
  });

  test('faaliyet olmadan da rapor üretilir', () async {
    final font = loadInter();
    final pdf = await ProgramPdfReport(regular: font, bold: font).build(
      const [],
      projectName: 'Boş Program',
      today: today,
    );
    expect(String.fromCharCodes(pdf.take(5)), '%PDF-');
  });
}
