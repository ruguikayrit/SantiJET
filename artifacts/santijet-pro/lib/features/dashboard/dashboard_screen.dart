import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/access/home_summary_visibility.dart';
import '../../core/domain/project_progress.dart';
import '../../core/theme/pro_theme.dart';

part 'reports_desk.dart';
part 'saha_desk.dart';
part 'saha_turu_desk.dart';
part 'yeni_saha_turu_desk.dart';
part 'gorev_ozet_desk.dart';
part 'puantaj_desk.dart';
part 'personel_desk.dart';
part 'personel_bilgi_desk.dart';
part 'personel_ekle_desk.dart';
part 'gorevler_desk.dart';
part 'imalat_desk.dart';
part 'imalat_kayit_ekle_desk.dart';
part 'imalat_tip_katalog.dart';
part 'yeni_imalat_tip_desk.dart';
part 'makine_desk.dart';
part 'malzeme_desk.dart';
part 'modul_kapak_desk.dart';
part 'projects_desk.dart';
part 'gunluk_rapor_desk.dart';

class _DemoScope extends InheritedWidget {
  const _DemoScope({required this.loaded, required super.child});

  final bool loaded;

  static bool of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_DemoScope>()?.loaded ?? false;
  }

  @override
  bool updateShouldNotify(_DemoScope oldWidget) => loaded != oldWidget.loaded;
}

class _ProjectProgressScope extends InheritedWidget {
  const _ProjectProgressScope({required this.snapshot, required super.child});

  final ProjectProgressSnapshot? snapshot;

  static ProjectProgressSnapshot? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_ProjectProgressScope>()?.snapshot;
  }

  @override
  bool updateShouldNotify(_ProjectProgressScope oldWidget) => snapshot != oldWidget.snapshot;
}

class _HomeSummaryScope extends InheritedWidget {
  const _HomeSummaryScope({required this.visibility, required super.child});

  final HomeSummaryVisibility visibility;

  static HomeSummaryVisibility of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_HomeSummaryScope>()?.visibility ?? const HomeSummaryVisibility();
  }

  @override
  bool updateShouldNotify(_HomeSummaryScope oldWidget) => visibility != oldWidget.visibility;
}

abstract final class _Demo {
  static const project = 'İstanbul Residence';
  static const place = 'İstanbul';
  static const span = '01 Mar – 30 Ara 2026';
  static const verim = ['%71', '%54', '%38'];
  static const butce = '128 M₺';
  static const maliyet = '74 M₺';
  static const kasa = '6,4 M₺';
  static const hakedis = '61 M₺';
  static const beton = ['4.800 m³', '2.960 m³', '%62'];
  static const demir = ['860 t', '540 t', '%63'];
  static const malzeme = ['6', '18', '14'];
  static const program = ['%58', '1.640', '3'];
}

void _keepInPro(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Kayıt bu uygulamada henüz tutulmuyor.')),
  );
}

/// Ana ekran. Rakamlar proje bağlanınca dolacak.
/// Ortak proje verisi bağlanana kadar değer gösterilmez.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

enum _Desk {
  home,
  modules,
  saha,
  sahaTuru,
  yeniSahaTuru,
  puantaj,
  personel,
  gorevler,
  imalat,
  imalatKayitEkle,
  yeniImalatTipi,
  makine,
  malzeme,
  modul,
  projects,
  reports,
  gunlukRapor,
  menu,
}

class _DashboardScreenState extends State<DashboardScreen> {
  _Desk _desk = _Desk.home;
  var _demo = true;
  var _modulId = 'beton';
  String? _bolumBaslik;
  late List<_ImalatKayit> _imalatKayitlari = _ImalatDesk.demoKayitlar();
  var _imalatOzelTipler = <_ImalatAltTurTanim>[];
  _ImalatAnaTur _yeniImalatTipBaslangicAna = _ImalatAnaTur.insaat;
  String? _yeniImalatTipBaslangicBolum;
  String? _imalatKayitEkleSeciliTipId;

  void _openModul(String id) {
    setState(() {
      _modulId = id;
      _bolumBaslik = null;
      _desk = _Desk.modul;
    });
  }

  void _loadDemo() {
    setState(() {
      _demo = true;
      _desk = _Desk.home;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Demo veriler yüklendi. Aktif proje: İstanbul Residence.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ProColors.canvas,
      body: SafeArea(
        bottom: false,
        child: _DemoScope(
          loaded: _demo,
          child: _ProjectProgressScope(
            snapshot: _demo ? DemoProjectProgress.snapshot(DateTime.now()) : null,
            child: _HomeSummaryScope(
              visibility: HomeSummaryVisibility.forRole(null),
              child: switch (_desk) {
          _Desk.home => _HomeDesk(onOpenSaha: () => setState(() => _desk = _Desk.saha)),
          _Desk.modules => _ModulesDesk(
                onOpenSaha: () => setState(() => _desk = _Desk.saha),
                onOpenModul: _openModul,
              ),
          _Desk.saha => _SahaDesk(
                onOpenPuantaj: () => setState(() => _desk = _Desk.puantaj),
                onOpenPersonel: () => setState(() => _desk = _Desk.personel),
                onOpenGorevler: () => setState(() => _desk = _Desk.gorevler),
                onOpenImalat: () => setState(() => _desk = _Desk.imalat),
                onOpenMakine: () => setState(() => _desk = _Desk.makine),
                onOpenMalzeme: () => setState(() => _desk = _Desk.malzeme),
                onOpenSahaTuru: () => setState(() => _desk = _Desk.sahaTuru),
              ),
          _Desk.sahaTuru => _SahaTuruDesk(
                onBack: () => setState(() => _desk = _Desk.saha),
                onYeniTur: () => setState(() => _desk = _Desk.yeniSahaTuru),
              ),
          _Desk.yeniSahaTuru => _YeniSahaTuruDesk(onBack: () => setState(() => _desk = _Desk.sahaTuru)),
          _Desk.puantaj => _PuantajDesk(onBack: () => setState(() => _desk = _Desk.saha)),
          _Desk.personel => _PersonelDesk(onBack: () => setState(() => _desk = _Desk.saha)),
          _Desk.gorevler => _GorevlerDesk(onBack: () => setState(() => _desk = _Desk.saha)),
          _Desk.imalat => _ImalatDesk(
                kayitlar: _imalatKayitlari,
                ozelTipler: _imalatOzelTipler,
                onBack: () => setState(() => _desk = _Desk.saha),
                onOpenKayitEkle: () => setState(() => _desk = _Desk.imalatKayitEkle),
              ),
          _Desk.imalatKayitEkle => _ImalatKayitEkleDesk(
                ozelTipler: _imalatOzelTipler,
                seciliAltTurId: _imalatKayitEkleSeciliTipId,
                onBack: () => setState(() => _desk = _Desk.imalat),
                onOpenYeniTip: (ana, bolum) => setState(() {
                  _yeniImalatTipBaslangicAna = ana;
                  _yeniImalatTipBaslangicBolum = bolum;
                  _imalatKayitEkleSeciliTipId = null;
                  _desk = _Desk.yeniImalatTipi;
                }),
                onKaydet: (taslak) {
                  setState(() {
                    _imalatKayitlari = [..._imalatKayitlari, _ImalatKayit.taslaktan(taslak, _imalatOzelTipler)];
                    _imalatKayitEkleSeciliTipId = null;
                    _desk = _Desk.imalat;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('İmalat kaydı listeye eklendi.')),
                  );
                },
              ),
          _Desk.yeniImalatTipi => _YeniImalatTipiDesk(
                baslangicAnaTur: _yeniImalatTipBaslangicAna,
                baslangicBolum: _yeniImalatTipBaslangicBolum,
                ozelTipler: _imalatOzelTipler,
                onBack: () => setState(() => _desk = _Desk.imalatKayitEkle),
                onOlustur: (tip) {
                  setState(() {
                    _imalatOzelTipler = [..._imalatOzelTipler, tip];
                    _imalatKayitEkleSeciliTipId = tip.id;
                    _desk = _Desk.imalatKayitEkle;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${tip.label}, ${tip.bolum} listesine eklendi.')),
                  );
                },
              ),
          _Desk.makine => _MakineDesk(onBack: () => setState(() => _desk = _Desk.saha)),
          _Desk.malzeme => _MalzemeDesk(onBack: () => setState(() => _desk = _Desk.saha)),
          _Desk.modul => _ModulHost(
                id: _modulId,
                bolum: _bolumBaslik,
                onOpenBolum: (baslik) => setState(() => _bolumBaslik = baslik),
                onBackToKapak: () => setState(() => _bolumBaslik = null),
              ),
          _Desk.projects => const _ProjectsDesk(),
          _Desk.reports => _ReportsDesk(onOpenGunlukRapor: () => setState(() => _desk = _Desk.gunlukRapor)),
          _Desk.gunlukRapor => _GunlukRaporDesk(onBack: () => setState(() => _desk = _Desk.reports)),
          _Desk.menu => _MenuDesk(
              demoLoaded: _demo,
              onSelect: (desk) => setState(() => _desk = desk),
              onLoadDemo: _loadDemo,
            ),
          },
            ),
          ),
        ),
      ),
      bottomNavigationBar: _desk == _Desk.yeniSahaTuru
          ? null
          : _BottomBar(
        desk: _desk,
        onSelect: (desk) => setState(() => _desk = desk),
        onQuickAdd: () => setState(() {
          _desk = _desk == _Desk.modules ? _Desk.home : _Desk.modules;
        }),
      ),
    );
  }
}

class _HomeDesk extends StatelessWidget {
  const _HomeDesk({required this.onOpenSaha});

  final VoidCallback onOpenSaha;

  @override
  Widget build(BuildContext context) {
    final ozet = _HomeSummaryScope.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        const _TopBar(),
        const SizedBox(height: 14),
        const _ProjectHero(),
        const SizedBox(height: 12),
        const _OzetBasligi('Genel proje ilerleme'),
        const SizedBox(height: 8),
        _SahaProgress(onOpen: onOpenSaha),
        const SizedBox(height: 10),
        _VerimKpi(onOpenSaha: onOpenSaha),
        if (ozet.shows(HomeSummarySection.finansalOzet)) ...[
          const SizedBox(height: 10),
          const _OzetBasligi('Finansal özet'),
          const SizedBox(height: 8),
          const _FinanceRow(),
        ],
        if (ozet.shows(HomeSummarySection.teknikOzet)) ...[
          const SizedBox(height: 10),
          const _OzetBasligi('Teknik özet'),
          const SizedBox(height: 8),
          const _SourceKpis(),
        ],
      ],
    );
  }
}

class _OzetBasligi extends StatelessWidget {
  const _OzetBasligi(this.baslik);

  final String baslik;

  @override
  Widget build(BuildContext context) {
    return Text(
      baslik,
      style: const TextStyle(
        fontFamily: 'Rajdhani',
        fontWeight: FontWeight.w700,
        fontSize: 16,
        color: ProColors.text,
      ),
    );
  }
}

class _ModulesDesk extends StatelessWidget {
  const _ModulesDesk({required this.onOpenSaha, required this.onOpenModul});

  final VoidCallback onOpenSaha;
  final ValueChanged<String> onOpenModul;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        const _ModulDeskUst(
          title: 'Modüller',
          moduleIcon: Icons.grid_view_rounded,
          moduleColor: ProColors.electricBlue,
        ),
        const SizedBox(height: 12),
        _ModuleGrid(onOpenSaha: onOpenSaha, onOpenModul: onOpenModul),
      ],
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({this.alertCount = 0, this.actions = true});

  final int alertCount;
  final bool actions;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const _ProLockup(),
        if (actions) ...[
          const Spacer(),
          _TopBarTrailing(alertCount: alertCount),
        ],
      ],
    );
  }
}

/// Ana sayfa markası. Şimşek ve wordmark dosyalarındaki boş kenar kırpılır.
class _ProLockup extends StatelessWidget {
  const _ProLockup();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _CroppedAsset(
          asset: 'assets/images/splash_bolt.png',
          sourceWidth: 1254,
          sourceHeight: 1254,
          cropLeft: 295,
          cropTop: 167,
          cropWidth: 633,
          cropHeight: 841,
          height: 30,
        ),
        SizedBox(width: 10),
        _CroppedAsset(
          asset: 'assets/images/splash_wordmark.png',
          sourceWidth: 895,
          sourceHeight: 150,
          cropLeft: 12,
          cropTop: 18,
          cropWidth: 871,
          cropHeight: 132,
          height: 18,
        ),
      ],
    );
  }
}

class _CroppedAsset extends StatelessWidget {
  const _CroppedAsset({
    required this.asset,
    required this.sourceWidth,
    required this.sourceHeight,
    required this.cropLeft,
    required this.cropTop,
    required this.cropWidth,
    required this.cropHeight,
    required this.height,
  });

  final String asset;
  final double sourceWidth;
  final double sourceHeight;
  final double cropLeft;
  final double cropTop;
  final double cropWidth;
  final double cropHeight;
  final double height;

  @override
  Widget build(BuildContext context) {
    final scale = height / cropHeight;
    return ClipRect(
      child: Align(
        alignment: Alignment(
          _align(cropLeft, cropWidth, sourceWidth),
          _align(cropTop, cropHeight, sourceHeight),
        ),
        widthFactor: cropWidth / sourceWidth,
        heightFactor: cropHeight / sourceHeight,
        child: Image.asset(
          asset,
          width: sourceWidth * scale,
          height: sourceHeight * scale,
          fit: BoxFit.fill,
          filterQuality: FilterQuality.high,
        ),
      ),
    );
  }

  /// Görünür pencere [crop] bölgesine oturur.
  static double _align(double cropStart, double cropSize, double source) {
    final hidden = source - cropSize;
    if (hidden == 0) return 0;
    return (cropStart / (hidden / 2)) - 1;
  }
}

class _TopBarTrailing extends StatelessWidget {
  const _TopBarTrailing({this.alertCount = 0});

  final int alertCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            const Icon(Icons.notifications_none, color: ProColors.text, size: 22),
            if (alertCount > 0)
              Positioned(
                right: -6,
                top: -4,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(color: Color(0xFFEF4444), shape: BoxShape.circle),
                  child: Text(
                    '$alertCount',
                    style: const TextStyle(fontFamily: 'Inter', fontSize: 8, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(width: 12),
        const CircleAvatar(
          radius: 14,
          backgroundColor: ProColors.border,
          child: Icon(Icons.person, size: 16, color: ProColors.textMuted),
        ),
      ],
    );
  }
}

/// Modül ızgarasındaki simge ve renk (masa üst barı ile aynı).
abstract final class _ModulDeskMark {
  static const sahaIcon = Icons.groups_outlined;
  static const sahaColor = Color(0xFF1D4ED8);

  static const betonIcon = Icons.foundation_outlined;
  static const betonColor = Color(0xFFE11D48);

  static const demirIcon = Icons.view_week_outlined;
  static const demirColor = Color(0xFF0F766E);

  static const malzemeIcon = Icons.inventory_2_outlined;
  static const malzemeColor = Color(0xFFEAB308);

  static const isProgramiIcon = Icons.calendar_month_outlined;
  static const isProgramiColor = Color(0xFF0284C7);

  static const maliyetIcon = Icons.show_chart;
  static const maliyetColor = Color(0xFFF59E0B);

  static const kasaIcon = Icons.account_balance_wallet_outlined;
  static const kasaColor = Color(0xFF4338CA);
}

/// Modül masaları: marka yok; modül simgesi + ad sol üstte.
class _ModulDeskUst extends StatelessWidget {
  const _ModulDeskUst({
    required this.title,
    required this.moduleIcon,
    required this.moduleColor,
    this.backKey,
    this.onBack,
    this.backLabel,
    this.trailing,
  });

  final String title;
  final IconData moduleIcon;
  final Color moduleColor;
  final Key? backKey;
  final VoidCallback? onBack;
  final String? backLabel;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (onBack != null)
            InkWell(
              key: backKey,
              onTap: onBack,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.chevron_left, color: ProColors.text, size: 22),
                    if (backLabel != null)
                      Text(
                        backLabel!,
                        style: const TextStyle(fontFamily: 'Inter', fontSize: 15, color: ProColors.text),
                      ),
                  ],
                ),
              ),
            ),
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: moduleColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(moduleIcon, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Rajdhani',
                fontWeight: FontWeight.w700,
                fontSize: 22,
                color: ProColors.text,
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class _OnlineSahaNokta extends StatefulWidget {
  const _OnlineSahaNokta();

  @override
  State<_OnlineSahaNokta> createState() => _OnlineSahaNoktaState();
}

class _OnlineSahaNoktaState extends State<_OnlineSahaNokta> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));
    // Widget testlerinde pumpAndSettle takılmasın; gerçek cihazda yanıp söner.
    final testBinding = WidgetsBinding.instance.runtimeType.toString().contains('TestWidgets');
    if (testBinding) {
      _pulse.value = 1;
    } else {
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_pulse.value);
        final glow = 4 + t * 6;
        final opacity = 0.55 + t * 0.45;
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF39FF14).withValues(alpha: opacity),
            boxShadow: [
              BoxShadow(color: const Color(0xFF39FF14).withValues(alpha: 0.85 * opacity), blurRadius: glow, spreadRadius: t * 1.5),
            ],
          ),
        );
      },
    );
  }
}

class _ProjectHero extends StatelessWidget {
  const _ProjectHero();

  @override
  Widget build(BuildContext context) {
    final demo = _DemoScope.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ColoredBox(
                color: const Color(0xFF10243F),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 11, 8, 11),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'AKTİF PROJE',
                            style: TextStyle(
                              fontFamily: 'Rajdhani',
                              fontSize: 11,
                              letterSpacing: 1.2,
                              color: Color(0xFF9EC1FF),
                            ),
                          ),
                          if (demo) ...[
                            const SizedBox(width: 6),
                            const _OnlineSahaNokta(),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        demo ? _Demo.project : 'Henüz proje yok',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Rajdhani',
                          fontWeight: FontWeight.w700,
                          fontSize: 22,
                          height: 1.05,
                          color: ProColors.text,
                        ),
                      ),
                      if (!demo) ...[
                        const SizedBox(height: 4),
                        const Text(
                          'KPI değerleri proje bağlanınca dolacak',
                          maxLines: 2,
                          style: TextStyle(fontFamily: 'Inter', fontSize: 11, height: 1.25, color: ProColors.textMuted),
                        ),
                      ],
                      SizedBox(height: demo ? 10 : 8),
                      Row(
                        children: [
                          const Icon(Icons.place_outlined, size: 14, color: ProColors.textMuted),
                          const SizedBox(width: 4),
                          Text(demo ? _Demo.place : '—', style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: ProColors.text)),
                          const SizedBox(width: 12),
                          const Icon(Icons.calendar_today_outlined, size: 13, color: ProColors.textMuted),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              demo ? _Demo.span : '—',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: ProColors.text),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(
              width: 92,
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF5B7CFF), Color(0xFFE07A2F), Color(0xFF1A120C)],
                  ),
                ),
                child: Center(
                  child: Icon(Icons.apartment_rounded, color: Colors.white, size: 32),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Saha ana sayfası: İnşaat / Elektrik / Mekanik grup verimi.
class _VerimKpi extends StatelessWidget {
  const _VerimKpi({required this.onOpenSaha});

  final VoidCallback onOpenSaha;

  @override
  Widget build(BuildContext context) {
    final demo = _DemoScope.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _OzetBasligi('Verim özeti'),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _VerimCard(label: 'İNŞAAT', value: demo ? _Demo.verim[0] : '—', color: const Color(0xFF16A34A), onTap: onOpenSaha)),
            const SizedBox(width: 8),
            Expanded(child: _VerimCard(label: 'ELEKTRİK', value: demo ? _Demo.verim[1] : '—', color: const Color(0xFFD97706), onTap: onOpenSaha)),
            const SizedBox(width: 8),
            Expanded(child: _VerimCard(label: 'MEKANİK', value: demo ? _Demo.verim[2] : '—', color: const Color(0xFFDC2626), onTap: onOpenSaha)),
          ],
        ),
      ],
    );
  }
}

class _VerimCard extends StatelessWidget {
  const _VerimCard({required this.label, required this.value, required this.color, required this.onTap});

  final String label;
  final String value;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.4)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                value,
                textAlign: TextAlign.center,
                style: const TextStyle(fontFamily: 'Rajdhani', fontWeight: FontWeight.w700, fontSize: 26, color: ProColors.text),
              ),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: color),
              ),
              const SizedBox(height: 8),
              const SizedBox(
                height: 4,
                width: double.infinity,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: ProColors.border,
                    borderRadius: BorderRadius.all(Radius.circular(4)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Saha ana sayfası: Proje genel — Süre, Metraj, Adam-gün.
class _SahaProgress extends StatelessWidget {
  const _SahaProgress({this.onOpen});

  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final progress = _ProjectProgressScope.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: _cardDecoration(),
          child: Row(
            children: [
              _Ring(
                label: 'Metraj',
                value: progress?.metrajLabel ?? '—',
                progress: progress?.metrajProgress,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: _MetricColumn(
                        label: 'Süre',
                        value: progress?.sureLabel ?? '—',
                        progress: progress?.durationProgress,
                        fillColor: const Color(0xFF22C55E),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _MetricColumn(
                        label: 'Adam-gün',
                        value: progress?.adamGunLabel ?? '—',
                        progress: progress?.adamGunProgress,
                        fillColor: const Color(0xFF3B82F6),
                      ),
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
}

class _Ring extends StatelessWidget {
  const _Ring({required this.label, required this.value, this.progress});

  final String label;
  final String value;
  final double? progress;

  @override
  Widget build(BuildContext context) {
    final fraction = progress?.clamp(0.0, 1.0);
    return SizedBox(
      width: 92,
      height: 92,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (fraction == null)
            DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: ProColors.border, width: 7),
              ),
              child: const SizedBox(width: 92, height: 92),
            )
          else
            SizedBox(
              width: 92,
              height: 92,
              child: CircularProgressIndicator(
                value: fraction,
                strokeWidth: 7,
                backgroundColor: ProColors.border,
                valueColor: const AlwaysStoppedAnimation<Color>(ProColors.electricBlue),
              ),
            ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontFamily: 'Rajdhani',
                  fontWeight: FontWeight.w700,
                  fontSize: 22,
                  color: ProColors.text,
                ),
              ),
              Text(
                label,
                style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: ProColors.textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricColumn extends StatelessWidget {
  const _MetricColumn({
    required this.label,
    required this.value,
    this.progress,
    this.fillColor = const Color(0xFF22C55E),
  });

  final String label;
  final String value;
  final double? progress;
  final Color fillColor;

  @override
  Widget build(BuildContext context) {
    final fraction = progress?.clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: ProColors.textMuted)),
        Text(
          value,
          style: const TextStyle(fontFamily: 'Rajdhani', fontWeight: FontWeight.w700, fontSize: 22, color: ProColors.text),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            height: 6,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                const ColoredBox(color: Color(0xFF163322)),
                if (fraction != null)
                  FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: fraction,
                    child: ColoredBox(color: fillColor),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _FinanceRow extends StatelessWidget {
  const _FinanceRow();

  @override
  Widget build(BuildContext context) {
    final demo = _DemoScope.of(context);
    final empty = '—';
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _FinanceTile(
                title: 'Bütçe',
                value: demo ? _Demo.butce : empty,
                icon: Icons.pie_chart_outline,
                colors: const [Color(0xFF2563EB), Color(0xFF1D4ED8)],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _FinanceTile(
                title: 'Maliyet',
                value: demo ? _Demo.maliyet : empty,
                icon: Icons.payments_outlined,
                colors: const [Color(0xFFF97316), Color(0xFFEA580C)],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _FinanceTile(
                title: 'Kasa',
                value: demo ? _Demo.kasa : empty,
                icon: Icons.account_balance_wallet_outlined,
                colors: const [Color(0xFF6366F1), Color(0xFF4F46E5)],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _FinanceTile(
                title: 'Hakediş',
                value: demo ? _Demo.hakedis : empty,
                icon: Icons.description_outlined,
                colors: const [Color(0xFFE11D48), Color(0xFFBE123C)],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _FinanceTile extends StatelessWidget {
  const _FinanceTile({
    required this.title,
    required this.value,
    required this.icon,
    required this.colors,
  });

  final String title;
  final String value;
  final IconData icon;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: colors),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(height: 10),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: Colors.white),
          ),
          Text(
            value,
            style: const TextStyle(fontFamily: 'Rajdhani', fontWeight: FontWeight.w700, fontSize: 26, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

/// Boş üretim özeti. Rakam yok.
class _SourceKpis extends StatelessWidget {
  const _SourceKpis();

  @override
  Widget build(BuildContext context) {
    final demo = _DemoScope.of(context);
    const dash = ['—', '—', '—', '—'];
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _SourceCell(title: 'Beton', lines: const ['Planlanan döküm', 'Gerçekleşen döküm', 'Keşif ilerlemesi'], values: demo ? _Demo.beton : dash)),
            const SizedBox(width: 8),
            Expanded(child: _SourceCell(title: 'Demir', lines: const ['Planlanan tonaj', 'Beklenen kullanım', 'İlerleme'], values: demo ? _Demo.demir : dash)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _SourceCell(title: 'Malzeme', lines: const ['Onay bekleyen', 'Onaylandı', 'Teslim edildi'], values: demo ? _Demo.malzeme : dash)),
            const SizedBox(width: 8),
            Expanded(child: _SourceCell(title: 'İş Programı', lines: const ['Ortalama ilerleme', 'Kalan adam-gün', 'Geciken'], values: demo ? _Demo.program : dash)),
          ],
        ),
      ],
    );
  }
}

class _SourceCell extends StatelessWidget {
  const _SourceCell({required this.title, required this.lines, required this.values});

  final String title;
  final List<String> lines;
  final List<String> values;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontFamily: 'Rajdhani', fontWeight: FontWeight.w700, fontSize: 14, color: ProColors.text),
          ),
          for (var i = 0; i < lines.length; i++)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Row(
                children: [
                  Expanded(
                    child: Text(lines[i], style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: ProColors.textMuted)),
                  ),
                  Text(i < values.length ? values[i] : '—', style: const TextStyle(fontSize: 11, color: ProColors.text)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}


class _ModuleGrid extends StatelessWidget {
  const _ModuleGrid({this.onOpenSaha, this.onOpenModul});

  final VoidCallback? onOpenSaha;
  final ValueChanged<String>? onOpenModul;

  static const tiles = <_ModuleTile>[
    _ModuleTile('Saha', 'Puantaj, günlük rapor, imalat', 'saha', _ModulDeskMark.sahaColor, _ModulDeskMark.sahaIcon),
    _ModuleTile('Genel İmalatlar', 'İş kalemi, plan, gerçekleşen', 'genel-imalatlar', Color(0xFFEA580C), Icons.construction_outlined),
    _ModuleTile('Beton', 'Keşif, sipariş, döküm, test', 'beton', _ModulDeskMark.betonColor, _ModulDeskMark.betonIcon),
    _ModuleTile('Demir', 'Sipariş, gelen demir, saha sayım', 'demir', _ModulDeskMark.demirColor, _ModulDeskMark.demirIcon),
    _ModuleTile('Çelik', 'Atölye, sevkiyat, montaj', 'celik', Color(0xFF7C3AED), Icons.precision_manufacturing_outlined),
    _ModuleTile('Malzeme', 'Keşif, talep, teslim, kütüphane', 'malzeme', _ModulDeskMark.malzemeColor, _ModulDeskMark.malzemeIcon),
    _ModuleTile('Satın Alma', 'Tedarikçi, sipariş, irsaliye', 'satin-alma', Color(0xFF16A34A), Icons.shopping_cart_outlined),
    _ModuleTile('İş Programı', 'Program, Gantt, özet', 'is-programi', _ModulDeskMark.isProgramiColor, _ModulDeskMark.isProgramiIcon),
    _ModuleTile('Bütçe', 'Plan, gerçekleşen, sapma', 'butce', Color(0xFFDB2777), Icons.pie_chart_outline),
    _ModuleTile('Maliyet', 'Analiz, metraj, yaklaşık maliyet', 'maliyet', _ModulDeskMark.maliyetColor, _ModulDeskMark.maliyetIcon),
    _ModuleTile('Kasa', 'Gelir, gider, güncel kasa', 'kasa', _ModulDeskMark.kasaColor, _ModulDeskMark.kasaIcon),
    _ModuleTile('Hakediş', 'İşveren ve taşeron', 'hakedis', Color(0xFFDC2626), Icons.description_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: tiles.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 2.15,
      ),
      itemBuilder: (context, index) => _ModuleCard(
        tile: tiles[index],
        onOpenSaha: onOpenSaha,
        onOpenModul: onOpenModul,
      ),
    );
  }
}

class _ModuleTile {
  const _ModuleTile(this.title, this.subtitle, this.moduleId, this.color, this.icon);

  final String title;
  final String subtitle;
  final String moduleId;
  final Color color;
  final IconData icon;
}

class _ModuleCard extends StatelessWidget {
  const _ModuleCard({required this.tile, this.onOpenSaha, this.onOpenModul});

  final _ModuleTile tile;
  final VoidCallback? onOpenSaha;
  final ValueChanged<String>? onOpenModul;

  @override
  Widget build(BuildContext context) {
    final darker = Color.lerp(tile.color, Colors.black, 0.18)!;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        key: Key('module-${tile.moduleId}'),
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          final id = tile.moduleId;
          if (id == 'saha' && onOpenSaha != null) {
            onOpenSaha!();
            return;
          }
          if (onOpenModul != null) {
            onOpenModul!(id);
            return;
          }
          _keepInPro(context);
        },
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [tile.color, darker],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(tile.icon, color: Colors.white, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tile.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Rajdhani',
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        tile.subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: Color(0xF2FFFFFF)),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.white, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.desk,
    required this.onSelect,
    required this.onQuickAdd,
  });

  final _Desk desk;
  final ValueChanged<_Desk> onSelect;
  final VoidCallback onQuickAdd;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF0B1018),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              _NavItem(icon: Icons.home_outlined, label: 'Ana Sayfa', selected: desk == _Desk.home, onTap: () => onSelect(_Desk.home)),
              _NavItem(icon: Icons.folder_outlined, label: 'Projeler', selected: desk == _Desk.projects, onTap: () => onSelect(_Desk.projects)),
              Expanded(
                child: InkWell(
                  key: const Key('quick-add'),
                  onTap: onQuickAdd,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircleAvatar(
                        radius: 16,
                        backgroundColor: ProColors.electricBlue,
                        child: Icon(Icons.add, color: Colors.white, size: 20),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Modüller',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 10,
                          color: desk == _Desk.modules || desk == _Desk.sahaTuru
                              ? ProColors.electricBlue
                              : ProColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              _NavItem(
                icon: Icons.bar_chart_outlined,
                label: 'Raporlar',
                selected: desk == _Desk.reports || desk == _Desk.gunlukRapor,
                onTap: () => onSelect(_Desk.reports),
              ),
              _NavItem(icon: Icons.menu, label: 'Menü', selected: desk == _Desk.menu, onTap: () => onSelect(_Desk.menu)),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? ProColors.electricBlue : ProColors.textMuted;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontFamily: 'Inter', fontSize: 10, color: color)),
          ],
        ),
      ),
    );
  }
}

class _PlainDesk extends StatelessWidget {
  const _PlainDesk({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(title, style: const TextStyle(fontFamily: 'Rajdhani', fontWeight: FontWeight.w700, fontSize: 28, color: ProColors.text)),
        const SizedBox(height: 8),
        Text(body, style: const TextStyle(fontFamily: 'Inter', color: ProColors.textMuted)),
      ],
    );
  }
}

class _MenuDesk extends StatelessWidget {
  const _MenuDesk({required this.onSelect, required this.onLoadDemo, required this.demoLoaded});

  final ValueChanged<_Desk> onSelect;
  final VoidCallback onLoadDemo;
  final bool demoLoaded;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        const _TopBar(actions: false),
        const SizedBox(height: 14),
        const _AccountCard(),
        const SizedBox(height: 10),
        const _AccountMetaRow(),
        const SizedBox(height: 18),
        _MenuKutulari(
          bolumler: [
            _MenuBolum(Icons.grid_view_rounded, 'Proje Yönetimi', [
              _MenuAction('Proje Seç', 'Aktif projeyi değiştir', Icons.apartment_outlined, const [Color(0xFF2563EB), Color(0xFF1D4ED8)], () => onSelect(_Desk.projects)),
              _MenuAction('Ekip Yönetimi', 'Ekip üyelerini yönet', Icons.groups_outlined, const [Color(0xFF7C3AED), Color(0xFF6D28D9)], () => _later(context, 'Ekip Yönetimi')),
              _MenuAction('Firma ve Şantiyeler', 'Firma, şantiye ve ayarlar', Icons.domain_outlined, const [Color(0xFFF97316), Color(0xFFEA580C)], () => _later(context, 'Firma ve Şantiyeler')),
            ]),
            _MenuBolum(Icons.bar_chart_rounded, 'Veri ve Raporlar', [
              _MenuAction('Veri Senkronizasyonu', 'Bulut ile senkronize et', Icons.cloud_upload_outlined, const [Color(0xFF10B981), Color(0xFF059669)], () => _later(context, 'Veri Senkronizasyonu')),
              _MenuAction('Raporlar', 'Tüm raporları görüntüle', Icons.description_outlined, const [Color(0xFF2563EB), Color(0xFF1E40AF)], () => onSelect(_Desk.reports)),
              _MenuAction('İş Programı', 'Plan, takip, gerçekleşme', Icons.calendar_month_outlined, const [Color(0xFF0891B2), Color(0xFF0E7490)], () => _keepInPro(context)),
            ]),
            _MenuBolum(Icons.settings_outlined, 'Ayarlar ve Güvenlik', [
              _MenuAction('Bildirimler', 'Bildirim ayarlarını düzenle', Icons.notifications_none, const [Color(0xFFEF4444), Color(0xFFDC2626)], () => _later(context, 'Bildirimler'), badge: '3'),
              _MenuAction('Güvenlik ve Gizlilik', 'Şifre, biyometrik giriş, veri güvenliği', Icons.verified_user_outlined, const [Color(0xFFF97316), Color(0xFFEA580C)], () => _later(context, 'Güvenlik ve Gizlilik')),
              _MenuAction('Görünüm', 'Tema, dil ve ekran ayarları', Icons.palette_outlined, const [Color(0xFF7C3AED), Color(0xFF6D28D9)], () => _later(context, 'Görünüm')),
            ]),
            _MenuBolum(Icons.help_outline, 'Destek ve Bilgilendirme', [
              _MenuAction('Yardım & Destek', 'Sık sorulan sorular, destek talebi', Icons.chat_bubble_outline, const [Color(0xFF06B6D4), Color(0xFF0891B2)], () => _later(context, 'Yardım & Destek')),
              _MenuAction('Kullanım Kılavuzu', 'Video eğitimler ve rehberler', Icons.school_outlined, const [Color(0xFFEF4444), Color(0xFFB91C1C)], () => _later(context, 'Kullanım Kılavuzu')),
              _MenuAction('Uygulama Hakkında', 'Sürüm 0.1.0 (PRO)', Icons.info_outline, const [Color(0xFF14B8A6), Color(0xFF0F766E)], () => _later(context, 'Uygulama Hakkında')),
            ]),
          ],
        ),
        const SizedBox(height: 16),
        _DemoLoadBar(loaded: demoLoaded, onTap: onLoadDemo),
        const SizedBox(height: 10),
        const _SignOutBar(),
      ],
    );
  }

  void _later(BuildContext context, String title) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$title daha sonra eklenecek.')),
    );
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF16325C), Color(0xFF0E1A2E)],
        ),
        border: Border.all(color: ProColors.border),
      ),
      child: const Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: Color(0xFF1E3A5F),
            child: Icon(Icons.person, color: Colors.white, size: 28),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Uğur Tiryaki',
                  style: TextStyle(fontFamily: 'Rajdhani', fontWeight: FontWeight.w700, fontSize: 20, color: ProColors.text),
                ),
                Text('Şantiye Şefi', style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: ProColors.textMuted)),
                Text('ugur@kantijet.com', style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: Color(0xFF9EC1FF))),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: ProColors.textMuted),
        ],
      ),
    );
  }
}

class _AccountMetaRow extends StatelessWidget {
  const _AccountMetaRow();

  @override
  Widget build(BuildContext context) {
    final demo = _DemoScope.of(context);
    return Row(
      children: [
        Expanded(
          child: _MetaChip(
            icon: Icons.apartment_outlined,
            label: 'Aktif Proje',
            value: demo ? _Demo.project : 'Henüz proje yok',
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          child: _MetaChip(
            icon: Icons.workspace_premium_outlined,
            label: 'Lisans',
            value: 'PRO',
          ),
        ),
      ],
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Icon(icon, color: ProColors.textMuted, size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: ProColors.textMuted)),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontFamily: 'Rajdhani', fontWeight: FontWeight.w700, fontSize: 16, color: ProColors.text),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: ProColors.textMuted, size: 18),
        ],
      ),
    );
  }
}

class _MenuSectionTitle extends StatelessWidget {
  const _MenuSectionTitle({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: ProColors.textMuted),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontFamily: 'Rajdhani', fontWeight: FontWeight.w700, fontSize: 16, color: ProColors.text),
          ),
        ),
      ],
    );
  }
}

class _MenuAction {
  const _MenuAction(this.title, this.subtitle, this.icon, this.colors, this.onTap, {this.badge});

  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> colors;
  final VoidCallback onTap;
  final String? badge;
}

class _MenuBolum {
  const _MenuBolum(this.icon, this.title, this.tiles);

  final IconData icon;
  final String title;
  final List<_MenuAction> tiles;
}

const _menuBaslikStili = TextStyle(
  fontFamily: 'Rajdhani',
  fontWeight: FontWeight.w700,
  fontSize: 13,
  height: 1.05,
  color: Colors.white,
);

const _menuAltStili = TextStyle(
  fontFamily: 'Inter',
  fontSize: 10,
  height: 1.15,
  color: Color(0xF2FFFFFF),
);

double _menuMetinYuksekligi(String metin, TextStyle stil, double genislik, int satir, TextScaler olcek) {
  final painter = TextPainter(
    text: TextSpan(text: metin, style: stil),
    textDirection: TextDirection.ltr,
    maxLines: satir,
    textScaler: olcek,
    ellipsis: '…',
  )..layout(maxWidth: genislik);
  return painter.height;
}

/// Tüm menü kutuları, en uzun başlık + alt yazıya göre aynı yükseklik.
double _menuKutuYuksekligi(List<_MenuAction> tiles, double kutuGenisligi, TextScaler olcek) {
  const ust = 6.0;
  const alt = 6.0;
  const ikon = 20.0;
  const ikonAralik = 6.0;
  const satirAralik = 2.0;
  final metinGenisligi = kutuGenisligi - 14;
  var enUzun = ust + ikon + ikonAralik + satirAralik + alt;
  for (final action in tiles) {
    final baslik = _menuMetinYuksekligi(action.title, _menuBaslikStili, metinGenisligi, 2, olcek);
    final altYazi = _menuMetinYuksekligi(action.subtitle, _menuAltStili, metinGenisligi, 3, olcek);
    final toplam = ust + ikon + ikonAralik + baslik + satirAralik + altYazi + alt;
    if (toplam > enUzun) enUzun = toplam;
  }
  return enUzun.ceilToDouble() + 12;
}

class _MenuKutulari extends StatelessWidget {
  const _MenuKutulari({required this.bolumler});

  final List<_MenuBolum> bolumler;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final genislik = (constraints.maxWidth - 16) / 3;
        final yukseklik = _menuKutuYuksekligi(
          [for (final bolum in bolumler) ...bolum.tiles],
          genislik,
          MediaQuery.textScalerOf(context),
        );
        return Column(
          children: [
            for (var i = 0; i < bolumler.length; i++) ...[
              if (i > 0) const SizedBox(height: 18),
              _MenuSectionTitle(icon: bolumler[i].icon, title: bolumler[i].title),
              const SizedBox(height: 10),
              _MenuGrid(tiles: bolumler[i].tiles, yukseklik: yukseklik),
            ],
          ],
        );
      },
    );
  }
}

class _MenuGrid extends StatelessWidget {
  const _MenuGrid({required this.tiles, required this.yukseklik});

  final List<_MenuAction> tiles;
  final double yukseklik;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: yukseklik,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < tiles.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            Expanded(child: _MenuTile(action: tiles[i])),
          ],
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({required this.action});

  final _MenuAction action;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: action.onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: action.colors),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 6, 6),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(action.icon, color: Colors.white, size: 20),
                    const Spacer(),
                    if (action.badge != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                        child: Text(
                          action.badge!,
                          style: TextStyle(fontFamily: 'Inter', fontSize: 10, fontWeight: FontWeight.w700, color: action.colors.first),
                        ),
                      )
                    else
                      const Icon(Icons.chevron_right, color: Colors.white, size: 16),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  action.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: _menuBaslikStili,
                ),
                const SizedBox(height: 2),
                Text(
                  action.subtitle,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: _menuAltStili,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DemoLoadBar extends StatelessWidget {
  const _DemoLoadBar({required this.loaded, required this.onTap});

  final bool loaded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: loaded ? const Color(0xFF14532D) : const Color(0xFF1D4ED8),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        key: const Key('menu-demo-load'),
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Icon(loaded ? Icons.check_circle_outline : Icons.download_outlined, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loaded ? 'Demo yüklü' : 'Demo Yükle',
                      style: const TextStyle(fontFamily: 'Rajdhani', fontWeight: FontWeight.w700, fontSize: 18, color: Colors.white),
                    ),
                    Text(
                      loaded ? _Demo.project : 'İstanbul Residence örnek kayıtları',
                      style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: Color(0xF2FFFFFF)),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}

class _SignOutBar extends StatelessWidget {
  const _SignOutBar();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF7F1D1D),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Oturum henüz bağlı değil.')),
          );
        },
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Icon(Icons.logout, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Çıkış Yap',
                  style: TextStyle(fontFamily: 'Rajdhani', fontWeight: FontWeight.w700, fontSize: 18, color: Colors.white),
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}

BoxDecoration _cardDecoration() {
  return BoxDecoration(
    color: ProColors.surface,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: ProColors.border),
  );
}

/// Veri giriş kutuları: normalde standart kontür, odak/seçimde mavi vurgu.
BoxDecoration _girisHucreKenar({required bool odakta, double radius = 12, Color? fill}) {
  return BoxDecoration(
    color: fill ?? ProColors.surface,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(
      color: odakta ? ProColors.electricBlue : ProColors.border,
      width: odakta ? 1.25 : 1,
    ),
  );
}

class _GirisHucreOdak extends StatefulWidget {
  const _GirisHucreOdak({
    super.key,
    required this.child,
    this.focusNode,
    this.height,
    this.padding = EdgeInsets.zero,
    this.borderRadius = 12,
    this.fillColor,
    this.vurgulu,
    this.onTap,
    this.inkWell = true,
    this.baglaFocus = true,
  });

  final Widget child;
  final FocusNode? focusNode;
  final double? height;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final Color? fillColor;
  final bool? vurgulu;
  final VoidCallback? onTap;
  final bool inkWell;
  /// false when child [TextField] already owns [focusNode].
  final bool baglaFocus;

  @override
  State<_GirisHucreOdak> createState() => _GirisHucreOdakState();
}

class _GirisHucreOdakState extends State<_GirisHucreOdak> {
  late FocusNode _node;
  var _ownsNode = false;

  @override
  void initState() {
    super.initState();
    if (widget.focusNode != null) {
      _node = widget.focusNode!;
    } else {
      _node = FocusNode();
      _ownsNode = true;
    }
    _node.addListener(_yenile);
  }

  @override
  void didUpdateWidget(covariant _GirisHucreOdak oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      _node.removeListener(_yenile);
      if (_ownsNode) {
        _node.dispose();
      }
      if (widget.focusNode != null) {
        _node = widget.focusNode!;
        _ownsNode = false;
      } else {
        _node = FocusNode();
        _ownsNode = true;
      }
      _node.addListener(_yenile);
    }
  }

  void _yenile() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _node.removeListener(_yenile);
    if (_ownsNode) {
      _node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final odakta = widget.vurgulu ?? _node.hasFocus;
    final cerceve = AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      height: widget.height,
      padding: widget.padding,
      decoration: _girisHucreKenar(odakta: odakta, radius: widget.borderRadius, fill: widget.fillColor),
      child: widget.baglaFocus
          ? Focus(
              focusNode: _node,
              child: widget.child,
            )
          : widget.child,
    );
    if (!widget.inkWell) return cerceve;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          widget.onTap?.call();
          _node.requestFocus();
        },
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: cerceve,
      ),
    );
  }
}

/// Metin alanları için standart kenarlık (InputDecoration).
InputDecoration _girisMetinDekor({
  required InputDecoration base,
  double radius = 12,
}) {
  final outline = OutlineInputBorder(
    borderRadius: BorderRadius.circular(radius),
    borderSide: const BorderSide(color: ProColors.border),
  );
  final odak = OutlineInputBorder(
    borderRadius: BorderRadius.circular(radius),
    borderSide: const BorderSide(color: ProColors.electricBlue, width: 1.25),
  );
  return base.copyWith(
    enabledBorder: outline,
    focusedBorder: odak,
    border: outline,
  );
}
