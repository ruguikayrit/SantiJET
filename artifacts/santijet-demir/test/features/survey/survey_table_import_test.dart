import 'package:flutter_test/flutter_test.dart';
import 'package:santijet_demir/data/services/rebar_survey_mapper.dart';
import 'package:santijet_demir/features/survey/survey_table_import.dart';

void main() {
  group('survey excel import', () {
    test('round-trips the official template into displayable imalats', () {
      final examples = [
        RebarSurveyMapper.imalatFromPlanned(
          id: 'temel',
          name: 'Temel',
          plannedByDiameter: const {12: 18.5, 16: 22, 20: 9},
        ),
        RebarSurveyMapper.imalatFromPlanned(
          id: 'kolon',
          name: 'Kolon',
          plannedByDiameter: const {14: 11, 16: 16.25},
        ),
      ];

      final bytes = buildSurveyImportTemplateBytes(examples: examples);
      final parsed = parseSurveyImport(
        fileName: surveyImportTemplateFileName,
        bytes: bytes,
      );

      expect(parsed.map((item) => item.name), ['Temel', 'Kolon']);
      expect(parsed.first.diameters, [12, 16, 20]);
      expect(parsed.first.planned, closeTo(49.5, 1e-9));
      expect(parsed.last.planned, closeTo(27.25, 1e-9));
      expect(parsed.first.diameterLines.every((line) => line.ordered == 0), isTrue);
    });

    test('rejects files that are not xlsx', () {
      expect(
        () => parseSurveyImport(fileName: 'kesif.csv', bytes: const [1, 2, 3]),
        throwsA(isA<SurveyImportException>()),
      );
    });

    test('rejects a missing or renamed header', () {
      expect(
        () => parseSurveyImportRows([
          ['İmalat', 'Ø8', 'Ø10', 'Çap', 'Ø14', 'Ø16', 'Ø18', 'Ø20', 'Ø22', 'Ø25', 'Ø28', 'Ø32'],
          ['Temel', '', '', '10', '', '', '', '', '', '', '', ''],
        ]),
        throwsA(isA<SurveyImportException>()),
      );
    });

    test('rejects extra columns', () {
      expect(
        () => parseSurveyImportRows([
          [...surveyImportHeaders, 'Not'],
          ['Temel', '', '', '10', '', '', '', '', '', '', '', '', 'x'],
        ]),
        throwsA(isA<SurveyImportException>()),
      );
    });

    test('rejects negative tonnage', () {
      expect(
        () => parseSurveyImportRows([
          surveyImportHeaders,
          ['Temel', '', '', '-1', '', '', '', '', '', '', '', ''],
        ]),
        throwsA(isA<SurveyImportException>()),
      );
    });

    test('rejects duplicate imalat names', () {
      expect(
        () => parseSurveyImportRows([
          surveyImportHeaders,
          ['Temel', '', '', '10', '', '', '', '', '', '', '', ''],
          ['temel', '', '4', '', '', '', '', '', '', '', '', ''],
        ]),
        throwsA(isA<SurveyImportException>()),
      );
    });

    test('skips blank rows and parses comma decimals', () {
      final parsed = parseSurveyImportRows([
        surveyImportHeaders,
        List<String>.filled(surveyImportHeaders.length, ''),
        ['Kiriş', '', '', '', '12,5', '', '', '', '', '', '', ''],
      ]);

      expect(parsed, hasLength(1));
      expect(parsed.single.name, 'Kiriş');
      expect(parsed.single.diameters, [14]);
      expect(parsed.single.planned, closeTo(12.5, 1e-9));
    });

    test('merges imported rows onto existing imalats by name', () {
      final existing = [
        RebarSurveyMapper.imalatFromPlanned(
          id: 'temel',
          name: 'Temel',
          plannedByDiameter: const {12: 5},
        ).copyWith(ordered: 2, delivered: 1, progressPercent: 20),
        RebarSurveyMapper.imalatFromPlanned(
          id: 'perde',
          name: 'Perde',
          plannedByDiameter: const {16: 8},
        ),
      ];
      final incoming = [
        RebarSurveyMapper.imalatFromPlanned(
          id: 'temel',
          name: 'TEMEL',
          plannedByDiameter: const {12: 18, 16: 4},
        ),
        RebarSurveyMapper.imalatFromPlanned(
          id: 'kolon',
          name: 'Kolon',
          plannedByDiameter: const {14: 7},
        ),
      ];

      final merged = mergeImportedImalats(
        existing: existing,
        incoming: incoming,
      );

      expect(merged.added, 1);
      expect(merged.updated, 1);
      expect(merged.imalats, hasLength(3));
      final temel = merged.imalats.firstWhere((item) => item.id == 'temel');
      expect(temel.planned, closeTo(22, 1e-9));
      expect(temel.ordered, 2);
      expect(temel.delivered, 1);
      expect(temel.progressPercent, 20);
      expect(temel.blocks, isEmpty);
      expect(
        merged.imalats.map((item) => item.name),
        containsAll(['Temel', 'Perde', 'Kolon']),
      );
    });
  });
}
