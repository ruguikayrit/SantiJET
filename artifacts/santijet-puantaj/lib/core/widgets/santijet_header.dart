import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../constants/app_info.dart';
import '../routing/app_routes.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// ŞantiJET marka başlığı — Demir `SantijetHeader` ile birebir metrikler.
///
/// Ana sayfada wordmark + ürün adı ([AppInfo.productLabel] = PUANTAJ).
class SantijetHeader extends StatelessWidget {
  const SantijetHeader({
    super.key,
    this.subtitle,
    this.showWordmark = false,
    this.showNotification = false,
    this.showAvatar = true,
    this.avatarInitial,
  });

  /// Ana sayfa ürün adı — wordmark altı (%50 büyütülmüş, Demir homeDemirScale).
  static const homeProductScale = 1.875;
  static const homeProductLetterSpacing = 0.75;
  static const _homeBrandToActionsGap = 8.0;
  static const _homeWordmarkToProductGap = 6.0;

  static const _pageLogoSize = 40.0;
  static const _pageLogoGap = 12.0;
  static const _pageTitleGap = 2.0;
  static const _pageTitleLift = 4.0;

  static const actionSize = 40.0;
  static const actionIconSize = 22.0;
  static const actionAvatarRadius = 16.0;
  static const actionGap = 2.0;

  static const pageHeaderBandColor = Color(0xFF05070A);

  final String? subtitle;
  final bool showWordmark;
  final bool showNotification;
  final bool showAvatar;
  final String? avatarInitial;

  @override
  Widget build(BuildContext context) {
    if (showWordmark) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          AppSpacing.sm,
        ),
        child: _WordmarkHeader(
          showNotification: showNotification,
          showAvatar: showAvatar,
          avatarInitial: avatarInitial,
        ),
      );
    }

    return _PageBrandHeader(
      subtitle: subtitle,
      showNotification: showNotification,
      showAvatar: showAvatar,
      avatarInitial: avatarInitial,
    );
  }
}

class _HeaderActions extends StatelessWidget {
  const _HeaderActions({
    required this.showNotification,
    required this.showAvatar,
    this.avatarInitial,
    this.onDarkBand = false,
  });

  final bool showNotification;
  final bool showAvatar;
  final String? avatarInitial;
  final bool onDarkBand;

  @override
  Widget build(BuildContext context) {
    if (!showNotification && !showAvatar) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (showNotification)
          _HeaderNotificationButton(onDarkBand: onDarkBand),
        if (showNotification && showAvatar)
          const SizedBox(width: SantijetHeader.actionGap),
        if (showAvatar)
          _HeaderAvatarButton(
            initial: avatarInitial,
            onDarkBand: onDarkBand,
          ),
      ],
    );
  }
}

class _HeaderNotificationButton extends StatelessWidget {
  const _HeaderNotificationButton({this.onDarkBand = false});

  final bool onDarkBand;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Bildirimler',
      button: true,
      child: SizedBox(
        width: SantijetHeader.actionSize,
        height: SantijetHeader.actionSize,
        child: IconButton(
          onPressed: () => context.push(AppRoutes.ayarlar),
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
          constraints: const BoxConstraints.tightFor(
            width: SantijetHeader.actionSize,
            height: SantijetHeader.actionSize,
          ),
          iconSize: SantijetHeader.actionIconSize,
          icon: Icon(
            Icons.notifications_outlined,
            color: onDarkBand
                ? Colors.white.withValues(alpha: 0.88)
                : AppColors.inkMutedFor(Theme.of(context).brightness),
          ),
        ),
      ),
    );
  }
}

class _HeaderAvatarButton extends StatelessWidget {
  const _HeaderAvatarButton({
    this.initial,
    this.onDarkBand = false,
  });

  final String? initial;
  final bool onDarkBand;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Ayarlar',
      button: true,
      child: SizedBox(
        width: SantijetHeader.actionSize,
        height: SantijetHeader.actionSize,
        child: IconButton(
          onPressed: () => context.push(AppRoutes.ayarlar),
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
          constraints: const BoxConstraints.tightFor(
            width: SantijetHeader.actionSize,
            height: SantijetHeader.actionSize,
          ),
          iconSize: SantijetHeader.actionIconSize,
          icon: Icon(
            Icons.settings_outlined,
            color: onDarkBand
                ? Colors.white.withValues(alpha: 0.88)
                : AppColors.inkMutedFor(Theme.of(context).brightness),
          ),
        ),
      ),
    );
  }
}

class _PageBrandHeader extends StatelessWidget {
  const _PageBrandHeader({
    required this.showNotification,
    required this.showAvatar,
    this.subtitle,
    this.avatarInitial,
  });

  final String? subtitle;
  final bool showNotification;
  final bool showAvatar;
  final String? avatarInitial;

  @override
  Widget build(BuildContext context) {
    // Açık chrome: siyah şerit + beyaz yazı. Koyu chrome: koyu zemin + açık yazı.
    final onDarkBand = Theme.of(context).brightness == Brightness.light;
    final onDarkChrome = onDarkBand || AppColors.useDarkChrome;

    final productLabelStyle = AppTypography.labelSmall.copyWith(
      fontSize: AppTypography.scale * 11,
      letterSpacing: 0.9,
      fontWeight: FontWeight.w700,
      color: onDarkChrome
          ? Colors.white.withValues(alpha: 0.62)
          : AppColors.inkMutedFor(Theme.of(context).brightness),
      height: 1.0,
    );

    final pageTitleStyle = AppTypography.headlineMedium.copyWith(
      fontSize: AppTypography.scale * 18,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.2,
      color: onDarkChrome
          ? Colors.white
          : AppColors.inkFor(Theme.of(context).brightness),
      height: 1.15,
    );

    final content = Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.asset(
                  'assets/images/splash_bolt.png',
                  width: SantijetHeader._pageLogoSize,
                  height: SantijetHeader._pageLogoSize,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                ),
                const SizedBox(width: SantijetHeader._pageLogoGap),
                Expanded(
                  child: Transform.translate(
                    offset: subtitle != null
                        ? const Offset(0, SantijetHeader._pageTitleLift)
                        : Offset.zero,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(AppInfo.productLabel, style: productLabelStyle),
                        if (subtitle != null) ...[
                          const SizedBox(height: SantijetHeader._pageTitleGap),
                          Text(subtitle!, style: pageTitleStyle),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          _HeaderActions(
            showNotification: showNotification,
            showAvatar: showAvatar,
            avatarInitial: avatarInitial,
            onDarkBand: onDarkChrome,
          ),
        ],
      ),
    );

    if (!onDarkBand) return content;

    return ColoredBox(
      color: SantijetHeader.pageHeaderBandColor,
      child: content,
    );
  }
}

class _WordmarkHeader extends StatelessWidget {
  const _WordmarkHeader({
    required this.showNotification,
    required this.showAvatar,
    this.avatarInitial,
  });

  final bool showNotification;
  final bool showAvatar;
  final String? avatarInitial;

  @override
  Widget build(BuildContext context) {
    final wordmarkHeight = _BrandTitleMetrics.wordmarkHeightOf(context);
    final productIndent = _BrandTitleMetrics.productIndentOf(context);
    final ink = AppColors.inkFor(Theme.of(context).brightness);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                AppColors.wordmarkAssetFor(Theme.of(context).brightness),
                height: wordmarkHeight,
                fit: BoxFit.fitHeight,
                filterQuality: FilterQuality.high,
                alignment: Alignment.centerLeft,
              ),
              const SizedBox(height: SantijetHeader._homeWordmarkToProductGap),
              Padding(
                padding: EdgeInsets.only(left: productIndent),
                child: Text(
                  AppInfo.productLabel,
                  style: _homeProductTitleStyle.copyWith(color: ink),
                ),
              ),
            ],
          ),
        ),
        if (showNotification || showAvatar) ...[
          const SizedBox(width: SantijetHeader._homeBrandToActionsGap),
          _HeaderActions(
            showNotification: showNotification,
            showAvatar: showAvatar,
            avatarInitial: avatarInitial,
          ),
        ],
      ],
    );
  }
}

TextStyle get _productMetricBaseStyle => AppTypography.titleMedium.copyWith(
      letterSpacing: 1.2,
      fontWeight: FontWeight.w700,
      height: 1.0,
    );

TextStyle get _brandMetricStyle => _productMetricBaseStyle.copyWith(
      fontSize: AppTypography.brandScale * 14,
    );

TextStyle get _homeProductTitleStyle => _productMetricBaseStyle.copyWith(
      fontSize: AppTypography.brandScale *
          14 *
          SantijetHeader.homeProductScale,
      letterSpacing: SantijetHeader.homeProductLetterSpacing,
    );

abstract final class _BrandTitleMetrics {
  static const wordmarkLetterFillRatio = 0.55;
  static const _wordmarkHeightScale = 2.5;

  static const _lightWordmarkPixelHeight = 157.0;
  static const _lightWordmarkLeftInkPx = 12.0;
  static const _darkWordmarkPixelHeight = 150.0;
  static const _darkWordmarkLeftInkPx = 12.0;

  static double wordmarkHeightOf(BuildContext context) {
    final textPainter = TextPainter(
      text: TextSpan(text: AppInfo.productLabel, style: _brandMetricStyle),
      textDirection: Directionality.of(context),
      maxLines: 1,
    )..layout();
    final capHeight = textPainter.computeLineMetrics().first.ascent;
    return capHeight / wordmarkLetterFillRatio * _wordmarkHeightScale;
  }

  static double productIndentOf(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final leftInk =
        isLight ? _lightWordmarkLeftInkPx : _darkWordmarkLeftInkPx;
    final pixelHeight =
        isLight ? _lightWordmarkPixelHeight : _darkWordmarkPixelHeight;
    return wordmarkHeightOf(context) * (leftInk / pixelHeight);
  }
}
