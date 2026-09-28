part of 'dashboard_screen.dart';

enum _GorevlerPane { liste, takvim, kanban, benim }

extension on _GorevlerPane {
  String get label => switch (this) {
        _GorevlerPane.liste => 'Görev Listesi',
        _GorevlerPane.takvim => 'Takvim',
        _GorevlerPane.kanban => 'Kanban',
        _GorevlerPane.benim => 'Benim Görevlerim',
      };
}

class _GorevlerDesk extends StatefulWidget {
  const _GorevlerDesk({required this.onBack});

  final VoidCallback onBack;

  @override
  State<_GorevlerDesk> createState() => _GorevlerDeskState();
}

class _GorevlerDeskState extends State<_GorevlerDesk> {
  _GorevlerPane _pane = _GorevlerPane.liste;

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
              key: const Key('gorevler-back'),
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
              backgroundColor: Color(0xFF7C3AED),
              child: Icon(Icons.task_alt_outlined, color: Colors.white),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Görevler',
                    style: TextStyle(fontFamily: 'Rajdhani', fontWeight: FontWeight.w700, fontSize: 26, color: ProColors.text),
                  ),
                  Text(
                    'Saha görevlerini oluştur, ata ve takip et',
                    style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: ProColors.textMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const _GorevlerProjectChip(),
          ],
        ),
        const SizedBox(height: 12),
        const Row(
          children: [
            Expanded(
              child: _GorevlerKpi(
                title: 'Toplam Görev',
                color: Color(0xFF1D4ED8),
                icon: Icons.checklist_outlined,
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: _GorevlerKpi(
                title: 'Tamamlanan',
                color: Color(0xFF16A34A),
                icon: Icons.check_circle_outline,
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: _GorevlerKpi(
                title: 'Devam ediyor',
                color: Color(0xFFD97706),
                icon: Icons.timelapse_outlined,
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: _GorevlerKpi(
                title: 'Geciken',
                color: Color(0xFFDC2626),
                icon: Icons.warning_amber_outlined,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final pane in _GorevlerPane.values)
              _FilterPill(
                label: pane.label,
                selected: pane == _pane,
                onTap: () => setState(() => _pane = pane),
              ),
          ],
        ),
        const SizedBox(height: 12),
        switch (_pane) {
          _GorevlerPane.liste => const _GorevlerListePane(),
          _GorevlerPane.takvim => const _GorevlerEmptyPane(
              title: 'Takvim',
              body: 'Görev takvimi proje bağlanınca dolacak.',
            ),
          _GorevlerPane.kanban => const _GorevlerEmptyPane(
              title: 'Kanban',
              body: 'Yapılacak, Başladı, Devam ediyor ve Tamamlandı sütunları proje bağlanınca görünür.',
            ),
          _GorevlerPane.benim => const _GorevlerEmptyPane(
              title: 'Benim Görevlerim',
              body: 'Size atanan görevler oturum ve proje bağlandığında listelenecek.',
            ),
        },
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            key: const Key('gorevler-open-app'),
            onPressed: () => _keepInPro(context),
            icon: const Icon(Icons.add),
            label: const Text('Yeni Görev Oluştur'),
            style: FilledButton.styleFrom(
              backgroundColor: ProColors.electricBlue,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ],
    );
  }
}

class _GorevlerProjectChip extends StatelessWidget {
  const _GorevlerProjectChip();

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
              Icon(Icons.keyboard_arrow_down, size: 12, color: ProColors.textMuted),
              SizedBox(width: 2),
              Text('—', style: TextStyle(fontFamily: 'Inter', fontSize: 10, color: ProColors.textMuted)),
            ],
          ),
        ],
      ),
    );
  }
}

class _GorevlerKpi extends StatelessWidget {
  const _GorevlerKpi({required this.title, required this.color, required this.icon});

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

class _GorevlerListePane extends StatelessWidget {
  const _GorevlerListePane();

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
                    hintText: 'Görev ara...',
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
        const SizedBox(height: 10),
        const Text(
          'Durum sırası: Yapılacak → Başladı → Devam ediyor → Tamamlandı',
          style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: ProColors.textFaint),
        ),
        const SizedBox(height: 12),
        for (var i = 0; i < 3; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          const _GorevlerTaskPlaceholder(),
        ],
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: _cardDecoration(),
          child: const Text(
            'Görev listesi proje bağlanınca dolacak.',
            style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: ProColors.textMuted),
          ),
        ),
      ],
    );
  }
}

class _GorevlerTaskPlaceholder extends StatelessWidget {
  const _GorevlerTaskPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _cardDecoration(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: ProColors.border,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.task_outlined, size: 20, color: ProColors.textMuted),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '—',
                  style: TextStyle(fontFamily: 'Rajdhani', fontWeight: FontWeight.w700, fontSize: 15, color: ProColors.textMuted),
                ),
                const SizedBox(height: 4),
                const Row(
                  children: [
                    Icon(Icons.place_outlined, size: 12, color: ProColors.textFaint),
                    SizedBox(width: 4),
                    Text('—', style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: ProColors.textFaint)),
                  ],
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    _GorevlerTagChip(label: '—'),
                    _GorevlerTagChip(label: '—'),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: const LinearProgressIndicator(
                    value: 0,
                    minHeight: 4,
                    backgroundColor: ProColors.border,
                    color: ProColors.textMuted,
                  ),
                ),
                const SizedBox(height: 6),
                const Row(
                  children: [
                    Text('—%', style: TextStyle(fontFamily: 'Inter', fontSize: 10, color: ProColors.textFaint)),
                    Spacer(),
                    Icon(Icons.calendar_today_outlined, size: 12, color: ProColors.textFaint),
                    SizedBox(width: 4),
                    Text('—', style: TextStyle(fontFamily: 'Inter', fontSize: 10, color: ProColors.textFaint)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: ProColors.border,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text('—', style: TextStyle(fontFamily: 'Inter', fontSize: 10, color: ProColors.textMuted)),
          ),
          const Icon(Icons.more_vert, size: 18, color: ProColors.textFaint),
        ],
      ),
    );
  }
}

class _GorevlerTagChip extends StatelessWidget {
  const _GorevlerTagChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: ProColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ProColors.border),
      ),
      child: Text(label, style: const TextStyle(fontFamily: 'Inter', fontSize: 10, color: ProColors.textMuted)),
    );
  }
}

class _GorevlerEmptyPane extends StatelessWidget {
  const _GorevlerEmptyPane({required this.title, required this.body});

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
