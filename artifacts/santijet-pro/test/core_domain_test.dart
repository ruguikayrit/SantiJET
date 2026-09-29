import 'package:flutter_test/flutter_test.dart';
import 'package:santijet_pro/core/access/home_summary_visibility.dart';
import 'package:santijet_pro/core/domain/project.dart';
import 'package:santijet_pro/core/domain/project_progress.dart';
import 'package:santijet_pro/core/domain/unit.dart';
import 'package:santijet_pro/core/domain/work_item.dart';

void main() {
  test('proje yalnız ortak kimliği tutar', () {
    const project = Project(
      id: 'p1',
      code: 'SJ-01',
      name: 'A Blok',
      company: 'SantiJET',
    );
    expect(project.code, 'SJ-01');
    expect(project.name, 'A Blok');
  });

  test('birim serbest metinden eşlenir', () {
    expect(MeasureUnit.parse('m³'), MeasureUnit.m3);
    expect(MeasureUnit.parse('m2'), MeasureUnit.m2);
    expect(MeasureUnit.parse('ton'), MeasureUnit.ton);
    expect(MeasureUnit.parse('adam-gün'), MeasureUnit.adamGun);
    expect(MeasureUnit.parse('saat'), MeasureUnit.saat);
    expect(MeasureUnit.parse('palet'), isNull);
  });

  test('iş kalemi plan tutarı miktar çarpı fiyattır', () {
    const item = WorkItem(
      id: 'w1',
      projectId: 'p1',
      name: 'C35/40 Beton',
      category: 'C35/40',
      kind: WorkItemKind.beton,
      unit: MeasureUnit.m3,
      plannedQty: 1250,
      unitPrice: 3500,
    );
    expect(item.plannedAmount, 4375000);
    expect(item.actualQty, 0);
    expect(item.remainingQty, 1250);
    expect(item.progress, 0);
  });

  test('yapılan miktar kalanı ve oranı günceller', () {
    const item = WorkItem(
      id: 'w2',
      projectId: 'p1',
      name: 'Ø16 Nervürlü Donatı',
      kind: WorkItemKind.donati,
      unit: MeasureUnit.ton,
      plannedQty: 185,
      actualQty: 12,
    );
    expect(item.remainingQty, 173);
    expect(item.progress, closeTo(12 / 185, 0.0001));
  });

  test('genel proje ilerlemesi plan ve kayıtlardan hesaplanır', () {
    final snapshot = DemoProjectProgress.snapshot(DateTime(2026, 9, 29));
    expect(snapshot.elapsedDays, 212);
    expect(snapshot.sureLabel, '212 gün');
    expect(snapshot.metrajLabel, '%62');
    expect(snapshot.adamGunLabel, '4.180');
    expect(snapshot.durationProgress, closeTo(212 / 365, 0.001));
    expect(snapshot.adamGunProgress, closeTo(4180 / 7200, 0.001));
    expect(snapshot.metrajProgress, closeTo(0.62, 0.001));
  });

  test('ana sayfa özet görünürlüğü bölüm kimliği ile seçilir', () {
    const kapaliFinans = HomeSummaryVisibility(finansalOzet: false);
    expect(kapaliFinans.shows(HomeSummarySection.finansalOzet), isFalse);
    expect(kapaliFinans.shows(HomeSummarySection.teknikOzet), isTrue);
    expect(HomeSummaryVisibility.forRole(null).finansalOzet, isTrue);
  });

  test('plan miktarı yoksa oran sıfırdır', () {
    const item = WorkItem(
      id: 'w3',
      projectId: 'p1',
      name: 'Kazı',
      unit: MeasureUnit.m3,
    );
    expect(item.progress, 0);
    expect(item.plannedAmount, 0);
  });
}
