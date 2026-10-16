import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:santijet_demir/core/format/app_format.dart';
import 'package:santijet_demir/core/theme/app_colors.dart';
import 'package:santijet_demir/core/theme/app_typography.dart';
import 'package:santijet_demir/core/widgets/app_toast.dart';
import 'package:santijet_demir/core/widgets/santijet_header.dart';
import 'package:santijet_demir/domain/entities/field_count.dart';
import 'package:santijet_demir/features/field_count/providers/field_count_provider.dart';

class NewCountScreen extends ConsumerStatefulWidget {
  const NewCountScreen({super.key, this.recordId});

  final String? recordId;

  @override
  ConsumerState<NewCountScreen> createState() => _NewCountScreenState();
}

class _NewCountScreenState extends ConsumerState<NewCountScreen> {
  final _personnelController = TextEditingController();
  final _regionController = TextEditingController();
  final _noteController = TextEditingController();
  final _controllers = <int, TextEditingController>{};
  final _subscriptions = <ProviderSubscription<Object?>>[];
  Set<int> _activeDiameters = const {};
  var _loadedRecord = false;

  static const _cardDecoration = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.all(Radius.circular(16)),
    border: Border.fromBorderSide(BorderSide(color: Color(0xFFE6EBF2))),
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  void _bootstrap() {
    if (!mounted) return;

    if (widget.recordId != null && !_loadedRecord) {
      _loadedRecord = true;
      final records = ref.read(fieldCountsProvider);
      for (final record in records) {
        if (record.id == widget.recordId) {
          ref.read(newCountDraftProvider.notifier).loadFromRecord(record);
          _personnelController.text = record.personnel;
          _regionController.text = record.region;
          _noteController.text = record.note;
          break;
        }
      }
    } else {
      ref.read(newCountDraftProvider.notifier).syncFromSources();
    }

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
    if (!ref.read(newCountDraftProvider).isEditing) {
      ref.read(newCountDraftProvider.notifier).syncFromSources();
    }
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
    _personnelController.dispose();
    _regionController.dispose();
    _noteController.dispose();
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

  Future<void> _pickDateTime(NewCountDraft draft, NewCountDraftNotifier notifier) async {
    final base = draft.date ?? DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: base,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(base),
    );
    if (time == null || !mounted) return;

    notifier.setDate(DateTime(date.year, date.month, date.day, time.hour, time.minute));
  }

  Future<void> _pickPhoto(NewCountDraftNotifier notifier) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Kamera'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Galeri'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;

    final file = await ImagePicker().pickImage(source: source, imageQuality: 85);
    if (file == null) return;
    notifier.setPhotoPath(file.path);
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(newCountDraftProvider);
    final notifier = ref.read(newCountDraftProvider.notifier);
    final lines = ref.watch(countDiameterLinesProvider);
    final isEditing = draft.isEditing;
    final when = draft.date ?? DateTime.now();
    final dateLabel = DateFormat('dd.MM.yyyy').format(when);
    final timeLabel = DateFormat('HH:mm').format(when);

    for (final line in lines) {
      _controllers.putIfAbsent(line.diameter, TextEditingController.new);
    }

    final filledLines = lines.where((line) => line.actual > 0).toList();
    final totalTons = filledLines.fold<double>(0, (sum, line) => sum + line.actual);

    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FA),
      body: Column(
        children: [
          DemirBrandHeader(
            title: isEditing ? 'Sayım Düzenle' : 'Yeni Saha Sayımı',
            showBack: true,
            showSettings: false,
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
          Text(
            'Genel Bilgiler',
            style: AppTypography.titleMedium.copyWith(
              color: const Color(0xFF1C2430),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            decoration: _cardDecoration,
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                _LabeledField(
                  label: 'Tarih',
                  child: InkWell(
                    onTap: () => _pickDateTime(draft, notifier),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F9FC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE6EBF2)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_outlined, size: 18, color: Color(0xFF2563EB)),
                          const SizedBox(width: 10),
                          Text(dateLabel, style: AppTypography.bodyMedium),
                          const Spacer(),
                          const Icon(Icons.schedule, size: 18, color: Color(0xFF64748B)),
                          const SizedBox(width: 6),
                          Text(timeLabel, style: AppTypography.bodyMedium),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _LabeledField(
                  label: 'Sayım yapan personel',
                  child: TextField(
                    controller: _personnelController,
                    decoration: const InputDecoration(hintText: 'Ad soyad'),
                    onChanged: notifier.setPersonnel,
                  ),
                ),
                const SizedBox(height: 12),
                _LabeledField(
                  label: 'Konum / bölge',
                  child: TextField(
                    controller: _regionController,
                    decoration: const InputDecoration(hintText: 'Örn: Blok A — depo'),
                    onChanged: notifier.setRegion,
                  ),
                ),
                const SizedBox(height: 12),
                _LabeledField(
                  label: 'Not',
                  child: TextField(
                    controller: _noteController,
                    minLines: 2,
                    maxLines: 4,
                    decoration: const InputDecoration(hintText: 'Saha koşulları, stok yeri…'),
                    onChanged: notifier.setNote,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Fotoğraf',
            style: AppTypography.titleMedium.copyWith(
              color: const Color(0xFF1C2430),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              onTap: () => _pickPhoto(notifier),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: _cardDecoration,
                child: !kIsWeb &&
                        draft.photoPath.isNotEmpty &&
                        File(draft.photoPath).existsSync()
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          File(draft.photoPath),
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Column(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(
                              color: Color(0xFFE8F1FE),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.add_a_photo_outlined, color: Color(0xFF2563EB)),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Saha fotoğrafı ekle',
                            style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
                          ),
                          Text(
                            'Kamera veya galeriden seçin',
                            style: AppTypography.bodySmall.copyWith(color: const Color(0xFF64748B)),
                          ),
                        ],
                      ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Mevcut demir (ton)',
                  style: AppTypography.titleMedium.copyWith(
                    color: const Color(0xFF1C2430),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                'Toplam: ${AppFormat.tonnage(totalTons)}',
                style: AppTypography.labelMedium.copyWith(color: const Color(0xFF64748B)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Sahada bulunan demiri çap bazında ton olarak girin.',
            style: AppTypography.bodySmall.copyWith(color: const Color(0xFF64748B)),
          ),
          const SizedBox(height: 10),
          if (lines.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: _cardDecoration,
              child: Text(
                'Keşif veya teslimat kaydı olmadığı için çap listesi boş. Önce keşif girin.',
                style: AppTypography.bodySmall.copyWith(color: const Color(0xFF64748B)),
              ),
            )
          else
            Container(
              decoration: _cardDecoration,
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'ÇAP',
                            style: AppTypography.labelMedium.copyWith(color: const Color(0xFF8B95A5)),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'SAHADA (t)',
                            textAlign: TextAlign.end,
                            style: AppTypography.labelMedium.copyWith(color: const Color(0xFF8B95A5)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  for (final line in lines)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Ø${line.diameter}',
                              style: AppTypography.titleMedium.copyWith(
                                color: AppColors.diameterColor(line.diameter),
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: TextField(
                              controller: _controllers[line.diameter],
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              textAlign: TextAlign.end,
                              decoration: const InputDecoration(
                                isDense: true,
                                hintText: '0',
                                suffixText: 't',
                              ),
                              onChanged: (value) => notifier.setActualCount(
                                line.diameter,
                                double.tryParse(value.replaceAll(',', '.')) ?? 0,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          const SizedBox(height: 24),
          Row(
            children: [
              TextButton(
                onPressed: () {
                  ref.read(newCountDraftProvider.notifier).reset();
                  context.pop();
                },
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textMuted,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                child: const Text('İptal'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    minimumSize: const Size.fromHeight(48),
                  ),
                  onPressed: lines.isEmpty
                      ? null
                      : () async {
                          final record = await notifier.completeCount(lines);
                          if (!context.mounted) return;

                          if (record == null) {
                            ScaffoldMessenger.of(context).showAppSnackBar(
                              const SnackBar(
                                content: Text('En az bir çap için tonaj girin'),
                                backgroundColor: AppColors.warning,
                              ),
                            );
                            return;
                          }

                          ScaffoldMessenger.of(context).showAppSnackBar(
                            SnackBar(
                              content: Text(
                                isEditing ? 'Sayım güncellendi' : 'Sayım kaydedildi',
                              ),
                              backgroundColor: AppColors.success,
                            ),
                          );
                          context.pop();
                        },
                  child: Text(isEditing ? 'Güncelle' : 'Kaydet'),
                ),
              ),
            ],
          ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.labelMedium.copyWith(
            color: const Color(0xFF64748B),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}
