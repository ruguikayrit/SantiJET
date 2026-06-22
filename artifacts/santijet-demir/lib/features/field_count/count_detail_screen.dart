import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:santijet_demir/core/theme/app_colors.dart';
import 'package:santijet_demir/core/theme/app_radii.dart';
import 'package:santijet_demir/core/theme/app_spacing.dart';
import 'package:santijet_demir/core/theme/app_typography.dart';
import 'package:santijet_demir/core/widgets/app_components.dart';
import 'package:santijet_demir/data/mock/mock_field_counts.dart';
import 'package:santijet_demir/features/field_count/providers/field_count_provider.dart';

class CountDetailScreen extends ConsumerStatefulWidget {
  const CountDetailScreen({super.key, required this.countId});

  final String countId;

  @override
  ConsumerState<CountDetailScreen> createState() => _CountDetailScreenState();
}

class _CountDetailScreenState extends ConsumerState<CountDetailScreen> {
  final _selectedCauses = <String>{};

  @override
  Widget build(BuildContext context) {
    final counts = ref.watch(fieldCountsProvider);
    final record = counts.firstWhere((c) => c.id == widget.countId);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(record.title, style: AppTypography.titleLarge),
            Text(record.region, style: AppTypography.labelMedium),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.6,
            children: [
              KpiCard(
                label: 'Beklenen',
                value: record.expected.toStringAsFixed(0),
                unit: 't',
                accentColor: AppColors.electricBlueLight,
              ),
              KpiCard(
                label: 'Gerçek',
                value: record.actual.toStringAsFixed(1),
                unit: 't',
                accentColor: AppColors.info,
              ),
              KpiCard(
                label: 'Sapma',
                value: record.variance.toStringAsFixed(1),
                unit: 't',
                accentColor: record.variance.abs() > 5
                    ? AppColors.critical
                    : AppColors.warning,
              ),
              KpiCard(
                label: 'Sapma %',
                value: record.variancePercent.toStringAsFixed(1),
                unit: '%',
                accentColor: AppColors.partial,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text('Sapma Nedeni', style: AppTypography.headlineMedium),
          const SizedBox(height: 8),
          ...varianceCauses.map((cause) {
            final selected = _selectedCauses.contains(cause);
            return CheckboxListTile(
              title: Text(cause, style: AppTypography.bodyMedium),
              value: selected,
              onChanged: (v) {
                setState(() {
                  if (v == true) {
                    _selectedCauses.add(cause);
                  } else {
                    _selectedCauses.remove(cause);
                  }
                });
              },
              activeColor: AppColors.electricBlue,
              tileColor: AppColors.surfaceElevated,
              shape: RoundedRectangleBorder(
                borderRadius: AppRadii.sm,
                side: const BorderSide(color: AppColors.border),
              ),
            );
          }),
          const SizedBox(height: 20),
          Text('Fotoğraflar', style: AppTypography.headlineMedium),
          const SizedBox(height: 8),
          Row(
            children: List.generate(3, (i) {
              return Expanded(
                child: Container(
                  height: 80,
                  margin: EdgeInsets.only(right: i < 2 ? 8 : 0),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: AppRadii.md,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Icon(Icons.image_outlined, color: AppColors.textMuted),
                ),
              );
            }),
          ),
          const SizedBox(height: 20),
          Text('Aktivite Logu', style: AppTypography.headlineMedium),
          const SizedBox(height: 8),
          _LogEntry(
            time: DateFormat('HH:mm').format(record.date),
            text: 'Sayım başlatıldı — ${record.personnel}',
          ),
          _LogEntry(
            time: DateFormat('HH:mm').format(record.date.add(const Duration(hours: 1))),
            text: 'Veri girişi tamamlandı',
          ),
          _LogEntry(
            time: DateFormat('HH:mm').format(record.date.add(const Duration(hours: 2))),
            text: 'Sayım onaylandı — sapma: ${record.variance.toStringAsFixed(1)}t',
          ),
        ],
      ),
    );
  }
}

class _LogEntry extends StatelessWidget {
  const _LogEntry({required this.time, required this.text});

  final String time;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(time, style: AppTypography.labelMedium.copyWith(color: AppColors.electricBlueLight)),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: AppTypography.bodyMedium)),
        ],
      ),
    );
  }
}
