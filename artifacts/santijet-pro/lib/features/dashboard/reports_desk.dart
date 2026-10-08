part of 'dashboard_screen.dart';

class _ReportKind {
  const _ReportKind({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.colors,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> colors;
}

const _reportKinds = <_ReportKind>[
  _ReportKind(
    title: 'Günlük Rapor',
    subtitle: 'Saha, imalat, hava',
    icon: Icons.calendar_today_outlined,
    colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
  ),
  _ReportKind(
    title: 'Haftalık Rapor',
    subtitle: 'İlerleme, personel, ekipman',
    icon: Icons.date_range_outlined,
    colors: [Color(0xFF059669), Color(0xFF047857)],
  ),
  _ReportKind(
    title: 'Aylık Rapor',
    subtitle: 'Maliyet, nakit akışı',
    icon: Icons.account_balance_wallet_outlined,
    colors: [Color(0xFFF97316), Color(0xFFEA580C)],
  ),
  _ReportKind(
    title: 'İmalat Raporu',
    subtitle: 'Metraj, gerçekleşme',
    icon: Icons.bar_chart_rounded,
    colors: [Color(0xFF7C3AED), Color(0xFF6D28D9)],
  ),
  _ReportKind(
    title: 'Beton Raporu',
    subtitle: 'Döküm, test sonuçları',
    icon: Icons.apartment_outlined,
    colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
  ),
  _ReportKind(
    title: 'Demir Raporu',
    subtitle: 'Kesim, montaj, atık',
    icon: Icons.grid_view_rounded,
    colors: [Color(0xFFCA8A04), Color(0xFFA16207)],
  ),
  _ReportKind(
    title: 'Malzeme Raporu',
    subtitle: 'Stok, tüketim, sipariş',
    icon: Icons.school_outlined,
    colors: [Color(0xFF2563EB), Color(0xFF1E40AF)],
  ),
  _ReportKind(
    title: 'Hakediş Raporu',
    subtitle: 'İşveren, taşeron, ödeme',
    icon: Icons.description_outlined,
    colors: [Color(0xFF16A34A), Color(0xFF15803D)],
  ),
  _ReportKind(
    title: 'Makine Raporu',
    subtitle: 'Çalışma süresi, yakıt, bakım',
    icon: Icons.two_wheeler_outlined,
    colors: [Color(0xFF0D9488), Color(0xFF0F766E)],
  ),
];

class _ReportsDesk extends StatelessWidget {
  const _ReportsDesk({this.onOpenGunlukRapor});

  final VoidCallback? onOpenGunlukRapor;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        const _RaporBaslik(),
        const SizedBox(height: 12),
        const _VerimAnalizKarti(),
        const SizedBox(height: 12),
        const _OneCikanlarKarti(),
        const SizedBox(height: 16),
        const _RaporTurleriBaslik(),
        const SizedBox(height: 10),
        _ReportKindGrid(kinds: _reportKinds, onOpenGunlukRapor: onOpenGunlukRapor),
      ],
    );
  }
}

void _raporDemo(BuildContext context, String ad) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('$ad demo görünümde sabit.')),
  );
}

class _RaporBaslik extends StatelessWidget {
  const _RaporBaslik();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: const Color(0xFF2563EB),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.bar_chart_rounded, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Raporlar',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontFamily: 'Rajdhani', fontWeight: FontWeight.w700, fontSize: 22, height: 1.05, color: ProColors.text),
              ),
              Text(
                'Şantiyenizin performansını analiz edin',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: ProColors.textMuted),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SecimCipi extends StatelessWidget {
  const _SecimCipi({required this.icon, required this.label, required this.onTap, this.esnek = false});

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool esnek;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF121A27),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 32),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: ProColors.border),
            ),
            child: Row(
              mainAxisSize: esnek ? MainAxisSize.max : MainAxisSize.min,
              children: [
                Icon(icon, size: 14, color: ProColors.textMuted),
                const SizedBox(width: 4),
                if (esnek)
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600, color: ProColors.text),
                    ),
                  )
                else
                  Text(
                    label,
                    maxLines: 2,
                    style: const TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600, color: ProColors.text),
                  ),
                const Icon(Icons.keyboard_arrow_down, size: 16, color: ProColors.textMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _VerimAnalizKarti extends StatefulWidget {
  const _VerimAnalizKarti();

  @override
  State<_VerimAnalizKarti> createState() => _VerimAnalizKartiState();
}

class _VerimAnalizKartiState extends State<_VerimAnalizKarti> {
  late _RaporSure _sure = _RaporSure.ay(DateTime(DateTime.now().year, DateTime.now().month, 1));

  Future<void> _sec() async {
    final sonuc = await showModalBottomSheet<_RaporSure>(
      context: context,
      backgroundColor: const Color(0xFF0B1220),
      isScrollControlled: true,
      builder: (context) => const _RaporTarihPanel(),
    );
    if (sonuc == null || !mounted) return;
    setState(() => _sure = sonuc);
  }

  @override
  Widget build(BuildContext context) {
    final gorunum = _VerimGorunum.sec(_sure);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0E1624),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ProColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _VerimBaslik(sure: _sure, gorunum: gorunum, onSec: _sec),
          const SizedBox(height: 12),
          _VerimGovde(gorunum: gorunum),
          const SizedBox(height: 10),
          const _VerimNotu(),
        ],
      ),
    );
  }
}

class _VerimGorunum {
  const _VerimGorunum({required this.genel, required this.genelFark, required this.kalemler});

  final int genel;
  final int? genelFark;
  final List<(int deger, int? fark)> kalemler;

  static const _sabitDeger = [82, 91, 88, 79, 93, 85];
  static const _sabitFark = [-8, 12, 3, -5, 7, 6];

  factory _VerimGorunum.sec(_RaporSure sure) {
    final simdi = DateTime.now();
    final ay = sure.tur == _RaporSureTur.ay;
    final buAy = ay && sure.bas.year == simdi.year && sure.bas.month == simdi.month;
    if (buAy) {
      return _VerimGorunum(
        genel: 87,
        genelFark: 6,
        kalemler: [for (var i = 0; i < 6; i++) (_sabitDeger[i], _sabitFark[i])],
      );
    }
    final tohum = switch (sure.tur) {
      _RaporSureTur.ay => sure.bas.year * 12 + sure.bas.month,
      _RaporSureTur.gun => _gunNo(sure.bas),
      _RaporSureTur.aralik => _gunNo(sure.bas) + _gunNo(sure.bit ?? sure.bas) * 3,
    };
    final degerler = [for (var i = 0; i < 6; i++) 68 + _verimKaris(tohum + i * 17) % 28];
    final genel = (degerler.reduce((a, b) => a + b) / degerler.length).round();
    if (!ay) {
      return _VerimGorunum(genel: genel, genelFark: null, kalemler: [for (final deger in degerler) (deger, null)]);
    }
    final farklar = [for (var i = 0; i < 6; i++) _verimFark(tohum, i)];
    final genelFark = (farklar.reduce((a, b) => a + b) / farklar.length).round();
    return _VerimGorunum(
      genel: genel,
      genelFark: genelFark == 0 ? 1 : genelFark,
      kalemler: [for (var i = 0; i < degerler.length; i++) (degerler[i], farklar[i])],
    );
  }
}

int _gunNo(DateTime gun) => gun.year * 400 + gun.month * 32 + gun.day;

int _verimKaris(int n) {
  var x = n & 0x7fffffff;
  x = (x * 1103515245 + 12345) & 0x7fffffff;
  return x;
}

int _verimFark(int tohum, int kayma) {
  final ham = _verimKaris(tohum + kayma * 13) % 21 - 10;
  return ham == 0 ? 1 : ham;
}

class _VerimBaslik extends StatelessWidget {
  const _VerimBaslik({required this.sure, required this.gorunum, required this.onSec});

  final _RaporSure sure;
  final _VerimGorunum gorunum;
  final VoidCallback onSec;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  _VerimBaslikIkon(),
                  SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Verim & Analiz',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontFamily: 'Rajdhani', fontWeight: FontWeight.w700, fontSize: 16, color: ProColors.text),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Az Veri. Çok Verim.',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: ProColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _SecimCipi(
                icon: Icons.calendar_today_outlined,
                label: sure.yazi,
                esnek: true,
                onTap: onSec,
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(width: 72, height: 72, child: _VerimHalka(oran: gorunum.genel / 100)),
        const SizedBox(width: 8),
        _VerimHalkaYazi(fark: gorunum.genelFark),
      ],
    );
  }
}

class _VerimBaslikIkon extends StatelessWidget {
  const _VerimBaslikIkon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: const Color(0xFF16A34A),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.trending_up, color: Colors.white, size: 18),
    );
  }
}

class _VerimHalkaYazi extends StatelessWidget {
  const _VerimHalkaYazi({required this.fark});

  final int? fark;

  @override
  Widget build(BuildContext context) {
    final kiyas = fark;
    final yukari = (kiyas ?? 0) > 0;
    final renk = yukari ? const Color(0xFF4ADE80) : const Color(0xFFEF4444);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('Genel Verim', style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: ProColors.text)),
        if (kiyas != null) ...[
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(yukari ? Icons.arrow_drop_up : Icons.arrow_drop_down, size: 18, color: renk),
              Text('%${kiyas.abs()}', style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w700, color: renk)),
            ],
          ),
          const Text('Geçen aya göre', style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: ProColors.textFaint)),
        ],
      ],
    );
  }
}

enum _RaporSureTur { ay, gun, aralik }

class _RaporSure {
  const _RaporSure.ay(DateTime ay)
      : tur = _RaporSureTur.ay,
        bas = ay,
        bit = null;

  const _RaporSure.gun(DateTime gun)
      : tur = _RaporSureTur.gun,
        bas = gun,
        bit = null;

  const _RaporSure.aralik(this.bas, DateTime bitis)
      : tur = _RaporSureTur.aralik,
        bit = bitis;

  static const _aylar = [
    'OCAK',
    'ŞUBAT',
    'MART',
    'NİSAN',
    'MAYIS',
    'HAZİRAN',
    'TEMMUZ',
    'AĞUSTOS',
    'EYLÜL',
    'EKİM',
    'KASIM',
    'ARALIK',
  ];

  final _RaporSureTur tur;
  final DateTime bas;
  final DateTime? bit;

  String get yazi {
    final ayAd = _aylar[bas.month - 1];
    return switch (tur) {
      _RaporSureTur.ay => '$ayAd ${bas.year}',
      _RaporSureTur.gun => '${bas.day} $ayAd ${bas.year}',
      _RaporSureTur.aralik => _aralikYazi(bas, bit ?? bas),
    };
  }

  static String _aralikYazi(DateTime bas, DateTime bit) {
    final a = bas.isAfter(bit) ? bit : bas;
    final b = bas.isAfter(bit) ? bas : bit;
    final ayA = _aylar[a.month - 1];
    final ayB = _aylar[b.month - 1];
    if (a.year == b.year && a.month == b.month) {
      if (a.day == b.day) return '${a.day} $ayA ${a.year}';
      return '${a.day}-${b.day} $ayA ${a.year}';
    }
    if (a.year == b.year) return '${a.day} $ayA - ${b.day} $ayB ${a.year}';
    return '${a.day} $ayA ${a.year} - ${b.day} $ayB ${b.year}';
  }
}

enum _TarihListe { yok, yil, ay }

class _RaporTarihPanel extends StatefulWidget {
  const _RaporTarihPanel();

  @override
  State<_RaporTarihPanel> createState() => _RaporTarihPanelState();
}

class _RaporTarihPanelState extends State<_RaporTarihPanel> {
  static const _ayAd = ['Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran', 'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'];
  static const _gunAd = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];

  _TarihListe _liste = _TarihListe.yok;
  late int _yil = _bugun.year;
  late int _ay = _bugun.month;
  DateTime? _bas;
  DateTime? _bit;

  DateTime get _bugun {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  List<int> get _yillar => [for (var y = _bugun.year; y >= 2020; y--) y];

  bool _ayAcik(int yil, int ay) {
    if (yil > _bugun.year) return false;
    if (yil == _bugun.year && ay > _bugun.month) return false;
    if (yil < 2020) return false;
    return true;
  }

  bool _gunAcik(DateTime gun) => !gun.isAfter(_bugun);

  void _ayKaydir(int delta) {
    final sonraki = DateTime(_yil, _ay + delta, 1);
    if (!_ayAcik(sonraki.year, sonraki.month)) return;
    setState(() {
      _yil = sonraki.year;
      _ay = sonraki.month;
      _liste = _TarihListe.yok;
    });
  }

  void _yilSec(int yil) {
    var ay = _ay;
    if (!_ayAcik(yil, ay)) ay = _bugun.month;
    setState(() {
      _yil = yil;
      _ay = ay;
      _liste = _TarihListe.yok;
    });
  }

  void _aySec(int ay) {
    if (!_ayAcik(_yil, ay)) return;
    setState(() {
      _ay = ay;
      _liste = _TarihListe.yok;
    });
  }

  void _listeAc(_TarihListe hedef) {
    setState(() => _liste = _liste == hedef ? _TarihListe.yok : hedef);
  }

  void _gunSec(DateTime gun) {
    if (!_gunAcik(gun)) return;
    setState(() {
      final bas = _bas;
      if (bas == null || _bit != null || _ayniGun(bas, gun)) {
        _bas = gun;
        _bit = null;
        return;
      }
      _bit = gun;
    });
  }

  void _onayla() {
    final bas = _bas;
    if (bas == null) return;
    final bit = _bit;
    if (bit == null || _ayniGun(bas, bit)) {
      Navigator.pop(context, _RaporSure.gun(bas));
      return;
    }
    final a = bas.isAfter(bit) ? bit : bas;
    final b = bas.isAfter(bit) ? bas : bit;
    Navigator.pop(context, _RaporSure.aralik(a, b));
  }

  void _tumu() {
    Navigator.pop(context, _RaporSure.ay(DateTime(_yil, _ay, 1)));
  }

  String get _ipucu {
    final bas = _bas;
    if (bas == null) return 'Bir gün seçip OK ile onaylayın. Ayın tamamı için Tümü.';
    final bit = _bit;
    if (bit == null) return '${bas.day} ${_ayAd[bas.month - 1]} seçildi. Aralık için bitiş gününü de seçin.';
    final a = bas.isAfter(bit) ? bit : bas;
    final b = bas.isAfter(bit) ? bas : bit;
    if (a.month == b.month && a.year == b.year) return '${a.day}-${b.day} ${_ayAd[a.month - 1]} seçildi.';
    return '${a.day} ${_ayAd[a.month - 1]} - ${b.day} ${_ayAd[b.month - 1]} seçildi.';
  }

  @override
  Widget build(BuildContext context) {
    final alt = MediaQuery.viewPaddingOf(context).bottom;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 8, 16, 12 + alt),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text('Tarih seç', style: TextStyle(fontFamily: 'Rajdhani', fontWeight: FontWeight.w700, fontSize: 20, color: ProColors.text)),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: ProColors.textMuted),
                ),
              ],
            ),
            _yilBaslik(),
            const SizedBox(height: 2),
            _ayBaslik(),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.46),
              child: SingleChildScrollView(
                child: _liste == _TarihListe.yok ? _gunGrid() : _acilirListe(),
              ),
            ),
            const SizedBox(height: 8),
            Text(_ipucu, textAlign: TextAlign.center, style: const TextStyle(fontFamily: 'Inter', fontSize: 12, height: 1.3, color: ProColors.textMuted)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    key: const Key('rapor-tarih-tumu'),
                    onPressed: _tumu,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: ProColors.text,
                      side: const BorderSide(color: ProColors.border),
                      minimumSize: const Size(0, 40),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Tümü', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 13)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    key: const Key('rapor-tarih-ok'),
                    onPressed: _bas == null ? null : _onayla,
                    style: FilledButton.styleFrom(
                      backgroundColor: ProColors.electricBlue,
                      disabledBackgroundColor: const Color(0xFF1E293B),
                      disabledForegroundColor: ProColors.textFaint,
                      minimumSize: const Size(0, 40),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check, size: 18),
                        SizedBox(width: 4),
                        Text('OK', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: 13)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _yilBaslik() {
    final acik = _liste == _TarihListe.yil;
    return Center(
      child: InkWell(
        key: const Key('rapor-tarih-yil'),
        borderRadius: BorderRadius.circular(8),
        onTap: () => _listeAc(_TarihListe.yil),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$_yil', style: const TextStyle(fontFamily: 'Rajdhani', fontWeight: FontWeight.w700, fontSize: 18, color: ProColors.text)),
              Icon(acik ? Icons.expand_less : Icons.expand_more, size: 18, color: ProColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }

  Widget _ayBaslik() {
    final onceki = DateTime(_yil, _ay - 1, 1);
    final sonraki = DateTime(_yil, _ay + 1, 1);
    final acik = _liste == _TarihListe.ay;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _ok(
          key: const Key('rapor-tarih-geri'),
          ikon: Icons.chevron_left,
          onTap: _ayAcik(onceki.year, onceki.month) ? () => _ayKaydir(-1) : null,
        ),
        InkWell(
          key: const Key('rapor-tarih-ay'),
          borderRadius: BorderRadius.circular(8),
          onTap: () => _listeAc(_TarihListe.ay),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_ayAd[_ay - 1], style: const TextStyle(fontFamily: 'Rajdhani', fontWeight: FontWeight.w700, fontSize: 18, color: ProColors.text)),
                Icon(acik ? Icons.expand_less : Icons.expand_more, size: 18, color: ProColors.textMuted),
              ],
            ),
          ),
        ),
        _ok(
          key: const Key('rapor-tarih-ileri'),
          ikon: Icons.chevron_right,
          onTap: _ayAcik(sonraki.year, sonraki.month) ? () => _ayKaydir(1) : null,
        ),
      ],
    );
  }

  Widget _ok({required Key key, required IconData ikon, required VoidCallback? onTap}) {
    final acik = onTap != null;
    return IconButton(
      key: key,
      onPressed: onTap,
      visualDensity: VisualDensity.compact,
      icon: Icon(ikon, color: acik ? ProColors.text : ProColors.textFaint),
    );
  }

  Widget _acilirListe() {
    if (_liste == _TarihListe.yil) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final yil in _yillar)
            _listeSatir(
              key: Key('rapor-tarih-yil-$yil'),
              etiket: '$yil',
              secili: yil == _yil,
              acik: true,
              onTap: () => _yilSec(yil),
            ),
        ],
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var ay = 1; ay <= 12; ay++)
          _listeSatir(
            key: Key('rapor-tarih-ay-$ay'),
            etiket: _ayAd[ay - 1],
            secili: ay == _ay,
            acik: _ayAcik(_yil, ay),
            onTap: () => _aySec(ay),
          ),
      ],
    );
  }

  Widget _listeSatir({required Key key, required String etiket, required bool secili, required bool acik, required VoidCallback onTap}) {
    return Material(
      color: secili ? const Color(0x332563EB) : Colors.transparent,
      child: InkWell(
        key: key,
        onTap: acik ? onTap : null,
        child: SizedBox(
          height: 40,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    etiket,
                    style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 14, color: acik ? ProColors.text : ProColors.textFaint),
                  ),
                ),
                if (secili) const Icon(Icons.check, size: 16, color: Color(0xFF2563EB)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _gunGrid() {
    final ilk = DateTime(_yil, _ay, 1);
    final adet = DateTime(_yil, _ay + 1, 0).day;
    final bos = ilk.weekday - 1;
    final bas = _bas;
    final bit = _bit;
    DateTime? sol;
    DateTime? sag;
    if (bas != null && bit != null) {
      sol = bas.isAfter(bit) ? bit : bas;
      sag = bas.isAfter(bit) ? bas : bit;
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            for (final ad in _gunAd)
              Expanded(child: Text(ad, textAlign: TextAlign.center, style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: ProColors.textMuted))),
          ],
        ),
        const SizedBox(height: 6),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: bos + adet,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, mainAxisSpacing: 4, crossAxisSpacing: 4),
          itemBuilder: (context, index) {
            if (index < bos) return const SizedBox.shrink();
            final gun = DateTime(_yil, _ay, index - bos + 1);
            final secili = (bas != null && _ayniGun(bas, gun)) || (bit != null && _ayniGun(bit, gun));
            final aralik = sol != null && sag != null && !gun.isBefore(sol) && !gun.isAfter(sag) && !secili;
            return _secimKutu(
              key: Key('rapor-tarih-gun-${gun.year}-${gun.month}-${gun.day}'),
              etiket: '${gun.day}',
              secili: secili,
              aralik: aralik,
              acik: _gunAcik(gun),
              onTap: () => _gunSec(gun),
            );
          },
        ),
      ],
    );
  }

  bool _ayniGun(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  Widget _secimKutu({
    required Key key,
    required String etiket,
    required bool secili,
    required bool acik,
    required VoidCallback onTap,
    bool aralik = false,
  }) {
    final dolgu = secili
        ? const Color(0xFF2563EB)
        : aralik
            ? const Color(0x472563EB)
            : (acik ? const Color(0xFF121826) : const Color(0xFF0B1220));
    return Material(
      color: dolgu,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        key: key,
        onTap: acik ? onTap : null,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: secili ? const Color(0xFF2563EB) : ProColors.border),
          ),
          child: Text(
            etiket,
            style: TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: acik ? (secili || aralik ? Colors.white : ProColors.text) : ProColors.textFaint,
            ),
          ),
        ),
      ),
    );
  }
}

const _verimIkon = 22.0;
const _verimOk = 12.0;

class _VerimGovde extends StatelessWidget {
  const _VerimGovde({required this.gorunum});

  final _VerimGorunum gorunum;

  static const _baslikStil = TextStyle(fontFamily: 'Inter', fontSize: 11);
  static const _basliklar = ['İşçilik Verimi', 'Makine Verimi', 'Malzeme Verimi', 'Zaman Verimi', 'Maliyet Verimi', 'Plan Gerçekleşme'];

  static double _yazi(String metin) {
    final painter = TextPainter(text: TextSpan(text: metin, style: _baslikStil), textDirection: TextDirection.ltr, maxLines: 1)..layout();
    final genislik = painter.width;
    painter.dispose();
    return genislik;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, sinir) {
        const kartPay = 4.0 + 4.0 + 2.0 + _verimIkon + 4.0 + _verimOk;
        final alan = (sinir.maxWidth - 6) / 2 - kartPay;
        final ikiSatir = _basliklar.any((baslik) => _yazi(baslik) > alan);
        return _VerimIzgara(ikiSatir: ikiSatir, kalemler: gorunum.kalemler);
      },
    );
  }
}

class _VerimHalka extends StatelessWidget {
  const _VerimHalka({required this.oran});

  final double oran;

  @override
  Widget build(BuildContext context) {
    final yuzde = (oran * 100).round();
    return AspectRatio(
      aspectRatio: 1,
      child: CustomPaint(
        painter: _VerimHalkaPainter(oran: oran),
        child: Center(
          child: Text('%$yuzde', style: const TextStyle(fontFamily: 'Rajdhani', fontWeight: FontWeight.w700, fontSize: 22, height: 1, color: ProColors.text)),
        ),
      ),
    );
  }
}

class _VerimHalkaPainter extends CustomPainter {
  const _VerimHalkaPainter({required this.oran});

  final double oran;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final stroke = size.shortestSide * 0.09;
    final radius = (size.shortestSide / 2) - stroke;
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = const Color(0xFF1E293B);
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF22C55E);
    canvas.drawCircle(center, radius, track);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -1.5708,
      6.2832 * oran,
      false,
      arc,
    );
  }

  @override
  bool shouldRepaint(covariant _VerimHalkaPainter oldDelegate) => oldDelegate.oran != oran;
}

class _VerimIzgara extends StatelessWidget {
  const _VerimIzgara({required this.ikiSatir, required this.kalemler});

  final bool ikiSatir;
  final List<(int deger, int? fark)> kalemler;

  static const _kimlik = <(IconData, Color, String)>[
    (Icons.groups, Color(0xFF7C3AED), 'İşçilik Verimi'),
    (Icons.precision_manufacturing, Color(0xFF2563EB), 'Makine Verimi'),
    (Icons.view_in_ar, Color(0xFF16A34A), 'Malzeme Verimi'),
    (Icons.schedule, Color(0xFFF97316), 'Zaman Verimi'),
    (Icons.payments, Color(0xFFEF4444), 'Maliyet Verimi'),
    (Icons.bar_chart, Color(0xFFEAB308), 'Plan Gerçekleşme'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < _kimlik.length; i += 2) ...[
          if (i > 0) const SizedBox(height: 6),
          Row(
            children: [
              Expanded(child: _hucre(i)),
              const SizedBox(width: 6),
              Expanded(child: _hucre(i + 1)),
            ],
          ),
        ],
      ],
    );
  }

  Widget _hucre(int index) {
    final hucre = _kimlik[index];
    final kalem = kalemler[index];
    return _VerimHucre(
      icon: hucre.$1,
      renk: hucre.$2,
      baslik: hucre.$3,
      deger: '%${kalem.$1}',
      fark: kalem.$2,
      ikiSatir: ikiSatir,
    );
  }
}

class _VerimHucre extends StatelessWidget {
  const _VerimHucre({
    required this.icon,
    required this.renk,
    required this.baslik,
    required this.deger,
    required this.fark,
    required this.ikiSatir,
  });

  final IconData icon;
  final Color renk;
  final String baslik;
  final String deger;
  final int? fark;
  final bool ikiSatir;

  @override
  Widget build(BuildContext context) {
    final kiyas = fark;
    final yukari = (kiyas ?? 0) > 0;
    final farkRenk = yukari ? const Color(0xFF4ADE80) : const Color(0xFFEF4444);
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 6, 4, 6),
      decoration: BoxDecoration(
        color: const Color(0xFF121A27),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ProColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: _verimIkon,
            height: _verimIkon,
            decoration: BoxDecoration(color: renk, borderRadius: BorderRadius.circular(7)),
            child: Icon(icon, size: 13, color: Colors.white),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        baslik,
                        maxLines: ikiSatir ? 2 : 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontFamily: 'Inter', fontSize: 11, height: 1.15, color: ProColors.textMuted),
                      ),
                    ),
                    const Icon(Icons.chevron_right, size: _verimOk, color: ProColors.textMuted),
                  ],
                ),
                Row(
                  children: [
                    Text(deger, style: const TextStyle(fontFamily: 'Rajdhani', fontWeight: FontWeight.w700, fontSize: 16, height: 1, color: ProColors.text)),
                    if (kiyas != null) ...[
                      Icon(yukari ? Icons.arrow_drop_up : Icons.arrow_drop_down, size: 16, color: farkRenk),
                      Text('%${kiyas.abs()}', style: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w700, color: farkRenk)),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VerimNotu extends StatelessWidget {
  const _VerimNotu();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF121A27),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info, size: 15, color: Color(0xFF3B82F6)),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Genel verim, 6 ana performans göstergesinin ağırlıklı değerlendirmesidir.',
              style: TextStyle(fontFamily: 'Inter', fontSize: 11, height: 1.3, color: ProColors.textMuted),
            ),
          ),
        ],
      ),
    );
  }
}

class _OneCikanlarKarti extends StatelessWidget {
  const _OneCikanlarKarti();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.campaign_outlined, size: 16, color: Color(0xFFFBBF24)),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'Öne Çıkanlar',
                  style: TextStyle(fontFamily: 'Rajdhani', fontWeight: FontWeight.w700, fontSize: 16, color: ProColors.text),
                ),
              ),
              _SecimCipi(icon: Icons.tune, label: 'Tümü', onTap: () => _raporDemo(context, 'Öne çıkan filtresi')),
            ],
          ),
          const SizedBox(height: 10),
          const _OneCikanSatir(
            icon: Icons.trending_up,
            renk: Color(0xFF22C55E),
            metin: 'Makine kullanımı geçen haftaya göre %12 arttı.',
            rozet: 'Bu Hafta',
          ),
          const _OneCikanSatir(
            icon: Icons.trending_down,
            renk: Color(0xFFEF4444),
            metin: 'İşçilik verimi %8 düştü.',
            rozet: 'Bu Hafta',
          ),
          const _OneCikanSatir(
            icon: Icons.warning_amber_rounded,
            renk: Color(0xFFF97316),
            metin: 'Beton tüketimi hedefin %4 üzerinde.',
            rozet: 'Bu Ay',
          ),
          const _OneCikanSatir(
            icon: Icons.info_outline,
            renk: Color(0xFF3B82F6),
            metin: 'İş programı gerçekleşmesi %91 seviyesinde.',
            rozet: 'Bu Ay',
            son: true,
          ),
        ],
      ),
    );
  }
}

class _OneCikanSatir extends StatelessWidget {
  const _OneCikanSatir({
    required this.icon,
    required this.renk,
    required this.metin,
    required this.rozet,
    this.son = false,
  });

  final IconData icon;
  final Color renk;
  final String metin;
  final String rozet;
  final bool son;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: son ? 0 : 8),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(color: renk.withValues(alpha: 0.16), shape: BoxShape.circle),
            child: Icon(icon, size: 15, color: renk),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              metin,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontFamily: 'Inter', fontSize: 13, height: 1.25, color: ProColors.text),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: renk.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              rozet,
              style: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w600, color: renk),
            ),
          ),
        ],
      ),
    );
  }
}

class _RaporTurleriBaslik extends StatelessWidget {
  const _RaporTurleriBaslik();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Icon(Icons.bar_chart_rounded, size: 16, color: Color(0xFF3B82F6)),
        SizedBox(width: 6),
        Expanded(
          child: Text(
            'Rapor Türleri',
            style: TextStyle(fontFamily: 'Rajdhani', fontWeight: FontWeight.w700, fontSize: 16, color: ProColors.text),
          ),
        ),
      ],
    );
  }
}

class _ReportKindGrid extends StatelessWidget {
  const _ReportKindGrid({required this.kinds, this.onOpenGunlukRapor});

  final List<_ReportKind> kinds;
  final VoidCallback? onOpenGunlukRapor;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: kinds.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        mainAxisExtent: 96,
      ),
      itemBuilder: (context, index) {
        final kind = kinds[index];
        return Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            key: kind.title == 'Günlük Rapor' ? const Key('report-open-gunluk') : null,
            borderRadius: BorderRadius.circular(14),
            onTap: () {
              if (kind.title == 'Günlük Rapor' && onOpenGunlukRapor != null) {
                onOpenGunlukRapor!();
                return;
              }
              _keepInPro(context);
            },
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: kind.colors),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(kind.icon, color: Colors.white, size: 18),
                    const SizedBox(height: 6),
                    Text(
                      kind.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontFamily: 'Rajdhani', fontWeight: FontWeight.w700, fontSize: 13, height: 1.05, color: Colors.white),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            kind.subtitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontFamily: 'Inter', fontSize: 11, height: 1.15, color: Color(0xF2FFFFFF)),
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: Colors.white, size: 14),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? ProColors.electricBlue : ProColors.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : ProColors.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}
