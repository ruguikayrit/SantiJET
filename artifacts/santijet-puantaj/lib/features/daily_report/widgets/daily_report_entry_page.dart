import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

/// Veri giriş formu — tam ekran; İptal / Kaydet en altta.
Future<T?> showDailyReportEntryPage<T>({
  required BuildContext context,
  required String title,
  required Widget Function(BuildContext ctx, StateSetter setModal) formBuilder,
  required T? Function() onSave,
  T? Function()? onCancel,
  String cancelLabel = 'İptal',
  String saveLabel = 'Kaydet',
}) {
  return Navigator.of(context).push<T>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (ctx) => _DailyReportEntryPage<T>(
        title: title,
        formBuilder: formBuilder,
        onSave: onSave,
        onCancel: onCancel,
        cancelLabel: cancelLabel,
        saveLabel: saveLabel,
      ),
    ),
  );
}

class _DailyReportEntryPage<T> extends StatefulWidget {
  const _DailyReportEntryPage({
    required this.title,
    required this.formBuilder,
    required this.onSave,
    required this.cancelLabel,
    required this.saveLabel,
    this.onCancel,
  });

  final String title;
  final Widget Function(BuildContext ctx, StateSetter setModal) formBuilder;
  final T? Function() onSave;
  final T? Function()? onCancel;
  final String cancelLabel;
  final String saveLabel;

  @override
  State<_DailyReportEntryPage<T>> createState() =>
      _DailyReportEntryPageState<T>();
}

class _DailyReportEntryPageState<T> extends State<_DailyReportEntryPage<T>> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Text(widget.title),
        automaticallyImplyLeading: false,
        backgroundColor: AppColors.surfaceElevated,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.lg,
              ),
              child: widget.formBuilder(context, setState),
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                AppSpacing.md,
              ),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                border: Border(
                  top: BorderSide(
                    color: theme.colorScheme.outlineVariant.withValues(
                      alpha: 0.6,
                    ),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        if (widget.onCancel != null) {
                          Navigator.pop(context, widget.onCancel!());
                        } else {
                          Navigator.pop(context);
                        }
                      },
                      child: Text(widget.cancelLabel),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        final value = widget.onSave();
                        if (value != null) Navigator.pop(context, value);
                      },
                      child: Text(widget.saveLabel),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
