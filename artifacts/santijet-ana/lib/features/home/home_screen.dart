import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:santijet_ana/bootstrap.dart';
import 'package:santijet_ana/core/routing/app_routes.dart';
import 'package:santijet_ana/core/theme/theme_colors.dart';
import 'package:santijet_ana/core/theme/theme_provider.dart';
import 'package:santijet_ana/data/providers/app_state_provider.dart';
import 'package:santijet_ana/domain/models/page_key.dart';

const _orderKey = 'santiye-tile-order-v1';
const _colorsKey = 'santiye-tile-colors-v1';

const _softColors = <Color>[
  Color(0xFFF87171),
  Color(0xFFFB923C),
  Color(0xFFFBBF24),
  Color(0xFFA3E635),
  Color(0xFF4ADE80),
  Color(0xFF34D399),
  Color(0xFF22D3EE),
  Color(0xFF38BDF8),
  Color(0xFF60A5FA),
  Color(0xFF818CF8),
  Color(0xFFA78BFA),
  Color(0xFFC084FC),
  Color(0xFFE879F9),
  Color(0xFFF472B6),
  Color(0xFFFB7185),
  Color(0xFF94A3B8),
  Color(0xFF78716C),
  Color(0xFF6B7280),
  Color(0xFFA8A29E),
  Color(0xFF64748B),
];

const _sectionNeon = <String, Color>{
  'proje': Color(0xFF3B82F6),
  'gunluk-rapor': Color(0xFFF97316),
  'puantaj': Color(0xFF8B5CF6),
  'gorev': Color(0xFF22C55E),
  'imalat': Color(0xFF3B82F6),
  'ilerleme': Color(0xFFF97316),
  'malzeme': Color(0xFFF97316),
  'kantar': Color(0xFF22C55E),
  'kesif': Color(0xFF60A5FA),
  'is-programi': Color(0xFFF97316),
  'satin-alma': Color(0xFFEC4899),
  'hakedis': Color(0xFF06B6D4),
  'butce': Color(0xFF22C55E),
  'taseron': Color(0xFFF97316),
  'kullanicilar': Color(0xFF8B5CF6),
  'dosyalar': Color(0xFF64748B),
};

const _sectionNum = <String, String>{
  'proje': '01',
  'gunluk-rapor': '02',
  'puantaj': '03',
  'gorev': '04',
  'imalat': '05',
  'ilerleme': '06',
  'malzeme': '07',
  'kantar': '08',
  'kesif': '09',
  'is-programi': '10',
  'satin-alma': '11',
  'hakedis': '12',
  'butce': '13',
  'taseron': '14',
  'kullanicilar': '15',
  'dosyalar': '16',
};

class _TileColorConfig {
  const _TileColorConfig({required this.mode, required this.color});
  final String mode; // accent | fill
  final Color color;

  Map<String, dynamic> toJson() => {
        'mode': mode,
        // ignore: deprecated_member_use
        'color':
            '#${color.value.toRadixString(16).padLeft(8, '0').substring(2)}',
      };

  static _TileColorConfig? fromJson(dynamic raw) {
    if (raw is! Map) return null;
    final mode = raw['mode']?.toString();
    final hex = raw['color']?.toString();
    if (mode == null || hex == null || hex.length < 7) return null;
    final c = Color(int.parse('FF${hex.replaceFirst('#', '')}', radix: 16));
    return _TileColorConfig(mode: mode, color: c);
  }
}

class _Section {
  const _Section({
    required this.key,
    required this.label,
    required this.icon,
    required this.route,
    required this.color,
    required this.code,
    required this.sub,
    required this.countOf,
  });

  final PageKey key;
  final String label;
  final IconData icon;
  final String route;
  final Color color;
  final String code;
  final String sub;
  final int Function(AppState state) countOf;

  String get wire => key;
}

/// ŞantiJET PRO ana hub — 16 modül ızgarası.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  List<String> _tileOrder = [];
  Map<String, _TileColorConfig> _tileColors = {};
  String? _dragKey;
  String? _cpKey;
  String _cpMode = 'accent';
  Color _cpColor = _softColors.first;
  bool _syncing = false;

  static List<_Section> get _allSections => [
        _Section(
          key: 'proje',
          label: 'Proje',
          icon: Icons.work_outline,
          route: AppRoutes.proje,
          color: const Color(0xFFE85D04),
          code: 'PR-01',
          sub: 'Aktif Proje',
          countOf: (s) => s.projects.length,
        ),
        _Section(
          key: 'gunluk-rapor',
          label: 'Günlük Rapor',
          icon: Icons.description_outlined,
          route: AppRoutes.gunlukRapor,
          color: const Color(0xFF0891B2),
          code: 'GR-02',
          sub: 'Bugün',
          countOf: (s) => s.dailyReports.length,
        ),
        _Section(
          key: 'puantaj',
          label: 'Puantaj',
          icon: Icons.groups_outlined,
          route: AppRoutes.puantaj,
          color: const Color(0xFF16A34A),
          code: 'PU-03',
          sub: 'Personel',
          countOf: (s) => s.attendance.length,
        ),
        _Section(
          key: 'gorev',
          label: 'Görev',
          icon: Icons.check_box_outlined,
          route: AppRoutes.gorev,
          color: const Color(0xFFDC2626),
          code: 'GV-04',
          sub: 'Açık Görev',
          countOf: (s) => s.tasks.length,
        ),
        _Section(
          key: 'imalat',
          label: 'İmalat',
          icon: Icons.build_outlined,
          route: AppRoutes.imalat,
          color: const Color(0xFFD97706),
          code: 'IM-05',
          sub: 'Devam Eden',
          countOf: (s) => s.productions.length,
        ),
        _Section(
          key: 'ilerleme',
          label: 'İlerleme',
          icon: Icons.trending_up,
          route: AppRoutes.ilerleme,
          color: const Color(0xFF0D9488),
          code: 'IL-06',
          sub: 'Kayıt',
          countOf: (s) => s.surveys.length + s.productions.length,
        ),
        _Section(
          key: 'malzeme',
          label: 'Malzeme',
          icon: Icons.inventory_2_outlined,
          route: AppRoutes.malzeme,
          color: const Color(0xFF059669),
          code: 'MZ-07',
          sub: 'Kritik Stok',
          countOf: (s) => s.materials.length,
        ),
        _Section(
          key: 'kantar',
          label: 'Kantar',
          icon: Icons.local_shipping_outlined,
          route: AppRoutes.kantar,
          color: const Color(0xFF0D9488),
          code: 'KN-08',
          sub: 'Bugün Giriş',
          countOf: (s) => s.weighbridges.length,
        ),
        _Section(
          key: 'kesif',
          label: 'Keşif',
          icon: Icons.search,
          route: AppRoutes.kesif,
          color: const Color(0xFF0EA5E9),
          code: 'KS-09',
          sub: 'Keşif',
          countOf: (s) => s.surveys.length,
        ),
        _Section(
          key: 'is-programi',
          label: 'İş Programı',
          icon: Icons.calendar_today_outlined,
          route: AppRoutes.isProgrami,
          color: const Color(0xFF8B5CF6),
          code: 'IP-10',
          sub: 'Aktif İş',
          countOf: (s) => s.scheduleTasks.length,
        ),
        _Section(
          key: 'satin-alma',
          label: 'Satın Alma',
          icon: Icons.shopping_cart_outlined,
          route: AppRoutes.satinAlma,
          color: const Color(0xFFEA580C),
          code: 'SA-11',
          sub: 'Açık Talep',
          countOf: (s) => s.purchases.length,
        ),
        _Section(
          key: 'hakedis',
          label: 'Hakediş',
          icon: Icons.article_outlined,
          route: AppRoutes.hakedis,
          color: const Color(0xFFBE185D),
          code: 'HK-12',
          sub: 'Bekleyen',
          countOf: (s) => s.hakedisler.length,
        ),
        _Section(
          key: 'butce',
          label: 'Yaklaşık Maliyet',
          icon: Icons.payments_outlined,
          route: AppRoutes.butce,
          color: const Color(0xFF16213E),
          code: 'YM-13',
          sub: 'Kalem',
          countOf: (s) =>
              s.surveys.fold<int>(0, (acc, sv) => acc + sv.items.length),
        ),
        _Section(
          key: 'taseron',
          label: 'Taşeron',
          icon: Icons.airport_shuttle_outlined,
          route: AppRoutes.taseron,
          color: const Color(0xFF7C3AED),
          code: 'TS-14',
          sub: 'Taşeron',
          countOf: (s) => s.subcontractors.length,
        ),
        _Section(
          key: 'kullanicilar',
          label: 'Personel',
          icon: Icons.shield_outlined,
          route: AppRoutes.kullanicilar,
          color: const Color(0xFF7C3AED),
          code: 'KU-15',
          sub: 'Personel',
          countOf: (s) => s.appUsers.length,
        ),
        _Section(
          key: 'dosyalar',
          label: 'Dosyalar',
          icon: Icons.folder_outlined,
          route: AppRoutes.dosyalar,
          color: const Color(0xFF475569),
          code: 'DS-16',
          sub: 'Dosya',
          countOf: (s) => s.archiveFiles.length,
        ),
      ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadPrefs());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _loadPrefs() {
    final box = ref.read(settingsBoxProvider);
    final orderRaw = box.get(_orderKey);
    if (orderRaw is String) {
      try {
        final list = (jsonDecode(orderRaw) as List).cast<String>();
        _tileOrder = list;
      } catch (_) {}
    } else if (orderRaw is List) {
      _tileOrder = orderRaw.map((e) => e.toString()).toList();
    }

    final colorsRaw = box.get(_colorsKey);
    if (colorsRaw is String) {
      try {
        final map = jsonDecode(colorsRaw) as Map<String, dynamic>;
        _tileColors = {
          for (final e in map.entries)
            if (_TileColorConfig.fromJson(e.value) != null)
              e.key: _TileColorConfig.fromJson(e.value)!,
        };
      } catch (_) {}
    }
    if (mounted) setState(() {});
  }

  void _persistOrder() {
    ref.read(settingsBoxProvider).put(_orderKey, jsonEncode(_tileOrder));
  }

  void _persistColors() {
    final map = {
      for (final e in _tileColors.entries) e.key: e.value.toJson(),
    };
    ref.read(settingsBoxProvider).put(_colorsKey, jsonEncode(map));
  }

  List<_Section> _orderedVisible(AppState state) {
    final allowed = _allSections
        .where((s) => state.getPermission(s.key) != Permission.none)
        .toList();

    var q = _query.trim().toLowerCase();
    if (q.isNotEmpty) {
      q = q
          .replaceAll('ı', 'i')
          .replaceAll('ğ', 'g')
          .replaceAll('ü', 'u')
          .replaceAll('ş', 's')
          .replaceAll('ö', 'o')
          .replaceAll('ç', 'c');
      allowed.retainWhere((s) {
        final hay = '${s.label} ${s.code} ${s.sub}'
            .toLowerCase()
            .replaceAll('ı', 'i')
            .replaceAll('ğ', 'g')
            .replaceAll('ü', 'u')
            .replaceAll('ş', 's')
            .replaceAll('ö', 'o')
            .replaceAll('ç', 'c');
        return hay.contains(q);
      });
    }

    final byKey = {for (final s in allowed) s.wire: s};
    final result = <_Section>[];
    for (final k in _tileOrder) {
      final s = byKey.remove(k);
      if (s != null) result.add(s);
    }
    result.addAll(byKey.values);
    return result;
  }

  void _swap(String a, String b) {
    if (a == b) return;
    final sections = _orderedVisible(ref.read(appStateProvider));
    final keys = sections.map((s) => s.wire).toList();
    final i = keys.indexOf(a);
    final j = keys.indexOf(b);
    if (i < 0 || j < 0) return;
    final tmp = keys[i];
    keys[i] = keys[j];
    keys[j] = tmp;
    setState(() => _tileOrder = keys);
    _persistOrder();
  }

  Future<void> _sync() async {
    setState(() => _syncing = true);
    try {
      await ref.read(appStateProvider.notifier).pullFromCloud();
      await ref.read(appStateProvider.notifier).pushToCloud();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Senkron başarısız')),
        );
      }
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  void _openColorPicker(String key) {
    final existing = _tileColors[key];
    setState(() {
      _cpKey = key;
      _cpMode = existing?.mode ?? 'accent';
      _cpColor = existing?.color ?? _softColors.first;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _cpKey != null) _showColorPicker();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeDefinitionProvider);
    final c = theme.colors;
    final state = ref.watch(appStateProvider);
    final isHiVis = theme.layout == ThemeLayout.hivis;
    final isSteel = theme.layout == ThemeLayout.steel;
    final sections = _orderedVisible(state);
    final top = MediaQuery.paddingOf(context).top;
    final now = DateTime.now();
    final dateStr = DateFormat('d MMMM y', 'tr_TR').format(now);
    final dayStr = DateFormat('EEEE', 'tr_TR').format(now);
    final ws = state.workspaceInfo;
    final isCloud = ws != null && ws.id != 'local';

    return Scaffold(
      backgroundColor: c.background,
      body: Column(
        children: [
          Container(
            color: c.secondary,
            padding: EdgeInsets.fromLTRB(16, top + 8, 12, 12),
            child: Row(
              children: [
                Expanded(child: _HomeBrandMark(colors: c)),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.notifications_none,
                      size: 20, color: Color(0xFF94A3B8)),
                ),
                IconButton(
                  onPressed: () => context.push(AppRoutes.ayarlar),
                  icon: const Icon(Icons.menu, color: Color(0xFFCBD5E1)),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                12,
                14,
                12,
                MediaQuery.paddingOf(context).bottom + 24,
              ),
              children: [
                _welcomeCard(c, state, dateStr, dayStr),
                const SizedBox(height: 12),
                if (isCloud) ...[
                  _syncBar(c, ws),
                  const SizedBox(height: 12),
                ],
                TextField(
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _query = v),
                  style: TextStyle(color: c.foreground, fontFamily: 'Inter'),
                  decoration: InputDecoration(
                    hintText: 'Modül ara…',
                    hintStyle: TextStyle(color: c.mutedForeground),
                    prefixIcon:
                        Icon(Icons.search, color: c.mutedForeground, size: 20),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            icon: Icon(Icons.close,
                                size: 18, color: c.mutedForeground),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _query = '');
                            },
                          ),
                    filled: true,
                    fillColor: c.card,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: c.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: c.primary),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (isHiVis) _hiVisBanner(c, theme.id),
                if (isSteel)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12, left: 4),
                    child: Text(
                      theme.id == 'steel-copper'
                          ? 'BAKIR & BETON'
                          : theme.id == 'steel-blueprint'
                              ? 'BLUEPRINT'
                              : 'STEEL & CONCRETE',
                      style: TextStyle(
                        color: c.mutedForeground,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ),
                _ModuleGrid(
                  sections: sections,
                  state: state,
                  colors: c,
                  isHiVis: isHiVis,
                  isSteel: isSteel,
                  tileColors: _tileColors,
                  dragKey: _dragKey,
                  getPermission: state.getPermission,
                  onTap: (s) => context.push(s.route),
                  onLongPressColor: (s) => _openColorPicker(s.wire),
                  onDragStarted: (k) => setState(() => _dragKey = k),
                  onDragEnded: () => setState(() => _dragKey = null),
                  onAccept: _swap,
                ),
                const SizedBox(height: 8),
                _shortcut(
                  c,
                  icon: Icons.memory,
                  iconBg: c.primary,
                  iconColor: c.primaryForeground,
                  title: 'AI Asistan',
                  sub: 'Şantiye sorularınıza anında yanıt',
                  trailing: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: c.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'YENİ',
                      style: TextStyle(
                        color: c.primary,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ),
                  borderColor: c.primary.withOpacity(0.4),
                  onTap: () => context.push(AppRoutes.asistan),
                ),
                const SizedBox(height: 10),
                _shortcut(
                  c,
                  icon: Icons.bar_chart_rounded,
                  iconBg: c.primary.withOpacity(0.12),
                  iconColor: c.primary,
                  title: 'Rapor',
                  sub: 'Özet ve analitik görünümler',
                  trailing: Icon(Icons.chevron_right, color: c.mutedForeground),
                  borderColor: c.primary.withOpacity(0.25),
                  onTap: () => context.push(AppRoutes.rapor),
                ),
                const SizedBox(height: 10),
                _shortcut(
                  c,
                  icon: Icons.settings_outlined,
                  iconBg: c.foreground.withOpacity(0.1),
                  iconColor: c.foreground,
                  title: 'Ayarlar',
                  sub: 'Tema, dil ve kataloglar',
                  trailing: Icon(Icons.chevron_right, color: c.mutedForeground),
                  borderColor: c.secondary.withOpacity(0.25),
                  onTap: () => context.push(AppRoutes.ayarlar),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showColorPicker() async {
    final key = _cpKey;
    if (key == null) return;
    final c = ref.read(themeDefinitionProvider).colors;
    await showDialog<void>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.45),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModal) {
            return Center(
              child: Material(
                color: c.card,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 320,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: _cpColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Kart Rengi',
                              style: TextStyle(
                                color: c.foreground,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'Inter',
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              setState(() => _cpKey = null);
                              Navigator.pop(ctx);
                            },
                            icon: Icon(Icons.close, color: c.mutedForeground),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _modeBtn(
                              c,
                              label: 'Sol Kenar',
                              selected: _cpMode == 'accent',
                              onTap: () => setModal(() => _cpMode = 'accent'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _modeBtn(
                              c,
                              label: 'Dolgu',
                              selected: _cpMode == 'fill',
                              onTap: () => setModal(() => _cpMode = 'fill'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        alignment: WrapAlignment.center,
                        children: [
                          for (final col in _softColors)
                            GestureDetector(
                              onTap: () => setModal(() => _cpColor = col),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 120),
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: col,
                                  shape: BoxShape.circle,
                                  border: _cpColor == col
                                      ? Border.all(
                                          color: Colors.white, width: 3)
                                      : null,
                                  boxShadow: _cpColor == col
                                      ? [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.25),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ]
                                      : null,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                setState(() {
                                  _tileColors.remove(key);
                                  _cpKey = null;
                                });
                                _persistColors();
                                Navigator.pop(ctx);
                              },
                              icon: Icon(Icons.refresh,
                                  size: 13, color: c.mutedForeground),
                              label: Text(
                                'Sıfırla',
                                style: TextStyle(
                                  color: c.mutedForeground,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Inter',
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: c.border),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 2,
                            child: FilledButton.icon(
                              onPressed: () {
                                setState(() {
                                  _tileColors[key] = _TileColorConfig(
                                    mode: _cpMode,
                                    color: _cpColor,
                                  );
                                  _cpKey = null;
                                });
                                _persistColors();
                                Navigator.pop(ctx);
                              },
                              icon: const Icon(Icons.check, size: 13),
                              label: const Text(
                                'Uygula',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Inter',
                                ),
                              ),
                              style: FilledButton.styleFrom(
                                backgroundColor: _cpColor,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
    if (mounted && _cpKey != null) setState(() => _cpKey = null);
  }

  Widget _modeBtn(
    ThemeColors c, {
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: selected ? _cpColor.withOpacity(0.1) : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? _cpColor : c.border,
              width: 1.5,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: selected ? _cpColor : c.mutedForeground,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              fontFamily: 'Inter',
            ),
          ),
        ),
      ),
    );
  }

  Widget _welcomeCard(
    ThemeColors c,
    AppState state,
    String dateStr,
    String dayStr,
  ) {
    final ws = state.workspaceInfo;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.secondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Hoş geldiniz',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 13,
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  (state.currentAppUser?.name ?? '').toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: c.secondaryForeground,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  state.currentRole?.name ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 13,
                    fontFamily: 'Inter',
                  ),
                ),
                if (ws != null) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.layers, size: 12, color: Color(0xFFE85D04)),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          ws.id == 'local' ? 'Yerel kullanım' : ws.companyName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFFCBD5E1),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ),
                      if (ws.id != 'local') ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0x2EE85D04),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            ws.inviteCode,
                            style: const TextStyle(
                              color: Color(0xFFE85D04),
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Icon(Icons.calendar_today, size: 16, color: Color(0xFF60A5FA)),
              const SizedBox(height: 4),
              Text(
                dateStr,
                style: TextStyle(
                  color: c.secondaryForeground,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Inter',
                ),
              ),
              Text(
                dayStr,
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 12,
                  fontFamily: 'Inter',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _syncBar(ThemeColors c, dynamic ws) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_outlined, size: 16, color: Color(0xFF94A3B8)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Bulut · ${ws.inviteCode}',
              style: const TextStyle(
                color: Color(0xFFCBD5E1),
                fontSize: 11,
                fontWeight: FontWeight.w500,
                fontFamily: 'Inter',
              ),
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: _syncing ? null : _sync,
            icon: _syncing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.sync, size: 18, color: Color(0xFFE85D04)),
          ),
        ],
      ),
    );
  }

  Widget _hiVisBanner(ThemeColors c, String themeId) {
    final label = themeId == 'hivis-orange'
        ? 'TURUNCU · İSG MODU'
        : themeId == 'hivis-lime'
            ? 'LIME · İSG MODU'
            : 'HI-VIS · İSG MODU';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(6),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded, size: 12, color: c.primary),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    color: c.primary,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2.5,
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
          ),
          _HazardStripe(height: 8, accent: c.card, ink: c.primary),
        ],
      ),
    );
  }

  Widget _shortcut(
    ThemeColors c, {
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String sub,
    required Widget trailing,
    required Color borderColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: c.card,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor, width: 1.5),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: c.foreground,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Inter',
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      sub,
                      style: TextStyle(
                        color: c.mutedForeground,
                        fontSize: 12,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
              ),
              trailing,
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeBrandMark extends StatelessWidget {
  const _HomeBrandMark({required this.colors});
  final ThemeColors colors;

  @override
  Widget build(BuildContext context) {
    final onLight = colors.secondary.computeLuminance() > 0.55;
    final asset = onLight
        ? 'assets/images/splash_wordmark_light.png'
        : 'assets/images/splash_wordmark.png';
    return Row(
      children: [
        Flexible(
          child: Image.asset(
            asset,
            height: 28,
            fit: BoxFit.contain,
            alignment: Alignment.centerLeft,
            errorBuilder: (_, __, ___) => Text(
              'ŞantiJET',
              style: TextStyle(
                color: colors.secondaryForeground,
                fontSize: 22,
                fontWeight: FontWeight.w700,
                fontFamily: 'Rajdhani',
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'PRO',
          style: TextStyle(
            color: colors.secondaryForeground,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.75,
            fontFamily: 'Inter',
          ),
        ),
      ],
    );
  }
}

class _HazardStripe extends StatelessWidget {
  const _HazardStripe({
    required this.height,
    required this.accent,
    required this.ink,
    this.segments = 28,
  });

  final double height;
  final Color accent;
  final Color ink;
  final int segments;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ColoredBox(
        color: accent,
        child: Row(
          children: List.generate(segments, (i) {
            return Transform(
              transform: Matrix4.skewX(-0.5),
              child: Container(
                width: 14,
                height: height * 3,
                margin: EdgeInsets.only(top: -height, left: -3),
                color: i.isEven ? ink : Colors.transparent,
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _ModuleGrid extends StatelessWidget {
  const _ModuleGrid({
    required this.sections,
    required this.state,
    required this.colors,
    required this.isHiVis,
    required this.isSteel,
    required this.tileColors,
    required this.dragKey,
    required this.getPermission,
    required this.onTap,
    required this.onLongPressColor,
    required this.onDragStarted,
    required this.onDragEnded,
    required this.onAccept,
  });

  final List<_Section> sections;
  final AppState state;
  final ThemeColors colors;
  final bool isHiVis;
  final bool isSteel;
  final Map<String, _TileColorConfig> tileColors;
  final String? dragKey;
  final Permission Function(PageKey) getPermission;
  final ValueChanged<_Section> onTap;
  final ValueChanged<_Section> onLongPressColor;
  final ValueChanged<String> onDragStarted;
  final VoidCallback onDragEnded;
  final void Function(String a, String b) onAccept;

  @override
  Widget build(BuildContext context) {
    final tileH = isHiVis
        ? 188.0
        : isSteel
            ? 160.0
            : 132.0;
    return LayoutBuilder(
      builder: (context, constraints) {
        const cols = 3;
        const gap = 10.0;
        final tileW = (constraints.maxWidth - gap * (cols - 1)) / cols;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (var i = 0; i < sections.length; i++)
              SizedBox(
                width: tileW,
                height: tileH,
                child: _DraggableTile(
                  section: sections[i],
                  index: i,
                  state: state,
                  colors: colors,
                  isHiVis: isHiVis,
                  isSteel: isSteel,
                  tileColor: tileColors[sections[i].wire],
                  permission: getPermission(sections[i].key),
                  dragging: dragKey == sections[i].wire,
                  onTap: () => onTap(sections[i]),
                  onLongPressColor: () => onLongPressColor(sections[i]),
                  onDragStarted: () => onDragStarted(sections[i].wire),
                  onDragEnded: onDragEnded,
                  onAccept: (other) => onAccept(sections[i].wire, other),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _DraggableTile extends StatelessWidget {
  const _DraggableTile({
    required this.section,
    required this.index,
    required this.state,
    required this.colors,
    required this.isHiVis,
    required this.isSteel,
    required this.tileColor,
    required this.permission,
    required this.dragging,
    required this.onTap,
    required this.onLongPressColor,
    required this.onDragStarted,
    required this.onDragEnded,
    required this.onAccept,
  });

  final _Section section;
  final int index;
  final AppState state;
  final ThemeColors colors;
  final bool isHiVis;
  final bool isSteel;
  final _TileColorConfig? tileColor;
  final Permission permission;
  final bool dragging;
  final VoidCallback onTap;
  final VoidCallback onLongPressColor;
  final VoidCallback onDragStarted;
  final VoidCallback onDragEnded;
  final ValueChanged<String> onAccept;

  @override
  Widget build(BuildContext context) {
    final child = _buildFace();
    return DragTarget<String>(
      onWillAcceptWithDetails: (d) => d.data != section.wire,
      onAcceptWithDetails: (d) => onAccept(d.data),
      builder: (context, candidate, _) {
        final highlight = candidate.isNotEmpty;
        return LongPressDraggable<String>(
          data: section.wire,
          onDragStarted: onDragStarted,
          onDragEnd: (_) => onDragEnded(),
          feedback: Material(
            color: Colors.transparent,
            elevation: 8,
            child: SizedBox(
              width: MediaQuery.sizeOf(context).width / 3 - 14,
              height: isHiVis
                  ? 188
                  : isSteel
                      ? 160
                      : 132,
              child: Opacity(opacity: 0.92, child: child),
            ),
          ),
          childWhenDragging: Opacity(opacity: 0.35, child: child),
          child: GestureDetector(
            onTap: onTap,
            onLongPress: onLongPressColor,
            child: AnimatedScale(
              scale: highlight || dragging ? 1.03 : 1,
              duration: const Duration(milliseconds: 120),
              child: child,
            ),
          ),
        );
      },
    );
  }

  Widget _buildFace() {
    if (isHiVis) return _hiVisFace();
    if (isSteel) return _steelFace();
    return _defaultFace();
  }

  Widget _hiVisFace() {
    final accent = colors.card;
    final ink = colors.primary;
    return Stack(
      children: [
        Positioned(
          left: 4,
          top: 4,
          right: -4,
          bottom: -4,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: ink,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: accent,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: ink, width: 2),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                color: ink,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, size: 9, color: accent),
                    const SizedBox(width: 4),
                    Text(
                      'DİKKAT',
                      style: TextStyle(
                        color: accent,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                        fontFamily: 'Inter',
                      ),
                    ),
                    const Spacer(),
                    Text(
                      section.code,
                      style: TextStyle(
                        color: accent,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: ink,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(section.icon, size: 20, color: accent),
                          ),
                          const Spacer(),
                          Text(
                            '${section.countOf(state)}',
                            style: TextStyle(
                              color: ink,
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        section.label,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: ink,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          fontFamily: 'Inter',
                        ),
                      ),
                      if (permission == Permission.view) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: ink,
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.visibility, size: 9, color: accent),
                              const SizedBox(width: 3),
                              Text(
                                'Salt okunur',
                                style: TextStyle(
                                  color: accent,
                                  fontSize: 9,
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
                ),
              ),
              _HazardStripe(
                height: 6,
                segments: 20,
                accent: accent,
                ink: ink,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _steelFace() {
    return Container(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Container(width: 4, color: section.color),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: section.color.withOpacity(0.13),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: section.color.withOpacity(0.33),
                        ),
                      ),
                      child: Icon(section.icon, size: 18, color: section.color),
                    ),
                    const Spacer(),
                    Text(
                      '#${(index + 1).toString().padLeft(2, '0')}',
                      style: TextStyle(
                        color: colors.mutedForeground,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  section.label.toUpperCase(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.foreground,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '${section.countOf(state)}',
                      style: TextStyle(
                        color: colors.foreground,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Inter',
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        permission == Permission.view
                            ? 'Salt okunur'
                            : section.sub,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.mutedForeground,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Divider(height: 1, color: colors.border),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      'AÇ',
                      style: TextStyle(
                        color: colors.mutedForeground,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                        fontFamily: 'Inter',
                      ),
                    ),
                    const Spacer(),
                    Icon(Icons.chevron_right,
                        size: 12, color: colors.mutedForeground),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _defaultFace() {
    final neon = tileColor?.color ?? (_sectionNeon[section.wire] ?? section.color);
    final isFill = tileColor?.mode == 'fill';
    final bg = isFill ? neon.withOpacity(0.13) : colors.card;
    final border =
        isFill ? neon.withOpacity(0.35) : neon.withOpacity(0.2);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                _sectionNum[section.wire] ?? '',
                style: const TextStyle(
                  color: Color(0xFF334155),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  fontFamily: 'Inter',
                ),
              ),
              const Spacer(),
              if (permission == Permission.view)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F2FE),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(Icons.visibility,
                      size: 8, color: Color(0xFF0EA5E9)),
                ),
            ],
          ),
          Expanded(
            child: Center(
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: neon.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(section.icon, size: 26, color: neon),
              ),
            ),
          ),
          Text(
            section.label.toUpperCase(),
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: colors.cardForeground,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(color: neon, shape: BoxShape.circle),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '${section.countOf(state)} ${section.sub}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: neon,
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: neon.withOpacity(0.33)),
                ),
                child: Icon(Icons.chevron_right, size: 9, color: neon),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
