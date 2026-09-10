import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../ui/design_system.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? timer;

  @override
  void initState() {
    super.initState();
    timer = Timer(const Duration(milliseconds: 1300), () {
      if (mounted) context.go('/');
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.navy,
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const BoltMark(size: 76),
          const SizedBox(height: 24),
          const Text(
            'ŞantiJET',
            style: TextStyle(
              color: Colors.white,
              fontFamily: AppTypography.displayFont,
              fontSize: 42,
              fontWeight: FontWeight.w700,
              letterSpacing: -.5,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'İŞ PROGRAMI',
            style: TextStyle(
              color: AppColors.electricBlue,
              fontFamily: AppTypography.displayFont,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: 4,
            ),
          ),
          const SizedBox(height: 34),
          SizedBox(
            width: 112,
            child: LinearProgressIndicator(
              minHeight: 3,
              backgroundColor: Colors.white12,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ],
      ),
    ),
  );
}
