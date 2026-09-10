import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../data/hareketler_store.dart';
import '../../data/import_draft_provider.dart';
import '../../data/settings_store.dart';
import '../../domain/kasa_hareket.dart';
import '../../domain/kasa_lookups.dart';
import '../../domain/kasa_rules.dart';
import '../../domain/money_format.dart';

/// Hareket ekle / düzenle — şantiye ana sayfadaki aktif seçimden gelir.
class HareketFormScreen extends ConsumerStatefulWidget {
  const HareketFormScreen({this.hareketId, super.key});

  final String? hareketId;

  @override
  ConsumerState<HareketFormScreen> createState() => _HareketFormScreenState();
}

class _HareketFormScreenState extends ConsumerState<HareketFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late DateTime _tarih;
  late final TextEditingController _tedarikci;
  late final TextEditingController _aciklama;
  late final TextEditingController _gelir;
  late final TextEditingController _gider;
  late final TextEditingController _ek;
  String _odemeSekli = OdemeSekli.sahsiKart;
  String _belgeTuru = BelgeTuru.fis;
  String _santiye = '';
  String? _existingId;
  DateTime? _createdAt;
  String? _error;

  bool get _isEdit => _existingId != null;

  @override
  void initState() {
    super.initState();
    _tarih = DateTime.now();
    _tedarikci = TextEditingController();
    _aciklama = TextEditingController();
    _gelir = TextEditingController();
    _gider = TextEditingController();
    _ek = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _santiye = ref.read(activeSantiyeProvider);
      final draft = ref.read(belgeImportDraftProvider.notifier).take();
      if (draft != null && widget.hareketId == null) {
        _aciklama.text = draft.aciklama;
        _ek.text = draft.ekAciklama;
        _belgeTuru = draft.belgeTuru;
        if (mounted) setState(() {});
        return;
      }
      final id = widget.hareketId;
      if (id != null) {
        final list = ref.read(hareketlerProvider);
        KasaHareket? found;
        for (final h in list) {
          if (h.id == id) {
            found = h;
            break;
          }
        }
        if (found != null) {
          _existingId = found.id;
          _createdAt = found.createdAt;
          _tarih = found.tarih;
          _tedarikci.text = found.tedarikci;
          _aciklama.text = found.aciklama;
          _gelir.text = found.gelir != null
              ? found.gelir!.toStringAsFixed(2).replaceAll('.', ',')
              : '';
          _gider.text = found.gider != null
              ? found.gider!.toStringAsFixed(2).replaceAll('.', ',')
              : '';
          _odemeSekli =
              found.odemeSekli.isNotEmpty ? found.odemeSekli : _odemeSekli;
          _belgeTuru =
              found.belgeTuru.isNotEmpty ? found.belgeTuru : _belgeTuru;
          _santiye = found.santiye.isNotEmpty ? found.santiye : _santiye;
          _ek.text = found.ekAciklama;
        }
      }
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tedarikci.dispose();
    _aciklama.dispose();
    _gelir.dispose();
    _gider.dispose();
    _ek.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _tarih,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) setState(() => _tarih = picked);
  }

  Future<void> _save() async {
    final gelir = MoneyFormat.tryParse(_gelir.text);
    final gider = MoneyFormat.tryParse(_gider.text);
    final err = validateHareket(
      aciklama: _aciklama.text,
      gelir: gelir,
      gider: gider,
    );
    if (err != null) {
      setState(() => _error = err);
      return;
    }

    final santiye = _isEdit
        ? _santiye
        : ref.read(activeSantiyeProvider);

    final now = DateTime.now();
    final hareket = KasaHareket(
      id: _existingId ?? const Uuid().v4(),
      tarih: _tarih,
      tedarikci: _tedarikci.text.trim(),
      aciklama: _aciklama.text.trim(),
      gelir: (gelir != null && gelir > 0) ? gelir : null,
      gider: (gider != null && gider > 0) ? gider : null,
      odemeSekli: _odemeSekli,
      belgeTuru: _belgeTuru,
      santiye: santiye,
      ekAciklama: _ek.text.trim(),
      createdAt: _createdAt ?? now,
      updatedAt: now,
    );

    await ref.read(hareketlerProvider.notifier).upsert(hareket);
    if (!mounted) return;
    context.pop();
  }

  Future<void> _delete() async {
    if (_existingId == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        title: Text('Hareketi sil', style: TextStyle(color: AppColors.textPrimary)),
        content: Text(
          'Bu hareket kalıcı olarak silinir.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Vazgeç'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(hareketlerProvider.notifier).remove(_existingId!);
      if (!mounted) return;
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeSantiye = ref.watch(activeSantiyeProvider);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        title: Text(
          _isEdit ? 'Hareketi Düzenle' : 'Hareket Ekle',
          style: AppTypography.headlineMedium.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          if (_isEdit)
            IconButton(
              onPressed: _delete,
              icon: Icon(Icons.delete_outline, color: AppColors.critical),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
          children: [
            if (_error != null) ...[
              Text(
                _error!,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.critical,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            if (!_isEdit)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Row(
                  children: [
                    Icon(
                      Icons.apartment,
                      size: 18,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Şantiye: $activeSantiye (ana sayfadan değiştirilir)',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('Tarih', style: AppTypography.labelMedium),
              subtitle: Text(
                DateFormat('dd.MM.yyyy').format(_tarih),
                style: AppTypography.titleMedium.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              trailing: const Icon(Icons.calendar_today_outlined),
              onTap: _pickDate,
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _tedarikci,
              decoration: const InputDecoration(labelText: 'Tedarikçi'),
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _aciklama,
              decoration: const InputDecoration(labelText: 'Açıklama *'),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _gelir,
                    decoration: const InputDecoration(
                      labelText: 'Gelir (₺)',
                      hintText: '0,00',
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                    ],
                    onChanged: (_) {
                      if (_gelir.text.trim().isNotEmpty) {
                        _gider.clear();
                      }
                      setState(() => _error = null);
                    },
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: TextField(
                    controller: _gider,
                    decoration: const InputDecoration(
                      labelText: 'Gider (₺)',
                      hintText: '0,00',
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                    ],
                    onChanged: (_) {
                      if (_gider.text.trim().isNotEmpty) {
                        _gelir.clear();
                      }
                      setState(() => _error = null);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<String>(
              key: ValueKey('odeme-$_odemeSekli'),
              initialValue: OdemeSekli.all.contains(_odemeSekli)
                  ? _odemeSekli
                  : OdemeSekli.diger,
              decoration: const InputDecoration(labelText: 'Ödeme şekli'),
              items: OdemeSekli.all
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) => setState(() => _odemeSekli = v ?? _odemeSekli),
            ),
            const SizedBox(height: AppSpacing.sm),
            DropdownButtonFormField<String>(
              key: ValueKey('belge-$_belgeTuru'),
              initialValue: BelgeTuru.all.contains(_belgeTuru)
                  ? _belgeTuru
                  : BelgeTuru.yok,
              decoration: const InputDecoration(labelText: 'Belge türü'),
              items: BelgeTuru.all
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) => setState(() => _belgeTuru = v ?? _belgeTuru),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _ek,
              decoration: const InputDecoration(labelText: 'Ek açıklama'),
              maxLines: 2,
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: _save,
              child: Text(_isEdit ? 'Güncelle' : 'Kaydet'),
            ),
          ],
        ),
      ),
    );
  }
}
