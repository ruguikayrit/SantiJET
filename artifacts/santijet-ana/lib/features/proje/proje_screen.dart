import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:santijet_ana/core/routing/app_routes.dart';
import 'package:santijet_ana/core/theme/app_radii.dart';
import 'package:santijet_ana/core/theme/app_spacing.dart';
import 'package:santijet_ana/core/theme/app_typography.dart';
import 'package:santijet_ana/core/theme/theme_colors.dart';
import 'package:santijet_ana/core/theme/theme_provider.dart';
import 'package:santijet_ana/core/widgets/sj_empty_state.dart';
import 'package:santijet_ana/core/widgets/sj_form_field.dart';
import 'package:santijet_ana/core/widgets/sj_header.dart';
import 'package:santijet_ana/data/providers/app_state_provider.dart';
import 'package:santijet_ana/domain/models/page_key.dart';
import 'package:santijet_ana/domain/models/project.dart';
import 'package:santijet_ana/features/_shared/entity_form_sheet.dart';

const _statusOpts = <({String value, String label})>[
  (value: 'active', label: 'Aktif'),
  (value: 'paused', label: 'Duraklatıldı'),
  (value: 'completed', label: 'Tamamlandı'),
];

const _statusColor = <String, Color>{
  'active': Color(0xFF16A34A),
  'paused': Color(0xFFD97706),
  'completed': Color(0xFF0891B2),
};

class ProjeScreen extends ConsumerStatefulWidget {
  const ProjeScreen({super.key});

  @override
  ConsumerState<ProjeScreen> createState() => _ProjeScreenState();
}

class _ProjeScreenState extends ConsumerState<ProjeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _guard());
  }

  void _guard() {
    if (!mounted) return;
    final perm = ref.read(appStateProvider).getPermission('proje');
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

  Future<void> _open([Project? p]) async {
    final c = ref.read(themeDefinitionProvider).colors;
    final nameCtrl = TextEditingController(text: p?.name ?? '');
    final locCtrl = TextEditingController(text: p?.location ?? '');
    final contractorCtrl = TextEditingController(text: p?.contractor ?? '');
    final budgetCtrl = TextEditingController(
      text: p != null && p.budget > 0 ? p.budget.toStringAsFixed(0) : '',
    );
    final descCtrl = TextEditingController(text: p?.description ?? '');
    var startDate = p?.startDate ?? '';
    var endDate = p?.endDate ?? '';
    var status = p?.status ?? 'active';
    final editId = p?.id;

    await showEntityFormSheet(
      context: context,
      title: editId == null ? 'Yeni Proje' : 'Projeyi Düzenle',
      onSave: () {
        final name = nameCtrl.text.trim();
        if (name.isEmpty) return;
        final notifier = ref.read(appStateProvider.notifier);
        final budget = double.tryParse(
              budgetCtrl.text.trim().replaceAll(',', '.'),
            ) ??
            0;
        if (editId == null) {
          notifier.addProject(Project(
            id: '',
            name: name,
            location: locCtrl.text.trim(),
            contractor: contractorCtrl.text.trim(),
            startDate: startDate,
            endDate: endDate,
            budget: budget,
            status: status,
            description: descCtrl.text.trim(),
          ));
        } else {
          notifier.updateProject(
            editId,
            (e) => e.copyWith(
              name: name,
              location: locCtrl.text.trim(),
              contractor: contractorCtrl.text.trim(),
              startDate: startDate,
              endDate: endDate,
              budget: budget,
              status: status,
              description: descCtrl.text.trim(),
            ),
          );
        }
        Navigator.pop(context);
      },
      onDelete: editId == null
          ? null
          : () {
              ref.read(appStateProvider.notifier).deleteProject(editId);
              Navigator.pop(context);
            },
      form: StatefulBuilder(
        builder: (ctx, setModal) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SjFormField(
                label: 'Proje Adı',
                controller: nameCtrl,
                hint: 'Örn: Çankaya Konutları',
              ),
              const SizedBox(height: AppSpacing.sm),
              SjFormField(
                label: 'Konum',
                controller: locCtrl,
                hint: 'Örn: Ankara / Çankaya',
              ),
              const SizedBox(height: AppSpacing.sm),
              SjFormField(
                label: 'Yüklenici',
                controller: contractorCtrl,
                hint: 'Firma adı',
              ),
              const SizedBox(height: AppSpacing.sm),
              SjDateField(
                label: 'Başlangıç',
                value: startDate,
                onPicked: (v) => setModal(() => startDate = v),
                foreground: c.foreground,
                mutedForeground: c.mutedForeground,
                card: c.background,
                input: c.input,
                primary: c.primary,
              ),
              const SizedBox(height: AppSpacing.sm),
              SjDateField(
                label: 'Bitiş',
                value: endDate,
                onPicked: (v) => setModal(() => endDate = v),
                foreground: c.foreground,
                mutedForeground: c.mutedForeground,
                card: c.background,
                input: c.input,
                primary: c.primary,
              ),
              const SizedBox(height: AppSpacing.sm),
              SjFormField(
                label: 'Bütçe (₺)',
                controller: budgetCtrl,
                keyboardType: TextInputType.number,
                hint: '0',
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Durum',
                style: AppTypography.labelMedium.copyWith(color: c.foreground),
              ),
              const SizedBox(height: AppSpacing.xxs),
              SjOptionChips(
                options: _statusOpts,
                value: status,
                onChanged: (v) => setModal(() => status = v),
                foreground: c.foreground,
                muted: c.muted,
                primary: c.primary,
                border: c.border,
              ),
              const SizedBox(height: AppSpacing.sm),
              SjFormField(
                label: 'Açıklama',
                controller: descCtrl,
                maxLines: 3,
                hint: 'Proje notları',
              ),
            ],
          );
        },
      ),
    );

    nameCtrl.dispose();
    locCtrl.dispose();
    contractorCtrl.dispose();
    budgetCtrl.dispose();
    descCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = ref.watch(themeDefinitionProvider).colors;
    final state = ref.watch(appStateProvider);
    final perm = state.getPermission('proje');
    if (perm == Permission.none) {
      return Scaffold(backgroundColor: c.background);
    }
    final canEdit = perm == Permission.edit;
    final projects = state.projects;

    return Scaffold(
      backgroundColor: c.background,
      body: Column(
        children: [
          SjHeader(
            title: 'Projeler',
            onBack: _goBack,
            trailing: canEdit
                ? IconButton(
                    onPressed: () => _open(),
                    icon: const Icon(Icons.add, color: Colors.white),
                  )
                : null,
          ),
          Expanded(
            child: projects.isEmpty
                ? const SjEmptyState(
                    title: 'Henüz proje yok',
                    message: 'İlk projenizi oluşturmak için + düğmesine dokunun',
                    icon: Icons.work_outline,
                  )
                : ListView.separated(
                    padding: EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.md,
                      AppSpacing.md,
                      MediaQuery.paddingOf(context).bottom + AppSpacing.xl,
                    ),
                    itemCount: projects.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, i) {
                      final p = projects[i];
                      final sc = _statusColor[p.status] ?? c.mutedForeground;
                      final label = _statusOpts
                          .firstWhere(
                            (o) => o.value == p.status,
                            orElse: () => (value: p.status, label: p.status),
                          )
                          .label;
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
                                        style:
                                            AppTypography.headlineMedium.copyWith(
                                          color: c.foreground,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: sc.withValues(alpha: 0.13),
                                        borderRadius: AppRadii.sm,
                                      ),
                                      child: Text(
                                        label,
                                        style: TextStyle(
                                          color: sc,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          fontFamily: 'Inter',
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (p.location.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  _meta(c, Icons.place_outlined, p.location),
                                ],
                                if (p.contractor.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  _meta(
                                    c,
                                    Icons.business_outlined,
                                    p.contractor,
                                  ),
                                ],
                                if (p.budget > 0) ...[
                                  const SizedBox(height: 4),
                                  _meta(
                                    c,
                                    Icons.payments_outlined,
                                    formatTl(p.budget),
                                  ),
                                ],
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

  Widget _meta(ThemeColors c, IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: c.mutedForeground),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: AppTypography.bodySmall.copyWith(color: c.mutedForeground),
          ),
        ),
      ],
    );
  }
}
