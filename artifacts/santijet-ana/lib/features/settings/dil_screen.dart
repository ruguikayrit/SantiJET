import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:santijet_ana/bootstrap.dart';
import 'package:santijet_ana/core/routing/app_routes.dart';
import 'package:santijet_ana/core/theme/theme_colors.dart';
import 'package:santijet_ana/core/theme/theme_provider.dart';

const _languageKey = 'language_v1';

class _Lang {
  const _Lang(this.code, this.flag, this.native, this.name);
  final String code;
  final String flag;
  final String native;
  final String name;
}

const _languages = <_Lang>[
  _Lang('tr', '🇹🇷', 'Türkçe', 'Turkish'),
  _Lang('en', '🇬🇧', 'English', 'English'),
  _Lang('ar', '🇸🇦', 'العربية', 'Arabic'),
  _Lang('ru', '🇷🇺', 'Русский', 'Russian'),
  _Lang('de', '🇩🇪', 'Deutsch', 'German'),
];

/// Dil seçimi — Hive settings'e yazılır.
class DilScreen extends ConsumerStatefulWidget {
  const DilScreen({super.key});

  @override
  ConsumerState<DilScreen> createState() => _DilScreenState();
}

class _DilScreenState extends ConsumerState<DilScreen> {
  String _code = 'tr';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final box = ref.read(settingsBoxProvider);
      final stored = box.get(_languageKey);
      if (stored is String && _languages.any((l) => l.code == stored)) {
        setState(() => _code = stored);
      }
    });
  }

  void _select(String code) {
    setState(() => _code = code);
    ref.read(settingsBoxProvider).put(_languageKey, code);
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeDefinitionProvider);
    final c = theme.colors;
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
                    'Dil',
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
                  'Arayüz dilini seçin. Seçiminiz cihazda saklanır.',
                  style: TextStyle(
                    color: c.mutedForeground,
                    fontSize: 13,
                    height: 1.4,
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(height: 16),
                for (final l in _languages) ...[
                  _langCard(c, l),
                  const SizedBox(height: 10),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _langCard(ThemeColors c, _Lang l) {
    final selected = l.code == _code;
    return Material(
      color: c.card,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _select(l.code),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? c.primary : c.border,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Text(l.flag, style: const TextStyle(fontSize: 32)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.native,
                      style: TextStyle(
                        color: c.foreground,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Inter',
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l.name,
                      style: TextStyle(
                        color: c.mutedForeground,
                        fontSize: 12,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: c.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.check, size: 14, color: c.primaryForeground),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
