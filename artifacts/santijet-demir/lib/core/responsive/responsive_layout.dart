import 'package:flutter/material.dart';

/// Tablet/desktop için içerik genişliğini sınırlar.
class ResponsiveLayout extends StatelessWidget {
  const ResponsiveLayout({
    super.key,
    required this.child,
    this.maxWidth = 720,
    this.phoneMaxWidth = double.infinity,
  });

  final Widget child;
  final double maxWidth;
  final double phoneMaxWidth;

  static bool isTablet(BuildContext context) {
    return MediaQuery.sizeOf(context).shortestSide >= 600;
  }

  static bool isLargeTablet(BuildContext context) {
    return MediaQuery.sizeOf(context).shortestSide >= 840;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final limit = isTablet(context) ? maxWidth : phoneMaxWidth;

    if (width <= limit) return child;

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: limit),
        child: child,
      ),
    );
  }
}
