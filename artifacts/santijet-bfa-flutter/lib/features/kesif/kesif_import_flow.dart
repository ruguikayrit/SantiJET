import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design_system/design_system.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/providers/catalog_provider.dart';
import '../../data/providers/kesif_provider.dart';
import '../../data/providers/user_analiz_provider.dart';
import '../../data/services/kesif_import_file_service.dart';
import '../../domain/entities/poz_analiz.dart';
import '../../domain/kesif/kesif_import.dart';

/// Keşif Excel/CSV içe aktarma akışı — RN `KesifImportModal` karşılığı.
abstract final class KesifImportFlow {
  static Future<void> run(
    BuildContext context,
    WidgetRef ref, {
    String? projectId,
    void Function(String projectId)? onImported,
  }) async {
    final picked = await KesifImportFileService.pickFile();
    if (picked == null || !context.mounted) return;

    final parsed = KesifImportFileService.parseBytes(picked.bytes, picked.name);
    if (parsed.errors.isNotEmpty && parsed.rows.isEmpty) {
      if (!context.mounted) return;
      await _alert(context, 'İçe Aktarma Hatası', parsed.errors.join('\n'));
      return;
    }

    final catalogAsync = ref.read(catalogProvider);
    final catalog = catalogAsync.maybeWhen(
      data: (c) => c.all,
      orElse: () => const <PozAnaliz>[],
    );
    if (catalog.isEmpty) {
      if (!context.mounted) return;
      await _alert(context, 'Hata', 'Katalog henüz yüklenmedi.');
      return;
    }

    final mergedRows = mergeImportRowsByPoz(parsed.rows);
    final validation = validateImportRows(mergedRows, catalog);
    var resolved = validationToResolved(validation);

    if (validation.pozTypo.isNotEmpty) {
      if (!context.mounted) return;
      final fix = await _confirm(
        context,
        'Poz No Düzeltmeleri',
        '${validation.pozTypo.length} satırda poz no hatalı görünüyor; sistemdeki tanıma göre düzeltilsin mi?\n\n'
        '${validation.pozTypo.take(3).map((e) => '${e.row.pozNo} → ${e.suggestedAnaliz?.pozNo}').join('\n')}',
        confirmLabel: 'Düzelt ve Devam',
      );
      if (!fix) return;
      resolved = [...resolved, ...resolveTypoImportRows(validation.pozTypo)];
    }

    var bothMissing = validation.bothMissing.map((e) => e.row).toList();
    var addToCatalog = false;
    if (bothMissing.isNotEmpty) {
      if (!context.mounted) return;
      addToCatalog = await _confirm(
        context,
        'Eşleşmeyen Pozlar',
        '${bothMissing.length} satır katalogda bulunamadı.\n\n'
        'Kataloğa eklenmesini onaylıyor musunuz?',
        confirmLabel: 'Kataloğa Ekle',
        cancelLabel: 'Atla',
      );
    }

    final importItems = <KesifImportResolvedRow>[...resolved];
    var catalogAdded = 0;

    if (addToCatalog) {
      for (final row in bothMissing) {
        final payload = buildCatalogAnalizFromImportRow(row);
        final id = ref.read(userAnalizProvider.notifier).add(payload);
        final created = payload.copyWith(id: id);
        importItems.add(KesifImportResolvedRow(row: row, analiz: created));
        catalogAdded++;
      }
      bothMissing = [];
    }

    if (importItems.isEmpty) {
      if (!context.mounted) return;
      await _alert(
        context,
        'İçe Aktarma İptal',
        bothMissing.isEmpty
            ? 'İçe aktarılacak geçerli satır bulunamadı.'
            : 'Eşleşmeyen pozlar kataloğa eklenmedi; aktarım yapılmadı.',
      );
      return;
    }

    var targetProjectId = projectId;
    var projectName = defaultImportProjectName(picked.name, parsed);

    if (targetProjectId == null) {
      if (!context.mounted) return;
      final name = await _askProjectName(context, projectName);
      if (name == null || name.trim().isEmpty) return;
      projectName = name.trim();
      targetProjectId =
          ref.read(kesifProvider.notifier).createProject(projectName, aciklama: parsed.projectAciklama ?? '');
    }

    ref.read(kesifProvider.notifier).importSatirlar(
          targetProjectId,
          importItems
              .map((e) => (analiz: e.analiz, miktar: e.row.miktar))
              .toList(),
        );

    if (!context.mounted) return;
    final lines = <String>['${importItems.length} poz keşife eklendi.'];
    if (catalogAdded > 0) {
      lines.add('$catalogAdded yeni poz kataloğa eklendi.');
    }
    if (bothMissing.isNotEmpty) {
      lines.add('${bothMissing.length} poz atlandı.');
    }
    await _alert(context, 'İçe Aktarma Tamamlandı', lines.join('\n'));
    onImported?.call(targetProjectId);
  }

  static Future<void> _alert(
    BuildContext context,
    String title,
    String message,
  ) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  static Future<bool> _confirm(
    BuildContext context,
    String title,
    String message, {
    required String confirmLabel,
    String cancelLabel = 'İptal',
  }) async {
    return SJModal.confirm(
      context: context,
      title: title,
      message: message,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
    );
  }

  static Future<String?> _askProjectName(
    BuildContext context,
    String suggested,
  ) async {
    final controller = TextEditingController(text: suggested);
    final result = await SJModal.showSheet<String>(
      context: context,
      title: 'Keşif Adı',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SJInput(controller: controller, label: 'Proje Adı'),
          const SizedBox(height: AppSpacing.md),
          SJButton(
            label: 'İçe Aktar',
            onPressed: () => Navigator.of(context).pop(controller.text),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }
}
