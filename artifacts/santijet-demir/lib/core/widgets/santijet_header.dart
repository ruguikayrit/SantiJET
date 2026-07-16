import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:santijet_demir/core/routing/app_routes.dart';
import 'package:santijet_demir/core/theme/app_colors.dart';
import 'package:santijet_demir/core/theme/app_spacing.dart';
import 'package:santijet_demir/core/theme/app_typography.dart';
import 'package:santijet_demir/features/settings/providers/profile_provider.dart';
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
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Image.asset(
                        'assets/images/splash_bolt.png',
                        width: 36,
                        height: 36,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.high,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Transform.translate(
                          offset: subtitle != null
                              ? const Offset(0, _titleGroupLift)
                              : Offset.zero,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('DEMİR', style: _demirTitleStyle),
                              if (subtitle != null) ...[
                                const SizedBox(height: 4),
                                Text(subtitle!, style: AppTypography.labelMedium),
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
                          style: AppTypography.titleMedium.copyWith(color: AppColors.warning),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
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
          child: Text('DEMİR', style: _demirTitleStyle),
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

class GreetingSection extends ConsumerWidget {
  const GreetingSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final displayName = ref.watch(profileDisplayNameProvider);
    final profession = ref.watch(profileProfessionProvider);
    final role = ref.watch(profileRoleProvider);

    // Referans satır: isim (headline). Diğer satırlar aynı sol mürekkep
    // hizasına çekilir — Inter boy/ağırlık farkından gelen bearing kayması giderilir.
    final nameStyle = AppTypography.headlineLarge.copyWith(letterSpacing: 0);
    final nameText = displayName.toUpperCase();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => context.push(AppRoutes.settings),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _TypographicFlushText(
                    'Hoş geldin',
                    style: AppTypography.bodySmall.copyWith(letterSpacing: 0),
                    referenceText: nameText,
                    referenceStyle: nameStyle,
                  ),
                  Text(nameText, style: nameStyle),
                  if (profession.isNotEmpty)
                    _TypographicFlushText(
                      profession,
                      style: AppTypography.bodyMedium.copyWith(letterSpacing: 0),
                      referenceText: nameText,
                      referenceStyle: nameStyle,
                    ),
                  if (role.isNotEmpty)
                    _TypographicFlushText(
                      role,
                      style: AppTypography.bodySmall.copyWith(letterSpacing: 0),
                      referenceText: nameText,
                      referenceStyle: nameStyle,
                    ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('Bugün', style: AppTypography.labelMedium),
                Text(
                  _formatToday(),
                  style: AppTypography.titleMedium,
                ),
                Text(
                  _formatWeekday(),
                  style: AppTypography.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatToday() {
    return DateFormat('d MMMM yyyy', 'tr_TR').format(DateTime.now());
  }

  String _formatWeekday() {
    return DateFormat('EEEE', 'tr_TR').format(DateTime.now());
  }
}

/// Sol baş hizası: satırın ilk glif mürekkebini [referenceText] ile hizalar.
class _TypographicFlushText extends StatelessWidget {
  const _TypographicFlushText(
    this.text, {
    required this.style,
    required this.referenceText,
    required this.referenceStyle,
  });

  final String text;
  final TextStyle style;
  final String referenceText;
  final TextStyle referenceStyle;

  static double _firstGlyphLeft(String value, TextStyle textStyle, TextDirection direction) {
    if (value.isEmpty) return 0;
    final painter = TextPainter(
      text: TextSpan(text: value, style: textStyle),
      textDirection: direction,
      maxLines: 1,
    )..layout();
    final boxes = painter.getBoxesForSelection(
      const TextSelection(baseOffset: 0, extentOffset: 1),
    );
    if (boxes.isEmpty) return 0;
    return boxes.first.left;
  }

  @override
  Widget build(BuildContext context) {
    final direction = Directionality.of(context);
    final referenceLeft =
        _firstGlyphLeft(referenceText, referenceStyle, direction);
    final lineLeft = _firstGlyphLeft(text, style, direction);
    final dx = referenceLeft - lineLeft;

    return Transform.translate(
      offset: Offset(dx, 0),
      child: Text(text, style: style),
    );
  }
}
