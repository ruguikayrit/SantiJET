part of 'dashboard_screen.dart';

const _talimatMetni = 'Belirtilen 2 bölgede alçıpan derz uygulaması tamamlanacak.';

class _GorevOzetDesk extends StatelessWidget {
  const _GorevOzetDesk({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final alt = MediaQuery.viewPaddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 8, 16, 12 + alt),
      child: Column(
        children: [
          _ModulDeskUst(
            title: 'Göreve Dönüştür',
            moduleIcon: _ModulDeskMark.sahaIcon,
            moduleColor: _ModulDeskMark.sahaColor,
            backKey: const Key('gorev-ozet-back'),
            onBack: onBack,
            backLabel: 'Tespit',
          ),
          const SizedBox(height: 14),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _OzetBaslik(),
                  const SizedBox(height: 14),
                  _TespitOzetKarti(onDuzenle: onBack),
                  const SizedBox(height: 12),
                  const _GorevBilgiKarti(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _KaydetButton(label: 'Görevi Oluştur ve Kaydet', onTap: () => _keepInPro(context)),
          const SizedBox(height: 8),
          _GeriButton(onTap: onBack),
        ],
      ),
    );
  }
}

class _OzetBaslik extends StatelessWidget {
  const _OzetBaslik();

  @override
  Widget build(BuildContext context) {
    return const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _YesilOnay(),
        SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Görev Oluştur - Özet',
                style: TextStyle(fontFamily: 'Rajdhani', fontWeight: FontWeight.w700, fontSize: 22, height: 1.1, color: ProColors.text),
              ),
              SizedBox(height: 2),
              Text(
                'Aşağıdaki bilgilerle görev kaydedilecek.',
                style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: ProColors.textMuted),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _YesilOnay extends StatelessWidget {
  const _YesilOnay();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: const Color(0xFF16A34A),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.check, color: Colors.white, size: 22),
    );
  }
}

class _TespitOzetKarti extends StatelessWidget {
  const _TespitOzetKarti({required this.onDuzenle});

  final VoidCallback onDuzenle;

  @override
  Widget build(BuildContext context) {
    return _OzetKart(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Color(0xFFF97316), size: 18),
              const SizedBox(width: 8),
              const Text(
                'Tespit Özeti',
                style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: 15, color: ProColors.text),
              ),
              const Spacer(),
              OutlinedButton.icon(
                key: const Key('gorev-ozet-duzenle'),
                onPressed: onDuzenle,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF60A5FA),
                  side: const BorderSide(color: Color(0xFF2563EB)),
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(0, 30),
                ),
                icon: const Icon(Icons.edit_outlined, size: 14),
                label: const Text('Düzenle', style: TextStyle(fontFamily: 'Inter', fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const _OzetSatir(icon: Icons.apartment_outlined, label: 'Proje', value: 'İstanbul Residence'),
          const _OzetSatir(icon: Icons.location_on_outlined, label: 'Konum', value: 'A Blok > 3. Kat > Daire 12'),
          const _OzetSatir(icon: Icons.sell_outlined, label: 'Kategori', value: 'Alçıpan'),
          const _OzetSatir(icon: Icons.notes_outlined, label: 'Açıklama', value: _tespitMetni),
          const SizedBox(height: 10),
          const Row(
            children: [
              Expanded(child: _OzetFoto(sahne: 0)),
              SizedBox(width: 8),
              Expanded(child: _OzetFoto(sahne: 1)),
              SizedBox(width: 8),
              Expanded(child: _OzetFoto(sahne: 2)),
            ],
          ),
        ],
      ),
    );
  }
}

class _GorevBilgiKarti extends StatelessWidget {
  const _GorevBilgiKarti();

  @override
  Widget build(BuildContext context) {
    return const _OzetKart(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.settings, color: Color(0xFFF97316), size: 18),
              SizedBox(width: 8),
              Text(
                'Görev Bilgileri',
                style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: 15, color: ProColors.text),
              ),
            ],
          ),
          SizedBox(height: 12),
          _AlanEtiket('Görev Başlığı'),
          _AlanKutu(child: Text('Alçıpan derz eksiklerini tamamla', style: _alanYazi)),
          SizedBox(height: 10),
          _AlanEtiket('Sorumlu'),
          _AlanKutu(
            child: Row(
              children: [
                Expanded(child: Text('Alçıpan Ekibi', style: _alanYazi)),
                Icon(Icons.expand_more, color: ProColors.textMuted, size: 18),
              ],
            ),
          ),
          SizedBox(height: 10),
          _AlanEtiket('Termin'),
          _AlanKutu(
            child: Row(
              children: [
                Icon(Icons.calendar_month_outlined, size: 16, color: Color(0xFF60A5FA)),
                SizedBox(width: 8),
                Expanded(child: Text('28 Eylül 2026', style: _alanYazi)),
                Icon(Icons.expand_more, color: ProColors.textMuted, size: 18),
              ],
            ),
          ),
          SizedBox(height: 10),
          _AlanEtiket('Öncelik'),
          _AlanKutu(
            child: Row(
              children: [
                _KirmiziNokta(),
                SizedBox(width: 8),
                Expanded(child: Text('Yüksek', style: _alanYazi)),
                Icon(Icons.expand_more, color: ProColors.textMuted, size: 18),
              ],
            ),
          ),
          SizedBox(height: 12),
          _AlanEtiket('Talimat (opsiyonel)'),
          _TalimatKutu(),
        ],
      ),
    );
  }
}

const _alanYazi = TextStyle(fontFamily: 'Inter', fontSize: 14, color: ProColors.text);

class _OzetKart extends StatelessWidget {
  const _OzetKart({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF121826),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF243044)),
      ),
      child: child,
    );
  }
}

class _OzetSatir extends StatelessWidget {
  const _OzetSatir({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF94A3B8)),
          const SizedBox(width: 8),
          SizedBox(
            width: 72,
            child: Text(label, style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: ProColors.textMuted)),
          ),
          const Text(':', style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: ProColors.textMuted)),
          const SizedBox(width: 8),
          Expanded(child: Text(value, style: const TextStyle(fontFamily: 'Inter', fontSize: 13, height: 1.3, color: ProColors.text))),
        ],
      ),
    );
  }
}

class _AlanEtiket extends StatelessWidget {
  const _AlanEtiket(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text, style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: ProColors.textMuted)),
    );
  }
}

class _AlanKutu extends StatelessWidget {
  const _AlanKutu({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 42),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1220),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF243044)),
      ),
      child: child,
    );
  }
}

class _KirmiziNokta extends StatelessWidget {
  const _KirmiziNokta();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: const BoxDecoration(color: Color(0xFFEF4444), shape: BoxShape.circle),
    );
  }
}

class _TalimatKutu extends StatelessWidget {
  const _TalimatKutu();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1220),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF243044)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(_talimatMetni, style: TextStyle(fontFamily: 'Inter', fontSize: 13, height: 1.35, color: ProColors.text)),
          ),
          SizedBox(height: 8),
          Text('68/500', style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: ProColors.textMuted)),
        ],
      ),
    );
  }
}

class _OzetFoto extends StatelessWidget {
  const _OzetFoto({required this.sahne});

  final int sahne;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: CustomPaint(
        painter: _BoruPainter(sahne, tespit: true),
        child: const SizedBox(height: 72),
      ),
    );
  }
}

class _GeriButton extends StatelessWidget {
  const _GeriButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        key: const Key('gorev-ozet-geri'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF334155)),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.arrow_back, size: 16, color: ProColors.text),
              SizedBox(width: 8),
              Text('Geri', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 15, color: ProColors.text)),
            ],
          ),
        ),
      ),
    );
  }
}
