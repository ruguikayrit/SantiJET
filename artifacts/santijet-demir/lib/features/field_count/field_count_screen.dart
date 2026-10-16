import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:santijet_demir/core/format/app_format.dart';
import 'package:santijet_demir/core/routing/app_routes.dart';
import 'package:santijet_demir/core/theme/app_typography.dart';
import 'package:santijet_demir/core/widgets/app_components.dart';
import 'package:santijet_demir/core/widgets/diameter_status_cells.dart';
import 'package:santijet_demir/core/widgets/santijet_header.dart';
import 'package:santijet_demir/core/widgets/shell_tab_guard.dart';
import 'package:santijet_demir/domain/entities/field_count.dart';
import 'package:santijet_demir/features/auth/providers/membership_permission_provider.dart';
import 'package:santijet_demir/features/field_count/providers/field_count_provider.dart';
import 'package:santijet_demir/features/projects/providers/project_provider.dart';

class FieldCountScreen extends ConsumerWidget {
  const FieldCountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasActiveProject = ref.watch(activeProjectProvider) != null;
    final counts = ref.watch(fieldCountsProvider);
    final canEdit = ref.watch(canEditFieldCountProvider);
    final latest = counts.isNotEmpty ? counts.first : null;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FA),
      floatingActionButtonLocation: ShellAddFab.location,
      floatingActionButton: hasActiveProject && canEdit
          ? ShellAddFab(
              heroTag: 'new-count',
              onPressed: () => context.push(AppRoutes.newCount),
            )
          : null,
      body: Column(
        children: [
          const SantijetHeader(subtitle: 'Saha Sayım'),
          if (!hasActiveProject)
            const Expanded(child: ActiveProjectGate(child: SizedBox.shrink()))
          else
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(16, 16, 16, AppFab.scrollClearanceOf(context)),
                children: [
                  if (latest != null) ...[
                    _LatestCountKpi(record: latest),
                    const SizedBox(height: 16),
                  ],
                  Row(
                    children: [
                      Text(
                        'Sayım Kayıt Listesi',
                        style: AppTypography.titleMedium.copyWith(
                          color: const Color(0xFF1C2430),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${counts.length} kayıt',
                        style: AppTypography.labelMedium.copyWith(
                          color: const Color(0xFF8B95A5),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (counts.isEmpty)
                    const _EmptyCountList()
                  else
                    for (final record in counts) ...[
                      _CountRecordTile(
                        record: record,
                        onTap: canEdit
                            ? () => context.push(AppRoutes.editCount(record.id))
                            : () => context.push(AppRoutes.countDetail(record.id)),
                      ),
                      const SizedBox(height: 10),
                    ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _LatestCountKpi extends StatelessWidget {
  const _LatestCountKpi({required this.record});

  final FieldCountRecord record;

  @override
  Widget build(BuildContext context) {
    final lines = record.lines.where((line) => line.actual > 0).toList()
      ..sort((a, b) => a.diameter.compareTo(b.diameter));
    final total = lines.fold<double>(0, (sum, line) => sum + line.actual);
    final when = DateFormat('dd.MM.yyyy · HH:mm').format(record.date);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE6EBF2)),
        boxShadow: const [
          BoxShadow(color: Color(0x0F0F2744), blurRadius: 14, offset: Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Son sayım',
                style: AppTypography.titleMedium.copyWith(
                  color: const Color(0xFF1C2430),
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Text(when, style: AppTypography.labelMedium.copyWith(color: const Color(0xFF8B95A5))),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            AppFormat.tonnage(total),
            style: AppTypography.headlineMedium.copyWith(
              color: const Color(0xFF2563EB),
              fontWeight: FontWeight.w800,
            ),
          ),
          if (lines.isNotEmpty) ...[
            const SizedBox(height: 14),
            DiameterStatusCells(
              items: [
                for (final line in lines)
                  DiameterStatusCellItem(
                    diameter: line.diameter,
                    bottomLabel: AppFormat.tonnage(line.actual),
                    sortValue: line.actual,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyCountList extends StatelessWidget {
  const _EmptyCountList();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE6EBF2)),
      ),
      child: Column(
        children: [
          const Icon(Icons.inventory_2_outlined, size: 34, color: Color(0xFF94A3B8)),
          const SizedBox(height: 8),
          Text(
            'Henüz sayım kaydı yok',
            style: AppTypography.titleMedium.copyWith(
              color: const Color(0xFF1C2430),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Sağ alttaki + ile sahadaki demir tonajını kaydedin.',
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall.copyWith(color: const Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }
}

class _CountRecordTile extends StatelessWidget {
  const _CountRecordTile({required this.record, required this.onTap});

  final FieldCountRecord record;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('dd.MM.yyyy · HH:mm').format(record.date);
    final lines = record.lines.where((line) => line.actual > 0).toList()
      ..sort((a, b) => a.diameter.compareTo(b.diameter));
    final total = lines.fold<double>(0, (sum, line) => sum + line.actual);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE6EBF2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      record.region.isNotEmpty ? record.region : record.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.titleMedium.copyWith(
                        color: const Color(0xFF1C2430),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Text(
                    date,
                    style: AppTypography.labelMedium.copyWith(color: const Color(0xFF8B95A5)),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8), size: 20),
                ],
              ),
              if (record.personnel.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  record.personnel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySmall.copyWith(color: const Color(0xFF64748B)),
                ),
              ],
              const SizedBox(height: 10),
              Text(
                AppFormat.tonnage(total),
                style: AppTypography.titleLarge.copyWith(
                  color: const Color(0xFF2563EB),
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (lines.isNotEmpty) ...[
                const SizedBox(height: 12),
                DiameterStatusCells(
                  items: [
                    for (final line in lines)
                      DiameterStatusCellItem(
                        diameter: line.diameter,
                        bottomLabel: AppFormat.tonnage(line.actual),
                        sortValue: line.actual,
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
