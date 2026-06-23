import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:santijet_bfa/core/design_system/design_system.dart';
import 'package:santijet_bfa/core/theme/app_theme.dart';

Widget _host(Widget child) => MaterialApp(
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      home: Scaffold(body: child),
    );

void main() {
  testWidgets('SJButton etiketi ve dokunması çalışır', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      _host(SJButton(label: 'Kaydet', onPressed: () => tapped = true)),
    );
    expect(find.text('Kaydet'), findsOneWidget);
    await tester.tap(find.text('Kaydet'));
    expect(tapped, isTrue);
  });

  testWidgets('SJStatCard değer ve etiket gösterir', (tester) async {
    await tester.pumpWidget(
      _host(const SJStatCard(label: 'İnşaat', value: '1.879', unit: 'analiz')),
    );
    expect(find.text('İnşaat'), findsOneWidget);
    expect(find.text('1.879'), findsOneWidget);
  });

  testWidgets('SJEmptyState aksiyonu tetiklenir', (tester) async {
    var acted = false;
    await tester.pumpWidget(
      _host(SJEmptyState(
        title: 'Boş',
        message: 'Kayıt yok',
        actionLabel: 'Ekle',
        onAction: () => acted = true,
      )),
    );
    await tester.tap(find.text('Ekle'));
    expect(acted, isTrue);
  });

  testWidgets('SJListItem başlık ve alt başlık gösterir', (tester) async {
    await tester.pumpWidget(
      _host(const SJListItem(title: '15.225.1009', subtitle: 'Gazbeton duvar')),
    );
    expect(find.text('15.225.1009'), findsOneWidget);
    expect(find.text('Gazbeton duvar'), findsOneWidget);
  });
}
