import 'package:flutter_test/flutter_test.dart';
import 'package:santijet_demir/core/theme/app_colors.dart';

void main() {
  test('diameter color mapping works', () {
    expect(AppColors.diameterColor(12), AppColors.diameter12);
  });
}
