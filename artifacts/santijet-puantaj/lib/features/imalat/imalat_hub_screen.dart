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
    final theme = Theme.of(context);
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
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.sm,
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: theme.cardTheme.color ?? theme.colorScheme.surface,
                  borderRadius: AppRadii.md,
                  border: Border.all(color: theme.dividerColor),
                ),
                child: Row(
                  children: [
                    for (final entry in const [
                      (0, 'İmalat'),
                      (1, 'Verim'),
                    ])
                      Expanded(
                        child: InkWell(
                          onTap: () => setState(() => _tab = entry.$1),
                          borderRadius: AppRadii.md,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _tab == entry.$1
                                  ? theme.colorScheme.secondary
                                  : Colors.transparent,
                              borderRadius: AppRadii.md,
                            ),
                            child: Text(
                              entry.$2,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: _tab == entry.$1
                                    ? Colors.white
                                    : theme.colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
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
