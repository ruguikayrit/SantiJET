import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:santijet_bfa/core/theme/app_theme.dart';
import 'package:santijet_bfa/features/legal/legal_document_screen.dart';
import 'package:santijet_bfa/features/legal/sources_screen.dart';

Widget _host(Widget child) => MaterialApp(theme: AppTheme.light, home: child);

void main() {
  testWidgets('Gizlilik politikası bölümleri görünür', (tester) async {
    await tester
        .pumpWidget(_host(const LegalDocumentScreen(documentId: 'privacy')));
    await tester.pump();

    expect(find.text('Gizlilik Politikası'), findsWidgets);
    expect(find.text('Toplanan Veriler'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await tester.pump();
    expect(find.text('Resmi Kurumlarla İlişki'), findsOneWidget);
  });

  testWidgets('Kullanım koşulları bölümleri görünür', (tester) async {
    await tester
        .pumpWidget(_host(const LegalDocumentScreen(documentId: 'terms')));
    await tester.pump();

    expect(find.text('Kullanım Koşulları'), findsWidgets);
    expect(find.text('Doğruluk Sorumluluğu'), findsOneWidget);
  });

  testWidgets('Kaynak kartları görünür', (tester) async {
    await tester.pumpWidget(_host(const SourcesScreen()));
    await tester.pump();

    expect(find.text('Kaynaklar'), findsWidgets);
    expect(find.text('Veri Doğrulama'), findsOneWidget);
    expect(find.text('İnşaat Birim Fiyat ve Analizleri'), findsOneWidget);
  });
}
