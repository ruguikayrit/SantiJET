import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:santijet_demir/core/format/app_format.dart';
import 'package:santijet_demir/core/theme/app_colors.dart';
import 'package:santijet_demir/core/widgets/empty_states.dart';
import 'package:santijet_demir/core/widgets/santijet_header.dart';
import 'package:santijet_demir/domain/entities/delivery.dart';
import 'package:santijet_demir/domain/enums/app_enums.dart';
import 'package:santijet_demir/features/incoming_rebar/providers/incoming_rebar_provider.dart';
import 'package:santijet_demir/features/incoming_rebar/widgets/delivery_card.dart';
import 'package:santijet_demir/features/orders/orders_screen.dart';
import 'package:santijet_demir/features/projects/providers/project_provider.dart';

const _statusChips = <(DeliveryStatus, String)>[
  (DeliveryStatus.received, 'Teslim Alındı'),
  (DeliveryStatus.partial, 'Kısmi Teslim'),
  (DeliveryStatus.missing, 'Eksik'),
  (DeliveryStatus.excess, 'Fazla'),
  (DeliveryStatus.pending, 'Beklemede'),
];

class DeliveryListScreen extends ConsumerStatefulWidget {
  const DeliveryListScreen({super.key});

  @override
  ConsumerState<DeliveryListScreen> createState() => _DeliveryListScreenState();
}

class _DeliveryListScreenState extends ConsumerState<DeliveryListScreen> {
  String _searchQuery = '';
  DeliveryStatus? _status;
  bool _newestFirst = true;
  DateTimeRange? _dateRange;
  int? _filterYear;
  int? _filterMonth;

  bool get _hasDateFilter =>
      _dateRange != null || _filterYear != null || _filterMonth != null;

  bool _matchesDate(DeliveryItem delivery) {
    final date = delivery.date;
    if (_dateRange != null) {
      final start = DateTime(
        _dateRange!.start.year,
        _dateRange!.start.month,
        _dateRange!.start.day,
      );
      final end = DateTime(
        _dateRange!.end.year,
        _dateRange!.end.month,
        _dateRange!.end.day,
        23,
        59,
        59,
      );
      return !date.isBefore(start) && !date.isAfter(end);
    }
    if (_filterYear != null && _filterMonth != null) {
      return date.year == _filterYear && date.month == _filterMonth;
    }
    if (_filterYear != null) {
      return date.year == _filterYear;
    }
    return true;
  }

  bool _matchesQuery(DeliveryItem delivery) {
    if (_searchQuery.isEmpty) return true;
    final query = _searchQuery.toLowerCase();
    return delivery.irsaliyeNo.toLowerCase().contains(query) ||
        delivery.orderNo.toLowerCase().contains(query) ||
        delivery.supplier.toLowerCase().contains(query) ||
        delivery.plateNo.toLowerCase().contains(query);
  }

  Future<void> _openDateFilters() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Tarih filtresi',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1C2430),
                  ),
                ),
                const SizedBox(height: 12),
                _FilterTile(
                  icon: Icons.date_range_outlined,
                  label: 'Gün aralığı',
                  onTap: () async {
                    Navigator.pop(ctx);
                    await _pickDayRange();
                  },
                ),
                _FilterTile(
                  icon: Icons.calendar_month_outlined,
                  label: 'Aya göre',
                  onTap: () async {
                    Navigator.pop(ctx);
                    await _pickMonthFilter();
                  },
                ),
                _FilterTile(
                  icon: Icons.event_outlined,
                  label: 'Yıla göre',
                  onTap: () async {
                    Navigator.pop(ctx);
                    await _pickYearFilter();
                  },
                ),
                if (_hasDateFilter)
                  _FilterTile(
                    icon: Icons.filter_alt_off_outlined,
                    label: 'Filtreyi temizle',
                    onTap: () {
                      Navigator.pop(ctx);
                      setState(() {
                        _dateRange = null;
                        _filterYear = null;
                        _filterMonth = null;
                      });
                    },
                  ),
                const Divider(height: 24),
                Text(
                  'Sıralama',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 8),
                _FilterTile(
                  icon: Icons.swap_vert,
                  label: _newestFirst ? 'Tarih (yeni → eski)' : 'Tarih (eski → yeni)',
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() => _newestFirst = !_newestFirst);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String? _activeFilterLabel() {
    if (_dateRange != null) {
      final a = _dateRange!.start;
      final b = _dateRange!.end;
      return '${a.day}.${a.month}.${a.year} – ${b.day}.${b.month}.${b.year}';
    }
    if (_filterYear != null && _filterMonth != null) {
      return '${OrderDateFilterLabels.months[_filterMonth! - 1]} ${_filterYear!}';
    }
    if (_filterYear != null) return 'Yıl ${_filterYear!}';
    return null;
  }

  Future<void> _pickDayRange() async {
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      locale: const Locale('tr', 'TR'),
      firstDate: DateTime(2020),
      lastDate: now.add(const Duration(days: 365)),
      initialDateRange: _dateRange,
      helpText: 'Tarih aralığı',
      cancelText: 'İptal',
      confirmText: 'Tamam',
      saveText: 'Kaydet',
      fieldStartHintText: 'Başlangıç',
      fieldEndHintText: 'Bitiş',
    );
    if (range == null || !mounted) return;
    setState(() {
      _dateRange = range;
      _filterYear = null;
      _filterMonth = null;
    });
  }

  Future<void> _pickMonthFilter() async {
    final picked = await showDialog<({int year, int month})>(
      context: context,
      builder: (context) => OrderMonthPickerDialog(
        initialYear: _filterYear ?? DateTime.now().year,
        initialMonth: _filterMonth,
      ),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _filterYear = picked.year;
      _filterMonth = picked.month;
      _dateRange = null;
    });
  }

  Future<void> _pickYearFilter() async {
    final picked = await showDialog<int>(
      context: context,
      builder: (context) => OrderYearPickerDialog(
        initialYear: _filterYear ?? DateTime.now().year,
      ),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _filterYear = picked;
      _filterMonth = null;
      _dateRange = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final deliveries = ref.watch(deliveriesProvider);
    final projectName = ref.watch(activeProjectProvider)?.name ?? '';

    final searched = deliveries.where(_matchesQuery).where(_matchesDate).toList();
    final counts = <DeliveryStatus, int>{};
    for (final delivery in searched) {
      counts[delivery.status] = (counts[delivery.status] ?? 0) + 1;
    }
    final filtered = searched
        .where((delivery) => _status == null || delivery.status == _status)
        .toList()
      ..sort(
        (a, b) => _newestFirst ? b.date.compareTo(a.date) : a.date.compareTo(b.date),
      );
    final totalTonnage = filtered.fold(0.0, (sum, item) => sum + item.tonnage);

    final chips = <(DeliveryStatus?, String, int)>[
      (null, 'Tümü', searched.length),
      for (final (status, label) in _statusChips) (status, label, counts[status] ?? 0),
    ];

    final filterLabel = _activeFilterLabel();

    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FA),
      body: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          children: [
            const SantijetHeader(
              subtitle: 'Teslimat Kayıtları',
              showBack: true,
            ),
            if (deliveries.isEmpty)
              const Expanded(
                child: ModuleEmptyState(type: EmptyStateType.noDelivery),
              )
            else ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        onChanged: (value) => setState(() => _searchQuery = value),
                        decoration: InputDecoration(
                          hintText: 'İrsaliye, sipariş, tedarikçi, plaka ara...',
                          hintStyle: GoogleFonts.inter(
                            color: const Color(0xFF94A3B8),
                            fontSize: 13,
                          ),
                          prefixIcon: const Icon(Icons.search, color: Color(0xFF94A3B8)),
                          filled: true,
                          fillColor: Colors.white,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: Color(0xFFE6EBF3)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: Color(0xFFE6EBF3)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Material(
                      color: _hasDateFilter ? const Color(0xFFE8F1FE) : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(
                          color: _hasDateFilter
                              ? const Color(0xFF2563EB)
                              : const Color(0xFFE6EBF3),
                        ),
                      ),
                      child: InkWell(
                        onTap: _openDateFilters,
                        borderRadius: BorderRadius.circular(14),
                        child: SizedBox(
                          width: 44,
                          height: 44,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Icon(
                                Icons.tune,
                                color: _hasDateFilter
                                    ? const Color(0xFF2563EB)
                                    : const Color(0xFF64748B),
                              ),
                              if (_hasDateFilter)
                                Positioned(
                                  top: 10,
                                  right: 10,
                                  child: Container(
                                    width: 7,
                                    height: 7,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF2563EB),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (filterLabel != null) ...[
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F1FE),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        filterLabel,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF2563EB),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              SizedBox(
                height: 36,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: chips.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final (status, label, count) = chips[index];
                    final selected = status == _status;
                    return Material(
                      color: selected ? const Color(0xFF2563EB) : Colors.white,
                      borderRadius: BorderRadius.circular(99),
                      child: InkWell(
                        onTap: () => setState(() => _status = status),
                        borderRadius: BorderRadius.circular(99),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(99),
                            border: Border.all(
                              color: selected
                                  ? const Color(0xFF2563EB)
                                  : const Color(0xFFE6EBF3),
                            ),
                          ),
                          child: Text(
                            '$label  $count',
                            style: GoogleFonts.inter(
                              color: selected ? Colors.white : const Color(0xFF475569),
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: _SummaryCard(
                        icon: Icons.local_shipping_outlined,
                        color: AppColors.success,
                        label: 'Toplam Kayıt',
                        value: '${filtered.length}',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _SummaryCard(
                        icon: Icons.scale_outlined,
                        color: AppColors.electricBlueLight,
                        label: 'Toplam',
                        value: AppFormat.tonnage(totalTonnage),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? const ModuleEmptyState(type: EmptyStateType.noSearchResult)
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          return DeliveryCard(
                            delivery: filtered[index],
                            projectName: projectName,
                          );
                        },
                      ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FilterTile extends StatelessWidget {
  const _FilterTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF2563EB)),
      title: Text(
        label,
        style: GoogleFonts.inter(
          fontWeight: FontWeight.w600,
          color: const Color(0xFF1C2430),
        ),
      ),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE6EBF2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF8B95A5),
                  ),
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1C2430),
                      height: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
