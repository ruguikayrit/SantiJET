import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:santijet_demir/features/survey/survey_list_screen.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', (message) async {
      final key = utf8.decode(message!.buffer.asUint8List());
      if (key == 'AssetManifest.json') {
        return ByteData.view(Uint8List.fromList(utf8.encode('{}')).buffer);
      }
      return null;
    });
  });

  testWidgets('yeni imalat penceresi kapanırken kırmızı ekran açmaz', (tester) async {
    String? created;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                created = await showDialog<String>(
                  context: context,
                  builder: (_) => const CreateImalatDialog(),
                );
              },
              child: const Text('Yeni Ekle'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Yeni Ekle'));
    await tester.pumpAndSettle();
    expect(find.text('Yeni İmalat'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '  Radye  ');
    await tester.tap(find.text('Oluştur'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(created, 'Radye');
    expect(find.text('Yeni İmalat'), findsNothing);
  });

  testWidgets('boş imalat adı pencereyi kapatmaz', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: CreateImalatDialog()),
    );

    await tester.tap(find.text('Oluştur'));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Yeni İmalat'), findsOneWidget);
  });
}
