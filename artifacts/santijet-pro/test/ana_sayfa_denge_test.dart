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

  for (final genislik in [360.0, 390.0]) {
    testWidgets('durum ve verim $genislik dengeli', (tester) async {
      tester.view.physicalSize = Size(genislik, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const SantijetProApp());
      await tester.pump(const Duration(milliseconds: 1700));
      await tester.pumpAndSettle();

      for (final baslik in [
        'Proje Durumu',
        'Şantiye Verimi',
        'Planlanan',
        'Gerçekleşen',
        'Sapma',
        'Genel İlerleme',
        'Genel\nVerim',
        'İşçilik',
        'Makine',
        'Malzeme',
        'Zaman',
        'Maliyet',
        'Plan',
        'İmalat Kaydı',
        'Malzeme',
        'Bugün ve Yaklaşan İşler',
      ]) {
        final bulunan = find.text(baslik);
        expect(bulunan, findsWidgets, reason: baslik);
        for (var i = 0; i < bulunan.evaluate().length; i++) {
          final yazi = tester.renderObject<RenderParagraph>(bulunan.at(i));
          expect(yazi.didExceedMaxLines, isFalse, reason: '$genislik $baslik');
        }
      }

      final halkalar = find.byType(CustomPaint).evaluate().map((e) => tester.getSize(find.byWidget(e.widget))).where((boy) => boy.width == boy.height && boy.width >= 48).toList();
      expect(halkalar.length, greaterThanOrEqualTo(3));
      final kartHalkalari = halkalar.where((boy) => boy.width == 60).toList();
      expect(kartHalkalari.length, 2, reason: 'iki kart halkası aynı boy');
      expect(tester.getSize(find.byKey(const Key('proje-resim-ekle'))).width, 100);
      final projeKart = tester.getSize(find.byKey(const Key('proje-durumu-kart')));
      final verimKart = tester.getSize(find.byKey(const Key('santiye-verimi-kart')));
      expect(projeKart.height, verimKart.height);
      final verimBaslik = tester.renderObject<RenderParagraph>(find.text('Şantiye Verimi'));
      expect(verimBaslik.computeMaxIntrinsicHeight(1000), greaterThanOrEqualTo(verimBaslik.size.height - 1));
      expect(find.text('Geçen aya göre'), findsNothing);
      expect(find.text('Detay'), findsNothing);
      expect(find.text('Az Veri. Çok Verim.'), findsNothing);
      final genel = tester.renderObject<RenderParagraph>(find.text('Genel\nVerim'));
      final olcu = TextPainter(text: genel.text, textDirection: TextDirection.ltr, maxLines: 2)..layout(maxWidth: genel.size.width);
      expect(olcu.computeLineMetrics().length, 2);
      expect(tester.getTopLeft(find.text('Puantaj')).dx, lessThan(tester.getTopLeft(find.text('İmalat Kaydı')).dx));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('menüde lisans dar, proje tek satır', (tester) async {
    tester.view.physicalSize = const Size(360, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const SantijetProApp());
    await tester.pump(const Duration(milliseconds: 1700));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Menü'));
    await tester.pumpAndSettle();

    final proje = tester.getSize(find.byKey(const Key('menu-aktif-proje')));
    final lisans = tester.getSize(find.byKey(const Key('menu-lisans')));
    expect(lisans.width, lessThan(proje.width * 0.55));
    expect(lisans.height, proje.height);
    final ad = tester.renderObject<RenderParagraph>(
      find.descendant(of: find.byKey(const Key('menu-aktif-proje')), matching: find.text('İstanbul Residence')),
    );
    expect(ad.didExceedMaxLines, isFalse);
    expect(ad.size.height, lessThanOrEqualTo(ad.computeMaxIntrinsicHeight(1000) + 1));
    await tester.tap(find.byKey(const Key('menu-lisans')));
    await tester.pumpAndSettle();
    expect(find.text('Paket Seçimi'), findsOneWidget);
    await tester.tap(find.byKey(const Key('paket-ekip')));
    await tester.tap(find.byKey(const Key('paket-onay')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Ekip paketi seçildi.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
