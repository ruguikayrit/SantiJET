part of 'dashboard_screen.dart';

class _PersonelKayit {
  const _PersonelKayit({
    required this.name,
    required this.unvan,
    required this.ekip,
    required this.firma,
    required this.giris,
    required this.color,
    required this.calisan,
    this.cikis,
    this.telefon,
    this.iban,
    this.tc,
    this.dogum,
    this.adres,
    this.notlar,
  });

  final String name;
  final String unvan;
  final String ekip;
  final String firma;
  final String giris;
  final String? cikis;
  final String? telefon;
  final String? iban;
  final String? tc;
  final String? dogum;
  final String? adres;
  final String? notlar;
  final Color color;
  final bool calisan;

  String get initials {
    final parts = name.split(' ');
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}';
    }
    return name.isEmpty ? '' : name.substring(0, 1);
  }
}

const _personelKayitlari = <_PersonelKayit>[
  _PersonelKayit(name: 'Mehmet Arslan', unvan: 'Alçıpan Ustası', ekip: 'Alçıpan Ekibi', firma: 'ABC Yapı Ltd. Şti.', giris: '03.01.2026', color: Color(0xFF2563EB), calisan: true),
  _PersonelKayit(name: 'Hasan Kaya', unvan: 'Alçıpan Ustası', ekip: 'Alçıpan Ekibi', firma: 'ABC Yapı Ltd. Şti.', giris: '15.02.2026', color: Color(0xFF7C3AED), calisan: true),
  _PersonelKayit(name: 'Ali Yılmaz', unvan: 'İşçi', ekip: 'Alçı Ekibi', firma: 'Kare İnşaat A.Ş.', giris: '10.11.2025', color: Color(0xFFF97316), calisan: true),
  _PersonelKayit(name: 'Emre Koç', unvan: 'İşçi', ekip: 'Alçıpan Ekibi', firma: 'Kare İnşaat A.Ş.', giris: '05.03.2026', color: Color(0xFFEF4444), calisan: true),
  _PersonelKayit(name: 'Burak Demir', unvan: 'İşçi', ekip: 'Boya Ekibi', firma: 'Demir Yapı Ltd. Şti.', giris: '12.01.2026', color: Color(0xFF0EA5E9), calisan: true),
  _PersonelKayit(name: 'Selim Karaca', unvan: 'Usta', ekip: 'Boya Ekibi', firma: 'Demir Yapı Ltd. Şti.', giris: '20.12.2025', color: Color(0xFF7C3AED), calisan: true),
  _PersonelKayit(name: 'Tamer Yıldız', unvan: 'İşçi', ekip: 'Boya Ekibi', firma: 'Demir Yapı Ltd. Şti.', giris: '01.02.2026', color: Color(0xFFA855F7), calisan: true),
  _PersonelKayit(name: 'Deniz Aydın', unvan: 'Usta', ekip: 'Demir Ekibi', firma: 'Demir Yapı Ltd. Şti.', giris: '01.02.2026', color: Color(0xFF22C55E), calisan: true),
  _PersonelKayit(name: 'Kemal Aydın', unvan: 'Boya Ustası', ekip: 'Boya Ekibi', firma: 'Demir Yapı Ltd. Şti.', giris: '04.02.2025', cikis: '18.08.2025', color: Color(0xFFDB2777), calisan: false),
  _PersonelKayit(name: 'Serkan Yıldız', unvan: 'İşçi', ekip: 'Boya Ekibi', firma: 'ABC Yapı Ltd. Şti.', giris: '11.09.2024', cikis: '02.06.2025', color: Color(0xFFBE185D), calisan: false),
  _PersonelKayit(name: 'Okan Demir', unvan: 'Elektrik Ustası', ekip: 'Elektrik Ekibi', firma: 'Kare İnşaat A.Ş.', giris: '20.01.2025', cikis: '14.04.2025', color: Color(0xFFF97316), calisan: false),
  _PersonelKayit(name: 'Yusuf Aksoy', unvan: 'İşçi', ekip: 'Elektrik Ekibi', firma: 'ABC Yapı Ltd. Şti.', giris: '08.11.2024', cikis: '22.03.2025', color: Color(0xFF2563EB), calisan: false),
];

class _PersonelDesk extends StatefulWidget {
  const _PersonelDesk({required this.onBack});

  final VoidCallback onBack;

  @override
  State<_PersonelDesk> createState() => _PersonelDeskState();
}

class _PersonelDeskState extends State<_PersonelDesk> {
  String _filtre = 'Tümü';
  String _arama = '';
  _PersonelKayit? _secili;
  var _ekle = false;
  final _kayitlar = <_PersonelKayit>[..._personelKayitlari];

  List<_PersonelKayit> get _gorunen {
    final sorgu = _arama.trim().toLowerCase();
    return [
      for (final kayit in _kayitlar)
        if ((_filtre == 'Tümü' || kayit.ekip.startsWith('$_filtre ')) &&
            (sorgu.isEmpty ||
                kayit.name.toLowerCase().contains(sorgu) ||
                kayit.ekip.toLowerCase().contains(sorgu) ||
                kayit.firma.toLowerCase().contains(sorgu)))
          kayit,
    ];
  }

  void _ekleAc() => setState(() {
        _secili = null;
        _ekle = true;
      });

  void _kaydet(_PersonelKayit kayit) {
    setState(() {
      _kayitlar.insert(0, kayit);
      _ekle = false;
      _arama = '';
      _filtre = 'Tümü';
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_ekle) {
      return _PersonelEkleDesk(
        onBack: () => setState(() => _ekle = false),
        onSave: _kaydet,
      );
    }
    final secili = _secili;
    if (secili != null) {
      return _PersonelBilgiDesk(
        kayit: secili,
        onBack: () => setState(() => _secili = null),
      );
    }
    final kayitlar = _gorunen;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        _ModulDeskUst(
          title: 'Personel',
          moduleIcon: _ModulDeskMark.sahaIcon,
          moduleColor: _ModulDeskMark.sahaColor,
          backKey: const Key('personel-back'),
          onBack: widget.onBack,
          backLabel: 'Saha',
          trailing: Material(
            color: Colors.transparent,
            child: InkWell(
              key: const Key('personel-open-app'),
              onTap: _ekleAc,
              borderRadius: BorderRadius.circular(8),
              child: Ink(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: ProColors.electricBlue,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.add, size: 20, color: Colors.white),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        const _PersonelBaslik(),
        const SizedBox(height: 14),
        _PersonelArama(
          filtre: _filtre,
          onQuery: (value) => setState(() => _arama = value),
          onFiltre: (value) => setState(() => _filtre = value),
        ),
        const SizedBox(height: 10),
        if (kayitlar.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Text(
              'Eşleşen personel yok.',
              style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: ProColors.textMuted),
            ),
          )
        else
          for (final kayit in kayitlar) ...[
            _PersonelSatir(kayit: kayit, onTap: () => setState(() => _secili = kayit)),
            const SizedBox(height: 8),
          ],
      ],
    );
  }
}

class _PersonelBaslik extends StatelessWidget {
  const _PersonelBaslik();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        _PersonelIsaret(),
        SizedBox(width: 12),
        Expanded(
          child: Text(
            'Ekip yönetimi ve personel bilgileri.',
            style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: ProColors.textMuted),
          ),
        ),
      ],
    );
  }
}

class _PersonelIsaret extends StatelessWidget {
  const _PersonelIsaret();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: const Color(0xFFE8A317),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.manage_accounts, color: Colors.white, size: 26),
    );
  }
}

class _PersonelArama extends StatelessWidget {
  const _PersonelArama({required this.filtre, required this.onQuery, required this.onFiltre});

  final String filtre;
  final ValueChanged<String> onQuery;
  final ValueChanged<String> onFiltre;

  @override
  Widget build(BuildContext context) {
    const ekipler = ['Tümü', 'Alçıpan', 'Alçı', 'Boya', 'Demir', 'Elektrik'];
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Container(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF0B1220),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: ProColors.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, size: 16, color: ProColors.textMuted),
                  const SizedBox(width: 6),
                  Expanded(
                    child: TextField(
                      onChanged: onQuery,
                      style: const TextStyle(color: ProColors.text, fontFamily: 'Inter', fontSize: 13),
                      decoration: const InputDecoration(
                        hintText: 'Personel ara (ad, ekip, firma...)',
                        hintStyle: TextStyle(color: ProColors.textMuted, fontFamily: 'Inter', fontSize: 13),
                        border: InputBorder.none,
                        isCollapsed: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            initialValue: filtre,
            onSelected: onFiltre,
            color: const Color(0xFF0B1220),
            itemBuilder: (context) => [
              for (final name in ekipler)
                PopupMenuItem(
                  value: name,
                  child: Text(name, style: const TextStyle(fontFamily: 'Inter', fontSize: 14, color: ProColors.text)),
                ),
            ],
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF0B1220),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: ProColors.border),
              ),
              child: const Row(
                children: [
                  Icon(Icons.filter_alt_outlined, size: 16, color: ProColors.text),
                  SizedBox(width: 6),
                  Text('Filtrele', style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: ProColors.text)),
                  Icon(Icons.keyboard_arrow_down, size: 18, color: ProColors.textMuted),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PersonelSatir extends StatelessWidget {
  const _PersonelSatir({required this.kayit, required this.onTap});

  final _PersonelKayit kayit;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF0B1220),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        key: Key('personel-row-${kayit.name}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 10, 8, 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: ProColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: kayit.color, shape: BoxShape.circle),
                child: Text(
                  kayit.initials,
                  style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: 12, color: Colors.white),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      kayit.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 14, color: ProColors.text),
                    ),
                    Text(
                      kayit.unvan,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: ProColors.textMuted),
                    ),
                    const SizedBox(height: 4),
                    _PersonelSatirBilgi(icon: Icons.groups_outlined, text: kayit.ekip),
                    const SizedBox(height: 2),
                    _PersonelSatirBilgi(icon: Icons.apartment_outlined, text: kayit.firma),
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

class _PersonelSatirBilgi extends StatelessWidget {
  const _PersonelSatirBilgi({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: ProColors.textMuted),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: ProColors.text),
          ),
        ),
      ],
    );
  }
}
