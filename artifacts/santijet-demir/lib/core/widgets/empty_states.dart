import 'package:flutter/material.dart';
import 'package:santijet_demir/core/theme/app_colors.dart';
import 'package:santijet_demir/core/theme/app_typography.dart';

enum EmptyStateType {
  noOrders(
    title: 'Sipariş Yok',
    message: 'Henüz sipariş oluşturulmadı. Yeni sipariş ekleyerek başlayın.',
    icon: Icons.receipt_long_outlined,
  ),
  noDelivery(
    title: 'Teslimat Yok',
    message: 'Kayıtlı teslimat bulunmuyor. İlk teslimatı ekleyin.',
    icon: Icons.local_shipping_outlined,
  ),
  noReport(
    title: 'Rapor Yok',
    message: 'Henüz rapor oluşturulmadı. Kategori seçerek rapor üretin.',
    icon: Icons.description_outlined,
  ),
  noCount(
    title: 'Sayım Yok',
    message: 'Saha sayımı kaydı bulunmuyor. Yeni sayım başlatın.',
    icon: Icons.inventory_2_outlined,
  ),
  noAnalysis(
    title: 'Analiz Verisi Yok',
    message: 'Analiz için yeterli veri toplanmadı.',
    icon: Icons.analytics_outlined,
  ),
  noAlert(
    title: 'Uyarı Yok',
    message: 'Şu an kritik uyarı bulunmuyor. Her şey yolunda.',
    icon: Icons.notifications_none_outlined,
  ),
  noVariance(
    title: 'Sapma Yok',
    message: 'Sayım sapması tespit edilmedi.',
    icon: Icons.check_circle_outline,
  ),
  noSurvey(
    title: 'Keşif Yok',
    message: 'Keşif kaydı bulunmuyor. Yeni imalat ekleyin.',
    icon: Icons.search_off_outlined,
  ),
  noSearchResult(
    title: 'Arama Sonucu Yok',
    message: 'Aramanızla eşleşen kayıt bulunamadı. Filtreleri değiştirin.',
    icon: Icons.manage_search_outlined,
  );

  const EmptyStateType({
    required this.title,
    required this.message,
    required this.icon,
  });

  final String title;
  final String message;
  final IconData icon;
}

class ModuleEmptyState extends StatelessWidget {
  const ModuleEmptyState({
    super.key,
    required this.type,
    this.actionLabel,
    this.onAction,
    this.inline = false,
  });

  final EmptyStateType type;
  final String? actionLabel;
  final VoidCallback? onAction;

  /// ListView / SliverList içinde kullanım — [Center] olmadan.
  final bool inline;

  @override
  Widget build(BuildContext context) {
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.electricBlue.withValues(alpha: 0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(type.icon, size: 40, color: AppColors.textMuted),
        ),
        const SizedBox(height: 20),
        Text(type.title, style: AppTypography.headlineMedium, textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text(type.message, style: AppTypography.bodyMedium, textAlign: TextAlign.center),
        if (actionLabel != null && onAction != null) ...[
          const SizedBox(height: 24),
          FilledButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ],
    );

    if (inline) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: content,
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: content,
      ),
    );
  }
}
