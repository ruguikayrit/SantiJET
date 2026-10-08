part of 'dashboard_screen.dart';

class _SahaDesk extends StatelessWidget {
  const _SahaDesk({
    required this.onOpenPuantaj,
    required this.onOpenPersonel,
    required this.onOpenGorevler,
    required this.onOpenImalat,
    required this.onOpenMakine,
    required this.onOpenMalzeme,
    required this.onOpenSahaTuru,
  });

  final VoidCallback onOpenPuantaj;
  final VoidCallback onOpenPersonel;
  final VoidCallback onOpenGorevler;
  final VoidCallback onOpenImalat;
  final VoidCallback onOpenMakine;
  final VoidCallback onOpenMalzeme;
  final VoidCallback onOpenSahaTuru;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        _ModulDeskUst(
          title: 'Saha',
          moduleIcon: _ModulDeskMark.sahaIcon,
          moduleColor: _ModulDeskMark.sahaColor,
          trailing: const SizedBox.shrink(),
        ),
        const SizedBox(height: 8),
        const Text(
          'Saha operasyonlarını kolayca yönetin',
          style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: ProColors.textMuted),
        ),
        const SizedBox(height: 12),
        const _SahaProgress(),
        const SizedBox(height: 14),
        _SahaGenelBody(
          onOpenPuantaj: onOpenPuantaj,
          onOpenPersonel: onOpenPersonel,
          onOpenGorevler: onOpenGorevler,
          onOpenMakine: onOpenMakine,
          onOpenImalat: onOpenImalat,
          onOpenMalzeme: onOpenMalzeme,
          onOpenSahaTuru: onOpenSahaTuru,
        ),
      ],
    );
  }
}

class _SahaAction {
  const _SahaAction(this.id, this.title, this.subtitle, this.icon, this.color);

  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
}

class _SahaGenelBody extends StatelessWidget {
  const _SahaGenelBody({
    required this.onOpenPuantaj,
    required this.onOpenPersonel,
    required this.onOpenGorevler,
    required this.onOpenMakine,
    required this.onOpenImalat,
    required this.onOpenMalzeme,
    required this.onOpenSahaTuru,
  });

  final VoidCallback onOpenPuantaj;
  final VoidCallback onOpenPersonel;
  final VoidCallback onOpenGorevler;
  final VoidCallback onOpenMakine;
  final VoidCallback onOpenImalat;
  final VoidCallback onOpenMalzeme;
  final VoidCallback onOpenSahaTuru;

  /// 3 sütunlu ızgarada yatay/dikey komşular birbirine yakın tonda olmasın diye renkler yerleştirildi.
  static const actions = <_SahaAction>[
    _SahaAction('puantaj', 'Puantaj', 'Giriş / Çıkış', Icons.groups_outlined, Color(0xFF9333EA)),
    _SahaAction('imalat', 'İmalat', 'Günlük kayıt', Icons.bar_chart_rounded, Color(0xFF0D9488)),
    _SahaAction('gorevler', 'Görevler', 'Ata / takip et', Icons.task_alt_outlined, Color(0xFF0891B2)),
    _SahaAction('personel', 'Personel', 'Ekip yönetimi', Icons.engineering_outlined, Color(0xFFCA8A04)),
    _SahaAction('makine', 'İş Makineleri', 'Kullanım / yakıt', Icons.agriculture_outlined, Color(0xFFA855F7)),
    _SahaAction('malzeme', 'Malzeme', 'Giriş / tüketim', Icons.inventory_2_outlined, Color(0xFF16A34A)),
  ];

  @override
  Widget build(BuildContext context) {
    final handlers = <String, VoidCallback>{
      'puantaj': onOpenPuantaj,
      'imalat': onOpenImalat,
      'gorevler': onOpenGorevler,
      'personel': onOpenPersonel,
      'makine': onOpenMakine,
      'malzeme': onOpenMalzeme,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: actions.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            mainAxisExtent: 112,
          ),
          itemBuilder: (context, index) => _SahaActionTile(
            action: actions[index],
            onTap: handlers[actions[index].id]!,
          ),
        ),
        const SizedBox(height: 8),
        _SahaTuruKarti(onTap: onOpenSahaTuru),
      ],
    );
  }
}

/// Saha turu gözlem, tespit ve kontrol formunu tek akışta topladığı için
/// ızgaradaki karolardan ayrı, tam genişlikte duruyor.
class _SahaTuruKarti extends StatelessWidget {
  const _SahaTuruKarti({required this.onTap});

  static const _renk = Color(0xFFDC2626);

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _renk.withValues(alpha: 0.16),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        key: const Key('saha-open-saha-turu'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              const Icon(Icons.place_outlined, color: _renk, size: 26),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Saha Turu',
                      style: TextStyle(fontFamily: 'Rajdhani', fontWeight: FontWeight.w700, fontSize: 15, color: ProColors.text),
                    ),
                    Text(
                      'Gözlem · tespit · kontrol formu',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: ProColors.textMuted),
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

class _SahaActionTile extends StatelessWidget {
  const _SahaActionTile({required this.action, required this.onTap});

  final _SahaAction action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: action.color.withValues(alpha: 0.16),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        key: Key('saha-open-${action.id}'),
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(action.icon, color: action.color, size: 26),
              const SizedBox(height: 4),
              Text(
                action.title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontFamily: 'Rajdhani', fontWeight: FontWeight.w700, fontSize: 13, color: ProColors.text),
              ),
              Text(
                action.subtitle,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: ProColors.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

