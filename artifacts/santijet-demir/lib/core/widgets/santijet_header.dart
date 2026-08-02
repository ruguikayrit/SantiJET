import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:santijet_demir/core/routing/app_routes.dart';
import 'package:santijet_demir/core/theme/app_colors.dart';
import 'package:santijet_demir/core/theme/app_spacing.dart';
import 'package:santijet_demir/core/theme/app_typography.dart';
import 'package:santijet_demir/features/settings/providers/profile_provider.dart';
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

  /// Ana sayfa DEMİR — wordmark altı ürün adı (%50 büyütülmüş).
  static const homeDemirScale = 1.875; // 1.25 × 1.5
  static const homeDemirLetterSpacing = 0.75;
  static const _homeBrandToActionsGap = 8.0;
  static const _homeWordmarkToDemirGap = 6.0;

  /// İç sayfa: bolt + küçük DEMİR etiketi + baskın sayfa adı.
  static const _pageLogoSize = 40.0;
  static const _pageLogoGap = 12.0;
  static const _pageTitleGap = 2.0;
  static const _pageTitleLift = 4.0;

  /// Sağ aksiyon kümesi — en az 48px dokunma alanı (Material erişilebilirlik).
  static const actionSize = 48.0;
  static const actionIconSize = 22.0;
  static const actionAvatarRadius = 16.0;
  static const actionGap = 4.0;

  /// Açık temada iç sayfa başlık bandı (ana sayfa hariç).
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

class _HeaderNotificationButton extends ConsumerWidget {
  const _HeaderNotificationButton({this.onDarkBand = false});

  final bool onDarkBand;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alerts = ref.watch(dashboardCriticalAlertsProvider);
    final alertCount = alerts.length;

    return Semantics(
      label: alertCount > 0
          ? '$alertCount kritik uyarı'
          : 'Bildirimler, uyarı yok',
      button: true,
      child: SizedBox(
        width: SantijetHeader.actionSize,
        height: SantijetHeader.actionSize,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: Material(
                type: MaterialType.transparency,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () {
                    GoRouter.of(context).push(AppRoutes.notificationSettings);
                  },
                  child: Center(
                    child: Icon(
                      Icons.notifications_outlined,
                      size: SantijetHeader.actionIconSize,
                      color: onDarkBand
                          ? Colors.white.withValues(alpha: 0.88)
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
            if (alertCount > 0)
              Positioned(
                right: 6,
                top: 6,
                child: IgnorePointer(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: AppColors.critical,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$alertCount',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _HeaderAvatarButton extends ConsumerWidget {
  const _HeaderAvatarButton({
    this.initial,
    this.onDarkBand = false,
  });

  final String? initial;
  final bool onDarkBand;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resolvedInitial =
        (initial == null || initial!.trim().isEmpty)
            ? ref.watch(profileInitialProvider)
            : initial!.trim();

    return Semantics(
      label: 'Ayarlar',
      button: true,
      child: SizedBox(
        width: SantijetHeader.actionSize,
        height: SantijetHeader.actionSize,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () {
              GoRouter.of(context).push(AppRoutes.settings);
            },
            child: Center(
              child: CircleAvatar(
                radius: SantijetHeader.actionAvatarRadius,
                backgroundColor: onDarkBand
                    ? AppColors.warning.withValues(alpha: 0.35)
                    : AppColors.warning.withValues(alpha: 0.3),
                child: Text(
                  resolvedInitial,
                  style: AppTypography.titleMedium.copyWith(
                    color: onDarkBand ? Colors.white : AppColors.warning,
                    fontSize: AppTypography.scale *
                        (resolvedInitial.length > 1 ? 11 : 14),
                    height: 1.0,
                    letterSpacing: resolvedInitial.length > 1 ? -0.4 : 0,
                  ),
                ),
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
                        Text('DEMİR', style: productLabelStyle),
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
            onDarkBand: onDarkBand,
          ),
        ],
      ),
    );

    if (!onDarkBand) return content;

    // Açık tema: logo + DEMİR + sayfa adı + aksiyonlar siyah bant içinde.
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
      color: AppColors.textPrimary,
    );

/// Wordmark metrikleri için kilitli marka ölçeği (global scale’ten bağımsız).
TextStyle get _brandMetricStyle => _demirTitleStyle.copyWith(
      fontSize: AppTypography.brandScale * 14,
    );

/// Wordmark altındaki DEMİR — marka ölçeğinde, homeDemirScale ile büyütülür.
TextStyle get _homeDemirTitleStyle => _demirTitleStyle.copyWith(
      fontSize: AppTypography.brandScale *
          14 *
          SantijetHeader.homeDemirScale,
      letterSpacing: SantijetHeader.homeDemirLetterSpacing,
    );

abstract final class _BrandTitleMetrics {
  /// Wordmark harf doluluk oranı — açık/koyu aynı görsel ölçek.
  static const wordmarkLetterFillRatio = 0.55;
  static const _wordmarkHeightScale = 2.5;

  /// Açık wordmark asset (splash_wordmark_light.png).
  static const _lightWordmarkPixelHeight = 157.0;
  static const _lightWordmarkLeftInkPx = 12.0;

  /// Koyu wordmark — kullanıcının referans tipografisinden kesilmiş
  /// (splash_wordmark.png, OPERASYON YÖNETİMİ yok).
  static const _darkWordmarkPixelHeight = 150.0;
  static const _darkWordmarkLeftInkPx = 12.0;

  static double wordmarkHeightOf(BuildContext context) {
    final textPainter = TextPainter(
      text: TextSpan(text: 'DEMİR', style: _brandMetricStyle),
      textDirection: Directionality.of(context),
      maxLines: 1,
    )..layout();
    final demirCapHeight = textPainter.computeLineMetrics().first.ascent;
    // Marka ölçeğine kilitli — global tipografi değişince wordmark büyümez.
    // Açık/koyu asset farklı piksel boyutunda olsa da aynı görsel yükseklik.
    return demirCapHeight / wordmarkLetterFillRatio * _wordmarkHeightScale;
  }

  static double demirIndentOf(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final leftInk =
        isLight ? _lightWordmarkLeftInkPx : _darkWordmarkLeftInkPx;
    final pixelHeight =
        isLight ? _lightWordmarkPixelHeight : _darkWordmarkPixelHeight;
    return wordmarkHeightOf(context) * (leftInk / pixelHeight);
  }
}
