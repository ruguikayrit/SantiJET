part of 'dashboard_screen.dart';

class _ImalatKayitEkleDesk extends StatefulWidget {
  const _ImalatKayitEkleDesk({
    required this.ozelTipler,
    this.seciliAltTurId,
    required this.onBack,
    required this.onOpenYeniTip,
    required this.onKaydet,
  });

  final List<_ImalatAltTurTanim> ozelTipler;
  final String? seciliAltTurId;
  final VoidCallback onBack;
  final void Function(_ImalatAnaTur ana, String bolum) onOpenYeniTip;
  final ValueChanged<_ImalatKayitTaslak> onKaydet;

  @override
  State<_ImalatKayitEkleDesk> createState() => _ImalatKayitEkleDeskState();
}

class _ImalatKayitEkleDeskState extends State<_ImalatKayitEkleDesk> {
  _ImalatAnaTur _anaTur = _ImalatAnaTur.insaat;
  late String _altTurId = widget.seciliAltTurId ?? _imalatVarsayilanTip(_ImalatAnaTur.insaat, widget.ozelTipler);

  @override
  void didUpdateWidget(covariant _ImalatKayitEkleDesk oldWidget) {
    super.didUpdateWidget(oldWidget);
    final yeniSecim = widget.seciliAltTurId;
    if (yeniSecim != null && yeniSecim != oldWidget.seciliAltTurId) {
      _altTurId = yeniSecim;
      final ana = _imalatAltTurBul(yeniSecim, widget.ozelTipler)?.ana;
      if (ana != null) _anaTur = ana;
    }
  }
  final _miktar = TextEditingController(text: '120');
  final _not = TextEditingController();
  final _notFocus = FocusNode();
  final _fotolar = <int>[0, 1, 2];

  @override
  void dispose() {
    _miktar.dispose();
    _not.dispose();
    _notFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final alt = MediaQuery.viewPaddingOf(context).bottom;
    final notLen = _not.text.length;

    return ListView(
      padding: EdgeInsets.fromLTRB(16, 8, 16, 12 + alt),
      children: [
        _ModulDeskUst(
          title: 'İmalat Kaydı Ekle',
          moduleIcon: Icons.bar_chart_rounded,
          moduleColor: const Color(0xFF0D9488),
          backKey: const Key('imalat-kayit-back'),
          onBack: widget.onBack,
          backLabel: 'İmalat',
          trailing: const SizedBox.shrink(),
        ),
        const SizedBox(height: 6),
        const Text(
          'Sahada yapılan imalatı hızlıca kaydedin.',
          style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: ProColors.textMuted),
        ),
        const SizedBox(height: 12),
        const _IkBolumBaslik(icon: Icons.category_outlined, renk: Color(0xFF0D9488), baslik: 'İmalat Grubu'),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final ana in _ImalatAnaTur.values) ...[
                _IkTurKart(
                  key: Key('imalat-ekle-ana-${ana.deskKey}'),
                  baslik: ana.label,
                  icon: ana.icon,
                  renk: ana.color,
                  secili: ana == _anaTur,
                  onTap: () {
                    setState(() {
                      _anaTur = ana;
                      _altTurId = _imalatVarsayilanTip(ana, widget.ozelTipler);
                    });
                  },
                ),
                const SizedBox(width: 6),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),
        const _IkBolumBaslik(
          icon: Icons.subdirectory_arrow_right,
          renk: Color(0xFF0D9488),
          baslik: 'İmalat Tipi',
        ),
        const SizedBox(height: 8),
        _ImalatTipAccordiyon(
          anaTur: _anaTur,
          ozelTipler: widget.ozelTipler,
          seciliTipId: _altTurId,
          onTipSec: (id) => setState(() => _altTurId = id),
          onYeniTip: () {
            final bolum = _imalatAltTurBul(_altTurId, widget.ozelTipler)?.bolum;
            final adlar = _imalatBolumAdlari(_anaTur, widget.ozelTipler);
            widget.onOpenYeniTip(_anaTur, bolum != null && adlar.contains(bolum) ? bolum : adlar.first);
          },
        ),
        const SizedBox(height: 14),
        const _IkBolumBaslik(icon: Icons.format_list_bulleted, baslik: 'İş Kalemi'),
        const SizedBox(height: 10),
        _IkAlan(deger: 'Kalıp İmalatı'),
        const SizedBox(height: 14),
        const _IkBolumBaslik(icon: Icons.location_on_outlined, baslik: 'Konum'),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _IkAlan(deger: 'A Blok', kucuk: true)),
            const SizedBox(width: 6),
            Expanded(child: _IkAlan(deger: '2. Kat', kucuk: true)),
            const SizedBox(width: 6),
            Expanded(child: _IkAlan(deger: 'Bölge / Mahal', kucuk: true, soluk: true)),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: _IkMiktarAlani(controller: _miktar),
            ),
            const SizedBox(width: 6),
            const Expanded(child: _IkPlanlananKpi()),
            const SizedBox(width: 6),
            const Expanded(child: _IkGerceklesmeKpi()),
          ],
        ),
        const SizedBox(height: 14),
        const _IkBolumBaslik(icon: Icons.groups_outlined, renk: Color(0xFF22C55E), baslik: 'Ekip / Personel'),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(flex: 3, child: _IkAlan(deger: 'Kalıp Ekibi', ikon: Icons.engineering_outlined)),
            const SizedBox(width: 6),
            const Expanded(child: _IkSayiKutusu(deger: '8 kişi')),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'Personel bilgisi puantajdan otomatik gelir.',
          style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: ProColors.textMuted),
        ),
        const SizedBox(height: 14),
        const _IkBolumBaslik(icon: Icons.agriculture_outlined, renk: Color(0xFFF59E0B), baslik: 'Ekipman'),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(flex: 3, child: _IkAlan(deger: 'Kule Vinç', ikon: Icons.precision_manufacturing_outlined)),
            const SizedBox(width: 6),
            const Expanded(child: _IkSayiKutusu(deger: '1 adet')),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'Seçilen tarihte sahada kullanılan ekipmanlar listelenir.',
          style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: ProColors.textMuted),
        ),
        const SizedBox(height: 14),
        _IkBolumBaslik(
          icon: Icons.photo_camera_outlined,
          renk: const Color(0xFF7C3AED),
          baslik: 'İmalat Fotoğrafları (Opsiyonel)',
          sag: '${_fotolar.length}/10',
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              if (_fotolar.length < 10)
                _IkFotoEkle(
                  onTap: () {
                    if (_fotolar.length >= 10) return;
                    setState(() => _fotolar.add(_fotolar.length));
                  },
                ),
              if (_fotolar.length < 10) const SizedBox(width: 8),
              for (var i = 0; i < _fotolar.length; i++) ...[
                _IkFotoThumb(
                  variant: _fotolar[i],
                  onSil: () => setState(() => _fotolar.removeAt(i)),
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),
        const _IkBolumBaslik(icon: Icons.notes_outlined, baslik: 'Not (Opsiyonel)'),
        const SizedBox(height: 10),
        _GirisHucreOdak(
          focusNode: _notFocus,
          baglaFocus: false,
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _not,
                focusNode: _notFocus,
                onChanged: (_) => setState(() {}),
                maxLines: 4,
                maxLength: 500,
                style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: ProColors.text),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  counterText: '',
                  hintText: 'İmalat ile ilgili not ekleyin…',
                  hintStyle: TextStyle(fontFamily: 'Inter', fontSize: 11, color: ProColors.textMuted),
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '$notLen/500',
                  style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: ProColors.textMuted),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            key: const Key('imalat-kaydet'),
            style: FilledButton.styleFrom(
              backgroundColor: ProColors.electricBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => widget.onKaydet(
                  _ImalatKayitTaslak(
                    anaTur: _anaTur,
                    altTurId: _altTurId,
                    isKalemi: '${_imalatAltTurBul(_altTurId, widget.ozelTipler)?.label ?? 'İmalat'} imalatı',
                  ),
                ),
            icon: const Icon(Icons.check, size: 20),
            label: const Text('Kaydet', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 15)),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _IkBolumBaslik extends StatelessWidget {
  const _IkBolumBaslik({
    required this.icon,
    this.renk = ProColors.electricBlue,
    required this.baslik,
    this.sag,
  });

  final IconData icon;
  final Color renk;
  final String baslik;
  final String? sag;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: renk),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            baslik,
            style: const TextStyle(fontFamily: 'Rajdhani', fontWeight: FontWeight.w700, fontSize: 16, color: ProColors.text),
          ),
        ),
        if (sag != null)
          Text(sag!, style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: ProColors.textMuted)),
      ],
    );
  }
}

/// İmalat listesi kategori kartından biraz geniş; etiket okunaklı kalsın.
const _kIkTurKartGenislik = 100.0;
const _kIkTurKartYukseklik = 88.0;

class _IkTurKart extends StatelessWidget {
  const _IkTurKart({
    super.key,
    required this.baslik,
    required this.icon,
    required this.renk,
    required this.secili,
    required this.onTap,
  });

  final String baslik;
  final IconData icon;
  final Color renk;
  final bool secili;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _kIkTurKartGenislik,
      height: _kIkTurKartYukseklik,
      child: Material(
        color: const Color(0xFF121826),
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: secili ? renk : const Color(0xFF243044), width: secili ? 1.5 : 1),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 22, color: renk),
                const SizedBox(height: 6),
                Text(
                  baslik,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    height: 1.15,
                    fontWeight: secili ? FontWeight.w600 : FontWeight.w500,
                    color: secili ? ProColors.text : ProColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _IkAlan extends StatelessWidget {
  const _IkAlan({required this.deger, this.kucuk = false, this.soluk = false, this.ikon});

  final String deger;
  final bool kucuk;
  final bool soluk;
  final IconData? ikon;

  @override
  Widget build(BuildContext context) {
    return _GirisHucreOdak(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      onTap: () => _keepInPro(context),
      child: Row(
        children: [
          if (ikon != null) ...[
            Icon(ikon, size: 16, color: ProColors.textMuted),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              deger,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: kucuk ? 12 : 13,
                fontWeight: soluk ? FontWeight.w400 : FontWeight.w600,
                color: soluk ? ProColors.textMuted : ProColors.text,
              ),
            ),
          ),
          if (!soluk) const Icon(Icons.keyboard_arrow_down, size: 18, color: ProColors.textMuted),
        ],
      ),
    );
  }
}

/// Referans mockup: başlık + mavi çerçeve, alt satırda miktar ve birim.
const _kIkMiktarSatirYukseklik = 100.0;
const _kIkGerceklesmeHalkaBoyut = 48.0 * 1.2;
const _kIkGerceklesmeHalkaStroke = 4.0 * 1.2;
const _kIkGerceklesmeYuzdeFont = 11.0;

class _IkMiktarAlani extends StatefulWidget {
  const _IkMiktarAlani({required this.controller});

  final TextEditingController controller;

  @override
  State<_IkMiktarAlani> createState() => _IkMiktarAlaniState();
}

class _IkMiktarAlaniState extends State<_IkMiktarAlani> {
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final odakta = _focus.hasFocus;
    return _GirisHucreOdak(
      focusNode: _focus,
      baglaFocus: false,
      height: _kIkMiktarSatirYukseklik,
      padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
      fillColor: const Color(0xFF121826),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.view_in_ar_outlined, size: 14, color: odakta ? ProColors.electricBlue : ProColors.textMuted),
              const SizedBox(width: 5),
              const Text(
                'Gerçekleşen Miktar',
                style: TextStyle(fontFamily: 'Inter', fontSize: 10, fontWeight: FontWeight.w600, color: ProColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(Icons.add_circle_outline, size: 20, color: odakta ? ProColors.electricBlue : ProColors.textMuted),
                const SizedBox(width: 6),
                Expanded(
                  child: TextField(
                    controller: widget.controller,
                    focusNode: _focus,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(
                      fontFamily: 'Rajdhani',
                      fontWeight: FontWeight.w700,
                      fontSize: 28,
                      height: 1,
                      color: ProColors.text,
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.only(bottom: 4),
                      border: UnderlineInputBorder(borderSide: BorderSide(color: ProColors.border, width: 1)),
                      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: ProColors.border, width: 1)),
                      focusedBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: ProColors.electricBlue, width: 1.25),
                      ),
                    ),
                  ),
                ),
                Container(width: 1, height: 28, color: const Color(0xFF243044)),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0B1018),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF243044)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('m²', style: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w600, color: ProColors.text)),
                      Icon(Icons.keyboard_arrow_down, size: 16, color: ProColors.textMuted),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _IkPlanlananKpi extends StatelessWidget {
  const _IkPlanlananKpi();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _kIkMiktarSatirYukseklik,
      child: Container(
        padding: _kImalatMetrikKartPadding,
        decoration: BoxDecoration(
          color: const Color(0xFF121826),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF243044)),
        ),
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.account_balance_outlined, size: 15, color: Color(0xFF22C55E)),
                const SizedBox(height: 4),
                const Text('Planlanan', style: TextStyle(fontFamily: 'Inter', fontSize: 10, height: 1.1, color: ProColors.textMuted)),
                const SizedBox(height: 2),
                Text(
                  '120 m²',
                  style: _kImalatMetrikDegerStili.copyWith(fontSize: 18),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _IkGerceklesmeKpi extends StatelessWidget {
  const _IkGerceklesmeKpi();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _kIkMiktarSatirYukseklik,
      child: Container(
        padding: _kImalatMetrikKartPadding,
        decoration: BoxDecoration(
          color: const Color(0xFF121826),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF243044)),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Gerçekleşme', style: TextStyle(fontFamily: 'Inter', fontSize: 10, height: 1.1, color: ProColors.textMuted)),
              const SizedBox(height: 4),
              SizedBox(
                width: _kIkGerceklesmeHalkaBoyut,
                height: _kIkGerceklesmeHalkaBoyut,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: 1,
                      strokeWidth: _kIkGerceklesmeHalkaStroke,
                      backgroundColor: const Color(0xFF243044),
                      color: const Color(0xFF22C55E),
                    ),
                    const Text(
                      '%100',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: _kIkGerceklesmeYuzdeFont,
                        fontWeight: FontWeight.w700,
                        height: 1,
                        color: ProColors.text,
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

class _IkSayiKutusu extends StatelessWidget {
  const _IkSayiKutusu({required this.deger});

  final String deger;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: ProColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ProColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.person_outline, size: 14, color: ProColors.textMuted),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              deger,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w600, color: ProColors.text),
            ),
          ),
        ],
      ),
    );
  }
}

class _IkFotoEkle extends StatelessWidget {
  const _IkFotoEkle({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: CustomPaint(
        painter: const _KesikCerceve(),
        child: const SizedBox(
          width: 72,
          height: 72,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add, color: ProColors.textMuted, size: 20),
              SizedBox(height: 2),
              Text(
                'Fotoğraf\nEkle',
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: 'Inter', fontSize: 9, height: 1.15, color: ProColors.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IkFotoThumb extends StatelessWidget {
  const _IkFotoThumb({required this.variant, required this.onSil});

  final int variant;
  final VoidCallback onSil;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      height: 72,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: CustomPaint(
              size: const Size(72, 72),
              painter: _BoruPainter(variant, tespit: false),
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: onSil,
              child: Container(
                width: 16,
                height: 16,
                decoration: const BoxDecoration(color: Color(0xCC111827), shape: BoxShape.circle),
                child: const Icon(Icons.close, size: 10, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tüm tip listesi tek blokta açılır-kapanır; bölümler birbirinden bağımsız genişler.
class _ImalatTipAccordiyon extends StatefulWidget {
  const _ImalatTipAccordiyon({
    required this.anaTur,
    required this.ozelTipler,
    required this.seciliTipId,
    required this.onTipSec,
    required this.onYeniTip,
  });

  final _ImalatAnaTur anaTur;
  final List<_ImalatAltTurTanim> ozelTipler;
  final String seciliTipId;
  final ValueChanged<String> onTipSec;
  final VoidCallback onYeniTip;

  @override
  State<_ImalatTipAccordiyon> createState() => _ImalatTipAccordiyonState();
}

class _ImalatTipAccordiyonState extends State<_ImalatTipAccordiyon> {
  var _listeAcik = false;
  late final Set<String> _acikBolumler = () {
    final bolum = _imalatAltTurBul(widget.seciliTipId, widget.ozelTipler)?.bolum;
    return bolum == null ? <String>{} : {bolum};
  }();

  Map<String, List<_ImalatAltTurTanim>> get _bolumler => _imalatTipBolumleri(widget.anaTur, widget.ozelTipler);

  @override
  void didUpdateWidget(covariant _ImalatTipAccordiyon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.anaTur != widget.anaTur || oldWidget.ozelTipler.length != widget.ozelTipler.length) {
      final bolum = _imalatAltTurBul(widget.seciliTipId, widget.ozelTipler)?.bolum;
      _acikBolumler
        ..clear()
        ..addAll(bolum == null ? const [] : [bolum]);
      if (oldWidget.ozelTipler.length != widget.ozelTipler.length) _listeAcik = true;
    }
  }

  void _bolumAc(String bolum) {
    setState(() {
      if (_acikBolumler.contains(bolum)) {
        _acikBolumler.remove(bolum);
      } else {
        _acikBolumler.add(bolum);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final secili = _imalatAltTurBul(widget.seciliTipId, widget.ozelTipler);
    final bolumler = _bolumler;
    final bolumAdlari = bolumler.keys.toList();
    final tipAdet = _imalatAltTurlerAna(widget.anaTur, widget.ozelTipler).length;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF121826),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF243044)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            color: _listeAcik ? const Color(0xFF1A2332) : Colors.transparent,
            child: InkWell(
              key: const Key('imalat-tip-liste-ac'),
              onTap: () => setState(() => _listeAcik = !_listeAcik),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        secili != null ? 'Seçili: ${secili.label}' : 'İmalat tipi seçin',
                        style: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: ProColors.text),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text('$tipAdet tip', style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: ProColors.textFaint)),
                    const SizedBox(width: 4),
                    Icon(_listeAcik ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, size: 22, color: ProColors.textMuted),
                  ],
                ),
              ),
            ),
          ),
          if (_listeAcik) ...[
            const Divider(height: 1, thickness: 1, color: Color(0xFF243044)),
            for (var i = 0; i < bolumAdlari.length; i++) ...[
              if (i > 0) const Divider(height: 1, thickness: 1, color: Color(0xFF243044)),
              _ImalatTipBolumSatiri(
                bolum: bolumAdlari[i],
                tipler: bolumler[bolumAdlari[i]]!,
                acik: _acikBolumler.contains(bolumAdlari[i]),
                seciliTipId: widget.seciliTipId,
                onBaslikTap: () => _bolumAc(bolumAdlari[i]),
                onTipSec: (id) {
                  widget.onTipSec(id);
                  final yeniBolum = _imalatAltTurBul(id, widget.ozelTipler)?.bolum;
                  if (yeniBolum != null) {
                    setState(() => _acikBolumler.add(yeniBolum));
                  }
                },
              ),
            ],
            Material(
              color: Colors.transparent,
              child: InkWell(
                key: const Key('imalat-yeni-tip'),
                onTap: widget.onYeniTip,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add, size: 18, color: widget.anaTur.color),
                      const SizedBox(width: 6),
                      Text(
                        'Yeni imalat tipi',
                        style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: widget.anaTur.color),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ImalatTipBolumSatiri extends StatelessWidget {
  const _ImalatTipBolumSatiri({
    required this.bolum,
    required this.tipler,
    required this.acik,
    required this.seciliTipId,
    required this.onBaslikTap,
    required this.onTipSec,
  });

  final String bolum;
  final List<_ImalatAltTurTanim> tipler;
  final bool acik;
  final String seciliTipId;
  final VoidCallback onBaslikTap;
  final ValueChanged<String> onTipSec;

  @override
  Widget build(BuildContext context) {
    final bolumdeSecili = tipler.any((t) => t.id == seciliTipId);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: acik ? const Color(0xFF1A2332) : Colors.transparent,
          child: InkWell(
            onTap: onBaslikTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      bolum,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: acik || bolumdeSecili ? ProColors.text : ProColors.textMuted,
                      ),
                    ),
                  ),
                  Text(
                    '${tipler.length}',
                    style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: ProColors.textFaint),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    acik ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    size: 20,
                    color: ProColors.textMuted,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (acik)
          for (final tip in tipler)
            _ImalatTipSecenekSatiri(
              key: Key('imalat-ekle-alt-${tip.id}'),
              label: tip.label,
              secili: tip.id == seciliTipId,
              onTap: () => onTipSec(tip.id),
            ),
      ],
    );
  }
}

class _ImalatTipSecenekSatiri extends StatelessWidget {
  const _ImalatTipSecenekSatiri({super.key, required this.label, required this.secili, required this.onTap});

  final String label;
  final bool secili;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: secili ? const Color(0xFF2563EB).withValues(alpha: 0.12) : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
          child: SizedBox(
            height: 40,
            child: Row(
              children: [
                const SizedBox(width: 8),
                Icon(
                  secili ? Icons.radio_button_checked : Icons.radio_button_off,
                  size: 18,
                  color: secili ? const Color(0xFF2563EB) : ProColors.textFaint,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: secili ? FontWeight.w600 : FontWeight.w500,
                      color: secili ? ProColors.text : ProColors.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
