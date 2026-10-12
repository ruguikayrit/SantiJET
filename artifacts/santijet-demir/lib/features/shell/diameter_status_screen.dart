import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:santijet_demir/core/format/app_format.dart';
import 'package:santijet_demir/features/field_count/providers/field_count_provider.dart';
import 'package:santijet_demir/features/projects/providers/project_provider.dart';
import 'package:santijet_demir/core/routing/app_routes.dart';
import 'package:santijet_demir/core/widgets/santijet_header.dart';
import 'package:santijet_demir/features/shell/diameter_calc.dart';
import 'package:santijet_demir/features/shell/widgets/home_dashboard.dart';

/// Çap Bazlı Durum — ana sayfadaki Detay.
class DiameterStatusScreen extends ConsumerWidget {
  const DiameterStatusScreen({super.key});

  static const _good = Color(0xFF16A34A);
  static const _warn = Color(0xFFE8A317);
  static const _bad = Color(0xFFEF4444);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final project = ref.watch(activeProjectProvider);
    final rows = ref.watch(reconciliationRowsProvider);
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
          _Header(subtitle: subtitle.isEmpty ? 'İş seçilmedi' : subtitle),
          Expanded(
            child: rows.isEmpty
                ? Center(
                    child: Text(
                      'Keşifte çap satırı yok',
                      style: GoogleFonts.inter(
                        color: HomeDashboard.muted,
                        fontSize: 14,
                      ),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                    children: [
                      const _ColumnTitles(),
                      const SizedBox(height: 8),
                      for (final row in rows) ...[
                        _DiameterRow(calc: DiameterCalc.fromRow(row)),
                        const SizedBox(height: 8),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.subtitle});

  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return DemirBrandHeader(
      title: 'Çap Bazlı Durum',
      caption: subtitle,
      showBack: true,
    );
  }
}

class _ColumnTitles extends StatelessWidget {
  const _ColumnTitles();

  @override
  Widget build(BuildContext context) {
    final style = GoogleFonts.inter(
      color: const Color(0xFF8B97A8),
      fontSize: 11,
      fontWeight: FontWeight.w600,
      height: 1.15,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Expanded(flex: 24, child: Text('Çap (mm)', style: style)),
          Expanded(
            flex: 28,
            child: Text('Net İmalat\nMiktarı (t)', style: style),
          ),
          Expanded(flex: 22, child: Text('Fire Oranı', style: style)),
          Expanded(
            flex: 18,
            child: Text('Durum', textAlign: TextAlign.right, style: style),
          ),
        ],
      ),
    );
  }
}

class _DiameterRow extends StatelessWidget {
  const _DiameterRow({required this.calc});

  final DiameterCalc calc;

  @override
  Widget build(BuildContext context) {
    final fire = calc.actualFireRate;
    final tone = calc.critical
        ? DiameterStatusScreen._bad
        : calc.warning
            ? DiameterStatusScreen._warn
            : DiameterStatusScreen._good;
    final critical = calc.critical;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push(AppRoutes.diameterCalc(calc.diameter)),
        borderRadius: BorderRadius.circular(16),
        child: Container(
      decoration: BoxDecoration(
        color: critical ? const Color(0xFFFDECEC) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x120F2744),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: IntrinsicHeight(
          child: Row(
            children: [
              if (critical)
                const ColoredBox(
                  color: DiameterStatusScreen._bad,
                  child: SizedBox(width: 4),
                ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 24,
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: HomeDashboard.diameterDot(calc.diameter),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                'Ø${calc.diameter}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  color: HomeDashboard.ink,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 28,
                        child: Text(
                          '${AppFormat.tonnage(calc.survey)}',
                          style: GoogleFonts.inter(
                            color: HomeDashboard.blue,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 22,
                        child: Text(
                          _fireLabel(fire),
                          style: GoogleFonts.inter(
                            color: tone,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 18,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(color: tone, shape: BoxShape.circle),
                            ),
                            const Icon(
                              Icons.chevron_right_rounded,
                              size: 20,
                              color: Color(0xFF94A3B8),
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
        ),
      ),
    );
  }

  static String _fireLabel(double value) {
    final fixed = value.toStringAsFixed(1).replaceAll('.', ',');
    return '%$fixed';
  }
}
