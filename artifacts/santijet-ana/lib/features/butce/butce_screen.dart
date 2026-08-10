import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/widgets/sj_empty_state.dart';
import '../../core/widgets/sj_form_field.dart';
import '../../core/widgets/sj_primary_button.dart';
import '../../data/providers/app_state_provider.dart';
import '../../domain/models/page_key.dart';
import '../../domain/models/survey.dart';
import '../common/module_helpers.dart';

class _BudgetRow {
  _BudgetRow({
    required this.surveyId,
    required this.surveyTitle,
    required this.projectId,
    required this.item,
  });

  final String surveyId;
  final String surveyTitle;
  final String projectId;
  final SurveyItem item;
}

/// Yaklaşık Maliyet — keşif kalemlerinin birim fiyatları (ayrı ledger değil).
class ButceScreen extends ConsumerStatefulWidget {
  const ButceScreen({super.key});

  @override
  ConsumerState<ButceScreen> createState() => _ButceScreenState();
}

class _ButceScreenState extends ConsumerState<ButceScreen> {
  String? _projectFilter;
  bool _canEdit = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _canEdit = guardPage(context, ref, 'butce');
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appStateProvider);
    final colors = ref.watch(themeDefinitionProvider).colors;
    final perm = state.getPermission('butce');
    if (perm == Permission.none) return const SizedBox.shrink();
    _canEdit = perm == Permission.edit;

    if (state.projects.isEmpty) {
      return const ModuleScaffold(
        title: 'Yaklaşık Maliyet',
        body: SjEmptyState(
          title: 'Önce proje ekleyin',
          message: 'Yaklaşık maliyet için en az bir proje gerekli.',
          icon: Icons.payments_outlined,
        ),
      );
    }

    final rows = <_BudgetRow>[];
    for (final s in state.surveys) {
      if (_projectFilter != null && s.projectId != _projectFilter) continue;
      for (final it in s.items) {
        rows.add(_BudgetRow(
          surveyId: s.id,
          surveyTitle: s.title,
          projectId: s.projectId,
          item: it,
        ));
      }
    }

    final totalMaliyet = rows.fold<double>(
      0,
      (sum, r) => sum + r.item.quantity * r.item.unitPrice,
    );
    final priced = rows.where((r) => r.item.unitPrice > 0).length;

    return ModuleScaffold(
      title: 'Yaklaşık Maliyet',
      bottom: Column(
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colors.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.border.withValues(alpha: 0.5)),
            ),
            child: Row(
              children: [
                _sumBox('Toplam Kalem', '${rows.length}', colors.foreground),
                _divider(colors),
                _sumBox('Fiyatlanan', '$priced', const Color(0xFF16A34A)),
                _divider(colors),
                Expanded(
                  child: _sumBox(
                    'Yaklaşık Maliyet',
                    fmtMoney(totalMaliyet),
                    colors.primary,
                  ),
                ),
              ],
            ),
          ),
          ProjectFilterBar(
            value: _projectFilter,
            onChanged: (v) => setState(() => _projectFilter = v),
          ),
        ],
      ),
      body: rows.isEmpty
          ? const SjEmptyState(
              title: 'Keşif kalemi yok',
              message: 'Önce Keşif modülünde kalem ekleyin; fiyatlar burada girilir.',
              icon: Icons.account_balance_wallet_outlined,
            )
          : ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 24),
              itemCount: rows.length,
              itemBuilder: (_, i) {
                final r = rows[i];
                final line = r.item.quantity * r.item.unitPrice;
                return EntityCard(
                  title: r.item.description,
                  subtitle:
                      '${projectNameOf(state.projects, r.projectId)} · ${r.surveyTitle}'
                      ' · ${fmtNum(r.item.quantity)} ${r.item.unit}',
                  trailing: Text(
                    fmtMoney(line),
                    style: AppTypography.labelMedium
                        .copyWith(fontWeight: FontWeight.w700),
                  ),
                  onTap: _canEdit ? () => _editPrice(r) : null,
                  extra: Text(
                    'Birim fiyat: ${fmtMoney(r.item.unitPrice)}'
                    '${r.item.pozCode != null && r.item.pozCode!.isNotEmpty ? ' · Poz: ${r.item.pozCode}' : ''}',
                    style: AppTypography.bodySmall,
                  ),
                );
              },
            ),
    );
  }

  Widget _sumBox(String label, String value, Color valueColor) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.titleMedium.copyWith(
              color: valueColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider(dynamic colors) => Container(
        width: 1,
        height: 36,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        color: colors.border,
      );

  Future<void> _editPrice(_BudgetRow row) async {
    final priceCtrl = TextEditingController(
      text: row.item.unitPrice > 0 ? row.item.unitPrice.toString() : '',
    );
    await showFormSheet(
      context: context,
      ref: ref,
      title: 'Birim Fiyat',
      heightFactor: 0.45,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              row.item.description,
              style: AppTypography.titleMedium
                  .copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              '${fmtNum(row.item.quantity)} ${row.item.unit}',
              style: AppTypography.bodySmall,
            ),
            const SizedBox(height: AppSpacing.md),
            SjFormField(
              label: 'Birim fiyat (₺)',
              controller: priceCtrl,
              keyboardType: TextInputType.number,
            ),
            const Spacer(),
            SjPrimaryButton(
              label: 'Kaydet',
              onPressed: () {
                final unitPrice = parseNum(priceCtrl.text);
                ref.read(appStateProvider.notifier).updateSurvey(
                  row.surveyId,
                  (s) => s.copyWith(
                    items: s.items
                        .map(
                          (it) => it.id == row.item.id
                              ? it.copyWith(unitPrice: unitPrice)
                              : it,
                        )
                        .toList(),
                  ),
                );
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
