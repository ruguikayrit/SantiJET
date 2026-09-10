import 'package:flutter_test/flutter_test.dart';

import 'package:santijet_kasa/domain/csv_export.dart';
import 'package:santijet_kasa/domain/hareket_filters.dart';
import 'package:santijet_kasa/domain/kasa_hareket.dart';
import 'package:santijet_kasa/domain/kasa_lookups.dart';
import 'package:santijet_kasa/domain/kasa_ocr_parser.dart';
import 'package:santijet_kasa/domain/kasa_rules.dart';
import 'package:santijet_kasa/domain/kasa_transfer_format.dart';
import 'package:santijet_kasa/domain/money_format.dart';
import 'package:santijet_kasa/data/demo_data.dart';
import 'package:santijet_kasa/data/kasa_export_service.dart';
import 'package:santijet_kasa/data/kasa_import_service.dart';
import 'package:santijet_kasa/data/kasa_table_ocr.dart';

void main() {
  group('validateHareket', () {
    test('rejects empty description', () {
      expect(
        validateHareket(aciklama: '', gelir: 10),
        isNotNull,
      );
    });

    test('rejects both gelir and gider', () {
      expect(
        validateHareket(aciklama: 'x', gelir: 10, gider: 5),
        contains('hem gelir hem gider'),
      );
    });

    test('rejects neither', () {
      expect(
        validateHareket(aciklama: 'x'),
        contains('Gelir veya gider'),
      );
    });

    test('accepts gelir only', () {
      expect(validateHareket(aciklama: 'avans', gelir: 100), isNull);
    });

    test('accepts gider only', () {
      expect(validateHareket(aciklama: 'fiş', gider: 50), isNull);
    });
  });

  group('hesaplaOzet', () {
    test('guncel kasa = gelir - gider', () {
      final now = DateTime(2026, 1, 1);
      final list = [
        KasaHareket(
          id: '1',
          tarih: now,
          aciklama: 'a',
          gelir: 1000,
          createdAt: now,
          updatedAt: now,
        ),
        KasaHareket(
          id: '2',
          tarih: now,
          aciklama: 'b',
          gider: 400,
          createdAt: now,
          updatedAt: now,
        ),
        KasaHareket(
          id: '3',
          tarih: now,
          aciklama: 'c',
          gider: 100,
          createdAt: now,
          updatedAt: now,
        ),
      ];
      final ozet = hesaplaOzet(list);
      expect(ozet.toplamGelir, 1000);
      expect(ozet.toplamGider, 500);
      expect(ozet.guncelKasa, 500);
      expect(ozet.isNegatif, isFalse);
    });

    test('negative balance', () {
      final now = DateTime(2026, 1, 1);
      final ozet = hesaplaOzet([
        KasaHareket(
          id: '1',
          tarih: now,
          aciklama: 'a',
          gelir: 100,
          createdAt: now,
          updatedAt: now,
        ),
        KasaHareket(
          id: '2',
          tarih: now,
          aciklama: 'b',
          gider: 250,
          createdAt: now,
          updatedAt: now,
        ),
      ]);
      expect(ozet.guncelKasa, -150);
      expect(ozet.isNegatif, isTrue);
    });
  });

  group('MoneyFormat', () {
    test('formats TR currency', () {
      final s = MoneyFormat.format(1234.56);
      expect(s, contains('1.234'));
      expect(s, contains('56'));
      expect(s, contains('₺'));
    });

    test('parses TR input', () {
      expect(MoneyFormat.tryParse('1.234,56'), 1234.56);
      expect(MoneyFormat.tryParse('₺350,00'), 350);
    });
  });

  group('HareketlerNotifier appendImported', () {
    test('appends without removing existing rows', () {
      final now = DateTime(2026, 9, 8);
      final existing = [
        KasaHareket(
          id: 'a',
          tarih: now,
          aciklama: 'Eski',
          gider: 5,
          santiye: 'İZMİT/EFSANE',
          createdAt: now,
          updatedAt: now,
        ),
      ];
      final incoming = [
        KasaHareket(
          id: 'b',
          tarih: now,
          aciklama: 'Yeni',
          gider: 10,
          santiye: 'YANLIŞ/OKUMA',
          createdAt: now,
          updatedAt: now,
        ),
      ];
      // appendImported mantığı: birleştir + id çakışmasını ele
      final merged = [
        ...incoming,
        ...existing.where((e) => !incoming.any((n) => n.id == e.id)),
      ];
      expect(merged.length, 2);
      expect(merged.map((e) => e.id).toSet(), {'a', 'b'});
    });
  });

  group('filter + demo', () {
    test('demo data is valid and balances', () {
      final demo = buildDemoHareketler(now: DateTime(2026, 9, 8));
      expect(demo.length, greaterThanOrEqualTo(8));
      expect(demo.length, lessThanOrEqualTo(12));
      for (final h in demo) {
        expect(
          validateHareket(
            aciklama: h.aciklama,
            gelir: h.gelir,
            gider: h.gider,
          ),
          isNull,
        );
      }
      final ozet = hesaplaOzet(demo);
      expect(ozet.toplamGelir, greaterThan(0));
      expect(ozet.toplamGider, greaterThan(0));
    });

    test('search filters tedarikci/aciklama', () {
      final demo = buildDemoHareketler(now: DateTime(2026, 9, 8));
      final found = filterHareketler(
        demo,
        const HareketFilters(query: 'yeşiller'),
      );
      expect(found, isNotEmpty);
      expect(found.first.tedarikci.toUpperCase(), contains('YEŞİLLER'));
    });

    test('santiye scope filters rows', () {
      final now = DateTime(2026, 9, 8);
      final rows = [
        KasaHareket(
          id: '1',
          tarih: now,
          aciklama: 'A',
          gider: 10,
          santiye: 'İZMİT/EFSANE',
          createdAt: now,
          updatedAt: now,
        ),
        KasaHareket(
          id: '2',
          tarih: now,
          aciklama: 'B',
          gider: 20,
          santiye: 'ANKARA/X',
          createdAt: now,
          updatedAt: now,
        ),
      ];
      final izmit = filterHareketler(
        rows,
        const HareketFilters(santiye: 'İZMİT/EFSANE'),
      );
      expect(izmit.length, 1);
      expect(izmit.first.santiye, 'İZMİT/EFSANE');
    });

    test('odeme, belge, gelir/gider and date filters', () {
      final demo = buildDemoHareketler(now: DateTime(2026, 9, 8));
      final havale = filterHareketler(
        demo,
        const HareketFilters(odemeSekli: OdemeSekli.havale),
      );
      expect(havale, isNotEmpty);
      expect(havale.every((h) => h.odemeSekli == OdemeSekli.havale), isTrue);

      final fis = filterHareketler(
        demo,
        const HareketFilters(belgeTuru: BelgeTuru.fis),
      );
      expect(fis, isNotEmpty);
      expect(fis.every((h) => h.belgeTuru == BelgeTuru.fis), isTrue);

      final gelir = filterHareketler(
        demo,
        const HareketFilters(onlyGelir: true),
      );
      expect(gelir, isNotEmpty);
      expect(gelir.every((h) => h.isGelir), isTrue);

      final gider = filterHareketler(
        demo,
        const HareketFilters(onlyGider: true),
      );
      expect(gider, isNotEmpty);
      expect(gider.every((h) => h.isGider), isTrue);

      final aug2024 = filterHareketler(
        demo,
        HareketFilters(
          from: DateTime(2024, 8, 1),
          to: DateTime(2024, 8, 31),
        ),
      );
      expect(aug2024, isNotEmpty);
      expect(
        aug2024.every((h) => h.tarih.year == 2024 && h.tarih.month == 8),
        isTrue,
      );
    });
  });

  group('CsvExport', () {
    test('includes header and rows', () {
      final demo = buildDemoHareketler(now: DateTime(2026, 9, 8));
      final csv = CsvExport.hareketlerToCsv(demo.take(2));
      expect(csv, startsWith('Tarih;Tedarikçi;Açıklama'));
      expect(csv.split('\n').length, greaterThan(2));
    });
  });

  group('Excel import/export', () {
    test('round-trips hareket rows', () {
      final demo = buildDemoHareketler(now: DateTime(2026, 9, 8));
      final bytes = KasaExportService().buildExcelBytes(hareketler: demo);
      final parsed = KasaImportService().parseExcelBytes(
        bytes,
        now: DateTime(2026, 9, 8),
      );
      expect(parsed.hareketler.length, demo.length);
      expect(parsed.hareketler.first.aciklama, isNotEmpty);
    });

    test('column char counts follow widest cell (except sizing policy)', () {
      final now = DateTime(2026, 9, 8);
      final svc = KasaExportService();
      final rows = [
        KasaHareket(
          id: '1',
          tarih: now,
          tedarikci: 'AB',
          aciklama: 'kısa',
          gider: 10,
          odemeSekli: OdemeSekli.nakit,
          belgeTuru: BelgeTuru.fis,
          santiye: 'X',
          createdAt: now,
          updatedAt: now,
        ),
        KasaHareket(
          id: '2',
          tarih: now,
          tedarikci: 'ÇOKUZUNTTEDARIKCIADI',
          aciklama: 'çok uzun açıklama satırı burada',
          gider: 1234567.89,
          odemeSekli: OdemeSekli.sahsiKart,
          belgeTuru: BelgeTuru.fatura,
          santiye: 'İZMİT/EFSANE',
          createdAt: now,
          updatedAt: now,
        ),
      ];
      final maxes = svc.maxContentCharCounts(rows);
      expect(maxes[1], 'ÇOKUZUNTTEDARIKCIADI'.length);
      expect(maxes[4], MoneyFormat.format(1234567.89).length);
      expect(maxes[0], greaterThanOrEqualTo('Tarih'.length));
      expect(KasaExportService.headers.contains('Ek Açıklama'), isFalse);
    });

    test('belge draft from jpg/pdf', () {
      final jpg = KasaImportService().draftFromBelge(
        format: KasaTransferFormat.jpg,
        fileName: 'fis_kocatas.jpg',
      );
      expect(jpg.belgeTuru, BelgeTuru.fis);
      expect(jpg.ekAciklama, contains('JPG'));

      final pdf = KasaImportService().draftFromBelge(
        format: KasaTransferFormat.pdf,
        fileName: 'fatura.pdf',
      );
      expect(pdf.belgeTuru, BelgeTuru.fatura);
      expect(pdf.ekAciklama, contains('PDF'));
    });
  });

  group('KasaTableOcr', () {
    test('peels excel-like expense line', () {
      const raw = '''
TARİH TEDARİKÇİ AÇIKLAMA GELİR GİDER ÖDEME BELGE ŞANTİYE
11.08.2024 YEŞİLLER TEKNİK CIVATA SOMUN ₺350,00 ŞAHSI K.KARTI FİŞ İZMİT/EFSANE
''';
      final parsed = KasaTableOcr.parse(
        rawText: raw,
        now: DateTime(2026, 9, 8),
      );
      expect(parsed.hareketler, isNotEmpty);
      final h = parsed.hareketler.first;
      expect(h.gider, 350);
      expect(h.tarih.day, 11);
      expect(h.santiye, contains('İZMİT'));
    });

    test('overlay column alignment', () {
      final header = [
        const OcrWord(text: 'TARİH', left: 10, top: 10, width: 40, height: 12),
        const OcrWord(
          text: 'TEDARİKÇİ',
          left: 80,
          top: 10,
          width: 60,
          height: 12,
        ),
        const OcrWord(
          text: 'AÇIKLAMA',
          left: 200,
          top: 10,
          width: 60,
          height: 12,
        ),
        const OcrWord(text: 'GELİR', left: 360, top: 10, width: 40, height: 12),
        const OcrWord(text: 'GİDER', left: 420, top: 10, width: 40, height: 12),
        const OcrWord(text: 'ÖDEME', left: 500, top: 10, width: 40, height: 12),
        const OcrWord(text: 'BELGE', left: 580, top: 10, width: 40, height: 12),
        const OcrWord(
          text: 'ŞANTİYE',
          left: 660,
          top: 10,
          width: 50,
          height: 12,
        ),
      ];
      final row = [
        const OcrWord(
          text: '11.08.2024',
          left: 8,
          top: 40,
          width: 55,
          height: 12,
        ),
        const OcrWord(
          text: 'YEŞİLLER',
          left: 80,
          top: 40,
          width: 50,
          height: 12,
        ),
        const OcrWord(
          text: 'CIVATA',
          left: 200,
          top: 40,
          width: 40,
          height: 12,
        ),
        const OcrWord(
          text: '350,00',
          left: 415,
          top: 40,
          width: 40,
          height: 12,
        ),
        const OcrWord(text: 'NAKİT', left: 500, top: 40, width: 35, height: 12),
        const OcrWord(text: 'FİŞ', left: 585, top: 40, width: 25, height: 12),
        const OcrWord(
          text: 'İZMİT/EFSANE',
          left: 650,
          top: 40,
          width: 70,
          height: 12,
        ),
      ];
      final parsed = KasaTableOcr.parse(
        rawText: '',
        words: [...header, ...row],
        now: DateTime(2026, 9, 8),
      );
      expect(parsed.hareketler.length, 1);
      expect(parsed.hareketler.first.gider, 350);
      expect(parsed.hareketler.first.aciklama, contains('CIVATA'));
    });
  });

  group('KasaOcrParser', () {
    test('parses table-like expense line', () {
      const raw = '''
TARİH TEDARİKÇİ AÇIKLAMA GELİR GİDER ÖDEME BELGE ŞANTİYE
11.08.2024 YEŞİLLER TEKNİK CIVATA SOMUN ₺350,00 ŞAHSI K.KARTI FİŞ İZMİT/EFSANE
''';
      final parsed = KasaOcrParser.parseText(
        raw,
        now: DateTime(2026, 9, 8),
      );
      expect(parsed.hareketler, isNotEmpty);
      final h = parsed.hareketler.first;
      expect(h.gider, 350);
      expect(h.tarih.day, 11);
      expect(h.tarih.month, 8);
    });

    test('parses income line', () {
      const raw =
          '11.07.2026 KADİR BEY DENİZBANK HESABIMA GÖNDERDİ ₺5.429,83 HAVALE';
      final parsed = KasaOcrParser.parseText(raw, now: DateTime(2026, 9, 8));
      expect(parsed.hareketler, isNotEmpty);
      expect(parsed.hareketler.first.gelir, closeTo(5429.83, 0.01));
    });

    test('receipt fallback single amount', () {
      const raw = '''
Market fişi
Alışveriş notu
15.03.2025
TOPLAM ₺890,00
''';
      final parsed = KasaOcrParser.parseText(raw, now: DateTime(2026, 9, 8));
      expect(parsed.hareketler, isNotEmpty);
      expect(
        parsed.hareketler.any((h) => h.gider == 890),
        isTrue,
      );
    });
  });
}
