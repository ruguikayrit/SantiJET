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
import 'package:santijet_ana/domain/models/app_user.dart';
import 'package:santijet_ana/domain/models/page_key.dart';
import 'package:santijet_ana/domain/models/role.dart';
import 'package:santijet_ana/features/_shared/entity_form_sheet.dart';

enum _Tab { users, roles }

const _permOpts = <({Permission value, String label, Color color})>[
  (value: Permission.none, label: 'Yok', color: Color(0xFF94A3B8)),
  (value: Permission.view, label: 'Görüntüle', color: Color(0xFF0EA5E9)),
  (value: Permission.edit, label: 'Düzenle', color: Color(0xFF16A34A)),
];

class KullanicilarScreen extends ConsumerStatefulWidget {
  const KullanicilarScreen({super.key});

  @override
  ConsumerState<KullanicilarScreen> createState() => _KullanicilarScreenState();
}

class _KullanicilarScreenState extends ConsumerState<KullanicilarScreen> {
  _Tab _tab = _Tab.users;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _guard());
  }

  void _guard() {
    if (!mounted) return;
    final perm = ref.read(appStateProvider).getPermission('kullanicilar');
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

  Future<void> _openUser([AppUser? u]) async {
    final state = ref.read(appStateProvider);
    final c = ref.read(themeDefinitionProvider).colors;
    final roles = state.roles;
    final nameCtrl = TextEditingController(text: u?.name ?? '');
    final pinCtrl = TextEditingController(text: u?.pin ?? '');
    final professionCtrl = TextEditingController(text: u?.profession ?? '');
    final phoneCtrl = TextEditingController(text: u?.phone ?? '');
    final addressCtrl = TextEditingController(text: u?.address ?? '');
    final companyCtrl = TextEditingController(text: u?.company ?? '');
    final teamCtrl = TextEditingController(text: u?.team ?? '');
    var roleId = u?.roleId ?? (roles.isNotEmpty ? roles.first.id : '');
    final editId = u?.id;

    await showEntityFormSheet(
      context: context,
      title: editId == null ? 'Yeni Kullanıcı' : 'Kullanıcıyı Düzenle',
      onSave: () {
        final name = nameCtrl.text.trim();
        if (name.isEmpty) return;
        final notifier = ref.read(appStateProvider.notifier);
        if (editId == null) {
          notifier.addAppUser(AppUser(
            id: '',
            name: name,
            roleId: roleId,
            pin: pinCtrl.text.trim(),
            profession: professionCtrl.text.trim(),
            phone: phoneCtrl.text.trim(),
            address: addressCtrl.text.trim(),
            company: companyCtrl.text.trim(),
            team: teamCtrl.text.trim().isEmpty ? null : teamCtrl.text.trim(),
          ));
        } else {
          notifier.updateAppUser(
            editId,
            (e) => e.copyWith(
              name: name,
              roleId: roleId,
              pin: pinCtrl.text.trim(),
              profession: professionCtrl.text.trim(),
              phone: phoneCtrl.text.trim(),
              address: addressCtrl.text.trim(),
              company: companyCtrl.text.trim(),
              team: teamCtrl.text.trim(),
            ),
          );
        }
        Navigator.pop(context);
      },
      onDelete: editId == null
          ? null
          : () {
              ref.read(appStateProvider.notifier).deleteAppUser(editId);
              Navigator.pop(context);
            },
      form: StatefulBuilder(
        builder: (ctx, setModal) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SjFormField(
                label: 'Ad Soyad',
                controller: nameCtrl,
                hint: 'Personel adı',
              ),
              const SizedBox(height: AppSpacing.sm),
              if (roles.isNotEmpty) ...[
                Text(
                  'Rol',
                  style:
                      AppTypography.labelMedium.copyWith(color: c.foreground),
                ),
                const SizedBox(height: AppSpacing.xxs),
                DropdownButtonFormField<String>(
                  value: roles.any((r) => r.id == roleId)
                      ? roleId
                      : roles.first.id,
                  items: [
                    for (final r in roles)
                      DropdownMenuItem(value: r.id, child: Text(r.name)),
                  ],
                  onChanged: (v) {
                    if (v != null) setModal(() => roleId = v);
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
                label: 'PIN',
                controller: pinCtrl,
                obscureText: true,
                keyboardType: TextInputType.number,
                hint: '4+ haneli',
              ),
              const SizedBox(height: AppSpacing.sm),
              SjFormField(
                label: 'Meslek',
                controller: professionCtrl,
              ),
              const SizedBox(height: AppSpacing.sm),
              SjFormField(
                label: 'Telefon',
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: AppSpacing.sm),
              SjFormField(
                label: 'Adres',
                controller: addressCtrl,
              ),
              const SizedBox(height: AppSpacing.sm),
              SjFormField(
                label: 'Firma',
                controller: companyCtrl,
              ),
              const SizedBox(height: AppSpacing.sm),
              SjFormField(
                label: 'Ekip',
                controller: teamCtrl,
              ),
            ],
          );
        },
      ),
    );

    nameCtrl.dispose();
    pinCtrl.dispose();
    professionCtrl.dispose();
    phoneCtrl.dispose();
    addressCtrl.dispose();
    companyCtrl.dispose();
    teamCtrl.dispose();
  }

  Future<void> _openRole(Role role) async {
    final c = ref.read(themeDefinitionProvider).colors;
    var perms = Map<String, Permission>.from(role.permissions);

    await showEntityFormSheet(
      context: context,
      title: '${role.name} — İzinler',
      saveLabel: 'İzinleri Kaydet',
      onSave: () {
        ref.read(appStateProvider.notifier).updateRole(
              role.id,
              (r) => r.copyWith(permissions: Map<String, Permission>.from(perms)),
            );
        Navigator.pop(context);
      },
      form: StatefulBuilder(
        builder: (ctx, setModal) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final key in allPageKeys) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pageLabels[key] ?? key,
                        style: AppTypography.labelMedium.copyWith(
                          color: c.foreground,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final o in _permOpts)
                            GestureDetector(
                              onTap: role.isAdmin
                                  ? null
                                  : () => setModal(
                                        () => perms[key] = o.value,
                                      ),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: (perms[key] ?? Permission.none) ==
                                          o.value
                                      ? o.color.withValues(alpha: 0.18)
                                      : c.muted.withValues(alpha: 0.35),
                                  borderRadius: AppRadii.sm,
                                  border: Border.all(
                                    color: (perms[key] ?? Permission.none) ==
                                            o.value
                                        ? o.color
                                        : c.border,
                                  ),
                                ),
                                child: Text(
                                  o.label,
                                  style: TextStyle(
                                    color: (perms[key] ?? Permission.none) ==
                                            o.value
                                        ? o.color
                                        : c.foreground,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'Inter',
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
              if (role.isAdmin)
                Text(
                  'Yönetici rolleri tüm sayfalarda düzenleme hakkına sahiptir.',
                  style: AppTypography.bodySmall.copyWith(
                    color: c.mutedForeground,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = ref.watch(themeDefinitionProvider).colors;
    final state = ref.watch(appStateProvider);
    final perm = state.getPermission('kullanicilar');
    if (perm == Permission.none) {
      return Scaffold(backgroundColor: c.background);
    }
    final canEdit = perm == Permission.edit;
    final users = state.appUsers;
    final roles = state.roles;

    String roleName(String id) {
      for (final r in roles) {
        if (r.id == id) return r.name;
      }
      return id;
    }

    return Scaffold(
      backgroundColor: c.background,
      body: Column(
        children: [
          SjHeader(
            title: 'Kullanıcı Yönetimi',
            onBack: _goBack,
            trailing: _tab == _Tab.users && canEdit
                ? IconButton(
                    onPressed: () => _openUser(),
                    icon: const Icon(Icons.person_add_alt_1, color: Colors.white),
                  )
                : null,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              0,
            ),
            child: Row(
              children: [
                Expanded(
                  child: _tabBtn(
                    c,
                    label: 'Kullanıcılar',
                    selected: _tab == _Tab.users,
                    onTap: () => setState(() => _tab = _Tab.users),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _tabBtn(
                    c,
                    label: 'Roller & İzinler',
                    selected: _tab == _Tab.roles,
                    onTap: () => setState(() => _tab = _Tab.roles),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _tab == _Tab.users
                ? (users.isEmpty
                    ? const SjEmptyState(
                        title: 'Kullanıcı yok',
                        message: 'Personel eklemek için + kullanın',
                        icon: Icons.people_outline,
                      )
                    : ListView.separated(
                        padding: EdgeInsets.fromLTRB(
                          AppSpacing.md,
                          AppSpacing.md,
                          AppSpacing.md,
                          MediaQuery.paddingOf(context).bottom + AppSpacing.xl,
                        ),
                        itemCount: users.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: AppSpacing.sm),
                        itemBuilder: (context, i) {
                          final u = users[i];
                          return Material(
                            color: c.card,
                            borderRadius: AppRadii.md,
                            child: InkWell(
                              borderRadius: AppRadii.md,
                              onTap: canEdit ? () => _openUser(u) : null,
                              child: Container(
                                padding: const EdgeInsets.all(AppSpacing.md),
                                decoration: BoxDecoration(
                                  borderRadius: AppRadii.md,
                                  border: Border.all(
                                    color: c.border.withValues(alpha: 0.6),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundColor:
                                          c.primary.withValues(alpha: 0.15),
                                      child: Text(
                                        u.name.isNotEmpty
                                            ? u.name[0].toUpperCase()
                                            : '?',
                                        style: TextStyle(
                                          color: c.primary,
                                          fontWeight: FontWeight.w700,
                                          fontFamily: 'Inter',
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            u.name,
                                            style: AppTypography.headlineMedium
                                                .copyWith(
                                              color: c.foreground,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 16,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            roleName(u.roleId),
                                            style: AppTypography.bodySmall
                                                .copyWith(color: c.primary),
                                          ),
                                          if (u.profession.isNotEmpty)
                                            Text(
                                              u.profession,
                                              style: AppTypography.bodySmall
                                                  .copyWith(
                                                color: c.mutedForeground,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      Icons.chevron_right,
                                      color: c.mutedForeground,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ))
                : ListView.separated(
                    padding: EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.md,
                      AppSpacing.md,
                      MediaQuery.paddingOf(context).bottom + AppSpacing.xl,
                    ),
                    itemCount: roles.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, i) {
                      final r = roles[i];
                      final editCount = r.permissions.values
                          .where((p) => p == Permission.edit)
                          .length;
                      final viewCount = r.permissions.values
                          .where((p) => p == Permission.view)
                          .length;
                      return Material(
                        color: c.card,
                        borderRadius: AppRadii.md,
                        child: InkWell(
                          borderRadius: AppRadii.md,
                          onTap: canEdit ? () => _openRole(r) : null,
                          child: Container(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            decoration: BoxDecoration(
                              borderRadius: AppRadii.md,
                              border: Border.all(
                                color: c.border.withValues(alpha: 0.6),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              r.name,
                                              style: AppTypography
                                                  .headlineMedium
                                                  .copyWith(
                                                color: c.foreground,
                                                fontWeight: FontWeight.w700,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ),
                                          if (r.isAdmin)
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 3,
                                              ),
                                              decoration: BoxDecoration(
                                                color: c.primary
                                                    .withValues(alpha: 0.15),
                                                borderRadius: AppRadii.sm,
                                              ),
                                              child: Text(
                                                'Admin',
                                                style: TextStyle(
                                                  color: c.primary,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w700,
                                                  fontFamily: 'Inter',
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '$editCount düzenle · $viewCount görüntüle',
                                        style: AppTypography.bodySmall
                                            .copyWith(color: c.mutedForeground),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.tune,
                                  color: c.mutedForeground,
                                  size: 20,
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

  Widget _tabBtn(
    ThemeColors c, {
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: selected ? c.primary : c.card,
      borderRadius: AppRadii.md,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.md,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: AppRadii.md,
            border: Border.all(
              color: selected ? c.primary : c.border,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? c.primaryForeground : c.foreground,
              fontWeight: FontWeight.w600,
              fontFamily: 'Inter',
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}
