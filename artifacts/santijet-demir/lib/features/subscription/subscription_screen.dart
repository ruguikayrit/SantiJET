import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:santijet_demir/core/routing/app_routes.dart';
import 'package:santijet_demir/core/theme/app_colors.dart';
import 'package:santijet_demir/core/theme/app_radii.dart';
import 'package:santijet_demir/core/theme/app_spacing.dart';
import 'package:santijet_demir/core/theme/app_typography.dart';
import 'package:santijet_demir/core/widgets/app_toast.dart';
import 'package:santijet_demir/domain/enums/subscription_plan.dart';
import 'package:santijet_demir/domain/subscription/subscription_catalog.dart';
import 'package:santijet_demir/features/auth/providers/auth_provider.dart';
import 'package:santijet_demir/features/subscription/providers/subscription_provider.dart';

class SubscriptionScreen extends ConsumerWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(currentSubscriptionPlanProvider);
    final package = ref.watch(currentSubscriptionPackageProvider);
    final isGuest = ref.watch(isGuestSessionProvider);
    final canPurchase = ref.watch(canPurchaseSubscriptionProvider);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(title: const Text('Abonelik')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: AppRadii.md,
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Mevcut plan', style: AppTypography.labelMedium),
                const SizedBox(height: 6),
                Text(
                  isGuest ? 'Demo sürüm' : package.title,
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.electricBlueLight,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isGuest
                      ? 'Misafir oturumu — satın alma kapalı'
                      : package.monthlyPriceLabel,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          if (isGuest) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: AppRadii.md,
                border: Border.all(
                  color: AppColors.warning.withValues(alpha: 0.4),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Üyelik açmadan premium paket alınamaz',
                    style: AppTypography.titleMedium.copyWith(
                      color: AppColors.warning,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Misafir girişi Demo Şantiye ile test içindir. '
                    'Paket satın almak için hesap oluşturun.',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.cardTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => context.push(AppRoutes.register),
                    child: const Text('Üyelik aç'),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          Text(
            'Paketler',
            style: AppTypography.headlineMedium,
          ),
          const SizedBox(height: 4),
          Text(
            isGuest
                ? 'Paketler yalnızca üyelik sonrası satın alınabilir.'
                : 'İki paket — fiyatlar geçici; ödeme altyapısı yakında bağlanacak.',
            style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: 12),
          for (final info in SubscriptionCatalog.purchasable) ...[
            _PackageCard(
              info: info,
              isCurrent: !isGuest && current == info.plan,
              purchaseEnabled: canPurchase,
              onSelect: () => _confirmPurchase(context, ref, info),
            ),
            const SizedBox(height: 12),
          ],
          Text(
            isGuest
                ? 'Misafir hesapla satın alma simülasyonu da kapalıdır.'
                : 'Satın alma şu an simülasyondur. Gerçek ödeme entegrasyonu '
                    'sonraki adımda eklenecektir.',
            style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Future<void> _confirmPurchase(
    BuildContext context,
    WidgetRef ref,
    SubscriptionPackageInfo info,
  ) async {
    if (!ref.read(canPurchaseSubscriptionProvider)) {
      ScaffoldMessenger.of(context).showAppSnackBar(
        const SnackBar(
          content: Text(
            'Misafir hesapla premium paket alınamaz. Üyelik açın.',
          ),
        ),
      );
      return;
    }

    final current = ref.read(currentSubscriptionPlanProvider);
    if (current == info.plan) {
      ScaffoldMessenger.of(context).showAppSnackBar(
        const SnackBar(content: Text('Bu plan zaten aktif')),
      );
      return;
    }

    final isUpgrade = info.plan == SubscriptionPlan.demirTakipAnaliz &&
        current != SubscriptionPlan.demirTakipAnaliz;
    final actionLabel = isUpgrade ? 'Yükselt' : 'Paketi seç';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(info.title),
        content: Text(
          '$actionLabel: ${info.monthlyPriceLabel}\n\n'
          'Bu işlem şu an ödeme almaz; plan hesabınıza yazılır (simülasyon).',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(actionLabel),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final ok =
        await ref.read(authProvider.notifier).setSubscriptionPlan(info.plan);
    if (!context.mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showAppSnackBar(
        SnackBar(content: Text('${info.title} aktif edildi')),
      );
    } else {
      final err = ref.read(authProvider).error ?? 'İşlem başarısız';
      ScaffoldMessenger.of(context).showAppSnackBar(
        SnackBar(content: Text(err)),
      );
    }
  }
}

class _PackageCard extends StatelessWidget {
  const _PackageCard({
    required this.info,
    required this.isCurrent,
    required this.purchaseEnabled,
    required this.onSelect,
  });

  final SubscriptionPackageInfo info;
  final bool isCurrent;
  final bool purchaseEnabled;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final borderColor = info.highlighted
        ? AppColors.electricBlueLight
        : AppColors.border;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: AppRadii.md,
        border: Border.all(
          color: borderColor,
          width: info.highlighted ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  info.title,
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (info.badge != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.electricBlue.withValues(alpha: 0.15),
                    borderRadius: AppRadii.full,
                  ),
                  child: Text(
                    info.badge!,
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.electricBlueLight,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              if (isCurrent) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.15),
                    borderRadius: AppRadii.full,
                  ),
                  child: Text(
                    'Aktif',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Text(
            info.subtitle,
            style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: 10),
          Text(
            info.monthlyPriceLabel,
            style: AppTypography.kpiValue.copyWith(
              fontSize: 22,
              color: AppColors.electricBlueLight,
            ),
          ),
          const SizedBox(height: 12),
          for (final feature in info.features)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 18,
                    color: AppColors.success,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(feature, style: AppTypography.bodySmall),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: (!purchaseEnabled || isCurrent) ? null : onSelect,
            style: FilledButton.styleFrom(
              backgroundColor: info.highlighted
                  ? AppColors.electricBlueLight
                  : AppColors.surface,
              foregroundColor:
                  info.highlighted ? AppColors.canvas : AppColors.textPrimary,
              disabledBackgroundColor:
                  AppColors.border.withValues(alpha: 0.35),
              minimumSize: const Size.fromHeight(48),
            ),
            child: Text(
              !purchaseEnabled
                  ? 'Üyelik gerekli'
                  : isCurrent
                      ? 'Mevcut plan'
                      : (info.highlighted
                          ? 'Bu pakete yükselt'
                          : 'Bu paketi seç'),
            ),
          ),
        ],
      ),
    );
  }
}
