import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:santijet_demir/core/routing/app_routes.dart';
import 'package:santijet_demir/core/theme/app_colors.dart';
import 'package:santijet_demir/core/theme/app_radii.dart';
import 'package:santijet_demir/core/theme/app_spacing.dart';
import 'package:santijet_demir/core/theme/app_typography.dart';
import 'package:santijet_demir/domain/entities/rebar_metraj.dart';
import 'package:santijet_demir/features/projects/providers/project_provider.dart';
import 'package:santijet_demir/features/rebar_metraj/providers/rebar_metraj_storage_provider.dart';
import 'package:santijet_demir/features/survey/providers/survey_provider.dart';

/// Kaydedilmiş CAD metraj kayıtları — keşif kart formatında.
class SavedMetrajListTab extends ConsumerWidget {
  const SavedMetrajListTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final records = ref.watch(savedRebarMetrajProvider);
    final project = ref.watch(surveyProjectProvider);
    final projectId = ref.watch(activeProjectIdProvider);
    final dateFormat = DateFormat('dd.MM.yyyy HH:mm', 'tr_TR');

    if (projectId == null) {
      return _EmptyState(
        icon: Icons.folder_off_outlined,
        title: 'Proje seçilmedi',
        subtitle: 'Metraj kayıtları proje bazında saklanır.',
      );
    }

    if (records.isEmpty) {
      return _EmptyState(
        icon: Icons.save_outlined,
        title: 'Henüz metraj kaydı yok',
        subtitle:
            'Demir Metraj sekmesinde CAD yükleyip "Sonucu Kaydet" ile buraya ekleyin.',
        actionLabel: 'Demir Metraj\'a git',
        onAction: () => ref.read(surveyTabIndexProvider.notifier).state = 1,
      );
    }

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: AppRadii.md,
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Metraj Kayıtları', style: AppTypography.headlineMedium),
                    Text(
                      '${records.length} kayıt · ${project.projectName}',
                      style: AppTypography.bodySmall,
                    ),
                  ],
                ),
              ),
              Text(
                '${records.fold<double>(0, (s, r) => s + r.result.totalTonnage).toStringAsFixed(1)} t',
                style: AppTypography.kpiValue.copyWith(fontSize: 22),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ...records.map(
          (record) => _SavedMetrajCard(
            record: record,
            dateFormat: dateFormat,
            onOpen: () => context.push(AppRoutes.savedMetrajDetail(record.id)),
          ),
        ),
      ],
    );
  }
}

class _SavedMetrajCard extends StatelessWidget {
  const _SavedMetrajCard({
    required this.record,
    required this.dateFormat,
    required this.onOpen,
  });

  final SavedRebarMetraj record;
  final DateFormat dateFormat;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final result = record.result;
    final tonnage = result.totalTonnage;
    final diameters = result.lines.map((line) => line.diameter).toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: AppRadii.md,
        border: Border.all(color: AppColors.border),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onOpen,
          borderRadius: AppRadii.md,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        record.displayTitle,
                        style: AppTypography.titleLarge,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: AppColors.textMuted),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  dateFormat.format(record.savedAt),
                  style: AppTypography.labelMedium,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      '${tonnage.toStringAsFixed(2)} t',
                      style: AppTypography.kpiValue.copyWith(fontSize: 22),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${result.totalBarCount} çubuk',
                      style: AppTypography.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  diameters.map((d) => 'Ø$d').join(' · '),
                  style: AppTypography.bodySmall,
                ),
                if (record.surveyImalatName != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Keşif: ${record.surveyImalatName}',
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.success,
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: AppRadii.full,
                  child: LinearProgressIndicator(
                    value: 1,
                    minHeight: 4,
                    backgroundColor: AppColors.border,
                    color: AppColors.electricBlueLight,
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: onOpen,
                    child: const Text('Metraj Detayı →'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: AppColors.textMuted),
            const SizedBox(height: 16),
            Text(title, style: AppTypography.headlineMedium, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(subtitle, style: AppTypography.bodySmall, textAlign: TextAlign.center),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 20),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

extension SavedMetrajTitle on SavedRebarMetraj {
  String get displayTitle {
    return result.fileName.replaceAll(
      RegExp(r'\.(dwg|dxf)$', caseSensitive: false),
      '',
    );
  }
}
