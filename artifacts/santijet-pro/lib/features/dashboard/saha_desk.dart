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
        const _ModulDeskUst(
          title: 'Saha',
          moduleIcon: _ModulDeskMark.sahaIcon,
          moduleColor: _ModulDeskMark.sahaColor,
        ),
        const SizedBox(height: 8),
        const Text(
          'Saha operasyonlarını kolayca yönetin',
          style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: ProColors.textMuted),
        ),
        const SizedBox(height: 12),
        const _ProjectHero(),
        const SizedBox(height: 10),
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
  const _SahaAction(this.title, this.subtitle, this.icon, this.color, {this.later});

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String? later;
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

  static const actions = <_SahaAction>[
    _SahaAction('Günlük Rapor', 'Saha raporu', Icons.description_outlined, Color(0xFF1D4ED8), later: 'Günlük Rapor'),
    _SahaAction('Puantaj', 'Giriş / Çıkış', Icons.groups_outlined, Color(0xFF2563EB)),
    _SahaAction('İmalat', 'Günlük kayıt', Icons.bar_chart_rounded, Color(0xFF0F766E)),
    _SahaAction('Görevler', 'Ata / takip et', Icons.task_alt_outlined, Color(0xFF7C3AED)),
    _SahaAction('Personel', 'Ekip yönetimi', Icons.engineering_outlined, Color(0xFFCA8A04)),
    _SahaAction('İş Makineleri', 'Kullanım / yakıt', Icons.agriculture_outlined, Color(0xFF0891B2)),
    _SahaAction('Malzeme', 'Giriş / tüketim', Icons.inventory_2_outlined, Color(0xFFEAB308)),
    _SahaAction('Kontrol Listesi', 'Saha kontrolleri', Icons.checklist_outlined, Color(0xFFF97316), later: 'Kontrol Listesi'),
    _SahaAction('Saha Turu', 'Denetim planı', Icons.place_outlined, Color(0xFFEF4444), later: 'Saha Turu'),
  ];

  @override
  Widget build(BuildContext context) {
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
            onOpenPuantaj: onOpenPuantaj,
            onOpenPersonel: onOpenPersonel,
            onOpenGorevler: onOpenGorevler,
            onOpenMakine: onOpenMakine,
            onOpenImalat: onOpenImalat,
            onOpenMalzeme: onOpenMalzeme,
            onOpenSahaTuru: onOpenSahaTuru,
          ),
        ),
      ],
    );
  }
}

class _SahaActionTile extends StatelessWidget {
  const _SahaActionTile({
    required this.action,
    this.onOpenPuantaj,
    this.onOpenPersonel,
    this.onOpenGorevler,
    this.onOpenMakine,
    this.onOpenImalat,
    this.onOpenMalzeme,
    this.onOpenSahaTuru,
  });

  final _SahaAction action;
  final VoidCallback? onOpenPuantaj;
  final VoidCallback? onOpenPersonel;
  final VoidCallback? onOpenGorevler;
  final VoidCallback? onOpenMakine;
  final VoidCallback? onOpenImalat;
  final VoidCallback? onOpenMalzeme;
  final VoidCallback? onOpenSahaTuru;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: action.color.withValues(alpha: 0.16),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        key: switch (action.title) {
          'Puantaj' => const Key('saha-open-puantaj'),
          'Personel' => const Key('saha-open-personel'),
          'Görevler' => const Key('saha-open-gorevler'),
          'İş Makineleri' => const Key('saha-open-makine'),
          'İmalat' => const Key('saha-open-imalat'),
          'Günlük Rapor' => const Key('saha-open-daily-report'),
          'Malzeme' => const Key('saha-open-malzeme'),
          'Saha Turu' => const Key('saha-open-saha-turu'),
          _ => null,
        },
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          if (action.title == 'Puantaj' && onOpenPuantaj != null) {
            onOpenPuantaj!();
            return;
          }
          if (action.title == 'Personel' && onOpenPersonel != null) {
            onOpenPersonel!();
            return;
          }
          if (action.title == 'Görevler' && onOpenGorevler != null) {
            onOpenGorevler!();
            return;
          }
          if (action.title == 'İş Makineleri' && onOpenMakine != null) {
            onOpenMakine!();
            return;
          }
          if (action.title == 'İmalat' && onOpenImalat != null) {
            onOpenImalat!();
            return;
          }
          if (action.title == 'Malzeme' && onOpenMalzeme != null) {
            onOpenMalzeme!();
            return;
          }
          if (action.title == 'Saha Turu' && onOpenSahaTuru != null) {
            onOpenSahaTuru!();
            return;
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${action.later} daha sonra eklenecek.')),
          );
        },
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

