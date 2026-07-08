import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// iOS Safari PWA'da MediaQuery safe area çoğu zaman 0 gelir; minimum inset uygular.
abstract final class AppSafeAreaInsets {
  static const _iosWebMinTop = 47.0;
  static const _iosWebMinBottom = 34.0;

  static bool _isIosWeb(BuildContext context) {
    if (!kIsWeb) return false;
    return Theme.of(context).platform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  static EdgeInsets effective(BuildContext context) {
    final media = MediaQuery.of(context);
    final view = media.viewPadding;
    final pad = media.padding;

    var top = math.max(view.top, pad.top);
    var bottom = math.max(view.bottom, pad.bottom);
    var left = math.max(view.left, pad.left);
    var right = math.max(view.right, pad.right);

    if (_isIosWeb(context)) {
      if (top < 20) top = _iosWebMinTop;
      if (bottom < 20) bottom = _iosWebMinBottom;
    }

    return EdgeInsets.fromLTRB(left, top, right, bottom);
  }

  static double topOf(BuildContext context) => effective(context).top;

  static double bottomOf(BuildContext context) => effective(context).bottom;
}

class AppSafeArea extends StatelessWidget {
  const AppSafeArea({
    super.key,
    required this.child,
    this.top = true,
    this.bottom = true,
    this.left = true,
    this.right = true,
  });

  final Widget child;
  final bool top;
  final bool bottom;
  final bool left;
  final bool right;

  @override
  Widget build(BuildContext context) {
    final insets = AppSafeAreaInsets.effective(context);
    return Padding(
      padding: EdgeInsets.only(
        top: top ? insets.top : 0,
        bottom: bottom ? insets.bottom : 0,
        left: left ? insets.left : 0,
        right: right ? insets.right : 0,
      ),
      child: child,
    );
  }
}
