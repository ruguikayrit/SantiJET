import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/pro_theme.dart';
import '../../modules/pro_module.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ProColors.canvas,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: [
            const _Brand(),
            const SizedBox(height: 20),
            for (final group in ProModuleGroup.values) ...[
              _GroupHeader(group: group),
              const SizedBox(height: 8),
              for (final module in ProModule.catalog)
                if (module.group == group) ...[
                  _ModuleCard(module: module),
                  const SizedBox(height: 8),
                ],
              if (group == ProModuleGroup.imalat) ...[
                const Padding(
                  padding: EdgeInsets.only(left: 4, bottom: 8),
                  child: Text(
                    'Çelik daha sonra eklenecek.',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: ProColors.textFaint,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Image.asset(
          'assets/images/splash_bolt.png',
          height: 28,
          filterQuality: FilterQuality.medium,
        ),
        const SizedBox(width: 10),
        Image.asset(
          'assets/images/splash_wordmark.png',
          height: 22,
          filterQuality: FilterQuality.medium,
        ),
        const SizedBox(width: 8),
        const Text(
          'PRO',
          style: TextStyle(
            fontFamily: 'Rajdhani',
            fontWeight: FontWeight.w700,
            fontSize: 18,
            letterSpacing: 1.2,
            color: ProColors.electricBlue,
          ),
        ),
      ],
    );
  }
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.group});

  final ProModuleGroup group;

  @override
  Widget build(BuildContext context) {
    return Text(
      group.label,
      style: const TextStyle(
        fontFamily: 'Rajdhani',
        fontWeight: FontWeight.w600,
        fontSize: 13,
        letterSpacing: 1.4,
        color: ProColors.textMuted,
      ),
    );
  }
}

class _ModuleCard extends StatelessWidget {
  const _ModuleCard({required this.module});

  final ProModule module;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ProColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: ProColors.border),
      ),
      child: InkWell(
        key: Key('module-${module.id}'),
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push(module.route),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Icon(module.icon, color: ProColors.electricBlue, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      module.label,
                      style: const TextStyle(
                        fontFamily: 'Rajdhani',
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        letterSpacing: 0.6,
                        color: ProColors.text,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      module.summary,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        color: ProColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: ProColors.textFaint, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
