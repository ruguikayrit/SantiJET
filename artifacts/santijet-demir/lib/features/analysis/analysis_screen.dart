import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:santijet_demir/core/routing/app_routes.dart';
import 'package:santijet_demir/core/theme/app_colors.dart';
import 'package:santijet_demir/core/theme/app_radii.dart';
import 'package:santijet_demir/core/theme/app_spacing.dart';
import 'package:santijet_demir/core/theme/app_typography.dart';
import 'package:santijet_demir/core/widgets/app_components.dart';
import 'package:santijet_demir/core/widgets/health_ring.dart';
import 'package:santijet_demir/core/widgets/santijet_header.dart';
import 'package:santijet_demir/domain/entities/analysis.dart';
import 'package:santijet_demir/features/analysis/providers/analysis_provider.dart';

class AnalysisScreen extends ConsumerWidget {
  const AnalysisScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(analysisSummaryProvider);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(
              child: SantijetHeader(subtitle: 'ANALİZ', showNotification: false),
            ),
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
                    children: [
                      KpiCard(
                        label: 'Toplam Keşif',
                        value: summary.totalSurvey.toStringAsFixed(0),
                        unit: 't',
                        accentColor: AppColors.electricBlueLight,
                      ),
                      KpiCard(
                        label: 'Sipariş',
                        value: summary.totalOrdered.toStringAsFixed(0),
                        unit: 't',
                        accentColor: AppColors.info,
                      ),
                      KpiCard(
                        label: 'Teslim',
                        value: summary.totalDelivered.toStringAsFixed(0),
                        unit: 't',
                        accentColor: AppColors.success,
                      ),
                      KpiCard(
                        label: 'Sapma',
                        value: summary.variance.toStringAsFixed(0),
                        unit: 't',
                        accentColor: AppColors.warning,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Center(child: HealthRing(score: summary.healthScore)),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Icon(Icons.bolt, color: AppColors.warning, size: 20),
                      const SizedBox(width: 8),
                      Text('AI İçgörüleri', style: AppTypography.headlineMedium),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ...summary.insights.map((i) => _InsightCard(insight: i)),
                  const SizedBox(height: 16),
                  Text('Çap Bazlı Teslim Oranı', style: AppTypography.headlineMedium),
                  const SizedBox(height: 10),
                  ...summary.diameterRates.map((d) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 40,
                            child: Text(
                              'Ø${d.diameter}',
                              style: AppTypography.titleMedium.copyWith(
                                color: AppColors.diameterColor(d.diameter),
                              ),
                            ),
                          ),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: AppRadii.full,
                              child: LinearProgressIndicator(
                                value: d.rate / 100,
                                minHeight: 6,
                                backgroundColor: AppColors.border,
                                color: AppColors.diameterColor(d.diameter),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('%${d.rate.toStringAsFixed(0)}', style: AppTypography.labelMedium),
                          const SizedBox(width: 8),
                          SapmaTag(value: d.variance),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 16),
                  _NavCard(
                    icon: Icons.bar_chart,
                    title: 'Performans Analizi',
                    subtitle: 'Sapma grafikleri · tedarikçi karşılaştırma',
                    onTap: () => context.push(AppRoutes.performanceAnalysis),
                  ),
                  const SizedBox(height: 10),
                  _NavCard(
                    icon: Icons.description,
                    title: 'Raporlar',
                    subtitle: 'PDF · Excel export · paylaşım',
                    onTap: () => context.push(AppRoutes.reports),
                  ),
                  const SizedBox(height: 10),
                  _NavCard(
                    icon: Icons.inventory_2,
                    title: 'Saha Sayım',
                    subtitle: 'Mutabakat tablosu · sayım detayları',
                    onTap: () => context.go(AppRoutes.fieldCount),
                  ),
                  const SizedBox(height: 80),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({required this.insight});

  final AiInsight insight;

  IconData get _icon => switch (insight.iconName) {
        'warning' => Icons.warning_amber,
        'trending_up' => Icons.trending_up,
        'analytics' => Icons.analytics,
        'local_shipping' => Icons.local_shipping,
        _ => Icons.lightbulb_outline,
      };

  @override
  Widget build(BuildContext context) {
    final color = Color(insight.colorValue);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: AppRadii.md,
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(_icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(insight.title, style: AppTypography.titleMedium),
                const SizedBox(height: 2),
                Text(insight.message, style: AppTypography.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavCard extends StatelessWidget {
  const _NavCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.md,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: AppRadii.md,
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Icon(icon, color: AppColors.electricBlueLight),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTypography.titleMedium),
                    Text(subtitle, style: AppTypography.bodySmall),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
