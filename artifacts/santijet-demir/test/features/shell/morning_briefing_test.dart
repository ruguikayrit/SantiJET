import 'package:flutter_test/flutter_test.dart';
import 'package:santijet_demir/domain/entities/field_count.dart';
import 'package:santijet_demir/domain/entities/prediction_models.dart';
import 'package:santijet_demir/features/shell/morning_briefing.dart';

void main() {
  const builder = MorningBriefingBuilder();

  test('beş operasyon kaynağı ile günlük brifing', () {
    final briefing = builder.build(
      now: DateTime(2026, 7, 19, 8),
      displayName: 'Uğur Yılmaz',
      ops: DailyOpsBriefingInput(
        kesifTonnage: 120,
        gerceklesenImalat: 48,
        kalanImalat: 72,
        overallProgressPercent: 40,
        latestCount: FieldCountRecord(
          id: 'c1',
          title: 'Sayım 1',
          date: DateTime(2026, 7, 18),
          personnel: 'Ali',
          region: 'Blok A',
          expected: 55,
          actual: 52,
          status: 'completed',
          lines: const [
            FieldCountLineRecord(
              diameter: 16,
              delivered: 80,
              expectedStock: 40,
              plannedUsage: 40,
              actual: 38,
            ),
            FieldCountLineRecord(
              diameter: 12,
              delivered: 40,
              expectedStock: 15,
              plannedUsage: 25,
              actual: 14,
            ),
          ],
        ),
        reconciliation: const [
          ReconciliationRow(
            diameter: 16,
            survey: 100,
            ordered: 80,
            delivered: 80,
            plannedUsage: 40,
            expectedStock: 40,
            counted: 38,
            used: 42,
          ),
        ],
      ),
    );

    expect(briefing.greetingLine, 'Günaydın Uğur');
    expect(briefing.eyebrow, 'Günlük Brifing');
    expect(briefing.bullets[0], contains('Keşif'));
    expect(briefing.bullets[0], contains('120'));
    expect(briefing.bullets[1], contains('Gerçekleşen imalat'));
    expect(briefing.bullets[1], contains('48'));
    expect(briefing.bullets[1], contains('%40'));
    expect(briefing.bullets[2], contains('Kalan imalat'));
    expect(briefing.bullets[2], contains('72'));
    expect(briefing.bullets[3], contains('Demir stok'));
    expect(briefing.bullets[4], contains('Saha sayımı'));
    expect(briefing.bullets[4], contains('18.7.2026'));
  });

  test('keşif ve sayım yoksa boş durum mesajları', () {
    final briefing = builder.build(
      now: DateTime(2026, 7, 19, 15),
      displayName: 'Ali',
      ops: const DailyOpsBriefingInput(
        kesifTonnage: 0,
        gerceklesenImalat: 0,
        kalanImalat: 0,
        overallProgressPercent: 0,
      ),
    );

    expect(briefing.greetingLine, 'İyi günler Ali');
    expect(briefing.bullets.any((b) => b.contains('keşif tonajı')), isTrue);
    expect(briefing.bullets.any((b) => b.contains('saha sayımı yok')), isTrue);
    expect(briefing.tone, PredictionRiskLevel.unknown);
  });

  test('kritik fire risk satırı eklenir', () {
    final briefing = builder.build(
      now: DateTime(2026, 7, 19),
      displayName: 'Ali',
      ops: DailyOpsBriefingInput(
        kesifTonnage: 100,
        gerceklesenImalat: 40,
        kalanImalat: 60,
        overallProgressPercent: 40,
        latestCount: FieldCountRecord(
          id: 'c1',
          title: 'Sayım',
          date: DateTime(2026, 7, 19),
          personnel: 'Ali',
          region: 'A',
          expected: 30,
          actual: 20,
          status: 'completed',
        ),
        reconciliation: const [
          ReconciliationRow(
            diameter: 14,
            survey: 100,
            ordered: 80,
            delivered: 80,
            plannedUsage: 40,
            expectedStock: 40,
            counted: 30,
            used: 50,
          ),
        ],
      ),
    );

    expect(
      briefing.bullets.any((b) => b.contains('Ø14') && b.contains('fire')),
      isTrue,
    );
    expect(briefing.tone, PredictionRiskLevel.red);
  });

  test('aktif proje yok', () {
    final briefing = builder.build(
      now: DateTime(2026, 7, 19, 8),
      displayName: 'Uğur',
      hasActiveProject: false,
    );
    expect(briefing.bullets.first, contains('Aktif proje'));
  });
}
