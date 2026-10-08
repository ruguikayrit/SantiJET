import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:santijet_pro/features/dashboard/dashboard_screen.dart';

void main() {
  testWidgets('şantiye resmi kare kırpılarak kaydedilir', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final png = await tester.runAsync(() async {
      final kayit = ui.PictureRecorder();
      final tuval = Canvas(kayit);
      tuval.drawRect(const Rect.fromLTWH(0, 0, 40, 20), Paint()..color = const Color(0xFFFF0000));
      tuval.drawRect(const Rect.fromLTWH(40, 0, 40, 20), Paint()..color = const Color(0xFF0000FF));
      final kaynak = await kayit.endRecording().toImage(80, 20);
      final veri = await kaynak.toByteData(format: ui.ImageByteFormat.png);
      kaynak.dispose();
      return veri!.buffer.asUint8List();
    });

    Uint8List? sonuc;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return TextButton(
              onPressed: () async {
                sonuc = await Navigator.of(context).push<Uint8List>(
                  MaterialPageRoute(builder: (context) => kareKirpEkrani(png!)),
                );
              },
              child: const Text('aç'),
            );
          },
        ),
      ),
    );
    await tester.tap(find.text('aç'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
    await tester.pump();

    expect(find.text('Kare kırp'), findsOneWidget);
    expect(find.byKey(const Key('proje-resim-kirp-kaydet')), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const Key('proje-resim-kirp-kaydet')));
    await tester.pump();
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    final kayit = sonuc;
    expect(kayit, isNotNull);
    final kirpik = await tester.runAsync(() => decodeImageFromList(kayit!));
    expect(kirpik!.width, kirpik.height);
    expect(kirpik.width, greaterThan(0));
    kirpik.dispose();
  });
}
