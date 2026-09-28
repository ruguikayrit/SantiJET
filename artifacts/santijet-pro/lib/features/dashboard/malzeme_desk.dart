part of 'dashboard_screen.dart';

enum _MalzemePane { gelen, tuketim, stok }

extension on _MalzemePane {
  String get label => switch (this) {
        _MalzemePane.gelen => 'Gelen Malzeme',
        _MalzemePane.tuketim => 'Tüketim',
        _MalzemePane.stok => 'Stok Durumu',
      };

  IconData get icon => switch (this) {
        _MalzemePane.gelen => Icons.local_shipping_outlined,
        _MalzemePane.tuketim => Icons.north_east,
        _MalzemePane.stok => Icons.inventory_2_outlined,
      };
}

class _MalzemeDesk extends StatefulWidget {
  const _MalzemeDesk({required this.onBack});

  final VoidCallback onBack;

  @override
  State<_MalzemeDesk> createState() => _MalzemeDeskState();
}

class _MalzemeDeskState extends State<_MalzemeDesk> {
  _MalzemePane _pane = _MalzemePane.gelen;

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
              key: const Key('malzeme-back'),
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
        const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _MalzemeMark(),
            SizedBox(width: 10),
            Expanded(child: _MalzemeHeading()),
            SizedBox(width: 8),
            _MalzemeProjectChip(),
          ],
        ),
        const SizedBox(height: 12),
        const Row(
          children: [
            Expanded(
              child: _MalzemeKpi(
                title: 'Gelen Malzeme',
                foot: 'Bu ay',
                color: Color(0xFF1D4ED8),
                icon: Icons.local_shipping_outlined,
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: _MalzemeKpi(
                title: 'Tüketim Kaydı',
                foot: 'Bu ay',
                color: Color(0xFF16A34A),
                icon: Icons.north_east,
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: _MalzemeKpi(
                title: 'Stoktaki Toplam',
                foot: 'Sahada mevcut',
                color: Color(0xFFEA580C),
                icon: Icons.widgets_outlined,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final pane in _MalzemePane.values) ...[
                _MalzemeTab(
                  label: pane.label,
                  icon: pane.icon,
                  selected: pane == _pane,
                  onTap: () => setState(() => _pane = pane),
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        switch (_pane) {
          _MalzemePane.gelen => const _MalzemeGelenPane(),
          _MalzemePane.tuketim => const _MalzemeEmptyPane(
              title: 'Tüketim',
              body: 'Tüketim kayıtları proje bağlanınca dolacak.',
            ),
          _MalzemePane.stok => const _MalzemeEmptyPane(
              title: 'Stok Durumu',
              body: 'Saha stok özeti proje bağlanınca görünür. Onay bekleyen, onaylandı ve teslim edildi durumları burada listelenir.',
            ),
        },
      ],
    );
  }
}

class _MalzemeMark extends StatelessWidget {
  const _MalzemeMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFF0284C7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.local_shipping_outlined, color: Colors.white, size: 24),
    );
  }
}

class _MalzemeHeading extends StatelessWidget {
  const _MalzemeHeading();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Malzeme',
          style: TextStyle(fontFamily: 'Rajdhani', fontWeight: FontWeight.w700, fontSize: 26, color: ProColors.text),
        ),
        Text(
          'Sahaya gelen malzemeleri kaydet, tüketimi takip et',
          style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: ProColors.textMuted),
        ),
      ],
    );
  }
}

class _MalzemeProjectChip extends StatelessWidget {
  const _MalzemeProjectChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 148,
      padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
      decoration: BoxDecoration(
        color: const Color(0xFF10243F),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1E3A5F)),
      ),
      child: const Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Aktif Proje',
                  style: TextStyle(fontFamily: 'Inter', fontSize: 9, color: Color(0xFF9EC1FF)),
                ),
                SizedBox(height: 2),
                Text(
                  'Henüz proje yok',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontFamily: 'Rajdhani', fontWeight: FontWeight.w700, fontSize: 12, color: ProColors.text),
                ),
                SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.apartment_outlined, size: 11, color: ProColors.textMuted),
                    SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        '—',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontFamily: 'Inter', fontSize: 10, color: ProColors.textMuted),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Icon(Icons.keyboard_arrow_down, size: 16, color: ProColors.textMuted),
        ],
      ),
    );
  }
}

class _MalzemeKpi extends StatelessWidget {
  const _MalzemeKpi({required this.title, required this.foot, required this.color, required this.icon});

  final String title;
  final String foot;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 108,
      padding: const EdgeInsets.fromLTRB(10, 10, 8, 8),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const Spacer(),
          const Text(
            '—',
            style: TextStyle(fontFamily: 'Rajdhani', fontWeight: FontWeight.w700, fontSize: 24, height: 1, color: Colors.white),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white),
          ),
          Text(foot, style: TextStyle(fontFamily: 'Inter', fontSize: 10, color: Colors.white.withValues(alpha: 0.78))),
        ],
      ),
    );
  }
}

class _MalzemeTab extends StatelessWidget {
  const _MalzemeTab({required this.label, required this.icon, required this.selected, required this.onTap});

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? Colors.white : ProColors.textMuted;
    return Material(
      color: selected ? ProColors.electricBlue : ProColors.surface,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MalzemeGelenPane extends StatelessWidget {
  const _MalzemeGelenPane();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _MalzemeFilterRow(),
        SizedBox(height: 10),
        _MalzemeActions(),
        SizedBox(height: 14),
        _MalzemeSectionTitle(),
        SizedBox(height: 8),
        _MalzemeGelenPlaceholder(),
        SizedBox(height: 8),
        _MalzemeGelenPlaceholder(),
        SizedBox(height: 8),
        _MalzemeGelenPlaceholder(),
        SizedBox(height: 12),
        _MalzemeNote(
          'Gelen malzeme listesi proje bağlanınca dolacak.',
        ),
      ],
    );
  }
}

class _MalzemeFilterRow extends StatelessWidget {
  const _MalzemeFilterRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _MalzemeDateChip(date: DateTime.now()),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: _cardDecoration(),
            child: const Row(
              children: [
                Icon(Icons.search, color: ProColors.textMuted, size: 18),
                SizedBox(width: 6),
                Expanded(
                  child: TextField(
                    enabled: false,
                    decoration: InputDecoration(
                      hintText: 'Malzeme ara...',
                      hintStyle: TextStyle(color: ProColors.textMuted, fontSize: 13),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        OutlinedButton.icon(
          onPressed: () => _keepInPro(context),
          icon: const Icon(Icons.tune, size: 16),
          label: const Text('Filtrele'),
          style: OutlinedButton.styleFrom(
            foregroundColor: ProColors.text,
            side: const BorderSide(color: ProColors.border),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            visualDensity: VisualDensity.compact,
          ),
        ),
      ],
    );
  }
}

class _MalzemeDateChip extends StatelessWidget {
  const _MalzemeDateChip({required this.date});

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

  static const _weekdays = ['Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar'];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: _cardDecoration(),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.calendar_today_outlined, size: 15, color: ProColors.textMuted),
          const SizedBox(width: 6),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${date.day} ${_months[date.month - 1]} ${date.year}',
                style: const TextStyle(fontFamily: 'Rajdhani', fontWeight: FontWeight.w700, fontSize: 12, color: ProColors.text),
              ),
              Text(
                _weekdays[date.weekday - 1],
                style: const TextStyle(fontFamily: 'Inter', fontSize: 10, color: ProColors.textMuted),
              ),
            ],
          ),
          const Icon(Icons.keyboard_arrow_down, size: 16, color: ProColors.textMuted),
        ],
      ),
    );
  }
}

class _MalzemeActions extends StatelessWidget {
  const _MalzemeActions();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: FilledButton.icon(
            key: const Key('malzeme-open-gelen'),
            onPressed: () => _keepInPro(context),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Yeni Gelen Malzeme Kaydı', maxLines: 1, overflow: TextOverflow.ellipsis),
            style: FilledButton.styleFrom(
              backgroundColor: ProColors.electricBlue,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: OutlinedButton.icon(
            key: const Key('malzeme-open-tuketim'),
            onPressed: () => _keepInPro(context),
            icon: const Icon(Icons.north_east, size: 16),
            label: const Text('Yeni Tüketim Kaydı', maxLines: 1, overflow: TextOverflow.ellipsis),
            style: OutlinedButton.styleFrom(
              foregroundColor: ProColors.text,
              side: const BorderSide(color: ProColors.border),
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
            ),
          ),
        ),
      ],
    );
  }
}

class _MalzemeSectionTitle extends StatelessWidget {
  const _MalzemeSectionTitle();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: _ReportSectionTitle('Son Gelen Malzemeler')),
        TextButton.icon(
          onPressed: () => _keepInPro(context),
          iconAlignment: IconAlignment.end,
          icon: const Icon(Icons.chevron_right, size: 18),
          label: const Text('Tümü'),
        ),
      ],
    );
  }
}

class _MalzemeGelenPlaceholder extends StatelessWidget {
  const _MalzemeGelenPlaceholder();

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
            decoration: BoxDecoration(color: ProColors.border, borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.image_outlined, color: ProColors.textFaint, size: 26),
          ),
          const SizedBox(width: 10),
          const Expanded(child: _MalzemeCardBody()),
          const SizedBox(width: 8),
          const _MalzemeCardMeta(),
        ],
      ),
    );
  }
}

class _MalzemeCardBody extends StatelessWidget {
  const _MalzemeCardBody();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 6,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text('—', style: TextStyle(fontFamily: 'Rajdhani', fontWeight: FontWeight.w700, fontSize: 15, color: ProColors.text)),
            _MalzemeUnitChip(),
          ],
        ),
        SizedBox(height: 6),
        _MalzemeMetaLine(icon: Icons.storefront_outlined, text: 'Tedarikçi —'),
        _MalzemeMetaLine(icon: Icons.local_shipping_outlined, text: 'Araç —'),
        _MalzemeMetaLine(icon: Icons.receipt_long_outlined, text: 'Fiş / Fatura No —'),
      ],
    );
  }
}

class _MalzemeUnitChip extends StatelessWidget {
  const _MalzemeUnitChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Text('Birim —', style: TextStyle(fontFamily: 'Inter', fontSize: 10, color: ProColors.textMuted)),
    );
  }
}

class _MalzemeMetaLine extends StatelessWidget {
  const _MalzemeMetaLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          Icon(icon, size: 12, color: ProColors.textFaint),
          const SizedBox(width: 4),
          Expanded(
            child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: ProColors.textMuted)),
          ),
        ],
      ),
    );
  }
}

class _MalzemeCardMeta extends StatelessWidget {
  const _MalzemeCardMeta();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text('—', style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: ProColors.textMuted)),
        SizedBox(height: 2),
        Text('—', style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: ProColors.textFaint)),
        SizedBox(height: 8),
        Text('—', style: TextStyle(fontFamily: 'Rajdhani', fontWeight: FontWeight.w700, fontSize: 16, color: ProColors.text)),
        SizedBox(height: 8),
        _MalzemeStatusChip(),
      ],
    );
  }
}

class _MalzemeStatusChip extends StatelessWidget {
  const _MalzemeStatusChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF14532D),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text(
        'Teslim —',
        style: TextStyle(fontFamily: 'Inter', fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF86EFAC)),
      ),
    );
  }
}

class _MalzemeNote extends StatelessWidget {
  const _MalzemeNote(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Text(text, style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: ProColors.textMuted)),
    );
  }
}

class _MalzemeEmptyPane extends StatelessWidget {
  const _MalzemeEmptyPane({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
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
        ),
        const SizedBox(height: 12),
        const _MalzemeActions(),
      ],
    );
  }
}
