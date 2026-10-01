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
  static const _bootDuration = Duration(milliseconds: 1600);

  late final AnimationController _boot;
  late final AnimationController _reveal;
  late final Animation<double> _bootProgress;

  @override
  void initState() {
    super.initState();
    _boot = AnimationController(vsync: this, duration: _bootDuration);
    _bootProgress = CurvedAnimation(parent: _boot, curve: Curves.easeInOut);
    _boot.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        context.go('/home');
      }
    });
    _reveal = AnimationController(vsync: this, duration: const Duration(milliseconds: 700))..forward();
    _boot.forward();
  }

  @override
  void dispose() {
    _boot.dispose();
    _reveal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final boltSize = (screenWidth * 0.65).clamp(240.0, 380.0);
    final wordmarkWidth = (screenWidth * 0.74).clamp(260.0, 340.0);
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
                                    fontSize: 34,
                                    fontWeight: FontWeight.w700,
                                    height: 1.1,
                                    color: ProColors.electricBlue,
                                    letterSpacing: 4,
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
                    animation: _bootProgress,
                    builder: (context, child) {
                      final fill = _bootProgress.value.clamp(0.0, 1.0);
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: SizedBox(
                          width: 130,
                          height: 4,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              const ColoredBox(color: ProColors.border),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: FractionallySizedBox(
                                  widthFactor: fill,
                                  heightFactor: 1,
                                  child: const DecoratedBox(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [ProColors.electricBlue, ProColors.electricBlueLight],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
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

  static const _spacing = 24.0;
  static const _majorEvery = 4;
  static const _minorColor = Color(0x1F4876DC);
  static const _majorColor = Color(0x384877DC);

  @override
  void paint(Canvas canvas, Size size) {
    final minor = Paint()
      ..color = _minorColor
      ..strokeWidth = 0.65;
    final major = Paint()
      ..color = _majorColor
      ..strokeWidth = 1;

    var index = 0;
    for (var x = 0.0; x <= size.width; x += _spacing, index++) {
      final p = index % _majorEvery == 0 ? major : minor;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
    }
    index = 0;
    for (var y = 0.0; y <= size.height; y += _spacing, index++) {
      final p = index % _majorEvery == 0 ? major : minor;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
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
