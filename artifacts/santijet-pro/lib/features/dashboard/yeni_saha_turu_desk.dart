part of 'dashboard_screen.dart';

const _gozlemMetni = 'Alçıpan imalatları devam ediyor. Genel durum uygun.';
const _tespitMetni = 'Alçıpan derz uygulaması eksik.\n2 bölgede tespit edildi.';

class _YeniSahaTuruDesk extends StatefulWidget {
  const _YeniSahaTuruDesk({required this.onBack});

  final VoidCallback onBack;

  @override
  State<_YeniSahaTuruDesk> createState() => _YeniSahaTuruDeskState();
}

class _YeniSahaTuruDeskState extends State<_YeniSahaTuruDesk> {
  var _gozlem = true;
  var _ozet = false;
  final _fotolar = <int>[0, 1, 2];

  void _fotoEkle() {
    if (_fotolar.length >= 10) return;
    setState(() => _fotolar.add(_fotolar.length));
  }

  void _fotoSil(int index) {
    setState(() => _fotolar.removeAt(index));
  }

  @override
  Widget build(BuildContext context) {
    if (_ozet) {
      return _GorevOzetDesk(onBack: () => setState(() => _ozet = false));
    }
    final alt = MediaQuery.viewPaddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 8, 16, 12 + alt),
      child: Column(
        children: [
          _YeniTurBar(onBack: widget.onBack),
          const SizedBox(height: 16),
          _TurSekme(
            gozlem: _gozlem,
            onGozlem: () => setState(() => _gozlem = true),
            onTespit: () => setState(() => _gozlem = false),
          ),
          const SizedBox(height: 18),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                const _SecimSatiri(icon: Icons.description_outlined, label: 'Proje', value: 'İstanbul Residence'),
                const SizedBox(height: 14),
                const _SecimSatiri(icon: Icons.location_on_outlined, label: 'Konum', value: 'A Blok > 3. Kat > Daire 12'),
                const SizedBox(height: 14),
                const _SecimSatiri(icon: Icons.sell_outlined, label: 'Kategori', value: 'Alçıpan'),
                const SizedBox(height: 16),
                _AciklamaAlani(
                  metin: _gozlem ? _gozlemMetni : _tespitMetni,
                  sayac: _gozlem ? '47/500' : '48/500',
                ),
                const SizedBox(height: 16),
                _FotoBaslik(adet: _fotolar.length),
                const SizedBox(height: 10),
                _FotoSeridi(fotolar: _fotolar, tespit: !_gozlem, onSil: _fotoSil, onEkle: _fotoEkle),
              ],
            ),
          ),
          if (!_gozlem) ...[
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
          _KaydetButton(
            label: _gozlem ? 'Gözlemi Kaydet' : 'Tespiti Kaydet',
            onTap: () => _keepInPro(context),
          ),
        ],
      ),
    );
  }
}

class _YeniTurBar extends StatelessWidget {
  const _YeniTurBar({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Row(
            children: [
              InkWell(
                key: const Key('yeni-saha-turu-back'),
                onTap: onBack,
                borderRadius: BorderRadius.circular(8),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.chevron_left, color: ProColors.text, size: 22),
                      Text('Saha Turu', style: TextStyle(fontFamily: 'Inter', fontSize: 15, color: ProColors.text)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const _ProMarka(bolt: 18, wordmark: 14, label: 14),
        ],
      ),
    );
  }
}

class _TurSekme extends StatelessWidget {
  const _TurSekme({required this.gozlem, required this.onGozlem, required this.onTespit});

  final bool gozlem;
  final VoidCallback onGozlem;
  final VoidCallback onTespit;

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
          Expanded(
            child: _SekmeTusu(
              key: const Key('saha-turu-gozlem'),
              secili: gozlem,
              renk: const Color(0xFF2563EB),
              icon: Icons.visibility_outlined,
              label: 'Gözlem',
              onTap: onGozlem,
            ),
          ),
          Expanded(
            child: _SekmeTusu(
              key: const Key('saha-turu-tespit'),
              secili: !gozlem,
              renk: const Color(0xFFF97316),
              icon: Icons.warning_amber_rounded,
              label: 'Tespit',
              onTap: onTespit,
            ),
          ),
        ],
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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
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
    );
  }
}

class _SecimSatiri extends StatelessWidget {
  const _SecimSatiri({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

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
            onSelected: (_) {},
            color: const Color(0xFF121826),
            itemBuilder: (context) => [
              PopupMenuItem(value: value, child: Text(value, style: const TextStyle(fontFamily: 'Inter', color: ProColors.text))),
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
                      maxLines: 1,
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
  const _KaydetButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF2563EB),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        key: const Key('saha-turu-kaydet'),
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
