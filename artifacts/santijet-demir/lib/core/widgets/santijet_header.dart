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
    this.showNotification = true,
    this.showAvatar = true,
    this.onNotificationTap,
    this.avatarInitial,
  });

  final String? subtitle;
  final bool showNotification;
  final bool showAvatar;
  final VoidCallback? onNotificationTap;
  final String? avatarInitial;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.sm),
      child: Row(
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DEMİR',
                  style: AppTypography.titleMedium.copyWith(
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w700,
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
