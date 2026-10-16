import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:santijet_demir/core/routing/app_routes.dart';
import 'package:santijet_demir/core/widgets/app_components.dart';
import 'package:santijet_demir/core/widgets/santijet_header.dart';
import 'package:santijet_demir/core/widgets/empty_states.dart';
import 'package:santijet_demir/core/widgets/shell_tab_guard.dart';
import 'package:santijet_demir/domain/entities/order.dart';
import 'package:santijet_demir/features/auth/providers/membership_permission_provider.dart';
import 'package:santijet_demir/features/incoming_rebar/providers/incoming_rebar_provider.dart';
import 'package:santijet_demir/features/orders/order_diameter_amounts.dart';
import 'package:santijet_demir/features/orders/providers/orders_provider.dart';
import 'package:santijet_demir/features/orders/widgets/order_card.dart';
import 'package:santijet_demir/features/projects/providers/project_provider.dart';
import 'package:santijet_demir/features/survey/providers/survey_provider.dart';

class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> {
  String _searchQuery = '';
  int _filter = 0;
  bool _newestFirst = true;
  DateTimeRange? _dateRange;
  int? _filterYear;
  int? _filterMonth;

  bool get _hasDateFilter =>
      _dateRange != null || _filterYear != null || _filterMonth != null;

  bool _matchesDate(OrderItem order) {
    final date = order.date;
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
    final hasActiveProject = ref.watch(activeProjectProvider) != null;
    final allOrders = ref.watch(ordersProvider);
    final deliveries = ref.watch(deliveriesProvider);
    final survey = ref.watch(surveyProjectProvider);

    OrderVisual visualOf(OrderItem order) {
      final amounts = resolvedOrderDiameterAmounts(order, survey.imalats);
      final ordered = amounts.isEmpty
          ? order.tonnage
          : amounts.values.fold(0.0, (sum, value) => sum + value);
      final delivered = deliveries
          .where(
            (delivery) =>
                delivery.orderId == order.id ||
                (delivery.orderNo.isNotEmpty && delivery.orderNo == order.orderNo),
          )
          .fold(0.0, (sum, delivery) => sum + delivery.tonnage);
      return orderVisual(order, delivered, ordered);
    }

    bool matchesQuery(OrderItem order) {
      if (_searchQuery.isEmpty) return true;
      final query = _searchQuery.toLowerCase();
      return order.orderNo.toLowerCase().contains(query) ||
          order.supplier.toLowerCase().contains(query) ||
          order.imalatTypes.any((type) => type.toLowerCase().contains(query));
    }

    final searched = allOrders.where(matchesQuery).where(_matchesDate).toList();
    final counts = <OrderVisual, int>{};
    for (final order in searched) {
      final visual = visualOf(order);
      counts[visual] = (counts[visual] ?? 0) + 1;
    }
    final filtered = searched.where((order) {
      final visual = visualOf(order);
      return switch (_filter) {
        1 => visual == OrderVisual.pending,
        2 => visual == OrderVisual.done,
        3 => visual == OrderVisual.cancelled,
        _ => true,
      };
    }).toList()
      ..sort(
        (a, b) => _newestFirst ? b.date.compareTo(a.date) : a.date.compareTo(b.date),
      );

    final chips = [
      ('Tümü', searched.length),
      ('Bekleyen', counts[OrderVisual.pending] ?? 0),
      ('Tamamlanan', counts[OrderVisual.done] ?? 0),
      ('İptal', counts[OrderVisual.cancelled] ?? 0),
    ];

    final filterLabel = _activeFilterLabel();

    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FB),
      floatingActionButtonLocation: ShellAddFab.location,
      floatingActionButton: hasActiveProject && ref.watch(canCreateOrderProvider)
          ? ShellAddFab(
              heroTag: 'new-order',
              onPressed: () => context.push(AppRoutes.newOrder),
            )
          : null,
      body: Column(
        children: [
          const SantijetHeader(subtitle: 'Sipariş'),
          if (!hasActiveProject)
            const Expanded(child: ActiveProjectGate(child: SizedBox.shrink()))
          else ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      onChanged: (value) => setState(() => _searchQuery = value),
                      decoration: InputDecoration(
                        hintText: 'Sipariş no, imalat, tedarikçi ara...',
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
                  final selected = index == _filter;
                  return Material(
                    color: selected ? const Color(0xFF2563EB) : Colors.white,
                    borderRadius: BorderRadius.circular(99),
                    child: InkWell(
                      onTap: () => setState(() => _filter = index),
                      borderRadius: BorderRadius.circular(99),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(99),
                          border: Border.all(
                            color: selected ? const Color(0xFF2563EB) : const Color(0xFFE6EBF3),
                          ),
                        ),
                        child: Text(
                          '${chips[index].$1}  ${chips[index].$2}',
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
            const SizedBox(height: 8),
            Expanded(
              child: filtered.isEmpty
                  ? ModuleEmptyState(
                      type: allOrders.isEmpty
                          ? EmptyStateType.noOrders
                          : EmptyStateType.noSearchResult,
                      actionLabel: 'Yeni Sipariş',
                      onAction: () => context.push(AppRoutes.newOrder),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.fromLTRB(
                        16,
                        0,
                        16,
                        AppFab.scrollClearanceOf(context),
                      ),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) => OrderCard(order: filtered[index]),
                    ),
            ),
          ],
        ],
      ),
    );
  }
}

class OrderDateFilterLabels {
  OrderDateFilterLabels._();

  static const months = [
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
}

/// Ay filtresi: üstte yıl, altta 12 ay ızgarası.
class OrderMonthPickerDialog extends StatefulWidget {
  const OrderMonthPickerDialog({
    super.key,
    required this.initialYear,
    this.initialMonth,
  });

  final int initialYear;
  final int? initialMonth;

  @override
  State<OrderMonthPickerDialog> createState() => _OrderMonthPickerDialogState();
}

class _OrderMonthPickerDialogState extends State<OrderMonthPickerDialog> {
  static const _firstYear = 2020;

  late int _year;

  @override
  void initState() {
    super.initState();
    _year = widget.initialYear;
  }

  int get _lastYear => DateTime.now().year + 1;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Ay seçin',
              style: GoogleFonts.inter(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1C2430),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                IconButton(
                  onPressed: _year <= _firstYear
                      ? null
                      : () => setState(() => _year--),
                  icon: const Icon(Icons.chevron_left),
                ),
                Expanded(
                  child: Text(
                    '$_year',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F2744),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _year >= _lastYear
                      ? null
                      : () => setState(() => _year++),
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
            const SizedBox(height: 8),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 2.2,
              ),
              itemCount: 12,
              itemBuilder: (context, index) {
                final month = index + 1;
                final isSelected =
                    widget.initialMonth == month && widget.initialYear == _year;
                return Material(
                  color: isSelected
                      ? const Color(0xFF2563EB)
                      : const Color(0xFFF3F6FB),
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => Navigator.pop(
                      context,
                      (year: _year, month: month),
                    ),
                    child: Center(
                      child: Text(
                        OrderDateFilterLabels.months[index],
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF334155),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('İptal'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Yıl filtresi: yıla dokununca filtre uygulanır, gün seçimi yok.
class OrderYearPickerDialog extends StatelessWidget {
  const OrderYearPickerDialog({super.key, required this.initialYear});

  final int initialYear;

  static const _firstYear = 2020;

  int get _lastYear => DateTime.now().year + 1;

  @override
  Widget build(BuildContext context) {
    final years = [
      for (var y = _lastYear; y >= _firstYear; y--) y,
    ];

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.55,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Yıl seçin',
                style: GoogleFonts.inter(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1C2430),
                ),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: GridView.builder(
                  shrinkWrap: true,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 2.4,
                  ),
                  itemCount: years.length,
                  itemBuilder: (context, index) {
                    final year = years[index];
                    final selected = year == initialYear;
                    return Material(
                      color: selected
                          ? const Color(0xFF2563EB)
                          : const Color(0xFFF3F6FB),
                      borderRadius: BorderRadius.circular(10),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () => Navigator.pop(context, year),
                        child: Center(
                          child: Text(
                            '$year',
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: selected
                                  ? Colors.white
                                  : const Color(0xFF334155),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('İptal'),
                ),
              ),
            ],
          ),
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
