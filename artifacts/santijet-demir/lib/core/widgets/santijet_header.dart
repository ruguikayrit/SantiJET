import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:santijet_demir/core/routing/app_routes.dart';
import 'package:santijet_demir/core/theme/app_colors.dart';
import 'package:santijet_demir/core/theme/app_spacing.dart';
import 'package:santijet_demir/core/theme/app_typography.dart';
import 'package:santijet_demir/features/shell/dashboard_feed_provider.dart';

class _HeaderNotificationButton extends ConsumerWidget {
  const _HeaderNotificationButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alerts = ref.watch(dashboardCriticalAlertsProvider);
    final alertCount = alerts.length;

    return Semantics(
      label: alertCount > 0
          ? '$alertCount kritik uyarı'
          : 'Bildirimler, uyarı yok',
      button: true,
      child: Badge(
        isLabelVisible: alertCount > 0,
        label: Text('$alertCount'),
        backgroundColor: AppColors.critical,
        child: IconButton(
          onPressed: () => context.push(AppRoutes.notificationSettings),
          icon: const Icon(
            Icons.notifications_outlined,
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class SantijetHeader extends StatelessWidget {
  const SantijetHeader({
    super.key,
    this.subtitle,
    this.showWordmark = false,
    this.showNotification = true,
    this.showAvatar = true,
    this.avatarInitial,
  });

  /// Ana sayfa (wordmark) hariç: marka biraz büyür, sayfa adı daha öne çıkar.
  static const pageBrandScale = 1.25;
  static const pageSubtitleScale = 1.5;
  /// Ana sayfa DEMİR — wordmark’a göre ürün adı okunurluğu.
  static const homeDemirScale = 1.25;
  static const homeDemirLetterSpacing = 0.75;
  static const _baseLogoSize = 36.0;
  static const _baseLogoGap = 10.0;
  static const _baseSubtitleGap = 4.0;
  static const _titleGroupLift = 6.0;

  final String? subtitle;
  final bool showWordmark;
  final bool showNotification;
  final bool showAvatar;
  final String? avatarInitial;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.sm),
      child: showWordmark
          ? _WordmarkHeader(
              showNotification: showNotification,
              showAvatar: showAvatar,
              avatarInitial: avatarInitial,
            )
          : _PageBrandHeader(
              subtitle: subtitle,
              showNotification: showNotification,
              showAvatar: showAvatar,
              avatarInitial: avatarInitial,
            ),
    );
  }
}

/// Bolt + DEMİR (×1.25) + sayfa alt başlığı (×1.50) — ana sayfa hariç.
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
    const brandScale = SantijetHeader.pageBrandScale;
    const subtitleScale = SantijetHeader.pageSubtitleScale;
    final logoSize = SantijetHeader._baseLogoSize * brandScale;
    final logoGap = SantijetHeader._baseLogoGap * brandScale;
    final subtitleGap = SantijetHeader._baseSubtitleGap * brandScale;
    final titleLift = SantijetHeader._titleGroupLift * brandScale;

    final demirStyle = _demirTitleStyle.copyWith(
      fontSize: (_demirTitleStyle.fontSize ?? 14) * brandScale,
      letterSpacing: 1.2 * brandScale,
    );
    final subtitleStyle = AppTypography.labelMedium.copyWith(
      fontSize: (AppTypography.labelMedium.fontSize ?? 12) * subtitleScale,
      letterSpacing:
          (AppTypography.labelMedium.letterSpacing ?? 0.04) * subtitleScale,
      fontWeight: FontWeight.w600,
      color: AppColors.textSecondary,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.asset(
                'assets/images/splash_bolt.png',
                width: logoSize,
                height: logoSize,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
              ),
              SizedBox(width: logoGap),
              Expanded(
                child: Transform.translate(
                  offset: subtitle != null
                      ? Offset(0, titleLift)
                      : Offset.zero,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('DEMİR', style: demirStyle),
                      if (subtitle != null) ...[
                        SizedBox(height: subtitleGap),
                        Text(subtitle!, style: subtitleStyle),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        if (showNotification) const _HeaderNotificationButton(),
        if (showAvatar)
          Semantics(
            label: 'Ayarlar',
            button: true,
            child: IconButton(
              onPressed: () => context.push(AppRoutes.settings),
              icon: CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.warning.withValues(alpha: 0.3),
                child: Text(
                  avatarInitial ?? 'U',
                  style: AppTypography.titleMedium
                      .copyWith(color: AppColors.warning),
                ),
              ),
            ),
          ),
      ],
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
    final demirIndent = _BrandTitleMetrics.demirIndentOf(context);
    // PNG üst/alt boşluğunu çıkar; harf bandının ortasına hizala.
    final letterBandTop = wordmarkHeight *
        (1 - _BrandTitleMetrics.wordmarkLetterFillRatio) /
        2;
    final letterBandHeight =
        wordmarkHeight * _BrandTitleMetrics.wordmarkLetterFillRatio;

    final actions = Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (showNotification) const _HeaderNotificationButton(),
        if (showAvatar)
          Semantics(
            label: 'Ayarlar',
            button: true,
            child: IconButton(
              onPressed: () => context.push(AppRoutes.settings),
              icon: CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.warning.withValues(alpha: 0.3),
                child: Text(
                  avatarInitial ?? 'U',
                  style: AppTypography.titleMedium
                      .copyWith(color: AppColors.warning),
                ),
              ),
            ),
          ),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ColorFiltered(
                colorFilter: ColorFilter.mode(
                  AppColors.canvas,
                  BlendMode.lighten,
                ),
                child: Image.asset(
                  'assets/images/splash_wordmark.png',
                  height: wordmarkHeight,
                  fit: BoxFit.fitHeight,
                  filterQuality: FilterQuality.high,
                  alignment: Alignment.centerLeft,
                ),
              ),
            ),
            if (showNotification || showAvatar)
              SizedBox(
                height: wordmarkHeight,
                child: Padding(
                  padding: EdgeInsets.only(top: letterBandTop),
                  child: SizedBox(
                    height: letterBandHeight,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: actions,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Padding(
          padding: EdgeInsets.only(left: demirIndent),
          child: Text('DEMİR', style: _homeDemirTitleStyle),
        ),
      ],
    );
  }
}

TextStyle get _demirTitleStyle => AppTypography.titleMedium.copyWith(
      letterSpacing: 1.2,
      fontWeight: FontWeight.w700,
      height: 1.0,
    );

/// Wordmark altındaki DEMİR — daha büyük, daha az tracking; wordmark ölçüsü değişmez.
TextStyle get _homeDemirTitleStyle => _demirTitleStyle.copyWith(
      fontSize:
          (_demirTitleStyle.fontSize ?? 14) * SantijetHeader.homeDemirScale,
      letterSpacing: SantijetHeader.homeDemirLetterSpacing,
    );

abstract final class _BrandTitleMetrics {
  static const wordmarkLetterFillRatio = 0.55;
  static const _wordmarkPixelHeight = 514.0;
  static const _wordmarkLeftInkPx = 139.0;

  static double wordmarkHeightOf(BuildContext context) {
    final textPainter = TextPainter(
      text: TextSpan(text: 'DEMİR', style: _demirTitleStyle),
      textDirection: Directionality.of(context),
      maxLines: 1,
    )..layout();
    final demirCapHeight =
        textPainter.computeLineMetrics().first.ascent;
    return demirCapHeight / wordmarkLetterFillRatio * 2.5;
  }

  static double demirIndentOf(BuildContext context) {
    return wordmarkHeightOf(context) *
        (_wordmarkLeftInkPx / _wordmarkPixelHeight);
  }
}
