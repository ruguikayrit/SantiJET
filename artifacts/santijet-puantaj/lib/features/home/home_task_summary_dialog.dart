import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design_system/sj_status_badge.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/providers/active_operator_provider.dart';
import '../../data/providers/tasks_provider.dart';
import '../../domain/catalogs/task_tags.dart';
import '../../domain/entities/site_task.dart';
import '../../domain/enums/task_status.dart';
import '../tasks/widgets/task_actual_date_sheet.dart';

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
      TaskStatus.started => AppColors.partial,
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

  Future<void> _onStatus(
    BuildContext context,
    WidgetRef ref,
    SiteTask task,
    TaskStatus status,
  ) async {
    final operator = ref.read(activeOperatorProvider);
    if (operator == null) return;
    if (!TaskStatusRules.canTransition(task.status, status)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Bu geçiş yapılamaz. Sıra: Yapılacak → Başlandı → '
            'Devam ediyor → Tamamlandı.',
          ),
        ),
      );
      return;
    }
    String? actualStart;
    String? actualDelivery;
    if (TaskStatusRules.needsActualDate(status)) {
      final picked = await showTaskActualDateSheet(
        context,
        forStatus: status,
      );
      if (picked == null || !context.mounted) return;
      if (status == TaskStatus.started) {
        actualStart = picked;
      } else {
        actualDelivery = picked;
      }
    }
    final result = ref.read(tasksProvider.notifier).applyOrRequestStatus(
          id: task.id,
          status: status,
          actor: operator,
          actualStartDate: actualStart,
          actualDeliveryDate: actualDelivery,
        );
    if (!context.mounted) return;
    if (result == 'pending') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Durum değişikliği atayana onay için gönderildi.'),
        ),
      );
    } else if (result == 'applied' && status == TaskStatus.done) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Görev tamamlandı · Gerçekleşen bitiş: '
            '${actualDelivery ?? task.actualDeliveryDate}',
          ),
        ),
      );
    } else if (result == 'rejected') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Durum güncellenemedi.')),
      );
    }
  }

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
                if (TaskTagCatalog.normalize(task.tag).isNotEmpty)
                  SJStatusBadge(
                    label: TaskTagCatalog.cardLabel(task.tag),
                    color: TaskTagCatalog.accentFor(task.tag),
                    icon: Icons.label_outline,
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
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final s in TaskStatus.values)
                  SizedBox(
                    width: 120,
                    child: _StatusActionButton(
                      label: s.shortLabel,
                      selected: task.status == s,
                      color: taskStatusColor(s),
                      enabled: task.status == s ||
                          TaskStatusRules.canTransition(task.status, s),
                      onTap: () => _onStatus(context, ref, task, s),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            _SummaryRow(
              icon: Icons.event_available_outlined,
              label: 'Planlanan başlangıç',
              value: task.earliestStart,
            ),
            _SummaryRow(
              icon: Icons.flag_outlined,
              label: 'Planlanan bitiş',
              value: task.dueDate,
            ),
            if (task.actualStartDate.trim().isNotEmpty)
              _SummaryRow(
                icon: Icons.play_circle_outline,
                label: 'Gerçekleşen başlangıç',
                value: task.actualStartDate,
              ),
            if (task.status == TaskStatus.done ||
                task.actualDeliveryDate.trim().isNotEmpty)
              _SummaryRow(
                icon: Icons.task_alt_outlined,
                label: 'Gerçekleşen bitiş',
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
                task.description.trim(),
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Kapat'),
        ),
      ],
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
    if (value.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: AppSpacing.sm),
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
                Text(value, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusActionButton extends StatelessWidget {
  const _StatusActionButton({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
    this.enabled = true,
  });

  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ink = !enabled
        ? theme.disabledColor
        : selected
            ? AppColors.readableOn(color)
            : theme.colorScheme.onSurfaceVariant;
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: Material(
        color: selected ? color : Colors.transparent,
        borderRadius: AppRadii.sm,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: AppRadii.sm,
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            decoration: BoxDecoration(
              borderRadius: AppRadii.sm,
              border: Border.all(
                color: selected ? color : color.withValues(alpha: 0.4),
              ),
            ),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: ink,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
