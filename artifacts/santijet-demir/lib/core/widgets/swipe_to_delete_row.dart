import 'package:flutter/material.dart';
import 'package:santijet_demir/core/theme/app_colors.dart';
import 'package:santijet_demir/core/theme/app_radii.dart';

/// Sola kaydırınca silme — onay diyalogu ile.
class SwipeToDeleteRow extends StatelessWidget {
  const SwipeToDeleteRow({
    super.key,
    required this.itemKey,
    required this.enabled,
    required this.title,
    required this.message,
    required this.onDelete,
    required this.child,
  });

  final Key itemKey;
  final bool enabled;
  final String title;
  final String message;
  final Future<void> Function() onDelete;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;

    return Dismissible(
      key: itemKey,
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppColors.surfaceElevated,
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('İptal'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.critical,
                ),
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Sil'),
              ),
            ],
          ),
        );
        if (confirmed != true) return false;
        await onDelete();
        return true;
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppColors.critical.withValues(alpha: 0.15),
          borderRadius: AppRadii.md,
          border: Border.all(color: AppColors.critical.withValues(alpha: 0.35)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Icon(Icons.delete_outline, color: AppColors.critical),
            SizedBox(width: 8),
            Text('Sil', style: TextStyle(color: AppColors.critical)),
          ],
        ),
      ),
      child: child,
    );
  }
}
