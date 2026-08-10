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
import 'package:santijet_ana/domain/models/subcontractor.dart';
import 'package:santijet_ana/features/_shared/entity_form_sheet.dart';

const _statusOpts = <({String value, String label})>[
  (value: 'active', label: 'Aktif'),
  (value: 'completed', label: 'Tamamlandı'),
  (value: 'cancelled', label: 'İptal'),
];

const _statusColor = <String, Color>{
  'active': Color(0xFF16A34A),
  'completed': Color(0xFF0891B2),
  'cancelled': Color(0xFFDC2626),
};

class TaseronScreen extends ConsumerStatefulWidget {
  const TaseronScreen({super.key});

  @override
  ConsumerState<TaseronScreen> createState() => _TaseronScreenState();
}

class _TaseronScreenState extends ConsumerState<TaseronScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _guard());
  }

  void _guard() {
    if (!mounted) return;
    final perm = ref.read(appStateProvider).getPermission('taseron');
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

  Future<void> _open([Subcontractor? s]) async {
    final state = ref.read(appStateProvider);
    final c = ref.read(themeDefinitionProvider).colors;
    final projects = state.projects;
    final nameCtrl = TextEditingController(text: s?.name ?? '');
    final contactCtrl = TextEditingController(text: s?.contactPerson ?? '');
    final phoneCtrl = TextEditingController(text: s?.phone ?? '');
    final emailCtrl = TextEditingController(text: s?.email ?? '');
    final specialtyCtrl = TextEditingController(text: s?.specialty ?? '');
    final amountCtrl = TextEditingController(
      text: s != null && s.contractAmount > 0
          ? s.contractAmount.toStringAsFixed(0)
          : '',
    );
    final notesCtrl = TextEditingController(text: s?.notes ?? '');
    var startDate = s?.startDate ?? '';
    var endDate = s?.endDate ?? '';
    var status = s?.status ?? 'active';
    var projectId =
        s?.projectId ?? (projects.isNotEmpty ? projects.first.id : '');
    final editId = s?.id;

    await showEntityFormSheet(
      context: context,
      title: editId == null ? 'Yeni Taşeron' : 'Taşeronu Düzenle',
      onSave: () {
        final name = nameCtrl.text.trim();
        if (name.isEmpty) return;
        final amount = double.tryParse(
              amountCtrl.text.trim().replaceAll(',', '.'),
            ) ??
            0;
        final notifier = ref.read(appStateProvider.notifier);
        if (editId == null) {
          notifier.addSubcontractor(Subcontractor(
            id: '',
            projectId: projectId,
            name: name,
            contactPerson: contactCtrl.text.trim(),
            phone: phoneCtrl.text.trim(),
            email: emailCtrl.text.trim(),
            specialty: specialtyCtrl.text.trim(),
            contractAmount: amount,
            startDate: startDate,
            endDate: endDate,
            status: status,
            notes: notesCtrl.text.trim(),
          ));
        } else {
          notifier.updateSubcontractor(
            editId,
            (e) => e.copyWith(
              projectId: projectId,
              name: name,
              contactPerson: contactCtrl.text.trim(),
              phone: phoneCtrl.text.trim(),
              email: emailCtrl.text.trim(),
              specialty: specialtyCtrl.text.trim(),
              contractAmount: amount,
              startDate: startDate,
              endDate: endDate,
              status: status,
              notes: notesCtrl.text.trim(),
            ),
          );
        }
        Navigator.pop(context);
      },
      onDelete: editId == null
          ? null
          : () {
              ref.read(appStateProvider.notifier).deleteSubcontractor(editId);
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
                  value: projects.any((p) => p.id == projectId)
                      ? projectId
                      : projects.first.id,
                  items: [
                    for (final p in projects)
                      DropdownMenuItem(value: p.id, child: Text(p.name)),
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
                label: 'Firma Adı',
                controller: nameCtrl,
                hint: 'Taşeron firması',
              ),
              const SizedBox(height: AppSpacing.sm),
              SjFormField(
                label: 'Yetkili',
                controller: contactCtrl,
              ),
              const SizedBox(height: AppSpacing.sm),
              SjFormField(
                label: 'Telefon',
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: AppSpacing.sm),
              SjFormField(
                label: 'E-posta',
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: AppSpacing.sm),
              SjFormField(
                label: 'Uzmanlık',
                controller: specialtyCtrl,
                hint: 'Örn: Kalıp, Demir',
              ),
              const SizedBox(height: AppSpacing.sm),
              SjFormField(
                label: 'Sözleşme Tutarı (₺)',
                controller: amountCtrl,
                keyboardType: TextInputType.number,
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
                label: 'Notlar',
                controller: notesCtrl,
                maxLines: 2,
              ),
            ],
          );
        },
      ),
    );

    nameCtrl.dispose();
    contactCtrl.dispose();
    phoneCtrl.dispose();
    emailCtrl.dispose();
    specialtyCtrl.dispose();
    amountCtrl.dispose();
    notesCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = ref.watch(themeDefinitionProvider).colors;
    final state = ref.watch(appStateProvider);
    final perm = state.getPermission('taseron');
    if (perm == Permission.none) {
      return Scaffold(backgroundColor: c.background);
    }
    final canEdit = perm == Permission.edit;
    final list = state.subcontractors;

    return Scaffold(
      backgroundColor: c.background,
      body: Column(
        children: [
          SjHeader(
            title: 'Taşeronlar',
            onBack: _goBack,
            trailing: canEdit
                ? IconButton(
                    onPressed: () => _open(),
                    icon: const Icon(Icons.add, color: Colors.white),
                  )
                : null,
          ),
          Expanded(
            child: list.isEmpty
                ? const SjEmptyState(
                    title: 'Henüz taşeron yok',
                    message: 'Taşeron eklemek için + düğmesine dokunun',
                    icon: Icons.handshake_outlined,
                  )
                : ListView.separated(
                    padding: EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.md,
                      AppSpacing.md,
                      MediaQuery.paddingOf(context).bottom + AppSpacing.xl,
                    ),
                    itemCount: list.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, i) {
                      final s = list[i];
                      final sc = _statusColor[s.status] ?? c.mutedForeground;
                      final label = _statusOpts
                          .firstWhere(
                            (o) => o.value == s.status,
                            orElse: () => (value: s.status, label: s.status),
                          )
                          .label;
                      return Material(
                        color: c.card,
                        borderRadius: AppRadii.md,
                        child: InkWell(
                          borderRadius: AppRadii.md,
                          onTap: canEdit ? () => _open(s) : null,
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
                                        s.name,
                                        style: AppTypography.headlineMedium
                                            .copyWith(
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
                                if (s.specialty.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    s.specialty,
                                    style: AppTypography.bodySmall
                                        .copyWith(color: c.mutedForeground),
                                  ),
                                ],
                                if (s.contactPerson.isNotEmpty ||
                                    s.phone.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    [
                                      if (s.contactPerson.isNotEmpty)
                                        s.contactPerson,
                                      if (s.phone.isNotEmpty) s.phone,
                                    ].join(' · '),
                                    style: AppTypography.bodySmall
                                        .copyWith(color: c.mutedForeground),
                                  ),
                                ],
                                if (s.contractAmount > 0) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    formatTl(s.contractAmount),
                                    style: AppTypography.bodyMedium.copyWith(
                                      color: c.foreground,
                                      fontWeight: FontWeight.w600,
                                    ),
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
}
