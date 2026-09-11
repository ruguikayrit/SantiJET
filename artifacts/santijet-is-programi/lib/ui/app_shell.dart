import 'package:flutter/material.dart';

import '../core/design_system/sj_bottom_navigation.dart';
import '../core/theme/app_colors.dart';
import '../features/calendar/calendar_screen.dart';
import '../features/program/program_screen.dart';
import '../features/summary/summary_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int index = 0;

  static const pages = [ProgramScreen(), CalendarScreen(), SummaryScreen()];

  static const items = [
    SJNavItem(
      icon: Icons.view_list_outlined,
      activeIcon: Icons.view_list_rounded,
      label: 'Program',
    ),
    SJNavItem(
      icon: Icons.view_timeline_outlined,
      activeIcon: Icons.view_timeline_rounded,
      label: 'Gantt',
    ),
    SJNavItem(
      icon: Icons.donut_large_outlined,
      activeIcon: Icons.donut_large_rounded,
      label: 'Özet',
    ),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.canvas,
    body: IndexedStack(index: index, children: pages),
    bottomNavigationBar: SJBottomNavigation(
      items: items,
      currentIndex: index,
      onTap: (value) => setState(() => index = value),
    ),
  );
}
