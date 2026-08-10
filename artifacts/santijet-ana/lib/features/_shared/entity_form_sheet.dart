import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:santijet_ana/core/theme/app_radii.dart';
import 'package:santijet_ana/core/theme/app_spacing.dart';
import 'package:santijet_ana/core/theme/app_typography.dart';
import 'package:santijet_ana/core/theme/theme_provider.dart';
import 'package:santijet_ana/core/widgets/sj_primary_button.dart';

/// Ortak tarih yardımcıları (yyyy-MM-dd depola, tr göster).
String isoDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

String todayIso() => isoDate(DateTime.now());

String displayDate(String raw) {
  final s = raw.trim();
  final ymd = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(s);
  if (ymd != null) return '${ymd[3]}.${ymd[2]}.${ymd[1]}';
  return s;
}

DateTime? parseFlexibleDate(String raw) {
  final s = raw.trim();
  if (s.isEmpty) return null;
  final ymd = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(s);
  if (ymd != null) {
    return DateTime(
      int.parse(ymd[1]!),
      int.parse(ymd[2]!),
      int.parse(ymd[3]!),
    );
  }
  final dmy = RegExp(r'^(\d{2})\.(\d{2})\.(\d{4})$').firstMatch(s);
  if (dmy != null) {
    return DateTime(
      int.parse(dmy[3]!),
      int.parse(dmy[2]!),
      int.parse(dmy[1]!),
    );
  }
  return DateTime.tryParse(s);
}

List<String> dateAliases(String s) {
  if (s.isEmpty) return const [];
  final ymd = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(s.trim());
  if (ymd != null) {
    return [s.trim(), '${ymd[3]}.${ymd[2]}.${ymd[1]}'];
  }
  final dmy = RegExp(r'^(\d{2})\.(\d{2})\.(\d{4})$').firstMatch(s.trim());
  if (dmy != null) {
    return [s.trim(), '${dmy[3]}-${dmy[2]}-${dmy[1]}'];
  }
  return [s.trim()];
}

String formatTl(num n) {
  final s = n.toStringAsFixed(0);
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    final fromEnd = s.length - i;
    buf.write(s[i]);
    if (fromEnd > 1 && fromEnd % 3 == 1) buf.write('.');
  }
  return '$buf ₺';
}

/// Modal bottom sheet: başlık + kaydırılabilir form + kaydet/sil.
Future<void> showEntityFormSheet({
  required BuildContext context,
  required String title,
  required Widget form,
  required VoidCallback onSave,
  VoidCallback? onDelete,
  String saveLabel = 'Kaydet',
  String deleteLabel = 'Sil',
  bool isScrollControlled = true,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: isScrollControlled,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _EntityFormSheetBody(
      title: title,
      form: form,
      onSave: onSave,
      onDelete: onDelete,
      saveLabel: saveLabel,
      deleteLabel: deleteLabel,
    ),
  );
}

class _EntityFormSheetBody extends ConsumerWidget {
  const _EntityFormSheetBody({
    required this.title,
    required this.form,
    required this.onSave,
    this.onDelete,
    required this.saveLabel,
    required this.deleteLabel,
  });

  final String title;
  final Widget form;
  final VoidCallback onSave;
  final VoidCallback? onDelete;
  final String saveLabel;
  final String deleteLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.watch(themeDefinitionProvider).colors;
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final safe = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.92,
        ),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: c.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: AppTypography.headlineMedium.copyWith(
                        color: c.foreground,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, color: c.mutedForeground),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  0,
                  AppSpacing.lg,
                  AppSpacing.md + safe,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    form,
                    const SizedBox(height: AppSpacing.lg),
                    SjPrimaryButton(
                      label: saveLabel,
                      onPressed: onSave,
                    ),
                    if (onDelete != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      OutlinedButton(
                        onPressed: onDelete,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: c.destructive,
                          side: BorderSide(
                            color: c.destructive.withValues(alpha: 0.5),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: const RoundedRectangleBorder(
                            borderRadius: AppRadii.md,
                          ),
                        ),
                        child: Text(
                          deleteLabel,
                          style: AppTypography.labelLarge.copyWith(
                            color: c.destructive,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Ortak seçenek chip satırı.
class SjOptionChips extends StatelessWidget {
  const SjOptionChips({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
    required this.foreground,
    required this.muted,
    required this.primary,
    required this.border,
    this.enabled = true,
  });

  final List<({String value, String label})> options;
  final String value;
  final ValueChanged<String> onChanged;
  final Color foreground;
  final Color muted;
  final Color primary;
  final Color border;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final o in options)
          GestureDetector(
            onTap: enabled ? () => onChanged(o.value) : null,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: value == o.value
                    ? primary.withValues(alpha: 0.15)
                    : muted.withValues(alpha: 0.35),
                borderRadius: AppRadii.sm,
                border: Border.all(
                  color: value == o.value ? primary : border,
                ),
              ),
              child: Text(
                o.label,
                style: TextStyle(
                  color: value == o.value ? primary : foreground,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Inter',
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Tarih seçici satırı (SjFormField benzeri).
class SjDateField extends StatelessWidget {
  const SjDateField({
    super.key,
    required this.label,
    required this.value,
    required this.onPicked,
    required this.foreground,
    required this.mutedForeground,
    required this.card,
    required this.input,
    required this.primary,
    this.enabled = true,
  });

  final String label;
  final String value;
  final ValueChanged<String> onPicked;
  final Color foreground;
  final Color mutedForeground;
  final Color card;
  final Color input;
  final Color primary;
  final bool enabled;

  Future<void> _pick(BuildContext context) async {
    if (!enabled) return;
    final initial = parseFlexibleDate(value) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) onPicked(isoDate(picked));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.labelMedium.copyWith(color: foreground),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Material(
          color: card,
          borderRadius: AppRadii.md,
          child: InkWell(
            onTap: () => _pick(context),
            borderRadius: AppRadii.md,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm + 2,
              ),
              decoration: BoxDecoration(
                borderRadius: AppRadii.md,
                border: Border.all(color: input),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      value.isEmpty ? 'Tarih seçin' : displayDate(value),
                      style: AppTypography.bodyMedium.copyWith(
                        color: value.isEmpty ? mutedForeground : foreground,
                      ),
                    ),
                  ),
                  Icon(Icons.calendar_today, size: 18, color: primary),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
