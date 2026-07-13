import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:santijet_demir/core/responsive/app_safe_area_inset_web.dart'
    if (dart.library.io) 'package:santijet_demir/core/responsive/app_safe_area_inset_io.dart'
    as inset_reader;

/// iOS Safari PWA'da MediaQuery safe area çoğu zaman 0 gelir; minimum inset uygular.
abstract final class AppSafeAreaInsets {
  static const _iosWebMinTop = 47.0;
  static const _iosWebMinBottom = 34.0;

  static bool _isIosWeb(BuildContext context) {
    if (!kIsWeb) return false;
    return Theme.of(context).platform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  static double _readBottomInset(BuildContext context, {required bool standaloneMinimum}) {
    final media = MediaQuery.of(context);
    var bottom = math.max(media.viewPadding.bottom, media.padding.bottom);

    if (!_isIosWeb(context)) return bottom;

    if (standaloneMinimum && inset_reader.readIosStandalonePwa()) {
      final injectedBottom = inset_reader.readWebSafeAreaBottomInset();
      if (injectedBottom != null && injectedBottom > 0) {
        bottom = math.max(bottom, injectedBottom);
      }
      if (bottom < 20) bottom = _iosWebMinBottom;
    }

    return bottom;
  }

  static EdgeInsets effective(BuildContext context) {
    final media = MediaQuery.of(context);
    final view = media.viewPadding;
    final pad = media.padding;

    var top = math.max(view.top, pad.top);
    var bottom = _readBottomInset(context, standaloneMinimum: true);
    var left = math.max(view.left, pad.left);
    var right = math.max(view.right, pad.right);

    if (_isIosWeb(context)) {
      if (top < 20) top = _iosWebMinTop;
    }

    return EdgeInsets.fromLTRB(left, top, right, bottom);
  }

  static double topOf(BuildContext context) => effective(context).top;

  static double bottomOf(BuildContext context) => effective(context).bottom;

  /// MediaQuery'ye zaten yansıtılmış inset'leri tekrar eklemez.
  static EdgeInsets remaining(BuildContext context) {
    final target = effective(context);
    final pad = MediaQuery.of(context).padding;
    return EdgeInsets.fromLTRB(
      math.max(0, target.left - pad.left),
      math.max(0, target.top - pad.top),
      math.max(0, target.right - pad.right),
      math.max(0, target.bottom - pad.bottom),
    );
  }

  /// Alt nav bar — home indicator alanı (View padding + iOS PWA JS probe).
  static double bottomNavInsetOf(BuildContext context) {
    final view = View.of(context);
    var bottom = view.padding.bottom / view.devicePixelRatio;

    if (kIsWeb && _isIosWeb(context) && inset_reader.readIosStandalonePwa()) {
      final injected = inset_reader.readWebSafeAreaBottomInset();
      if (injected != null && injected > 0) {
        bottom = math.max(bottom, injected);
      }
    }

    return bottom;
  }
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
    final insets = AppSafeAreaInsets.remaining(context);
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

/// Tüm sayfalarda MediaQuery safe area değerlerini güvenilir hale getirir.
class AppMediaQuery extends StatelessWidget {
  const AppMediaQuery({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final insets = AppSafeAreaInsets.effective(context);
    return MediaQuery(
      data: media.copyWith(
        padding: EdgeInsets.fromLTRB(
          math.max(media.padding.left, insets.left),
          math.max(media.padding.top, insets.top),
          math.max(media.padding.right, insets.right),
          math.max(media.padding.bottom, insets.bottom),
        ),
        viewPadding: EdgeInsets.fromLTRB(
          math.max(media.viewPadding.left, insets.left),
          math.max(media.viewPadding.top, insets.top),
          math.max(media.viewPadding.right, insets.right),
          math.max(media.viewPadding.bottom, insets.bottom),
        ),
      ),
      child: child,
    );
  }
}
