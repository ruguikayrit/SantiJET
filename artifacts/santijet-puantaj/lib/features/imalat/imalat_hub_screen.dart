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
              child: _HubSegmentBar(
                selectedIndex: _tab,
                onChanged: (i) => setState(() => _tab = i),
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

/// Ana seviye İmalat | Verim — tek hatlı segment; faz satırlarından ayrı dil.
class _HubSegmentBar extends StatelessWidget {
  const _HubSegmentBar({
    required this.selectedIndex,
    required this.onChanged,
  });

  final int selectedIndex;
  final ValueChanged<int> onChanged;

  static const _labels = ['İmalat', 'Verim'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Chrome segment — hibrit kart paletine bağlanmaz.
    final track = AppColors.surfaceHighlight;
    final selectedBg = AppColors.useDarkChrome
        ? AppColors.electricBlueLight
        : AppColors.electricBlue;
    const selectedFg = Colors.white;
    final idleFg = AppColors.textMuted;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: track,
        borderRadius: AppRadii.md,
      ),
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: Row(
          children: [
            for (var i = 0; i < _labels.length; i++) ...[
              if (i > 0) const SizedBox(width: 3),
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => onChanged(i),
                    borderRadius: AppRadii.sm,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOut,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        borderRadius: AppRadii.sm,
                        color: selectedIndex == i
                            ? selectedBg
                            : Colors.transparent,
                      ),
                      child: Text(
                        _labels[i],
                        textAlign: TextAlign.center,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: selectedIndex == i ? selectedFg : idleFg,
                          fontWeight: selectedIndex == i
                              ? FontWeight.w800
                              : FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
