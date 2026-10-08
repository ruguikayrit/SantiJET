import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:santijet_pro/app.dart';

Future<void> _yaziYukle() async {
  final inter = FontLoader('Inter')..addFont(rootBundle.load('assets/fonts/Inter-Variable.ttf'));
  final rajdhani = FontLoader('Rajdhani')
    ..addFont(rootBundle.load('assets/fonts/Rajdhani-Regular.ttf'))
    ..addFont(rootBundle.load('assets/fonts/Rajdhani-Bold.ttf'));
  await inter.load();
  await rajdhani.load();
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await _yaziYukle();
  });

  for (final genislik in [360.0, 390.0, 800.0]) {
    testWidgets('verim kartları $genislik net okunur', (tester) async {
      tester.view.physicalSize = Size(genislik, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const SantijetProApp());
      await tester.pump(const Duration(milliseconds: 1700));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Raporlar'));
      await tester.pumpAndSettle();

      expect(find.text('%87'), findsOneWidget);
      expect(find.text('Genel Verim'), findsOneWidget);
      for (final baslik in ['İşçilik Verimi', 'Makine Verimi', 'Malzeme Verimi', 'Zaman Verimi', 'Maliyet Verimi', 'Plan Gerçekleşme', 'Genel Verim', 'Geçen aya göre']) {
        final yazi = tester.renderObject<RenderParagraph>(find.text(baslik));
        expect(yazi.didExceedMaxLines, isFalse, reason: '$genislik $baslik');
      }
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('gün seçiminde aylık kıyas kapalı', (tester) async {
    tester.view.physicalSize = const Size(390, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const SantijetProApp());
    await tester.pump(const Duration(milliseconds: 1700));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Raporlar'));
    await tester.pumpAndSettle();

    expect(find.text('%87'), findsOneWidget);
    expect(find.text('Geçen aya göre'), findsOneWidget);
    expect(find.text('%8'), findsOneWidget);

    final simdi = DateTime.now();
    const aylar = ['OCAK', 'ŞUBAT', 'MART', 'NİSAN', 'MAYIS', 'HAZİRAN', 'TEMMUZ', 'AĞUSTOS', 'EYLÜL', 'EKİM', 'KASIM', 'ARALIK'];
    await tester.tap(find.text('${aylar[simdi.month - 1]} ${simdi.year}'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('rapor-tarih-ay')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('rapor-tarih-ay-9')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(Key('rapor-tarih-gun-${simdi.year}-9-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('rapor-tarih-ok')));
    await tester.pumpAndSettle();

    expect(find.text('1 EYLÜL ${simdi.year}'), findsOneWidget);
    expect(find.text('Geçen aya göre'), findsNothing);
    expect(find.text('%8'), findsNothing);
    expect(find.text('%87'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ayı tümü, aralığı OK onaylar', (tester) async {
    tester.view.physicalSize = const Size(390, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const SantijetProApp());
    await tester.pump(const Duration(milliseconds: 1700));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Raporlar'));
    await tester.pumpAndSettle();

    final simdi = DateTime.now();
    const aylar = ['OCAK', 'ŞUBAT', 'MART', 'NİSAN', 'MAYIS', 'HAZİRAN', 'TEMMUZ', 'AĞUSTOS', 'EYLÜL', 'EKİM', 'KASIM', 'ARALIK'];
    final buAy = '${aylar[simdi.month - 1]} ${simdi.year}';
    await tester.tap(find.text(buAy));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('rapor-tarih-tumu')));
    await tester.pumpAndSettle();
    expect(find.text(buAy), findsOneWidget);
    expect(find.text('Geçen aya göre'), findsOneWidget);

    await tester.tap(find.text(buAy));
    await tester.pumpAndSettle();
    var yil = simdi.year;
    var ay = simdi.month;
    if (simdi.day < 2) {
      await tester.tap(find.byKey(const Key('rapor-tarih-geri')));
      await tester.pumpAndSettle();
      final once = DateTime(simdi.year, simdi.month - 1, 1);
      yil = once.year;
      ay = once.month;
    }
    await tester.tap(find.byKey(Key('rapor-tarih-gun-$yil-$ay-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(Key('rapor-tarih-gun-$yil-$ay-2')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('rapor-tarih-ok')));
    await tester.pumpAndSettle();
    expect(find.text('1-2 ${aylar[ay - 1]} $yil'), findsOneWidget);
    expect(find.text('Geçen aya göre'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
