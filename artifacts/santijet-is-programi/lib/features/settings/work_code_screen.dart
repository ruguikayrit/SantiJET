import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/app_state.dart';
import '../../ui/design_system.dart';
import 'settings_scaffold.dart';

class WorkCodeScreen extends ConsumerStatefulWidget {
  const WorkCodeScreen({super.key});

  @override
  ConsumerState<WorkCodeScreen> createState() => _WorkCodeScreenState();
}

class _WorkCodeScreenState extends ConsumerState<WorkCodeScreen> {
  final _join = TextEditingController();

  @override
  void dispose() {
    _join.dispose();
    super.dispose();
  }

  Future<void> _copy(String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('İş kodu kopyalandı: $code')),
    );
  }

  Future<void> _joinCode() async {
    final code = _join.text.trim().toUpperCase();
    if (code.isEmpty) return;
    await ref.read(projectsProvider.notifier).joinCode(code);
    _join.clear();
    if (!mounted) return;
    final project = ref.read(activeProjectProvider);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          project == null
              ? 'Kod işlendi.'
              : '${project.name} seçildi (${project.code}).',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final project = ref.watch(activeProjectProvider);

    return SettingsScaffold(
      title: 'İş kodu',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        children: [
          SJCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  project?.code ?? 'Kod yok',
                  style: AppTypography.onCard(AppTypography.headlineMedium),
                ),
                const SizedBox(height: 6),
                Text(
                  project == null
                      ? 'Önce Projelerim’den bir şantiye seçin.'
                      : '${project.name} için yerel kod. Cihaz dışına çıkmaz; '
                          'aynı telefondaki başka bir kayda geçmek için kullanılır.',
                  style: AppTypography.cardBodySmall,
                ),
                if (project != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  SJButton(
                    label: 'Kodu kopyala',
                    icon: Icons.copy_outlined,
                    onPressed: () => _copy(project.code),
                    variant: SJButtonVariant.secondary,
                    expanded: true,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          SJCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Koda geç',
                  style: AppTypography.cardTitleMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  'Kod bu cihazda varsa o şantiye açılır. Yoksa boş bir şantiye '
                  'oluşturulur. Paylaşım veya bulut yoktur.',
                  style: AppTypography.cardBodySmall,
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _join,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'İş kodu',
                    hintText: 'SJAB12',
                    prefixIcon: Icon(Icons.qr_code_2_outlined),
                  ),
                  onFieldSubmitted: (_) => _joinCode(),
                ),
                const SizedBox(height: AppSpacing.md),
                SJButton(
                  label: 'Koda geç',
                  onPressed: _joinCode,
                  expanded: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
