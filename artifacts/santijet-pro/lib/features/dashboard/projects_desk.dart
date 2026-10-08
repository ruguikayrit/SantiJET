part of 'dashboard_screen.dart';

enum _ProjeListeSekme { aktif, tamamlanan, arsiv }

class _ProjeOzet {
  const _ProjeOzet({
    required this.ad,
    required this.sehir,
    required this.isveren,
    required this.durum,
    required this.ilerleme,
    required this.ekip,
    required this.tarih,
    required this.kalanGun,
    required this.sekme,
    required this.thumb,
  });

  final String ad;
  final String sehir;
  final String isveren;
  final String durum;
  final double ilerleme;
  final int ekip;
  final String tarih;
  final String kalanGun;
  final _ProjeListeSekme sekme;
  final List<Color> thumb;
}

class _ProjectsDesk extends StatefulWidget {
  const _ProjectsDesk();

  @override
  State<_ProjectsDesk> createState() => _ProjectsDeskState();
}

class _ProjectsDeskState extends State<_ProjectsDesk> {
  _ProjeListeSekme _sekme = _ProjeListeSekme.aktif;
  final _ara = TextEditingController();

  static const _demoProjeler = <_ProjeOzet>[
    _ProjeOzet(
      ad: 'İstanbul Residence',
      sehir: 'İstanbul',
      isveren: 'ABC Yapı A.Ş.',
      durum: 'Aktif',
      ilerleme: 0.62,
      ekip: 28,
      tarih: '01 Mar 2026',
      kalanGun: '212 gün',
      sekme: _ProjeListeSekme.aktif,
      thumb: [Color(0xFF5B7CFF), Color(0xFFE07A2F), Color(0xFF1A120C)],
    ),
    _ProjeOzet(
      ad: 'Ankara Plaza',
      sehir: 'Ankara',
      isveren: 'XYZ Mühendislik',
      durum: 'Planlama',
      ilerleme: 0.28,
      ekip: 0,
      tarih: '15 Haz 2026',
      kalanGun: '287 gün',
      sekme: _ProjeListeSekme.aktif,
      thumb: [Color(0xFF64748B), Color(0xFF334155), Color(0xFF0F172A)],
    ),
    _ProjeOzet(
      ad: 'İzmir Marina',
      sehir: 'İzmir',
      isveren: 'DEF İnşaat',
      durum: 'Teklif',
      ilerleme: 0,
      ekip: 0,
      tarih: '—',
      kalanGun: '—',
      sekme: _ProjeListeSekme.aktif,
      thumb: [Color(0xFF0EA5E9), Color(0xFF0369A1), Color(0xFF082F49)],
    ),
    _ProjeOzet(
      ad: 'Bursa Konut',
      sehir: 'Bursa',
      isveren: 'GHI Yapı',
      durum: 'Tamamlandı',
      ilerleme: 1,
      ekip: 0,
      tarih: '10 Oca 2026',
      kalanGun: '—',
      sekme: _ProjeListeSekme.tamamlanan,
      thumb: [Color(0xFF22C55E), Color(0xFF15803D), Color(0xFF14532D)],
    ),
    _ProjeOzet(
      ad: 'Antalya Otel',
      sehir: 'Antalya',
      isveren: 'JKL Turizm',
      durum: 'Tamamlandı',
      ilerleme: 1,
      ekip: 0,
      tarih: '05 Ağu 2025',
      kalanGun: '—',
      sekme: _ProjeListeSekme.tamamlanan,
      thumb: [Color(0xFFF59E0B), Color(0xFFD97706), Color(0xFF78350F)],
    ),
    _ProjeOzet(
      ad: 'Eski Fabrika',
      sehir: 'Kocaeli',
      isveren: 'MNO Sanayi',
      durum: 'Arşiv',
      ilerleme: 0.41,
      ekip: 0,
      tarih: '2019',
      kalanGun: '—',
      sekme: _ProjeListeSekme.arsiv,
      thumb: [Color(0xFF475569), Color(0xFF1E293B), Color(0xFF0F172A)],
    ),
  ];

  @override
  void dispose() {
    _ara.dispose();
    super.dispose();
  }

  int _sekmeAdet(_ProjeListeSekme sekme, bool demo) {
    if (!demo) return 0;
    return switch (sekme) {
      _ProjeListeSekme.aktif => 6,
      _ProjeListeSekme.tamamlanan => 8,
      _ProjeListeSekme.arsiv => 2,
    };
  }

  List<_ProjeOzet> _filtreli(bool demo) {
    if (!demo) return const [];
    final q = _ara.text.trim().toLowerCase();
    return _demoProjeler.where((p) {
      if (p.sekme != _sekme) return false;
      if (q.isEmpty) return true;
      return p.ad.toLowerCase().contains(q) ||
          p.sehir.toLowerCase().contains(q) ||
          p.isveren.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final demo = _DemoScope.of(context);
    final liste = _filtreli(demo);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Projeler',
                    style: TextStyle(
                      fontFamily: 'Rajdhani',
                      fontWeight: FontWeight.w700,
                      fontSize: 22,
                      height: 1.05,
                      color: ProColors.text,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Tüm projeleri görüntüleyin ve yönetin.',
                    style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: ProColors.textMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Material(
              color: ProColors.electricBlue,
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                key: const Key('project-add'),
                borderRadius: BorderRadius.circular(10),
                onTap: () => _keepInPro(context),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add, color: Colors.white, size: 18),
                      SizedBox(width: 4),
                      Text(
                        'Proje Ekle',
                        style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 13, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _ProjeSekmeler(
          sekme: _sekme,
          aktif: _sekmeAdet(_ProjeListeSekme.aktif, demo),
          tamamlanan: _sekmeAdet(_ProjeListeSekme.tamamlanan, demo),
          arsiv: _sekmeAdet(_ProjeListeSekme.arsiv, demo),
          onSec: (s) => setState(() => _sekme = s),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF121826),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF243044)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  children: [
                    const Icon(Icons.search, size: 18, color: ProColors.textMuted),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        key: const Key('project-search'),
                        controller: _ara,
                        onChanged: (_) => setState(() {}),
                        style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: ProColors.text),
                        decoration: const InputDecoration(
                          isDense: true,
                          border: InputBorder.none,
                          hintText: 'Proje ara (ad, konum, işveren...)',
                          hintStyle: TextStyle(fontFamily: 'Inter', fontSize: 13, color: ProColors.textMuted),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Material(
              color: const Color(0xFF121826),
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                key: const Key('project-filter'),
                borderRadius: BorderRadius.circular(10),
                onTap: () => _keepInPro(context),
                child: Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF243044)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.filter_list, size: 18, color: ProColors.textMuted),
                      SizedBox(width: 2),
                      Text('Filtrele', style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: ProColors.textMuted)),
                      Icon(Icons.keyboard_arrow_down, size: 16, color: ProColors.textMuted),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (liste.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 24),
            child: Text(
              'Bu listede proje yok.',
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: ProColors.textMuted),
            ),
          )
        else
          for (var i = 0; i < liste.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            _ProjeKart(proje: liste[i], onTap: () => _keepInPro(context)),
          ],
      ],
    );
  }
}

class _ProjeSekmeler extends StatelessWidget {
  const _ProjeSekmeler({
    required this.sekme,
    required this.aktif,
    required this.tamamlanan,
    required this.arsiv,
    required this.onSec,
  });

  final _ProjeListeSekme sekme;
  final int aktif;
  final int tamamlanan;
  final int arsiv;
  final ValueChanged<_ProjeListeSekme> onSec;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF121826),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF243044)),
      ),
      child: Row(
        children: [
          _ProjeSekmeChip(
            key: const Key('project-tab-aktif'),
            label: 'Aktif ($aktif)',
            selected: sekme == _ProjeListeSekme.aktif,
            onTap: () => onSec(_ProjeListeSekme.aktif),
          ),
          _ProjeSekmeChip(
            key: const Key('project-tab-tamamlanan'),
            label: 'Tamamlanan ($tamamlanan)',
            selected: sekme == _ProjeListeSekme.tamamlanan,
            onTap: () => onSec(_ProjeListeSekme.tamamlanan),
          ),
          _ProjeSekmeChip(
            key: const Key('project-tab-arsiv'),
            label: 'Arşiv ($arsiv)',
            selected: sekme == _ProjeListeSekme.arsiv,
            onTap: () => onSec(_ProjeListeSekme.arsiv),
          ),
        ],
      ),
    );
  }
}

class _ProjeSekmeChip extends StatelessWidget {
  const _ProjeSekmeChip({super.key, required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: selected ? ProColors.electricBlue : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : ProColors.textMuted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProjeKart extends StatelessWidget {
  const _ProjeKart({required this.proje, required this.onTap});

  final _ProjeOzet proje;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bar = _ProjeDurumRenk.bar(proje.durum);
    final yuzde = (proje.ilerleme * 100).round();

    return Material(
      color: const Color(0xFF121826),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 8, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 72,
                  height: 72,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: proje.thumb),
                    ),
                    child: const Center(child: Icon(Icons.apartment_rounded, color: Colors.white70, size: 28)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            proje.ad,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Rajdhani',
                              fontWeight: FontWeight.w700,
                              fontSize: 17,
                              color: ProColors.text,
                            ),
                          ),
                        ),
                        _ProjeDurumRozet(durum: proje.durum),
                      ],
                    ),
                    const SizedBox(height: 4),
                    _ProjeMetaSatir(icon: Icons.place_outlined, metin: proje.sehir),
                    const SizedBox(height: 2),
                    _ProjeMetaSatir(icon: Icons.apartment_outlined, metin: proje.isveren),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: proje.ilerleme.clamp(0, 1),
                              minHeight: 5,
                              backgroundColor: const Color(0xFF243044),
                              color: bar,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '%$yuzde',
                          style: const TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w600, color: ProColors.text),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _ProjeAltIkon(Icons.engineering_outlined, '${proje.ekip}', shrink: true),
                        ),
                        Expanded(
                          child: _ProjeAltIkon(Icons.calendar_today_outlined, proje.tarih, shrink: true),
                        ),
                        Expanded(
                          child: _ProjeAltIkon(Icons.schedule_outlined, proje.kalanGun, shrink: true),
                        ),
                        InkWell(
                          onTap: () => _keepInPro(context),
                          borderRadius: BorderRadius.circular(6),
                          child: const Padding(
                            padding: EdgeInsets.all(4),
                            child: Icon(Icons.more_horiz, size: 18, color: ProColors.textMuted),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 2),
              Padding(
                padding: const EdgeInsets.only(top: 28),
                child: Icon(Icons.chevron_right, color: ProColors.textMuted.withValues(alpha: 0.8), size: 22),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProjeMetaSatir extends StatelessWidget {
  const _ProjeMetaSatir({required this.icon, required this.metin});

  final IconData icon;
  final String metin;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 13, color: ProColors.textMuted),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            metin,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: ProColors.textMuted),
          ),
        ),
      ],
    );
  }
}

class _ProjeAltIkon extends StatelessWidget {
  const _ProjeAltIkon(this.icon, this.metin, {this.shrink = false});

  final IconData icon;
  final String metin;
  final bool shrink;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: shrink ? MainAxisSize.max : MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: ProColors.textMuted),
        const SizedBox(width: 3),
        if (shrink)
          Expanded(
            child: Text(
              metin,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: ProColors.textMuted),
            ),
          )
        else
          Text(
            metin,
            style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: ProColors.textMuted),
          ),
      ],
    );
  }
}

class _ProjeDurumRozet extends StatelessWidget {
  const _ProjeDurumRozet({required this.durum});

  final String durum;

  @override
  Widget build(BuildContext context) {
    final renk = _ProjeDurumRenk.rozet(durum);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: renk.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: renk.withValues(alpha: 0.45)),
      ),
      child: Text(
        durum,
        style: TextStyle(fontFamily: 'Inter', fontSize: 10, fontWeight: FontWeight.w600, color: renk),
      ),
    );
  }
}

abstract final class _ProjeDurumRenk {
  static Color bar(String durum) => switch (durum) {
        'Aktif' => ProColors.electricBlue,
        'Planlama' => const Color(0xFFF97316),
        'Teklif' => const Color(0xFF38BDF8),
        'Tamamlandı' => const Color(0xFF22C55E),
        _ => ProColors.textMuted,
      };

  static Color rozet(String durum) => switch (durum) {
        'Aktif' => const Color(0xFF22C55E),
        'Planlama' => const Color(0xFFF97316),
        'Teklif' => const Color(0xFF38BDF8),
        'Tamamlandı' => const Color(0xFF94A3B8),
        'Arşiv' => const Color(0xFF94A3B8),
        _ => ProColors.textMuted,
      };
}
