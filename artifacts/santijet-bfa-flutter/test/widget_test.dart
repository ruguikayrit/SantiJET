import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:santijet_bfa/app/app.dart';

void main() {
  testWidgets('Uygulama açılır ve ana sayfa görünür', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: SantijetBfaApp()),
    );
    await tester.pump();

    expect(find.text('ŞantiJET BFA'), findsWidgets);
  });
}
