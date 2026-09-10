import 'package:flutter/material.dart';

import '../features/calendar/calendar_screen.dart';
import '../features/program/program_screen.dart';
import '../features/summary/summary_screen.dart';
import 'design_system.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int index = 0;

  static const pages = [ProgramScreen(), CalendarScreen(), SummaryScreen()];

  @override
  Widget build(BuildContext context) => Scaffold(
    body: IndexedStack(index: index, children: pages),
    bottomNavigationBar: SJBottomNavigation(
      index: index,
      onChanged: (value) => setState(() => index = value),
    ),
  );
}
