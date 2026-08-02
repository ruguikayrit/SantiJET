import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:santijet_demir/core/responsive/app_safe_area_inset_web.dart'
    if (dart.library.io) 'package:santijet_demir/core/responsive/app_safe_area_inset_io.dart'
    as inset_reader;

/// iOS Safari PWA'da MediaQuery safe area çoğu zaman 0 gelir; üst için minimum.
///
/// Alt inset MediaQuery.padding'e yazılmaz — aksi halde her [Scaffold] altında
/// boş "ölü" şerit oluşur (nav ayrıca kendi home-indicator alanını çizer).
abstract final class AppSafeAreaInsets {
  static const _iosWebMinTop = 47.0;

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
    // Bottom: yalnızca motorun bildirdiği değer — şişirme yok.
    final bottom = math.max(view.bottom, pad.bottom);
    var left = math.max(view.left, pad.left);
    var right = math.max(view.right, pad.right);

    if (_isIosWeb(context)) {
      final injectedTop = inset_reader.readWebSafeAreaTopInset();
      if (injectedTop != null && injectedTop > 0) {
        top = math.max(top, injectedTop);
      }
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

  /// Alt nav yüksekliği hesabı — Puantaj/Beton ile aynı: yalnızca viewPadding.
  ///
  /// Eski sürüm iOS web'de zorunlu +34 ekliyordu; visualViewport ile birlikte
  /// nav altında çift boş / ölü şerit oluşturuyordu. Kullanmayın / şişirmeyin.
  static double bottomNavInsetOf(BuildContext context) {
    final media = MediaQuery.maybeOf(context);
    if (media == null) return 0;
    final bottom = media.viewPadding.bottom;
    if (!bottom.isFinite || bottom.isNaN || bottom < 0) return 0;
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

/// Üst notch güvenli alanı.
///
/// **Kritik:** [padding.bottom] her zaman 0.
/// Flutter Scaffold, `padding.bottom` kadar alanı ekranın altında boş bırakır
/// (giriş, splash, ayarlar ve nav barın altı). Home indicator için gerçek
/// değer [viewPadding.bottom] içinde kalır; nav onu kendi içinde çizer.
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
          0,
        ),
        viewPadding: EdgeInsets.fromLTRB(
          math.max(media.viewPadding.left, insets.left),
          math.max(media.viewPadding.top, insets.top),
          math.max(media.viewPadding.right, insets.right),
          media.viewPadding.bottom,
        ),
      ),
      child: child,
    );
  }
}
