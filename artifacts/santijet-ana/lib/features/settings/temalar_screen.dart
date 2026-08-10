import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:santijet_ana/core/routing/app_routes.dart';
import 'package:santijet_ana/core/theme/app_themes.dart';
import 'package:santijet_ana/core/theme/theme_colors.dart';
import 'package:santijet_ana/core/theme/theme_provider.dart';

/// 12 tema ızgarası — seçim themeProvider'a yazılır.
class TemalarScreen extends ConsumerWidget {
  const TemalarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeDefinitionProvider);
    final c = theme.colors;
    final themes = AppThemes.themes;
    final top = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: c.background,
      body: Column(
        children: [
          Container(
            color: c.secondary,
            padding: EdgeInsets.fromLTRB(12, top + 12, 12, 14),
            child: Row(
              children: [
                IconButton(
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go(AppRoutes.ayarlar);
                    }
                  },
                  icon: Icon(Icons.arrow_back, color: c.secondaryForeground),
                ),
                Expanded(
                  child: Text(
                    'Temalar',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: c.secondaryForeground,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
                const SizedBox(width: 40),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                MediaQuery.paddingOf(context).bottom + 24,
              ),
              children: [
                Text(
                  'Uygulamanın görünümünü değiştirin. Hi-Vis ve Steel temalar ana sayfa kart düzenini de etkiler.',
                  style: TextStyle(
                    color: c.mutedForeground,
                    fontSize: 13,
                    height: 1.4,
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(height: 16),
                for (final th in themes) ...[
                  _ThemeCard(
                    definition: th,
                    selected: th.id == theme.id,
                    colors: c,
                    onTap: () =>
                        ref.read(themeIdProvider.notifier).setThemeId(th.id),
                  ),
                  const SizedBox(height: 12),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemeCard extends StatelessWidget {
  const _ThemeCard({
    required this.definition,
    required this.selected,
    required this.colors,
    required this.onTap,
  });

  final ThemeDefinition definition;
  final bool selected;
  final ThemeColors colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final th = definition;
    return Material(
      color: colors.card,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? colors.primary : colors.border,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 92,
                height: 110,
                decoration: BoxDecoration(
                  color: th.preview.bg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: colors.border),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(height: 24, color: th.preview.secondary),
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              color: th.preview.primary,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            height: 6,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: th.isDark
                                  ? Colors.white.withOpacity(0.4)
                                  : Colors.black.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          const SizedBox(height: 6),
                          FractionallySizedBox(
                            widthFactor: 0.55,
                            child: Container(
                              height: 6,
                              decoration: BoxDecoration(
                                color: th.isDark
                                    ? Colors.white.withOpacity(0.25)
                                    : Colors.black.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            th.name,
                            style: TextStyle(
                              color: colors.foreground,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ),
                        if (selected) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: colors.primary,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check,
                                    size: 12, color: colors.primaryForeground),
                                const SizedBox(width: 4),
                                Text(
                                  'Aktif',
                                  style: TextStyle(
                                    color: colors.primaryForeground,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: 'Inter',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      th.description,
                      style: TextStyle(
                        color: colors.mutedForeground,
                        fontSize: 13,
                        fontFamily: 'Inter',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _swatch(th.colors.navy),
                        const SizedBox(width: 6),
                        _swatch(th.colors.orange),
                        const SizedBox(width: 6),
                        _swatch(th.colors.background, border: colors.border),
                        if (th.isDark) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: colors.muted,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.dark_mode,
                                    size: 10, color: colors.mutedForeground),
                                const SizedBox(width: 3),
                                Text(
                                  'Koyu',
                                  style: TextStyle(
                                    color: colors.mutedForeground,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'Inter',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _swatch(Color color, {Color? border}) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: border != null ? Border.all(color: border) : null,
      ),
    );
  }
}
