import 'package:flutter/material.dart';

import '../../core/theme/pro_theme.dart';

part 'reports_desk.dart';
part 'saha_desk.dart';
part 'saha_turu_desk.dart';
part 'yeni_saha_turu_desk.dart';
part 'gorev_ozet_desk.dart';
part 'puantaj_desk.dart';
part 'personel_desk.dart';
part 'gorevler_desk.dart';
part 'imalat_desk.dart';
part 'makine_desk.dart';
part 'malzeme_desk.dart';

class _DemoScope extends InheritedWidget {
  const _DemoScope({required this.loaded, required super.child});

  final bool loaded;

  static bool of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_DemoScope>()?.loaded ?? false;
  }

  @override
  bool updateShouldNotify(_DemoScope oldWidget) => loaded != oldWidget.loaded;
}

abstract final class _Demo {
  static const project = 'İstanbul Residence';
  static const place = 'İstanbul';
  static const span = '01 Mar – 30 Ara 2026';
  static const note = 'A Blok · şantiye açık';
  static const metraj = '%62';
  static const sure = '212 gün';
  static const adamGun = '4.180';
  static const verim = ['%71', '%54', '%38'];
  static const butce = '128 M₺';
  static const maliyet = '74 M₺';
  static const kasa = '6,4 M₺';
  static const hakedis = '61 M₺';
  static const beton = ['4.800 m³', '42 m³', '2.960 m³', '%62'];
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

enum _Desk { home, modules, saha, sahaTuru, yeniSahaTuru, puantaj, personel, gorevler, imalat, makine, malzeme, projects, reports, menu }

class _DashboardScreenState extends State<DashboardScreen> {
  _Desk _desk = _Desk.home;
  var _demo = false;

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
          child: switch (_desk) {
          _Desk.home => _HomeDesk(onOpenSaha: () => setState(() => _desk = _Desk.saha)),
          _Desk.modules => _ModulesDesk(onOpenSaha: () => setState(() => _desk = _Desk.saha)),
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
          _Desk.imalat => _ImalatDesk(onBack: () => setState(() => _desk = _Desk.saha)),
          _Desk.makine => _MakineDesk(onBack: () => setState(() => _desk = _Desk.saha)),
          _Desk.malzeme => _MalzemeDesk(onBack: () => setState(() => _desk = _Desk.saha)),
          _Desk.projects => _PlainDesk(
              title: 'Projeler',
              body: _demo ? 'Aktif proje: İstanbul Residence' : 'Ortak proje kaydı henüz bir uygulamaya bağlanmadı.',
            ),
          _Desk.reports => const _ReportsDesk(),
          _Desk.menu => _MenuDesk(
              demoLoaded: _demo,
              onSelect: (desk) => setState(() => _desk = desk),
              onLoadDemo: _loadDemo,
            ),
        },
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
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        const _TopBar(),
        const SizedBox(height: 14),
        const _ProjectHero(),
        const SizedBox(height: 12),
        _SahaProgress(onOpen: onOpenSaha),
        const SizedBox(height: 10),
        _VerimKpi(onOpenSaha: onOpenSaha),
        const SizedBox(height: 10),
        const _FinanceRow(),
        const SizedBox(height: 10),
        const _SourceKpis(),
      ],
    );
  }
}

class _ModulesDesk extends StatelessWidget {
  const _ModulesDesk({required this.onOpenSaha});

  final VoidCallback onOpenSaha;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        const _TopBar(),
        const SizedBox(height: 18),
        const _ModuleHeader(),
        const SizedBox(height: 12),
        _ModuleGrid(onOpenSaha: onOpenSaha),
      ],
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({this.alertCount = 0});

  final int alertCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Image.asset('assets/images/splash_bolt.png', height: 26),
        const SizedBox(width: 8),
        Image.asset('assets/images/splash_wordmark.png', height: 18),
        const SizedBox(width: 6),
        const Text(
          'PRO',
          style: TextStyle(
            fontFamily: 'Rajdhani',
            fontWeight: FontWeight.w700,
            fontSize: 18,
            letterSpacing: 1.1,
            color: ProColors.electricBlue,
          ),
        ),
        const Spacer(),
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

class _ProjectHero extends StatelessWidget {
  const _ProjectHero();

  @override
  Widget build(BuildContext context) {
    final demo = _DemoScope.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        height: 128,
        child: Row(
          children: [
            Expanded(
              child: ColoredBox(
                color: const Color(0xFF10243F),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                      const SizedBox(height: 2),
                      Text(
                        demo ? _Demo.project : 'Henüz proje yok',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Rajdhani',
                          fontWeight: FontWeight.w700,
                          fontSize: 22,
                          color: ProColors.text,
                        ),
                      ),
                      Text(
                        demo ? _Demo.note : 'KPI değerleri proje bağlanınca dolacak',
                        maxLines: 2,
                        style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: ProColors.textMuted),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          const Icon(Icons.place_outlined, size: 14, color: ProColors.textMuted),
                          const SizedBox(width: 4),
                          Text(demo ? _Demo.place : '—', style: const TextStyle(color: ProColors.text, fontSize: 12)),
                          const SizedBox(width: 12),
                          const Icon(Icons.calendar_today_outlined, size: 13, color: ProColors.textMuted),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              demo ? _Demo.span : '—',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: ProColors.text, fontSize: 12),
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
              width: 108,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF5B7CFF), Color(0xFFE07A2F), Color(0xFF1A120C)],
                  ),
                ),
                child: Center(
                  child: Icon(Icons.apartment_rounded, color: Colors.white, size: 36),
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
        const Text(
          'Verim özeti',
          style: TextStyle(
            fontFamily: 'Rajdhani',
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: ProColors.text,
          ),
        ),
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
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(fontFamily: 'Rajdhani', fontWeight: FontWeight.w700, fontSize: 22, color: ProColors.text),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(fontFamily: 'Rajdhani', fontWeight: FontWeight.w700, fontSize: 12, letterSpacing: 0.4, color: color),
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
              _Ring(label: 'Metraj', value: _DemoScope.of(context) ? _Demo.metraj : '—'),
              const SizedBox(width: 14),
              Expanded(
                child: Row(
                  children: [
                    Expanded(child: _MetricColumn(label: 'Süre', value: _DemoScope.of(context) ? _Demo.sure : '—')),
                    const SizedBox(width: 12),
                    Expanded(child: _MetricColumn(label: 'Adam-gün', value: _DemoScope.of(context) ? _Demo.adamGun : '—')),
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
  const _Ring({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 92,
      height: 92,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: ProColors.electricBlue, width: 7),
        ),
        child: Column(
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
      ),
    );
  }
}

class _MetricColumn extends StatelessWidget {
  const _MetricColumn({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: ProColors.textMuted)),
        Text(
          value,
          style: const TextStyle(fontFamily: 'Rajdhani', fontWeight: FontWeight.w700, fontSize: 22, color: ProColors.text),
        ),
        const SizedBox(height: 8),
        const SizedBox(
          height: 6,
          width: double.infinity,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Color(0xFF163322),
              borderRadius: BorderRadius.all(Radius.circular(6)),
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
                foot: 'Planlanan maliyet',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _FinanceTile(
                title: 'Maliyet',
                value: demo ? _Demo.maliyet : empty,
                icon: Icons.payments_outlined,
                colors: const [Color(0xFFF97316), Color(0xFFEA580C)],
                foot: 'Yaklaşık maliyet',
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
                foot: 'Güncel kasa',
                detail: 'Toplam gelir',
                extra: 'Toplam gider',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _FinanceTile(
                title: 'Hakediş',
                value: demo ? _Demo.hakedis : empty,
                icon: Icons.description_outlined,
                colors: const [Color(0xFFE11D48), Color(0xFFBE123C)],
                foot: 'İşveren hakedişi',
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
    required this.foot,
    this.detail,
    this.extra,
  });

  final String title;
  final String value;
  final IconData icon;
  final List<Color> colors;
  final String foot;
  final String? detail;
  final String? extra;

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
          Text(
            foot,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: Color(0xF2FFFFFF)),
          ),
          if (detail != null)
            Text(
              detail!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: Color(0xCCFFFFFF)),
            ),
          if (extra != null)
            Text(
              extra!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: Color(0xCCFFFFFF)),
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
            Expanded(child: _SourceCell(title: 'Beton', lines: const ['Planlanan döküm', 'Bugünkü döküm', 'Gerçekleşen döküm', 'Keşif ilerlemesi'], values: demo ? _Demo.beton : dash)),
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


class _ModuleHeader extends StatelessWidget {
  const _ModuleHeader();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Icon(Icons.grid_view_rounded, size: 16, color: ProColors.textMuted),
        SizedBox(width: 6),
        Text(
          'MODÜLLER',
          style: TextStyle(
            fontFamily: 'Rajdhani',
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
            color: ProColors.textMuted,
          ),
        ),
        Spacer(),
        Text(
          'Tüm Modüller',
          style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: ProColors.textMuted),
        ),
        Icon(Icons.chevron_right, size: 16, color: ProColors.textMuted),
      ],
    );
  }
}

class _ModuleGrid extends StatelessWidget {
  const _ModuleGrid({this.onOpenSaha});

  final VoidCallback? onOpenSaha;

  static const tiles = <_ModuleTile>[
    _ModuleTile('Saha', 'Puantaj, günlük rapor, imalat', 'saha', Color(0xFF1D4ED8), Icons.groups_outlined),
    _ModuleTile('Genel İmalatlar', 'Tüm iş kalemleri', null, Color(0xFFEA580C), Icons.construction_outlined),
    _ModuleTile('Beton', 'Keşif, sipariş, döküm, test', 'beton', Color(0xFFE11D48), Icons.foundation_outlined),
    _ModuleTile('Demir', 'Sipariş, kesim, montaj', 'demir', Color(0xFF0F766E), Icons.view_week_outlined),
    _ModuleTile('Çelik', 'Atölye, sevkiyat, montaj', null, Color(0xFF7C3AED), Icons.precision_manufacturing_outlined),
    _ModuleTile('Malzeme', 'Talep, sipariş, stok, tüketim', 'malzeme', Color(0xFFEAB308), Icons.inventory_2_outlined),
    _ModuleTile('Satın Alma', 'Tedarikçi, sipariş, irsaliye', null, Color(0xFF16A34A), Icons.shopping_cart_outlined),
    _ModuleTile('İş Programı', 'Gantt, plan, gerçekleşme', 'is-programi', Color(0xFF0284C7), Icons.calendar_month_outlined),
    _ModuleTile('Bütçe', 'Planlanan maliyet ve sapma', null, Color(0xFFDB2777), Icons.pie_chart_outline),
    _ModuleTile('Maliyet', 'Keşif, metraj, yaklaşık maliyet', 'maliyet', Color(0xFFF59E0B), Icons.show_chart),
    _ModuleTile('Kasa', 'Ödeme, tahsilat, banka', 'kasa', Color(0xFF4338CA), Icons.account_balance_wallet_outlined),
    _ModuleTile('Hakediş', 'İşveren ve taşeron hakedişi', null, Color(0xFFDC2626), Icons.description_outlined),
    _ModuleTile('Tahvil', 'Saha, temel, kolon, kiriş, döşeme', 'tahvil', Color(0xFFC2410C), Icons.calculate_outlined),
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
      itemBuilder: (context, index) => _ModuleCard(tile: tiles[index], onOpenSaha: onOpenSaha),
    );
  }
}

class _ModuleTile {
  const _ModuleTile(this.title, this.subtitle, this.moduleId, this.color, this.icon);

  final String title;
  final String subtitle;
  final String? moduleId;
  final Color color;
  final IconData icon;
}

class _ModuleCard extends StatelessWidget {
  const _ModuleCard({required this.tile, this.onOpenSaha});

  final _ModuleTile tile;
  final VoidCallback? onOpenSaha;

  @override
  Widget build(BuildContext context) {
    final darker = Color.lerp(tile.color, Colors.black, 0.18)!;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        key: tile.moduleId == null ? null : Key('module-${tile.moduleId}'),
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          final id = tile.moduleId;
          if (id == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${tile.title} daha sonra eklenecek.')),
            );
            return;
          }
          if (id == 'saha' && onOpenSaha != null) {
            onOpenSaha!();
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
              _NavItem(icon: Icons.bar_chart_outlined, label: 'Raporlar', selected: desk == _Desk.reports, onTap: () => onSelect(_Desk.reports)),
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
        const _TopBar(alertCount: 3),
        const SizedBox(height: 14),
        const _AccountCard(),
        const SizedBox(height: 10),
        const _AccountMetaRow(),
        const SizedBox(height: 18),
        const _MenuSectionTitle(icon: Icons.grid_view_rounded, title: 'Proje Yönetimi'),
        const SizedBox(height: 10),
        _MenuGrid(
          tiles: [
            _MenuAction('Proje Seç', 'Aktif projeyi değiştir', Icons.apartment_outlined, const [Color(0xFF2563EB), Color(0xFF1D4ED8)], () => onSelect(_Desk.projects)),
            _MenuAction('Ekip Yönetimi', 'Ekip üyelerini yönet', Icons.groups_outlined, const [Color(0xFF7C3AED), Color(0xFF6D28D9)], () => _later(context, 'Ekip Yönetimi')),
            _MenuAction('Firma ve Şantiyeler', 'Firma, şantiye ve ayarlar', Icons.domain_outlined, const [Color(0xFFF97316), Color(0xFFEA580C)], () => _later(context, 'Firma ve Şantiyeler')),
          ],
        ),
        const SizedBox(height: 18),
        const _MenuSectionTitle(icon: Icons.bar_chart_rounded, title: 'Veri ve Raporlar'),
        const SizedBox(height: 10),
        _MenuGrid(
          tiles: [
            _MenuAction('Veri Senkronizasyonu', 'Bulut ile senkronize et', Icons.cloud_upload_outlined, const [Color(0xFF10B981), Color(0xFF059669)], () => _later(context, 'Veri Senkronizasyonu')),
            _MenuAction('Raporlar', 'Tüm raporları görüntüle', Icons.description_outlined, const [Color(0xFF2563EB), Color(0xFF1E40AF)], () => onSelect(_Desk.reports)),
            _MenuAction('İş Programı', 'Plan, takip, gerçekleşme', Icons.calendar_month_outlined, const [Color(0xFF0891B2), Color(0xFF0E7490)], () => _keepInPro(context)),
          ],
        ),
        const SizedBox(height: 18),
        const _MenuSectionTitle(icon: Icons.settings_outlined, title: 'Ayarlar ve Güvenlik'),
        const SizedBox(height: 10),
        _MenuGrid(
          tiles: [
            _MenuAction('Bildirimler', 'Bildirim ayarlarını düzenle', Icons.notifications_none, const [Color(0xFFEF4444), Color(0xFFDC2626)], () => _later(context, 'Bildirimler'), badge: '3'),
            _MenuAction('Güvenlik ve Gizlilik', 'Şifre, biyometrik giriş, veri güvenliği', Icons.verified_user_outlined, const [Color(0xFFF97316), Color(0xFFEA580C)], () => _later(context, 'Güvenlik ve Gizlilik')),
            _MenuAction('Görünüm', 'Tema, dil ve ekran ayarları', Icons.palette_outlined, const [Color(0xFF7C3AED), Color(0xFF6D28D9)], () => _later(context, 'Görünüm')),
          ],
        ),
        const SizedBox(height: 18),
        const _MenuSectionTitle(icon: Icons.help_outline, title: 'Destek ve Bilgilendirme'),
        const SizedBox(height: 10),
        _MenuGrid(
          tiles: [
            _MenuAction('Yardım & Destek', 'Sık sorulan sorular, destek talebi', Icons.chat_bubble_outline, const [Color(0xFF06B6D4), Color(0xFF0891B2)], () => _later(context, 'Yardım & Destek')),
            _MenuAction('Kullanım Kılavuzu', 'Video eğitimler ve rehberler', Icons.school_outlined, const [Color(0xFFEF4444), Color(0xFFB91C1C)], () => _later(context, 'Kullanım Kılavuzu')),
            _MenuAction('Uygulama Hakkında', 'Sürüm 0.1.0 (PRO)', Icons.info_outline, const [Color(0xFF14B8A6), Color(0xFF0F766E)], () => _later(context, 'Uygulama Hakkında')),
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

class _MenuGrid extends StatelessWidget {
  const _MenuGrid({required this.tiles});

  final List<_MenuAction> tiles;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: tiles.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        mainAxisExtent: 124,
      ),
      itemBuilder: (context, index) => _MenuTile(action: tiles[index]),
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
            padding: const EdgeInsets.fromLTRB(8, 8, 6, 8),
            child: Column(
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
                const SizedBox(height: 8),
                Text(
                  action.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontFamily: 'Rajdhani', fontWeight: FontWeight.w700, fontSize: 13, height: 1.05, color: Colors.white),
                ),
                const SizedBox(height: 2),
                Text(
                  action.subtitle,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontFamily: 'Inter', fontSize: 10, height: 1.15, color: Color(0xF2FFFFFF)),
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
