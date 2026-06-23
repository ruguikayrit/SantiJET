import 'package:flutter/material.dart';

/// ŞantiJET animasyon süreleri ve eğrileri — Demir referansından birebir.
abstract final class AppAnimations {
  static const fast = Duration(milliseconds: 200);
  static const normal = Duration(milliseconds: 300);
  static const slow = Duration(milliseconds: 450);

  static const curve = Curves.easeOutCubic;
  static const enterCurve = Curves.easeOut;
  static const exitCurve = Curves.easeIn;
}

/// Liste öğeleri için kademeli fade + slide animasyonu (Demir `StaggeredFadeIn`).
///
/// Faz 7 listelerinde kullanılacaktır.
class StaggeredFadeIn extends StatefulWidget {
  const StaggeredFadeIn({
    required this.index,
    required this.child,
    this.baseDelay = const Duration(milliseconds: 40),
    super.key,
  });

  final int index;
  final Widget child;
  final Duration baseDelay;

  @override
  State<StaggeredFadeIn> createState() => _StaggeredFadeInState();
}

class _StaggeredFadeInState extends State<StaggeredFadeIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: AppAnimations.normal);
    _opacity =
        CurvedAnimation(parent: _controller, curve: AppAnimations.enterCurve);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: AppAnimations.curve));

    Future<void>.delayed(widget.baseDelay * widget.index, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}
