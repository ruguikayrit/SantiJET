import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:santijet_demir/data/services/home_weather_service.dart';
import 'package:santijet_demir/features/shell/providers/home_weather_provider.dart';

class HomeWelcomeCard extends ConsumerWidget {
  const HomeWelcomeCard({super.key});

  static const ink = Color(0xFF0F2744);
  static const blue = Color(0xFF2563EB);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weatherAsync = ref.watch(homeWeatherProvider);
    final dateLabel = _capitalizeTurkishDate(
      DateFormat('d MMMM EEEE', 'tr_TR').format(DateTime.now()),
    );

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE6EBF2)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x140F2744),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const ColoredBox(
                color: HomeWelcomeCard.blue,
                child: SizedBox(width: 4),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
                  child: Row(
                    children: [
                      _InfoChip(
                        icon: Icons.calendar_today_outlined,
                        label: dateLabel,
                        onTap: () => _openCalendar(context),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: weatherAsync.when(
                            data: (weather) => weather == null
                                ? const _InfoChip(
                                    icon: Icons.cloud_off_outlined,
                                    label: 'Hava —',
                                  )
                                : _WeatherChip(weather: weather),
                            loading: () => const _InfoChip(
                              icon: Icons.cloud_queue_outlined,
                              label: 'Hava…',
                            ),
                            error: (_, __) => const _InfoChip(
                              icon: Icons.cloud_off_outlined,
                              label: 'Hava —',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openCalendar(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) => const _MonthCalendarSheet(),
    );
  }

  static String _capitalizeTurkishDate(String label) {
    return label.split(' ').map((word) {
      if (word.isEmpty) return word;
      final lower = word.toLowerCase();
      final first = lower[0];
      if (first.codeUnitAt(0) < 65) return word;
      final head = first == 'i' ? 'İ' : first.toUpperCase();
      return '$head${lower.substring(1)}';
    }).join(' ');
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label, this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: const Color(0xFFE8EDF3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: HomeWelcomeCard.blue),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              color: HomeWelcomeCard.ink,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
    if (onTap == null) return chip;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(11),
        child: chip,
      ),
    );
  }
}

class _WeatherChip extends StatelessWidget {
  const _WeatherChip({required this.weather});

  final HomeWeatherSnapshot weather;

  @override
  Widget build(BuildContext context) {
    final icon = switch (weather.icon) {
      IconKind.clear => Icons.wb_sunny_outlined,
      IconKind.partlyCloudy => Icons.wb_cloudy_outlined,
      IconKind.cloudy => Icons.cloud_outlined,
      IconKind.fog => Icons.foggy,
      IconKind.rain => Icons.grain,
      IconKind.snow => Icons.ac_unit,
      IconKind.thunder => Icons.thunderstorm_outlined,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: const Color(0xFFE8EDF3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: HomeWelcomeCard.blue),
          const SizedBox(width: 6),
          Flexible(
            fit: FlexFit.loose,
            child: Text(
              '${weather.temperatureC}°  ${weather.summary}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                color: HomeWelcomeCard.ink,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthCalendarSheet extends StatefulWidget {
  const _MonthCalendarSheet();

  @override
  State<_MonthCalendarSheet> createState() => _MonthCalendarSheetState();
}

enum _CalendarPane { days, months, years }

class _MonthCalendarSheetState extends State<_MonthCalendarSheet> {
  static const _weekdays = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
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
  static const _span = 21 * 12;

  late final DateTime _origin;
  late final DateTime _today;
  late final PageController _pages;
  late int _index;
  _CalendarPane _pane = _CalendarPane.days;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _today = DateTime(now.year, now.month, now.day);
    _origin = DateTime(now.year - 10);
    _index = (now.year - _origin.year) * 12 + now.month - 1;
    _pages = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  DateTime _monthAt(int index) => DateTime(_origin.year, index + 1);

  void _step(int delta) {
    final next = _index + delta;
    if (next < 0 || next >= _span) return;
    if (_pane == _CalendarPane.days) {
      _pages.animateToPage(
        next,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
      return;
    }
    setState(() => _index = next);
    if (_pages.hasClients) _pages.jumpToPage(next);
  }

  Widget _choiceGrid({
    required int columns,
    required int count,
    required double rowHeight,
    required String Function(int index) label,
    required bool Function(int index) selected,
    required void Function(int index) onPick,
  }) {
    final rows = (count / columns).ceil();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var row = 0; row < rows; row++)
          SizedBox(
            height: rowHeight,
            child: Row(
              children: [
                for (var column = 0; column < columns; column++)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: row * columns + column < count
                          ? _ChoiceCell(
                              label: label(row * columns + column),
                              selected: selected(row * columns + column),
                              onTap: () => onPick(row * columns + column),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  void _show(DateTime month) {
    final index = (month.year - _origin.year) * 12 + month.month - 1;
    if (index < 0 || index >= _span) return;
    setState(() {
      _index = index;
      _pane = _CalendarPane.days;
    });
    if (_pages.hasClients) _pages.jumpToPage(index);
  }

  void _toggle(_CalendarPane pane) {
    setState(() => _pane = _pane == pane ? _CalendarPane.days : pane);
  }

  @override
  Widget build(BuildContext context) {
    final month = _monthAt(_index);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        12,
        10,
        12,
        12 + MediaQuery.viewPaddingOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              IconButton(
                onPressed: _index == 0 ? null : () => _step(-1),
                icon: const Icon(Icons.chevron_left_rounded),
                color: HomeWelcomeCard.blue,
                disabledColor: const Color(0xFFCBD5E1),
              ),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _PaneLabel(
                      label: _months[month.month - 1],
                      active: _pane == _CalendarPane.months,
                      onTap: () => _toggle(_CalendarPane.months),
                    ),
                    const SizedBox(width: 4),
                    _PaneLabel(
                      label: '${month.year}',
                      active: _pane == _CalendarPane.years,
                      onTap: () => _toggle(_CalendarPane.years),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _index == _span - 1 ? null : () => _step(1),
                icon: const Icon(Icons.chevron_right_rounded),
                color: HomeWelcomeCard.blue,
                disabledColor: const Color(0xFFCBD5E1),
              ),
            ],
          ),
          const SizedBox(height: 4),
          IndexedStack(
            index: _pane.index,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      for (final day in _weekdays)
                        Expanded(
                          child: Text(
                            day,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              color: const Color(0xFF8B97A8),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    height: 240,
                    child: PageView.builder(
                      controller: _pages,
                      itemCount: _span,
                      onPageChanged: (index) => setState(() => _index = index),
                      itemBuilder: (context, index) => _MonthGrid(
                        month: _monthAt(index),
                        today: _today,
                      ),
                    ),
                  ),
                ],
              ),
              _choiceGrid(
                columns: 3,
                count: 12,
                rowHeight: 64,
                label: (index) => _months[index],
                selected: (index) => index + 1 == month.month,
                onPick: (index) => _show(DateTime(month.year, index + 1)),
              ),
              _choiceGrid(
                columns: 3,
                count: 21,
                rowHeight: 40,
                label: (index) => '${_origin.year + index}',
                selected: (index) => _origin.year + index == month.year,
                onPick: (index) => _show(DateTime(_origin.year + index, month.month)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PaneLabel extends StatelessWidget {
  const _PaneLabel({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? const Color(0xFFE8F1FE) : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Text(
            label,
            style: GoogleFonts.inter(
              color: active ? HomeWelcomeCard.blue : HomeWelcomeCard.ink,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _ChoiceCell extends StatelessWidget {
  const _ChoiceCell({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? HomeWelcomeCard.blue : const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Center(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              color: selected ? Colors.white : HomeWelcomeCard.ink,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({required this.month, required this.today});

  final DateTime month;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final lead = DateTime(month.year, month.month).weekday - 1;
    final days = DateUtils.getDaysInMonth(month.year, month.month);
    return Column(
      children: [
        for (var week = 0; week < 6; week++)
          SizedBox(
            height: 40,
            child: Row(
              children: [
                for (var weekday = 0; weekday < 7; weekday++)
                  Expanded(child: _day(week * 7 + weekday - lead + 1, days)),
              ],
            ),
          ),
      ],
    );
  }

  Widget _day(int day, int days) {
    if (day < 1 || day > days) return const SizedBox.shrink();
    final isToday = today.year == month.year &&
        today.month == month.month &&
        today.day == day;
    return Center(
      child: Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        decoration: isToday
            ? const BoxDecoration(
                color: HomeWelcomeCard.blue,
                shape: BoxShape.circle,
              )
            : null,
        child: Text(
          '$day',
          style: GoogleFonts.inter(
            color: isToday ? Colors.white : HomeWelcomeCard.ink,
            fontSize: 14,
            fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
