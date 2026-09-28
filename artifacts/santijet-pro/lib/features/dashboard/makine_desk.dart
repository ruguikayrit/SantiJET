part of 'dashboard_screen.dart';

enum _MakinePeriod { gunluk, haftalik, aylik }

extension on _MakinePeriod {
  String get label => switch (this) {
        _MakinePeriod.gunluk => 'Günlük',
        _MakinePeriod.haftalik => 'Haftalık',
        _MakinePeriod.aylik => 'Aylık',
      };
}

enum _MakinePane { liste, operatorler, ozet }

extension on _MakinePane {
  String get label => switch (this) {
        _MakinePane.liste => 'Makine Listesi',
        _MakinePane.operatorler => 'Operatörler',
        _MakinePane.ozet => 'Günlük Özet',
      };
}

enum _MakineKindFilter { tum, isMakinesi, vasita }

extension on _MakineKindFilter {
  String get label => switch (this) {
        _MakineKindFilter.tum => 'Tümü',
        _MakineKindFilter.isMakinesi => 'İş makinesi',
        _MakineKindFilter.vasita => 'Vasıta',
      };
}

class _MakineDesk extends StatefulWidget {
  const _MakineDesk({required this.onBack});

  final VoidCallback onBack;

  @override
  State<_MakineDesk> createState() => _MakineDeskState();
}

class _MakineDeskState extends State<_MakineDesk> {
  _MakinePeriod _period = _MakinePeriod.gunluk;
  _MakinePane _pane = _MakinePane.liste;
  _MakineKindFilter _kind = _MakineKindFilter.tum;

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
              key: const Key('makine-back'),
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
              backgroundColor: Color(0xFF0891B2),
              child: Icon(Icons.agriculture_outlined, color: Colors.white),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'İş Makineleri',
                    style: TextStyle(fontFamily: 'Rajdhani', fontWeight: FontWeight.w700, fontSize: 24, color: ProColors.text),
                  ),
                  Text(
                    'Makine ve vasıta kullanımını, çalışma saatlerini takip edin',
                    style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: ProColors.textMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const _MakineProjectChip(),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _MakineDateChip(date: DateTime.now()),
            const SizedBox(width: 8),
            Expanded(
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                alignment: WrapAlignment.end,
                children: [
                  for (final period in _MakinePeriod.values)
                    _FilterPill(
                      label: period.label,
                      selected: period == _period,
                      onTap: () => setState(() => _period = period),
                    ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Row(
          children: [
            Expanded(
              child: _MakineKpi(
                title: 'Toplam Kayıt',
                color: Color(0xFF1D4ED8),
                icon: Icons.local_shipping_outlined,
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: _MakineKpi(
                title: 'Aktif Makine',
                color: Color(0xFF16A34A),
                icon: Icons.precision_manufacturing_outlined,
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: _MakineKpi(
                title: 'Çalışma Saati',
                color: Color(0xFFD97706),
                icon: Icons.schedule_outlined,
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: _MakineKpi(
                title: 'Vasıta',
                color: Color(0xFF1E3A5F),
                icon: Icons.directions_car_outlined,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final pane in _MakinePane.values)
              _FilterPill(
                label: pane.label,
                selected: pane == _pane,
                onTap: () => setState(() => _pane = pane),
              ),
          ],
        ),
        const SizedBox(height: 12),
        switch (_pane) {
          _MakinePane.liste => _MakineListePane(
              kind: _kind,
              onKindChanged: (value) => setState(() => _kind = value),
            ),
          _MakinePane.operatorler => const _MakineEmptyPane(
              title: 'Operatörler',
              body: 'Operatör atamaları proje bağlanınca dolacak.',
            ),
          _MakinePane.ozet => const _MakineEmptyPane(
              title: 'Günlük Özet',
              body: 'İş makinesi özeti proje bağlanınca dolacak.',
            ),
        },
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _keepInPro(context),
                icon: const Icon(Icons.download_outlined),
                label: const Text('Puantaj Raporu'),
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
                key: const Key('makine-open-app'),
                onPressed: () => _keepInPro(context),
                icon: const Icon(Icons.add),
                label: const Text('Makine Kaydı'),
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

class _MakineProjectChip extends StatelessWidget {
  const _MakineProjectChip();

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

class _MakineDateChip extends StatelessWidget {
  const _MakineDateChip({required this.date});

  final DateTime date;

  static const _months = [
    'Ocak',
    'Şubat',
    'Mart',
    'Nisan',
    'Mayıs',
    'Haziran',
    'Temmuz',
    'Ağustos',
    'Eylül',
    'Ekim',
    'Kasım',
    'Aralık',
  ];

  static const _weekdays = [
    'Pazartesi',
    'Salı',
    'Çarşamba',
    'Perşembe',
    'Cuma',
    'Cumartesi',
    'Pazar',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: ProColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ProColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${date.day} ${_months[date.month - 1]} ${date.year}',
                style: const TextStyle(
                  fontFamily: 'Rajdhani',
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: ProColors.text,
                ),
              ),
              Text(
                _weekdays[date.weekday - 1],
                style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: ProColors.textMuted),
              ),
            ],
          ),
          const SizedBox(width: 4),
          const Icon(Icons.keyboard_arrow_down, color: ProColors.textMuted, size: 18),
        ],
      ),
    );
  }
}

class _MakineKpi extends StatelessWidget {
  const _MakineKpi({required this.title, required this.color, required this.icon});

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

class _MakineListePane extends StatelessWidget {
  const _MakineListePane({required this.kind, required this.onKindChanged});

  final _MakineKindFilter kind;
  final ValueChanged<_MakineKindFilter> onKindChanged;

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
                    hintText: 'Makine ara...',
                    hintStyle: TextStyle(color: ProColors.textMuted, fontSize: 14),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                ),
              ),
              Icon(Icons.tune, color: ProColors.textMuted, size: 18),
            ],
          ),
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final filter in _MakineKindFilter.values) ...[
                _FilterPill(
                  label: filter.label,
                  selected: filter == kind,
                  onTap: () => onKindChanged(filter),
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Günlük raporda İş makinesi ve Vasıta ayrı kaydedilir.',
          style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: ProColors.textFaint),
        ),
        const SizedBox(height: 12),
        for (var i = 0; i < 3; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          const _MakineRecordPlaceholder(),
        ],
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: _cardDecoration(),
          child: const Text(
            'Makine listesi proje bağlanınca dolacak.',
            style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: ProColors.textMuted),
          ),
        ),
      ],
    );
  }
}

class _MakineRecordPlaceholder extends StatelessWidget {
  const _MakineRecordPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _cardDecoration(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF0891B2).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.agriculture_outlined, color: Color(0xFF0891B2), size: 24),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Expanded(
                      child: Text(
                        '—',
                        style: TextStyle(
                          fontFamily: 'Rajdhani',
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: ProColors.textMuted,
                        ),
                      ),
                    ),
                    Icon(Icons.more_vert, size: 18, color: ProColors.textFaint),
                  ],
                ),
                const SizedBox(height: 4),
                const Text('Tür — · Plaka —', style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: ProColors.textFaint)),
                const SizedBox(height: 6),
                const Row(
                  children: [
                    Icon(Icons.business_outlined, size: 12, color: ProColors.textMuted),
                    SizedBox(width: 4),
                    Text('Firma —', style: TextStyle(fontFamily: 'Inter', fontSize: 10, color: ProColors.textMuted)),
                  ],
                ),
                const SizedBox(height: 4),
                const Row(
                  children: [
                    Icon(Icons.schedule_outlined, size: 12, color: ProColors.textMuted),
                    SizedBox(width: 4),
                    Text('Çalışma saati —', style: TextStyle(fontFamily: 'Inter', fontSize: 10, color: ProColors.textMuted)),
                    SizedBox(width: 10),
                    Icon(Icons.person_outline, size: 12, color: ProColors.textMuted),
                    SizedBox(width: 4),
                    Text('Operatör —', style: TextStyle(fontFamily: 'Inter', fontSize: 10, color: ProColors.textMuted)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MakineEmptyPane extends StatelessWidget {
  const _MakineEmptyPane({required this.title, required this.body});

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
