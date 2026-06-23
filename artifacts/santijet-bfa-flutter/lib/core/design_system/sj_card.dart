import 'package:flutter/material.dart';

import '../theme/app_radii.dart';
import '../theme/app_spacing.dart';

/// ŞantiJET Design System — kart.
///
/// ŞantiJET Demir kart desenine (yüzey + ince kenarlık + md yarıçap) dayanır;
/// hem açık hem koyu temada doğru görünmesi için yapısal renkler `Theme`'den
/// alınır. İsteğe bağlı sol renk şeridi (`accentColor`) ve dokunma desteği vardır.
class SJCard extends StatelessWidget {
  const SJCard({
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.accentColor,
    this.selected = false,
    super.key,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final Color? accentColor;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardTheme = theme.cardTheme;
    final surface = cardTheme.color ?? theme.colorScheme.surface;
    final borderColor = selected
        ? theme.colorScheme.primary
        : theme.dividerColor;

    final content = Padding(
      padding: padding,
      child: accentColor == null
          ? child
          : Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: AppRadii.xs,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: child),
              ],
            ),
    );

    final decorated = DecoratedBox(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: AppRadii.md,
        border: Border.all(
          color: borderColor,
          width: selected ? 1.5 : 1,
        ),
      ),
      child: content,
    );

    if (onTap == null) return decorated;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.md,
        child: decorated,
      ),
    );
  }
}
