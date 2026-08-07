import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/santijet_header.dart';
import '../verim/verim_screen.dart';
import 'imalat_screen.dart';

/// İmalat hub — alt nav’da tek sekme; içinde İmalat | Verim segmenti.
class ImalatHubScreen extends ConsumerStatefulWidget {
  const ImalatHubScreen({super.key, this.initialTab = 0});

  /// 0 = İmalat, 1 = Verim.
  final int initialTab;

  @override
  ConsumerState<ImalatHubScreen> createState() => _ImalatHubScreenState();
}

class _ImalatHubScreenState extends ConsumerState<ImalatHubScreen> {
  late int _tab;

  @override
  void initState() {
    super.initState();
    _tab = widget.initialTab.clamp(0, 1);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final q = GoRouterState.of(context).uri.queryParameters['tab'];
    if (q == 'verim' && _tab != 1) {
      _tab = 1;
    } else if (q == 'imalat' && _tab != 0) {
      _tab = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SantijetHeader(subtitle: _tab == 0 ? 'İmalat' : 'Verim'),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.afterHeader,
                AppSpacing.md,
                AppSpacing.sm,
              ),
              child: Row(
                children: [
                  for (final entry in const [
                    (0, 'İmalat'),
                    (1, 'Verim'),
                  ]) ...[
                    if (entry.$1 > 0) const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _HubSegmentTab(
                        label: entry.$2,
                        selected: _tab == entry.$1,
                        onTap: () => setState(() => _tab = entry.$1),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              child: IndexedStack(
                index: _tab,
                children: const [
                  ImalatScreen(embedded: true),
                  VerimScreen(embedded: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Faz satır başlıklarıyla aynı dil: yumuşak dolgu + kenarlık + renkli metin.
class _HubSegmentTab extends StatelessWidget {
  const _HubSegmentTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = AppColors.info;
    final muted = theme.colorScheme.onSurfaceVariant;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.md,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            borderRadius: AppRadii.md,
            color: selected
                ? accent.withValues(alpha: 0.12)
                : theme.colorScheme.surface.withValues(alpha: 0.55),
            border: Border.all(
              color: selected
                  ? accent.withValues(alpha: 0.45)
                  : theme.dividerColor.withValues(alpha: 0.7),
              width: selected ? 1.25 : 1,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: theme.textTheme.labelLarge?.copyWith(
              color: selected ? accent : muted,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
