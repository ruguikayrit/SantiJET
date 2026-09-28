part of 'dashboard_screen.dart';

enum _PersonelPane { tum, ekipler, gorevler, belgeler }

extension on _PersonelPane {
  String get label => switch (this) {
        _PersonelPane.tum => 'Tüm Personel',
        _PersonelPane.ekipler => 'Ekipler',
        _PersonelPane.gorevler => 'Görevler',
        _PersonelPane.belgeler => 'Belgeler',
      };
}

class _PersonelDesk extends StatefulWidget {
  const _PersonelDesk({required this.onBack});

  final VoidCallback onBack;

  @override
  State<_PersonelDesk> createState() => _PersonelDeskState();
}

class _PersonelDeskState extends State<_PersonelDesk> {
  _PersonelPane _pane = _PersonelPane.tum;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        const _TopBar(),
        const SizedBox(height: 8),
        Row(
          children: [
            IconButton(
              key: const Key('personel-back'),
              onPressed: widget.onBack,
              icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: ProColors.text),
            ),
            const Text(
              'Saha',
              style: TextStyle(fontFamily: 'Rajdhani', fontWeight: FontWeight.w700, fontSize: 18, color: ProColors.text),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CircleAvatar(
              radius: 22,
              backgroundColor: Color(0xFFCA8A04),
              child: Icon(Icons.engineering_outlined, color: Colors.white),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Personel',
                    style: TextStyle(fontFamily: 'Rajdhani', fontWeight: FontWeight.w700, fontSize: 26, color: ProColors.text),
                  ),
                  Text(
                    'Ekipleri ve saha personelini yönetin',
                    style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: ProColors.textMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const _PersonelProjectChip(),
          ],
        ),
        const SizedBox(height: 12),
        const Row(
          children: [
            Expanded(
              child: _PersonelKpi(
                title: 'Toplam Personel',
                color: Color(0xFF1D4ED8),
                icon: Icons.groups_outlined,
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: _PersonelKpi(
                title: 'Mevcut',
                color: Color(0xFF16A34A),
                icon: Icons.person_outline,
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: _PersonelKpi(
                title: 'İzinli',
                color: Color(0xFFD97706),
                icon: Icons.beach_access_outlined,
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: _PersonelKpi(
                title: 'Raporlu',
                color: Color(0xFF1E3A5F),
                icon: Icons.person_off_outlined,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final pane in _PersonelPane.values)
              _FilterPill(
                label: pane.label,
                selected: pane == _pane,
                onTap: () => setState(() => _pane = pane),
              ),
          ],
        ),
        const SizedBox(height: 12),
        switch (_pane) {
          _PersonelPane.tum => const _PersonelTumPane(),
          _PersonelPane.ekipler => const _PersonelEmptyPane(
              title: 'Ekipler',
              body: 'Ekip kartları proje bağlanınca dolacak.',
            ),
          _PersonelPane.gorevler => const _PersonelEmptyPane(
              title: 'Görevler',
              body: 'Personel görevleri proje bağlanınca dolacak.',
            ),
          _PersonelPane.belgeler => const _PersonelEmptyPane(
              title: 'Belgeler',
              body: 'SGK, iş güvenliği ve ekip belgeleri proje bağlanınca listelenecek.',
            ),
        },
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _keepInPro(context),
                icon: const Icon(Icons.group_add_outlined),
                label: const Text('Ekip Oluştur'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: ProColors.text,
                  side: const BorderSide(color: ProColors.border),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton.icon(
                key: const Key('personel-open-app'),
                onPressed: () => _keepInPro(context),
                icon: const Icon(Icons.add),
                label: const Text('Personel Ekle'),
                style: FilledButton.styleFrom(
                  backgroundColor: ProColors.electricBlue,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PersonelProjectChip extends StatelessWidget {
  const _PersonelProjectChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 132,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: ProColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ProColors.border),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'AKTİF PROJE',
            style: TextStyle(
              fontFamily: 'Rajdhani',
              fontSize: 9,
              letterSpacing: 0.8,
              color: Color(0xFF9EC1FF),
            ),
          ),
          SizedBox(height: 2),
          Text(
            'Henüz proje yok',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Rajdhani',
              fontWeight: FontWeight.w700,
              fontSize: 12,
              color: ProColors.text,
            ),
          ),
          SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.place_outlined, size: 12, color: ProColors.textMuted),
              SizedBox(width: 2),
              Text('—', style: TextStyle(fontFamily: 'Inter', fontSize: 10, color: ProColors.textMuted)),
            ],
          ),
        ],
      ),
    );
  }
}

class _PersonelKpi extends StatelessWidget {
  const _PersonelKpi({required this.title, required this.color, required this.icon});

  final String title;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 10, 4, 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Icon(icon, color: Colors.white.withValues(alpha: 0.9), size: 16),
              const Spacer(),
              Icon(Icons.chevron_right, color: Colors.white.withValues(alpha: 0.6), size: 16),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            '—',
            style: TextStyle(fontFamily: 'Rajdhani', fontWeight: FontWeight.w700, fontSize: 20, color: Colors.white),
          ),
          Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontFamily: 'Inter', fontSize: 9, color: Color(0xF2FFFFFF)),
          ),
        ],
      ),
    );
  }
}

class _PersonelTumPane extends StatelessWidget {
  const _PersonelTumPane();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          decoration: _cardDecoration(),
          child: const Row(
            children: [
              Icon(Icons.search, color: ProColors.textMuted, size: 18),
              SizedBox(width: 8),
              Expanded(
                child: TextField(
                  enabled: false,
                  decoration: InputDecoration(
                    hintText: 'Personel ara...',
                    hintStyle: TextStyle(color: ProColors.textMuted, fontSize: 14),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                ),
              ),
              Text('Tümü', style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: ProColors.textMuted)),
              Icon(Icons.keyboard_arrow_down, color: ProColors.textMuted, size: 18),
              SizedBox(width: 4),
              Icon(Icons.tune, color: ProColors.textMuted, size: 18),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            const Expanded(child: _ReportSectionTitle('Ekipler')),
            TextButton(
              onPressed: () => _keepInPro(context),
              child: const Text('Tümü'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 1.05,
          children: const [
            _PersonelTeamPlaceholder(),
            _PersonelTeamPlaceholder(),
            _PersonelTeamPlaceholder(),
            _PersonelTeamPlaceholder(),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            const Expanded(child: _ReportSectionTitle('Personel Listesi')),
            TextButton(
              onPressed: () => _keepInPro(context),
              child: const Text('+ Personel Ekle'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: _cardDecoration(),
          child: const Text(
            'Personel listesi proje bağlanınca dolacak.',
            style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: ProColors.textMuted),
          ),
        ),
      ],
    );
  }
}

class _PersonelTeamPlaceholder extends StatelessWidget {
  const _PersonelTeamPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: ProColors.border,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.groups_outlined, size: 16, color: ProColors.textMuted),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  '—',
                  style: TextStyle(fontFamily: 'Rajdhani', fontWeight: FontWeight.w700, fontSize: 14, color: ProColors.textMuted),
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: ProColors.border,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text('—', style: TextStyle(fontFamily: 'Inter', fontSize: 10, color: ProColors.textMuted)),
          ),
          const SizedBox(height: 8),
          const Text('— kişi', style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: ProColors.textMuted)),
          const SizedBox(height: 4),
          const Text('—', style: TextStyle(fontFamily: 'Inter', fontSize: 10, color: ProColors.textFaint)),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: const LinearProgressIndicator(value: 0, minHeight: 4, backgroundColor: ProColors.border, color: ProColors.textMuted),
          ),
        ],
      ),
    );
  }
}

class _PersonelEmptyPane extends StatelessWidget {
  const _PersonelEmptyPane({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontFamily: 'Rajdhani', fontWeight: FontWeight.w700, fontSize: 16, color: ProColors.text)),
          const SizedBox(height: 6),
          Text(body, style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: ProColors.textMuted)),
        ],
      ),
    );
  }
}
