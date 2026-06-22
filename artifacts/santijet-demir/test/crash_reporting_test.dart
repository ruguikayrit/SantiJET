import 'package:flutter_test/flutter_test.dart';
import 'package:santijet_demir/core/crash/crash_reporting_service.dart';
import 'package:santijet_demir/core/responsive/responsive_layout.dart';
import 'package:flutter/material.dart';

void main() {
  group('CrashReportingService', () {
    test('singleton instance exists', () {
      expect(CrashReportingService.instance, isNotNull);
    });
  });

  group('ResponsiveLayout', () {
    testWidgets('isTablet returns false on phone width', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(390, 844)),
            child: Builder(
              builder: (context) {
                expect(ResponsiveLayout.isTablet(context), isFalse);
                return const SizedBox();
              },
            ),
          ),
        ),
      );
    });

    testWidgets('isTablet returns true on tablet width', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(768, 1024)),
            child: Builder(
              builder: (context) {
                expect(ResponsiveLayout.isTablet(context), isTrue);
                return const SizedBox();
              },
            ),
          ),
        ),
      );
    });
  });
}
