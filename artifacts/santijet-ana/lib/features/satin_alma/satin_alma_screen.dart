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
import '../../domain/models/purchase.dart';
import '../common/module_helpers.dart';

const _statusLabels = {
  'pending': ('Beklemede', Color(0xFFF59E0B)),
  'approved': ('Onaylandı', Color(0xFF16A34A)),
  'paid': ('Ödendi', Color(0xFF2563EB)),
  'cancelled': ('İptal', Color(0xFFDC2626)),
};

const _paymentLabels = {
  'nakit': 'Nakit',
  'havale': 'Havale',
  'kredi-karti': 'Kredi Kartı',
  'cek': 'Çek',
  'vadeli': 'Vadeli',
};

class SatinAlmaScreen extends ConsumerStatefulWidget {
  const SatinAlmaScreen({super.key});

  @override
  ConsumerState<SatinAlmaScreen> createState() => _SatinAlmaScreenState();
}

class _SatinAlmaScreenState extends ConsumerState<SatinAlmaScreen> {
  String? _projectFilter;
  bool _canEdit = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _canEdit = guardPage(context, ref, 'satin-alma');
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appStateProvider);
    final colors = ref.watch(themeDefinitionProvider).colors;
    final perm = state.getPermission('satin-alma');
    if (perm == Permission.none) return const SizedBox.shrink();
    _canEdit = perm == Permission.edit;

    if (state.projects.isEmpty) {
      return const ModuleScaffold(
        title: 'Satın Alma',
        body: SjEmptyState(
          title: 'Önce proje ekleyin',
          message: 'Satın alma için en az bir proje gerekli.',
          icon: Icons.shopping_cart_outlined,
        ),
      );
    }

    final items = state.purchases
        .where((p) => _projectFilter == null || p.projectId == _projectFilter)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    return ModuleScaffold(
      title: 'Satın Alma',
      floatingActionButton: _canEdit
          ? FloatingActionButton(
              onPressed: () => _edit(null),
              backgroundColor: colors.primary,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
      bottom: ProjectFilterBar(
        value: _projectFilter,
        onChanged: (v) => setState(() => _projectFilter = v),
      ),
      body: items.isEmpty
          ? const SjEmptyState(
              title: 'Satın alma yok',
              message: 'Yeni satın alma kaydı ekleyin.',
              icon: Icons.shopping_bag_outlined,
            )
          : ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 88),
              itemCount: items.length,
              itemBuilder: (_, i) {
                final p = items[i];
                final st = _statusLabels[p.status] ?? _statusLabels['pending']!;
                final net = p.quantity * p.unitPrice;
                final total = net * (1 + p.vatRate / 100);
                return EntityCard(
                  title: p.itemName,
                  subtitle:
                      '${projectNameOf(state.projects, p.projectId)} · ${p.supplier} · ${p.date}',
                  trailing: StatusPill(label: st.$1, color: st.$2),
                  onTap: _canEdit ? () => _edit(p) : null,
                  onDelete: _canEdit
                      ? () async {
                          if (await confirmDelete(context, 'Kaydı sil')) {
                            ref
                                .read(appStateProvider.notifier)
                                .deletePurchase(p.id);
                          }
                        }
                      : null,
                  extra: Text(
                    '${fmtNum(p.quantity)} ${p.unit} · KDV %${fmtNum(p.vatRate, maxFrac: 0)}'
                    ' · ${_paymentLabels[p.paymentMethod] ?? p.paymentMethod}'
                    ' · ${fmtMoney(total)}'
                    '${p.invoiceNo.isNotEmpty ? ' · Fatura: ${p.invoiceNo}' : ''}'
                    '${p.invoiceReceived ? ' · Fatura alındı' : ''}',
                    style: AppTypography.bodySmall,
                  ),
                );
              },
            ),
    );
  }

  Future<void> _edit(Purchase? existing) async {
    final state = ref.read(appStateProvider);
    var projectId =
        existing?.projectId ?? _projectFilter ?? state.projects.first.id;
    final dateCtrl =
        TextEditingController(text: existing?.date ?? todayIso());
    final supplierCtrl =
        TextEditingController(text: existing?.supplier ?? '');
    final itemCtrl = TextEditingController(text: existing?.itemName ?? '');
    final catCtrl = TextEditingController(text: existing?.category ?? '');
    final unitCtrl = TextEditingController(text: existing?.unit ?? 'adet');
    final qtyCtrl =
        TextEditingController(text: existing?.quantity.toString() ?? '');
    final priceCtrl =
        TextEditingController(text: existing?.unitPrice.toString() ?? '');
    final vatCtrl =
        TextEditingController(text: existing?.vatRate.toString() ?? '20');
    final paidCtrl =
        TextEditingController(text: existing?.paidDate ?? '');
    final invCtrl =
        TextEditingController(text: existing?.invoiceNo ?? '');
    final notesCtrl = TextEditingController(text: existing?.notes ?? '');
    final payNoteCtrl =
        TextEditingController(text: existing?.paymentNote ?? '');
    var status = existing?.status ?? 'pending';
    var payment = existing?.paymentMethod ?? 'nakit';
    var invoiceReceived = existing?.invoiceReceived ?? false;

    await showFormSheet(
      context: context,
      ref: ref,
      title: existing == null ? 'Satın Alma' : 'Satın Alma Düzenle',
      child: StatefulBuilder(
        builder: (ctx, setLocal) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            children: [
              SjDropdownField<String>(
                label: 'Proje',
                value: projectId,
                items: state.projects
                    .map((p) => DropdownMenuItem(
                          value: p.id,
                          child: Text(p.name),
                        ))
                    .toList(),
                onChanged: (v) => setLocal(() => projectId = v!),
              ),
              const SizedBox(height: AppSpacing.sm),
              SjFormField(label: 'Tarih', controller: dateCtrl),
              const SizedBox(height: AppSpacing.sm),
              SjFormField(label: 'Tedarikçi', controller: supplierCtrl),
              const SizedBox(height: AppSpacing.sm),
              SjFormField(label: 'Kalem', controller: itemCtrl),
              const SizedBox(height: AppSpacing.sm),
              SjFormField(label: 'Kategori', controller: catCtrl),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: SjFormField(label: 'Birim', controller: unitCtrl),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SjFormField(
                      label: 'Miktar',
                      controller: qtyCtrl,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: SjFormField(
                      label: 'Birim fiyat',
                      controller: priceCtrl,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SjFormField(
                      label: 'KDV %',
                      controller: vatCtrl,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              SjDropdownField<String>(
                label: 'Ödeme yöntemi',
                value: payment,
                items: _paymentLabels.entries
                    .map((e) => DropdownMenuItem(
                          value: e.key,
                          child: Text(e.value),
                        ))
                    .toList(),
                onChanged: (v) => setLocal(() => payment = v!),
              ),
              const SizedBox(height: AppSpacing.sm),
              SjDropdownField<String>(
                label: 'Durum',
                value: status,
                items: _statusLabels.entries
                    .map((e) => DropdownMenuItem(
                          value: e.key,
                          child: Text(e.value.$1),
                        ))
                    .toList(),
                onChanged: (v) => setLocal(() => status = v!),
              ),
              const SizedBox(height: AppSpacing.sm),
              SjFormField(label: 'Ödeme tarihi', controller: paidCtrl),
              const SizedBox(height: AppSpacing.sm),
              SjFormField(label: 'Fatura no', controller: invCtrl),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Fatura alındı'),
                value: invoiceReceived,
                onChanged: (v) => setLocal(() => invoiceReceived = v),
              ),
              SjFormField(
                label: 'Ödeme notu',
                controller: payNoteCtrl,
              ),
              const SizedBox(height: AppSpacing.sm),
              SjFormField(label: 'Notlar', controller: notesCtrl, maxLines: 2),
              const SizedBox(height: AppSpacing.md),
              SjPrimaryButton(
                label: 'Kaydet',
                onPressed: () {
                  if (itemCtrl.text.trim().isEmpty) return;
                  final model = Purchase(
                    id: existing?.id ?? '',
                    projectId: projectId,
                    date: dateCtrl.text.trim().isEmpty
                        ? todayIso()
                        : dateCtrl.text.trim(),
                    supplier: supplierCtrl.text.trim(),
                    itemName: itemCtrl.text.trim(),
                    category: catCtrl.text.trim(),
                    unit: unitCtrl.text.trim().isEmpty
                        ? 'adet'
                        : unitCtrl.text.trim(),
                    quantity: parseNum(qtyCtrl.text),
                    unitPrice: parseNum(priceCtrl.text),
                    vatRate: parseNum(vatCtrl.text),
                    status: status,
                    paymentMethod: payment,
                    paidDate: paidCtrl.text.trim(),
                    invoiceNo: invCtrl.text.trim(),
                    notes: notesCtrl.text.trim(),
                    invoiceReceived: invoiceReceived,
                    paymentNote: payNoteCtrl.text.trim(),
                    invoicePhoto: existing?.invoicePhoto,
                    materialRequestId: existing?.materialRequestId,
                    materialId: existing?.materialId,
                  );
                  final n = ref.read(appStateProvider.notifier);
                  if (existing == null) {
                    n.addPurchase(model);
                  } else {
                    n.updatePurchase(existing.id, (_) => model);
                  }
                  Navigator.pop(ctx);
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
