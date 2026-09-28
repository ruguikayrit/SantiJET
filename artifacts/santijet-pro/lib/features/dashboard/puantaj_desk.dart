part of 'dashboard_screen.dart';

enum _PuantajRange { gunluk, haftalik, aylik }

extension on _PuantajRange {
  String get label => switch (this) {
        _PuantajRange.gunluk => 'Günlük',
        _PuantajRange.haftalik => 'Haftalık',
        _PuantajRange.aylik => 'Aylık',
      };
}

class _EkipPuantaj {
  const _EkipPuantaj({
    required this.name,
    required this.filter,
    required this.people,
    required this.sahada,
    required this.yarim,
    required this.izinli,
    required this.yok,
    required this.toplam,
    required this.icon,
    required this.color,
  });

  final String name;
  final String filter;
  final int people;
  final int sahada;
  final int yarim;
  final int izinli;
  final int yok;
  final int toplam;
  final IconData icon;
  final Color color;
}

class _EkipTanimi {
  const _EkipTanimi(this.name, this.icon, this.color);

  final String name;
  final IconData icon;
  final Color color;

  String get baslik => name == 'Diğer' ? name : '$name Ekibi';
}

const _ekipler = <_EkipTanimi>[
  _EkipTanimi('Alçıpan', Icons.auto_awesome, Color(0xFF7C3AED)),
  _EkipTanimi('Boya', Icons.format_paint, Color(0xFFDB2777)),
  _EkipTanimi('Elektrik', Icons.bolt, Color(0xFFF97316)),
  _EkipTanimi('Sıhhi Tesisat', Icons.water_drop, Color(0xFF14B8A6)),
  _EkipTanimi('Mekanik', Icons.settings, Color(0xFF64748B)),
  _EkipTanimi('Kalıp', Icons.view_column, Color(0xFFD97706)),
  _EkipTanimi('Demir', Icons.grid_4x4, Color(0xFFEAB308)),
  _EkipTanimi('Nakliye', Icons.local_shipping, Color(0xFFEC4899)),
  _EkipTanimi('Peyzaj', Icons.eco, Color(0xFF22C55E)),
  _EkipTanimi('Diğer', Icons.more_horiz, Color(0xFF8B5CF6)),
];

class _Kadro {
  const _Kadro(this.name, this.team, this.unvan, this.color);

  final String name;
  final String team;
  final String unvan;
  final Color color;

  String get initials {
    final parts = name.split(' ');
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}';
    }
    return name.isEmpty ? '' : name.substring(0, 1);
  }
}

const _kadro = <_Kadro>[
  _Kadro('Mehmet Arslan', 'Alçıpan', 'Usta', Color(0xFF2563EB)),
  _Kadro('Hasan Kaya', 'Alçıpan', 'Usta', Color(0xFF7C3AED)),
  _Kadro('Ali Yılmaz', 'Alçıpan', 'İşçi', Color(0xFFF97316)),
  _Kadro('Emre Koç', 'Alçıpan', 'İşçi', Color(0xFFEF4444)),
  _Kadro('Burak Demir', 'Alçıpan', 'İşçi', Color(0xFF22C55E)),
  _Kadro('Selim Karaca', 'Boya', 'Usta', Color(0xFF7C3AED)),
  _Kadro('Tamer Yıldız', 'Boya', 'İşçi', Color(0xFFF97316)),
  _Kadro('Kemal Aydın', 'Boya', 'Usta', Color(0xFFDB2777)),
  _Kadro('Serkan Yıldız', 'Boya', 'İşçi', Color(0xFFBE185D)),
  _Kadro('Deniz Aydın', 'Elektrik', 'Usta', Color(0xFF14B8A6)),
  _Kadro('Okan Demir', 'Elektrik', 'Usta', Color(0xFFF97316)),
  _Kadro('Yusuf Aksoy', 'Elektrik', 'İşçi', Color(0xFF2563EB)),
  _Kadro('Tarık Aslan', 'Sıhhi Tesisat', 'Usta', Color(0xFF14B8A6)),
  _Kadro('Emrah Kılıç', 'Sıhhi Tesisat', 'Usta', Color(0xFF0F766E)),
  _Kadro('Barış Öztürk', 'Sıhhi Tesisat', 'İşçi', Color(0xFFF97316)),
  _Kadro('Murat Çetin', 'Sıhhi Tesisat', 'İşçi', Color(0xFF22C55E)),
  _Kadro('Deniz Acar', 'Mekanik', 'Usta', Color(0xFF64748B)),
  _Kadro('Onur Yalçın', 'Mekanik', 'İşçi', Color(0xFF475569)),
  _Kadro('Mert Koçak', 'Mekanik', 'İşçi', Color(0xFF94A3B8)),
  _Kadro('Hakan Şahin', 'Kalıp', 'Usta', Color(0xFFD97706)),
  _Kadro('Caner Polat', 'Kalıp', 'İşçi', Color(0xFFB45309)),
  _Kadro('Volkan Er', 'Demir', 'Usta', Color(0xFFEAB308)),
  _Kadro('Cem Aktaş', 'Demir', 'İşçi', Color(0xFFCA8A04)),
  _Kadro('Halil Doğan', 'Demir', 'İşçi', Color(0xFFA16207)),
  _Kadro('İbrahim Uçar', 'Nakliye', 'Usta', Color(0xFFEC4899)),
  _Kadro('Ferhat Sönmez', 'Nakliye', 'İşçi', Color(0xFFDB2777)),
  _Kadro('Gökhan Aydın', 'Peyzaj', 'Usta', Color(0xFF22C55E)),
  _Kadro('Levent Koç', 'Peyzaj', 'İşçi', Color(0xFF16A34A)),
  _Kadro('Yaşar Çelik', 'Diğer', 'Usta', Color(0xFF8B5CF6)),
  _Kadro('Nihat Acar', 'Diğer', 'İşçi', Color(0xFF7C3AED)),
];

int _isimIz(String name) => name.codeUnits.fold<int>(7, (sum, unit) => (sum * 31 + unit) & 0x7fffffff);

_PuantajDurum _otomatikDurum(String name, DateTime day) {
  final weekend = day.weekday == DateTime.saturday || day.weekday == DateTime.sunday;
  final n = (_isimIz(name) + day.year * 366 + day.month * 31 + day.day) % (weekend ? 5 : 10);
  if (weekend) return n == 0 ? _PuantajDurum.sahada : _PuantajDurum.yok;
  if (n == 0) return _PuantajDurum.yok;
  if (n == 1) return _PuantajDurum.izinli;
  if (n == 2) return _PuantajDurum.yarim;
  return _PuantajDurum.sahada;
}

String _gunAnahtar(String name, DateTime day) => '$name|${day.year}-${day.month}-${day.day}';

enum _PuantajDurum { sahada, izinli, yok, yarim }

extension on _PuantajDurum {
  String get label => switch (this) {
        _PuantajDurum.sahada => 'Sahada',
        _PuantajDurum.izinli => 'İzinli',
        _PuantajDurum.yok => 'Yok',
        _PuantajDurum.yarim => 'Yarım',
      };
}

class _PersonelKaydi {
  _PersonelKaydi({
    required this.name,
    required this.unvan,
    required this.initials,
    required this.color,
    required this.durum,
  });

  final String name;
  final String unvan;
  final String initials;
  final Color color;
  _PuantajDurum durum;
}

class _PuantajDesk extends StatefulWidget {
  const _PuantajDesk({required this.onBack});

  final VoidCallback onBack;

  @override
  State<_PuantajDesk> createState() => _PuantajDeskState();
}

class _PuantajDeskState extends State<_PuantajDesk> {
  static const _dayNames = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];

  static const _months = ['Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran', 'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'];

  _PuantajRange _range = _PuantajRange.gunluk;
  _HaftalikSekme _haftalikSekme = _HaftalikSekme.ekip;
  _HaftalikSekme _aylikSekme = _HaftalikSekme.ekip;
  late DateTime _selectedDay = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
  String _filter = 'Tümü';
  String _haftaEkip = 'Tümü';
  final _haftaAra = TextEditingController();
  final List<_Kadro> _eklenen = [];
  final Set<String> _cikarilan = {};
  final Map<String, _PuantajDurum> _elle = {};
  DateTime _savedAt = DateTime.now();

  List<_Kadro> get _aktifKadro => [
        for (final kisi in _kadro)
          if (!_cikarilan.contains(kisi.name)) kisi,
        ..._eklenen,
      ];

  _PuantajDurum _durum(_Kadro kisi, DateTime day) => _elle[_gunAnahtar(kisi.name, day)] ?? _otomatikDurum(kisi.name, day);

  _EkipPuantaj _ekipGunu(_EkipTanimi ekip, DateTime day) {
    final people = _aktifKadro.where((kisi) => kisi.team == ekip.name).toList();
    var sahada = 0;
    var yarim = 0;
    var izinli = 0;
    var yok = 0;
    for (final kisi in people) {
      switch (_durum(kisi, day)) {
        case _PuantajDurum.sahada:
          sahada++;
        case _PuantajDurum.yarim:
          yarim++;
        case _PuantajDurum.izinli:
          izinli++;
        case _PuantajDurum.yok:
          yok++;
      }
    }
    return _EkipPuantaj(
      name: ekip.baslik,
      filter: ekip.name,
      people: people.length,
      sahada: sahada,
      yarim: yarim,
      izinli: izinli,
      yok: yok,
      toplam: people.length,
      icon: ekip.icon,
      color: ekip.color,
    );
  }

  List<_HaftaKisi> _haftaListesi(DateTime weekStart) {
    return [
      for (final kisi in _aktifKadro)
        _HaftaKisi(
          kisi.name,
          kisi.team,
          kisi.unvan,
          kisi.initials,
          kisi.color,
          [
            for (var index = 0; index < 7; index++)
              switch (_durum(kisi, weekStart.add(Duration(days: index)))) {
                _PuantajDurum.sahada => 'S',
                _PuantajDurum.yarim => 'H',
                _PuantajDurum.izinli => 'I',
                _PuantajDurum.yok => 'Y',
              },
          ].join(),
        ),
    ];
  }

  List<_AyKisi> _ayListesi(DateTime day) {
    final start = DateTime(day.year, day.month);
    final count = DateTime(day.year, day.month + 1, 0).day;
    return [
      for (final kisi in _aktifKadro)
        () {
          var sahada = 0;
          var yarim = 0;
          var izinli = 0;
          var yok = 0;
          for (var offset = 0; offset < count; offset++) {
            switch (_durum(kisi, start.add(Duration(days: offset)))) {
              case _PuantajDurum.sahada:
                sahada++;
              case _PuantajDurum.yarim:
                yarim++;
              case _PuantajDurum.izinli:
                izinli++;
              case _PuantajDurum.yok:
                yok++;
            }
          }
          return _AyKisi(kisi.name, kisi.team, kisi.unvan, kisi.initials, kisi.color, sahada, yarim, izinli, yok);
        }(),
    ];
  }

  @override
  void dispose() {
    _haftaAra.dispose();
    super.dispose();
  }

  String get _subtitle {
    if (_range == _PuantajRange.haftalik) {
      return _haftalikSekme == _HaftalikSekme.ekip ? 'Ekiplerin haftalık puantaj özeti.' : 'Personel bazlı haftalık puantaj.';
    }
    if (_range == _PuantajRange.aylik) {
      return _aylikSekme == _HaftalikSekme.ekip ? 'Ekiplerin aylık puantaj özeti.' : 'Personel bazlı aylık puantaj.';
    }
    return _filter == 'Tümü' ? 'Ekip ekip günlük puantaj özeti.' : 'Personel bazlı günlük puantaj.';
  }

  DateTime _shiftMonth(int delta) {
    final total = _selectedDay.year * 12 + (_selectedDay.month - 1) + delta;
    return DateTime(total ~/ 12, (total % 12) + 1, 1);
  }

  String _haftaAralik() {
    final start = _weekStart;
    final end = start.add(const Duration(days: 6));
    if (start.month == end.month) {
      return '${start.day} - ${end.day} ${_months[start.month - 1]} ${start.year}';
    }
    return '${start.day} ${_months[start.month - 1]} - ${end.day} ${_months[end.month - 1]} ${end.year}';
  }

  DateTime get _weekStart => _selectedDay.subtract(Duration(days: _selectedDay.weekday - 1));

  Future<void> _addPerson() async {
    final result = await showDialog<(String, String)>(
      context: context,
      builder: (context) => const _PersonelEkleDialog(),
    );
    if (result != null && result.$1.isNotEmpty && mounted && _filter != 'Tümü') {
      setState(() {
        final name = result.$1;
        final unvan = result.$2.isEmpty ? 'İşçi' : result.$2;
        if (_kadro.any((kisi) => kisi.name == name)) {
          _cikarilan.remove(name);
        } else {
          _eklenen.removeWhere((kisi) => kisi.name == name);
          _eklenen.add(_Kadro(name, _filter, unvan, const Color(0xFF2563EB)));
        }
        _elle[_gunAnahtar(name, _selectedDay)] = _PuantajDurum.sahada;
        _savedAt = DateTime.now();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final rows = [for (final ekip in _ekipler) _ekipGunu(ekip, _selectedDay)];
    final sahada = rows.fold<int>(0, (sum, row) => sum + row.sahada);
    final yarim = rows.fold<int>(0, (sum, row) => sum + row.yarim);
    final izinli = rows.fold<int>(0, (sum, row) => sum + row.izinli);
    final yok = rows.fold<int>(0, (sum, row) => sum + row.yok);
    final kisiGun = sahada + yarim + izinli + yok;
    final filtreler = <(String, int)>[
      ('Tümü', _aktifKadro.length),
      for (final ekip in _ekipler) (ekip.name, _aktifKadro.where((kisi) => kisi.team == ekip.name).length),
    ];
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        _PuantajTopBar(onBack: widget.onBack),
        const SizedBox(height: 16),
        Row(
          children: [
            const _PuantajMark(),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Puantaj',
                    style: TextStyle(fontFamily: 'Rajdhani', fontWeight: FontWeight.w700, fontSize: 26, color: ProColors.text),
                  ),
                  Text(
                    _subtitle,
                    style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: ProColors.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _PuantajRangeBar(
          range: _range,
          onChanged: (range) => setState(() => _range = range),
        ),
        const SizedBox(height: 10),
        if (_range == _PuantajRange.aylik)
          _AylikSayfa(
            monthLabel: '${_months[_selectedDay.month - 1]} ${_selectedDay.year}',
            sekme: _aylikSekme,
            ekip: _haftaEkip,
            query: _haftaAra.text,
            arama: _haftaAra,
            kisiler: _ayListesi(_selectedDay),
            onPrevious: () => setState(() => _selectedDay = _shiftMonth(-1)),
            onNext: () => setState(() => _selectedDay = _shiftMonth(1)),
            onSekme: (sekme) => setState(() => _aylikSekme = sekme),
            onEkip: (ekip) => setState(() => _haftaEkip = ekip),
            onQuery: (_) => setState(() {}),
            onReport: () => _keepInPro(context),
          )
        else if (_range == _PuantajRange.haftalik)
          _HaftalikSayfa(
            weekStart: _weekStart,
            rangeLabel: _haftaAralik(),
            sekme: _haftalikSekme,
            dayNames: _dayNames,
            ekip: _haftaEkip,
            query: _haftaAra.text,
            arama: _haftaAra,
            kisiler: _haftaListesi(_weekStart),
            onPrevious: () => setState(() => _selectedDay = _selectedDay.subtract(const Duration(days: 7))),
            onNext: () => setState(() => _selectedDay = _selectedDay.add(const Duration(days: 7))),
            onSekme: (sekme) => setState(() => _haftalikSekme = sekme),
            onEkip: (ekip) => setState(() => _haftaEkip = ekip),
            onQuery: (_) => setState(() {}),
            onReport: () => _keepInPro(context),
          )
        else ...[
        _PuantajWeekStrip(
          weekStart: _weekStart,
          selected: _selectedDay,
          dayNames: _dayNames,
          onSelect: (day) => setState(() => _selectedDay = day),
          onPrevious: () => setState(() => _selectedDay = _selectedDay.subtract(const Duration(days: 7))),
          onNext: () => setState(() => _selectedDay = _selectedDay.add(const Duration(days: 7))),
        ),
        const SizedBox(height: 14),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final item in filtreler) ...[
                _PuantajFilterChip(
                  label: '${item.$1} (${item.$2})',
                  selected: _filter == item.$1,
                  onTap: () => setState(() => _filter = item.$1),
                ),
                const SizedBox(width: 6),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (_filter == 'Tümü') ...[
          const Text(
            'Ekip Bazlı Puantaj (Tümü)',
            style: TextStyle(fontFamily: 'Rajdhani', fontWeight: FontWeight.w700, fontSize: 16, color: ProColors.text),
          ),
          const SizedBox(height: 8),
          _PuantajTable(rows: rows),
          const SizedBox(height: 14),
          const Text(
            'Genel Toplam',
            style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: ProColors.textMuted),
          ),
          const SizedBox(height: 8),
          _ToplamSatiri(
            children: [
              _PuantajTotal(value: '$sahada', label: 'Sahada', icon: Icons.groups, color: const Color(0xFF166534), tint: const Color(0xFF14532D)),
              _PuantajTotal(value: '$izinli', label: 'İzinli', icon: Icons.hotel, color: const Color(0xFF60A5FA), tint: const Color(0xFF1E3A8A)),
              _PuantajTotal(value: '$yok', label: 'Yok', icon: Icons.do_not_disturb_on, color: const Color(0xFFF87171), tint: const Color(0xFF7F1D1D)),
              _PuantajTotal(value: '$yarim', label: 'Yarım', icon: Icons.contrast, color: const Color(0xFFFBBF24), tint: const Color(0xFF78350F)),
              _PuantajTotal(value: '$kisiGun', label: 'Kişi-gün', icon: null, color: Colors.black, labelColor: Colors.black, tint: const Color(0xFFE5E7EB), solid: true),
            ],
          ),
        ] else
          _PuantajEkipDetay(
            team: rows.firstWhere((row) => row.filter == _filter),
            people: [
              for (final kisi in _aktifKadro.where((kisi) => kisi.team == _filter))
                _PersonelKaydi(
                  name: kisi.name,
                  unvan: kisi.unvan,
                  initials: kisi.initials,
                  color: kisi.color,
                  durum: _durum(kisi, _selectedDay),
                ),
            ],
            savedLabel: '${_savedAt.hour.toString().padLeft(2, '0')}:${_savedAt.minute.toString().padLeft(2, '0')}',
            onDurum: (index, durum) => setState(() {
              final kisi = _aktifKadro.where((item) => item.team == _filter).elementAt(index);
              _elle[_gunAnahtar(kisi.name, _selectedDay)] = durum;
              _savedAt = DateTime.now();
            }),
            onRemove: (index) => setState(() {
              final kisi = _aktifKadro.where((item) => item.team == _filter).elementAt(index);
              _eklenen.removeWhere((item) => item.name == kisi.name);
              _cikarilan.add(kisi.name);
              _savedAt = DateTime.now();
            }),
            onAdd: _addPerson,
          ),
        ],
      ],
    );
  }
}

enum _HaftalikSekme { ekip, personel }

class _HaftaEkipSatir {
  const _HaftaEkipSatir(this.name, this.people, this.icon, this.color, this.days, this.toplam);

  final String name;
  final String people;
  final IconData icon;
  final Color color;
  final List<int> days;
  final int toplam;
}


class _HaftaKisi {
  const _HaftaKisi(this.name, this.team, this.unvan, this.initials, this.color, this.days);

  final String name;
  final String team;
  final String unvan;
  final String initials;
  final Color color;
  final String days;

  int get sahada => 'S'.allMatches(days).length;
  int get yarim => 'H'.allMatches(days).length;
  int get izinli => 'I'.allMatches(days).length;
  int get yok => 'Y'.allMatches(days).length;
  int get toplam => days.length;
}

class _HaftalikSayfa extends StatelessWidget {
  const _HaftalikSayfa({
    required this.weekStart,
    required this.rangeLabel,
    required this.sekme,
    required this.dayNames,
    required this.ekip,
    required this.query,
    required this.arama,
    required this.kisiler,
    required this.onPrevious,
    required this.onNext,
    required this.onSekme,
    required this.onEkip,
    required this.onQuery,
    required this.onReport,
  });

  final DateTime weekStart;
  final String rangeLabel;
  final _HaftalikSekme sekme;
  final List<String> dayNames;
  final String ekip;
  final String query;
  final TextEditingController arama;
  final List<_HaftaKisi> kisiler;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final ValueChanged<_HaftalikSekme> onSekme;
  final ValueChanged<String> onEkip;
  final ValueChanged<String> onQuery;
  final VoidCallback onReport;

  List<_HaftaEkipSatir> get _ekipSatirlari {
    return [
      for (final team in _ekipler)
        () {
          final members = kisiler.where((person) => person.team == team.name).toList();
          final days = [
            for (var index = 0; index < 7; index++) members.where((person) => person.days[index] == 'S').length,
          ];
          return _HaftaEkipSatir(team.name, '${members.length} kişi', team.icon, team.color, days, days.fold<int>(0, (sum, value) => sum + value));
        }(),
    ];
  }

  (int, int, int, int, int) _ozet(List<_HaftaKisi> people) {
    final sahada = people.fold<int>(0, (sum, person) => sum + person.sahada);
    final yarim = people.fold<int>(0, (sum, person) => sum + person.yarim);
    final izinli = people.fold<int>(0, (sum, person) => sum + person.izinli);
    final yok = people.fold<int>(0, (sum, person) => sum + person.yok);
    return (sahada, yarim, izinli, yok, sahada + yarim + izinli + yok);
  }

  @override
  Widget build(BuildContext context) {
    final people = kisiler.where((person) {
      final matchesTeam = ekip == 'Tümü' || person.team == ekip;
      final matchesQuery = query.trim().isEmpty || person.name.toLowerCase().contains(query.trim().toLowerCase());
      return matchesTeam && matchesQuery;
    }).toList();
    final tumPersonel = ekip == 'Tümü' && query.trim().isEmpty;
    final ekipOzet = _ozet(kisiler);
    final personelOzet = _ozet(people);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _HaftaAralikBar(label: rangeLabel, onPrevious: onPrevious, onNext: onNext),
        const SizedBox(height: 10),
        _HaftaSekmeBar(sekme: sekme, onChanged: onSekme),
        const SizedBox(height: 10),
        if (sekme == _HaftalikSekme.ekip)
          _HaftaEkipTablosu(weekStart: weekStart, dayNames: dayNames, rows: _ekipSatirlari)
        else
          _HaftaPersonelTablosu(
            weekStart: weekStart,
            dayNames: dayNames,
            people: people,
            ekip: ekip,
            arama: arama,
            onEkip: onEkip,
            onQuery: onQuery,
          ),
        const SizedBox(height: 12),
        if (sekme == _HaftalikSekme.ekip)
          _HaftaOzet(
            title: 'Haftalık Toplam',
            sahada: '${ekipOzet.$1}',
            yarim: '${ekipOzet.$2}',
            izinli: '${ekipOzet.$3}',
            yok: '${ekipOzet.$4}',
            kisiGun: '${ekipOzet.$5}',
            kisiGunLabel: 'Kişi-gün',
          )
        else
          _HaftaOzet(
            title: tumPersonel ? 'Hafta Özeti (Tüm Personel)' : 'Hafta Özeti',
            sahada: '${personelOzet.$1}',
            yarim: '${personelOzet.$2}',
            izinli: '${personelOzet.$3}',
            yok: '${personelOzet.$4}',
            kisiGun: '${personelOzet.$5}',
            kisiGunLabel: 'Kişi-gün',
          ),
        const SizedBox(height: 12),
        Material(
          color: const Color(0xFF0B1220),
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: onReport,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: ProColors.border),
              ),
              child: const Row(
                children: [
                  Icon(Icons.bar_chart_rounded, color: Color(0xFF60A5FA), size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Detaylı Raporu Görüntüle',
                      style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 14, color: ProColors.text),
                    ),
                  ),
                  Icon(Icons.chevron_right, color: ProColors.textMuted),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HaftaAralikBar extends StatelessWidget {
  const _HaftaAralikBar({required this.label, required this.onPrevious, required this.onNext});

  final String label;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1220),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ProColors.border),
      ),
      child: Row(
        children: [
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: onPrevious,
            icon: const Icon(Icons.chevron_left, color: ProColors.textMuted),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.calendar_today_outlined, size: 14, color: ProColors.textMuted),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 14, color: ProColors.text),
                  ),
                ),
                const Icon(Icons.keyboard_arrow_down, size: 18, color: ProColors.textMuted),
              ],
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: onNext,
            icon: const Icon(Icons.chevron_right, color: ProColors.textMuted),
          ),
        ],
      ),
    );
  }
}

class _HaftaSekmeBar extends StatelessWidget {
  const _HaftaSekmeBar({required this.sekme, required this.onChanged});

  final _HaftalikSekme sekme;
  final ValueChanged<_HaftalikSekme> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1220),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ProColors.border),
      ),
      child: Row(
        children: [
          for (final item in _HaftalikSekme.values)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(item),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: item == sekme ? const Color(0xFF2563EB) : Colors.transparent,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    item == _HaftalikSekme.ekip ? 'Ekip' : 'Personel',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: item == sekme ? Colors.white : ProColors.textMuted,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _HaftaEkipTablosu extends StatelessWidget {
  const _HaftaEkipTablosu({required this.weekStart, required this.dayNames, required this.rows});

  final DateTime weekStart;
  final List<String> dayNames;
  final List<_HaftaEkipSatir> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 10, 4, 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1220),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ProColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(flex: 4, child: Text('Ekip', style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: ProColors.textMuted))),
              for (var index = 0; index < 7; index++)
                Expanded(
                  child: Column(
                    children: [
                      Text(dayNames[index], style: const TextStyle(fontFamily: 'Inter', fontSize: 10, color: ProColors.textMuted)),
                      Text('${weekStart.add(Duration(days: index)).day}', style: const TextStyle(fontFamily: 'Inter', fontSize: 10, color: ProColors.textFaint)),
                    ],
                  ),
                ),
              const _SigdirBaslik('Toplam', flex: 2),
              const SizedBox(width: 16),
            ],
          ),
          const SizedBox(height: 8),
          for (final row in rows) _HaftaEkipSatiri(row: row),
        ],
      ),
    );
  }
}

class _HaftaEkipSatiri extends StatelessWidget {
  const _HaftaEkipSatiri({required this.row});

  final _HaftaEkipSatir row;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Row(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(color: row.color.withValues(alpha: 0.2), shape: BoxShape.circle),
                  child: Icon(row.icon, size: 14, color: row.color),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(row.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 12, color: ProColors.text)),
                      Text(row.people, style: const TextStyle(fontFamily: 'Inter', fontSize: 10, color: ProColors.textMuted)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          for (final value in row.days)
            Expanded(
              child: Center(
                child: Container(
                  width: 22,
                  height: 20,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: value == 0 ? const Color(0xFF7F1D1D) : const Color(0xFF14532D),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    '$value',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                      color: value == 0 ? const Color(0xFFFCA5A5) : const Color(0xFF4ADE80),
                    ),
                  ),
                ),
              ),
            ),
          Expanded(
            flex: 2,
            child: Text(
              '${row.toplam}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontFamily: 'Rajdhani', fontWeight: FontWeight.w700, fontSize: 14, color: ProColors.text),
            ),
          ),
          const Icon(Icons.chevron_right, size: 16, color: ProColors.textMuted),
        ],
      ),
    );
  }
}

class _PersonelAramaSatiri extends StatelessWidget {
  const _PersonelAramaSatiri({
    required this.ekip,
    required this.ekipler,
    required this.arama,
    required this.onEkip,
    required this.onQuery,
  });

  final String ekip;
  final List<String> ekipler;
  final TextEditingController arama;
  final ValueChanged<String> onEkip;
  final ValueChanged<String> onQuery;

  BoxDecoration get _box => BoxDecoration(
        color: const Color(0xFF0B1220),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: ProColors.border),
      );

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Container(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: _box,
              child: Row(
                children: [
                  const Icon(Icons.search, size: 16, color: ProColors.textMuted),
                  const SizedBox(width: 6),
                  Expanded(
                    child: TextField(
                      controller: arama,
                      onChanged: onQuery,
                      style: const TextStyle(color: ProColors.text, fontFamily: 'Inter', fontSize: 13),
                      decoration: const InputDecoration(
                        hintText: 'Personel ara...',
                        hintStyle: TextStyle(color: ProColors.textMuted, fontFamily: 'Inter', fontSize: 13),
                        border: InputBorder.none,
                        isCollapsed: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            onSelected: onEkip,
            padding: EdgeInsets.zero,
            color: const Color(0xFF111827),
            itemBuilder: (context) => [
              for (final name in ekipler)
                PopupMenuItem(value: name, child: Text(name, style: const TextStyle(color: ProColors.text, fontFamily: 'Inter'))),
            ],
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              decoration: _box,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.filter_alt_outlined, size: 14, color: ProColors.textMuted),
                  const SizedBox(width: 4),
                  Text('Ekip: $ekip', style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: ProColors.text)),
                  const Icon(Icons.keyboard_arrow_down, size: 16, color: ProColors.textMuted),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HaftaPersonelTablosu extends StatelessWidget {
  const _HaftaPersonelTablosu({
    required this.weekStart,
    required this.dayNames,
    required this.people,
    required this.ekip,
    required this.arama,
    required this.onEkip,
    required this.onQuery,
  });

  final DateTime weekStart;
  final List<String> dayNames;
  final List<_HaftaKisi> people;
  final String ekip;
  final TextEditingController arama;
  final ValueChanged<String> onEkip;
  final ValueChanged<String> onQuery;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _PersonelAramaSatiri(
          ekip: ekip,
          ekipler: ['Tümü', for (final team in _ekipler) team.name],
          arama: arama,
          onEkip: onEkip,
          onQuery: onQuery,
        ),
        const SizedBox(height: 8),
        const _DurumAciklama(),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.fromLTRB(8, 10, 4, 8),
          decoration: BoxDecoration(
            color: const Color(0xFF0B1220),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: ProColors.border),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: Text('Personel\n(${people.length} kişi)', style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: ProColors.textMuted)),
                  ),
                  for (var index = 0; index < 7; index++)
                    Expanded(
                      child: Column(
                        children: [
                          Text(dayNames[index], style: const TextStyle(fontFamily: 'Inter', fontSize: 10, color: ProColors.textMuted)),
                          Text('${weekStart.add(Duration(days: index)).day}', style: const TextStyle(fontFamily: 'Inter', fontSize: 10, color: ProColors.textFaint)),
                        ],
                      ),
                    ),
                  const _SigdirBaslik('Toplam\n(Gün)', flex: 2),
                  const SizedBox(width: 14),
                ],
              ),
              const SizedBox(height: 6),
              for (final person in people) _HaftaKisiSatiri(person: person),
            ],
          ),
        ),
      ],
    );
  }
}

class _HaftaKisiSatiri extends StatelessWidget {
  const _HaftaKisiSatiri({required this.person});

  final _HaftaKisi person;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Row(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: person.color, shape: BoxShape.circle),
                  child: Text(person.initials, style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: 9, color: Colors.white)),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(person.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 11, color: ProColors.text)),
                      Text('${person.team} - ${person.unvan}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontFamily: 'Inter', fontSize: 9, color: ProColors.textMuted)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          for (final mark in person.days.split(''))
            Expanded(child: Center(child: _HaftaDurumIkonu(mark: mark))),
          Expanded(
            flex: 2,
            child: Text(
              '${person.toplam}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontFamily: 'Rajdhani', fontWeight: FontWeight.w700, fontSize: 14, color: ProColors.text),
            ),
          ),
          const Icon(Icons.chevron_right, size: 14, color: ProColors.textMuted),
        ],
      ),
    );
  }
}

class _HaftaDurumIkonu extends StatelessWidget {
  const _HaftaDurumIkonu({required this.mark});

  final String mark;

  @override
  Widget build(BuildContext context) {
    final (Color background, Color foreground, IconData icon) = switch (mark) {
      'I' => (const Color(0xFF1E3A8A), const Color(0xFF93C5FD), Icons.hotel),
      'Y' => (const Color(0xFF7F1D1D), const Color(0xFFFCA5A5), Icons.remove),
      'H' => (const Color(0xFF78350F), const Color(0xFFFBBF24), Icons.contrast),
      _ => (const Color(0xFF14532D), const Color(0xFF4ADE80), Icons.check),
    };
    return Container(
      width: 18,
      height: 18,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(5)),
      child: Icon(icon, size: 11, color: foreground),
    );
  }
}

class _HaftaOzet extends StatelessWidget {
  const _HaftaOzet({
    required this.title,
    required this.sahada,
    required this.yarim,
    required this.izinli,
    required this.yok,
    required this.kisiGun,
    required this.kisiGunLabel,
  });

  final String title;
  final String sahada;
  final String yarim;
  final String izinli;
  final String yok;
  final String kisiGun;
  final String kisiGunLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1220),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ProColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: ProColors.textMuted)),
          const SizedBox(height: 8),
          _ToplamSatiri(
            children: [
              _PuantajTotal(value: sahada, label: 'Sahada', icon: Icons.groups, color: const Color(0xFF4ADE80), tint: const Color(0xFF14532D)),
              _PuantajTotal(value: izinli, label: 'İzinli', icon: Icons.hotel, color: const Color(0xFF93C5FD), tint: const Color(0xFF1E3A8A)),
              _PuantajTotal(value: yok, label: 'Yok', icon: Icons.do_not_disturb_on, color: const Color(0xFFFCA5A5), tint: const Color(0xFF7F1D1D)),
              _PuantajTotal(value: yarim, label: 'Yarım', icon: Icons.contrast, color: const Color(0xFFFBBF24), tint: const Color(0xFF78350F)),
              _PuantajTotal(value: kisiGun, label: kisiGunLabel, icon: null, color: Colors.black, labelColor: Colors.black, tint: const Color(0xFFE5E7EB), solid: true),
            ],
          ),
        ],
      ),
    );
  }
}

class _PersonelEkleDialog extends StatefulWidget {
  const _PersonelEkleDialog();

  @override
  State<_PersonelEkleDialog> createState() => _PersonelEkleDialogState();
}

class _PersonelEkleDialogState extends State<_PersonelEkleDialog> {
  final _name = TextEditingController();
  final _unvan = TextEditingController(text: 'İşçi');

  @override
  void dispose() {
    _name.dispose();
    _unvan.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF0B1220),
      title: const Text('Personel Ekle', style: TextStyle(fontFamily: 'Rajdhani', color: ProColors.text)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _name,
            style: const TextStyle(color: ProColors.text),
            decoration: const InputDecoration(labelText: 'Adı Soyadı'),
          ),
          TextField(
            controller: _unvan,
            style: const TextStyle(color: ProColors.text),
            decoration: const InputDecoration(labelText: 'Ünvan'),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Vazgeç')),
        TextButton(
          onPressed: () => Navigator.pop(context, (_name.text.trim(), _unvan.text.trim())),
          child: const Text('Ekle'),
        ),
      ],
    );
  }
}

class _PuantajTopBar extends StatelessWidget {
  const _PuantajTopBar({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Row(
            children: [
              InkWell(
                key: const Key('puantaj-back'),
                onTap: onBack,
                borderRadius: BorderRadius.circular(8),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.chevron_left, color: ProColors.text, size: 22),
                      Text(
                        'Saha',
                        style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: ProColors.text),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: ProColors.border),
                ),
                child: const Icon(Icons.calendar_today_outlined, size: 16, color: ProColors.text),
              ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset('assets/images/splash_bolt.png', height: 18),
              const SizedBox(width: 6),
              Image.asset('assets/images/splash_wordmark.png', height: 14),
              const SizedBox(width: 4),
              const Text(
                'PRO',
                style: TextStyle(
                  fontFamily: 'Rajdhani',
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  letterSpacing: 1,
                  color: ProColors.electricBlue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PuantajMark extends StatelessWidget {
  const _PuantajMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: const Color(0xFF2563EB),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.groups, color: Colors.white, size: 26),
    );
  }
}

class _PuantajRangeBar extends StatelessWidget {
  const _PuantajRangeBar({required this.range, required this.onChanged});

  final _PuantajRange range;
  final ValueChanged<_PuantajRange> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1220),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ProColors.border),
      ),
      child: Row(
        children: [
          for (final item in _PuantajRange.values)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(item),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: item == range ? const Color(0xFF2563EB) : Colors.transparent,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    item.label,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: item == range ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 14,
                      color: item == range ? Colors.white : ProColors.textMuted,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PuantajWeekStrip extends StatelessWidget {
  const _PuantajWeekStrip({
    required this.weekStart,
    required this.selected,
    required this.dayNames,
    required this.onSelect,
    required this.onPrevious,
    required this.onNext,
  });

  final DateTime weekStart;
  final DateTime selected;
  final List<String> dayNames;
  final ValueChanged<DateTime> onSelect;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1220),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ProColors.border),
      ),
      child: Row(
        children: [
          IconButton(
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 36),
            onPressed: onPrevious,
            icon: const Icon(Icons.chevron_left, color: ProColors.textMuted, size: 20),
          ),
          for (var index = 0; index < 7; index++)
            Expanded(
              child: _WeekDay(
                name: dayNames[index],
                day: weekStart.add(Duration(days: index)),
                selected: _sameDay(weekStart.add(Duration(days: index)), selected),
                onTap: () => onSelect(weekStart.add(Duration(days: index))),
              ),
            ),
          IconButton(
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 36),
            onPressed: onNext,
            icon: const Icon(Icons.chevron_right, color: ProColors.textMuted, size: 20),
          ),
        ],
      ),
    );
  }
}

class _WeekDay extends StatelessWidget {
  const _WeekDay({required this.name, required this.day, required this.selected, required this.onTap});

  final String name;
  final DateTime day;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Column(
        children: [
          Text(
            name,
            style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: selected ? ProColors.text : ProColors.textMuted),
          ),
          const SizedBox(height: 4),
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? const Color(0xFF2563EB) : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Text(
              '${day.day}',
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: selected ? Colors.white : ProColors.text,
              ),
            ),
          ),
          const SizedBox(height: 3),
          Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: selected ? const Color(0xFF2563EB) : Colors.transparent,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}

class _PuantajEkipDetay extends StatelessWidget {
  const _PuantajEkipDetay({
    required this.team,
    required this.people,
    required this.savedLabel,
    required this.onDurum,
    required this.onRemove,
    required this.onAdd,
  });

  final _EkipPuantaj team;
  final List<_PersonelKaydi> people;
  final String savedLabel;
  final void Function(int index, _PuantajDurum durum) onDurum;
  final ValueChanged<int> onRemove;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final sahada = people.where((person) => person.durum == _PuantajDurum.sahada).length;
    final yarim = people.where((person) => person.durum == _PuantajDurum.yarim).length;
    final izinli = people.where((person) => person.durum == _PuantajDurum.izinli).length;
    final yok = people.where((person) => person.durum == _PuantajDurum.yok).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF0B1220),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: ProColors.border),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(color: team.color.withValues(alpha: 0.2), shape: BoxShape.circle),
                    child: Icon(team.icon, color: team.color, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(team.name, style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: 16, color: ProColors.text)),
                        Text('${people.length} personel', style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: ProColors.textMuted)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _ToplamSatiri(
                children: [
                  _PuantajTotal(value: '$sahada', label: 'Sahada', icon: Icons.groups, color: const Color(0xFF4ADE80), tint: const Color(0xFF14532D)),
                  _PuantajTotal(value: '$izinli', label: 'İzinli', icon: Icons.hotel, color: const Color(0xFF93C5FD), tint: const Color(0xFF1E3A8A)),
                  _PuantajTotal(value: '$yok', label: 'Yok', icon: Icons.do_not_disturb_on, color: const Color(0xFFFCA5A5), tint: const Color(0xFF7F1D1D)),
                  _PuantajTotal(value: '$yarim', label: 'Yarım', icon: Icons.contrast, color: const Color(0xFFFBBF24), tint: const Color(0xFF78350F)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Expanded(flex: 5, child: Text('Adı Soyadı', style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: ProColors.textMuted))),
                  const Expanded(flex: 2, child: Text('Ünvan', style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: ProColors.textMuted))),
                  const Expanded(flex: 3, child: Text('Durum', style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: ProColors.textMuted))),
                  InkWell(
                    onTap: onAdd,
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: ProColors.border),
                      ),
                      child: const Icon(Icons.add, size: 16, color: ProColors.textMuted),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              for (var index = 0; index < people.length; index++)
                _PersonelSatiri(
                  person: people[index],
                  onDurum: (durum) => onDurum(index, durum),
                  onRemove: () => onRemove(index),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Personel Ekle'),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF60A5FA),
            side: const BorderSide(color: Color(0xFF1D4ED8)),
            minimumSize: const Size.fromHeight(46),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 14),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF052E16),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF166534)),
          ),
          child: Row(
            children: [
              const Icon(Icons.check_circle, color: Color(0xFF4ADE80), size: 18),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Puantaj otomatik olarak kaydedildi.',
                  style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: Color(0xFF86EFAC)),
                ),
              ),
              Text(savedLabel, style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: ProColors.textMuted)),
            ],
          ),
        ),
      ],
    );
  }
}

class _PersonelSatiri extends StatelessWidget {
  const _PersonelSatiri({required this.person, required this.onDurum, required this.onRemove});

  final _PersonelKaydi person;
  final ValueChanged<_PuantajDurum> onDurum;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: person.color, shape: BoxShape.circle),
                  child: Text(
                    person.initials,
                    style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: 11, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    person.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 13, color: ProColors.text),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(person.unvan, style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: ProColors.textMuted)),
          ),
          Expanded(
            flex: 3,
            child: PopupMenuButton<_PuantajDurum>(
              onSelected: onDurum,
              color: const Color(0xFF111827),
              itemBuilder: (context) => [
                for (final durum in _PuantajDurum.values)
                  PopupMenuItem(value: durum, child: Text(durum.label, style: const TextStyle(color: ProColors.text, fontFamily: 'Inter'))),
              ],
              child: _DurumChip(durum: person.durum),
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (_) => onRemove(),
            color: const Color(0xFF111827),
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'sil', child: Text('Listeden çıkar', style: TextStyle(color: ProColors.text, fontFamily: 'Inter'))),
            ],
            child: const Icon(Icons.more_horiz, color: ProColors.textMuted, size: 18),
          ),
        ],
      ),
    );
  }
}

class _DurumChip extends StatelessWidget {
  const _DurumChip({required this.durum});

  final _PuantajDurum durum;

  @override
  Widget build(BuildContext context) {
    final (Color background, Color foreground, IconData icon) = switch (durum) {
      _PuantajDurum.sahada => (const Color(0xFF14532D), const Color(0xFF4ADE80), Icons.check_circle),
      _PuantajDurum.izinli => (const Color(0xFF1E3A8A), const Color(0xFF93C5FD), Icons.hotel),
      _PuantajDurum.yok => (const Color(0xFF7F1D1D), const Color(0xFFFCA5A5), Icons.do_not_disturb_on),
      _PuantajDurum.yarim => (const Color(0xFF78350F), const Color(0xFFFBBF24), Icons.contrast),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: foreground),
          const SizedBox(width: 3),
          Flexible(
            child: Text(
              durum.label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 11, color: foreground),
            ),
          ),
          Icon(Icons.keyboard_arrow_down, size: 14, color: foreground),
        ],
      ),
    );
  }
}

class _PuantajFilterChip extends StatelessWidget {
  const _PuantajFilterChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFF2563EB) : const Color(0xFF111827),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: selected ? const Color(0xFF2563EB) : ProColors.border),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w600,
              fontSize: 12,
              color: selected ? Colors.white : ProColors.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}

class _PuantajTable extends StatelessWidget {
  const _PuantajTable({required this.rows});

  final List<_EkipPuantaj> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0B1220),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ProColors.border),
      ),
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(12, 10, 8, 8),
            child: Row(
              children: [
                Expanded(flex: 5, child: Text('Ekip', style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: ProColors.textMuted))),
                Expanded(flex: 2, child: Text('Sahada', textAlign: TextAlign.center, style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: ProColors.textMuted))),
                Expanded(flex: 2, child: Text('Yarım', textAlign: TextAlign.center, style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: ProColors.textMuted))),
                Expanded(flex: 2, child: Text('İzinli', textAlign: TextAlign.center, style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: ProColors.textMuted))),
                Expanded(flex: 2, child: Text('Yok', textAlign: TextAlign.center, style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: ProColors.textMuted))),
                const _SigdirBaslik('Toplam', flex: 2, size: 12),
              ],
            ),
          ),
          const Divider(height: 1, color: ProColors.border),
          for (final row in rows) _PuantajRow(row: row),
        ],
      ),
    );
  }
}

class _PuantajRow extends StatelessWidget {
  const _PuantajRow({required this.row});

  final _EkipPuantaj row;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(color: row.color.withValues(alpha: 0.2), shape: BoxShape.circle),
                  child: Icon(row.icon, size: 15, color: row.color),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        row.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 13, color: ProColors.text),
                      ),
                      Text(
                        '${row.people} kişi',
                        style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: ProColors.textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(flex: 2, child: _CountPill(value: row.sahada, kind: _CountKind.sahada)),
          Expanded(flex: 2, child: _CountPill(value: row.yarim, kind: _CountKind.yarim)),
          Expanded(flex: 2, child: _CountPill(value: row.izinli, kind: _CountKind.izinli)),
          Expanded(flex: 2, child: _CountPill(value: row.yok, kind: _CountKind.yok)),
          Expanded(
            flex: 2,
            child: Text(
              '${row.toplam}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontFamily: 'Rajdhani', fontWeight: FontWeight.w700, fontSize: 16, color: ProColors.text),
            ),
          ),
        ],
      ),
    );
  }
}

enum _CountKind { sahada, yarim, izinli, yok }

class _CountPill extends StatelessWidget {
  const _CountPill({required this.value, required this.kind});

  final int value;
  final _CountKind kind;

  @override
  Widget build(BuildContext context) {
    final (Color background, Color foreground) = switch (kind) {
      _CountKind.sahada => value == 0 ? (const Color(0xFF052E16), const Color(0xFF166534)) : (const Color(0xFF14532D), const Color(0xFF4ADE80)),
      _CountKind.yarim => value == 0 ? (const Color(0xFF1C1917), const Color(0xFF78350F)) : (const Color(0xFF78350F), const Color(0xFFFBBF24)),
      _CountKind.izinli => value == 0 ? (const Color(0xFF0F172A), const Color(0xFF334155)) : (const Color(0xFF1E3A8A), const Color(0xFF93C5FD)),
      _CountKind.yok => value == 0 ? (const Color(0xFF2A1215), const Color(0xFF7F1D1D)) : (const Color(0xFF7F1D1D), const Color(0xFFFECACA)),
    };
    return Center(
      child: Container(
        width: 26,
        height: 22,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(6)),
        child: Text(
          '$value',
          style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: 12, color: foreground),
        ),
      ),
    );
  }
}

class _SigdirBaslik extends StatelessWidget {
  const _SigdirBaslik(this.text, {this.flex = 1, this.size = 10});

  final String text;
  final int flex;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: SizedBox(
        height: size * 2.8,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.center,
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'Inter', fontSize: size, height: 1.15, color: ProColors.textMuted),
          ),
        ),
      ),
    );
  }
}

class _DurumAciklama extends StatelessWidget {
  const _DurumAciklama();

  @override
  Widget build(BuildContext context) {
    return const Wrap(
      spacing: 12,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _DurumEtiket(Icons.check_circle, Color(0xFF4ADE80), 'Sahada'),
        _DurumEtiket(Icons.hotel, Color(0xFF93C5FD), 'İzinli'),
        _DurumEtiket(Icons.do_not_disturb_on, Color(0xFFFCA5A5), 'Yok'),
        _DurumEtiket(Icons.contrast, Color(0xFFFBBF24), 'Yarım'),
      ],
    );
  }
}

class _DurumEtiket extends StatelessWidget {
  const _DurumEtiket(this.icon, this.color, this.label);

  final IconData icon;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: ProColors.textMuted)),
      ],
    );
  }
}

class _ToplamSatiri extends StatelessWidget {
  const _ToplamSatiri({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var index = 0; index < children.length; index++) ...[
            if (index > 0) const SizedBox(width: 8),
            Expanded(child: children[index]),
          ],
        ],
      ),
    );
  }
}

class _PuantajTotal extends StatelessWidget {
  const _PuantajTotal({
    required this.value,
    required this.label,
    required this.color,
    required this.tint,
    this.icon,
    this.labelColor = ProColors.textMuted,
    this.solid = false,
  });

  final String value;
  final String label;
  final IconData? icon;
  final Color color;
  final Color tint;
  final Color labelColor;
  final bool solid;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      decoration: BoxDecoration(
        color: solid ? tint : tint.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: solid ? const Color(0xFFD1D5DB) : tint),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) Icon(icon, size: 16, color: color),
          Text(
            value,
            style: TextStyle(fontFamily: 'Rajdhani', fontWeight: FontWeight.w700, fontSize: 20, color: color),
          ),
          for (final line in label.split('\n'))
            Text(
              line,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.fade,
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: 'Inter', fontSize: 10, color: labelColor),
            ),
        ],
      ),
    );
  }
}

(int, int, int, int) _dortYuzde(int first, int second, int third, int fourth) {
  final parts = [first, second, third, fourth];
  final whole = parts.fold<int>(0, (sum, value) => sum + value);
  if (whole == 0) return (0, 0, 0, 0);
  final raw = [for (final value in parts) value / whole];
  final rounded = [for (final value in raw) (value * 100).round()];
  final drift = rounded.fold<int>(0, (sum, value) => sum + value) - 100;
  if (drift != 0) {
    var index = 0;
    for (var cursor = 1; cursor < raw.length; cursor++) {
      if (raw[cursor] > raw[index]) index = cursor;
    }
    rounded[index] -= drift;
  }
  return (rounded[0], rounded[1], rounded[2], rounded[3]);
}

class _AyKisi {
  const _AyKisi(this.name, this.team, this.unvan, this.initials, this.color, this.sahada, this.yarim, this.izinli, this.yok);

  final String name;
  final String team;
  final String unvan;
  final String initials;
  final Color color;
  final int sahada;
  final int yarim;
  final int izinli;
  final int yok;

  int get toplam => sahada + yarim + izinli + yok;
}

class _AylikSayfa extends StatelessWidget {
  const _AylikSayfa({
    required this.monthLabel,
    required this.sekme,
    required this.ekip,
    required this.query,
    required this.arama,
    required this.kisiler,
    required this.onPrevious,
    required this.onNext,
    required this.onSekme,
    required this.onEkip,
    required this.onQuery,
    required this.onReport,
  });

  final String monthLabel;
  final _HaftalikSekme sekme;
  final String ekip;
  final String query;
  final TextEditingController arama;
  final List<_AyKisi> kisiler;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final ValueChanged<_HaftalikSekme> onSekme;
  final ValueChanged<String> onEkip;
  final ValueChanged<String> onQuery;
  final VoidCallback onReport;

  @override
  Widget build(BuildContext context) {
    final people = kisiler.where((person) {
      final matchesTeam = ekip == 'Tümü' || person.team == ekip;
      final matchesQuery = query.trim().isEmpty || person.name.toLowerCase().contains(query.trim().toLowerCase());
      return matchesTeam && matchesQuery;
    }).toList();
    final tumu = ekip == 'Tümü' && query.trim().isEmpty;
    final kaynak = sekme == _HaftalikSekme.ekip ? kisiler : people;
    final sahada = kaynak.fold<int>(0, (sum, person) => sum + person.sahada);
    final yarim = kaynak.fold<int>(0, (sum, person) => sum + person.yarim);
    final izinli = kaynak.fold<int>(0, (sum, person) => sum + person.izinli);
    final yok = kaynak.fold<int>(0, (sum, person) => sum + person.yok);
    final toplam = sahada + yarim + izinli + yok;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _HaftaAralikBar(label: monthLabel, onPrevious: onPrevious, onNext: onNext),
        const SizedBox(height: 10),
        _HaftaSekmeBar(sekme: sekme, onChanged: onSekme),
        const SizedBox(height: 10),
        if (sekme == _HaftalikSekme.ekip)
          _AyEkipTablosu(people: kisiler)
        else
          _AyPersonelTablosu(people: people, ekip: ekip, arama: arama, onEkip: onEkip, onQuery: onQuery),
        const SizedBox(height: 12),
        _AyDagilim(
          title: sekme == _HaftalikSekme.ekip ? 'Aylık Dağılım' : (tumu ? 'Ay Özeti (Tüm Personel)' : 'Ay Özeti'),
          showBar: sekme == _HaftalikSekme.ekip,
          sahada: sahada,
          yarim: yarim,
          izinli: izinli,
          yok: yok,
          toplam: toplam,
        ),
        const SizedBox(height: 12),
        Material(
          color: const Color(0xFF0B1220),
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: onReport,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: ProColors.border),
              ),
              child: const Row(
                children: [
                  Icon(Icons.bar_chart_rounded, color: Color(0xFF60A5FA), size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Detaylı Raporu Görüntüle',
                      style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 14, color: ProColors.text),
                    ),
                  ),
                  Icon(Icons.chevron_right, color: ProColors.textMuted),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AyEkipTablosu extends StatelessWidget {
  const _AyEkipTablosu({required this.people});

  final List<_AyKisi> people;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 10, 4, 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1220),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ProColors.border),
      ),
      child: Column(
        children: [
          const Row(
            children: [
              Expanded(flex: 4, child: Text('Ekip', style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: ProColors.textMuted))),
              Expanded(flex: 2, child: Text('Sahada\nKişi-gün', textAlign: TextAlign.center, style: TextStyle(fontFamily: 'Inter', fontSize: 10, color: ProColors.textMuted))),
              Expanded(flex: 2, child: Text('Yarım\nKişi-gün', textAlign: TextAlign.center, style: TextStyle(fontFamily: 'Inter', fontSize: 10, color: ProColors.textMuted))),
              Expanded(flex: 2, child: Text('İzinli\nKişi-gün', textAlign: TextAlign.center, style: TextStyle(fontFamily: 'Inter', fontSize: 10, color: ProColors.textMuted))),
              Expanded(flex: 2, child: Text('Yok\nKişi-gün', textAlign: TextAlign.center, style: TextStyle(fontFamily: 'Inter', fontSize: 10, color: ProColors.textMuted))),
              const _SigdirBaslik('Toplam\nKişi-gün', flex: 2),
              SizedBox(width: 14),
            ],
          ),
          const SizedBox(height: 8),
          for (final team in _ekipler)
            _AyEkipSatiri(
              team: team,
              people: people.where((person) => person.team == team.name).toList(),
            ),
        ],
      ),
    );
  }
}

class _AyEkipSatiri extends StatelessWidget {
  const _AyEkipSatiri({required this.team, required this.people});

  final _EkipTanimi team;
  final List<_AyKisi> people;

  @override
  Widget build(BuildContext context) {
    final sahada = people.fold<int>(0, (sum, person) => sum + person.sahada);
    final yarim = people.fold<int>(0, (sum, person) => sum + person.yarim);
    final izinli = people.fold<int>(0, (sum, person) => sum + person.izinli);
    final yok = people.fold<int>(0, (sum, person) => sum + person.yok);
    final toplam = sahada + yarim + izinli + yok;
    final yuzde = _dortYuzde(sahada, yarim, izinli, yok);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Row(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(color: team.color.withValues(alpha: 0.2), shape: BoxShape.circle),
                  child: Icon(team.icon, size: 14, color: team.color),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(team.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 12, color: ProColors.text)),
                      Text('${people.length} kişi', style: const TextStyle(fontFamily: 'Inter', fontSize: 10, color: ProColors.textMuted)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(flex: 2, child: _AySayi(value: sahada, percent: yuzde.$1, color: const Color(0xFF4ADE80))),
          Expanded(flex: 2, child: _AySayi(value: yarim, percent: yuzde.$2, color: const Color(0xFFFBBF24))),
          Expanded(flex: 2, child: _AySayi(value: izinli, percent: yuzde.$3, color: const Color(0xFF93C5FD))),
          Expanded(flex: 2, child: _AySayi(value: yok, percent: yuzde.$4, color: const Color(0xFFFCA5A5))),
          Expanded(
            flex: 2,
            child: Text('$toplam', textAlign: TextAlign.center, style: const TextStyle(fontFamily: 'Rajdhani', fontWeight: FontWeight.w700, fontSize: 16, color: ProColors.text)),
          ),
          const Icon(Icons.chevron_right, size: 16, color: ProColors.textMuted),
        ],
      ),
    );
  }
}

class _AySayi extends StatelessWidget {
  const _AySayi({required this.value, required this.percent, required this.color});

  final int value;
  final int percent;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('$value', style: TextStyle(fontFamily: 'Rajdhani', fontWeight: FontWeight.w700, fontSize: 16, color: color)),
        Text('%$percent', style: TextStyle(fontFamily: 'Inter', fontSize: 10, color: color.withValues(alpha: 0.8))),
      ],
    );
  }
}

class _AyPersonelTablosu extends StatelessWidget {
  const _AyPersonelTablosu({
    required this.people,
    required this.ekip,
    required this.arama,
    required this.onEkip,
    required this.onQuery,
  });

  final List<_AyKisi> people;
  final String ekip;
  final TextEditingController arama;
  final ValueChanged<String> onEkip;
  final ValueChanged<String> onQuery;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _PersonelAramaSatiri(
          ekip: ekip,
          ekipler: ['Tümü', for (final team in _ekipler) team.name],
          arama: arama,
          onEkip: onEkip,
          onQuery: onQuery,
        ),
        const SizedBox(height: 8),
        const _DurumAciklama(),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.fromLTRB(8, 10, 4, 8),
          decoration: BoxDecoration(
            color: const Color(0xFF0B1220),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: ProColors.border),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(flex: 4, child: Text('Personel\n(${people.length} kişi)', style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: ProColors.textMuted))),
                  const Expanded(flex: 2, child: Text('Sahada\nGün  %', textAlign: TextAlign.center, style: TextStyle(fontFamily: 'Inter', fontSize: 10, color: ProColors.textMuted))),
                  const Expanded(flex: 2, child: Text('Yarım\nGün  %', textAlign: TextAlign.center, style: TextStyle(fontFamily: 'Inter', fontSize: 10, color: ProColors.textMuted))),
                  const Expanded(flex: 2, child: Text('İzinli\nGün  %', textAlign: TextAlign.center, style: TextStyle(fontFamily: 'Inter', fontSize: 10, color: ProColors.textMuted))),
                  const Expanded(flex: 2, child: Text('Yok\nGün  %', textAlign: TextAlign.center, style: TextStyle(fontFamily: 'Inter', fontSize: 10, color: ProColors.textMuted))),
                  const _SigdirBaslik('Toplam\nGün', flex: 2),
                  const SizedBox(width: 14),
                ],
              ),
              const SizedBox(height: 6),
              for (final person in people)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 4,
                        child: Row(
                          children: [
                            Container(
                              width: 26,
                              height: 26,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(color: person.color, shape: BoxShape.circle),
                              child: Text(person.initials, style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: 9, color: Colors.white)),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(person.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 11, color: ProColors.text)),
                                  Text('${person.team} - ${person.unvan}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontFamily: 'Inter', fontSize: 9, color: ProColors.textMuted)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(flex: 2, child: _AySayi(value: person.sahada, percent: _dortYuzde(person.sahada, person.yarim, person.izinli, person.yok).$1, color: const Color(0xFF4ADE80))),
                      Expanded(flex: 2, child: _AySayi(value: person.yarim, percent: _dortYuzde(person.sahada, person.yarim, person.izinli, person.yok).$2, color: const Color(0xFFFBBF24))),
                      Expanded(flex: 2, child: _AySayi(value: person.izinli, percent: _dortYuzde(person.sahada, person.yarim, person.izinli, person.yok).$3, color: const Color(0xFF93C5FD))),
                      Expanded(flex: 2, child: _AySayi(value: person.yok, percent: _dortYuzde(person.sahada, person.yarim, person.izinli, person.yok).$4, color: const Color(0xFFFCA5A5))),
                      Expanded(flex: 2, child: Text('${person.toplam}', textAlign: TextAlign.center, style: const TextStyle(fontFamily: 'Rajdhani', fontWeight: FontWeight.w700, fontSize: 15, color: ProColors.text))),
                      const Icon(Icons.chevron_right, size: 14, color: ProColors.textMuted),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AyDagilim extends StatelessWidget {
  const _AyDagilim({
    required this.title,
    required this.showBar,
    required this.sahada,
    required this.yarim,
    required this.izinli,
    required this.yok,
    required this.toplam,
  });

  final String title;
  final bool showBar;
  final int sahada;
  final int yarim;
  final int izinli;
  final int yok;
  final int toplam;

  @override
  Widget build(BuildContext context) {
    final yuzde = _dortYuzde(sahada, yarim, izinli, yok);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1220),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ProColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: ProColors.textMuted)),
          if (showBar) ...[
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 10,
              child: Row(
                children: [
                  if (sahada > 0) Expanded(flex: sahada, child: const ColoredBox(color: Color(0xFF22C55E))),
                  if (yarim > 0) Expanded(flex: yarim, child: const ColoredBox(color: Color(0xFFFBBF24))),
                  if (izinli > 0) Expanded(flex: izinli, child: const ColoredBox(color: Color(0xFF60A5FA))),
                  if (yok > 0) Expanded(flex: yok, child: const ColoredBox(color: Color(0xFFEF4444))),
                ],
              ),
            ),
          ),
          ],
          const SizedBox(height: 10),
          _ToplamSatiri(
            children: [
              _PuantajTotal(value: '$sahada', label: 'Sahada\n%${yuzde.$1}', icon: Icons.groups, color: const Color(0xFF4ADE80), tint: const Color(0xFF14532D)),
              _PuantajTotal(value: '$yarim', label: 'Yarım\n%${yuzde.$2}', icon: Icons.contrast, color: const Color(0xFFFBBF24), tint: const Color(0xFF78350F)),
              _PuantajTotal(value: '$izinli', label: 'İzinli\n%${yuzde.$3}', icon: Icons.hotel, color: const Color(0xFF93C5FD), tint: const Color(0xFF1E3A8A)),
              _PuantajTotal(value: '$yok', label: 'Yok\n%${yuzde.$4}', icon: Icons.do_not_disturb_on, color: const Color(0xFFFCA5A5), tint: const Color(0xFF7F1D1D)),
              _PuantajTotal(value: '$toplam', label: 'Kişi-gün\n%100', icon: null, color: Colors.black, labelColor: Colors.black, tint: const Color(0xFFE5E7EB), solid: true),
            ],
          ),
        ],
      ),
    );
  }
}
