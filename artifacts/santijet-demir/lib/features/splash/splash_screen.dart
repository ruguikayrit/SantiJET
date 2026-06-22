import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:santijet_demir/core/routing/app_routes.dart';
import 'package:santijet_demir/core/theme/app_colors.dart';
import 'package:santijet_demir/core/theme/app_shadows.dart';
import 'package:santijet_demir/core/theme/app_spacing.dart';
import 'package:santijet_demir/core/theme/app_typography.dart';

/// Figma Make v16 — Splash ekranı spesifikasyonları.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _loadingController;

  @override
  void initState() {
    super.initState();
    _loadingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    Timer(const Duration(milliseconds: 2800), () {
      if (mounted) context.go(AppRoutes.dashboard);
    });
  }

  @override
  void dispose() {
    _loadingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: Stack(
        children: [
          // Blueprint grid arka plan
          Positioned.fill(
            child: CustomPaint(
              painter: _BlueprintGridPainter(),
            ),
          ),
          // Rebar overlay
          Positioned.fill(
            child: Opacity(
              opacity: 0.04,
              child: CustomPaint(
                painter: _RebarOverlayPainter(),
              ),
            ),
          ),
          // Logo glow
          Positioned(
            top: AppSpacing.splashContentTop - 80,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 300,
                height: 270,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.electricBlue.withValues(alpha: 0.10),
                      AppColors.electricBlue.withValues(alpha: 0.04),
                      AppColors.electricBlue.withValues(alpha: 0.01),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.35, 0.65, 1.0],
                  ),
                ),
              ),
            ),
          ),
          // İçerik
          SafeArea(
            child: Column(
              children: [
                SizedBox(height: AppSpacing.splashContentTop - MediaQuery.of(context).padding.top),
                // S Logo — 284px (Figma)
                Image.asset(
                  'assets/images/s_logo.png',
                  width: 142,
                  height: 142,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: AppSpacing.splashLogoToWordmark),
                // ŞANTİJET wordmark — 234px genişlik, OPERASYON kırpılmış
                ClipRect(
                  child: Align(
                    alignment: Alignment.topCenter,
                    heightFactor: 0.55,
                    child: Image.asset(
                      'assets/images/wordmark.png',
                      width: 234,
                      fit: BoxFit.fitWidth,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.splashWordmarkToDemir),
                // DEMİR — Rajdhani 700, 40px, Electric Blue
                Text('DEMİR', style: AppTypography.displayLarge),
                const SizedBox(height: AppSpacing.splashDemirToTagline),
                // ÇELİK TAKİP SİSTEMİ — Inter 12px
                Text(
                  'ÇELİK TAKİP SİSTEMİ',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textPrimary.withValues(alpha: 0.30),
                    letterSpacing: 4.2,
                  ),
                ),
                const Spacer(),
                // Loading bar — 130px × 4px
                AnimatedBuilder(
                  animation: _loadingController,
                  builder: (context, child) {
                    return Container(
                      width: 130,
                      height: 4,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        color: AppColors.border,
                        boxShadow: AppShadows.loadingBarGlow,
                      ),
                      child: Align(
                        alignment: Alignment(_loadingController.value * 2 - 1, 0),
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(2),
                            gradient: const LinearGradient(
                              colors: [
                                AppColors.electricBlue,
                                AppColors.electricBlueLight,
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                SizedBox(height: AppSpacing.splashBottomSafe),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BlueprintGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.blueprintGrid
      ..strokeWidth = 0.5;

    const spacing = 24.0;
    for (var x = 0.0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 0.0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _RebarOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.rebarOverlay
      ..strokeWidth = 2;

    for (var i = 0; i < 6; i++) {
      final y = size.height * 0.15 + i * 80;
      canvas.drawLine(Offset(0, y), Offset(size.width, y + 40), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
