import 'package:flutter_test/flutter_test.dart';
import 'package:santijet_demir/core/theme/app_colors.dart';

void main() {
  group('AppColors.diameterColor', () {
    test('returns correct color for known diameters', () {
      expect(AppColors.diameterColor(8), AppColors.diameter8);
      expect(AppColors.diameterColor(16), AppColors.diameter16);
      expect(AppColors.diameterColor(28), AppColors.diameter28);
    });

    test('returns fallback for unknown diameter', () {
      expect(AppColors.diameterColor(99), AppColors.electricBlueLight);
    });
  });
}
