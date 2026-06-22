import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:santijet_demir/core/theme/app_spacing.dart';
import 'package:santijet_demir/domain/entities/app_settings.dart';
import 'package:santijet_demir/features/settings/providers/settings_provider.dart';

class CompanySettingsScreen extends ConsumerStatefulWidget {
  const CompanySettingsScreen({super.key});

  @override
  ConsumerState<CompanySettingsScreen> createState() =>
      _CompanySettingsScreenState();
}

class _CompanySettingsScreenState extends ConsumerState<CompanySettingsScreen> {
  TextEditingController? _nameCtrl;
  TextEditingController? _taxCtrl;
  TextEditingController? _addressCtrl;
  TextEditingController? _emailCtrl;
  TextEditingController? _phoneCtrl;

  void _ensureControllers(AppSettings settings) {
    _nameCtrl ??= TextEditingController(text: settings.companyName);
    _taxCtrl ??= TextEditingController(text: settings.taxNo);
    _addressCtrl ??= TextEditingController(text: settings.address);
    _emailCtrl ??= TextEditingController(text: settings.contactEmail);
    _phoneCtrl ??= TextEditingController(text: settings.contactPhone);
  }

  @override
  void dispose() {
    _nameCtrl?.dispose();
    _taxCtrl?.dispose();
    _addressCtrl?.dispose();
    _emailCtrl?.dispose();
    _phoneCtrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(appSettingsProvider);
    _ensureControllers(settings);

    return Scaffold(
      appBar: AppBar(title: const Text('Firma Bilgileri')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(labelText: 'Firma / Şantiye Adı'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _taxCtrl,
            decoration: const InputDecoration(labelText: 'Vergi No'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _addressCtrl,
            decoration: const InputDecoration(labelText: 'Adres'),
            maxLines: 2,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _emailCtrl,
            decoration: const InputDecoration(labelText: 'E-posta'),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _phoneCtrl,
            decoration: const InputDecoration(labelText: 'Telefon'),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () async {
              await ref.read(appSettingsProvider.notifier).updateCompany(
                    companyName: _nameCtrl!.text,
                    taxNo: _taxCtrl!.text,
                    address: _addressCtrl!.text,
                    contactEmail: _emailCtrl!.text,
                    contactPhone: _phoneCtrl!.text,
                  );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Firma bilgileri kaydedildi')),
                );
                context.pop();
              }
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }
}
