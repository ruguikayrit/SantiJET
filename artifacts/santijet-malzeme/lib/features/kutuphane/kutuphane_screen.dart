import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/design_system/sj_button.dart';
import '../../core/design_system/sj_card.dart';
import '../../core/design_system/sj_empty_state.dart';
import '../../core/design_system/sj_input.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/id_gen.dart';
import '../../core/widgets/santijet_header.dart';
import '../../core/widgets/swipe_to_delete_row.dart';
import '../../data/providers/app_data_provider.dart';
import '../../domain/entities/tech_sheet.dart';

/// TDS / teknik kütüphane — liste + ekle kabuğu (image_picker iskelet).
class KutuphaneScreen extends ConsumerStatefulWidget {
  const KutuphaneScreen({super.key});

  @override
  ConsumerState<KutuphaneScreen> createState() => _KutuphaneScreenState();
}

class _KutuphaneScreenState extends ConsumerState<KutuphaneScreen> {
  @override
  Widget build(BuildContext context) {
    final sheets = ref.watch(libraryProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SantijetHeader(subtitle: 'Kütüphane'),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                0,
                AppSpacing.md,
                AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Teknik föyler (TDS)',
                      style: AppTypography.titleMedium.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  SJButton(
                    label: 'Ekle',
                    icon: Icons.add,
                    onPressed: () => _openAddSheet(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: sheets.isEmpty
                  ? const SJEmptyState(
                      title: 'Kütüphane boş',
                      message:
                          'Ürün, üretici ve TDS dosyası ekleyin. '
                          'Sipariş öncesi teknik karar için kullanın.',
                      icon: Icons.menu_book_outlined,
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md,
                        0,
                        AppSpacing.md,
                        AppSpacing.xxl,
                      ),
                      itemCount: sheets.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, index) {
                        final sheet = sheets[index];
                        return SwipeToDeleteRow(
                          itemKey: ValueKey('tds-${sheet.id}'),
                          bottomMargin: 0,
                          title: 'Kayıt sil',
                          message:
                              '"${sheet.productName}" kütüphaneden silinsin mi?',
                          onDelete: () async {
                            ref
                                .read(libraryProvider.notifier)
                                .delete(sheet.id);
                          },
                          child: SJCard(
                            onTap: () => _openDetail(context, sheet),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  sheet.productName,
                                  style: AppTypography.titleMedium.copyWith(
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  sheet.manufacturer,
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                if (sheet.tags.isNotEmpty) ...[
                                  const SizedBox(height: AppSpacing.sm),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: [
                                      for (final tag in sheet.tags)
                                        Chip(
                                          label: Text(tag),
                                          visualDensity: VisualDensity.compact,
                                          backgroundColor:
                                              AppColors.surfaceElevated,
                                          side: BorderSide(
                                            color: AppColors.border,
                                          ),
                                          labelStyle:
                                              AppTypography.labelSmall.copyWith(
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openAddSheet(BuildContext context) async {
    final productCtrl = TextEditingController();
    final mfrCtrl = TextEditingController();
    final tagsCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    String? filePath;
    String fileName = '';

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceElevated,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.md,
            right: AppSpacing.md,
            top: AppSpacing.md,
            bottom: MediaQuery.viewInsetsOf(ctx).bottom + AppSpacing.md,
          ),
          child: StatefulBuilder(
            builder: (ctx, setModal) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'TDS ekle',
                      style: AppTypography.titleMedium.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    SJInput(
                      controller: productCtrl,
                      label: 'Ürün adı',
                      hint: 'Örn. Flex Yapıştırıcı C2TE',
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    SJInput(
                      controller: mfrCtrl,
                      label: 'Üretici',
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    SJInput(
                      controller: tagsCtrl,
                      label: 'Etiketler',
                      hint: 'virgülle ayırın',
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    SJInput(
                      controller: notesCtrl,
                      label: 'Notlar',
                      maxLines: 3,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    SJButton(
                      label: fileName.isEmpty
                          ? 'Dosya / foto seç'
                          : 'Seçildi: $fileName',
                      variant: SJButtonVariant.secondary,
                      icon: Icons.attach_file,
                      onPressed: () async {
                        final picker = ImagePicker();
                        final file = await picker.pickImage(
                          source: ImageSource.gallery,
                        );
                        if (file == null) return;
                        setModal(() {
                          filePath = file.path;
                          fileName = file.name;
                        });
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    SJButton(
                      label: 'Kaydet',
                      onPressed: () {
                        if (productCtrl.text.trim().isEmpty) return;
                        Navigator.pop(ctx, true);
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );

    if (saved != true) return;

    final tags = tagsCtrl.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    ref.read(libraryProvider.notifier).upsert(
          TechSheet(
            id: IdGen.make('tds'),
            productName: productCtrl.text.trim(),
            manufacturer: mfrCtrl.text.trim(),
            filePath: filePath,
            fileName: fileName,
            mimeType: fileName.toLowerCase().endsWith('.pdf')
                ? 'application/pdf'
                : 'image/*',
            tags: tags,
            notes: notesCtrl.text.trim(),
            createdAt: DateTime.now(),
          ),
        );
  }

  void _openDetail(BuildContext context, TechSheet sheet) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceElevated,
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                sheet.productName,
                style: AppTypography.titleMedium.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                sheet.manufacturer,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              if (sheet.notes.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  sheet.notes,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
              if (sheet.fileName.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Dosya: ${sheet.fileName}',
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              Text(
                'Aç / paylaş — sonraki faz (path veya bytes ref).',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              SJButton(
                label: 'Kapat',
                variant: SJButtonVariant.ghost,
                onPressed: () => Navigator.pop(ctx),
              ),
            ],
          ),
        );
      },
    );
  }
}
