import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:santijet_demir/core/routing/app_routes.dart';
import 'package:santijet_demir/core/theme/app_colors.dart';
import 'package:santijet_demir/core/theme/app_spacing.dart';
import 'package:santijet_demir/core/theme/app_typography.dart';
import 'package:santijet_demir/features/shell/dashboard_feed_provider.dart';

class SantijetHeader extends StatelessWidget {
  const SantijetHeader({
    super.key,
    this.subtitle,
    this.showWordmark = false,
    this.showNotification = true,
    this.showAvatar = true,
    this.avatarInitial,
  });

  /// Ana sayfa DEMİR — wordmark’a göre ürün adı okunurluğu.
  static const homeDemirScale = 1.25;
  static const homeDemirLetterSpacing = 0.75;
  static const _homeBrandToActionsGap = 8.0;
  static const _homeWordmarkToDemirGap = 6.0;

  /// İç sayfa: bolt + küçük DEMİR etiketi + baskın sayfa adı.
  static const _pageLogoSize = 40.0;
  static const _pageLogoGap = 12.0;
  static const _pageTitleGap = 2.0;
  static const _pageTitleLift = 4.0;

  /// Sağ aksiyon kümesi — eşit dokunma alanı, sıkı görsel boşluk.
  static const actionSize = 40.0;
  static const actionIconSize = 22.0;
  static const actionAvatarRadius = 16.0;
  static const actionGap = 2.0;

  final String? subtitle;
  final bool showWordmark;
  final bool showNotification;
  final bool showAvatar;
  final String? avatarInitial;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.sm,
      ),
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

class _HeaderActions extends StatelessWidget {
  const _HeaderActions({
    required this.showNotification,
    required this.showAvatar,
    this.avatarInitial,
  });

  final bool showNotification;
  final bool showAvatar;
  final String? avatarInitial;

  @override
  Widget build(BuildContext context) {
    if (!showNotification && !showAvatar) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (showNotification) const _HeaderNotificationButton(),
        if (showNotification && showAvatar)
          const SizedBox(width: SantijetHeader.actionGap),
        if (showAvatar) _HeaderAvatarButton(initial: avatarInitial),
      ],
    );
  }
}

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
        child: SizedBox(
          width: SantijetHeader.actionSize,
          height: SantijetHeader.actionSize,
          child: IconButton(
            onPressed: () => context.push(AppRoutes.notificationSettings),
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints.tightFor(
              width: SantijetHeader.actionSize,
              height: SantijetHeader.actionSize,
            ),
            iconSize: SantijetHeader.actionIconSize,
            icon: Icon(
              Icons.notifications_outlined,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderAvatarButton extends StatelessWidget {
  const _HeaderAvatarButton({this.initial});

  final String? initial;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Ayarlar',
      button: true,
      child: SizedBox(
        width: SantijetHeader.actionSize,
        height: SantijetHeader.actionSize,
        child: IconButton(
          onPressed: () => context.push(AppRoutes.settings),
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
          constraints: const BoxConstraints.tightFor(
            width: SantijetHeader.actionSize,
            height: SantijetHeader.actionSize,
          ),
          icon: CircleAvatar(
            radius: SantijetHeader.actionAvatarRadius,
            backgroundColor: AppColors.warning.withValues(alpha: 0.3),
            child: Text(
              initial ?? 'U',
              style: AppTypography.titleMedium.copyWith(
                color: AppColors.warning,
                fontSize: 14,
                height: 1.0,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Bolt + muted DEMİR etiketi + baskın sayfa adı — ana sayfa hariç.
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

  static final _productLabelStyle = AppTypography.labelSmall.copyWith(
    fontSize: 11,
    letterSpacing: 0.9,
    fontWeight: FontWeight.w700,
    color: AppColors.textMuted,
    height: 1.0,
  );

  static final _pageTitleStyle = AppTypography.headlineMedium.copyWith(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
    color: AppColors.textPrimary,
    height: 1.15,
  );

  @override
  Widget build(BuildContext context) {
    return Row(
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
                      Text('DEMİR', style: _productLabelStyle),
                      if (subtitle != null) ...[
                        const SizedBox(height: SantijetHeader._pageTitleGap),
                        Text(subtitle!, style: _pageTitleStyle),
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
              const SizedBox(height: SantijetHeader._homeWordmarkToDemirGap),
              Padding(
                padding: EdgeInsets.only(left: demirIndent),
                child: Text('DEMİR', style: _homeDemirTitleStyle),
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
    final demirCapHeight = textPainter.computeLineMetrics().first.ascent;
    return demirCapHeight / wordmarkLetterFillRatio * 2.5;
  }

  static double demirIndentOf(BuildContext context) {
    return wordmarkHeightOf(context) *
        (_wordmarkLeftInkPx / _wordmarkPixelHeight);
  }
}
