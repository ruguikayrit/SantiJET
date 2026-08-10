import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_typography.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/widgets/sj_empty_state.dart';
import '../../data/providers/app_state_provider.dart';
import '../../domain/models/page_key.dart';
import '../common/module_helpers.dart';

class _ProgressRow {
  _ProgressRow({
    required this.key,
    required this.description,
    required this.unit,
    required this.planned,
    required this.actual,
    required this.unitPrice,
  });

  final String key;
  final String description;
  final String unit;
  double planned;
  double actual;
  final double unitPrice;
}

Color _pctColor(double p) {
  if (p >= 80) return const Color(0xFF16A34A);
  if (p >= 50) return const Color(0xFFD97706);
  if (p > 0) return const Color(0xFFDC2626);
  return const Color(0xFF94A3B8);
}

/// Planlanan (keşif) vs gerçekleşen (malzeme / imalat) ilerleme görünümü.
class IlerlemeScreen extends ConsumerStatefulWidget {
  const IlerlemeScreen({super.key});

  @override
  ConsumerState<IlerlemeScreen> createState() => _IlerlemeScreenState();
}

class _IlerlemeScreenState extends ConsumerState<IlerlemeScreen> {
  String? _projectFilter;
  String _tab = 'malzeme';
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      guardPage(context, ref, 'ilerleme');
      final projects = ref.read(appStateProvider).projects;
      if (projects.isNotEmpty && _projectFilter == null) {
        setState(() => _projectFilter = projects.first.id);
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appStateProvider);
    final colors = ref.watch(themeDefinitionProvider).colors;
    final perm = state.getPermission('ilerleme');
    if (perm == Permission.none) return const SizedBox.shrink();

    if (state.projects.isEmpty) {
      return const ModuleScaffold(
        title: 'İlerleme',
        body: SjEmptyState(
          title: 'Önce proje ekleyin',
          message: 'İlerlemeyi izlemek için en az bir proje gerekli.',
          icon: Icons.trending_up,
        ),
      );
    }

    final projectId = _projectFilter ?? state.projects.first.id;
    final materialNames = {
      for (final m in state.materialList) m.name.trim().toLowerCase(),
    };

    final surveyItems = state.surveys
        .where((s) => s.projectId == projectId)
        .expand((s) => s.items);

    final projectMaterials =
        state.materials.where((m) => m.projectId == projectId);
    final projectProductions =
        state.productions.where((p) => p.projectId == projectId);

    final malzemeMap = <String, _ProgressRow>{};
    final iscilikMap = <String, _ProgressRow>{};

    for (final it in surveyItems) {
      final desc = it.description.trim();
      if (desc.isEmpty) continue;
      final key = desc.toLowerCase();
      final isMalzeme = it.itemType == 'malzeme' ||
          (it.itemType == null && materialNames.contains(key));
      final map = isMalzeme ? malzemeMap : iscilikMap;
      final cur = map[key];
      if (cur != null) {
        cur.planned += it.quantity;
      } else {
        map[key] = _ProgressRow(
          key: key,
          description: desc,
          unit: it.unit,
          planned: it.quantity,
          actual: 0,
          unitPrice: it.unitPrice,
        );
      }
    }

    for (final m in projectMaterials) {
      final key = m.name.trim().toLowerCase();
      final cur = malzemeMap[key];
      if (cur != null) cur.actual += m.quantity;
    }
    for (final p in projectProductions) {
      final key = p.name.trim().toLowerCase();
      final cur = iscilikMap[key];
      if (cur != null) cur.actual += p.completedQty;
    }

    var rows = (_tab == 'malzeme' ? malzemeMap : iscilikMap).values.toList()
      ..sort((a, b) => a.description.compareTo(b.description));

    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isNotEmpty) {
      rows = rows
          .where((r) =>
              r.description.toLowerCase().contains(q) ||
              r.unit.toLowerCase().contains(q))
          .toList();
    }

    var plannedValue = 0.0;
    var actualValue = 0.0;
    var completed = 0;
    for (final r in rows) {
      plannedValue += r.planned * r.unitPrice;
      actualValue +=
          (r.actual < r.planned ? r.actual : r.planned) * r.unitPrice;
      if (r.planned > 0 && r.actual >= r.planned) completed++;
    }
    final valuePct =
        plannedValue > 0 ? ((actualValue / plannedValue) * 100).round() : 0;

    return ModuleScaffold(
      title: 'İlerleme',
      bottom: Column(
        children: [
          ProjectFilterBar(
            value: projectId,
            allowAll: false,
            onChanged: (v) => setState(() => _projectFilter = v),
          ),
          Container(
            color: colors.card,
            child: Row(
              children: [
                for (final t in [
                  ('malzeme', 'Malzeme'),
                  ('iscilik', 'İşçilik / İmalat'),
                ])
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _tab = t.$1),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: _tab == t.$1
                                  ? colors.primary
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                        ),
                        child: Text(
                          t.$2,
                          textAlign: TextAlign.center,
                          style: AppTypography.labelMedium.copyWith(
                            color: _tab == t.$1
                                ? colors.primary
                                : colors.mutedForeground,
                            fontWeight: _tab == t.$1
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Ara…',
                prefixIcon: const Icon(Icons.search, size: 20),
                filled: true,
                fillColor: colors.card,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: colors.border),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.fromLTRB(16, 6, 16, 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.card,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Değer ilerleme: %$valuePct',
                        style: AppTypography.labelLarge
                            .copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    Text(
                      '$completed / ${rows.length} tamam',
                      style: AppTypography.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (valuePct / 100).clamp(0, 1),
                    minHeight: 10,
                    backgroundColor: colors.muted,
                    color: _pctColor(valuePct.toDouble()),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Plan: ${fmtMoney(plannedValue)} · Gerçek: ${fmtMoney(actualValue)}',
                  style: AppTypography.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
      body: rows.isEmpty
          ? const SjEmptyState(
              title: 'Veri yok',
              message: 'Bu proje için keşif kalemi bulunamadı.',
              icon: Icons.bar_chart_outlined,
            )
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: 24),
              itemCount: rows.length,
              itemBuilder: (_, i) {
                final r = rows[i];
                final pct = r.planned > 0
                    ? ((r.actual / r.planned) * 100).clamp(0, 999)
                    : 0.0;
                final color = _pctColor(pct.toDouble());
                return EntityCard(
                  title: r.description,
                  subtitle: '${fmtNum(r.actual)} / ${fmtNum(r.planned)} ${r.unit}',
                  trailing: Text(
                    '%${pct.round()}',
                    style: AppTypography.labelLarge.copyWith(
                      color: color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  extra: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (pct / 100).clamp(0.0, 1.0),
                      minHeight: 8,
                      backgroundColor: colors.muted,
                      color: color,
                    ),
                  ),
                );
              },
            ),
    );
  }
}
