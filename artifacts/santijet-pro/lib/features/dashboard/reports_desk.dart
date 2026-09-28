part of 'dashboard_screen.dart';

enum _ReportFilter { genel, saha, maliyet, imalat, ekip, makine, hakedis }

extension on _ReportFilter {
  String get label => switch (this) {
        _ReportFilter.genel => 'Genel',
        _ReportFilter.saha => 'Saha',
        _ReportFilter.maliyet => 'Maliyet',
        _ReportFilter.imalat => 'İmalat',
        _ReportFilter.ekip => 'Ekip',
        _ReportFilter.makine => 'Makine',
        _ReportFilter.hakedis => 'Hakediş',
      };
}

class _ReportKind {
  const _ReportKind({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.colors,
    required this.filters,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> colors;
  final Set<_ReportFilter> filters;

  bool visibleIn(_ReportFilter filter) => filter == _ReportFilter.genel || filters.contains(filter);
}

const _reportKinds = <_ReportKind>[
  _ReportKind(
    title: 'Günlük Rapor',
    subtitle: 'Saha, imalat, hava durumu',
    icon: Icons.calendar_today_outlined,
    colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
    filters: {_ReportFilter.saha},
  ),
  _ReportKind(
    title: 'Haftalık Rapor',
    subtitle: 'İlerleme, personel, ekipman',
    icon: Icons.date_range_outlined,
    colors: [Color(0xFF059669), Color(0xFF047857)],
    filters: {_ReportFilter.saha, _ReportFilter.ekip},
  ),
  _ReportKind(
    title: 'Aylık Rapor',
    subtitle: 'Maliyet, nakit akışı',
    icon: Icons.payments_outlined,
    colors: [Color(0xFFF97316), Color(0xFFEA580C)],
    filters: {_ReportFilter.maliyet},
  ),
  _ReportKind(
    title: 'İmalat Raporu',
    subtitle: 'Metraj, gerçekleşme',
    icon: Icons.bar_chart_rounded,
    colors: [Color(0xFF7C3AED), Color(0xFF6D28D9)],
    filters: {_ReportFilter.imalat, _ReportFilter.saha},
  ),
  _ReportKind(
    title: 'Beton Raporu',
    subtitle: 'Döküm, test sonuçları',
    icon: Icons.foundation_outlined,
    colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
    filters: {_ReportFilter.imalat},
  ),
  _ReportKind(
    title: 'Demir Raporu',
    subtitle: 'Kesim, montaj, atık',
    icon: Icons.view_week_outlined,
    colors: [Color(0xFFCA8A04), Color(0xFFA16207)],
    filters: {_ReportFilter.imalat},
  ),
  _ReportKind(
    title: 'Malzeme Raporu',
    subtitle: 'Stok, tüketim, sipariş',
    icon: Icons.inventory_2_outlined,
    colors: [Color(0xFF2563EB), Color(0xFF1E3A8A)],
    filters: {_ReportFilter.maliyet, _ReportFilter.imalat},
  ),
  _ReportKind(
    title: 'Hakediş Raporu',
    subtitle: 'İşveren, taşeron, ödeme',
    icon: Icons.request_quote_outlined,
    colors: [Color(0xFF16A34A), Color(0xFF15803D)],
    filters: {_ReportFilter.hakedis},
  ),
  _ReportKind(
    title: 'Makine Raporu',
    subtitle: 'Çalışma süresi, yakıt, bakım',
    icon: Icons.agriculture_outlined,
    colors: [Color(0xFF0D9488), Color(0xFF0F766E)],
    filters: {_ReportFilter.makine, _ReportFilter.saha},
  ),
];

class _ReportsDesk extends StatefulWidget {
  const _ReportsDesk();

  @override
  State<_ReportsDesk> createState() => _ReportsDeskState();
}

class _ReportsDeskState extends State<_ReportsDesk> {
  _ReportFilter _filter = _ReportFilter.genel;

  @override
  Widget build(BuildContext context) {
    final kinds = _reportKinds.where((kind) => kind.visibleIn(_filter)).toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        const _TopBar(alertCount: 3),
        const SizedBox(height: 14),
        const Row(
          children: [
            Icon(Icons.bar_chart_rounded, color: ProColors.electricBlue, size: 22),
            SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Raporlar',
                    style: TextStyle(fontFamily: 'Rajdhani', fontWeight: FontWeight.w700, fontSize: 26, color: ProColors.text),
                  ),
                  Text(
                    'Tüm verilerinizi analiz edin, projelerinizi yönetin',
                    style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: ProColors.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final filter in _ReportFilter.values) ...[
                _FilterPill(
                  label: filter.label,
                  selected: filter == _filter,
                  onTap: () => setState(() => _filter = filter),
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        const _ReportKpiGrid(),
        const SizedBox(height: 12),
        const _CostSplitCard(),
        const SizedBox(height: 12),
        const _CostTrendCard(),
        const SizedBox(height: 12),
        const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _ProjectStatusCard()),
            SizedBox(width: 10),
            Expanded(child: _ScheduleProgressCard()),
          ],
        ),
        const SizedBox(height: 16),
        const _ReportSectionTitle('Rapor Türleri'),
        const SizedBox(height: 10),
        _ReportKindGrid(kinds: kinds),
      ],
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? ProColors.electricBlue : ProColors.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : ProColors.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}

class _ReportKpiGrid extends StatelessWidget {
  const _ReportKpiGrid();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _ReportKpi(
                title: 'Toplam Proje',
                value: '—',
                foot: 'Aktif proje',
                icon: Icons.description_outlined,
                colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: _ReportKpi(
                title: 'Toplam Maliyet',
                value: '—',
                foot: 'Bu ay',
                icon: Icons.account_balance_outlined,
                colors: [Color(0xFF059669), Color(0xFF047857)],
              ),
            ),
          ],
        ),
        SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _ReportKpi(
                title: 'Tamamlanma Oranı',
                value: '—',
                foot: 'Planlanan / Gerçekleşen',
                icon: Icons.donut_large_outlined,
                colors: [Color(0xFFF97316), Color(0xFFEA580C)],
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: _ReportKpi(
                title: 'Toplam Süre',
                value: '—',
                foot: 'Ortalama proje',
                icon: Icons.calendar_month_outlined,
                colors: [Color(0xFF7C3AED), Color(0xFF6D28D9)],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ReportKpi extends StatelessWidget {
  const _ReportKpi({
    required this.title,
    required this.value,
    required this.foot,
    required this.icon,
    required this.colors,
  });

  final String title;
  final String value;
  final String foot;
  final IconData icon;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(colors: colors),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: Color(0xF2FFFFFF))),
          Text(value, style: const TextStyle(fontFamily: 'Rajdhani', fontWeight: FontWeight.w700, fontSize: 26, color: Colors.white)),
          Text(foot, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: Color(0xCCFFFFFF))),
        ],
      ),
    );
  }
}

class _CostSplitCard extends StatelessWidget {
  const _CostSplitCard();

  static const slices = <(String, Color)>[
    ('Kaba İnşaat', Color(0xFF2563EB)),
    ('Mimari İşler', Color(0xFF22C55E)),
    ('Tesisat İşleri', Color(0xFFF97316)),
    ('Çelik İşler', Color(0xFFA855F7)),
    ('Diğer', Color(0xFF64748B)),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _ReportSectionTitle('Maliyet Dağılımı'),
          const SizedBox(height: 12),
          Row(
            children: [
              const SizedBox(
                width: 92,
                height: 92,
                child: CustomPaint(painter: _EmptyRingPainter()),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  children: [
                    for (final slice in slices)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            Container(width: 8, height: 8, decoration: BoxDecoration(color: slice.$2, shape: BoxShape.circle)),
                            const SizedBox(width: 8),
                            Expanded(child: Text(slice.$1, style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: ProColors.text))),
                            const Text('—', style: TextStyle(fontFamily: 'Rajdhani', fontWeight: FontWeight.w700, color: ProColors.textMuted)),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyRingPainter extends CustomPainter {
  const _EmptyRingPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - 6;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..color = ProColors.border;
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CostTrendCard extends StatelessWidget {
  const _CostTrendCard();

  static const months = ['Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz', 'Tem', 'Ağu', 'Eyl'];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _ReportSectionTitle('Aylık Maliyet Trendi'),
          const SizedBox(height: 6),
          const Row(
            children: [
              _LegendDot(color: Color(0xFF2563EB), label: 'Planlanan'),
              SizedBox(width: 12),
              _LegendDot(color: Color(0xFF22C55E), label: 'Gerçekleşen'),
            ],
          ),
          const SizedBox(height: 12),
          const SizedBox(height: 88, width: double.infinity, child: CustomPaint(painter: _EmptyAxesPainter())),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final month in months)
                Text(month, style: const TextStyle(fontFamily: 'Inter', fontSize: 10, color: ProColors.textMuted)),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: ProColors.textMuted)),
      ],
    );
  }
}

class _EmptyAxesPainter extends CustomPainter {
  const _EmptyAxesPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = ProColors.border
      ..strokeWidth = 1;
    canvas.drawLine(Offset(0, size.height - 1), Offset(size.width, size.height - 1), paint);
    canvas.drawLine(const Offset(0, 0), Offset(0, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ProjectStatusCard extends StatelessWidget {
  const _ProjectStatusCard();

  static const rows = <(IconData, Color, String)>[
    (Icons.play_circle_outline, Color(0xFF22C55E), 'Devam Eden'),
    (Icons.pause_circle_outline, Color(0xFFF59E0B), 'Bekleyen'),
    (Icons.check_circle_outline, Color(0xFF2563EB), 'Tamamlanan'),
    (Icons.cancel_outlined, Color(0xFFEF4444), 'İptal Edilen'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Proje Durumu', style: TextStyle(fontFamily: 'Rajdhani', fontWeight: FontWeight.w700, fontSize: 15, color: ProColors.text)),
          const SizedBox(height: 8),
          for (final row in rows)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Icon(row.$1, size: 16, color: row.$2),
                  const SizedBox(width: 6),
                  Expanded(child: Text(row.$3, style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: ProColors.text))),
                  const Text('—', style: TextStyle(fontFamily: 'Rajdhani', fontWeight: FontWeight.w700, color: ProColors.text)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ScheduleProgressCard extends StatelessWidget {
  const _ScheduleProgressCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _cardDecoration(),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('İş Programı İlerlemesi', style: TextStyle(fontFamily: 'Rajdhani', fontWeight: FontWeight.w700, fontSize: 15, color: ProColors.text)),
          SizedBox(height: 6),
          Text('—', style: TextStyle(fontFamily: 'Rajdhani', fontWeight: FontWeight.w700, fontSize: 28, color: ProColors.text)),
          SizedBox(height: 8),
          _MiniStat('Planlanan Süre'),
          _MiniStat('Geçen Süre'),
          _MiniStat('Kalan Süre'),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: ProColors.textMuted))),
          const Text('—', style: TextStyle(fontFamily: 'Rajdhani', fontWeight: FontWeight.w700, color: ProColors.text)),
        ],
      ),
    );
  }
}

class _ReportSectionTitle extends StatelessWidget {
  const _ReportSectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(fontFamily: 'Rajdhani', fontWeight: FontWeight.w700, fontSize: 16, color: ProColors.text),
    );
  }
}

class _ReportKindGrid extends StatelessWidget {
  const _ReportKindGrid({required this.kinds});

  final List<_ReportKind> kinds;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: kinds.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        mainAxisExtent: 112,
      ),
      itemBuilder: (context, index) {
        final kind = kinds[index];
        return Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => _keepInPro(context),
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: kind.colors),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(kind.icon, color: Colors.white, size: 18),
                    const Spacer(),
                    Text(
                      kind.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontFamily: 'Rajdhani', fontWeight: FontWeight.w700, fontSize: 13, height: 1.05, color: Colors.white),
                    ),
                    Text(
                      kind.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontFamily: 'Inter', fontSize: 10, height: 1.15, color: Color(0xF2FFFFFF)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
