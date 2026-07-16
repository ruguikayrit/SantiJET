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

    // Tipografik sol baş: tüm satırların ilk glif mürekkebi aynı x'te.
    final nameStyle = AppTypography.headlineLarge.copyWith(
      letterSpacing: 0,
      height: 1.15,
    );
    final welcomeStyle = AppTypography.bodySmall.copyWith(
      letterSpacing: 0,
      height: 1.2,
    );
    final metaStyle = AppTypography.bodyMedium.copyWith(
      letterSpacing: 0,
      height: 1.25,
    );
    final roleStyle = AppTypography.bodySmall.copyWith(
      letterSpacing: 0,
      height: 1.2,
    );
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
                  _InkFlushStartText('Hoş geldin', style: welcomeStyle),
                  _InkFlushStartText(nameText, style: nameStyle),
                  if (profession.isNotEmpty)
                    _InkFlushStartText(profession, style: metaStyle),
                  if (role.isNotEmpty)
                    _InkFlushStartText(role, style: roleStyle),
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

/// Sol mürekkep kenarını sütun başlangıcına hizalar (Inter side-bearing farkı).
class _InkFlushStartText extends StatelessWidget {
  const _InkFlushStartText(this.text, {required this.style});

  final String text;
  final TextStyle style;

  /// Inter Latin için yaklaşık sol bearing (em oranı).
  static double _estimatedBearing(TextStyle textStyle) {
    final size = textStyle.fontSize ?? 14.0;
    final weight = textStyle.fontWeight?.value ?? 400;
    // Bold / büyük kapaklar daha dar bearing taşır.
    final fraction = weight >= 700 ? 0.018 : 0.06;
    return size * fraction;
  }

  static double _inkLeft(String value, TextStyle textStyle, TextDirection direction) {
    if (value.isEmpty) return 0;
    final painter = TextPainter(
      text: TextSpan(text: value, style: textStyle),
      textDirection: direction,
      maxLines: 1,
    )..layout();
    final boxes = painter.getBoxesForSelection(
      const TextSelection(baseOffset: 0, extentOffset: 1),
    );
    final measured = boxes.isEmpty ? 0.0 : boxes.first.left;
    // Web / bazı renderer'larda kutu sol kenarı 0 döner; tahmini bearing kullan.
    if (measured.abs() < 0.05) return _estimatedBearing(textStyle);
    return measured;
  }

  @override
  Widget build(BuildContext context) {
    final inkLeft = _inkLeft(text, style, Directionality.of(context));
    return Transform.translate(
      offset: Offset(-inkLeft, 0),
      child: Text(text, style: style),
    );
  }
}
