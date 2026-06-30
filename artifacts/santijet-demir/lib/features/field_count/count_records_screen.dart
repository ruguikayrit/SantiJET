import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:santijet_demir/core/format/app_format.dart';
import 'package:santijet_demir/core/routing/app_routes.dart';
import 'package:santijet_demir/core/theme/app_colors.dart';
import 'package:santijet_demir/core/theme/app_radii.dart';
import 'package:santijet_demir/core/theme/app_spacing.dart';
import 'package:santijet_demir/core/theme/app_typography.dart';
import 'package:santijet_demir/core/widgets/app_components.dart';
import 'package:santijet_demir/core/widgets/empty_states.dart';
import 'package:santijet_demir/domain/entities/field_count.dart';
import 'package:santijet_demir/features/field_count/providers/field_count_provider.dart';

class CountRecordsScreen extends ConsumerStatefulWidget {
  const CountRecordsScreen({super.key});

  @override
  ConsumerState<CountRecordsScreen> createState() => _CountRecordsScreenState();
}

class _CountRecordsScreenState extends ConsumerState<CountRecordsScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final records = ref.watch(fieldCountsProvider);
    final filtered = _searchQuery.isEmpty
        ? records
        : records.where((record) {
            final query = _searchQuery.toLowerCase();
            return record.title.toLowerCase().contains(query) ||
                record.region.toLowerCase().contains(query) ||
                record.personnel.toLowerCase().contains(query);
          }).toList();

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(title: const Text('Sayım Kayıtları')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: AppSearchBar(
              hint: 'Bölge, personel ara...',
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? const Center(
                    child: ModuleEmptyState(type: EmptyStateType.noCount),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final record = filtered[index];
                      return _CountRecordCard(
                        record: record,
                        onTap: () => context.push(AppRoutes.countDetail(record.id)),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: AppFab(
        label: 'Yeni Sayım',
        onPressed: () => context.push(AppRoutes.newCount),
      ),
    );
  }
}

class _CountRecordCard extends StatelessWidget {
  const _CountRecordCard({
    required this.record,
    required this.onTap,
  });

  final FieldCountRecord record;
  final VoidCallback onTap;

  Color get _statusColor => switch (record.status) {
        'completed' => AppColors.success,
        'critical' => AppColors.critical,
        'warning' => AppColors.warning,
        _ => AppColors.textMuted,
      };

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormat('d MMM yyyy · HH:mm').format(record.date);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.md,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: AppRadii.md,
            border: Border.all(color: AppColors.border),
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: _statusColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      bottomLeft: Radius.circular(12),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(record.title, style: AppTypography.titleMedium),
                            ),
                            StatusBadge(
                              label: _statusLabel(record.status),
                              color: _statusColor,
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(dateLabel, style: AppTypography.bodySmall),
                        if (record.personnel.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(record.personnel, style: AppTypography.bodySmall),
                        ],
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            _MetricChip(
                              label: 'Beklenen',
                              value: '${AppFormat.tonnage(record.expected)}t',
                            ),
                            const SizedBox(width: 8),
                            _MetricChip(
                              label: 'Sayım',
                              value: '${AppFormat.tonnage(record.actual)}t',
                            ),
                            const Spacer(),
                            SapmaTag(value: record.variance),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _statusLabel(String status) => switch (status) {
        'completed' => 'Tamam',
        'critical' => 'Kritik',
        'warning' => 'Sapmalı',
        _ => 'Kayıt',
      };
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.labelMedium),
        Text(value, style: AppTypography.titleMedium),
      ],
    );
  }
}
