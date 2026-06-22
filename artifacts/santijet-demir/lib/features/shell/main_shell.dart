import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:santijet_demir/core/routing/app_routes.dart';
import 'package:santijet_demir/core/theme/app_colors.dart';
import 'package:santijet_demir/core/theme/app_spacing.dart';
import 'package:santijet_demir/core/theme/app_typography.dart';
import 'package:santijet_demir/core/widgets/app_bottom_nav_bar.dart';
import 'package:santijet_demir/core/widgets/app_components.dart';
import 'package:santijet_demir/core/widgets/santijet_header.dart';

class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: navigationShell,
      bottomNavigationBar: AppBottomNavBar(navigationShell: navigationShell),
    );
  }
}

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(child: SantijetHeader()),
            const SliverToBoxAdapter(child: GreetingSection()),
            SliverPadding(
              padding: const EdgeInsets.all(AppSpacing.md),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.5,
                    children: const [
                      KpiCard(
                        label: 'Toplam Keşif',
                        value: '3.156',
                        unit: 't',
                        trend: '+12%',
                        trendUp: true,
                        accentColor: AppColors.electricBlueLight,
                      ),
                      KpiCard(
                        label: 'Toplam Sipariş',
                        value: '2.890',
                        unit: 't',
                        trend: '+8%',
                        trendUp: true,
                        accentColor: AppColors.info,
                      ),
                      KpiCard(
                        label: 'Sahaya Gelen',
                        value: '2.770',
                        unit: 't',
                        trend: '-3%',
                        trendUp: false,
                        accentColor: AppColors.success,
                      ),
                      KpiCard(
                        label: 'Beklenen Stok',
                        value: '412',
                        unit: 't',
                        accentColor: AppColors.warning,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _QuickAccessRow(
                    onSurveyTap: () => context.push(AppRoutes.survey),
                    onOrdersTap: () => context.go(AppRoutes.orders),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text('Kritik Uyarılar', style: AppTypography.headlineMedium),
                  const SizedBox(height: AppSpacing.sm),
                  const AlertCard(
                    title: 'Ø16 Stok Kritik',
                    message: 'Beklenen stok 45t altına düştü',
                    severityColor: AppColors.critical,
                  ),
                  const SizedBox(height: 8),
                  const AlertCard(
                    title: 'Kısmi Teslimat',
                    message: 'SIP-2025-0042 — 12t eksik teslim',
                    severityColor: AppColors.warning,
                  ),
                  const SizedBox(height: 8),
                  const AlertCard(
                    title: 'Sayım Sapması',
                    message: 'Perde bölgesi -8.5t sapma tespit edildi',
                    severityColor: Color(0xFFFBBF24),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text('Süreç Durumu', style: AppTypography.headlineMedium),
                  const SizedBox(height: AppSpacing.sm),
                  GestureDetector(
                    onTap: () => context.push(AppRoutes.survey),
                    child: const ProgressCard(
                      label: 'Keşif',
                      percentage: 87,
                      color: AppColors.electricBlueLight,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const ProgressCard(label: 'Sipariş', percentage: 73, color: AppColors.info),
                  const SizedBox(height: 8),
                  const ProgressCard(label: 'Teslimat', percentage: 61, color: AppColors.success),
                  const SizedBox(height: 8),
                  const ProgressCard(label: 'Saha Sayım', percentage: 45, color: AppColors.warning),
                  const SizedBox(height: AppSpacing.lg),
                  Text('Son Aktiviteler', style: AppTypography.headlineMedium),
                  const SizedBox(height: AppSpacing.sm),
                  ..._buildTimeline(),
                  const SizedBox(height: 80),
                ]),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: AppFab(
        label: 'Yeni İşlem',
        onPressed: () => context.push(AppRoutes.newOrder),
        extended: false,
      ),
    );
  }

  static List<Widget> _buildTimeline() {
    const activities = [
      ('Teslimat alındı', 'Çolakoğlu — 48t Ø16/Ø20', Icons.local_shipping, AppColors.success),
      ('Sipariş onaylandı', 'SIP-2025-0048 — 120t', Icons.receipt_long, AppColors.info),
      ('Keşif güncellendi', 'Radye Temel rev.3', Icons.edit_note, AppColors.electricBlueLight),
      ('Sayım tamamlandı', 'Kolon bölgesi — sapma -2.1t', Icons.inventory_2, AppColors.warning),
      ('Analiz raporu', 'Haftalık performans %96', Icons.analytics, AppColors.partial),
    ];

    return activities.map((a) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: a.$4.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(a.$3, size: 18, color: a.$4),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(a.$1, style: AppTypography.titleMedium),
                  Text(a.$2, style: AppTypography.bodySmall),
                ],
              ),
            ),
          ],
        ),
      );
    }).toList();
  }
}

class _QuickAccessRow extends StatelessWidget {
  const _QuickAccessRow({
    required this.onSurveyTap,
    required this.onOrdersTap,
  });

  final VoidCallback onSurveyTap;
  final VoidCallback onOrdersTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QuickAccessCard(
            icon: Icons.search,
            label: 'Keşif',
            subtitle: '5 imalat',
            color: AppColors.electricBlueLight,
            onTap: onSurveyTap,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickAccessCard(
            icon: Icons.receipt_long,
            label: 'Siparişler',
            subtitle: '7 aktif',
            color: AppColors.info,
            onTap: onOrdersTap,
          ),
        ),
      ],
    );
  }
}

class _QuickAccessCard extends StatelessWidget {
  const _QuickAccessCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 10),
              Text(label, style: AppTypography.titleMedium),
              Text(subtitle, style: AppTypography.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

class AnalysisScreen extends StatelessWidget {
  const AnalysisScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderTabScreen(
      title: 'Analiz',
      message: 'Sağlık halkası, AI içgörüleri\nve performans analizi',
      icon: Icons.analytics_outlined,
    );
  }
}
