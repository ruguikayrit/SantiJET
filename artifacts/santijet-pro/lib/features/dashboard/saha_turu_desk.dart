part of 'dashboard_screen.dart';

enum _TurSahne { blok, icMekan, guvenlik, mekanik }

enum _TurDurum { acik, devam, tamam }

class _SahaTuru {
  const _SahaTuru({
    required this.title,
    required this.badge,
    required this.durum,
    required this.date,
    required this.time,
    required this.tespit,
    required this.sahne,
  });

  final String title;
  final String badge;
  final _TurDurum durum;
  final String date;
  final String time;
  final int tespit;
  final _TurSahne sahne;
}

const _sonTurlar = <_SahaTuru>[
  _SahaTuru(
    title: 'A Blok Genel Saha Turu',
    badge: '3 Açık',
    durum: _TurDurum.acik,
    date: '26 Eyl 2026',
    time: '10:30',
    tespit: 8,
    sahne: _TurSahne.blok,
  ),
  _SahaTuru(
    title: 'B Blok İç Mekan Turu',
    badge: '2 Devam',
    durum: _TurDurum.devam,
    date: '25 Eyl 2026',
    time: '15:20',
    tespit: 5,
    sahne: _TurSahne.icMekan,
  ),
  _SahaTuru(
    title: 'Şantiye Geneli Güvenlik Turu',
    badge: 'Tamamlandı',
    durum: _TurDurum.tamam,
    date: '24 Eyl 2026',
    time: '14:10',
    tespit: 7,
    sahne: _TurSahne.guvenlik,
  ),
  _SahaTuru(
    title: 'A Blok - 3. Kat Mekanik Kontrol',
    badge: 'Tamamlandı',
    durum: _TurDurum.tamam,
    date: '23 Eyl 2026',
    time: '11:40',
    tespit: 4,
    sahne: _TurSahne.mekanik,
  ),
];

class _SahaTuruDesk extends StatelessWidget {
  const _SahaTuruDesk({required this.onBack, required this.onYeniTur});

  final VoidCallback onBack;
  final VoidCallback onYeniTur;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        _SahaTuruTopBar(onBack: onBack),
        const SizedBox(height: 16),
        const _SahaTuruBaslik(),
        const SizedBox(height: 14),
        const _SahaTuruFiltre(),
        const SizedBox(height: 12),
        const _TespitSatiri(),
        const SizedBox(height: 12),
        _YeniTurButton(onTap: onYeniTur),
        const SizedBox(height: 16),
        const _SonTurlarBaslik(),
        const SizedBox(height: 10),
        for (final tur in _sonTurlar) ...[
          _TurKarti(tur: tur),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _SahaTuruTopBar extends StatelessWidget {
  const _SahaTuruTopBar({required this.onBack});

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
                key: const Key('saha-turu-back'),
                onTap: onBack,
                borderRadius: BorderRadius.circular(8),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.chevron_left, color: ProColors.text, size: 22),
                      Text('Saha', style: TextStyle(fontFamily: 'Inter', fontSize: 15, color: ProColors.text)),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              const Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(Icons.notifications_none, color: ProColors.text, size: 22),
                  Positioned(
                    right: -6,
                    top: -4,
                    child: DecoratedBox(
                      decoration: BoxDecoration(color: Color(0xFFEF4444), shape: BoxShape.circle),
                      child: Padding(
                        padding: EdgeInsets.all(3),
                        child: Text(
                          '3',
                          style: TextStyle(fontFamily: 'Inter', fontSize: 8, fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              const CircleAvatar(
                radius: 14,
                backgroundColor: Color(0xFF1E293B),
                child: Icon(Icons.person, size: 16, color: ProColors.textMuted),
              ),
            ],
          ),
          const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ProMarka(bolt: 18, wordmark: 14, label: 14),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProMarka extends StatelessWidget {
  const _ProMarka({required this.bolt, required this.wordmark, required this.label});

  final double bolt;
  final double wordmark;
  final double label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset('assets/images/splash_bolt.png', height: bolt),
        const SizedBox(width: 6),
        Image.asset('assets/images/splash_wordmark.png', height: wordmark),
        const SizedBox(width: 4),
        Text(
          'PRO',
          style: TextStyle(
            fontFamily: 'Rajdhani',
            fontWeight: FontWeight.w700,
            fontSize: label,
            letterSpacing: 1,
            color: ProColors.electricBlue,
          ),
        ),
      ],
    );
  }
}

class _SahaTuruBaslik extends StatelessWidget {
  const _SahaTuruBaslik();

  @override
  Widget build(BuildContext context) {
    return const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TurIkonu(),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Saha Turu',
                style: TextStyle(fontFamily: 'Rajdhani', fontWeight: FontWeight.w700, fontSize: 28, height: 1, color: ProColors.text),
              ),
              SizedBox(height: 4),
              Text(
                'Sahadaki durumu gözlemle, tespit et, kaydet.',
                style: TextStyle(fontFamily: 'Inter', fontSize: 13, height: 1.3, color: ProColors.textMuted),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TurIkonu extends StatelessWidget {
  const _TurIkonu();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF34D399), Color(0xFF059669)],
        ),
      ),
      child: const Stack(
        alignment: Alignment.center,
        children: [
          Icon(Icons.article_outlined, color: Colors.white, size: 28),
          Positioned(right: 7, bottom: 7, child: Icon(Icons.location_on, color: Colors.white, size: 14)),
        ],
      ),
    );
  }
}

class _SahaTuruFiltre extends StatelessWidget {
  const _SahaTuruFiltre();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: _FiltreKart(
            onTap: () => _keepInPro(context),
            child: const Row(
              children: [
                _FiltreIkon(icon: Icons.calendar_month_outlined),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '26 Eylül 2026',
                        style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: 14, color: ProColors.text),
                      ),
                      Text('Cuma', style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: ProColors.textMuted)),
                    ],
                  ),
                ),
                Icon(Icons.expand_more, color: ProColors.textMuted, size: 20),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: _FiltreKart(
            onTap: () => _keepInPro(context),
            child: const Row(
              children: [
                _FiltreIkon(icon: Icons.history),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Tur Geçmişi',
                    style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 13, color: ProColors.text),
                  ),
                ),
                Icon(Icons.chevron_right, color: ProColors.textMuted, size: 18),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _FiltreIkon extends StatelessWidget {
  const _FiltreIkon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: const Color(0xFF1E3A5F),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: const Color(0xFF60A5FA), size: 18),
    );
  }
}

class _FiltreKart extends StatelessWidget {
  const _FiltreKart({required this.child, required this.onTap});

  final Widget child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF121826),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF243044)),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _TespitSatiri extends StatelessWidget {
  const _TespitSatiri();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 112,
      child: Row(
        children: [
          Expanded(
            child: _TespitKart(
              value: '12',
              label: 'Toplam Tespit',
              icon: Icons.description_outlined,
              colors: [Color(0xFF1A2744), Color(0xFF121C30)],
              iconColor: Color(0xFF64748B),
            ),
          ),
          SizedBox(width: 6),
          Expanded(
            child: _TespitKart(
              value: '7',
              label: 'Açık',
              icon: Icons.error_outline,
              colors: [Color(0xFF5C1A22), Color(0xFF2C1014)],
              iconColor: Color(0xFFEF4444),
            ),
          ),
          SizedBox(width: 6),
          Expanded(
            child: _TespitKart(
              value: '3',
              label: 'Devam Ediyor',
              icon: Icons.schedule,
              colors: [Color(0xFF5A3A12), Color(0xFF2A1C0A)],
              iconColor: Color(0xFFFBBF24),
            ),
          ),
          SizedBox(width: 6),
          Expanded(
            child: _TespitKart(
              value: '2',
              label: 'Tamamlandı',
              icon: Icons.check_circle_outline,
              colors: [Color(0xFF14532D), Color(0xFF0B2E18)],
              iconColor: Color(0xFF22C55E),
            ),
          ),
        ],
      ),
    );
  }
}

class _TespitKart extends StatelessWidget {
  const _TespitKart({
    required this.value,
    required this.label,
    required this.icon,
    required this.colors,
    required this.iconColor,
  });

  final String value;
  final String label;
  final IconData icon;
  final List<Color> colors;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: colors),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(fontFamily: 'Rajdhani', fontWeight: FontWeight.w700, fontSize: 28, height: 1, color: ProColors.text),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 2,
              style: const TextStyle(fontFamily: 'Inter', fontSize: 11, height: 1.15, color: ProColors.textMuted),
            ),
            const Spacer(),
            Align(alignment: Alignment.bottomRight, child: Icon(icon, color: iconColor, size: 18)),
          ],
        ),
      ),
    );
  }
}

class _YeniTurButton extends StatelessWidget {
  const _YeniTurButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF2563EB),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        key: const Key('saha-turu-yeni'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: const SizedBox(
          height: 52,
          child: Row(
            children: [
              SizedBox(width: 16),
              Icon(Icons.add, color: Colors.white, size: 22),
              Expanded(
                child: Text(
                  'Yeni Saha Turu Başlat',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: 16, color: Colors.white),
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.white, size: 22),
              SizedBox(width: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class _SonTurlarBaslik extends StatelessWidget {
  const _SonTurlarBaslik();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text(
          'Son Turlar',
          style: TextStyle(fontFamily: 'Rajdhani', fontWeight: FontWeight.w700, fontSize: 20, color: ProColors.text),
        ),
        const Spacer(),
        InkWell(
          onTap: () => _keepInPro(context),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Tümü',
                style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF60A5FA)),
              ),
              Icon(Icons.chevron_right, color: Color(0xFF60A5FA), size: 18),
            ],
          ),
        ),
      ],
    );
  }
}

class _TurKarti extends StatelessWidget {
  const _TurKarti({required this.tur});

  final _SahaTuru tur;

  Color get _badgeColor => switch (tur.durum) {
        _TurDurum.acik => const Color(0xFFB45309),
        _TurDurum.devam => const Color(0xFFD97706),
        _TurDurum.tamam => const Color(0xFF15803D),
      };

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF121826),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => _keepInPro(context),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF243044)),
          ),
          child: Row(
            children: [
              _TurFoto(sahne: tur.sahne),
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
                            tur.title,
                            maxLines: 2,
                            style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: 14, height: 1.2, color: ProColors.text),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: _badgeColor, borderRadius: BorderRadius.circular(8)),
                          child: Text(
                            tur.badge,
                            style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: 11, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_outlined, size: 12, color: ProColors.textMuted),
                          const SizedBox(width: 4),
                          Text(tur.date, style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: ProColors.textMuted)),
                          const SizedBox(width: 8),
                          const Icon(Icons.access_time, size: 12, color: ProColors.textMuted),
                          const SizedBox(width: 4),
                          Text(tur.time, style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: ProColors.textMuted)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${tur.tespit} tespit',
                      style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: ProColors.textMuted),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: ProColors.textMuted, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _TurFoto extends StatelessWidget {
  const _TurFoto({required this.sahne});

  final _TurSahne sahne;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: CustomPaint(
        size: const Size(72, 72),
        painter: _TurSahnePainter(sahne),
      ),
    );
  }
}

class _TurSahnePainter extends CustomPainter {
  const _TurSahnePainter(this.sahne);

  final _TurSahne sahne;

  @override
  void paint(Canvas canvas, Size size) {
    switch (sahne) {
      case _TurSahne.blok:
        _blok(canvas, size);
      case _TurSahne.icMekan:
        _ic(canvas, size);
      case _TurSahne.guvenlik:
        _guvenlik(canvas, size);
      case _TurSahne.mekanik:
        _mekanik(canvas, size);
    }
  }

  void _blok(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF8FB4D4));
    canvas.drawRect(Rect.fromLTWH(0, size.height * 0.72, size.width, size.height * 0.28), Paint()..color = const Color(0xFF6D8B62));
    final building = Paint()..color = const Color(0xFFE6EDF3);
    canvas.drawRect(Rect.fromLTWH(size.width * 0.22, size.height * 0.18, size.width * 0.56, size.height * 0.58), building);
    final window = Paint()..color = const Color(0xFF4C6F90);
    for (var row = 0; row < 4; row++) {
      for (var col = 0; col < 3; col++) {
        canvas.drawRect(
          Rect.fromLTWH(size.width * (0.28 + col * 0.16), size.height * (0.24 + row * 0.12), size.width * 0.08, size.height * 0.07),
          window,
        );
      }
    }
  }

  void _ic(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFFE8E2D6));
    final wall = Paint()..color = const Color(0xFFD5CFC3);
    canvas.drawRect(Rect.fromLTWH(0, size.height * 0.55, size.width, size.height * 0.45), wall);
    canvas.drawRect(Rect.fromLTWH(size.width * 0.62, size.height * 0.18, size.width * 0.28, size.height * 0.42), Paint()..color = const Color(0xFFB9D4EA));
    canvas.drawLine(Offset(0, size.height * 0.55), Offset(size.width, size.height * 0.55), Paint()..color = const Color(0xFFC4BBA8)..strokeWidth = 1);
  }

  void _guvenlik(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFFC4A574));
    final steel = Paint()
      ..color = const Color(0xFF8E98A3)
      ..strokeWidth = 1.4;
    for (var i = 0; i < 6; i++) {
      final y = size.height * (0.15 + i * 0.12);
      canvas.drawLine(Offset(0, y), Offset(size.width, y + 8), steel);
      canvas.drawLine(Offset(size.width * i / 5, 0), Offset(size.width * i / 5, size.height), steel);
    }
  }

  void _mekanik(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF9AA3AD));
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(size.width * 0.18, size.height * 0.28, size.width * 0.42, size.height * 0.48), const Radius.circular(8)),
      Paint()..color = const Color(0xFFE07A3D),
    );
    canvas.drawCircle(Offset(size.width * 0.7, size.height * 0.58), size.width * 0.12, Paint()..color = const Color(0xFF4B5563));
  }

  @override
  bool shouldRepaint(covariant _TurSahnePainter oldDelegate) => oldDelegate.sahne != sahne;
}
