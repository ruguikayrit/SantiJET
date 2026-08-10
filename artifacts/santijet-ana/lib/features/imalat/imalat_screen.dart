import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:santijet_ana/core/routing/app_routes.dart';
import 'package:santijet_ana/core/theme/app_radii.dart';
import 'package:santijet_ana/core/theme/app_spacing.dart';
import 'package:santijet_ana/core/theme/app_typography.dart';
import 'package:santijet_ana/core/theme/theme_provider.dart';
import 'package:santijet_ana/core/widgets/sj_empty_state.dart';
import 'package:santijet_ana/core/widgets/sj_form_field.dart';
import 'package:santijet_ana/core/widgets/sj_header.dart';
import 'package:santijet_ana/data/providers/app_state_provider.dart';
import 'package:santijet_ana/domain/models/page_key.dart';
import 'package:santijet_ana/domain/models/production.dart';
import 'package:santijet_ana/features/_shared/entity_form_sheet.dart';

class ImalatScreen extends ConsumerStatefulWidget {
  const ImalatScreen({super.key});

  @override
  ConsumerState<ImalatScreen> createState() => _ImalatScreenState();
}

class _ImalatScreenState extends ConsumerState<ImalatScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _guard());
  }

  void _guard() {
    if (!mounted) return;
    final perm = ref.read(appStateProvider).getPermission('imalat');
    if (perm == Permission.none) {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go(AppRoutes.home);
      }
    }
  }

  void _goBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.home);
    }
  }

  double _parse(String s) =>
      double.tryParse(s.trim().replaceAll(',', '.')) ?? 0;

  Future<void> _open([Production? p]) async {
    final state = ref.read(appStateProvider);
    final c = ref.read(themeDefinitionProvider).colors;
    final projects = state.projects;
    final nameCtrl = TextEditingController(text: p?.name ?? '');
    final unitCtrl = TextEditingController(text: p?.unit ?? 'm³');
    final plannedCtrl = TextEditingController(
      text: p != null ? p.plannedQty.toString() : '',
    );
    final completedCtrl = TextEditingController(
      text: p != null ? p.completedQty.toString() : '',
    );
    final priceCtrl = TextEditingController(
      text: p != null && p.unitPrice > 0 ? p.unitPrice.toString() : '',
    );
    final pozCtrl = TextEditingController(text: p?.pozCode ?? '');
    final mixerCtrl = TextEditingController(text: p?.mixerCount ?? '');
    final pumpCtrl = TextEditingController(text: p?.pumpCount ?? '');
    final pumpInfoCtrl = TextEditingController(text: p?.pumpInfo ?? '');
    var date = p?.date ?? todayIso();
    var projectId =
        p?.projectId ?? (projects.isNotEmpty ? projects.first.id : '');
    final editId = p?.id;

    await showEntityFormSheet(
      context: context,
      title: editId == null ? 'Yeni İmalat' : 'İmalatı Düzenle',
      onSave: () {
        final name = nameCtrl.text.trim();
        if (name.isEmpty) return;
        final notifier = ref.read(appStateProvider.notifier);
        if (editId == null) {
          notifier.addProduction(Production(
            id: '',
            projectId: projectId,
            name: name,
            unit: unitCtrl.text.trim().isEmpty ? 'm³' : unitCtrl.text.trim(),
            plannedQty: _parse(plannedCtrl.text),
            completedQty: _parse(completedCtrl.text),
            unitPrice: _parse(priceCtrl.text),
            date: date,
            pozCode: pozCtrl.text.trim().isEmpty ? null : pozCtrl.text.trim(),
            mixerCount:
                mixerCtrl.text.trim().isEmpty ? null : mixerCtrl.text.trim(),
            pumpCount:
                pumpCtrl.text.trim().isEmpty ? null : pumpCtrl.text.trim(),
            pumpInfo:
                pumpInfoCtrl.text.trim().isEmpty ? null : pumpInfoCtrl.text.trim(),
          ));
        } else {
          notifier.updateProduction(
            editId,
            (e) => e.copyWith(
              projectId: projectId,
              name: name,
              unit: unitCtrl.text.trim().isEmpty ? 'm³' : unitCtrl.text.trim(),
              plannedQty: _parse(plannedCtrl.text),
              completedQty: _parse(completedCtrl.text),
              unitPrice: _parse(priceCtrl.text),
              date: date,
              pozCode: pozCtrl.text.trim(),
              mixerCount: mixerCtrl.text.trim(),
              pumpCount: pumpCtrl.text.trim(),
              pumpInfo: pumpInfoCtrl.text.trim(),
            ),
          );
        }
        Navigator.pop(context);
      },
      onDelete: editId == null
          ? null
          : () {
              ref.read(appStateProvider.notifier).deleteProduction(editId);
              Navigator.pop(context);
            },
      form: StatefulBuilder(
        builder: (ctx, setModal) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (projects.isNotEmpty) ...[
                Text(
                  'Proje',
                  style:
                      AppTypography.labelMedium.copyWith(color: c.foreground),
                ),
                const SizedBox(height: AppSpacing.xxs),
                DropdownButtonFormField<String>(
                  value: projects.any((x) => x.id == projectId)
                      ? projectId
                      : projects.first.id,
                  items: [
                    for (final pr in projects)
                      DropdownMenuItem(value: pr.id, child: Text(pr.name)),
                  ],
                  onChanged: (v) {
                    if (v != null) setModal(() => projectId = v);
                  },
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: c.background,
                    border: OutlineInputBorder(
                      borderRadius: AppRadii.md,
                      borderSide: BorderSide(color: c.input),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
              SjFormField(
                label: 'İmalat Adı',
                controller: nameCtrl,
                hint: 'Örn: Temel betonu',
              ),
              const SizedBox(height: AppSpacing.sm),
              SjFormField(label: 'Birim', controller: unitCtrl, hint: 'm³'),
              const SizedBox(height: AppSpacing.sm),
              SjFormField(
                label: 'Planlanan Miktar',
                controller: plannedCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              SjFormField(
                label: 'Tamamlanan Miktar',
                controller: completedCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              SjFormField(
                label: 'Birim Fiyat (₺)',
                controller: priceCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              SjDateField(
                label: 'Tarih',
                value: date,
                onPicked: (v) => setModal(() => date = v),
                foreground: c.foreground,
                mutedForeground: c.mutedForeground,
                card: c.background,
                input: c.input,
                primary: c.primary,
              ),
              const SizedBox(height: AppSpacing.sm),
              SjFormField(
                label: 'Poz Kodu',
                controller: pozCtrl,
                hint: 'Örn: 16.051',
              ),
              const SizedBox(height: AppSpacing.sm),
              SjFormField(
                label: 'Mikser Adedi',
                controller: mixerCtrl,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: AppSpacing.sm),
              SjFormField(
                label: 'Pompa Adedi',
                controller: pumpCtrl,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: AppSpacing.sm),
              SjFormField(
                label: 'Pompa Bilgisi',
                controller: pumpInfoCtrl,
                hint: 'Pompa tipi / plaka',
              ),
            ],
          );
        },
      ),
    );

    nameCtrl.dispose();
    unitCtrl.dispose();
    plannedCtrl.dispose();
    completedCtrl.dispose();
    priceCtrl.dispose();
    pozCtrl.dispose();
    mixerCtrl.dispose();
    pumpCtrl.dispose();
    pumpInfoCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = ref.watch(themeDefinitionProvider).colors;
    final state = ref.watch(appStateProvider);
    final perm = state.getPermission('imalat');
    if (perm == Permission.none) {
      return Scaffold(backgroundColor: c.background);
    }
    final canEdit = perm == Permission.edit;
    final items = state.productions;
    final projects = state.projects;

    String projectName(String id) {
      for (final p in projects) {
        if (p.id == id) return p.name;
      }
      return '';
    }

    return Scaffold(
      backgroundColor: c.background,
      body: Column(
        children: [
          SjHeader(
            title: 'İmalat',
            onBack: _goBack,
            trailing: canEdit
                ? IconButton(
                    onPressed: () => _open(),
                    icon: const Icon(Icons.add, color: Colors.white),
                  )
                : null,
          ),
          Expanded(
            child: items.isEmpty
                ? const SjEmptyState(
                    title: 'Henüz imalat yok',
                    message: 'İmalat kaydı eklemek için + düğmesine dokunun',
                    icon: Icons.construction_outlined,
                  )
                : ListView.separated(
                    padding: EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.md,
                      AppSpacing.md,
                      MediaQuery.paddingOf(context).bottom + AppSpacing.xl,
                    ),
                    itemCount: items.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, i) {
                      final p = items[i];
                      final pct = p.plannedQty <= 0
                          ? 0.0
                          : (p.completedQty / p.plannedQty).clamp(0.0, 1.0);
                      return Material(
                        color: c.card,
                        borderRadius: AppRadii.md,
                        child: InkWell(
                          borderRadius: AppRadii.md,
                          onTap: canEdit ? () => _open(p) : null,
                          child: Container(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            decoration: BoxDecoration(
                              borderRadius: AppRadii.md,
                              border: Border.all(
                                color: c.border.withValues(alpha: 0.6),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        p.name,
                                        style: AppTypography.headlineMedium
                                            .copyWith(
                                          color: c.foreground,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    if (p.pozCode != null &&
                                        p.pozCode!.isNotEmpty)
                                      Text(
                                        p.pozCode!,
                                        style: AppTypography.bodySmall
                                            .copyWith(color: c.primary),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${p.completedQty} / ${p.plannedQty} ${p.unit}',
                                  style: AppTypography.bodyMedium
                                      .copyWith(color: c.foreground),
                                ),
                                const SizedBox(height: 6),
                                ClipRRect(
                                  borderRadius: AppRadii.sm,
                                  child: LinearProgressIndicator(
                                    value: pct,
                                    minHeight: 6,
                                    backgroundColor:
                                        c.muted.withValues(alpha: 0.5),
                                    color: c.primary,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  [
                                    if (p.date.isNotEmpty) displayDate(p.date),
                                    if (p.unitPrice > 0) formatTl(p.unitPrice),
                                    if (projectName(p.projectId).isNotEmpty)
                                      projectName(p.projectId),
                                  ].join(' · '),
                                  style: AppTypography.bodySmall
                                      .copyWith(color: c.mutedForeground),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
