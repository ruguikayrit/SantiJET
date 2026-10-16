import 'package:flutter_test/flutter_test.dart';
import 'package:santijet_demir/domain/entities/survey.dart';
import 'package:santijet_demir/features/survey/imalat_block_template.dart';
import 'package:santijet_demir/features/survey/providers/survey_provider.dart';

SurveyImalat _imalat({
  required String name,
  required double planned,
  required double ordered,
  required double delivered,
  required double progress,
}) {
  return SurveyImalat(
    id: name,
    name: name,
    totalTonnage: planned,
    progressPercent: progress,
    diameters: const [],
    diameterLines: const [],
    planned: planned,
    ordered: ordered,
    delivered: delivered,
    pending: ordered - delivered,
  );
}

void main() {
  test('recognizes the sample imalats that were written into empty projects', () {
    expect(
      isInjectedSampleImalat(
        _imalat(name: 'Temel', planned: 280, ordered: 172, delivered: 148, progress: 49),
      ),
      isTrue,
    );
    expect(
      isInjectedSampleImalat(
        _imalat(name: 'Döşeme', planned: 320, ordered: 128, delivered: 72, progress: 20),
      ),
      isTrue,
    );
    expect(
      isInjectedSampleImalat(
        _imalat(name: 'Merdiven', planned: 85, ordered: 34, delivered: 22, progress: 23),
      ),
      isTrue,
    );
    expect(
      isInjectedSampleImalat(
        _imalat(name: 'Temel', planned: 140, ordered: 108, delivered: 108, progress: 57.5),
      ),
      isFalse,
    );
  });

  test('empty imalat template does not invent tonnage', () {
    final blocks = ImalatBlockTemplate.build(
      _imalat(name: 'Kolon', planned: 0, ordered: 0, delivered: 0, progress: 0),
    );

    final planned = blocks.fold<double>(0, (sum, block) => sum + block.planned);
    expect(blocks, isNotEmpty);
    expect(planned, 0);
    expect(ImalatBlockTemplate.isUntouchedGenerated(blocks), isTrue);
  });
}
