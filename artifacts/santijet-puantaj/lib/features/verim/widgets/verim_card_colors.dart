import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Verim imalat kartları — yumuşak, birbirinden ayrık arka plan tonları.
abstract final class VerimCardColors {
  static const _lightTints = [
    Color(0xFFE8EFFA), // soft slate blue
    Color(0xFFE5F2EC), // soft sage
    Color(0xFFEDE8F7), // soft lavender
    Color(0xFFF3EDE4), // soft sand
    Color(0xFFF8EBEB), // soft blush
  ];

  static const _darkTints = [
    Color(0xFF1C2433), // muted blue-gray
    Color(0xFF1A2A26), // muted teal-gray
    Color(0xFF252033), // muted purple-gray
    Color(0xFF2A2620), // muted warm gray
    Color(0xFF2A2224), // muted rose-gray
  ];

  static List<Color> get palette =>
      AppColors.useDarkCards ? _darkTints : _lightTints;

  static Color at(int index) => palette[index % palette.length];
}
