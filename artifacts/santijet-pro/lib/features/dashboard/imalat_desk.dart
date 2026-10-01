part of 'dashboard_screen.dart';

/// Üst özet KPI ile alttaki kategori kartları aynı yükseklikte.
const _kImalatMetrikKartYukseklik = 82.0;
const _kImalatMetrikKartPadding = EdgeInsets.symmetric(horizontal: 6, vertical: 6);

const _kImalatMetrikDegerStili = TextStyle(
  fontFamily: 'Rajdhani',
  fontWeight: FontWeight.w700,
  fontSize: 20,
  height: 1,
  color: ProColors.text,
);

Widget _imalatMetrikKartMerkez({
  required IconData icon,
  required Color iconRenk,
  required String deger,
  required String baslik,
  required TextStyle baslikStili,
}) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Icon(icon, size: 15, color: iconRenk),
      const SizedBox(height: 4),
      Text(deger, textAlign: TextAlign.center, style: _kImalatMetrikDegerStili),
      const SizedBox(height: 2),
      Text(
        baslik,
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: baslikStili,
      ),
    ],
  );
}

enum _ImalatKategori { tum, genel, beton, demir, celik }

extension on _ImalatKategori {
  String get label => switch (this) {
        _ImalatKategori.tum => 'Tümü',
        _ImalatKategori.genel => 'Genel İmalat',
        _ImalatKategori.beton => 'Beton',
        _ImalatKategori.demir => 'Demir',
        _ImalatKategori.celik => 'Çelik',
      };

  IconData get icon => switch (this) {
        _ImalatKategori.tum => Icons.description_outlined,
        _ImalatKategori.genel => Icons.construction_outlined,
        _ImalatKategori.beton => Icons.circle,
        _ImalatKategori.demir => Icons.view_week_outlined,
        _ImalatKategori.celik => Icons.precision_manufacturing_outlined,
      };

  Color get color => switch (this) {
        _ImalatKategori.tum => ProColors.electricBlue,
        _ImalatKategori.genel => const Color(0xFFEAB308),
        _ImalatKategori.beton => const Color(0xFFEF4444),
        _ImalatKategori.demir => const Color(0xFF22C55E),
        _ImalatKategori.celik => const Color(0xFF7C3AED),
      };
}

class _ImalatKayit {
  const _ImalatKayit({
    required this.baslik,
    required this.alt,
    required this.kategori,
    required this.durum,
    required this.durumRenk,
    required this.durumIcon,
    required this.metraj,
    required this.kisi,
    required this.saat,
    required this.thumb,
  });

  final String baslik;
  final String alt;
  final _ImalatKategori kategori;
  final String durum;
  final Color durumRenk;
  final IconData durumIcon;
  final String metraj;
  final String kisi;
  final String saat;
  final List<Color> thumb;
}

class _ImalatDesk extends StatefulWidget {
  const _ImalatDesk({required this.onBack, required this.onOpenKayitEkle});

  final VoidCallback onBack;
  final VoidCallback onOpenKayitEkle;

  @override
  State<_ImalatDesk> createState() => _ImalatDeskState();
}

class _ImalatDeskState extends State<_ImalatDesk> {
  static final _seciliGun = DateTime(2026, 9, 25);
  static const _haftaGunAdlari = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];

  _ImalatKategori _kategori = _ImalatKategori.tum;
  late DateTime _gun = _seciliGun;

  DateTime get _haftaBasi => _gun.subtract(Duration(days: _gun.weekday - 1));

  static const _kayitlar = <_ImalatKayit>[
    _ImalatKayit(
      baslik: 'A Blok 2. Kat Kalıp imalatı',
      alt: 'Genel İmalat · A Blok · 2. Kat',
      kategori: _ImalatKategori.genel,
      durum: 'Tamamlandı',
      durumRenk: Color(0xFF22C55E),
      durumIcon: Icons.check,
      metraj: '120 m²',
      kisi: '6 kişi',
      saat: '09:15',
      thumb: [Color(0xFF64748B), Color(0xFF334155)],
    ),
    _ImalatKayit(
      baslik: 'Temel perde beton dökümü',
      alt: 'Beton · Temel',
      kategori: _ImalatKategori.beton,
      durum: 'Devam Ediyor',
      durumRenk: Color(0xFF2563EB),
      durumIcon: Icons.play_arrow,
      metraj: '80 m³',
      kisi: '4 kişi',
      saat: '11:40',
      thumb: [Color(0xFF78716C), Color(0xFF44403C)],
    ),
    _ImalatKayit(
      baslik: 'Çelik karkas montajı',
      alt: 'Çelik · B Blok · 1. Kat',
      kategori: _ImalatKategori.celik,
      durum: 'Devam Ediyor',
      durumRenk: Color(0xFFF97316),
      durumIcon: Icons.schedule,
      metraj: '35 mt',
      kisi: '3 kişi',
      saat: '14:05',
      thumb: [Color(0xFF0EA5E9), Color(0xFF0369A1)],
    ),
  ];

  static int _kategoriAdet(_ImalatKategori k) => switch (k) {
        _ImalatKategori.tum => 3,
        _ImalatKategori.genel => 1,
        _ImalatKategori.beton => 1,
        _ImalatKategori.demir => 0,
        _ImalatKategori.celik => 1,
      };

  List<_ImalatKayit> get _filtreli {
    if (_kategori == _ImalatKategori.tum) return _kayitlar;
    return _kayitlar.where((k) => k.kategori == _kategori).toList();
  }

  @override
  Widget build(BuildContext context) {
    final liste = _filtreli;
    final gunEtiket = '${_gun.day} Eylül İmalatları';
    final alt = MediaQuery.viewPaddingOf(context).bottom;

    return ListView(
      padding: EdgeInsets.fromLTRB(16, 8, 16, 12 + alt),
      children: [
        _ModulDeskUst(
          title: 'İmalat',
          moduleIcon: Icons.bar_chart_rounded,
          moduleColor: const Color(0xFF0D9488),
          backKey: const Key('imalat-back'),
          onBack: widget.onBack,
          backLabel: 'Saha',
          trailing: IconButton(
            onPressed: () => _keepInPro(context),
            icon: const Icon(Icons.more_horiz, color: ProColors.text),
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Günlük imalat kayıtlarını hızlıca oluşturun.',
          style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: ProColors.textMuted),
        ),
        const SizedBox(height: 12),
        _ImalatTarihKart(gun: _gun, onTap: () => _keepInPro(context)),
        const SizedBox(height: 10),
        _PuantajWeekStrip(
          weekStart: _haftaBasi,
          selected: _gun,
          dayNames: _haftaGunAdlari,
          onSelect: (g) => setState(() => _gun = g),
          onPrevious: () => setState(() => _gun = _gun.subtract(const Duration(days: 7))),
          onNext: () => setState(() => _gun = _gun.add(const Duration(days: 7))),
        ),
        const SizedBox(height: 14),
        _ImalatBolumBaslik(
          baslik: gunEtiket,
          alt: 'Seçilen tarihte kaydedilen imalat verisi',
        ),
        const SizedBox(height: 10),
        const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _ImalatOzetKpi(baslik: 'İmalat kaydı', deger: '3', icon: Icons.description_outlined, renk: Color(0xFF2563EB))),
            SizedBox(width: 6),
            Expanded(child: _ImalatOzetKpi(baslik: 'İş kalemi', deger: '8', icon: Icons.view_in_ar_outlined, renk: Color(0xFF7C3AED))),
            SizedBox(width: 6),
            Expanded(child: _ImalatOzetKpi(baslik: 'Personel', deger: '34', icon: Icons.groups_outlined, renk: Color(0xFF22C55E), info: true)),
            SizedBox(width: 6),
            Expanded(child: _ImalatOzetKpi(baslik: 'Ekipman', deger: '4', icon: Icons.agriculture_outlined, renk: Color(0xFFF59E0B), info: true)),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            key: const Key('imalat-open-app'),
            style: FilledButton.styleFrom(
              backgroundColor: ProColors.electricBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: widget.onOpenKayitEkle,
            icon: const Icon(Icons.add, size: 20),
            label: const Text('İmalat Kaydı Ekle', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 15)),
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final k in _ImalatKategori.values) ...[
                _ImalatKategoriKutu(
                  kategori: k,
                  adet: _kategoriAdet(k),
                  selected: k == _kategori,
                  onTap: () => setState(() => _kategori = k),
                ),
                const SizedBox(width: 6),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            const Icon(Icons.format_list_bulleted, size: 18, color: ProColors.electricBlue),
            const SizedBox(width: 6),
            const Expanded(
              child: Text(
                'Kayıt listesi',
                style: TextStyle(fontFamily: 'Rajdhani', fontWeight: FontWeight.w700, fontSize: 16, color: ProColors.text),
              ),
            ),
            Text('${liste.length} kayıt', style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: ProColors.textMuted)),
            IconButton(
              onPressed: () => _keepInPro(context),
              icon: const Icon(Icons.tune, size: 18, color: ProColors.textMuted),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (liste.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: _cardDecoration(),
            child: const Text(
              'Bu kategoride kayıt yok.',
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: ProColors.textMuted),
            ),
          )
        else
          for (var i = 0; i < liste.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            _ImalatKayitKart(kayit: liste[i]),
          ],
        const SizedBox(height: 12),
        Material(
          color: const Color(0xFF121826),
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _keepInPro(context),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF243044)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: const Row(
                children: [
                  Icon(Icons.history, size: 22, color: Color(0xFF7C3AED)),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Geçmiş Kayıtlar', style: TextStyle(fontFamily: 'Rajdhani', fontWeight: FontWeight.w700, fontSize: 15, color: ProColors.text)),
                        Text(
                          'Farklı tarihlerdeki imalat kayıtlarını görüntüleyin.',
                          style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: ProColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: ProColors.textMuted),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ImalatTarihKart extends StatelessWidget {
  const _ImalatTarihKart({required this.gun, required this.onTap});

  final DateTime gun;
  final VoidCallback onTap;

  static const _gunAd = ['Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar'];

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF121826),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF243044)),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFF7C3AED).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.calendar_month_outlined, size: 18, color: Color(0xFFA78BFA)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${gun.day} Eylül ${gun.year} ${_gunAd[gun.weekday - 1]}',
                  style: const TextStyle(fontFamily: 'Rajdhani', fontWeight: FontWeight.w700, fontSize: 16, color: ProColors.text),
                ),
              ),
              const Icon(Icons.keyboard_arrow_down, color: ProColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImalatBolumBaslik extends StatelessWidget {
  const _ImalatBolumBaslik({required this.baslik, required this.alt});

  final String baslik;
  final String alt;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(width: 3, height: 36, decoration: BoxDecoration(color: const Color(0xFF0D9488), borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(baslik, style: const TextStyle(fontFamily: 'Rajdhani', fontWeight: FontWeight.w700, fontSize: 16, color: ProColors.text)),
              Text(alt, style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: ProColors.textMuted)),
            ],
          ),
        ),
      ],
    );
  }
}

class _ImalatOzetKpi extends StatelessWidget {
  const _ImalatOzetKpi({required this.baslik, required this.deger, required this.icon, required this.renk, this.info = false});

  final String baslik;
  final String deger;
  final IconData icon;
  final Color renk;
  final bool info;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _kImalatMetrikKartYukseklik,
      child: Container(
        padding: _kImalatMetrikKartPadding,
        decoration: BoxDecoration(
          color: const Color(0xFF121826),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF243044)),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: _imalatMetrikKartMerkez(
                  icon: icon,
                  iconRenk: renk,
                  deger: deger,
                  baslik: baslik,
                  baslikStili: const TextStyle(fontFamily: 'Inter', fontSize: 10, height: 1.1, color: ProColors.textMuted),
                ),
              ),
            ),
            if (info)
              const Positioned(
                top: 0,
                right: 0,
                child: Icon(Icons.info_outline, size: 13, color: ProColors.textMuted),
              ),
          ],
        ),
      ),
    );
  }
}

class _ImalatKategoriKutu extends StatelessWidget {
  const _ImalatKategoriKutu({required this.kategori, required this.adet, required this.selected, required this.onTap});

  final _ImalatKategori kategori;
  final int adet;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 84,
      height: _kImalatMetrikKartYukseklik,
      child: Material(
        color: const Color(0xFF121826),
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: _kImalatMetrikKartPadding,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: selected ? kategori.color : const Color(0xFF243044), width: selected ? 1.5 : 1),
            ),
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: _imalatMetrikKartMerkez(
                  icon: kategori.icon,
                  iconRenk: kategori.color,
                  deger: '$adet',
                  baslik: kategori.label,
                  baslikStili: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10,
                    height: 1.1,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    color: selected ? ProColors.text : ProColors.textMuted,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ImalatKayitKart extends StatelessWidget {
  const _ImalatKayitKart({required this.kayit});

  final _ImalatKayit kayit;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF121826),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _keepInPro(context),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF243044)),
          ),
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 72,
                  height: 72,
                  child: DecoratedBox(
                    decoration: BoxDecoration(gradient: LinearGradient(colors: kayit.thumb)),
                    child: const Icon(Icons.photo_outlined, color: Colors.white54, size: 22),
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
                            kayit.baslik,
                            style: const TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600, color: ProColors.text),
                          ),
                        ),
                        _ImalatDurumRozet(kayit: kayit),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(kayit.alt, style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: ProColors.textMuted)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.straighten, size: 13, color: ProColors.textMuted),
                        const SizedBox(width: 3),
                        Text(kayit.metraj, style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: ProColors.textMuted)),
                        const SizedBox(width: 8),
                        const Icon(Icons.groups_outlined, size: 13, color: ProColors.textMuted),
                        const SizedBox(width: 3),
                        Flexible(child: Text(kayit.kisi, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: ProColors.textMuted))),
                        const SizedBox(width: 8),
                        const Icon(Icons.schedule, size: 13, color: ProColors.textMuted),
                        const SizedBox(width: 3),
                        Text(kayit.saat, style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: ProColors.textMuted)),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  const Icon(Icons.chevron_right, size: 18, color: ProColors.textMuted),
                  IconButton(
                    onPressed: () => _keepInPro(context),
                    icon: const Icon(Icons.more_vert, size: 18, color: ProColors.textMuted),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImalatDurumRozet extends StatelessWidget {
  const _ImalatDurumRozet({required this.kayit});

  final _ImalatKayit kayit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: kayit.durumRenk.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: kayit.durumRenk.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(kayit.durumIcon, size: 10, color: kayit.durumRenk),
          const SizedBox(width: 2),
          Text(kayit.durum, style: TextStyle(fontFamily: 'Inter', fontSize: 10, fontWeight: FontWeight.w600, color: kayit.durumRenk)),
        ],
      ),
    );
  }
}
