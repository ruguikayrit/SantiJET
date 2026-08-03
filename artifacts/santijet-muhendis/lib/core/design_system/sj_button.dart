import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radii.dart';

/// ŞantiJET buton varyantları.
enum SJButtonVariant { primary, secondary, ghost, destructive }

/// ŞantiJET Design System — buton.
///
/// Varyant + yükleniyor durumu + opsiyonel ikon. Electric blue marka rengi ve
/// `AppRadii.md` köşe yarıçapı ŞantiJET Demir ile aynıdır.
class SJButton extends StatelessWidget {
  const SJButton({
    required this.label,
    required this.onPressed,
    this.variant = SJButtonVariant.primary,
    this.icon,
    this.loading = false,
    this.expanded = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final SJButtonVariant variant;
  final IconData? icon;
  final bool loading;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final effectiveOnPressed = loading ? null : onPressed;
    final child = _buildChild();

    final Widget button = switch (variant) {
      SJButtonVariant.primary => FilledButton(
          onPressed: effectiveOnPressed,
          style: _filledStyle(AppColors.electricBlue, Colors.white),
          child: child,
        ),
      SJButtonVariant.destructive => FilledButton(
          onPressed: effectiveOnPressed,
          style: _filledStyle(AppColors.critical, Colors.white),
          child: child,
        ),
      SJButtonVariant.secondary => OutlinedButton(
          onPressed: effectiveOnPressed,
          style: OutlinedButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: AppRadii.md),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          ),
          child: child,
        ),
      SJButtonVariant.ghost => TextButton(
          onPressed: effectiveOnPressed,
          style: TextButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: AppRadii.md),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          child: child,
        ),
    };

    return expanded ? SizedBox(width: double.infinity, child: button) : button;
  }

  ButtonStyle _filledStyle(Color bg, Color fg) {
    return FilledButton.styleFrom(
      backgroundColor: bg,
      foregroundColor: fg,
      shape: RoundedRectangleBorder(borderRadius: AppRadii.md),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
    );
  }

  Widget _buildChild() {
    if (loading) {
      return const SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }
    if (icon == null) return Text(label);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: 8),
        Text(label),
      ],
    );
  }
}
