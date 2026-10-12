import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:santijet_demir/core/format/app_format.dart';
import 'package:santijet_demir/features/field_count/providers/field_count_provider.dart';
import 'package:santijet_demir/features/projects/providers/project_provider.dart';
import 'package:santijet_demir/core/widgets/santijet_header.dart';
import 'package:santijet_demir/features/shell/diameter_calc.dart';
import 'package:santijet_demir/features/shell/widgets/home_dashboard.dart';

class DiameterCalcDetailScreen extends ConsumerWidget {
  const DiameterCalcDetailScreen({super.key, required this.diameter});

  final int diameter;

  static const bad = Color(0xFFEF4444);
  static const warn = Color(0xFFE8A317);
  static const good = Color(0xFF16A34A);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final project = ref.watch(activeProjectProvider);
    final rows = ref.watch(reconciliationRowsProvider);
    final match = rows.where((row) => row.diameter == diameter);
    final code = project?.code.trim() ?? '';
    final location = project?.location.trim() ?? '';
    final subtitle = [
      if (code.isNotEmpty) code,
      if (location.isNotEmpty) location,
    ].join(' · ');

    return ColoredBox(
      color: HomeDashboard.page,
      child: Column(
        children: [
          _Header(
            title: 'Hesaplama Detayı (Ø$diameter)',
            subtitle: subtitle.isEmpty ? 'İş seçilmedi' : subtitle,
          ),
          Expanded(
            child: match.isEmpty
                ? Center(
                    child: Text(
                      'Bu çap keşifte yok',
                      style: GoogleFonts.inter(color: HomeDashboard.muted, fontSize: 14),
                    ),
                  )
                : _Body(calc: DiameterCalc.fromRow(match.first)),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return DemirBrandHeader(
      title: title,
      caption: subtitle,
      showBack: true,
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.calc});

  final DiameterCalc calc;

  @override
  Widget build(BuildContext context) {
    final tone = calc.critical
        ? DiameterCalcDetailScreen.bad
        : calc.warning
            ? DiameterCalcDetailScreen.warn
            : DiameterCalcDetailScreen.good;
    final status = calc.critical
        ? 'Kritik'
        : calc.warning
            ? 'Uyarı'
            : 'Normal';
    final note = calc.critical
        ? 'Fire oranı kabul edilenden yüksek.'
        : calc.warning
            ? 'Fire oranı kabul edilen sınıra yakın.'
            : 'Fire oranı kabul edilen sınırın altında.';
    final over = calc.consumption > calc.totalNeed;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        Transform.translate(
          offset: const Offset(0, -16),
          child: _StatusCard(calc: calc, tone: tone, status: status, note: note),
        ),
        _MetricCard(
          rows: [
            _Metric(
              icon: Icons.calculate_outlined,
              iconColor: HomeDashboard.blue,
              label: 'Net İmalat Miktarı (Keşif)',
              value: _tons(calc.survey),
              valueColor: HomeDashboard.blue,
            ),
            _Metric(
              icon: Icons.percent,
              iconColor: HomeDashboard.blue,
              label: 'Kabul Edilen Fire Oranı',
              value:
                  '%${_num(calc.acceptedRate)} (${_tons(calc.acceptedTons)})',
              valueColor: HomeDashboard.ink,
            ),
            _Metric(
              icon: Icons.functions,
              iconColor: HomeDashboard.blue,
              label: 'Toplam İhtiyaç (Fire Dahil)',
              value: _tons(calc.totalNeed),
              valueColor: HomeDashboard.blue,
            ),
            _Metric(
              icon: Icons.shopping_cart_outlined,
              iconColor: HomeDashboard.blue,
              label: 'Gerçekleşen Tüketim',
              value: _tons(calc.consumption),
              valueColor: over ? DiameterCalcDetailScreen.bad : HomeDashboard.blue,
            ),
            _Metric(
              icon: Icons.warning_amber_rounded,
              iconColor: HomeDashboard.blue,
              label: 'Gerçekleşen Fire',
              value: _tons(calc.actualFire),
              valueColor: tone,
            ),
            _Metric(
              icon: Icons.bar_chart_rounded,
              iconColor: HomeDashboard.blue,
              label: 'Gerçekleşen Fire Oranı',
              value: '%${_num(calc.actualFireRate)}',
              valueColor: tone,
            ),
          ],
        ),
        const SizedBox(height: 12),
        _MetricCard(
          rows: [
            _Metric(
              icon: Icons.inventory_2_outlined,
              iconColor: HomeDashboard.blue,
              label: 'Saha Sayımı (Mevcut)',
              value: _tons(calc.counted),
              valueColor: HomeDashboard.blue,
            ),
            _Metric(
              icon: Icons.local_shipping_outlined,
              iconColor: DiameterCalcDetailScreen.good,
              label: 'Bekleyen Sipariş',
              value: _tons(calc.pendingOrder),
              valueColor: HomeDashboard.blue,
            ),
            _Metric(
              icon: Icons.account_balance_outlined,
              iconColor: HomeDashboard.blue,
              label: 'Kullanılabilir Stok',
              value: _tons(calc.availableStock),
              valueColor: HomeDashboard.blue,
            ),
            _Metric(
              icon: Icons.arrow_upward_rounded,
              iconColor: DiameterCalcDetailScreen.bad,
              iconOnCircle: true,
              label: 'Kalan Net İhtiyaç',
              value: _tons(calc.remainingNeed),
              valueColor: calc.remainingNeed <= 0
                  ? DiameterCalcDetailScreen.good
                  : DiameterCalcDetailScreen.bad,
            ),
          ],
        ),
        if (calc.overAccepted) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F1FE),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info, color: HomeDashboard.blue, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Gerçekleşen fire oranı, kabul edilen fire oranının üzerindedir. '
                    'Fire nedenlerinin kontrol edilmesi önerilir.',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF1D4ED8),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.calc,
    required this.tone,
    required this.status,
    required this.note,
  });

  final DiameterCalc calc;
  final Color tone;
  final String status;
  final String note;

  @override
  Widget build(BuildContext context) {
    final critical = calc.critical;
    return Container(
      decoration: BoxDecoration(
        color: critical ? const Color(0xFFFDECEC) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(color: Color(0x140F2744), blurRadius: 16, offset: Offset(0, 6)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: IntrinsicHeight(
          child: Row(
            children: [
              if (critical)
                const ColoredBox(
                  color: DiameterCalcDetailScreen.bad,
                  child: SizedBox(width: 5),
                ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Ø${calc.diameter}',
                            style: GoogleFonts.inter(
                              color: critical
                                  ? DiameterCalcDetailScreen.bad
                                  : HomeDashboard.diameterDot(calc.diameter),
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              height: 1,
                            ),
                          ),
                          Text(
                            'mm',
                            style: GoogleFonts.inter(
                              color: HomeDashboard.muted,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        width: 1,
                        height: 52,
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        color: const Color(0xFFE6EBF3),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Durum',
                              style: GoogleFonts.inter(
                                color: HomeDashboard.muted,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(color: tone, shape: BoxShape.circle),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  status,
                                  style: GoogleFonts.inter(
                                    color: tone,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              note,
                              style: GoogleFonts.inter(
                                color: const Color(0xFF64748B),
                                fontSize: 12,
                                height: 1.3,
                              ),
                            ),
                          ],
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
}

class _Metric {
  const _Metric({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.valueColor,
    this.iconOnCircle = false,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final Color valueColor;
  final bool iconOnCircle;
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.rows});

  final List<_Metric> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(color: Color(0x120F2744), blurRadius: 12, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const Divider(height: 1, color: Color(0xFFEEF2F7)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  _IconBadge(metric: rows[i]),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      rows[i].label,
                      style: GoogleFonts.inter(
                        color: HomeDashboard.ink,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    rows[i].value,
                    style: GoogleFonts.inter(
                      color: rows[i].valueColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _IconBadge extends StatelessWidget {
  const _IconBadge({required this.metric});

  final _Metric metric;

  @override
  Widget build(BuildContext context) {
    if (metric.iconOnCircle) {
      return Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: metric.iconColor, shape: BoxShape.circle),
        child: Icon(metric.icon, size: 18, color: Colors.white),
      );
    }
    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: metric.iconColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(metric.icon, size: 18, color: metric.iconColor),
    );
  }
}

String _tons(double value) => '${AppFormat.tonnage(value)}';

String _num(double value) => value.toStringAsFixed(1).replaceAll('.', ',');
