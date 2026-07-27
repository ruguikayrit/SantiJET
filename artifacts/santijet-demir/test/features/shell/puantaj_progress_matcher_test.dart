import 'package:flutter_test/flutter_test.dart';
import 'package:santijet_demir/domain/entities/puantaj_progress_cloud.dart';
import 'package:santijet_demir/domain/entities/survey.dart';
import 'package:santijet_demir/features/shell/puantaj_progress_matcher.dart';

SurveyImalat _imalat({
  required String id,
  required String name,
  required double planned,
  double progress = 0,
}) {
  return SurveyImalat(
    id: id,
    name: name,
    totalTonnage: planned,
    progressPercent: progress,
    diameters: const [],
    diameterLines: const [],
    planned: planned,
    ordered: 0,
    delivered: 0,
    pending: 0,
  );
}

void main() {
  test('imalat adı eşleşmesi (Türkçe büyük/küçük harf)', () {
    final matched = matchPuantajProgressToSurvey(
      imalats: [
        _imalat(id: 'a', name: 'Kolon Demiri', planned: 10),
        _imalat(id: 'b', name: 'Kiriş', planned: 5, progress: 10),
      ],
      snapshot: PuantajProgressSnapshot(
        accountEmail: 'usta@example.com',
        projectCode: 'PRJ-1',
        updatedAt: DateTime(2026, 7, 28),
        items: const [
          PuantajImalatProgressItem(
            imalatName: 'kolon demiri',
            progressPercent: 42,
          ),
          PuantajImalatProgressItem(
            imalatName: 'Döşeme',
            progressPercent: 20,
          ),
        ],
      ),
    );

    expect(matched.progressByImalatId, {'a': 42});
    expect(matched.unmatchedNames, ['Döşeme']);
  });
}
