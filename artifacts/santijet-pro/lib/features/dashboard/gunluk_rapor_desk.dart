part of 'dashboard_screen.dart';

class _GunlukRaporDesk extends StatefulWidget {
  const _GunlukRaporDesk({required this.onBack});

  final VoidCallback onBack;

  @override
  State<_GunlukRaporDesk> createState() => _GunlukRaporDeskState();
}

class _GunlukRaporDeskState extends State<_GunlukRaporDesk> {
  var _gecikmeVar = false;

  @override
  Widget build(BuildContext context) {
    final demo = _DemoScope.of(context);
    final alt = MediaQuery.viewPaddingOf(context).bottom;

    return ListView(
      padding: EdgeInsets.fromLTRB(16, 8, 16, 12 + alt),
      children: [
        _ModulDeskUst(
          title: 'Günlük Rapor',
          moduleIcon: Icons.event_note_outlined,
          moduleColor: const Color(0xFF2563EB),
          backKey: const Key('gunluk-rapor-back'),
          onBack: widget.onBack,
          backLabel: 'Raporlar',
          trailing: Material(
            color: const Color(0xFF121826),
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              key: const Key('gunluk-rapor-taslak'),
              borderRadius: BorderRadius.circular(8),
              onTap: () => _keepInPro(context),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.description_outlined, size: 16, color: ProColors.textMuted),
                    SizedBox(width: 4),
                    Text('Taslaklar', style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: ProColors.textMuted)),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Şantiye durumunu tek ekranda takip edin.',
          style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: ProColors.textMuted),
        ),
        const SizedBox(height: 12),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _GrProjeKart(demo: demo)),
              const SizedBox(width: 8),
              const Expanded(child: _GrTarihKart()),
            ],
          ),
        ),
        const SizedBox(height: 10),
        const _GrHavaKart(),
        const SizedBox(height: 10),
        const IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _GrSayiKart(icon: Icons.groups_outlined, baslik: 'Saha Personeli', sol: '28', sag: '34', alt: 'Aktif / Toplam')),
              SizedBox(width: 8),
              Expanded(child: _GrSayiKart(icon: Icons.agriculture_outlined, baslik: 'Ekipman', sol: '6', sag: '8', alt: 'Aktif / Toplam')),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const _GrIlerlemeBaslik(),
        const SizedBox(height: 10),
        const _GrIlerlemeGovde(),
        const SizedBox(height: 14),
        _GrBolumBaslik(
          baslik: 'Yapılan İmalatlar',
          sag: Material(
            color: ProColors.electricBlue,
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              key: const Key('gunluk-rapor-is-ekle'),
              borderRadius: BorderRadius.circular(8),
              onTap: () => _keepInPro(context),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add, size: 16, color: Colors.white),
                    SizedBox(width: 4),
                    Text('İş Ekle', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 12, color: Colors.white)),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        const _GrImalatSatir(
          icon: Icons.check_circle,
          iconColor: Color(0xFF22C55E),
          baslik: 'A Blok 2. Kat kalıp imalatı',
          alt: 'Kalıp · A Blok · 2. Kat',
          miktar: '120 m²',
        ),
        const SizedBox(height: 6),
        const _GrImalatSatir(
          icon: Icons.radio_button_checked,
          iconColor: Color(0xFF2563EB),
          baslik: 'Temel perde beton dökümü',
          alt: 'Beton · Temel',
          miktar: '80 m³',
        ),
        const SizedBox(height: 6),
        const _GrImalatSatir(
          icon: Icons.pause_circle_filled,
          iconColor: Color(0xFFF59E0B),
          baslik: 'Elektrik kablo tavası montajı',
          alt: 'Elektrik · B Blok · 1. Kat',
          miktar: '35 mt',
        ),
        const SizedBox(height: 14),
        _GrBolumBaslik(
          baslik: 'Saha Fotoğrafları',
          sag: const Text('4 fotoğraf  ›', style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: ProColors.textMuted)),
        ),
        const SizedBox(height: 8),
        const _GrFotoSerit(),
        const SizedBox(height: 14),
        _GrBolumBaslik(
          baslik: 'Malzeme / Teslimatlar',
          sag: const Text('Bugün 3 kalem  ›', style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: ProColors.textMuted)),
        ),
        const SizedBox(height: 8),
        const _GrMalzemeSerit(),
        const SizedBox(height: 14),
        _GrBolumBaslik(
          baslik: 'Kontrol / Denetim',
          sag: const Text('Bugün 2 kontrol  ›', style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: ProColors.textMuted)),
        ),
        const SizedBox(height: 8),
        const Row(
          children: [
            Expanded(
              child: _GrKontrolKart(
                baslik: 'İşveren kontrolü',
                alt: 'A Blok 2. Kat kalıp',
                durum: 'Tamamlandı',
                saat: '10:30',
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: _GrKontrolKart(
                baslik: 'Beton numune alımı',
                alt: 'Temel perde betonu',
                durum: 'Tamamlandı',
                saat: '14:15',
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _GrBolumBaslik(
          baslik: 'İSG Durumu',
          sag: const Icon(Icons.chevron_right, size: 18, color: ProColors.textMuted),
        ),
        const SizedBox(height: 8),
        const _GrIsgGrid(),
        const SizedBox(height: 14),
        Row(
          children: [
            const Icon(Icons.warning_amber_rounded, size: 18, color: Color(0xFFEF4444)),
            const SizedBox(width: 6),
            const Expanded(
              child: Text(
                'Gecikmeler / Engeller',
                style: TextStyle(fontFamily: 'Rajdhani', fontWeight: FontWeight.w700, fontSize: 16, color: ProColors.text),
              ),
            ),
            _GrGecikmeSecim(
              gecikmeVar: _gecikmeVar,
              onYok: () => setState(() => _gecikmeVar = false),
              onVar: () => setState(() => _gecikmeVar = true),
            ),
          ],
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          key: const Key('gunluk-rapor-kaydet'),
          style: FilledButton.styleFrom(
            backgroundColor: ProColors.electricBlue,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () => _keepInPro(context),
          icon: const Icon(Icons.check, size: 20),
          label: const Text('Raporu Kaydet', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 15)),
        ),
      ],
    );
  }
}

class _GrKart extends StatelessWidget {
  const _GrKart({required this.child, this.padding = const EdgeInsets.all(10)});

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: const Color(0xFF121826),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF243044)),
      ),
      child: child,
    );
  }
}

class _GrProjeKart extends StatelessWidget {
  const _GrProjeKart({required this.demo});

  final bool demo;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _keepInPro(context),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF243044)),
          ),
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: const SizedBox(
                  width: 52,
                  height: 52,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF5B7CFF), Color(0xFFE07A2F), Color(0xFF1A120C)],
                      ),
                    ),
                    child: Icon(Icons.apartment_rounded, color: Colors.white70, size: 22),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      demo ? _Demo.project : 'Proje seçin',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontFamily: 'Rajdhani', fontWeight: FontWeight.w700, fontSize: 15, color: ProColors.text),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.place_outlined, size: 12, color: ProColors.textMuted),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            demo ? 'İstanbul / Kadıköy' : '—',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontFamily: 'Inter', fontSize: 10, color: ProColors.textMuted),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(Icons.apartment_outlined, size: 12, color: ProColors.textMuted),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            demo ? 'ABC Yapı A.Ş.' : '—',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontFamily: 'Inter', fontSize: 10, color: ProColors.textMuted),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, size: 18, color: ProColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class _GrTarihKart extends StatelessWidget {
  const _GrTarihKart();

  @override
  Widget build(BuildContext context) {
    return _GrKart(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Rapor Tarihi', style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: ProColors.textMuted)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF0B1018),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF243044)),
            ),
            child: const Row(
              children: [
                Icon(Icons.calendar_today_outlined, size: 16, color: ProColors.textMuted),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '25.09.2026',
                    style: TextStyle(fontFamily: 'Rajdhani', fontWeight: FontWeight.w700, fontSize: 16, color: ProColors.text),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          const Text('Perşembe', style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: ProColors.textMuted)),
        ],
      ),
    );
  }
}

class _GrHavaKart extends StatelessWidget {
  const _GrHavaKart();

  @override
  Widget build(BuildContext context) {
    return _GrKart(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Hava Durumu', style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: ProColors.textMuted)),
          const SizedBox(height: 8),
          Row(
            children: const [
              Expanded(child: _GrHavaHucre(icon: Icons.wb_sunny_outlined, baslik: 'Açık', alt: '26° / 18°')),
              Expanded(child: _GrHavaHucre(icon: Icons.air, baslik: 'Rüzgar', alt: '12 km/sa')),
              Expanded(child: _GrHavaHucre(icon: Icons.water_drop_outlined, baslik: 'Nem', alt: '%52')),
            ],
          ),
        ],
      ),
    );
  }
}

class _GrHavaHucre extends StatelessWidget {
  const _GrHavaHucre({required this.icon, required this.baslik, required this.alt});

  final IconData icon;
  final String baslik;
  final String alt;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFFF59E0B)),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(baslik, style: const TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w600, color: ProColors.text)),
              Text(alt, style: const TextStyle(fontFamily: 'Inter', fontSize: 10, color: ProColors.textMuted)),
            ],
          ),
        ),
      ],
    );
  }
}

class _GrSayiKart extends StatelessWidget {
  const _GrSayiKart({required this.icon, required this.baslik, required this.sol, required this.sag, required this.alt});

  final IconData icon;
  final String baslik;
  final String sol;
  final String sag;
  final String alt;

  @override
  Widget build(BuildContext context) {
    return _GrKart(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: ProColors.textMuted),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  baslik,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: ProColors.textMuted),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              style: const TextStyle(fontFamily: 'Rajdhani', fontWeight: FontWeight.w700, fontSize: 22, color: ProColors.text),
              children: [
                TextSpan(text: sol),
                const TextSpan(text: ' / ', style: TextStyle(color: ProColors.textMuted, fontSize: 18)),
                TextSpan(text: sag, style: const TextStyle(color: ProColors.textMuted, fontSize: 18)),
              ],
            ),
          ),
          Text(alt, style: const TextStyle(fontFamily: 'Inter', fontSize: 10, color: ProColors.textMuted)),
        ],
      ),
    );
  }
}

class _GrIlerlemeBaslik extends StatelessWidget {
  const _GrIlerlemeBaslik();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Text('Günlük İlerleme', style: TextStyle(fontFamily: 'Rajdhani', fontWeight: FontWeight.w700, fontSize: 16, color: ProColors.text)),
        SizedBox(width: 4),
        Icon(Icons.info_outline, size: 14, color: ProColors.textMuted),
        Spacer(),
        Flexible(
          child: Text(
            'Toplam Planlanan: 8 iş kalemi',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
            style: TextStyle(fontFamily: 'Inter', fontSize: 10, color: ProColors.textMuted),
          ),
        ),
      ],
    );
  }
}

class _GrIlerlemeGovde extends StatelessWidget {
  const _GrIlerlemeGovde();

  @override
  Widget build(BuildContext context) {
    return _GrKart(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      child: Row(
        children: [
          const SizedBox(
            width: 96,
            height: 96,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 96,
                  height: 96,
                  child: CircularProgressIndicator(
                    value: 0.68,
                    strokeWidth: 8,
                    backgroundColor: Color(0xFF243044),
                    color: Color(0xFF2563EB),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('%68', style: TextStyle(fontFamily: 'Rajdhani', fontWeight: FontWeight.w700, fontSize: 20, color: ProColors.text)),
                    Text('Günlük plan\ngerçekleşme', textAlign: TextAlign.center, style: TextStyle(fontFamily: 'Inter', fontSize: 8, color: ProColors.textMuted)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              children: [
                _GrDurumCubuk(icon: Icons.check_circle, renk: Color(0xFF22C55E), etiket: '3 Tamamlandı', oran: 0.38),
                SizedBox(height: 8),
                _GrDurumCubuk(icon: Icons.play_circle_fill, renk: Color(0xFF2563EB), etiket: '4 Devam Ediyor', oran: 0.50),
                SizedBox(height: 8),
                _GrDurumCubuk(icon: Icons.schedule, renk: Color(0xFFF97316), etiket: '1 Ertelendi', oran: 0.12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GrDurumCubuk extends StatelessWidget {
  const _GrDurumCubuk({required this.icon, required this.renk, required this.etiket, required this.oran});

  final IconData icon;
  final Color renk;
  final String etiket;
  final double oran;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: renk),
            const SizedBox(width: 4),
            Expanded(
              child: Text(etiket, style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: ProColors.text)),
            ),
            Text('${(oran * 100).round()}%', style: const TextStyle(fontFamily: 'Inter', fontSize: 10, color: ProColors.textMuted)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(value: oran, minHeight: 4, backgroundColor: Color(0xFF243044), color: renk),
        ),
      ],
    );
  }
}

class _GrBolumBaslik extends StatelessWidget {
  const _GrBolumBaslik({required this.baslik, this.sag});

  final String baslik;
  final Widget? sag;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            baslik,
            style: const TextStyle(fontFamily: 'Rajdhani', fontWeight: FontWeight.w700, fontSize: 16, color: ProColors.text),
          ),
        ),
        if (sag != null) sag!,
      ],
    );
  }
}

class _GrImalatSatir extends StatelessWidget {
  const _GrImalatSatir({
    required this.icon,
    required this.iconColor,
    required this.baslik,
    required this.alt,
    required this.miktar,
  });

  final IconData icon;
  final Color iconColor;
  final String baslik;
  final String alt;
  final String miktar;

  @override
  Widget build(BuildContext context) {
    return _GrKart(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: iconColor),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  baslik,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600, color: ProColors.text),
                ),
                Text(alt, style: const TextStyle(fontFamily: 'Inter', fontSize: 10, color: ProColors.textMuted)),
              ],
            ),
          ),
          Text(miktar, style: const TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w600, color: ProColors.text)),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right, size: 16, color: ProColors.textMuted),
        ],
      ),
    );
  }
}

class _GrFotoSerit extends StatelessWidget {
  const _GrFotoSerit();

  static const _renkler = [
    [Color(0xFF64748B), Color(0xFF334155)],
    [Color(0xFF78716C), Color(0xFF44403C)],
    [Color(0xFF0EA5E9), Color(0xFF0369A1)],
    [Color(0xFF22C55E), Color(0xFF15803D)],
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (final renk in _renkler) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 72,
                height: 64,
                child: DecoratedBox(
                  decoration: BoxDecoration(gradient: LinearGradient(colors: renk)),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _keepInPro(context),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 72,
                height: 64,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF243044), style: BorderStyle.solid),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_photo_alternate_outlined, size: 18, color: ProColors.textMuted),
                    SizedBox(height: 2),
                    Text('+ Fotoğraf\nEkle', textAlign: TextAlign.center, style: TextStyle(fontFamily: 'Inter', fontSize: 9, color: ProColors.textMuted)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GrMalzemeSerit extends StatelessWidget {
  const _GrMalzemeSerit();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 112,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: const [
          _GrMalzemeKart(baslik: 'C30 Beton', miktar: '80 m³', durum: 'Teslim alındı', icon: Icons.foundation),
          SizedBox(width: 8),
          _GrMalzemeKart(baslik: 'İnşaat Demiri', miktar: '12 ton', durum: 'Sahaya geldi', icon: Icons.view_week),
          SizedBox(width: 8),
          _GrMalzemeKart(baslik: 'Kalıp Plywood', miktar: '150 adet', durum: 'Teslim alındı', icon: Icons.layers),
        ],
      ),
    );
  }
}

class _GrMalzemeKart extends StatelessWidget {
  const _GrMalzemeKart({required this.baslik, required this.miktar, required this.durum, required this.icon});

  final String baslik;
  final String miktar;
  final String durum;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 132,
      height: 112,
      child: _GrKart(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, size: 18, color: ProColors.textMuted),
            Text(baslik, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontFamily: 'Inter', fontSize: 10, fontWeight: FontWeight.w600, color: ProColors.text)),
            Text(miktar, style: const TextStyle(fontFamily: 'Rajdhani', fontWeight: FontWeight.w700, fontSize: 14, color: ProColors.text)),
            Row(
              children: [
                Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFF22C55E), shape: BoxShape.circle)),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(durum, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontFamily: 'Inter', fontSize: 9, color: ProColors.textMuted)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _GrKontrolKart extends StatelessWidget {
  const _GrKontrolKart({required this.baslik, required this.alt, required this.durum, required this.saat});

  final String baslik;
  final String alt;
  final String durum;
  final String saat;

  @override
  Widget build(BuildContext context) {
    return _GrKart(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(baslik, maxLines: 2, style: const TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w600, color: ProColors.text)),
          const SizedBox(height: 2),
          Text(alt, maxLines: 2, style: const TextStyle(fontFamily: 'Inter', fontSize: 10, color: ProColors.textMuted)),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF22C55E).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(durum, style: const TextStyle(fontFamily: 'Inter', fontSize: 9, fontWeight: FontWeight.w600, color: Color(0xFF22C55E))),
              ),
              const Spacer(),
              Text(saat, style: const TextStyle(fontFamily: 'Inter', fontSize: 10, color: ProColors.textMuted)),
            ],
          ),
        ],
      ),
    );
  }
}

class _GrIsgGrid extends StatelessWidget {
  const _GrIsgGrid();

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 2.4,
      children: const [
        _GrIsgHucre(baslik: 'Kaza / Olay', deger: 'Yok', icon: Icons.check_circle, renk: Color(0xFF22C55E)),
        _GrIsgHucre(baslik: 'Riskli Durum', deger: 'Yok', icon: Icons.check_circle, renk: Color(0xFF22C55E)),
        _GrIsgHucre(baslik: 'Düzeltici Faaliyet', deger: '1 adet', icon: Icons.warning_amber_rounded, renk: Color(0xFFF59E0B)),
        _GrIsgHucre(baslik: 'Denetim', deger: 'Tamamlandı', icon: Icons.check_circle, renk: Color(0xFF22C55E)),
      ],
    );
  }
}

class _GrIsgHucre extends StatelessWidget {
  const _GrIsgHucre({required this.baslik, required this.deger, required this.icon, required this.renk});

  final String baslik;
  final String deger;
  final IconData icon;
  final Color renk;

  @override
  Widget build(BuildContext context) {
    return _GrKart(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(baslik, style: const TextStyle(fontFamily: 'Inter', fontSize: 10, color: ProColors.textMuted)),
                Text(deger, style: const TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600, color: ProColors.text)),
              ],
            ),
          ),
          Icon(icon, size: 18, color: renk),
        ],
      ),
    );
  }
}

class _GrGecikmeSecim extends StatelessWidget {
  const _GrGecikmeSecim({required this.gecikmeVar, required this.onYok, required this.onVar});

  final bool gecikmeVar;
  final VoidCallback onYok;
  final VoidCallback onVar;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _GrToggleChip(label: 'Yok', selected: !gecikmeVar, onTap: onYok),
        const SizedBox(width: 6),
        _GrToggleChip(label: 'Var', selected: gecikmeVar, onTap: onVar),
      ],
    );
  }
}

class _GrToggleChip extends StatelessWidget {
  const _GrToggleChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final renk = selected ? const Color(0xFF22C55E) : ProColors.textMuted;
    return Material(
      color: selected ? renk.withValues(alpha: 0.15) : const Color(0xFF0B1018),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: selected ? renk.withValues(alpha: 0.5) : const Color(0xFF243044)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected) ...[
                Container(width: 6, height: 6, decoration: BoxDecoration(color: renk, shape: BoxShape.circle)),
                const SizedBox(width: 4),
              ],
              Text(label, style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600, color: renk)),
            ],
          ),
        ),
      ),
    );
  }
}
