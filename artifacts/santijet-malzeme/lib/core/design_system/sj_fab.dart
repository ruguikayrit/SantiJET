import 'package:flutter/material.dart';

import '../theme/app_typography.dart';

/// Demir `AppFab` — extended FAB + scroll clearance.
class SJFab extends StatelessWidget {
  const SJFab({
    super.key,
    required this.label,
    required this.onPressed,
    this.extended = true,
    this.aboveBottomNav = true,
  });

  final String label;
  final VoidCallback onPressed;
  final bool extended;
  final bool aboveBottomNav;

  static const _extendedHeight = 56.0;
  static const _fabEdgeMargin = 16.0;
  static const _contentGap = 24.0;
  static const _shellDockGap = 8.0;

  static double scrollClearanceOf(
    BuildContext context, {
    bool aboveBottomNav = true,
  }) {
    final dock = aboveBottomNav ? _shellDockGap : 0.0;
    return dock + _extendedHeight + _fabEdgeMargin + _contentGap;
  }

  @override
  Widget build(BuildContext context) {
    // AppTypography.* chrome mürekkebi taşır; FAB foreground (beyaz) ezilmesin.
    final labelStyle = AppTypography.labelLarge.copyWith(
      color: Colors.white,
      fontWeight: FontWeight.w600,
    );

    final Widget fab;
    if (extended) {
      fab = FloatingActionButton.extended(
        onPressed: onPressed,
        icon: const Icon(Icons.add),
        label: Text(label, style: labelStyle),
      );
    } else {
      fab = FloatingActionButton(
        onPressed: onPressed,
        child: const Icon(Icons.add),
      );
    }

    if (!aboveBottomNav) return fab;

    return Padding(
      padding: const EdgeInsets.only(bottom: _shellDockGap),
      child: fab,
    );
  }
}
