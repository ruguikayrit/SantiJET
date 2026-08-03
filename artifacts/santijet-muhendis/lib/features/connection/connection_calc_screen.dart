import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_info.dart';
import '../../core/design_system/sj_status_badge.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../data/catalog/steel_profile_catalog.dart';
import '../../domain/tbdy/steel_grade.dart';
import '../../domain/tbdy/steel_profile.dart';
import '../../domain/tbdy/tbdy_connection_calculator.dart';
import '../../domain/tbdy/tbdy_connection_input.dart';
import '../../domain/tbdy/tbdy_connection_result.dart';

/// TBDY-2018 tam penetrasyonlu küt kaynaklı kiriş-kolon birleşim ekranı.
class ConnectionCalcScreen extends StatefulWidget {
  const ConnectionCalcScreen({super.key});

  @override
  State<ConnectionCalcScreen> createState() => _ConnectionCalcScreenState();
}

class _ConnectionCalcScreenState extends State<ConnectionCalcScreen> {
  /// Excel sarı hücre metaforu — düzenlenebilir girdiler.
  static const _editableFill = Color(0xFFFFF8E1);

  SteelGrade _grade = SteelGrades.s235;
  SteelProfile _column = SteelProfileCatalog.find('IPB (HE-B) 260')!;
  SteelProfile _beam = SteelProfileCatalog.find('IPE 300')!;

  late final TextEditingController _loadCtrl;
  late final TextEditingController _spanCtrl;

  TbdyConnectionResult? _result;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCtrl = TextEditingController(text: '9');
    _spanCtrl = TextEditingController(text: '4.5');
    _recalculate();
  }

  @override
  void dispose() {
    _loadCtrl.dispose();
    _spanCtrl.dispose();
    super.dispose();
  }

  void _recalculate() {
    final w = double.tryParse(_loadCtrl.text.replaceAll(',', '.'));
    final l = double.tryParse(_spanCtrl.text.replaceAll(',', '.'));
    if (w == null || w <= 0 || l == null || l <= 0) {
      setState(() {
        _error = 'Yük ve açıklık pozitif sayı olmalı.';
        _result = null;
      });
      return;
    }

    try {
      final result = TbdyConnectionCalculator.calculate(
        TbdyConnectionInput(
          steelGrade: _grade,
          column: _column,
          beam: _beam,
          distributedLoadKnPerM: w,
          spanLengthM: l,
        ),
      );
      setState(() {
        _result = result;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _result = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final result = _result;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 16,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppInfo.displayName,
              style: AppTypography.titleLarge.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              AppInfo.codeLabel,
              style: theme.textTheme.labelMedium?.copyWith(
                color: AppColors.electricBlue,
                letterSpacing: 0.4,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
        children: [
          _HeroStrip(tagline: AppInfo.tagline),
          const SizedBox(height: AppSpacing.md),
          _InfoBanner(
            text:
                'Sarı alanlar düzenlenebilir girdilerdir. Hesap anında güncellenir.',
          ),
          const SizedBox(height: AppSpacing.md),
          _SectionCard(
            title: 'Girdiler',
            child: Column(
              children: [
                _DropdownField<SteelGrade>(
                  label: 'Çelik sınıfı',
                  value: _grade,
                  items: SteelGrades.all,
                  fill: _editableFill,
                  labelOf: (g) =>
                      '${g.label}  (Fy=${g.fy.toInt()}, Fu=${g.fu.toInt()})',
                  onChanged: (g) {
                    if (g == null) return;
                    setState(() => _grade = g);
                    _recalculate();
                  },
                ),
                const SizedBox(height: 12),
                _DropdownField<SteelProfile>(
                  label: 'Kolon profili',
                  value: _column,
                  items: SteelProfileCatalog.heb,
                  fill: _editableFill,
                  labelOf: (p) => p.designation,
                  onChanged: (p) {
                    if (p == null) return;
                    setState(() => _column = p);
                    _recalculate();
                  },
                ),
                const SizedBox(height: 12),
                _DropdownField<SteelProfile>(
                  label: 'Kiriş profili',
                  value: _beam,
                  items: SteelProfileCatalog.ipe,
                  fill: _editableFill,
                  labelOf: (p) => p.designation,
                  onChanged: (p) {
                    if (p == null) return;
                    setState(() => _beam = p);
                    _recalculate();
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _NumberField(
                        label: 'Yayılı yük w [kN/m]',
                        controller: _loadCtrl,
                        fill: _editableFill,
                        onChanged: (_) => _recalculate(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _NumberField(
                        label: 'Açıklık L [m]',
                        controller: _spanCtrl,
                        fill: _editableFill,
                        onChanged: (_) => _recalculate(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _ReadonlyRow(
                  label: 'Ry / Rt (Tablo 9.2)',
                  value:
                      'Ry = ${_grade.ry.toStringAsFixed(2)}   Rt = ${_grade.rt.toStringAsFixed(2)}',
                ),
                const SizedBox(height: 8),
                const _ReadonlyRow(
                  label: 'Montaj cıvataları',
                  value: '2 × M16 (bilgi)',
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _SectionCard(
            title: 'Kesit özellikleri',
            child: Column(
              children: [
                _ProfileSummary(title: 'Kolon', profile: _column),
                Divider(height: 24, color: AppColors.border),
                _ProfileSummary(title: 'Kiriş', profile: _beam),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (_error != null)
            _SectionCard(
              title: 'Hata',
              accent: AppColors.critical,
              child: Text(
                _error!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.critical,
                ),
              ),
            ),
          if (result != null) ...[
            _SectionCard(
              title: 'Hesap adımları',
              child: Column(
                children: [
                  _CalcRow(
                    formula: 'Cpr = (Fy+Fu)/(2·Fy) ≤ 1.2',
                    value:
                        '${result.cprRaw.toStringAsFixed(4)} → ${result.cpr.toStringAsFixed(2)}',
                  ),
                  _CalcRow(
                    formula: 'Mpr = Cpr·Ry·Fy·Wplx',
                    value: '${result.mprKNm.toStringAsFixed(3)} kNm',
                  ),
                  _CalcRow(
                    formula: 'Lh = L − d_kolon',
                    value: '${result.lhM.toStringAsFixed(3)} m',
                  ),
                  _CalcRow(
                    formula: 'Vh = 2·Mpr/Lh + w·Lh/2',
                    value: '${result.vhKn.toStringAsFixed(3)} kN',
                  ),
                  _CalcRow(
                    formula: 'Mf = Mpr + Vh·Sh (Sh=0)',
                    value: '${result.mfKNm.toStringAsFixed(3)} kNm',
                  ),
                  _CalcRow(
                    formula: 'Vu',
                    value: '${result.vuKn.toStringAsFixed(3)} kN',
                  ),
                  _CalcRow(
                    formula: 'φVn = 0.6·Fy·Aw·Cv1',
                    value: '${result.phiVnKn.toStringAsFixed(2)} kN',
                    emphasize: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _SectionCard(
              title: 'Uygunluk kontrolleri',
              trailing: SJStatusBadge(
                label: result.allPassed ? 'UYGUN' : 'UYGUN DEĞİL',
                color: result.allPassed
                    ? AppColors.success
                    : AppColors.critical,
                icon: result.allPassed
                    ? Icons.check_circle_outline
                    : Icons.cancel_outlined,
              ),
              child: Column(
                children: [
                  for (final check in result.checks) ...[
                    _CheckRow(check: check),
                    if (check != result.checks.last)
                      Divider(height: 20, color: AppColors.border),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _HeroStrip extends StatelessWidget {
  const _HeroStrip({required this.tagline});
  final String tagline;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        borderRadius: AppRadii.md,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.electricBlue.withValues(alpha: 0.16),
            AppColors.surface,
          ],
        ),
        border: Border.all(
          color: AppColors.electricBlue.withValues(alpha: 0.28),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.electricBlue,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppInfo.productLabel,
                  style: AppTypography.labelLarge.copyWith(
                    color: AppColors.electricBlue,
                    letterSpacing: 1.4,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tagline,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.35,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.electricBlue.withValues(alpha: 0.08),
        borderRadius: AppRadii.md,
        border: Border.all(
          color: AppColors.electricBlue.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, size: 18, color: AppColors.electricBlue),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
    this.trailing,
    this.accent,
  });

  final String title;
  final Widget child;
  final Widget? trailing;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bar = accent ?? AppColors.electricBlue;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.md,
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.elevationSoft,
      ),
      child: ClipRRect(
        borderRadius: AppRadii.md,
        child: Stack(
          children: [
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(width: 3, color: bar),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (trailing != null) trailing!,
                    ],
                  ),
                  const SizedBox(height: 14),
                  child,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DropdownField<T> extends StatelessWidget {
  const _DropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.labelOf,
    required this.onChanged,
    required this.fill,
  });

  final String label;
  final T value;
  final List<T> items;
  final String Function(T) labelOf;
  final ValueChanged<T?> onChanged;
  final Color fill;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppColors.textMuted,
              ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<T>(
          // ignore: deprecated_member_use
          value: value,
          isExpanded: true,
          dropdownColor: AppColors.lightSurface,
          style: const TextStyle(
            color: AppColors.inkPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
          iconEnabledColor: AppColors.inkSecondary,
          decoration: InputDecoration(
            filled: true,
            fillColor: fill,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(borderRadius: AppRadii.md),
            enabledBorder: OutlineInputBorder(
              borderRadius: AppRadii.md,
              borderSide: const BorderSide(color: AppColors.lightBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: AppRadii.md,
              borderSide: const BorderSide(
                color: AppColors.electricBlue,
                width: 1.5,
              ),
            ),
          ),
          items: [
            for (final item in items)
              DropdownMenuItem(
                value: item,
                child: Text(
                  labelOf(item),
                  style: const TextStyle(color: AppColors.inkPrimary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.label,
    required this.controller,
    required this.onChanged,
    required this.fill,
  });

  final String label;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final Color fill;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppColors.textMuted,
              ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
          ],
          onChanged: onChanged,
          cursorColor: AppColors.electricBlue,
          style: const TextStyle(
            color: AppColors.inkPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: fill,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(borderRadius: AppRadii.md),
            enabledBorder: OutlineInputBorder(
              borderRadius: AppRadii.md,
              borderSide: const BorderSide(color: AppColors.lightBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: AppRadii.md,
              borderSide: const BorderSide(
                color: AppColors.electricBlue,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ReadonlyRow extends StatelessWidget {
  const _ReadonlyRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: AppRadii.sm,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textMuted,
              ),
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileSummary extends StatelessWidget {
  const _ProfileSummary({required this.title, required this.profile});
  final String title;
  final SteelProfile profile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$title — ${profile.designation}',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 6,
          children: [
            _chip('A', '${profile.areaCm2} cm²'),
            _chip('d', '${profile.depthMm} mm'),
            _chip('b', '${profile.widthMm} mm'),
            _chip('tw', '${profile.webThicknessMm} mm'),
            _chip('tf', '${profile.flangeThicknessMm} mm'),
            _chip('Wplx', '${profile.wplxCm3} cm³'),
          ],
        ),
      ],
    );
  }

  Widget _chip(String k, String v) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: AppRadii.sm,
        border: Border.all(color: AppColors.border),
      ),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$k ',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 12,
                color: AppColors.textPrimary,
              ),
            ),
            TextSpan(
              text: v,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CalcRow extends StatelessWidget {
  const _CalcRow({
    required this.formula,
    required this.value,
    this.emphasize = false,
  });

  final String formula;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              formula,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: emphasize ? AppColors.electricBlue : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckRow extends StatelessWidget {
  const _CheckRow({required this.check});
  final ComplianceCheck check;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = check.passed ? AppColors.success : AppColors.critical;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          check.passed ? Icons.check_circle : Icons.cancel,
          size: 20,
          color: color,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                check.label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                check.detail,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        SJStatusBadge(
          label: check.passed ? 'uygun' : 'uygun değil',
          color: color,
        ),
      ],
    );
  }
}
