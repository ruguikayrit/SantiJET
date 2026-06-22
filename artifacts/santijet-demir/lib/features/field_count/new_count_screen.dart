import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:santijet_demir/core/theme/app_colors.dart';
import 'package:santijet_demir/core/theme/app_radii.dart';
import 'package:santijet_demir/core/theme/app_spacing.dart';
import 'package:santijet_demir/core/theme/app_typography.dart';
import 'package:santijet_demir/core/widgets/app_components.dart';
import 'package:santijet_demir/data/mock/mock_field_counts.dart';
import 'package:santijet_demir/features/field_count/providers/field_count_provider.dart';

class NewCountScreen extends ConsumerWidget {
  const NewCountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(newCountDraftProvider);
    final notifier = ref.read(newCountDraftProvider.notifier);
    final rows = getMockReconciliationRows();

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(title: const Text('Yeni Sayım')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Text('Tarih', style: AppTypography.titleMedium),
          const SizedBox(height: 8),
          ListTile(
            tileColor: AppColors.surfaceElevated,
            shape: RoundedRectangleBorder(
              borderRadius: AppRadii.md,
              side: const BorderSide(color: AppColors.border),
            ),
            leading: const Icon(Icons.calendar_today, color: AppColors.electricBlueLight),
            title: Text(
              draft.date != null
                  ? '${draft.date!.day}.${draft.date!.month}.${draft.date!.year}'
                  : 'Tarih seçin',
            ),
          ),
          const SizedBox(height: 16),
          Text('Personel', style: AppTypography.titleMedium),
          const SizedBox(height: 8),
          TextField(
            decoration: const InputDecoration(hintText: 'Sayım yapan personel'),
            onChanged: notifier.setPersonnel,
          ),
          const SizedBox(height: 16),
          Text('Şantiye Bölgesi', style: AppTypography.titleMedium),
          const SizedBox(height: 8),
          TextField(
            decoration: const InputDecoration(hintText: 'Örn: Blok A — Kolon'),
            onChanged: notifier.setRegion,
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: AppRadii.md,
              border: Border.all(color: AppColors.border, style: BorderStyle.solid),
            ),
            child: Column(
              children: [
                Icon(Icons.camera_alt_outlined, size: 40, color: AppColors.textMuted),
                const SizedBox(height: 8),
                Text('Fotoğraf Yükle', style: AppTypography.bodyMedium),
                Text('Saha fotoğrafı ekleyin', style: AppTypography.bodySmall),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text('Sayım Girişi', style: AppTypography.headlineMedium),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: AppRadii.md,
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: AppColors.border)),
                  ),
                  child: Row(
                    children: [
                      Expanded(child: Text('ÇAP', style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w700))),
                      Expanded(child: Text('BEKLENEN', style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w700))),
                      Expanded(child: Text('GERÇEK', style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w700))),
                      Expanded(child: Text('SAPMA', style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w700))),
                    ],
                  ),
                ),
                ...rows.take(5).map((row) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Ø${row.diameter}',
                            style: AppTypography.titleMedium.copyWith(
                              color: AppColors.diameterColor(row.diameter),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text('${row.expected.toStringAsFixed(0)}t', style: AppTypography.bodyMedium),
                        ),
                        Expanded(
                          child: TextField(
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              isDense: true,
                              hintText: row.counted.toStringAsFixed(0),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                              suffixText: 't',
                            ),
                          ),
                        ),
                        Expanded(
                          child: SapmaTag(value: row.variance),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () {
              notifier.reset();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Sayım tamamlandı'),
                  backgroundColor: AppColors.success,
                ),
              );
              context.pop();
            },
            child: const Text('Tamamla'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Taslak kaydedildi')),
              );
              context.pop();
            },
            child: const Text('Taslak Kaydet'),
          ),
        ],
      ),
    );
  }
}
