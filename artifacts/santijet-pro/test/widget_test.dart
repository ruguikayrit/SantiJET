import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:santijet_pro/app.dart';
import 'package:santijet_pro/modules/pro_module.dart';

void main() {
  test('modül listesi Pro kararlarıyla uyumlu', () {
    final ids = ProModule.catalog.map((module) => module.id).toList();
    expect(ids, [
      'saha',
      'beton',
      'demir',
      'tahvil',
      'malzeme',
      'is-programi',
      'maliyet',
      'kasa',
    ]);
    expect(ids, isNot(contains('muhendis')));
    expect(ids, isNot(contains('celik')));
  });

  testWidgets('dashboard modülleri gösterir', (tester) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const SantijetProApp());
    expect(find.text('SAHA'), findsOneWidget);
    expect(find.text('KASA'), findsOneWidget);
    expect(find.text('TAHVİL'), findsOneWidget);
    expect(find.text('Çelik daha sonra eklenecek.'), findsOneWidget);
    expect(find.text('MÜHENDİS'), findsNothing);
  });

  testWidgets('modül kabuğu kaynak adresi açar ve geri döner', (tester) async {
    await tester.pumpWidget(const SantijetProApp());
    await tester.tap(find.byKey(const Key('module-demir')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('pro-return')), findsOneWidget);
    expect(
      find.text('https://ruguikayrit.github.io/SantiJET/demir/'),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('pro-return')));
    await tester.pumpAndSettle();
    expect(find.text('SAHA'), findsOneWidget);
  });
}
