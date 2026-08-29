import 'package:flutter/material.dart';

import '../../../core/design_system/sj_modal.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/puantaj_date.dart';
import '../../../domain/enums/task_status.dart';

/// Dün / Bugün / Özel — gerçekleşen başlangıç veya bitiş.
Future<String?> showTaskActualDateSheet(
  BuildContext context, {
  required TaskStatus forStatus,
}) async {
  final sheetTheme = SJModal.sheetThemeOf(context);
  final today = DateTime.now();
  final todayDay = DateTime(today.year, today.month, today.day);
  final yesterday = todayDay.subtract(const Duration(days: 1));

  return showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    backgroundColor: SJModal.sheetSurface,
    builder: (ctx) => Theme(
      data: sheetTheme,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            0,
            AppSpacing.md,
            AppSpacing.md,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                TaskStatusRules.dateSheetTitle(forStatus),
                style: Theme.of(ctx).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Unutulan gün için doğru tarihi seçin.',
                style: Theme.of(ctx).textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.md),
              ListTile(
                leading: const Icon(Icons.history),
                title: const Text('Dün'),
                subtitle: Text(PuantajDate.format(yesterday)),
                onTap: () =>
                    Navigator.pop(ctx, PuantajDate.format(yesterday)),
              ),
              ListTile(
                leading: const Icon(Icons.today),
                title: const Text('Bugün'),
                subtitle: Text(PuantajDate.format(todayDay)),
                onTap: () =>
                    Navigator.pop(ctx, PuantajDate.format(todayDay)),
              ),
              ListTile(
                leading: const Icon(Icons.calendar_month_outlined),
                title: const Text('Özel tarih'),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: todayDay,
                    firstDate: todayDay.subtract(const Duration(days: 365)),
                    lastDate: todayDay,
                  );
                  if (picked == null || !ctx.mounted) return;
                  Navigator.pop(ctx, PuantajDate.format(picked));
                },
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
