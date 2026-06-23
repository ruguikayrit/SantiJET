import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Favori aç/kapa yıldız butonu.
class FavoriteButton extends StatelessWidget {
  const FavoriteButton({
    required this.isFavorite,
    required this.onToggle,
    this.size = 22,
    super.key,
  });

  final bool isFavorite;
  final VoidCallback onToggle;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onToggle,
      tooltip: isFavorite ? 'Favorilerden çıkar' : 'Favorilere ekle',
      icon: Icon(
        isFavorite ? Icons.star : Icons.star_border,
        size: size,
        color: isFavorite
            ? AppColors.moduleFavori
            : Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}
