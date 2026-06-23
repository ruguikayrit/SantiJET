import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:santijet_bfa/app.dart';

void main() {
  testWidgets('Uygulama açılır, ana sayfa ve alt navigasyon görünür',
      (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: SantijetBfaApp()),
    );
    await tester.pumpAndSettle();

    // AppBar başlığı
    expect(find.text('ŞantiJET BFA'), findsWidgets);
    // Alt navigasyon sekmeleri
    expect(find.text('Ana Sayfa'), findsOneWidget);
    expect(find.text('Katalog'), findsOneWidget);
    expect(find.text('Keşif'), findsOneWidget);
    expect(find.text('Ayarlar'), findsOneWidget);
  });

  testWidgets('Katalog sekmesine geçiş çalışır', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: SantijetBfaApp()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Katalog'));
    await tester.pumpAndSettle();

    // Katalog → AnalizListScreen (PhasePlaceholder başlığı)
    expect(find.text('Analiz Listesi'), findsWidgets);
  });
}
