import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:santijet_ana/core/routing/app_routes.dart';
import 'package:santijet_ana/core/theme/theme_colors.dart';
import 'package:santijet_ana/core/theme/theme_provider.dart';
import 'package:santijet_ana/data/providers/app_state_provider.dart';

class _RowItem {
  const _RowItem({
    required this.icon,
    required this.title,
    required this.sub,
    required this.route,
  });

  final IconData icon;
  final String title;
  final String sub;
  final String route;
}

/// Ayarlar hub — tema, dil, kataloglar, veri, hesap.
class AyarlarScreen extends ConsumerStatefulWidget {
  const AyarlarScreen({super.key});

  @override
  ConsumerState<AyarlarScreen> createState() => _AyarlarScreenState();
}

class _AyarlarScreenState extends ConsumerState<AyarlarScreen> {
  Future<void> _openAccountSheet() async {
    final state = ref.read(appStateProvider);
    final user = state.currentAppUser;
    final c = ref.read(themeDefinitionProvider).colors;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: c.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            16,
            20,
            MediaQuery.paddingOf(ctx).bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: c.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              CircleAvatar(
                radius: 32,
                backgroundColor: const Color(0xFFEA580C),
                child: Text(
                  user != null && user.name.isNotEmpty
                      ? user.name[0].toUpperCase()
                      : 'U',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                user?.name ?? 'Hesap',
                style: TextStyle(
                  color: c.foreground,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Inter',
                ),
              ),
              const SizedBox(height: 4),
              Text(
                state.currentRole?.name ?? 'Oturum',
                style: TextStyle(
                  color: c.mutedForeground,
                  fontSize: 13,
                  fontFamily: 'Inter',
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    ref.read(appStateProvider.notifier).logout();
                  },
                  icon: const Icon(Icons.logout, size: 18),
                  label: const Text(
                    'Oturumu Kapat',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Inter',
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: c.destructive,
                    side: BorderSide(color: c.destructive.withOpacity(0.5)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeDefinitionProvider);
    final c = theme.colors;
    final state = ref.watch(appStateProvider);
    final isAdmin = state.currentRole?.isAdmin == true;
    final top = MediaQuery.paddingOf(context).top;

    const general = [
      _RowItem(
        icon: Icons.water_drop_outlined,
        title: 'Temalar',
        sub: 'Uygulama görünümünü kişiselleştirin',
        route: AppRoutes.temalar,
      ),
      _RowItem(
        icon: Icons.language,
        title: 'Dil',
        sub: 'Arayüz dilini seçin',
        route: AppRoutes.dil,
      ),
    ];

    const construction = [
      _RowItem(
        icon: Icons.menu_book_outlined,
        title: 'İmalat Poz Analizleri',
        sub: 'Resmi analiz tabloları, fiyat hesaplamaları ve özel analizler',
        route: AppRoutes.imalatPozlari,
      ),
      _RowItem(
        icon: Icons.home_outlined,
        title: 'Yapı Yaklaşık Birim Maliyetleri',
        sub: 'Yıllık tebliğler, yapı sınıfı fiyatları ve yıllar arası mukayese',
        route: AppRoutes.yybm,
      ),
      _RowItem(
        icon: Icons.work_outline,
        title: 'Meslekler',
        sub: 'Kullanıcı meslek kategorilerini ekleyin, düzenleyin, sıralayın',
        route: AppRoutes.meslekler,
      ),
      _RowItem(
        icon: Icons.layers_outlined,
        title: 'Meslek Grubu',
        sub: 'Kalıp, Demir, Duvar, Çelik gibi inşaat meslek gruplarını yönetin',
        route: AppRoutes.meslekGrubu,
      ),
    ];

    const material = [
      _RowItem(
        icon: Icons.grid_view_rounded,
        title: 'Malzeme Kategorisi',
        sub: 'Kategori ağacını yönetin',
        route: AppRoutes.malzemeKategorisi,
      ),
      _RowItem(
        icon: Icons.inventory_2_outlined,
        title: 'Malzeme Listesi',
        sub: 'Katalog kalemlerini düzenleyin',
        route: AppRoutes.malzemeListesi,
      ),
      _RowItem(
        icon: Icons.tag,
        title: 'Malzeme Birimi',
        sub: 'Ölçü birimlerini yönetin',
        route: AppRoutes.malzemeBirimi,
      ),
    ];

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
                      context.go(AppRoutes.home);
                    }
                  },
                  icon: Icon(Icons.arrow_back, color: c.secondaryForeground),
                ),
                Expanded(
                  child: Text(
                    'Ayarlar',
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
                _navRow(
                  c,
                  leading: CircleAvatar(
                    radius: 20,
                    backgroundColor: const Color(0xFFEA580C),
                    child: Text(
                      state.currentAppUser != null &&
                              state.currentAppUser!.name.isNotEmpty
                          ? state.currentAppUser!.name[0].toUpperCase()
                          : 'U',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ),
                  title: 'Hesabım',
                  sub: state.currentAppUser?.name ?? 'Profil ve oturum',
                  onTap: _openAccountSheet,
                ),
                const SizedBox(height: 20),
                _section(c, 'GENEL'),
                for (var i = 0; i < general.length; i++) ...[
                  if (i > 0) const SizedBox(height: 10),
                  _linkRow(c, general[i]),
                ],
                if (isAdmin) ...[
                  const SizedBox(height: 24),
                  _section(c, 'İNŞAAT'),
                  for (var i = 0; i < construction.length; i++) ...[
                    if (i > 0) const SizedBox(height: 10),
                    _linkRow(c, construction[i]),
                  ],
                  const SizedBox(height: 24),
                  _section(c, 'MALZEME'),
                  for (var i = 0; i < material.length; i++) ...[
                    if (i > 0) const SizedBox(height: 10),
                    _linkRow(c, material[i]),
                  ],
                  const SizedBox(height: 24),
                  _section(c, 'VERİ'),
                  _linkRow(
                    c,
                    const _RowItem(
                      icon: Icons.storage_outlined,
                      title: 'Veri Yönetimi',
                      sub: 'Veri dışa/içe aktarma, yedekleme',
                      route: AppRoutes.veriYonetim,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(ThemeColors c, String title) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(
          title,
          style: TextStyle(
            color: c.foreground,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            fontFamily: 'Inter',
          ),
        ),
      );

  Widget _linkRow(ThemeColors c, _RowItem r) {
    return _navRow(
      c,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: c.foreground.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(r.icon, size: 20, color: c.foreground),
      ),
      title: r.title,
      sub: r.sub,
      onTap: () => context.push(r.route),
    );
  }

  Widget _navRow(
    ThemeColors c, {
    required Widget leading,
    required String title,
    required String sub,
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
            border: Border.all(color: c.secondary.withOpacity(0.25)),
          ),
          child: Row(
            children: [
              leading,
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
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Inter',
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      sub,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: c.mutedForeground,
                        fontSize: 12,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: c.mutedForeground, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
