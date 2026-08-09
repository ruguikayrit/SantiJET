import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../animations/app_animations.dart';

/// go_router sayfa geçişleri — yatay kaydırma jesti yok (pop gesture kapalı).

/// Fade + hafif slide (yalnızca animasyon; jest ile pop yok).
CustomTransitionPage<T> fadeSlidePage<T>({
  required LocalKey key,
  required Widget child,
}) {
  return _NoSwipeTransitionPage<T>(
    key: key,
    child: child,
    transitionDuration: AppAnimations.normal,
    reverseTransitionDuration: AppAnimations.fast,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: AppAnimations.curve,
        reverseCurve: AppAnimations.exitCurve,
      );
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.02),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}

CustomTransitionPage<T> fadePage<T>({
  required LocalKey key,
  required Widget child,
}) {
  return _NoSwipeTransitionPage<T>(
    key: key,
    child: child,
    transitionDuration: AppAnimations.normal,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurvedAnimation(
          parent: animation,
          curve: AppAnimations.enterCurve,
        ),
        child: child,
      );
    },
  );
}

/// [CustomTransitionPage] + iOS/Web kenar kaydırarak geri jesti kapalı.
class _NoSwipeTransitionPage<T> extends CustomTransitionPage<T> {
  const _NoSwipeTransitionPage({
    required super.child,
    required super.transitionsBuilder,
    super.transitionDuration,
    super.reverseTransitionDuration,
    super.key,
  });

  @override
  Route<T> createRoute(BuildContext context) =>
      _NoSwipeTransitionPageRoute<T>(this);
}

class _NoSwipeTransitionPageRoute<T> extends PageRoute<T> {
  _NoSwipeTransitionPageRoute(_NoSwipeTransitionPage<T> page)
      : super(settings: page);

  _NoSwipeTransitionPage<T> get _page =>
      settings as _NoSwipeTransitionPage<T>;

  @override
  bool get barrierDismissible => _page.barrierDismissible;

  @override
  Color? get barrierColor => _page.barrierColor;

  @override
  String? get barrierLabel => _page.barrierLabel;

  @override
  Duration get transitionDuration => _page.transitionDuration;

  @override
  Duration get reverseTransitionDuration => _page.reverseTransitionDuration;

  @override
  bool get maintainState => _page.maintainState;

  @override
  bool get fullscreenDialog => _page.fullscreenDialog;

  @override
  bool get opaque => _page.opaque;

  /// Kenardan kaydırarak pop / sayfa değişimi yok.
  @override
  bool get popGestureEnabled => false;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) =>
      Semantics(
        scopesRoute: true,
        explicitChildNodes: true,
        child: _page.child,
      );

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) =>
      _page.transitionsBuilder(
        context,
        animation,
        secondaryAnimation,
        child,
      );
}
