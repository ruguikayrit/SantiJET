import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design_system/sj_button.dart';
import '../../core/routing/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/providers/company_provider.dart';

/// Firma bilgileri — Yönetim alt sayfası.
class CompanySettingsScreen extends ConsumerStatefulWidget {
  const CompanySettingsScreen({super.key});

  @override
  ConsumerState<CompanySettingsScreen> createState() =>
      _CompanySettingsScreenState();
}

class _CompanySettingsScreenState extends ConsumerState<CompanySettingsScreen> {
  late final TextEditingController _name;
  late final TextEditingController _tax;
  late final TextEditingController _address;
  late final TextEditingController _email;
  late final TextEditingController _phone;

  @override
  void initState() {
    super.initState();
    final c = ref.read(companyInfoProvider);
    _name = TextEditingController(text: c.name);
    _tax = TextEditingController(text: c.taxNo);
    _address = TextEditingController(text: c.address);
    _email = TextEditingController(text: c.email);
    _phone = TextEditingController(text: c.phone);
  }

  @override
  void dispose() {
    _name.dispose();
    _tax.dispose();
    _address.dispose();
    _email.dispose();
    _phone.dispose();
    super.dispose();
  }

  void _save() {
    ref.read(companyInfoProvider.notifier).update(
          name: _name.text.trim(),
          taxNo: _tax.text.trim(),
          address: _address.text.trim(),
          email: _email.text.trim(),
          phone: _phone.text.trim(),
        );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Firma bilgileri kaydedildi')),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: const Text('Firma Bilgileri'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.yonetim),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          TextField(
            controller: _name,
            decoration: const InputDecoration(
              labelText: 'Firma / Şantiye Adı',
            ),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _tax,
            decoration: const InputDecoration(labelText: 'Vergi No'),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _address,
            decoration: const InputDecoration(labelText: 'Adres'),
            maxLines: 2,
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _email,
            decoration: const InputDecoration(labelText: 'E-posta'),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _phone,
            decoration: const InputDecoration(labelText: 'Telefon'),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: AppSpacing.lg),
          SJButton(
            label: 'Kaydet',
            icon: Icons.check,
            expanded: true,
            onPressed: _save,
          ),
        ],
      ),
    );
  }
}
