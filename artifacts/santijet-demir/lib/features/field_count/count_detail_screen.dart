import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:santijet_demir/core/theme/app_colors.dart';
import 'package:santijet_demir/core/theme/app_radii.dart';
import 'package:santijet_demir/core/theme/app_spacing.dart';
import 'package:santijet_demir/core/theme/app_typography.dart';
import 'package:santijet_demir/core/widgets/app_components.dart';
import 'package:santijet_demir/core/widgets/app_table_header.dart';
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
  late final TextEditingController _otherNoteController;
  Timer? _persistTimer;
  bool _initialized = false;

  static const _persistDelay = Duration(milliseconds: 400);

  @override
  void initState() {
    super.initState();
    _otherNoteController = TextEditingController();
  }

  @override
  void dispose() {
    _persistTimer?.cancel();
    _otherNoteController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant CountDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.countId != widget.countId) {
      _initialized = false;
    }
  }

  void _syncFromRecord(FieldCountRecord record) {
    _selectedCauses
      ..clear()
      ..addAll(record.varianceCauses);
    if (_otherNoteController.text != record.varianceOtherNote) {
      _otherNoteController.text = record.varianceOtherNote;
    }
    _initialized = true;
  }

  void _schedulePersist() {
    _persistTimer?.cancel();
    _persistTimer = Timer(_persistDelay, _persistVarianceCauses);
  }

  Future<void> _persistVarianceCauses() async {
    await ref.read(fieldCountsProvider.notifier).updateVarianceCauses(
          countId: widget.countId,
          causes: _selectedCauses.toList(),
          otherNote: _otherNoteController.text,
        );
  }

  void _toggleCause(String cause, bool? selected) {
    setState(() {
      if (selected == true) {
        _selectedCauses.add(cause);
      } else {
        _selectedCauses.remove(cause);
        if (cause == varianceCauseOther) {
          _otherNoteController.clear();
        }
      }
    });
    _schedulePersist();
  }

  bool get _showOtherNoteField => _selectedCauses.contains(varianceCauseOther);
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

    if (!_initialized) {
      _syncFromRecord(record);
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
                label: 'Planlanan kullanım',
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
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: CheckboxListTile(
                title: Text(cause, style: AppTypography.bodyMedium),
                value: selected,
                onChanged: (value) => _toggleCause(cause, value),
                activeColor: AppColors.electricBlue,
                tileColor: AppColors.surfaceElevated,
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadii.sm,
                  side: BorderSide(color: AppColors.border),
                ),
              ),
            );
          }),
          if (_showOtherNoteField) ...[
            const SizedBox(height: 4),
            TextField(
              controller: _otherNoteController,
              maxLines: 3,
              minLines: 2,
              style: AppTypography.bodyMedium,
              decoration: InputDecoration(
                labelText: 'Diğer — açıklama girin',
                hintText: 'Sapma nedenini kısaca yazın…',
                alignLabelWithHint: true,
                filled: true,
                fillColor: AppColors.surfaceElevated,
                border: OutlineInputBorder(
                  borderRadius: AppRadii.sm,
                  borderSide: BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: AppRadii.sm,
                  borderSide: BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: AppRadii.sm,
                  borderSide: BorderSide(
                    color: AppColors.electricBlueLight.withValues(alpha: 0.65),
                  ),
                ),
              ),
              onChanged: (_) => _schedulePersist(),
              onEditingComplete: _persistVarianceCauses,
            ),
          ],
        ],
      ),
    );
  }
}

class _LineTableHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const AppTableHeaderRow(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      cells: [
        AppTableHeaderCell('ÇAP'),
        AppTableHeaderCell('TESLİM'),
        AppTableHeaderCell('BEKLENEN'),
        AppTableHeaderCell('SAYIM'),
        AppTableHeaderCell('KULLANILAN'),
      ],
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
              textAlign: TextAlign.center,
              style: AppTypography.titleMedium.copyWith(
                color: AppColors.diameterColor(line.diameter),
              ),
            ),
          ),
          Expanded(
            child: Text(
              '${line.delivered.toStringAsFixed(1)}t',
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Text(
              '${line.plannedUsage.toStringAsFixed(1)}t',
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Text(
              '${line.actual.toStringAsFixed(1)}t',
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Text(
              '${line.actualUsed.toStringAsFixed(1)}t',
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
