part of 'dashboard_screen.dart';

const _kYeniImalatTipSari = Color(0xFFEAB308);

class _YeniImalatTipiDesk extends StatefulWidget {
  const _YeniImalatTipiDesk({
    required this.baslangicAnaTur,
    required this.baslangicBolum,
    required this.ozelTipler,
    required this.onBack,
    required this.onOlustur,
  });

  final _ImalatAnaTur baslangicAnaTur;
  final String? baslangicBolum;
  final List<_ImalatAltTurTanim> ozelTipler;
  final VoidCallback onBack;
  final ValueChanged<_ImalatAltTurTanim> onOlustur;

  @override
  State<_YeniImalatTipiDesk> createState() => _YeniImalatTipiDeskState();
}

class _YeniImalatTipiDeskState extends State<_YeniImalatTipiDesk> {
  late _ImalatAnaTur _anaTur = widget.baslangicAnaTur;
  late final TextEditingController _bolumAd = TextEditingController(
    text: _gecerliBolum(widget.baslangicAnaTur, widget.baslangicBolum, widget.ozelTipler),
  );
  final _bolumFocus = FocusNode();
  final _tipAdi = TextEditingController();
  final _tipAdiFocus = FocusNode();

  static String _gecerliBolum(_ImalatAnaTur ana, String? aday, List<_ImalatAltTurTanim> ozel) {
    final adlar = _imalatBolumAdlari(ana, ozel);
    if (aday != null && adlar.contains(aday)) return aday;
    return adlar.first;
  }

  String? get _hazirBolum => _imalatBolumEsle(_bolumAd.text, _anaTur, widget.ozelTipler);

  List<_ImalatAltTurTanim> get _mevcutAltTipler {
    final bolum = _hazirBolum;
    if (bolum == null) return const [];
    return _imalatTipBolumleri(_anaTur, widget.ozelTipler)[bolum] ?? const [];
  }

  @override
  void dispose() {
    _bolumAd.dispose();
    _bolumFocus.dispose();
    _tipAdi.dispose();
    _tipAdiFocus.dispose();
    super.dispose();
  }

  Future<void> _grupSec() async {
    final secilen = await showModalBottomSheet<_ImalatAnaTur>(
      context: context,
      backgroundColor: const Color(0xFF0B1220),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final ana in _ImalatAnaTur.values)
              ListTile(
                key: Key('yeni-imalat-tip-grup-${ana.deskKey}'),
                leading: Icon(ana.icon, color: ana.color),
                title: Text(ana.label, style: const TextStyle(fontFamily: 'Inter', fontSize: 15, color: ProColors.text)),
                trailing: ana == _anaTur ? const Icon(Icons.check, color: Color(0xFF2563EB)) : null,
                onTap: () => Navigator.pop(context, ana),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (secilen == null || secilen == _anaTur) return;
    setState(() {
      _anaTur = secilen;
      _bolumAd.text = _gecerliBolum(secilen, _hazirBolum, widget.ozelTipler);
    });
  }

  Future<void> _bolumSec() async {
    final adlar = _imalatBolumAdlari(_anaTur, widget.ozelTipler);
    final secilen = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: const Color(0xFF0B1220),
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.7),
          child: ListView(
            shrinkWrap: true,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 14, 16, 6),
                child: Text(
                  'Hazır imalat tipleri',
                  style: TextStyle(fontFamily: 'Rajdhani', fontWeight: FontWeight.w700, fontSize: 16, color: ProColors.text),
                ),
              ),
              for (final bolum in adlar)
                ListTile(
                  key: Key('yeni-imalat-tip-bolum-$bolum'),
                  title: Text(bolum, style: const TextStyle(fontFamily: 'Inter', fontSize: 15, color: ProColors.text)),
                  subtitle: Text(
                    '${(_imalatTipBolumleri(_anaTur, widget.ozelTipler)[bolum] ?? const []).length} alt tip',
                    style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: ProColors.textMuted),
                  ),
                  trailing: bolum == _hazirBolum ? const Icon(Icons.check, color: Color(0xFF2563EB)) : null,
                  onTap: () => Navigator.pop(context, bolum),
                ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
    if (secilen != null) {
      setState(() => _bolumAd.text = secilen);
    }
  }

  void _olustur() {
    final yazilan = _bolumAd.text.trim();
    if (yazilan.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('İmalat tipi seçin veya yazın.')),
      );
      return;
    }
    final bolum = _hazirBolum ?? yazilan;
    final ad = _tipAdi.text.trim();
    if (ad.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Alt tip adı girin.')),
      );
      return;
    }
    widget.onOlustur(
      _ImalatAltTurTanim(
        id: _imalatOzelTipId(),
        label: ad,
        ana: _anaTur,
        bolum: bolum,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final alt = MediaQuery.viewPaddingOf(context).bottom;
    final klavye = MediaQuery.viewInsetsOf(context).bottom;

    return ListView(
      padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + alt + klavye),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [
        _ModulDeskUst(
          title: 'Yeni İmalat Tipi',
          moduleIcon: Icons.bar_chart_rounded,
          moduleColor: const Color(0xFF0D9488),
          backKey: const Key('yeni-imalat-tip-back'),
          onBack: widget.onBack,
          backLabel: 'İmalat Tipi',
          trailing: const SizedBox.shrink(),
        ),
        const SizedBox(height: 6),
        const Text(
          'Seçtiğiniz listenin altına yeni bir alt tip ekleyin.',
          style: TextStyle(fontFamily: 'Inter', fontSize: 12, height: 1.35, color: ProColors.textMuted),
        ),
        const SizedBox(height: 16),
        const _YitBolumBaslik(icon: Icons.category_outlined, renk: Color(0xFF0D9488), baslik: 'İmalat Grubu'),
        const SizedBox(height: 8),
        _GirisHucreOdak(
          onTap: _grupSec,
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Icon(_anaTur.icon, size: 20, color: _anaTur.color),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _anaTur.label,
                  style: const TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w500, color: ProColors.text),
                ),
              ),
              const Icon(Icons.keyboard_arrow_down, color: ProColors.textMuted),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const _YitBolumBaslik(icon: Icons.account_tree_outlined, renk: Color(0xFF2563EB), baslik: 'İmalat Tipi'),
        const SizedBox(height: 8),
        _GirisHucreOdak(
          focusNode: _bolumFocus,
          baglaFocus: false,
          padding: const EdgeInsets.only(left: 12),
          child: Row(
            children: [
              const Icon(Icons.folder_outlined, size: 20, color: Color(0xFF2563EB)),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  key: const Key('yeni-imalat-tip-bolum-ad'),
                  controller: _bolumAd,
                  focusNode: _bolumFocus,
                  style: const TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w500, color: ProColors.text),
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    hintText: 'Listeden seçin veya yazın',
                    hintStyle: TextStyle(fontFamily: 'Inter', fontSize: 14, color: ProColors.textMuted),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 14),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              IconButton(
                key: const Key('yeni-imalat-tip-bolum-ac'),
                onPressed: _bolumSec,
                icon: const Icon(Icons.keyboard_arrow_down, color: ProColors.textMuted),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _hazirBolum == null
              ? 'Hazır listeden seçin veya yeni bir imalat tipi yazın.'
              : 'Hazır listeden seçildi. Altına yeni bir alt tip eklenir.',
          style: const TextStyle(fontFamily: 'Inter', fontSize: 11, height: 1.35, color: ProColors.textMuted),
        ),
        if (_hazirBolum != null) ...[
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          decoration: BoxDecoration(
            color: const Color(0xFF121826),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF243044)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mevcut alt tipler · ${_mevcutAltTipler.length}',
                style: const TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w600, color: ProColors.textMuted),
              ),
              const SizedBox(height: 6),
              for (final tip in _mevcutAltTipler)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Text(
                    tip.label,
                    style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: ProColors.text),
                  ),
                ),
            ],
          ),
        ),
        ],
        const SizedBox(height: 16),
        const _YitBolumBaslik(icon: Icons.format_list_bulleted, renk: Color(0xFF2563EB), baslik: 'Alt Tip Adı'),
        const SizedBox(height: 8),
        _GirisHucreOdak(
          focusNode: _tipAdiFocus,
          baglaFocus: false,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: TextField(
            key: const Key('imalat-yeni-tip-ad'),
            controller: _tipAdi,
            focusNode: _tipAdiFocus,
            style: const TextStyle(fontFamily: 'Inter', fontSize: 14, color: ProColors.text),
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              hintText: 'Örn. Gazbeton Duvar',
              hintStyle: TextStyle(fontFamily: 'Inter', fontSize: 14, color: ProColors.textMuted),
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 10),
            ),
            onSubmitted: (_) => _olustur(),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _hazirBolum == null
              ? 'Yeni imalat tipinin ilk alt tipi olarak eklenir.'
              : 'Bu ad, $_hazirBolum listesine yeni alt tip olarak eklenir.',
          style: const TextStyle(fontFamily: 'Inter', fontSize: 11, height: 1.35, color: ProColors.textMuted),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            key: const Key('imalat-yeni-tip-olustur'),
            onPressed: _olustur,
            style: FilledButton.styleFrom(
              backgroundColor: _kYeniImalatTipSari,
              foregroundColor: const Color(0xFF0B1220),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.add, size: 20),
            label: const Text('Alt Tipi Ekle', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: 15)),
          ),
        ),
      ],
    );
  }
}

class _YitBolumBaslik extends StatelessWidget {
  const _YitBolumBaslik({required this.icon, required this.renk, required this.baslik, this.sag});

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
