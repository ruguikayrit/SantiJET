import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/pro_theme.dart';

/// ŞantiJET Pro açılışı. Diğer ürünlerle aynı düzen: ızgara, şimşek, wordmark, ürün adı.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  static const _wordmarkAspect = 895 / 150;
  static const _boltWordmarkGap = 28.0;

  late final AnimationController _loading;
  late final AnimationController _reveal;

  @override
  void initState() {
    super.initState();
    _loading = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..repeat();
    _reveal = AnimationController(vsync: this, duration: const Duration(milliseconds: 700))..forward();
    _openHome();
  }

  Future<void> _openHome() async {
    await Future<void>.delayed(const Duration(milliseconds: 1600));
    if (!mounted) return;
    context.go('/home');
  }

  @override
  void dispose() {
    _loading.dispose();
    _reveal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final boltSize = (screenWidth * 0.76).clamp(280.0, 440.0);
    final wordmarkWidth = (screenWidth * 0.78).clamp(260.0, 360.0);
    final wordmarkHeight = wordmarkWidth / _wordmarkAspect;

    return Scaffold(
      backgroundColor: ProColors.canvas,
      body: ColoredBox(
        color: ProColors.canvas,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const CustomPaint(painter: _BlueprintGridPainter()),
            const Opacity(opacity: 0.04, child: CustomPaint(painter: _RebarOverlayPainter())),
            SafeArea(
              bottom: false,
              child: Column(
                children: [
                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(height: _boltWordmarkGap * 0.35),
                              FadeTransition(
                                opacity: CurvedAnimation(parent: _reveal, curve: const Interval(0, 0.45, curve: Curves.easeOut)),
                                child: Image.asset(
                                  'assets/images/splash_bolt.png',
                                  width: boltSize,
                                  height: boltSize,
                                  fit: BoxFit.contain,
                                  filterQuality: FilterQuality.high,
                                ),
                              ),
                              SizedBox(height: _boltWordmarkGap * 0.3),
                              FadeTransition(
                                opacity: CurvedAnimation(parent: _reveal, curve: const Interval(0.25, 0.7, curve: Curves.easeOut)),
                                child: Image.asset(
                                  'assets/images/splash_wordmark.png',
                                  width: wordmarkWidth,
                                  height: wordmarkHeight,
                                  fit: BoxFit.contain,
                                  filterQuality: FilterQuality.high,
                                ),
                              ),
                              const SizedBox(height: 30),
                              FadeTransition(
                                opacity: CurvedAnimation(parent: _reveal, curve: const Interval(0.5, 1, curve: Curves.easeOut)),
                                child: const Text(
                                  'PRO',
                                  style: TextStyle(
                                    fontFamily: 'Rajdhani',
                                    fontSize: 37,
                                    fontWeight: FontWeight.w700,
                                    height: 1.1,
                                    color: ProColors.electricBlue,
                                    letterSpacing: 6,
                                    shadows: [
                                      Shadow(color: ProColors.electricBlueGlow, blurRadius: 24),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  AnimatedBuilder(
                    animation: _loading,
                    builder: (context, child) {
                      return Container(
                        width: 130,
                        height: 4,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                          color: ProColors.border,
                          boxShadow: const [
                            BoxShadow(color: Color(0x660055FF), blurRadius: 8, spreadRadius: 1),
                          ],
                        ),
                        child: Align(
                          alignment: Alignment(_loading.value * 2 - 1, 0),
                          child: Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(2),
                              gradient: const LinearGradient(
                                colors: [ProColors.electricBlue, ProColors.electricBlueLight],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  SizedBox(height: MediaQuery.viewPaddingOf(context).bottom + 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BlueprintGridPainter extends CustomPainter {
  const _BlueprintGridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = ProColors.blueprintGrid
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
  const _RebarOverlayPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x0AFFFFFF)
      ..strokeWidth = 2;
    for (var i = 0; i < 6; i++) {
      final y = size.height * 0.15 + i * 80;
      canvas.drawLine(Offset(0, y), Offset(size.width, y + 40), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
