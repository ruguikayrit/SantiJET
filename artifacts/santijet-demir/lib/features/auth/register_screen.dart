import 'package:flutter/material.dart';
import 'package:santijet_demir/core/widgets/app_toast.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:santijet_demir/core/routing/app_routes.dart';
import 'package:santijet_demir/core/theme/app_colors.dart';
import 'package:santijet_demir/core/theme/app_radii.dart';
import 'package:santijet_demir/core/theme/app_spacing.dart';
import 'package:santijet_demir/core/theme/app_typography.dart';
import 'package:santijet_demir/domain/enums/corporate_role.dart';
import 'package:santijet_demir/domain/enums/membership_type.dart';
import 'package:santijet_demir/features/auth/providers/auth_provider.dart';
import 'package:santijet_demir/features/projects/providers/project_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  MembershipType _membershipType = MembershipType.individual;
  CorporateRole? _corporateRole;
  bool _loading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);

    if (_membershipType == MembershipType.corporate && _corporateRole == null) {
      messenger.showAppSnackBar(
        const SnackBar(content: Text('Kurumsal üyelik için bir rol seçin')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final ok = await ref.read(authProvider.notifier).register(
            email: _emailCtrl.text,
            displayName: _nameCtrl.text,
            password: _passwordCtrl.text,
            membershipType: _membershipType,
            corporateRole: _corporateRole,
          );
      if (!context.mounted) return;

      if (!ok) {
        final error = ref.read(authProvider).error;
        messenger.showAppSnackBar(
          SnackBar(content: Text(error ?? 'Kayıt başarısız')),
        );
        return;
      }

      if (ref.read(authProvider).usesSupabase) {
        try {
          await ref
              .read(projectsControllerProvider)
              .refreshFromCloud()
              .timeout(const Duration(seconds: 15));
        } catch (_) {
          // Kayıt tamam; proje senkronu sonra tekrar denenebilir.
        }
      }

      router.go(AppRoutes.projects);
    } finally {
      if (context.mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(title: const Text('Kayıt Ol')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text(
            'Üyelik tipinizi seçin. Kurumsal hesaplarda rolünüze göre '
            'sayfa ve işlem yetkileri uygulanır.',
            style: AppTypography.bodyMedium,
          ),
          const SizedBox(height: 20),
          Text('Üyelik tipi', style: AppTypography.titleMedium),
          const SizedBox(height: 10),
          Row(
            children: [
              for (final type in MembershipType.values) ...[
                if (type != MembershipType.values.first)
                  const SizedBox(width: 10),
                Expanded(
                  child: _MembershipTypeCard(
                    type: type,
                    selected: _membershipType == type,
                    onTap: () => setState(() {
                      _membershipType = type;
                      if (type == MembershipType.individual) {
                        _corporateRole = null;
                      }
                    }),
                  ),
                ),
              ],
            ],
          ),
          if (_membershipType == MembershipType.corporate) ...[
            const SizedBox(height: 20),
            Text('Kurumsal rol', style: AppTypography.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Rol, görebileceğiniz sayfaları ve onay yetkilerini belirler.',
              style: AppTypography.bodySmall,
            ),
            const SizedBox(height: 10),
            ...CorporateRole.values.map(
              (role) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _CorporateRoleTile(
                  role: role,
                  selected: _corporateRole == role,
                  onTap: () => setState(() => _corporateRole = role),
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(labelText: 'Ad Soyad'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'E-posta'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _passwordCtrl,
            obscureText: true,
            decoration:
                const InputDecoration(labelText: 'Şifre (en az 6 karakter)'),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _loading ? null : _submit,
            child: _loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Kayıt Ol'),
          ),
        ],
      ),
    );
  }
}

class _MembershipTypeCard extends StatelessWidget {
  const _MembershipTypeCard({
    required this.type,
    required this.selected,
    required this.onTap,
  });

  final MembershipType type;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.md,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.electricBlue.withValues(alpha: 0.12)
                : AppColors.surfaceElevated,
            borderRadius: AppRadii.md,
            border: Border.all(
              color: selected ? AppColors.electricBlue : AppColors.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                type.label,
                style: AppTypography.titleMedium.copyWith(
                  color: selected
                      ? AppColors.electricBlueLight
                      : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                type.description,
                style: AppTypography.bodySmall,
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CorporateRoleTile extends StatelessWidget {
  const _CorporateRoleTile({
    required this.role,
    required this.selected,
    required this.onTap,
  });

  final CorporateRole role;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.md,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.electricBlue.withValues(alpha: 0.1)
                : AppColors.surfaceElevated,
            borderRadius: AppRadii.md,
            border: Border.all(
              color: selected ? AppColors.electricBlue : AppColors.border,
            ),
          ),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: selected
                    ? AppColors.electricBlueLight
                    : AppColors.textMuted,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(role.label, style: AppTypography.titleMedium),
                    Text(role.description, style: AppTypography.bodySmall),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
