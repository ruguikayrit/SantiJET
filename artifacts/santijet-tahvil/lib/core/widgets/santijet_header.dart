import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../constants/app_info.dart';
import '../routing/app_routes.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// ŞantiJET marka başlığı — Demir/Malzeme metrikleri.
///
/// Ayarlar = sağ üst dişli. Bildirim zili yok.
class SantijetHeader extends StatelessWidget {
  const SantijetHeader({
    super.key,
    this.subtitle,
    this.showWordmark = false,
  });

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

  static const pageHeaderBandColor = Color(0xFF05070A);

  final String? subtitle;
  final bool showWordmark;

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
        child: const _WordmarkHeader(),
      );
    }

    return _PageBrandHeader(subtitle: subtitle);
  }
}

class _HeaderSettingsButton extends StatelessWidget {
  const _HeaderSettingsButton({this.onDarkBand = false});

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
                : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _PageBrandHeader extends StatelessWidget {
  const _PageBrandHeader({this.subtitle});

  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final onDarkBand = Theme.of(context).brightness == Brightness.light;

    final productLabelStyle = AppTypography.labelSmall.copyWith(
      fontSize: AppTypography.scale * 11,
      letterSpacing: 0.9,
      fontWeight: FontWeight.w700,
      color: onDarkBand
          ? Colors.white.withValues(alpha: 0.62)
          : AppColors.textMuted,
      height: 1.0,
    );

    final pageTitleStyle = AppTypography.headlineMedium.copyWith(
      fontSize: AppTypography.scale * 18,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.2,
      color: onDarkBand ? Colors.white : AppColors.textPrimary,
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
          _HeaderSettingsButton(onDarkBand: onDarkBand),
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
  const _WordmarkHeader();

  @override
  Widget build(BuildContext context) {
    final wordmarkHeight = _BrandTitleMetrics.wordmarkHeightOf(context);
    final productIndent = _BrandTitleMetrics.productIndentOf(context);
    final ink = AppColors.textPrimary;

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
        const SizedBox(width: SantijetHeader._homeBrandToActionsGap),
        const _HeaderSettingsButton(),
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
      fontSize: AppTypography.brandScale * 14 * SantijetHeader.homeProductScale,
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
