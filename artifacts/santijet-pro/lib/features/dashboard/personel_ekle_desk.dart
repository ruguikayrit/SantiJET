part of 'dashboard_screen.dart';

const _personelEkipler = [
  'Alçıpan Ekibi',
  'Alçı Ekibi',
  'Boya Ekibi',
  'Demir Ekibi',
  'Elektrik Ekibi',
];

const _personelMeslekler = [
  'İşçi',
  'Usta',
  'Alçıpan Ustası',
  'Boya Ustası',
  'Elektrik Ustası',
];

const _personelFirmalar = [
  'ABC Yapı Ltd. Şti.',
  'Kare İnşaat A.Ş.',
  'Demir Yapı Ltd. Şti.',
];

const _personelRenkler = [
  Color(0xFF2563EB),
  Color(0xFF7C3AED),
  Color(0xFFF97316),
  Color(0xFFEF4444),
  Color(0xFF0EA5E9),
  Color(0xFF22C55E),
];

const _personelAlanYazi = TextStyle(fontFamily: 'Inter', fontSize: 14, color: ProColors.text);
const _personelIpucu = TextStyle(fontFamily: 'Inter', fontSize: 14, color: ProColors.textFaint);
const _personelEtiket = TextStyle(fontFamily: 'Inter', fontSize: 13, color: ProColors.textMuted);
const _personelHata = TextStyle(fontFamily: 'Inter', fontSize: 13, color: Color(0xFFFCA5A5));

/// Yeni personel kaydı. Liste ile aynı masanın içindedir; kayıt o listenin belleğine yazılır.
class _PersonelEkleDesk extends StatefulWidget {
  const _PersonelEkleDesk({required this.onBack, required this.onSave});

  final VoidCallback onBack;
  final ValueChanged<_PersonelKayit> onSave;

  @override
  State<_PersonelEkleDesk> createState() => _PersonelEkleDeskState();
}

class _PersonelEkleDeskState extends State<_PersonelEkleDesk> {
  final _ad = TextEditingController();
  final _telefon = TextEditingController();
  final _iban = TextEditingController();
  final _tc = TextEditingController();
  final _adres = TextEditingController();
  final _notlar = TextEditingController();
  final _eksik = <String>{};

  String? _meslek;
  String? _ekip;
  String? _firma;
  String? _giris;
  String? _cikis;
  String? _dogum;

  @override
  void initState() {
    super.initState();
    _giris = _tarihYaz(DateTime.now());
  }

  @override
  void dispose() {
    _ad.dispose();
    _telefon.dispose();
    _iban.dispose();
    _tc.dispose();
    _adres.dispose();
    _notlar.dispose();
    super.dispose();
  }

  void _kaydet() {
    final eksik = <String>{};
    if (_ad.text.trim().isEmpty) eksik.add('ad');
    if (_meslek == null) eksik.add('meslek');
    if (_ekip == null) eksik.add('ekip');
    if (_firma == null) eksik.add('firma');
    if (_giris == null) eksik.add('giris');
    if (eksik.isNotEmpty) {
      setState(() {
        _eksik
          ..clear()
          ..addAll(eksik);
      });
      return;
    }
    final ad = _ad.text.trim();
    final renk = _personelRenkler[ad.codeUnits.fold<int>(0, (sum, unit) => sum + unit) % _personelRenkler.length];
    widget.onSave(
      _PersonelKayit(
        name: ad,
        unvan: _meslek!,
        ekip: _ekip!,
        firma: _firma!,
        giris: _giris!,
        cikis: _cikis,
        color: renk,
        calisan: _cikis == null,
        telefon: _bos(_telefon),
        iban: _bos(_iban),
        tc: _bos(_tc),
        dogum: _dogum,
        adres: _bos(_adres),
        notlar: _bos(_notlar),
      ),
    );
  }

  Future<void> _tarihSec({required String? mevcut, required ValueChanged<String> yaz}) async {
    final secilen = await showDatePicker(
      context: context,
      initialDate: _tarihOku(mevcut) ?? DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF2563EB),
              onPrimary: Colors.white,
              surface: Color(0xFF121826),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (!mounted || secilen == null) return;
    setState(() => yaz(_tarihYaz(secilen)));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            children: [
              _ModulDeskUst(
                title: 'Personel Ekle',
                moduleIcon: _ModulDeskMark.sahaIcon,
                moduleColor: _ModulDeskMark.sahaColor,
                backKey: const Key('personel-ekle-back'),
                onBack: widget.onBack,
                backLabel: 'Personel',
              ),
              const SizedBox(height: 8),
              const _PersonelEkleBaslik(),
              const SizedBox(height: 14),
              _PersonelBolum(
                no: '1',
                baslik: 'Temel Bilgiler',
                children: [
                  _PersonelEtiket(label: 'Ad Soyad', zorunlu: true),
                  TextField(
                    key: const Key('personel-ekle-ad'),
                    controller: _ad,
                    style: _personelAlanYazi,
                    textCapitalization: TextCapitalization.words,
                    decoration: _personelAlanDekor(hint: 'Ad ve soyad girin', icon: Icons.person_outline),
                    onChanged: (_) => _temizle('ad'),
                  ),
                  if (_eksik.contains('ad')) const _PersonelHataYazi('Ad Soyad gerekli.'),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const _PersonelEtiket(label: 'Meslek', zorunlu: true),
                            _PersonelSecim(
                              fieldKey: const Key('personel-ekle-meslek'),
                              icon: Icons.work_outline,
                              value: _meslek,
                              placeholder: 'Meslek seçin',
                              options: _personelMeslekler,
                              onSelected: (value) => setState(() {
                                _meslek = value;
                                _eksik.remove('meslek');
                              }),
                            ),
                            if (_eksik.contains('meslek')) const _PersonelHataYazi('Meslek seçin.'),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const _PersonelEtiket(label: 'Ekip', zorunlu: true),
                            _PersonelSecim(
                              fieldKey: const Key('personel-ekle-ekip'),
                              icon: Icons.groups_outlined,
                              value: _ekip,
                              placeholder: 'Ekip seçin',
                              options: _personelEkipler,
                              onSelected: (value) => setState(() {
                                _ekip = value;
                                _eksik.remove('ekip');
                              }),
                            ),
                            if (_eksik.contains('ekip')) const _PersonelHataYazi('Ekip seçin.'),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const _PersonelEtiket(label: 'Bağlı Firma', zorunlu: true),
                  _PersonelSecim(
                    fieldKey: const Key('personel-ekle-firma'),
                    icon: Icons.apartment_outlined,
                    value: _firma,
                    placeholder: 'Firma seçin',
                    options: _personelFirmalar,
                    onSelected: (value) => setState(() {
                      _firma = value;
                      _eksik.remove('firma');
                    }),
                  ),
                  if (_eksik.contains('firma')) const _PersonelHataYazi('Firma seçin.'),
                ],
              ),
              const SizedBox(height: 10),
              _PersonelBolum(
                no: '2',
                baslik: 'Çalışma Bilgileri',
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const _PersonelEtiket(label: 'İşe Giriş Tarihi', zorunlu: true),
                            _PersonelTarih(
                              value: _giris,
                              placeholder: 'Tarih seçin',
                              onPick: () => _tarihSec(
                                mevcut: _giris,
                                yaz: (value) {
                                  _giris = value;
                                  _eksik.remove('giris');
                                },
                              ),
                              onClear: () => setState(() => _giris = null),
                            ),
                            if (_eksik.contains('giris')) const _PersonelHataYazi('İşe giriş tarihi gerekli.'),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const _PersonelEtiket(label: 'İşten Çıkış Tarihi'),
                            _PersonelTarih(
                              value: _cikis,
                              placeholder: 'Tarih seçin',
                              onPick: () => _tarihSec(mevcut: _cikis, yaz: (value) => _cikis = value),
                              onClear: () => setState(() => _cikis = null),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline, size: 14, color: Color(0xFF60A5FA)),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Boş bırakılırsa personel aktif (çalışan) olarak kaydedilir.',
                          style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: ProColors.textMuted),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _PersonelBolum(
                no: '3',
                baslik: 'İletişim Bilgileri',
                children: [
                  const _PersonelEtiket(label: 'Telefon', not: 'Opsiyonel'),
                  TextField(
                    key: const Key('personel-ekle-telefon'),
                    controller: _telefon,
                    style: _personelAlanYazi,
                    keyboardType: TextInputType.phone,
                    decoration: _personelAlanDekor(hint: 'Telefon numarası girin', icon: Icons.phone_outlined),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _PersonelBolum(
                no: '4',
                baslik: 'Maaş ve Ödeme Bilgileri',
                children: [
                  const _PersonelEtiket(label: 'IBAN', not: 'Opsiyonel'),
                  TextField(
                    key: const Key('personel-ekle-iban'),
                    controller: _iban,
                    style: _personelAlanYazi,
                    textCapitalization: TextCapitalization.characters,
                    inputFormatters: const [_IbanMask()],
                    decoration: _personelAlanDekor(
                      hint: 'TR__ ____ ____ ____ ____ ____ __',
                      icon: Icons.credit_card_outlined,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _PersonelBolum(
                no: '5',
                baslik: 'Kimlik Bilgileri',
                opsiyonel: true,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const _PersonelEtiket(label: 'T.C. Kimlik No'),
                            TextField(
                              key: const Key('personel-ekle-tc'),
                              controller: _tc,
                              style: _personelAlanYazi,
                              keyboardType: TextInputType.number,
                              inputFormatters: const [_RakamMask(11)],
                              decoration: _personelAlanDekor(hint: 'T.C. kimlik no girin', icon: Icons.badge_outlined),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const _PersonelEtiket(label: 'Doğum Tarihi'),
                            _PersonelTarih(
                              value: _dogum,
                              placeholder: 'Tarih seçin',
                              onPick: () => _tarihSec(mevcut: _dogum, yaz: (value) => _dogum = value),
                              onClear: () => setState(() => _dogum = null),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _PersonelBolum(
                no: '6',
                baslik: 'Adres ve Notlar',
                opsiyonel: true,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const _PersonelEtiket(label: 'Adres'),
                            TextField(
                              controller: _adres,
                              style: _personelAlanYazi,
                              minLines: 1,
                              maxLines: 3,
                              decoration: _personelAlanDekor(hint: 'Adres girin', icon: Icons.location_on_outlined),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const _PersonelEtiket(label: 'Notlar'),
                            TextField(
                              controller: _notlar,
                              style: _personelAlanYazi,
                              minLines: 1,
                              maxLines: 3,
                              decoration: _personelAlanDekor(hint: 'Not ekleyin', icon: Icons.notes_outlined),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  key: const Key('personel-ekle-vazgec'),
                  onPressed: widget.onBack,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                    side: const BorderSide(color: Color(0xFF334155)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    'Vazgeç',
                    style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  key: const Key('personel-ekle-kaydet'),
                  onPressed: _kaydet,
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text(
                    'Kaydet',
                    style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _temizle(String alan) {
    if (_eksik.remove(alan)) setState(() {});
  }

  String? _bos(TextEditingController controller) {
    final text = controller.text.trim();
    return text.isEmpty ? null : text;
  }
}

class _PersonelEkleBaslik extends StatelessWidget {
  const _PersonelEkleBaslik();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        _PersonelEkleIsaret(),
        SizedBox(width: 12),
        Expanded(
          child: Text(
            'Yeni personel bilgilerini girin.',
            style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: ProColors.textMuted),
          ),
        ),
      ],
    );
  }
}

class _PersonelEkleIsaret extends StatelessWidget {
  const _PersonelEkleIsaret();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: const Color(0xFFE8A317),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.person_add_alt_1, color: Colors.white, size: 24),
    );
  }
}

class _PersonelBolum extends StatelessWidget {
  const _PersonelBolum({
    required this.no,
    required this.baslik,
    required this.children,
    this.opsiyonel = false,
  });

  final String no;
  final String baslik;
  final bool opsiyonel;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 22,
                height: 22,
                alignment: Alignment.center,
                decoration: const BoxDecoration(color: Color(0xFF2563EB), shape: BoxShape.circle),
                child: Text(
                  no,
                  style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: 12, color: Colors.white),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: baslik,
                        style: const TextStyle(fontFamily: 'Rajdhani', fontWeight: FontWeight.w700, fontSize: 16, color: ProColors.text),
                      ),
                      if (opsiyonel)
                        const TextSpan(
                          text: ' (Opsiyonel)',
                          style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w400, fontSize: 12, color: ProColors.textMuted),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}

class _PersonelEtiket extends StatelessWidget {
  const _PersonelEtiket({required this.label, this.zorunlu = false, this.not});

  final String label;
  final bool zorunlu;
  final String? not;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text.rich(
        TextSpan(
          style: _personelEtiket,
          children: [
            TextSpan(text: label),
            if (zorunlu) const TextSpan(text: ' *'),
            if (not != null) TextSpan(text: ' ($not)'),
          ],
        ),
      ),
    );
  }
}

class _PersonelHataYazi extends StatelessWidget {
  const _PersonelHataYazi(this.mesaj);

  final String mesaj;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(mesaj, style: _personelHata),
    );
  }
}

class _PersonelSecim extends StatefulWidget {
  const _PersonelSecim({
    required this.fieldKey,
    required this.icon,
    required this.value,
    required this.placeholder,
    required this.options,
    required this.onSelected,
  });

  final Key fieldKey;
  final IconData icon;
  final String? value;
  final String placeholder;
  final List<String> options;
  final ValueChanged<String> onSelected;

  @override
  State<_PersonelSecim> createState() => _PersonelSecimState();
}

class _PersonelSecimState extends State<_PersonelSecim> {
  final _focus = FocusNode();
  var _menuAcik = false;

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
    return PopupMenuButton<String>(
      key: widget.fieldKey,
      initialValue: widget.value,
      onOpened: () => setState(() {
        _menuAcik = true;
        _focus.requestFocus();
      }),
      onCanceled: () => setState(() => _menuAcik = false),
      onSelected: (value) {
        setState(() => _menuAcik = false);
        widget.onSelected(value);
      },
      color: const Color(0xFF121826),
      itemBuilder: (context) => [
        for (final option in widget.options)
          PopupMenuItem(
            value: option,
            child: Text(option, style: _personelAlanYazi),
          ),
      ],
      child: _GirisHucreOdak(
        focusNode: _focus,
        vurgulu: _focus.hasFocus || _menuAcik,
        inkWell: false,
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        fillColor: const Color(0xFF121826),
        child: Row(
          children: [
            Icon(widget.icon, size: 18, color: ProColors.textMuted),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                widget.value ?? widget.placeholder,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: widget.value == null ? _personelIpucu : _personelAlanYazi,
              ),
            ),
            const Icon(Icons.expand_more, size: 20, color: ProColors.textMuted),
          ],
        ),
      ),
    );
  }
}

class _PersonelTarih extends StatefulWidget {
  const _PersonelTarih({
    required this.value,
    required this.placeholder,
    required this.onPick,
    required this.onClear,
  });

  final String? value;
  final String placeholder;
  final VoidCallback onPick;
  final VoidCallback onClear;

  @override
  State<_PersonelTarih> createState() => _PersonelTarihState();
}

class _PersonelTarihState extends State<_PersonelTarih> {
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
    return _GirisHucreOdak(
      focusNode: _focus,
      height: 48,
      padding: const EdgeInsets.only(left: 12),
      fillColor: const Color(0xFF121826),
      onTap: widget.onPick,
      child: Row(
        children: [
          const Icon(Icons.calendar_today_outlined, size: 16, color: ProColors.textMuted),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.value ?? widget.placeholder,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: widget.value == null ? _personelIpucu : _personelAlanYazi,
            ),
          ),
          GestureDetector(
            onTap: widget.onClear,
            behavior: HitTestBehavior.opaque,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 14),
              child: Icon(Icons.close, size: 16, color: ProColors.textMuted),
            ),
          ),
        ],
      ),
    );
  }
}

InputDecoration _personelAlanDekor({required String hint, required IconData icon}) {
  return _girisMetinDekor(
    base: InputDecoration(
      hintText: hint,
      hintStyle: _personelIpucu,
      prefixIcon: Icon(icon, size: 18, color: ProColors.textMuted),
      prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 48),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      filled: true,
      fillColor: const Color(0xFF121826),
    ),
  );
}

String _tarihYaz(DateTime date) {
  final gun = date.day.toString().padLeft(2, '0');
  final ay = date.month.toString().padLeft(2, '0');
  return '$gun.$ay.${date.year}';
}

DateTime? _tarihOku(String? text) {
  if (text == null) return null;
  final parca = text.split('.');
  if (parca.length != 3) return null;
  final gun = int.tryParse(parca[0]);
  final ay = int.tryParse(parca[1]);
  final yil = int.tryParse(parca[2]);
  if (gun == null || ay == null || yil == null) return null;
  return DateTime(yil, ay, gun);
}

class _IbanMask extends TextInputFormatter {
  const _IbanMask();

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var body = newValue.text.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
    if (body.startsWith('TR')) body = body.substring(2);
    body = body.replaceAll(RegExp(r'[^0-9]'), '');
    if (body.length > 24) body = body.substring(0, 24);
    if (body.isEmpty) {
      return const TextEditingValue(text: '', selection: TextSelection.collapsed(offset: 0));
    }
    final raw = 'TR$body';
    final buf = StringBuffer();
    for (var i = 0; i < raw.length; i++) {
      if (i == 4 || i == 8 || i == 12 || i == 16 || i == 20 || i == 24) buf.write(' ');
      buf.write(raw[i]);
    }
    final text = buf.toString();
    return TextEditingValue(text: text, selection: TextSelection.collapsed(offset: text.length));
  }
}

class _RakamMask extends TextInputFormatter {
  const _RakamMask(this.max);

  final int max;

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length > max) digits = digits.substring(0, max);
    return TextEditingValue(text: digits, selection: TextSelection.collapsed(offset: digits.length));
  }
}
