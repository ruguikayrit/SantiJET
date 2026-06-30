import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:santijet_demir/core/theme/app_colors.dart';
import 'package:santijet_demir/core/theme/app_radii.dart';
import 'package:santijet_demir/core/theme/app_spacing.dart';
import 'package:santijet_demir/core/theme/app_typography.dart';
import 'package:santijet_demir/core/widgets/app_components.dart';
import 'package:santijet_demir/data/mock/mock_field_counts.dart';
import 'package:santijet_demir/domain/entities/field_count.dart';
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
    final record = counts.cast<FieldCountRecord?>().firstWhere(
          (item) => item?.id == widget.countId,
          orElse: () => null,
        );

    if (record == null) {
      return Scaffold(
        backgroundColor: AppColors.canvas,
        appBar: AppBar(title: const Text('Sayım Detayı')),
        body: const Center(child: Text('Sayım kaydı bulunamadı')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(record.title, style: AppTypography.titleLarge),
            Text(
              DateFormat('d MMM yyyy · HH:mm').format(record.date),
              style: AppTypography.labelMedium,
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          if (record.personnel.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                'Personel: ${record.personnel}',
                style: AppTypography.bodyMedium,
              ),
            ),
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
                value: record.totalExpectedStock.toStringAsFixed(0),
                unit: 't',
                accentColor: AppColors.electricBlueLight,
              ),
              KpiCard(
                label: 'Sayım',
                value: record.actual.toStringAsFixed(1),
                unit: 't',
                accentColor: AppColors.info,
              ),
              KpiCard(
                label: 'Kullanılan',
                value: record.totalUsed.toStringAsFixed(1),
                unit: 't',
                accentColor: AppColors.warning,
              ),
              KpiCard(
                label: 'Sapma',
                value: record.variance.toStringAsFixed(1),
                unit: 't',
                accentColor: record.variance.abs() > 5
                    ? AppColors.critical
                    : AppColors.warning,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text('Çap Detayı', style: AppTypography.headlineMedium),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: AppRadii.md,
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                _LineTableHeader(),
                ...record.lines.map(_LineTableRow.new),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text('Sapma Nedeni', style: AppTypography.headlineMedium),
          const SizedBox(height: 8),
          ...varianceCauses.map((cause) {
            final selected = _selectedCauses.contains(cause);
            return CheckboxListTile(
              title: Text(cause, style: AppTypography.bodyMedium),
              value: selected,
              onChanged: (value) {
                setState(() {
                  if (value == true) {
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
        ],
      ),
    );
  }
}

class _LineTableHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          for (final label in ['ÇAP', 'TESLİM', 'BEKLENEN', 'SAYIM', 'KULLANILAN'])
            Expanded(
              child: Text(
                label,
                style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
        ],
      ),
    );
  }
}

class _LineTableRow extends StatelessWidget {
  const _LineTableRow(this.line);

  final FieldCountLineRecord line;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Ø${line.diameter}',
              style: AppTypography.titleMedium.copyWith(
                color: AppColors.diameterColor(line.diameter),
              ),
            ),
          ),
          Expanded(
            child: Text('${line.delivered.toStringAsFixed(1)}t'),
          ),
          Expanded(
            child: Text('${line.plannedUsage.toStringAsFixed(1)}t'),
          ),
          Expanded(
            child: Text('${line.actual.toStringAsFixed(1)}t'),
          ),
          Expanded(
            child: Text('${line.actualUsed.toStringAsFixed(1)}t'),
          ),
        ],
      ),
    );
  }
}
