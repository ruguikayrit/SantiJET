part of 'dashboard_screen.dart';

/// Diğer masalarla aynı taban ölçü. Dar ekranda hafif küçülür, geniş ekranda şişmez.
double _malzemeOlcek(double genislik) => (genislik / 390).clamp(0.9, 1.0);

const _kMalzemeSerit = 40.0;
const _kMalzemeKpi = 72.0;

class _MalzemeOlcek extends InheritedWidget {
  const _MalzemeOlcek({required this.s, required super.child});

  final double s;

  static double of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<_MalzemeOlcek>()!.s;

  @override
  bool updateShouldNotify(_MalzemeOlcek oldWidget) => oldWidget.s != s;
}

double _mz(BuildContext context, double v) => _MalzemeOlcek.of(context) * v;

enum _MalzemeSekme { genel, giris, tuketim, stok, transfer, iade }

enum _MalzemeIslemTur { giris, tuketim, transfer }

extension on _MalzemeSekme {
  String get label => switch (this) {
        _MalzemeSekme.genel => 'Genel Bakış',
        _MalzemeSekme.giris => 'Giriş (25)',
        _MalzemeSekme.tuketim => 'Tüketim (18)',
        _MalzemeSekme.stok => 'Stok (312)',
        _MalzemeSekme.transfer => 'Transfer',
        _MalzemeSekme.iade => 'İadeler',
      };
}

class _DusukStokKalem {
  const _DusukStokKalem({
    required this.ad,
    required this.grup,
    required this.miktar,
    required this.min,
    required this.renk,
    required this.icon,
  });

  final String ad;
  final String grup;
  final String miktar;
  final String min;
  final Color renk;
  final IconData icon;
}

class _MalzemeIslem {
  const _MalzemeIslem({
    required this.tur,
    required this.tarih,
    required this.ad,
    required this.miktar,
    required this.yer,
    required this.taraf,
    required this.belge,
  });

  final _MalzemeIslemTur tur;
  final String tarih;
  final String ad;
  final String miktar;
  final String yer;
  final String taraf;
  final String belge;
}

const _kDusukStok = <_DusukStokKalem>[
  _DusukStokKalem(
    ad: 'Nervürlü Demir Ø12',
    grup: 'Çelik · Donatı',
    miktar: '80 kg',
    min: 'Min: 500 kg',
    renk: Color(0xFF64748B),
    icon: Icons.linear_scale,
  ),
  _DusukStokKalem(
    ad: 'CEM I 42.5 R Çimento',
    grup: 'Yapı Kimyasalı',
    miktar: '12 torba',
    min: 'Min: 50 torba',
    renk: Color(0xFFD6C4A8),
    icon: Icons.inventory_2_outlined,
  ),
  _DusukStokKalem(
    ad: 'PVC Pis Su Borusu Ø100',
    grup: 'Mekanik · Tesisat',
    miktar: '20 m',
    min: 'Min: 100 m',
    renk: Color(0xFFE07A3D),
    icon: Icons.circle_outlined,
  ),
];

const _kMalzemeIslemler = <_MalzemeIslem>[
  _MalzemeIslem(
    tur: _MalzemeIslemTur.giris,
    tarih: '2 Eki 2026 15:10',
    ad: 'Beton C35/40',
    miktar: '120 m³',
    yer: 'A Blok · 2. Kat',
    taraf: 'Beton A.Ş.',
    belge: 'Fiş: F-1023',
  ),
  _MalzemeIslem(
    tur: _MalzemeIslemTur.tuketim,
    tarih: '2 Eki 2026 13:20',
    ad: 'Kalıp Plywood 18 mm',
    miktar: '120 m²',
    yer: 'A Blok · 2. Kat',
    taraf: 'Kalıp Ekibi',
    belge: 'İmalat: Kalıp',
  ),
  _MalzemeIslem(
    tur: _MalzemeIslemTur.transfer,
    tarih: '1 Eki 2026 10:45',
    ad: 'Nervürlü Demir Ø16',
    miktar: '1.200 kg',
    yer: 'A Blok → B Blok',
    taraf: 'Depo Sorumlusu',
    belge: 'Transfer: T-045',
  ),
];

class _MalzemeDesk extends StatefulWidget {
  const _MalzemeDesk({required this.onBack});

  final VoidCallback onBack;

  @override
  State<_MalzemeDesk> createState() => _MalzemeDeskState();
}

class _MalzemeDeskState extends State<_MalzemeDesk> {
  static const _haftaGunAdlari = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];

  _MalzemeSekme _sekme = _MalzemeSekme.genel;
  _MalzemeIslemTur? _islemFiltre;
  final _arama = TextEditingController();
  late DateTime _gun = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

  DateTime get _haftaBasi => _gun.subtract(Duration(days: _gun.weekday - 1));

  @override
  void dispose() {
    _arama.dispose();
    super.dispose();
  }

  List<_DusukStokKalem> get _dusuk {
    final q = _arama.text.trim().toLowerCase();
    if (q.isEmpty) return _kDusukStok;
    return _kDusukStok.where((k) => k.ad.toLowerCase().contains(q) || k.grup.toLowerCase().contains(q)).toList();
  }

  List<_MalzemeIslem> get _islemler {
    final q = _arama.text.trim().toLowerCase();
    return [
      for (final islem in _kMalzemeIslemler)
        if ((_islemFiltre == null || islem.tur == _islemFiltre) && (q.isEmpty || islem.ad.toLowerCase().contains(q))) islem,
    ];
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final s = _malzemeOlcek(constraints.maxWidth);
        double z(double v) => v * s;
        return _MalzemeOlcek(
          s: s,
          child: ListView(
            padding: EdgeInsets.fromLTRB(z(16), z(8), z(16), z(24)),
            children: [
              _ModulDeskUst(
                title: 'Malzeme',
                moduleIcon: Icons.local_shipping_outlined,
                moduleColor: const Color(0xFF2563EB),
                backKey: const Key('malzeme-back'),
                onBack: widget.onBack,
                backLabel: 'Saha',
                trailing: const SizedBox.shrink(),
              ),
              SizedBox(height: z(12)),
              _PuantajWeekStrip(
                weekStart: _haftaBasi,
                selected: _gun,
                dayNames: _haftaGunAdlari,
                onSelect: (gun) => setState(() => _gun = DateTime(gun.year, gun.month, gun.day)),
                onPrevious: () => setState(() => _gun = _gun.subtract(const Duration(days: 7))),
                onNext: () => setState(() => _gun = _gun.add(const Duration(days: 7))),
              ),
              SizedBox(height: z(12)),
              _MalzemeSekmeler(
                secili: _sekme,
                onSec: (sekme) => setState(() => _sekme = sekme),
              ),
              SizedBox(height: z(10)),
              const _MalzemeKpiSatiri(),
              SizedBox(height: z(10)),
              const _MalzemeAksiyonlar(),
              SizedBox(height: z(10)),
              _MalzemeArama(
                controller: _arama,
                onChanged: (_) => setState(() {}),
              ),
              SizedBox(height: z(12)),
              ..._govde(z),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _govde(double Function(double) z) {
    final bosluk = SizedBox(height: z(12));
    return switch (_sekme) {
      _MalzemeSekme.genel => [
          _DusukStokKart(kalemler: _dusuk),
          bosluk,
          _SonIslemler(
            islemler: _islemler,
            filtre: _islemFiltre,
            onTemizle: () => setState(() => _islemFiltre = null),
            onFiltre: (tur) => setState(() => _islemFiltre = _islemFiltre == tur ? null : tur),
          ),
          bosluk,
          const _MalzemeRaporlar(),
        ],
      _MalzemeSekme.giris => [
          _IslemListesi(baslik: 'Giriş Kayıtları', islemler: _kMalzemeIslemler.where((i) => i.tur == _MalzemeIslemTur.giris).toList()),
        ],
      _MalzemeSekme.tuketim => [
          _IslemListesi(baslik: 'Tüketim Kayıtları', islemler: _kMalzemeIslemler.where((i) => i.tur == _MalzemeIslemTur.tuketim).toList()),
        ],
      _MalzemeSekme.stok => [
          _DusukStokKart(kalemler: _dusuk),
          bosluk,
          const _MalzemeRaporlar(),
        ],
      _MalzemeSekme.transfer => [
          _IslemListesi(baslik: 'Transfer Kayıtları', islemler: _kMalzemeIslemler.where((i) => i.tur == _MalzemeIslemTur.transfer).toList()),
        ],
      _MalzemeSekme.iade => const [
          _MalzemeBos('İade kaydı yok.', 'İade hareketleri oluşunca bu listede görünür.'),
        ],
    };
  }
}

class _MalzemeSekmeler extends StatelessWidget {
  const _MalzemeSekmeler({required this.secili, required this.onSec});

  final _MalzemeSekme secili;
  final ValueChanged<_MalzemeSekme> onSec;

  @override
  Widget build(BuildContext context) {
    final yukseklik = _mz(context, _kMalzemeSerit);
    return SizedBox(
      height: yukseklik,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _MalzemeSekme.values.length,
        separatorBuilder: (_, __) => SizedBox(width: _mz(context, 8)),
        itemBuilder: (context, index) {
          final sekme = _MalzemeSekme.values[index];
          return _MalzemeSekmeCip(
            key: Key('malzeme-sekme-${sekme.name}'),
            label: sekme.label,
            secili: sekme == secili,
            onTap: () => onSec(sekme),
          );
        },
      ),
    );
  }
}

class _MalzemeSekmeCip extends StatelessWidget {
  const _MalzemeSekmeCip({super.key, required this.label, required this.secili, required this.onTap});

  final String label;
  final bool secili;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: secili ? const Color(0xFF16A34A) : const Color(0xFF121826),
      borderRadius: BorderRadius.circular(_mz(context, 16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(_mz(context, 16)),
        child: Container(
          height: _mz(context, _kMalzemeSerit),
          alignment: Alignment.center,
          padding: EdgeInsets.symmetric(horizontal: _mz(context, 14)),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_mz(context, 12)),
            border: Border.all(color: secili ? const Color(0xFF16A34A) : const Color(0xFF243044)),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: _mz(context, 13),
              fontWeight: FontWeight.w600,
              color: secili ? Colors.white : ProColors.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}

class _MalzemeKpiSatiri extends StatelessWidget {
  const _MalzemeKpiSatiri();

  @override
  Widget build(BuildContext context) {
    final aralik = _mz(context, 6);
    return SizedBox(
      height: _mz(context, _kMalzemeKpi),
      child: Row(
        children: [
          const Expanded(
            child: _MalzemeKpi(
              renk: Color(0xFF15803D),
              icon: Icons.local_shipping_outlined,
              deger: '25',
              baslik: 'Gelen Malzeme',
            ),
          ),
          SizedBox(width: aralik),
          const Expanded(
            child: _MalzemeKpi(
              renk: Color(0xFF1D4ED8),
              icon: Icons.trending_up,
              deger: '18',
              baslik: 'Tüketim Kaydı',
            ),
          ),
          SizedBox(width: aralik),
          const Expanded(
            child: _MalzemeKpi(
              renk: Color(0xFFC2410C),
              icon: Icons.inventory_2_outlined,
              deger: '312',
              baslik: 'Stoktaki Malzeme',
            ),
          ),
          SizedBox(width: aralik),
          const Expanded(
            child: _MalzemeKpi(
              renk: Color(0xFF9F1239),
              icon: Icons.warning_amber_rounded,
              deger: '3',
              baslik: 'Düşük Stok',
            ),
          ),
        ],
      ),
    );
  }
}

class _MalzemeKpi extends StatelessWidget {
  const _MalzemeKpi({
    required this.renk,
    required this.icon,
    required this.deger,
    required this.baslik,
  });

  final Color renk;
  final IconData icon;
  final String deger;
  final String baslik;

  @override
  Widget build(BuildContext context) {
    final yazi = _mz(context, 11);
    return Container(
      padding: EdgeInsets.fromLTRB(_mz(context, 8), _mz(context, 8), _mz(context, 6), _mz(context, 8)),
      decoration: BoxDecoration(color: renk, borderRadius: BorderRadius.circular(_mz(context, 12))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: _mz(context, 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: _mz(context, 16)),
                SizedBox(width: _mz(context, 4)),
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      deger,
                      style: TextStyle(fontFamily: 'Rajdhani', fontWeight: FontWeight.w700, fontSize: _mz(context, 20), height: 1, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: _mz(context, 4)),
          Text(
            baslik,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontFamily: 'Inter', fontSize: yazi, height: 1.15, fontWeight: FontWeight.w600, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _MalzemeAksiyonlar extends StatelessWidget {
  const _MalzemeAksiyonlar();

  @override
  Widget build(BuildContext context) {
    const aksiyonlar = <(Key?, String)>[
      (Key('malzeme-open-gelen'), 'Malzeme Girişi'),
      (Key('malzeme-open-tuketim'), 'Tüketim Kaydı'),
      (null, 'Transfer'),
      (null, 'Stok Sayımı'),
    ];
    return SizedBox(
      height: _mz(context, _kMalzemeSerit),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: aksiyonlar.length,
        separatorBuilder: (_, __) => SizedBox(width: _mz(context, 8)),
        itemBuilder: (context, index) {
          final (anahtar, etiket) = aksiyonlar[index];
          return _MalzemeSekmeCip(
            key: anahtar,
            label: etiket,
            secili: false,
            onTap: () => _keepInPro(context),
          );
        },
      ),
    );
  }
}

class _MalzemeArama extends StatelessWidget {
  const _MalzemeArama({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final h = _mz(context, _kMalzemeSerit);
    return SizedBox(
      height: h,
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: _mz(context, 10)),
              decoration: BoxDecoration(
                color: const Color(0xFF121826),
                borderRadius: BorderRadius.circular(_mz(context, 12)),
                border: Border.all(color: const Color(0xFF243044)),
              ),
              child: Row(
                children: [
                  Icon(Icons.search, color: ProColors.textMuted, size: _mz(context, 18)),
                  SizedBox(width: _mz(context, 6)),
                  Expanded(
                    child: TextField(
                      controller: controller,
                      onChanged: onChanged,
                      style: TextStyle(fontFamily: 'Inter', fontSize: _mz(context, 13), color: ProColors.text),
                      decoration: InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        hintText: 'Malzeme ara...',
                        hintStyle: TextStyle(fontFamily: 'Inter', fontSize: _mz(context, 13), color: ProColors.textMuted),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(width: _mz(context, 6)),
          _KareAksiyon(icon: Icons.qr_code_scanner, onTap: () => _keepInPro(context)),
          SizedBox(width: _mz(context, 6)),
          _KareAksiyon(icon: Icons.tune, etiket: 'Filtrele', onTap: () => _keepInPro(context)),
        ],
      ),
    );
  }
}

class _KareAksiyon extends StatelessWidget {
  const _KareAksiyon({required this.icon, required this.onTap, this.etiket});

  final IconData icon;
  final VoidCallback onTap;
  final String? etiket;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF121826),
      borderRadius: BorderRadius.circular(_mz(context, 10)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(_mz(context, 10)),
        child: Container(
          height: _mz(context, _kMalzemeSerit),
          padding: EdgeInsets.symmetric(horizontal: _mz(context, etiket == null ? 12 : 10)),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_mz(context, 10)),
            border: Border.all(color: const Color(0xFF243044)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: _mz(context, 18), color: ProColors.text),
              if (etiket != null) ...[
                SizedBox(width: _mz(context, 4)),
                Text(etiket!, style: TextStyle(fontFamily: 'Inter', fontSize: _mz(context, 13), fontWeight: FontWeight.w600, color: ProColors.text)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DusukStokKart extends StatelessWidget {
  const _DusukStokKart({required this.kalemler});

  final List<_DusukStokKalem> kalemler;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(_mz(context, 10)),
      decoration: BoxDecoration(
        color: const Color(0xFF121826),
        borderRadius: BorderRadius.circular(_mz(context, 14)),
        border: Border.all(color: const Color(0xFF243044)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: const Color(0xFFF87171), size: _mz(context, 16)),
              SizedBox(width: _mz(context, 6)),
              Text(
                'Düşük Stok (${kalemler.length})',
                style: TextStyle(fontFamily: 'Rajdhani', fontWeight: FontWeight.w700, fontSize: _mz(context, 15), color: ProColors.text),
              ),
              const Spacer(),
              Flexible(
                child: Text(
                  'Min. seviyenin altındaki malzemeler',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: TextStyle(fontFamily: 'Inter', fontSize: _mz(context, 9), color: ProColors.textMuted),
                ),
              ),
            ],
          ),
          SizedBox(height: _mz(context, 8)),
          if (kalemler.isEmpty)
            Text('Eşleşen malzeme yok.', style: TextStyle(fontFamily: 'Inter', fontSize: _mz(context, 12), color: ProColors.textMuted))
          else
            for (var i = 0; i < kalemler.length; i++) ...[
              if (i > 0) SizedBox(height: _mz(context, 8)),
              _DusukStokSatir(kalem: kalemler[i]),
            ],
        ],
      ),
    );
  }
}

class _DusukStokSatir extends StatelessWidget {
  const _DusukStokSatir({required this.kalem});

  final _DusukStokKalem kalem;

  @override
  Widget build(BuildContext context) {
    final g = _mz(context, 36);
    return Row(
      children: [
        Container(
          width: g,
          height: g,
          decoration: BoxDecoration(color: kalem.renk.withValues(alpha: 0.35), borderRadius: BorderRadius.circular(_mz(context, 8))),
          child: Icon(kalem.icon, color: Colors.white, size: _mz(context, 16)),
        ),
        SizedBox(width: _mz(context, 8)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                kalem.ad,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontFamily: 'Inter', fontSize: _mz(context, 12), fontWeight: FontWeight.w600, color: ProColors.text),
              ),
              Text(
                kalem.grup,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontFamily: 'Inter', fontSize: _mz(context, 10), color: ProColors.textMuted),
              ),
            ],
          ),
        ),
        SizedBox(width: _mz(context, 6)),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(kalem.miktar, style: TextStyle(fontFamily: 'Inter', fontSize: _mz(context, 12), fontWeight: FontWeight.w700, color: ProColors.text)),
            Text(kalem.min, style: TextStyle(fontFamily: 'Inter', fontSize: _mz(context, 9), color: ProColors.textMuted)),
          ],
        ),
        SizedBox(width: _mz(context, 6)),
        Container(
          padding: EdgeInsets.symmetric(horizontal: _mz(context, 6), vertical: _mz(context, 3)),
          decoration: BoxDecoration(
            color: const Color(0xFF3F1218),
            borderRadius: BorderRadius.circular(_mz(context, 8)),
            border: Border.all(color: const Color(0xFFEF4444)),
          ),
          child: Text(
            'Düşük Stok',
            style: TextStyle(fontFamily: 'Inter', fontSize: _mz(context, 8), fontWeight: FontWeight.w700, color: const Color(0xFFFCA5A5)),
          ),
        ),
        Icon(Icons.chevron_right, size: _mz(context, 16), color: ProColors.textFaint),
      ],
    );
  }
}

class _SonIslemler extends StatelessWidget {
  const _SonIslemler({required this.islemler, required this.filtre, required this.onTemizle, required this.onFiltre});

  final List<_MalzemeIslem> islemler;
  final _MalzemeIslemTur? filtre;
  final VoidCallback onTemizle;
  final ValueChanged<_MalzemeIslemTur> onFiltre;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Son İşlemler',
              style: TextStyle(fontFamily: 'Rajdhani', fontWeight: FontWeight.w700, fontSize: _mz(context, 16), color: ProColors.text),
            ),
            SizedBox(width: _mz(context, 8)),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                reverse: true,
                child: Row(
                  children: [
                    _IslemCip(etiket: 'Tümü', secili: filtre == null, onTap: onTemizle),
                    SizedBox(width: _mz(context, 4)),
                    for (final tur in _MalzemeIslemTur.values) ...[
                      _IslemCip(etiket: _islemAd(tur), secili: filtre == tur, onTap: () => onFiltre(tur)),
                      SizedBox(width: _mz(context, 4)),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: _mz(context, 8)),
        if (islemler.isEmpty)
          const _MalzemeBos('Eşleşen işlem yok.', 'Aramayı veya filtreyi değiştirin.')
        else
          for (var i = 0; i < islemler.length; i++) ...[
            if (i > 0) SizedBox(height: _mz(context, 8)),
            _IslemKarti(islem: islemler[i]),
          ],
      ],
    );
  }
}

class _IslemCip extends StatelessWidget {
  const _IslemCip({required this.etiket, required this.secili, required this.onTap});

  final String etiket;
  final bool secili;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: secili ? const Color(0xFF2563EB) : const Color(0xFF121826),
      borderRadius: BorderRadius.circular(_mz(context, 12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(_mz(context, 12)),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: _mz(context, 8), vertical: _mz(context, 4)),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_mz(context, 12)),
            border: Border.all(color: secili ? const Color(0xFF2563EB) : const Color(0xFF243044)),
          ),
          child: Text(
            etiket,
            style: TextStyle(fontFamily: 'Inter', fontSize: _mz(context, 10), fontWeight: FontWeight.w600, color: secili ? Colors.white : ProColors.textMuted),
          ),
        ),
      ),
    );
  }
}

String _islemAd(_MalzemeIslemTur tur) => switch (tur) {
      _MalzemeIslemTur.giris => 'Giriş',
      _MalzemeIslemTur.tuketim => 'Tüketim',
      _MalzemeIslemTur.transfer => 'Transfer',
    };

(Color, IconData) _islemGorsel(_MalzemeIslemTur tur) => switch (tur) {
      _MalzemeIslemTur.giris => (const Color(0xFF16A34A), Icons.login),
      _MalzemeIslemTur.tuketim => (const Color(0xFF2563EB), Icons.north_east),
      _MalzemeIslemTur.transfer => (const Color(0xFF7C3AED), Icons.swap_horiz),
    };

class _IslemKarti extends StatelessWidget {
  const _IslemKarti({required this.islem});

  final _MalzemeIslem islem;

  @override
  Widget build(BuildContext context) {
    final (renk, icon) = _islemGorsel(islem.tur);
    final g = _mz(context, 28);
    return Container(
      padding: EdgeInsets.all(_mz(context, 10)),
      decoration: BoxDecoration(
        color: const Color(0xFF121826),
        borderRadius: BorderRadius.circular(_mz(context, 12)),
        border: Border.all(color: const Color(0xFF243044)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: g,
            height: g,
            decoration: BoxDecoration(color: renk.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(_mz(context, 8))),
            child: Icon(icon, size: _mz(context, 14), color: renk),
          ),
          SizedBox(width: _mz(context, 8)),
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_islemAd(islem.tur), style: TextStyle(fontFamily: 'Inter', fontSize: _mz(context, 12), fontWeight: FontWeight.w700, color: ProColors.text)),
                Text(islem.tarih, style: TextStyle(fontFamily: 'Inter', fontSize: _mz(context, 9), color: ProColors.textMuted)),
              ],
            ),
          ),
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(islem.ad, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontFamily: 'Inter', fontSize: _mz(context, 12), fontWeight: FontWeight.w600, color: ProColors.text)),
                Text(islem.miktar, style: TextStyle(fontFamily: 'Inter', fontSize: _mz(context, 11), color: ProColors.text)),
                Text(islem.yer, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontFamily: 'Inter', fontSize: _mz(context, 10), color: ProColors.textMuted)),
              ],
            ),
          ),
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(islem.taraf, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.right, style: TextStyle(fontFamily: 'Inter', fontSize: _mz(context, 11), color: ProColors.text)),
                Text(islem.belge, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.right, style: TextStyle(fontFamily: 'Inter', fontSize: _mz(context, 10), color: ProColors.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _IslemListesi extends StatelessWidget {
  const _IslemListesi({required this.baslik, required this.islemler});

  final String baslik;
  final List<_MalzemeIslem> islemler;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(baslik, style: TextStyle(fontFamily: 'Rajdhani', fontWeight: FontWeight.w700, fontSize: _mz(context, 16), color: ProColors.text)),
        SizedBox(height: _mz(context, 8)),
        if (islemler.isEmpty)
          const _MalzemeBos('Kayıt yok.', 'Bu türde hareket bulunmuyor.')
        else
          for (var i = 0; i < islemler.length; i++) ...[
            if (i > 0) SizedBox(height: _mz(context, 8)),
            _IslemKarti(islem: islemler[i]),
          ],
      ],
    );
  }
}

class _MalzemeRaporlar extends StatelessWidget {
  const _MalzemeRaporlar();

  @override
  Widget build(BuildContext context) {
    final ara = _mz(context, 6);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Expanded(child: _RaporKutu(icon: Icons.bar_chart_rounded, renk: Color(0xFF2563EB), baslik: 'Stok Raporu', alt: 'Güncel stok durumu')),
        SizedBox(width: ara),
        const Expanded(child: _RaporKutu(icon: Icons.pie_chart_outline, renk: Color(0xFF2563EB), baslik: 'Tüketim Analizi', alt: 'İmalat bazlı tüketim')),
        SizedBox(width: ara),
        const Expanded(child: _RaporKutu(icon: Icons.description_outlined, renk: Color(0xFF64748B), baslik: 'Malzeme Listesi', alt: 'Tüm malzemeler')),
        SizedBox(width: ara),
        const Expanded(child: _RaporKutu(icon: Icons.file_download_outlined, renk: Color(0xFF16A34A), baslik: 'Excel / PDF', alt: 'Rapor indir')),
      ],
    );
  }
}

class _RaporKutu extends StatelessWidget {
  const _RaporKutu({required this.icon, required this.renk, required this.baslik, required this.alt});

  final IconData icon;
  final Color renk;
  final String baslik;
  final String alt;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF121826),
      borderRadius: BorderRadius.circular(_mz(context, 12)),
      child: InkWell(
        onTap: () => _keepInPro(context),
        borderRadius: BorderRadius.circular(_mz(context, 12)),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: _mz(context, 4), vertical: _mz(context, 10)),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_mz(context, 12)),
            border: Border.all(color: const Color(0xFF243044)),
          ),
          child: Column(
            children: [
              Icon(icon, color: renk, size: _mz(context, 18)),
              SizedBox(height: _mz(context, 6)),
              Text(
                baslik,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontFamily: 'Inter', fontSize: _mz(context, 10), fontWeight: FontWeight.w700, height: 1.15, color: ProColors.text),
              ),
              SizedBox(height: _mz(context, 2)),
              Text(
                alt,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontFamily: 'Inter', fontSize: _mz(context, 8), height: 1.15, color: ProColors.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MalzemeBos extends StatelessWidget {
  const _MalzemeBos(this.baslik, this.govde);

  final String baslik;
  final String govde;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(_mz(context, 14)),
      decoration: BoxDecoration(
        color: const Color(0xFF121826),
        borderRadius: BorderRadius.circular(_mz(context, 12)),
        border: Border.all(color: const Color(0xFF243044)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(baslik, style: TextStyle(fontFamily: 'Inter', fontSize: _mz(context, 13), fontWeight: FontWeight.w600, color: ProColors.text)),
          SizedBox(height: _mz(context, 4)),
          Text(govde, style: TextStyle(fontFamily: 'Inter', fontSize: _mz(context, 12), color: ProColors.textMuted)),
        ],
      ),
    );
  }
}
