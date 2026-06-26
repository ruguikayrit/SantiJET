import 'package:flutter_test/flutter_test.dart';
import 'package:santijet_demir/data/services/rebar_survey_mapper.dart';
import 'package:santijet_demir/domain/entities/rebar_metraj.dart';
import 'package:santijet_demir/domain/entities/survey.dart';

void main() {
  const lines = [
    RebarMetrajLine(
      diameter: 22,
      totalLengthM: 4008,
      weightKg: 11900,
      barCount: 334,
      layerName: 'TEXT',
    ),
    RebarMetrajLine(
      diameter: 16,
      totalLengthM: 30000,
      weightKg: 47400,
      barCount: 15000,
      layerName: 'TEXT',
    ),
  ];

  group('RebarSurveyMapper', () {
    test('yeni imalat oluşturur', () {
      final imalat = RebarSurveyMapper.createImalatFromMetraj(
        id: 'dosya-1',
        name: 'Dosya Metraj',
        lines: lines,
      );

      expect(imalat.name, 'Dosya Metraj');
      expect(imalat.diameterLines.length, 2);
      expect(imalat.planned, closeTo(11.9 + 47.4, 0.01));
      expect(imalat.ordered, 0);
    });

    test('mevcut imalata replace ile aktarır', () {
      const existing = SurveyImalat(
        id: 'radye',
        name: 'Radye Temel',
        totalTonnage: 100,
        progressPercent: 10,
        diameters: [22],
        diameterLines: [
          DiameterLine(diameter: 22, planned: 100, ordered: 20, delivered: 10),
        ],
        planned: 100,
        ordered: 20,
        delivered: 10,
        pending: 10,
      );

      final updated = RebarSurveyMapper.applyMetrajToImalat(
        imalat: existing,
        lines: [lines.first],
        replaceExisting: true,
      );

      expect(updated.diameterLines.first.planned, closeTo(11.9, 0.01));
      expect(updated.diameterLines.first.ordered, 20);
      expect(updated.diameterLines.first.delivered, 10);
    });

    test('mevcut imalata merge ile aktarır', () {
      const existing = SurveyImalat(
        id: 'radye',
        name: 'Radye Temel',
        totalTonnage: 100,
        progressPercent: 10,
        diameters: [22],
        diameterLines: [
          DiameterLine(diameter: 22, planned: 100, ordered: 20, delivered: 10),
        ],
        planned: 100,
        ordered: 20,
        delivered: 10,
        pending: 10,
      );

      final updated = RebarSurveyMapper.applyMetrajToImalat(
        imalat: existing,
        lines: [lines.first],
        replaceExisting: false,
      );

      expect(updated.diameterLines.first.planned, closeTo(111.9, 0.01));
    });
  });

  group('RebarMetrajResult serialization', () {
    test('toJson/fromJson roundtrip', () {
      final result = RebarMetrajResult(
        fileName: 'plan.dwg',
        sourceFormat: 'DWG',
        parsedAt: DateTime(2025, 6, 22, 12, 30),
        lines: lines,
        textDetails: const [
          RebarMetrajTextDetail(
            entityType: 'TEXT',
            sourceText: 'üst.334Ø22/15 l=120',
            included: true,
            diameter: 22,
            lengthM: 12,
            quantity: 334,
            weightKg: 11900,
          ),
        ],
        skippedEntityCount: 2,
        warnings: const ['Uyarı'],
      );

      final restored = RebarMetrajResult.fromJson(result.toJson());
      expect(restored.fileName, result.fileName);
      expect(restored.lines.length, 2);
      expect(restored.totalTonnage, closeTo(result.totalTonnage, 0.001));
      expect(restored.textDetails.first.sourceText, result.textDetails.first.sourceText);
    });
  });
}
