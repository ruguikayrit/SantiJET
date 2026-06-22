import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:santijet_demir/core/routing/app_routes.dart';
import 'package:santijet_demir/core/theme/app_colors.dart';
import 'package:santijet_demir/core/theme/app_spacing.dart';
import 'package:santijet_demir/core/theme/app_typography.dart';

class SantijetHeader extends StatelessWidget {
  const SantijetHeader({
    super.key,
    this.subtitle,
    this.showNotification = true,
    this.showAvatar = true,
    this.onNotificationTap,
  });

  final String? subtitle;
  final bool showNotification;
  final bool showAvatar;
  final VoidCallback? onNotificationTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.sm),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              'assets/images/s_logo.png',
              width: 36,
              height: 36,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ŞantiJET DEMİR',
                  style: AppTypography.titleMedium.copyWith(
                    letterSpacing: 0.5,
                  ),
                ),
                if (subtitle != null)
                  Text(subtitle!, style: AppTypography.labelMedium),
              ],
            ),
          ),
          if (showNotification)
            Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  onPressed: onNotificationTap,
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
                  'U',
                  style: AppTypography.titleMedium.copyWith(color: AppColors.warning),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class GreetingSection extends StatelessWidget {
  const GreetingSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Hoş geldin', style: AppTypography.bodySmall),
              Text('UĞUR TİRYAKİ', style: AppTypography.headlineLarge),
              Text('Şantiye Şefi', style: AppTypography.bodyMedium),
            ],
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
                Text('16 May 2025', style: AppTypography.titleMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
