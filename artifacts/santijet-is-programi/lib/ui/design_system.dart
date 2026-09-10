import 'package:flutter/material.dart';

import '../domain/program_item.dart';

abstract final class AppColors {
  static const electricBlue = Color(0xFF0055FF);
  static const navy = Color(0xFF08162E);
  static const ink = Color(0xFF182338);
  static const mist = Color(0xFFF3F6FB);
  static const line = Color(0xFFDDE4EF);
  static const success = Color(0xFF11845B);
  static const warning = Color(0xFFE78A05);
  static const danger = Color(0xFFD9354F);
}

abstract final class AppTypography {
  static const bodyFont = 'Inter';
  static const displayFont = 'Rajdhani';
}

ThemeData buildTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.electricBlue,
    brightness: brightness,
    primary: AppColors.electricBlue,
    surface: dark ? AppColors.navy : Colors.white,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: dark ? const Color(0xFF071225) : AppColors.mist,
    fontFamily: AppTypography.bodyFont,
    textTheme: ThemeData(brightness: brightness).textTheme.apply(
      fontFamily: AppTypography.bodyFont,
      bodyColor: dark ? Colors.white : AppColors.ink,
      displayColor: dark ? Colors.white : AppColors.navy,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: dark ? const Color(0xFF111F36) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: dark ? Colors.white12 : AppColors.line),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: dark ? Colors.white.withValues(alpha: .06) : Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: dark ? Colors.white24 : AppColors.line),
      ),
    ),
  );
}

class SJCard extends StatelessWidget {
  const SJCard({super.key, required this.child, this.padding});
  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    child: Padding(padding: padding ?? const EdgeInsets.all(16), child: child),
  );
}

class SJButton extends StatelessWidget {
  const SJButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.secondary = false,
  });
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool secondary;

  @override
  Widget build(BuildContext context) {
    final child = icon == null
        ? Text(label)
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18),
              const SizedBox(width: 8),
              Text(label),
            ],
          );
    return secondary
        ? OutlinedButton(onPressed: onPressed, child: child)
        : FilledButton(onPressed: onPressed, child: child);
  }
}

class SJStatusBadge extends StatelessWidget {
  const SJStatusBadge({super.key, required this.status});
  final ProgramStatus status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      ProgramStatus.completed => AppColors.success,
      ProgramStatus.delayed => AppColors.danger,
      ProgramStatus.inProgress => AppColors.electricBlue,
      ProgramStatus.planned => const Color(0xFF6A7485),
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: .11),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Text(
          status.label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w700,
            fontSize: 11,
          ),
        ),
      ),
    );
  }
}

class SantijetHeader extends StatelessWidget {
  const SantijetHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.onSettings,
    this.showBack = false,
  });
  final String title;
  final String? subtitle;
  final VoidCallback? onSettings;
  final bool showBack;

  @override
  Widget build(BuildContext context) => SafeArea(
    bottom: false,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 12, 12),
      child: Row(
        children: [
          if (showBack)
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back_rounded),
            )
          else
            const BoltMark(size: 36),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: AppTypography.displayFont,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: .3,
                  ),
                ),
                if (subtitle != null)
                  Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          if (onSettings != null)
            IconButton(
              tooltip: 'Ayarlar',
              onPressed: onSettings,
              icon: const Icon(Icons.settings_outlined),
            ),
        ],
      ),
    ),
  );
}

class BoltMark extends StatelessWidget {
  const BoltMark({super.key, this.size = 48});
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: AppColors.electricBlue,
      borderRadius: BorderRadius.circular(size * .28),
    ),
    child: Icon(Icons.bolt_rounded, color: Colors.white, size: size * .72),
  );
}

class SJBottomNavigation extends StatelessWidget {
  const SJBottomNavigation({
    super.key,
    required this.index,
    required this.onChanged,
  });
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => NavigationBar(
    selectedIndex: index,
    onDestinationSelected: onChanged,
    destinations: const [
      NavigationDestination(
        icon: Icon(Icons.view_list_outlined),
        selectedIcon: Icon(Icons.view_list_rounded),
        label: 'Program',
      ),
      NavigationDestination(
        icon: Icon(Icons.calendar_month_outlined),
        selectedIcon: Icon(Icons.calendar_month_rounded),
        label: 'Takvim',
      ),
      NavigationDestination(
        icon: Icon(Icons.donut_large_outlined),
        selectedIcon: Icon(Icons.donut_large_rounded),
        label: 'Özet',
      ),
    ],
  );
}
