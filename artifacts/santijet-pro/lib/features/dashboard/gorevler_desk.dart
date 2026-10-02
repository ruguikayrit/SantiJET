part of 'dashboard_screen.dart';

/// Görevin hangi kapıdan geldiği. İş Programı ve İmalat bu akışa girmez.
enum _GorevKaynak { sahaTuru, kontrol, manuel }

enum _GorevDurum { yapilacak, devam, tamam, geciken }

extension on _GorevKaynak {
  String get ad => switch (this) {
        _GorevKaynak.sahaTuru => 'Saha Turu',
        _GorevKaynak.kontrol => 'Kontrol',
        _GorevKaynak.manuel => 'Manuel',
      };

  String get akis => switch (this) {
        _GorevKaynak.sahaTuru => 'Tespit → Göreve dönüştür',
        _GorevKaynak.kontrol => 'Uygunsuzluk → Göreve dönüştür',
        _GorevKaynak.manuel => 'Görev oluştur',
      };

  IconData get icon => switch (this) {
        _GorevKaynak.sahaTuru => Icons.place_outlined,
        _GorevKaynak.kontrol => Icons.checklist_outlined,
        _GorevKaynak.manuel => Icons.edit_outlined,
      };

  Color get renk => switch (this) {
        _GorevKaynak.sahaTuru => const Color(0xFFDC2626),
        _GorevKaynak.kontrol => const Color(0xFF16A34A),
        _GorevKaynak.manuel => const Color(0xFF2563EB),
      };
}

extension on _GorevDurum {
  String get ad => switch (this) {
        _GorevDurum.yapilacak => 'Yapılacak',
        _GorevDurum.devam => 'Devam ediyor',
        _GorevDurum.tamam => 'Tamamlandı',
        _GorevDurum.geciken => 'Gecikti',
      };

  Color get renk => switch (this) {
        _GorevDurum.yapilacak => const Color(0xFF64748B),
        _GorevDurum.devam => const Color(0xFFD97706),
        _GorevDurum.tamam => const Color(0xFF16A34A),
        _GorevDurum.geciken => const Color(0xFFDC2626),
      };
}

class _GorevKaydi {
  const _GorevKaydi({
    required this.baslik,
    required this.konum,
    required this.kaynak,
    required this.kaynakNot,
    required this.durum,
    required this.sorumlu,
    required this.termin,
    required this.oncelik,
  });

  final String baslik;
  final String konum;
  final _GorevKaynak kaynak;
  final String kaynakNot;
  final _GorevDurum durum;
  final String sorumlu;
  final String termin;
  final String oncelik;
}

const _gorevKayitlari = <_GorevKaydi>[
  _GorevKaydi(
    baslik: 'Alçıpan derz eksiklerini tamamla',
    konum: 'A Blok · 3. Kat · Daire 12',
    kaynak: _GorevKaynak.sahaTuru,
    kaynakNot: 'Tespit · Göreve dönüştü',
    durum: _GorevDurum.yapilacak,
    sorumlu: 'Alçıpan Ekibi',
    termin: '28 Eyl',
    oncelik: 'Yüksek',
  ),
  _GorevKaydi(
    baslik: 'Kenar koruma eksiklerini kapat',
    konum: 'A Blok · Genel saha',
    kaynak: _GorevKaynak.sahaTuru,
    kaynakNot: 'Tespit · A Blok turu',
    durum: _GorevDurum.geciken,
    sorumlu: 'İSG Ekibi',
    termin: '25 Eyl',
    oncelik: 'Yüksek',
  ),
  _GorevKaydi(
    baslik: 'Elektrik panosu düzenini düzelt',
    konum: 'Şantiye geneli',
    kaynak: _GorevKaynak.kontrol,
    kaynakNot: 'İSG açılış · Uygun değil',
    durum: _GorevDurum.devam,
    sorumlu: 'Elektrik Ekibi',
    termin: '27 Eyl',
    oncelik: 'Yüksek',
  ),
  _GorevKaydi(
    baslik: 'Paspayı ve sehpa yerleşimini tamamla',
    konum: 'A Blok · 2. Kat',
    kaynak: _GorevKaynak.kontrol,
    kaynakNot: 'Kalıp-donatı · Uygun değil',
    durum: _GorevDurum.yapilacak,
    sorumlu: 'Demir Ekibi',
    termin: '29 Eyl',
    oncelik: 'Orta',
  ),
  _GorevKaydi(
    baslik: 'Hasarlı malzeme tutanağını kapat',
    konum: 'Malzeme sahası',
    kaynak: _GorevKaynak.kontrol,
    kaynakNot: 'Mal kabul · Uygun değil',
    durum: _GorevDurum.tamam,
    sorumlu: 'Depo',
    termin: '24 Eyl',
    oncelik: 'Orta',
  ),
  _GorevKaydi(
    baslik: 'Merdiven korkuluğu montajı',
    konum: 'B Blok · 1. Kat',
    kaynak: _GorevKaynak.manuel,
    kaynakNot: 'Manuel görev',
    durum: _GorevDurum.devam,
    sorumlu: 'İnce İşler',
    termin: '30 Eyl',
    oncelik: 'Normal',
  ),
];

class _GorevlerDesk extends StatefulWidget {
  const _GorevlerDesk({required this.onBack});

  final VoidCallback onBack;

  @override
  State<_GorevlerDesk> createState() => _GorevlerDeskState();
}

class _GorevlerDeskState extends State<_GorevlerDesk> {
  _GorevKaynak? _kaynak;

  List<_GorevKaydi> get _gorunen => [
        for (final gorev in _gorevKayitlari)
          if (_kaynak == null || gorev.kaynak == _kaynak) gorev,
      ];

  int _durumAdet(_GorevDurum durum) => _gorevKayitlari.where((g) => g.durum == durum).length;

  void _kaynakSec(_GorevKaynak kaynak) {
    setState(() => _kaynak = _kaynak == kaynak ? null : kaynak);
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        _ModulDeskUst(
          title: 'Görevler',
          moduleIcon: _ModulDeskMark.sahaIcon,
          moduleColor: _ModulDeskMark.sahaColor,
          backKey: const Key('gorevler-back'),
          onBack: widget.onBack,
          backLabel: 'Saha',
          trailing: Material(
            color: Colors.transparent,
            child: InkWell(
              key: const Key('gorevler-open-app'),
              onTap: () => _keepInPro(context),
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
        const Text(
          'Saha turu tespiti, kontrol uygunsuzluğu ve manuel görev burada birleşir.',
          style: TextStyle(fontFamily: 'Inter', fontSize: 12, height: 1.35, color: ProColors.textMuted),
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final kaynak in _GorevKaynak.values) ...[
              if (kaynak != _GorevKaynak.sahaTuru) const SizedBox(width: 8),
              Expanded(
                child: _GorevKaynakKarti(
                  kaynak: kaynak,
                  adet: _gorevKayitlari.where((g) => g.kaynak == kaynak).length,
                  secili: _kaynak == kaynak,
                  onTap: () => _kaynakSec(kaynak),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _GorevlerKpi(
                title: 'Toplam Görev',
                value: '${_gorevKayitlari.length}',
                color: const Color(0xFF1D4ED8),
                icon: Icons.checklist_outlined,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _GorevlerKpi(
                title: 'Tamamlanan',
                value: '${_durumAdet(_GorevDurum.tamam)}',
                color: const Color(0xFF16A34A),
                icon: Icons.check_circle_outline,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _GorevlerKpi(
                title: 'Devam ediyor',
                value: '${_durumAdet(_GorevDurum.devam)}',
                color: const Color(0xFFD97706),
                icon: Icons.timelapse_outlined,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _GorevlerKpi(
                title: 'Geciken',
                value: '${_durumAdet(_GorevDurum.geciken)}',
                color: const Color(0xFFDC2626),
                icon: Icons.warning_amber_outlined,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        const Text(
          'Görev Listesi',
          style: TextStyle(fontFamily: 'Rajdhani', fontWeight: FontWeight.w700, fontSize: 16, color: ProColors.text),
        ),
        const SizedBox(height: 8),
        for (final gorev in _gorunen) ...[
          _GorevKarti(gorev: gorev),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _GorevKaynakKarti extends StatelessWidget {
  const _GorevKaynakKarti({
    required this.kaynak,
    required this.adet,
    required this.secili,
    required this.onTap,
  });

  final _GorevKaynak kaynak;
  final int adet;
  final bool secili;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: kaynak.renk.withValues(alpha: secili ? 0.22 : 0.12),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        key: Key('gorev-kaynak-${kaynak.name}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 108,
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: secili ? kaynak.renk : kaynak.renk.withValues(alpha: 0.28)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(kaynak.icon, size: 16, color: kaynak.renk),
                  const Spacer(),
                  Text(
                    '$adet',
                    style: TextStyle(
                      fontFamily: 'Rajdhani',
                      fontWeight: FontWeight.w700,
                      fontSize: 24,
                      height: 1.5,
                      color: kaynak.renk,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                kaynak.ad,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontFamily: 'Rajdhani', fontWeight: FontWeight.w700, fontSize: 14, height: 1.2, color: ProColors.text),
              ),
              const SizedBox(height: 2),
              Text(
                kaynak.akis,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontFamily: 'Inter', fontSize: 10, height: 1.25, color: ProColors.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GorevlerKpi extends StatelessWidget {
  const _GorevlerKpi({required this.title, required this.value, required this.color, required this.icon});

  final String title;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _kImalatMetrikKartYukseklik,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            top: 0,
            right: 0,
            child: Icon(icon, color: Colors.white.withValues(alpha: 0.85), size: 16),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontFamily: 'Rajdhani', fontWeight: FontWeight.w700, fontSize: 24, height: 1.05, color: Colors.white),
                ),
                const SizedBox(height: 3),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontFamily: 'Inter', fontSize: 11, height: 1.2, fontWeight: FontWeight.w600, color: Color(0xF2FFFFFF)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GorevKarti extends StatelessWidget {
  const _GorevKarti({required this.gorev});

  final _GorevKaydi gorev;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  gorev.baslik,
                  style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: 14, height: 1.25, color: ProColors.text),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: gorev.durum.renk.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  gorev.durum.ad,
                  style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 10, color: gorev.durum.renk),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.place_outlined, size: 13, color: ProColors.textMuted),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  gorev.konum,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: ProColors.textMuted),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _GorevEtiket(label: gorev.kaynak.ad, renk: gorev.kaynak.renk),
              _GorevEtiket(label: gorev.kaynakNot),
              _GorevEtiket(label: gorev.oncelik),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.engineering_outlined, size: 13, color: ProColors.textMuted),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  gorev.sorumlu,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: ProColors.textMuted),
                ),
              ),
              const Icon(Icons.calendar_today_outlined, size: 12, color: ProColors.textMuted),
              const SizedBox(width: 4),
              Text(gorev.termin, style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: ProColors.textMuted)),
            ],
          ),
        ],
      ),
    );
  }
}

class _GorevEtiket extends StatelessWidget {
  const _GorevEtiket({required this.label, this.renk});

  final String label;
  final Color? renk;

  @override
  Widget build(BuildContext context) {
    final vurgu = renk ?? ProColors.textMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: vurgu.withValues(alpha: renk == null ? 0.08 : 0.14),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: vurgu.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(fontFamily: 'Inter', fontSize: 10, fontWeight: FontWeight.w600, color: vurgu),
      ),
    );
  }
}
