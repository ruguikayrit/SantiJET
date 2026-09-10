import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/interop/program_interop.dart';
import '../../domain/program_item.dart';
import '../../state/app_state.dart';
import '../../ui/design_system.dart';
import 'import_preview_screen.dart';

/// MS Project, Excel ve PDF alışverişinin toplandığı sayfa.
class TransferScreen extends ConsumerStatefulWidget {
  const TransferScreen({super.key});

  @override
  ConsumerState<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends ConsumerState<TransferScreen> {
  /// Aktarımın tüm şantiyeleri mi, yalnız etkin şantiyeyi mi kapsadığı.
  bool _allSites = false;
  InteropFormat? _busy;
  bool _importing = false;

  @override
  Widget build(BuildContext context) {
    final site = ref.watch(activeSiteProvider);
    final all = ref.watch(programItemsProvider);
    final scoped = _allSites
        ? all
        : all.where((item) => item.santiyeId == site).toList();

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/'),
        ),
        title: Text(
          'Aktar',
          style: AppTypography.headlineMedium.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        children: [
          const _SectionLabel('KAPSAM'),
          SJCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _allSites ? 'Tüm şantiyeler' : site,
                        style: AppTypography.onCard(
                          AppTypography.cardTitleMedium,
                        ),
                      ),
                    ),
                    Switch(
                      value: _allSites,
                      onChanged: (value) => setState(() => _allSites = value),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${scoped.length} faaliyet aktarılacak. MS Project '
                  'dosyasında her şantiye bir özet görev olur.',
                  style: AppTypography.cardBodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const _SectionLabel('MS PROJECT’E AKTAR'),
          _FormatTile(
            icon: Icons.account_tree_outlined,
            title: 'MS Project XML',
            subtitle:
                'Project’te “Dosya → Aç” ile açılır, tarihler ve ilerleme '
                'yeniden hesaplanır.',
            busy: _busy == InteropFormat.msProjectXml,
            enabled: scoped.isNotEmpty && _busy == null,
            onTap: () => _export(InteropFormat.msProjectXml, scoped, site),
          ),
          _FormatTile(
            icon: Icons.grid_on_outlined,
            title: 'Excel (.xlsx)',
            subtitle:
                'Sütun başlıkları Project alan adlarıyla yazılır; Project '
                'içe aktarım sihirbazı kendiliğinden eşler.',
            busy: _busy == InteropFormat.excel,
            enabled: scoped.isNotEmpty && _busy == null,
            onTap: () => _export(InteropFormat.excel, scoped, site),
          ),
          _FormatTile(
            icon: Icons.picture_as_pdf_outlined,
            title: 'PDF raporu',
            subtitle:
                'Tablo ve Gantt şeridiyle paylaşım raporu. Project’e geri '
                'okunmaz.',
            busy: _busy == InteropFormat.pdf,
            enabled: scoped.isNotEmpty && _busy == null,
            onTap: () => _export(InteropFormat.pdf, scoped, site),
          ),
          const SizedBox(height: 22),
          const _SectionLabel('MS PROJECT’TEN AL'),
          SJCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dosya seç',
                  style: AppTypography.onCard(AppTypography.cardTitleMedium),
                ),
                const SizedBox(height: 6),
                Text(
                  'MS Project XML (.xml) ya da Excel (.xlsx) dosyası okunur. '
                  'Faaliyetler yazılmadan önce önizlenir.',
                  style: AppTypography.cardBodySmall,
                ),
                const SizedBox(height: AppSpacing.md),
                SJButton(
                  label: 'Dosya seç ve önizle',
                  icon: Icons.file_open_outlined,
                  expanded: true,
                  loading: _importing,
                  onPressed: _importing || _busy != null ? null : _import,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SJCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  size: 18,
                  color: AppColors.cardTextMuted,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '.mpp dosyası doğrudan okunamaz. MS Project içinde '
                    '“Dosya → Farklı Kaydet → MS Project XML (*.xml)” ile '
                    'kaydedip o dosyayı seçin.',
                    style: AppTypography.cardBodySmall,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _export(
    InteropFormat format,
    List<ProgramItem> items,
    String site,
  ) async {
    setState(() => _busy = format);
    try {
      final name = await ref.read(programInteropServiceProvider).export(
        format,
        items,
        projectName: _allSites ? 'ŞantiJET İş Programı' : site,
      );
      _notify('$name hazırlandı.');
    } catch (error) {
      _notify(_message(error), isError: true);
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  Future<void> _import() async {
    setState(() => _importing = true);
    try {
      final result = await ref
          .read(programInteropServiceProvider)
          .pickAndDecode(fallbackSite: ref.read(activeSiteProvider));
      if (result == null) return;
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ImportPreviewScreen(result: result),
        ),
      );
    } catch (error) {
      _notify(_message(error), isError: true);
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  String _message(Object error) => error is ProgramImportException
      ? error.message
      : 'Dosya işlenemedi: $error';

  void _notify(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.critical : null,
        duration: Duration(seconds: isError ? 6 : 3),
      ),
    );
  }
}

class _FormatTile extends StatelessWidget {
  const _FormatTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.busy,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool busy;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: SJCard(
      onTap: enabled ? onTap : null,
      child: Row(
        children: [
          Icon(
            icon,
            size: 22,
            color: enabled ? AppColors.electricBlue : AppColors.cardTextMuted,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.onCard(AppTypography.cardTitleMedium),
                ),
                const SizedBox(height: 3),
                Text(subtitle, style: AppTypography.cardBodySmall),
              ],
            ),
          ),
          const SizedBox(width: 10),
          if (busy)
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Icon(
              Icons.download_rounded,
              size: 18,
              color: AppColors.cardTextMuted,
            ),
        ],
      ),
    ),
  );
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 10),
    child: Text(
      text,
      style: AppTypography.labelSmall.copyWith(
        color: AppColors.textMuted,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.1,
      ),
    ),
  );
}
