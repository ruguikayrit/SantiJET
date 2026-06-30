import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:santijet_demir/core/theme/app_colors.dart';
import 'package:santijet_demir/core/theme/app_radii.dart';
import 'package:santijet_demir/core/theme/app_spacing.dart';
import 'package:santijet_demir/core/theme/app_typography.dart';
import 'package:santijet_demir/core/widgets/empty_states.dart';
import 'package:santijet_demir/domain/entities/field_count.dart';
import 'package:santijet_demir/features/field_count/providers/field_count_provider.dart';

class NewCountScreen extends ConsumerStatefulWidget {
  const NewCountScreen({super.key});

  @override
  ConsumerState<NewCountScreen> createState() => _NewCountScreenState();
}

class _NewCountScreenState extends ConsumerState<NewCountScreen> {
  final _controllers = <int, TextEditingController>{};
  final _subscriptions = <ProviderSubscription<Object?>>[];
  Set<int> _activeDiameters = const {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  void _bootstrap() {
    if (!mounted) return;

    _applyLines(ref.read(countDiameterLinesProvider));
    _subscriptions
      ..add(
        ref.listenManual<Map<int, double>>(
          plannedUsageByDiameterProvider,
          (_, __) => _onSourcesChanged(),
        ),
      )
      ..add(
        ref.listenManual<Map<int, double>>(
          deliveredDiametersForCountProvider,
          (_, __) => _onSourcesChanged(),
        ),
      );
  }

  void _onSourcesChanged() {
    if (!mounted) return;
    ref.read(newCountDraftProvider.notifier).syncFromSources();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _applyLines(ref.read(countDiameterLinesProvider));
    });
  }

  void _applyLines(List<CountDiameterLine> lines) {
    final diameters = lines.map((line) => line.diameter).toSet();

    for (final diameter in diameters) {
      _controllers.putIfAbsent(diameter, TextEditingController.new);
    }

    for (final line in lines) {
      final controller = _controllers[line.diameter];
      if (controller == null) continue;
      final text = _formatCount(line.actual);
      if (controller.text != text) {
        controller.text = text;
      }
    }

    if (diameters != _activeDiameters) {
      final stale = _activeDiameters.difference(diameters);
      for (final diameter in stale) {
        _controllers.remove(diameter)?.dispose();
      }
      _activeDiameters = diameters;
    }
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      subscription.close();
    }
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  String _formatCount(double value) {
    if (value == 0) return '';
    if (value == value.roundToDouble()) return value.toStringAsFixed(0);
    return value.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(newCountDraftProvider);
    final notifier = ref.read(newCountDraftProvider.notifier);
    final lines = ref.watch(countDiameterLinesProvider);

    for (final line in lines) {
      _controllers.putIfAbsent(line.diameter, TextEditingController.new);
    }

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(title: const Text('Yeni Sayım')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Text('Tarih', style: AppTypography.titleMedium),
          const SizedBox(height: 8),
          ListTile(
            tileColor: AppColors.surfaceElevated,
            shape: RoundedRectangleBorder(
              borderRadius: AppRadii.md,
              side: const BorderSide(color: AppColors.border),
            ),
            leading: const Icon(Icons.calendar_today, color: AppColors.electricBlueLight),
            title: Text(
              draft.date != null
                  ? '${draft.date!.day}.${draft.date!.month}.${draft.date!.year}'
                  : 'Tarih seçin',
            ),
          ),
          const SizedBox(height: 16),
          Text('Personel', style: AppTypography.titleMedium),
          const SizedBox(height: 8),
          TextField(
            decoration: const InputDecoration(hintText: 'Sayım yapan personel'),
            onChanged: notifier.setPersonnel,
          ),
          const SizedBox(height: 16),
          Text('Şantiye Bölgesi', style: AppTypography.titleMedium),
          const SizedBox(height: 8),
          TextField(
            decoration: const InputDecoration(hintText: 'Örn: Blok A — Kolon'),
            onChanged: notifier.setRegion,
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: AppRadii.md,
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                Icon(Icons.camera_alt_outlined, size: 40, color: AppColors.textMuted),
                const SizedBox(height: 8),
                Text('Fotoğraf Yükle', style: AppTypography.bodyMedium),
                Text('Saha fotoğrafı ekleyin', style: AppTypography.bodySmall),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text('Sayım Girişi', style: AppTypography.headlineMedium),
          const SizedBox(height: 4),
          Text(
            'Beklenen = ana sayfadaki çap bazında plan kullanım; yalnızca sayım girin.',
            style: AppTypography.bodySmall,
          ),
          const SizedBox(height: 12),
          if (lines.isEmpty)
            const ModuleEmptyState(type: EmptyStateType.noDelivery, inline: true)
          else
            _CountEntryTable(
              lines: lines,
              controllers: _controllers,
              onChanged: notifier.setActualCount,
            ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: lines.isEmpty
                ? null
                : () async {
                    final record = await notifier.completeCount(lines);
                    if (!context.mounted) return;

                    for (final controller in _controllers.values) {
                      controller.clear();
                    }

                    if (record == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('En az bir çap için sayım girin'),
                          backgroundColor: AppColors.warning,
                        ),
                      );
                      return;
                    }

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Sayım kaydedildi'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                    context.pop();
                  },
            child: const Text('Tamamla'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: lines.isEmpty
                ? null
                : () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Taslak kaydedildi')),
                    );
                    context.pop();
                  },
            child: const Text('Taslak Kaydet'),
          ),
        ],
      ),
    );
  }
}

class _CountEntryTable extends StatelessWidget {
  const _CountEntryTable({
    required this.lines,
    required this.controllers,
    required this.onChanged,
  });

  final List<CountDiameterLine> lines;
  final Map<int, TextEditingController> controllers;
  final void Function(int diameter, double value) onChanged;

  static const _columns = [
    _CountColumnSpec('ÇAP', 56),
    _CountColumnSpec('TESLİM', 72),
    _CountColumnSpec('BEKLENEN', 88),
    _CountColumnSpec('SAYIM', 88),
    _CountColumnSpec('KULLANILAN', 96),
  ];

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: AppRadii.md,
        border: Border.all(color: AppColors.border),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: 620,
          child: Column(
            children: [
              const _CountTableHeader(),
              ...lines.map((line) {
                final controller = controllers[line.diameter];
                if (controller == null) return const SizedBox.shrink();

                return _CountTableRow(
                  line: line,
                  controller: controller,
                  onChanged: (value) => onChanged(
                    line.diameter,
                    double.tryParse(value.replaceAll(',', '.')) ?? 0,
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

class _CountTableHeader extends StatelessWidget {
  const _CountTableHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          for (final column in _CountEntryTable._columns)
            SizedBox(
              width: column.width,
              child: Text(
                column.label,
                style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
        ],
      ),
    );
  }
}

class _CountTableRow extends StatelessWidget {
  const _CountTableRow({
    required this.line,
    required this.controller,
    required this.onChanged,
  });

  final CountDiameterLine line;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 56,
            child: Text(
              'Ø${line.diameter}',
              style: AppTypography.titleMedium.copyWith(
                color: AppColors.diameterColor(line.diameter),
              ),
            ),
          ),
          SizedBox(
            width: 72,
            child: Text(
              '${line.delivered.toStringAsFixed(1)}t',
              style: AppTypography.bodyMedium,
            ),
          ),
          SizedBox(
            width: 88,
            child: Text(
              '${line.plannedUsage.toStringAsFixed(1)}t',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.electricBlueLight,
              ),
            ),
          ),
          SizedBox(
            width: 88,
            child: TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                isDense: true,
                hintText: '0',
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                suffixText: 't',
              ),
              onChanged: onChanged,
            ),
          ),
          SizedBox(
            width: 96,
            child: Text(
              '${line.actualUsed.toStringAsFixed(1)}t',
              style: AppTypography.bodyMedium.copyWith(
                color: line.actualUsed > line.plannedUsage
                    ? AppColors.warning
                    : AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CountColumnSpec {
  const _CountColumnSpec(this.label, this.width);

  final String label;
  final double width;
}
