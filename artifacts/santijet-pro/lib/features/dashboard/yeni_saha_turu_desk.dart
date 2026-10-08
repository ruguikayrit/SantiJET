part of 'dashboard_screen.dart';

const _gozlemMetni = 'Alçıpan imalatları devam ediyor. Genel durum uygun.';
const _tespitMetni = 'Alçıpan derz uygulaması eksik.\n2 bölgede tespit edildi.';

/// Turda ne kaydedildiği. Kontrol, serbest açıklama yerine şablona bağlı
/// maddeleri işaretletir; uygunsuz madde yine tespit gibi göreve dönüşür.
enum _TurGirdi { gozlem, tespit, kontrol }

enum _MaddeDurum { uygun, uygunsuz, kapsamDisi }

extension on _MaddeDurum {
  String get label => switch (this) {
        _MaddeDurum.uygun => 'Uygun',
        _MaddeDurum.uygunsuz => 'Uygun Değil',
        _MaddeDurum.kapsamDisi => 'Kapsam Dışı',
      };

  IconData get icon => switch (this) {
        _MaddeDurum.uygun => Icons.check,
        _MaddeDurum.uygunsuz => Icons.priority_high,
        _MaddeDurum.kapsamDisi => Icons.remove,
      };

  Color get color => switch (this) {
        _MaddeDurum.uygun => const Color(0xFF16A34A),
        _MaddeDurum.uygunsuz => const Color(0xFFDC2626),
        _MaddeDurum.kapsamDisi => const Color(0xFF475569),
      };
}

class _KontrolFormu {
  const _KontrolFormu(this.ad, this.maddeler, this.baslangic);

  final String ad;
  final List<String> maddeler;

  /// Demo kabuğunda form canlı görünsün diye önceden işaretli gelen durumlar.
  /// `null` henüz işaretlenmemiş maddedir.
  final List<_MaddeDurum?> baslangic;
}

const _kontrolFormlari = <_KontrolFormu>[
  _KontrolFormu(
    'Günlük İSG Açılış',
    [
      'KKD kullanımı (baret, gözlük, ayakkabı)',
      'İskele ve çalışma platformu emniyeti',
      'Elektrik panosu ve kablo düzeni',
      'Yangın yolu ve söndürücü erişimi',
      'Kenar koruma ve döşeme boşluk kapakları',
      'İlk yardım ve acil durum donanımı',
    ],
    [
      _MaddeDurum.uygun,
      _MaddeDurum.uygun,
      _MaddeDurum.uygunsuz,
      _MaddeDurum.uygun,
      _MaddeDurum.uygun,
      null,
    ],
  ),
  _KontrolFormu(
    'Döküm Öncesi Kalıp-Donatı',
    [
      'Kalıp ölçü ve aks kontrolü',
      'Kalıp temizliği ve ayırıcı uygulaması',
      'Donatı çapı ve aralık kontrolü',
      'Paspayı ve sehpa yerleşimi',
      'Bindirme boyları',
      'Ankraj ve filiz donatıları',
      'Tesisat boru / kovan yerleşimi',
      'Payanda sıklığı ve kalıp desteği',
    ],
    [
      _MaddeDurum.uygun,
      _MaddeDurum.uygun,
      _MaddeDurum.uygun,
      _MaddeDurum.uygunsuz,
      _MaddeDurum.uygun,
      _MaddeDurum.uygun,
      _MaddeDurum.kapsamDisi,
      null,
    ],
  ),
  _KontrolFormu(
    'Mal Kabul',
    [
      'İrsaliye ve sipariş uygunluğu',
      'Miktar sayımı',
      'Ürün etiketi ve parti numarası',
      'Görsel hasar kontrolü',
      'Numune alımı / belge teslimi',
      'Depolama koşulu',
    ],
    [
      _MaddeDurum.uygun,
      _MaddeDurum.uygun,
      _MaddeDurum.uygun,
      _MaddeDurum.uygunsuz,
      _MaddeDurum.uygun,
      null,
    ],
  ),
  _KontrolFormu(
    'İşveren / Müşavir Kabul',
    [
      'İmalatın projeye uygunluğu',
      'Ölçü ve kot kontrolü',
      'Yüzey ve işçilik kalitesi',
      'Önceki tespitlerin kapatılması',
      'Teslim tutanağı imzası',
    ],
    [
      _MaddeDurum.uygun,
      _MaddeDurum.uygun,
      _MaddeDurum.uygunsuz,
      _MaddeDurum.uygun,
      null,
    ],
  ),
];

class _YeniSahaTuruDesk extends StatefulWidget {
  const _YeniSahaTuruDesk({required this.onBack});

  final VoidCallback onBack;

  @override
  State<_YeniSahaTuruDesk> createState() => _YeniSahaTuruDeskState();
}

class _YeniSahaTuruDeskState extends State<_YeniSahaTuruDesk> {
  var _girdi = _TurGirdi.gozlem;
  var _ozet = false;
  var _formIndex = 0;
  final _fotolar = <int>[0, 1, 2];
  late var _durumlar = [..._kontrolFormlari[_formIndex].baslangic];

  _KontrolFormu get _form => _kontrolFormlari[_formIndex];

  bool get _uygunsuzVar => _durumlar.contains(_MaddeDurum.uygunsuz);

  void _formSec(String ad) {
    final index = _kontrolFormlari.indexWhere((f) => f.ad == ad);
    if (index < 0 || index == _formIndex) return;
    setState(() {
      _formIndex = index;
      _durumlar = [..._kontrolFormlari[index].baslangic];
    });
  }

  void _maddeIsaretle(int index, _MaddeDurum durum) {
    setState(() => _durumlar[index] = _durumlar[index] == durum ? null : durum);
  }

  void _fotoEkle() {
    if (_fotolar.length >= 10) return;
    setState(() => _fotolar.add(_fotolar.length));
  }

  void _fotoSil(int index) {
    setState(() => _fotolar.removeAt(index));
  }

  String get _kaydetEtiketi => switch (_girdi) {
        _TurGirdi.gozlem => 'Gözlemi Kaydet',
        _TurGirdi.tespit => 'Tespiti Kaydet',
        _TurGirdi.kontrol => 'Kontrolü Kaydet',
      };

  /// Gözlemde görev yok; tespitte her zaman var; kontrolde ancak uygunsuz
  /// madde işaretlendiyse var.
  bool get _goreveDonusur => switch (_girdi) {
        _TurGirdi.gozlem => false,
        _TurGirdi.tespit => true,
        _TurGirdi.kontrol => _uygunsuzVar,
      };

  @override
  Widget build(BuildContext context) {
    if (_ozet) {
      return _GorevOzetDesk(onBack: () => setState(() => _ozet = false));
    }
    final kontrol = _girdi == _TurGirdi.kontrol;
    final alt = MediaQuery.viewPaddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 8, 16, 12 + alt),
      child: Column(
        children: [
          _ModulDeskUst(
            title: 'Yeni Tur',
            moduleIcon: _ModulDeskMark.sahaIcon,
            moduleColor: _ModulDeskMark.sahaColor,
            backKey: const Key('yeni-saha-turu-back'),
            onBack: widget.onBack,
            backLabel: 'Saha Turu',
          ),
          const SizedBox(height: 16),
          _TurSekme(girdi: _girdi, onSec: (g) => setState(() => _girdi = g)),
          const SizedBox(height: 18),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                const _SecimSatiri(icon: Icons.description_outlined, label: 'Proje', value: 'İstanbul Residence'),
                const SizedBox(height: 14),
                const _SecimSatiri(icon: Icons.location_on_outlined, label: 'Konum', value: 'A Blok > 3. Kat > Daire 12'),
                const SizedBox(height: 14),
                if (kontrol) ...[
                  _SecimSatiri(
                    icon: Icons.checklist_outlined,
                    label: 'Form',
                    value: _form.ad,
                    options: [for (final f in _kontrolFormlari) f.ad],
                    onSelected: _formSec,
                  ),
                  const SizedBox(height: 16),
                  _KontrolOzeti(durumlar: _durumlar),
                  const SizedBox(height: 10),
                  for (var i = 0; i < _form.maddeler.length; i++) ...[
                    _KontrolMaddesi(
                      sira: i + 1,
                      metin: _form.maddeler[i],
                      durum: _durumlar[i],
                      onSec: (d) => _maddeIsaretle(i, d),
                    ),
                    const SizedBox(height: 8),
                  ],
                  const SizedBox(height: 8),
                ] else ...[
                  const _SecimSatiri(icon: Icons.sell_outlined, label: 'Kategori', value: 'Alçıpan'),
                  const SizedBox(height: 16),
                  _AciklamaAlani(
                    metin: _girdi == _TurGirdi.gozlem ? _gozlemMetni : _tespitMetni,
                    sayac: _girdi == _TurGirdi.gozlem ? '47/500' : '48/500',
                  ),
                  const SizedBox(height: 16),
                ],
                _FotoBaslik(adet: _fotolar.length),
                const SizedBox(height: 10),
                _FotoSeridi(
                  fotolar: _fotolar,
                  tespit: _girdi != _TurGirdi.gozlem,
                  onSil: _fotoSil,
                  onEkle: _fotoEkle,
                ),
              ],
            ),
          ),
          if (_goreveDonusur) ...[
            const SizedBox(height: 8),
            InkWell(
              key: const Key('saha-turu-goreve-donustur'),
              onTap: () => setState(() => _ozet = true),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Göreve Dönüştür',
                      style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 15, color: ProColors.text),
                    ),
                    SizedBox(width: 6),
                    Icon(Icons.arrow_forward, size: 16, color: ProColors.text),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),
          _KaydetButton(label: _kaydetEtiketi, onTap: () => _keepInPro(context)),
        ],
      ),
    );
  }
}

class _TurSekme extends StatelessWidget {
  const _TurSekme({required this.girdi, required this.onSec});

  static const _tanimlar = <_TurGirdi, (String, String, IconData, Color)>{
    _TurGirdi.gozlem: ('saha-turu-gozlem', 'Gözlem', Icons.visibility_outlined, Color(0xFF2563EB)),
    _TurGirdi.tespit: ('saha-turu-tespit', 'Tespit', Icons.warning_amber_rounded, Color(0xFFF97316)),
    _TurGirdi.kontrol: ('saha-turu-kontrol', 'Kontrol', Icons.checklist_outlined, Color(0xFF16A34A)),
  };

  final _TurGirdi girdi;
  final ValueChanged<_TurGirdi> onSec;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF121826),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF243044)),
      ),
      child: Row(
        children: [
          for (final entry in _tanimlar.entries)
            Expanded(
              child: _SekmeTusu(
                key: Key(entry.value.$1),
                secili: entry.key == girdi,
                renk: entry.value.$4,
                icon: entry.value.$3,
                label: entry.value.$2,
                onTap: () => onSec(entry.key),
              ),
            ),
        ],
      ),
    );
  }
}

class _KontrolOzeti extends StatelessWidget {
  const _KontrolOzeti({required this.durumlar});

  final List<_MaddeDurum?> durumlar;

  int _adet(_MaddeDurum durum) => durumlar.where((d) => d == durum).length;

  @override
  Widget build(BuildContext context) {
    final isaretli = durumlar.where((d) => d != null).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.rule, size: 18, color: Color(0xFF94A3B8)),
            const SizedBox(width: 8),
            const Text('Kontrol Maddeleri', style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: ProColors.text)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Text(
                '$isaretli/${durumlar.length}',
                style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: ProColors.textMuted),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: Row(
            children: [
              for (final durum in _MaddeDurum.values)
                if (_adet(durum) > 0)
                  Expanded(
                    flex: _adet(durum),
                    child: Container(height: 6, color: durum.color),
                  ),
              if (isaretli < durumlar.length)
                Expanded(
                  flex: durumlar.length - isaretli,
                  child: Container(height: 6, color: const Color(0xFF1E293B)),
                ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Row(
            children: [
              for (final durum in _MaddeDurum.values) ...[
                Container(width: 8, height: 8, decoration: BoxDecoration(color: durum.color, shape: BoxShape.circle)),
                const SizedBox(width: 5),
                Text(
                  '${durum.label} ${_adet(durum)}',
                  style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: ProColors.textMuted),
                ),
                const SizedBox(width: 12),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _KontrolMaddesi extends StatelessWidget {
  const _KontrolMaddesi({required this.sira, required this.metin, required this.durum, required this.onSec});

  final int sira;
  final String metin;
  final _MaddeDurum? durum;
  final ValueChanged<_MaddeDurum> onSec;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: const Color(0xFF121826),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: durum == _MaddeDurum.uygunsuz ? const Color(0xFF7F1D1D) : const Color(0xFF243044)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 20,
                child: Text(
                  '$sira.',
                  style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: ProColors.textMuted),
                ),
              ),
              Expanded(
                child: Text(
                  metin,
                  style: const TextStyle(fontFamily: 'Inter', fontSize: 13, height: 1.3, color: ProColors.text),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (final secenek in _MaddeDurum.values) ...[
                Expanded(child: _MaddeTusu(durum: secenek, secili: secenek == durum, onTap: () => onSec(secenek))),
                if (secenek != _MaddeDurum.values.last) const SizedBox(width: 6),
              ],
            ],
          ),
          if (durum == _MaddeDurum.uygunsuz) ...[
            const SizedBox(height: 8),
            const Row(
              children: [
                Icon(Icons.arrow_forward, size: 13, color: Color(0xFFF87171)),
                SizedBox(width: 5),
                Expanded(
                  child: Text(
                    'Bu madde tespit olarak kaydedilir ve göreve dönüştürülebilir.',
                    style: TextStyle(fontFamily: 'Inter', fontSize: 11, height: 1.3, color: Color(0xFFF87171)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _MaddeTusu extends StatelessWidget {
  const _MaddeTusu({required this.durum, required this.secili, required this.onTap});

  final _MaddeDurum durum;
  final bool secili;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: secili ? durum.color : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 34,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: secili ? durum.color : const Color(0xFF243044)),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(durum.icon, size: 14, color: secili ? Colors.white : ProColors.textMuted),
                  const SizedBox(width: 4),
                  Text(
                    durum.label,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: secili ? FontWeight.w600 : FontWeight.w400,
                      fontSize: 11,
                      color: secili ? Colors.white : ProColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SekmeTusu extends StatelessWidget {
  const _SekmeTusu({
    super.key,
    required this.secili,
    required this.renk,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final bool secili;
  final Color renk;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: secili ? renk : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: 44,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 18, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: 15, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SecimSatiri extends StatelessWidget {
  const _SecimSatiri({
    required this.icon,
    required this.label,
    required this.value,
    this.options,
    this.onSelected,
  });

  final IconData icon;
  final String label;
  final String value;
  final List<String>? options;
  final ValueChanged<String>? onSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF94A3B8)),
        const SizedBox(width: 8),
        SizedBox(
          width: 78,
          child: Text(label, style: const TextStyle(fontFamily: 'Inter', fontSize: 14, color: ProColors.text)),
        ),
        Expanded(
          child: PopupMenuButton<String>(
            onSelected: (secilen) => onSelected?.call(secilen),
            color: const Color(0xFF121826),
            itemBuilder: (context) => [
              for (final secenek in options ?? [value])
                PopupMenuItem(
                  value: secenek,
                  child: Text(secenek, style: const TextStyle(fontFamily: 'Inter', color: ProColors.text)),
                ),
            ],
            child: Container(
              height: 46,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF121826),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF243044)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      value,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontFamily: 'Inter', fontSize: 14, color: ProColors.text),
                    ),
                  ),
                  const Icon(Icons.expand_more, color: ProColors.textMuted, size: 20),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AciklamaAlani extends StatelessWidget {
  const _AciklamaAlani({required this.metin, required this.sayac});

  final String metin;
  final String sayac;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.apartment_outlined, size: 18, color: Color(0xFF94A3B8)),
            SizedBox(width: 8),
            Text('Açıklama', style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: ProColors.text)),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 118),
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
          decoration: BoxDecoration(
            color: const Color(0xFF121826),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF243044)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  metin,
                  style: const TextStyle(fontFamily: 'Inter', fontSize: 14, height: 1.4, color: ProColors.text),
                ),
              ),
              const SizedBox(height: 10),
              Text(sayac, style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: ProColors.textMuted)),
            ],
          ),
        ),
      ],
    );
  }
}

class _FotoBaslik extends StatelessWidget {
  const _FotoBaslik({required this.adet});

  final int adet;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.image_outlined, size: 18, color: Color(0xFF94A3B8)),
        const SizedBox(width: 8),
        const Text('Fotoğraf', style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: ProColors.text)),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF334155)),
          ),
          child: Text(
            '$adet/10',
            style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: ProColors.textMuted),
          ),
        ),
      ],
    );
  }
}

class _FotoSeridi extends StatelessWidget {
  const _FotoSeridi({required this.fotolar, required this.tespit, required this.onSil, required this.onEkle});

  final List<int> fotolar;
  final bool tespit;
  final ValueChanged<int> onSil;
  final VoidCallback onEkle;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < fotolar.length; i++) ...[
            _BoruKarti(variant: fotolar[i], tespit: tespit, onSil: () => onSil(i)),
            const SizedBox(width: 8),
          ],
          if (fotolar.length < 10) _FotoEkle(onTap: onEkle),
        ],
      ),
    );
  }
}

class _BoruKarti extends StatelessWidget {
  const _BoruKarti({required this.variant, required this.tespit, required this.onSil});

  final int variant;
  final bool tespit;
  final VoidCallback onSil;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 78,
      height: 96,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CustomPaint(size: const Size(78, 96), painter: _BoruPainter(variant, tespit: tespit)),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: onSil,
              child: Container(
                width: 18,
                height: 18,
                decoration: const BoxDecoration(color: Color(0xCC111827), shape: BoxShape.circle),
                child: const Icon(Icons.close, size: 12, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FotoEkle extends StatelessWidget {
  const _FotoEkle({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: const Key('saha-turu-foto-ekle'),
      onTap: onTap,
      child: CustomPaint(
        painter: const _KesikCerceve(),
        child: const SizedBox(
          width: 78,
          height: 96,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add, color: ProColors.textMuted, size: 22),
              SizedBox(height: 4),
              Text(
                'Fotoğraf\nEkle',
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: 'Inter', fontSize: 11, height: 1.2, color: ProColors.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _KaydetButton extends StatelessWidget {
  const _KaydetButton({this.buttonKey, required this.label, required this.onTap});

  final Key? buttonKey;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF2563EB),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        key: buttonKey ?? const Key('saha-turu-kaydet'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          height: 52,
          width: double.infinity,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: 16, color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BoruPainter extends CustomPainter {
  const _BoruPainter(this.variant, {required this.tespit});

  final int variant;
  final bool tespit;

  @override
  void paint(Canvas canvas, Size size) {
    final sahne = tespit ? variant % 3 : 1;
    if (sahne == 0) {
      _profil(canvas, size);
    } else if (sahne == 2) {
      _zemin(canvas, size);
    } else {
      _boru(canvas, size);
    }
  }

  void _profil(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFFE7E2D8));
    final metal = Paint()
      ..color = const Color(0xFF9AA3AD)
      ..strokeWidth = 3;
    for (var i = 0; i < 5; i++) {
      final x = size.width * (0.12 + i * 0.18);
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), metal);
    }
    canvas.drawLine(
      Offset(0, size.height * 0.45),
      Offset(size.width, size.height * 0.45),
      Paint()
        ..color = const Color(0xFFE4572E)
        ..strokeWidth = 7
        ..strokeCap = StrokeCap.round,
    );
  }

  void _boru(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFFE4E0D8));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height * 0.16), Paint()..color = const Color(0xFFCFC8BC));
    final boru = Paint()
      ..color = const Color(0xFFE4572E)
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(-4, 24), Offset(size.width + 4, 12), boru);
    canvas.drawLine(Offset(8, 42), Offset(size.width * 0.72, size.height * 0.8), boru);
    canvas.drawLine(Offset(size.width * 0.4, 16), Offset(size.width * 0.52, size.height), boru);
  }

  void _zemin(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFFE8E3D8));
    canvas.drawRect(Rect.fromLTWH(0, size.height * 0.62, size.width, size.height * 0.38), Paint()..color = const Color(0xFFB7B1A6));
    canvas.drawLine(
      Offset(0, size.height * 0.62),
      Offset(size.width, size.height * 0.62),
      Paint()
        ..color = const Color(0xFF8C8680)
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant _BoruPainter oldDelegate) => oldDelegate.variant != variant || oldDelegate.tespit != tespit;
}

class _KesikCerceve extends CustomPainter {
  const _KesikCerceve();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF64748B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(Rect.fromLTWH(1, 1, size.width - 2, size.height - 2), const Radius.circular(12)));
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = (distance + 5).clamp(0, metric.length).toDouble();
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance += 9;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
