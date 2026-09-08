import 'package:flutter_test/flutter_test.dart';

import 'package:santijet_kasa/domain/csv_export.dart';
import 'package:santijet_kasa/domain/hareket_filters.dart';
import 'package:santijet_kasa/domain/kasa_hareket.dart';
import 'package:santijet_kasa/domain/kasa_rules.dart';
import 'package:santijet_kasa/domain/money_format.dart';
import 'package:santijet_kasa/data/demo_data.dart';

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
  });

  group('CsvExport', () {
    test('includes header and rows', () {
      final demo = buildDemoHareketler(now: DateTime(2026, 9, 8));
      final csv = CsvExport.hareketlerToCsv(demo.take(2));
      expect(csv, startsWith('Tarih;Tedarikçi;Açıklama'));
      expect(csv.split('\n').length, greaterThan(2));
    });
  });
}
