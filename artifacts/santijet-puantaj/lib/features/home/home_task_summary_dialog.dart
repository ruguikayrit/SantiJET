import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design_system/sj_status_badge.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/puantaj_date.dart';
import '../../data/providers/tasks_provider.dart';
import '../../domain/entities/site_task.dart';
import '../../domain/enums/task_status.dart';

/// Teslim tarihine göre aciliyet rengi ve etiketi.
class TaskUrgency {
  const TaskUrgency({required this.color, required this.label});

  final Color color;
  final String label;

  factory TaskUrgency.of(SiteTask task, DateTime today) {
    final due = task.latestDeliveryDate;
    final dueDay =
        due == null ? null : DateTime(due.year, due.month, due.day);
    if (dueDay == null) {
      return TaskUrgency(color: AppColors.info, label: task.dueDate);
    }
    if (dueDay.isBefore(today)) {
      final days = today.difference(dueDay).inDays;
      return TaskUrgency(
        color: AppColors.critical,
        label: days == 1 ? '1 gün gecikti' : '$days gün gecikti',
      );
    }
    if (dueDay == today) {
      return const TaskUrgency(
        color: AppColors.warning,
        label: 'Bugün teslim',
      );
    }
    final days = dueDay.difference(today).inDays;
    return TaskUrgency(
      color: AppColors.info,
      label: days == 1 ? 'Yarın teslim' : '$days gün kaldı',
    );
  }
}

Color taskStatusColor(TaskStatus status) => switch (status) {
      TaskStatus.todo => AppColors.info,
      TaskStatus.doing => AppColors.warning,
      TaskStatus.done => AppColors.success,
    };

/// Anasayfadaki acil görev satırına dokununca açılan ortalanmış özet.
Future<void> showHomeTaskSummaryDialog(
  BuildContext context, {
  required SiteTask task,
}) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  return showDialog<void>(
    context: context,
    builder: (ctx) => _HomeTaskSummaryDialog(
      taskId: task.id,
      initialTask: task,
      today: today,
    ),
  );
}

class _HomeTaskSummaryDialog extends ConsumerWidget {
  const _HomeTaskSummaryDialog({
    required this.taskId,
    required this.initialTask,
    required this.today,
  });

  final String taskId;
  final SiteTask initialTask;
  final DateTime today;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tasks = ref.watch(tasksProvider);
    var task = initialTask;
    for (final t in tasks) {
      if (t.id == taskId) {
        task = t;
        break;
      }
    }
    final urgency = TaskUrgency.of(task, today);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: AppRadii.md),
      title: Text(task.title, style: theme.textTheme.titleMedium),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                SJStatusBadge(
                  label: task.status.label,
                  color: taskStatusColor(task.status),
                ),
                if (task.category.trim().isNotEmpty)
                  SJStatusBadge(
                    label: task.category.trim(),
                    color: AppColors.electricBlue,
                    icon: Icons.category_outlined,
                  ),
                if (task.status != TaskStatus.done && urgency.label.isNotEmpty)
                  SJStatusBadge(
                    label: urgency.label,
                    color: urgency.color,
                    icon: Icons.schedule,
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Görev aksiyonu',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                for (final s in TaskStatus.values) ...[
                  Expanded(
                    child: _StatusActionButton(
                      label: s.label,
                      selected: task.status == s,
                      color: taskStatusColor(s),
                      onTap: () {
                        ref.read(tasksProvider.notifier).setStatus(task.id, s);
                        if (s == TaskStatus.done && context.mounted) {
                          final delivery = task.actualDeliveryDate.trim().isNotEmpty
                              ? task.actualDeliveryDate.trim()
                              : PuantajDate.today();
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Görev tamamlandı · Gerçek teslim: $delivery',
                              ),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                  if (s != TaskStatus.done) const SizedBox(width: 6),
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            _SummaryRow(
              icon: Icons.event_available_outlined,
              label: 'En erken başlangıç',
              value: task.earliestStart,
            ),
            _SummaryRow(
              icon: Icons.flag_outlined,
              label: 'En geç teslim',
              value: task.dueDate,
            ),
            if (task.status == TaskStatus.done ||
                task.actualDeliveryDate.trim().isNotEmpty)
              _SummaryRow(
                icon: Icons.task_alt_outlined,
                label: 'Gerçek teslim',
                value: task.actualDeliveryDate,
              ),
            _SummaryRow(
              icon: Icons.person_outline,
              label: 'Atanan',
              value: task.assignee,
            ),
            _SummaryRow(
              icon: Icons.badge_outlined,
              label: 'Atayan',
              value: task.assignerName,
            ),
            if (task.description.trim().isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Açıklama',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(task.description.trim(), style: theme.textTheme.bodyMedium),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Kapat'),
        ),
      ],
    );
  }
}

class _StatusActionButton extends StatelessWidget {
  const _StatusActionButton({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ink = AppColors.statusInkOnCard(color);
    return Material(
      color: selected ? color.withValues(alpha: 0.22) : color.withValues(alpha: 0.08),
      borderRadius: AppRadii.sm,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.sm,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          decoration: BoxDecoration(
            borderRadius: AppRadii.sm,
            border: Border.all(
              color: selected ? color : color.withValues(alpha: 0.35),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              color: ink,
              height: 1.15,
            ),
          ),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = value.trim().isEmpty ? '—' : value.trim();
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(text, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
