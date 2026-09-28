part of 'dashboard_screen.dart';

enum _ImalatPeriod { gunluk, haftalik, aylik }

extension on _ImalatPeriod {
  String get label => switch (this) {
        _ImalatPeriod.gunluk => 'Günlük',
        _ImalatPeriod.haftalik => 'Haftalık',
        _ImalatPeriod.aylik => 'Aylık',
      };
}

enum _ImalatGroupFilter { tum, insaat, elektrik, mekanik, diger }

extension on _ImalatGroupFilter {
  String get label => switch (this) {
        _ImalatGroupFilter.tum => 'Tümü',
        _ImalatGroupFilter.insaat => 'İNŞAAT',
        _ImalatGroupFilter.elektrik => 'ELEKTRİK',
        _ImalatGroupFilter.mekanik => 'MEKANİK',
        _ImalatGroupFilter.diger => 'Diğer',
      };
}

class _ImalatDesk extends StatefulWidget {
  const _ImalatDesk({required this.onBack});

  final VoidCallback onBack;

  @override
  State<_ImalatDesk> createState() => _ImalatDeskState();
}

class _ImalatDeskState extends State<_ImalatDesk> {
  _ImalatPeriod _period = _ImalatPeriod.gunluk;
  _ImalatGroupFilter _group = _ImalatGroupFilter.tum;

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
              key: const Key('imalat-back'),
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
              backgroundColor: Color(0xFF059669),
              child: Icon(Icons.bar_chart_rounded, color: Colors.white),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Günlük İmalatlar',
                    style: TextStyle(fontFamily: 'Rajdhani', fontWeight: FontWeight.w700, fontSize: 24, color: ProColors.text),
                  ),
                  Text(
                    'Saha imalatlarını kaydet, takip et ve raporla',
                    style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: ProColors.textMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const _ImalatProjectChip(),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _ImalatDateChip(date: DateTime.now()),
            const SizedBox(width: 8),
            Expanded(
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                alignment: WrapAlignment.end,
                children: [
                  for (final period in _ImalatPeriod.values)
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
              child: _ImalatKpi(
                title: 'Toplam İmalat',
                color: Color(0xFF1D4ED8),
                icon: Icons.layers_outlined,
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: _ImalatKpi(
                title: 'Tamamlanan',
                color: Color(0xFF16A34A),
                icon: Icons.check_circle_outline,
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: _ImalatKpi(
                title: 'Devam eden',
                color: Color(0xFFD97706),
                icon: Icons.timelapse_outlined,
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: _ImalatKpi(
                title: 'Geciken',
                color: Color(0xFFDC2626),
                icon: Icons.warning_amber_outlined,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final filter in _ImalatGroupFilter.values) ...[
                _FilterPill(
                  label: filter == _ImalatGroupFilter.tum ? 'Tümü' : filter.label,
                  selected: filter == _group,
                  onTap: () => setState(() => _group = filter),
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        for (var i = 0; i < 3; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          const _ImalatRecordPlaceholder(),
        ],
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: _cardDecoration(),
          child: const Text(
            'Günlük imalat kaydı proje bağlanınca dolacak.',
            style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: ProColors.textMuted),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _keepInPro(context),
                icon: const Icon(Icons.flash_on_outlined),
                label: const Text('Hızlı Kayıt'),
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
                key: const Key('imalat-open-app'),
                onPressed: () => _keepInPro(context),
                icon: const Icon(Icons.add),
                label: const Text('Yeni Günlük İmalat'),
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

class _ImalatProjectChip extends StatelessWidget {
  const _ImalatProjectChip();

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

class _ImalatDateChip extends StatelessWidget {
  const _ImalatDateChip({required this.date});

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

class _ImalatKpi extends StatelessWidget {
  const _ImalatKpi({required this.title, required this.color, required this.icon});

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

class _ImalatRecordPlaceholder extends StatelessWidget {
  const _ImalatRecordPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: _cardDecoration(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: ProColors.border,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.image_outlined, color: ProColors.textFaint, size: 28),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: ProColors.border,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.construction_outlined, size: 16, color: ProColors.textMuted),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '—',
                            style: TextStyle(
                              fontFamily: 'Rajdhani',
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: ProColors.textMuted,
                            ),
                          ),
                          Row(
                            children: [
                              Icon(Icons.place_outlined, size: 12, color: ProColors.textFaint),
                              SizedBox(width: 4),
                              Text('—', style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: ProColors.textFaint)),
                            ],
                          ),
                        ],
                      ),
                    ),
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
                    Icon(Icons.groups_outlined, size: 14, color: ProColors.textFaint),
                    SizedBox(width: 4),
                    Text('— kişi', style: TextStyle(fontFamily: 'Inter', fontSize: 10, color: ProColors.textFaint)),
                  ],
                ),
                const SizedBox(height: 8),
                const Row(
                  children: [
                    Icon(Icons.straighten_outlined, size: 14, color: ProColors.textMuted),
                    SizedBox(width: 4),
                    Text('Metraj —', style: TextStyle(fontFamily: 'Inter', fontSize: 10, color: ProColors.textMuted)),
                    SizedBox(width: 10),
                    Icon(Icons.schedule_outlined, size: 14, color: ProColors.textMuted),
                    SizedBox(width: 4),
                    Text('Süre —', style: TextStyle(fontFamily: 'Inter', fontSize: 10, color: ProColors.textMuted)),
                    SizedBox(width: 10),
                    Icon(Icons.photo_outlined, size: 14, color: ProColors.textMuted),
                    SizedBox(width: 4),
                    Text('— fotoğraf', style: TextStyle(fontFamily: 'Inter', fontSize: 10, color: ProColors.textMuted)),
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
