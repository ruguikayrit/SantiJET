import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// Faz iskeleti ekran yer tutucusu (design token'larıyla).
///
/// İlgili fazlarda gerçek ekran içerikleriyle değiştirilecektir.
class PhasePlaceholder extends StatelessWidget {
  const PhasePlaceholder({
    required this.title,
    required this.phase,
    this.subtitle,
    super.key,
  });

  final String title;
  final String phase;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.architecture_outlined,
                size: 48,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                title,
                style: theme.textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                subtitle ?? '$phase aşamasında uygulanacak.',
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
