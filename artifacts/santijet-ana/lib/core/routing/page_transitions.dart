import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../animations/app_animations.dart';

CustomTransitionPage<T> fadePage<T>({
  required LocalKey key,
  required Widget child,
}) {
  return CustomTransitionPage<T>(
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
