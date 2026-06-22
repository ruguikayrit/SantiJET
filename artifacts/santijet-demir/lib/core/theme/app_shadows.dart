import 'package:flutter/material.dart';
import 'package:santijet_demir/core/theme/app_colors.dart';

/// Figma Make — 5 elevation seviyesi.
abstract final class AppShadows {
  static const level0 = <BoxShadow>[];

  static const level1 = [
    BoxShadow(
      color: Color(0x1A000000),
      blurRadius: 4,
      offset: Offset(0, 2),
    ),
  ];

  static const level2 = [
    BoxShadow(
      color: Color(0x26000000),
      blurRadius: 8,
      offset: Offset(0, 4),
    ),
  ];

  static const level3 = [
    BoxShadow(
      color: Color(0x33000000),
      blurRadius: 16,
      offset: Offset(0, 8),
    ),
  ];

  static const level4 = [
    BoxShadow(
      color: Color(0x40000000),
      blurRadius: 24,
      offset: Offset(0, 12),
    ),
  ];

  static const fabGlow = [
    BoxShadow(
      color: AppColors.electricBlueGlow,
      blurRadius: 20,
      spreadRadius: 2,
    ),
  ];

  static const loadingBarGlow = [
    BoxShadow(
      color: Color(0x660055FF),
      blurRadius: 8,
      spreadRadius: 1,
    ),
  ];
}
