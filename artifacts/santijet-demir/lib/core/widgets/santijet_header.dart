import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:santijet_demir/core/routing/app_routes.dart';
import 'package:santijet_demir/core/theme/app_colors.dart';
import 'package:santijet_demir/core/theme/app_spacing.dart';
import 'package:santijet_demir/core/theme/app_typography.dart';
import 'package:santijet_demir/features/settings/providers/profile_provider.dart';

class SantijetHeader extends StatelessWidget {
  const SantijetHeader({
    super.key,
    this.subtitle,
    this.showWordmark = false,
    this.showNotification = true,
    this.showAvatar = true,
    this.onNotificationTap,
    this.avatarInitial,
  });

  static const _titleGroupLift = 6.0;

  final String? subtitle;
  final bool showWordmark;
  final bool showNotification;
  final bool showAvatar;
  final VoidCallback? onNotificationTap;
  final String? avatarInitial;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: showWordmark
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Image.asset(
                        'assets/images/splash_bolt.png',
                        width: 36,
                        height: 36,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.high,
                      ),
                      const SizedBox(width: 10),
                      Flexible(child: _BrandTitleRow(shiftUpByFontHeight: true)),
                    ],
                  )
                : Row(
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
          if (showNotification)
            Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  onPressed:
                      onNotificationTap ?? () => context.push(AppRoutes.notificationSettings),
                  icon: const Icon(Icons.notifications_outlined, color: AppColors.textSecondary),
                ),
                Positioned(
                  right: 10,
                  top: 10,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.critical,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          if (showAvatar)
            GestureDetector(
              onTap: () => context.push(AppRoutes.settings),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.warning.withValues(alpha: 0.3),
                child: Text(
                  avatarInitial ?? 'U',
                  style: AppTypography.titleMedium.copyWith(color: AppColors.warning),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

TextStyle get _demirTitleStyle => AppTypography.titleMedium.copyWith(
      letterSpacing: 1.2,
      fontWeight: FontWeight.w700,
      height: 1.0,
    );

class _BrandTitleRow extends StatelessWidget {
  const _BrandTitleRow({this.shiftUpByFontHeight = false});

  final bool shiftUpByFontHeight;

  /// PNG wordmark içinde harfler dikeyde ~%55 alan kaplar; geri kalan boşluktur.
  static const _wordmarkLetterFillRatio = 0.55;

  @override
  Widget build(BuildContext context) {
    final textPainter = TextPainter(
      text: TextSpan(text: 'DEMİR', style: _demirTitleStyle),
      textDirection: Directionality.of(context),
      maxLines: 1,
    )..layout();

    final lineMetric = textPainter.computeLineMetrics().first;
    final demirCapHeight = lineMetric.ascent;
    final wordmarkHeight = demirCapHeight / _wordmarkLetterFillRatio * 2;
    final fontHeight = textPainter.height;

    final row = Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        ColorFiltered(
          colorFilter: ColorFilter.mode(
            AppColors.canvas,
            BlendMode.lighten,
          ),
          child: Image.asset(
            'assets/images/splash_wordmark.png',
            height: wordmarkHeight,
            fit: BoxFit.fitHeight,
            filterQuality: FilterQuality.high,
          ),
        ),
        const SizedBox(width: 8),
        Text('DEMİR', style: _demirTitleStyle),
      ],
    );

    if (!shiftUpByFontHeight) return row;

    return Transform.translate(
      offset: Offset(-12, -fontHeight + 2),
      child: row,
    );
  }
}

class GreetingSection extends ConsumerWidget {
  const GreetingSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final displayName = ref.watch(profileDisplayNameProvider);
    final profession = ref.watch(profileProfessionProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => context.push(AppRoutes.settings),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Hoş geldin', style: AppTypography.bodySmall),
                  Text(
                    displayName.toUpperCase(),
                    style: AppTypography.headlineLarge,
                  ),
                  Text(profession, style: AppTypography.bodyMedium),
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatToday() {
    final now = DateTime.now();
    const months = [
      'Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz',
      'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara',
    ];
    return '${now.day} ${months[now.month - 1]} ${now.year}';
  }
}
