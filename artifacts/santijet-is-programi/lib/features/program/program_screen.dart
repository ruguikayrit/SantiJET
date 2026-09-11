import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../state/app_state.dart';
import '../../ui/design_system.dart';
import 'program_table.dart';

class ProgramScreen extends ConsumerStatefulWidget {
  const ProgramScreen({super.key});

  @override
  ConsumerState<ProgramScreen> createState() => _ProgramScreenState();
}

class _ProgramScreenState extends ConsumerState<ProgramScreen> {
  ProgramTableView _view = ProgramTableView.entry;

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(programItemsProvider);
    final selectedSite = ref.watch(activeSiteProvider);
    final project = ref.watch(activeProjectProvider);
    final items = all.where((item) => item.santiyeId == selectedSite).toList();

    return Scaffold(
      backgroundColor: AppColors.canvas,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const SantijetHeader(showWordmark: true),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: _ProjectStrip(
                name: project?.name ?? selectedSite,
                code: project?.code,
                onTap: () => context.push('/settings/projeler'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: _TableTabs(
                view: _view,
                onChanged: (value) => setState(() => _view = value),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                child: ProgramTable(
                  items: items,
                  view: _view,
                  siteId: selectedSite,
                  onOpenDetails: (item) => context.push('/form', extra: item),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProjectStrip extends StatelessWidget {
  const _ProjectStrip({
    required this.name,
    required this.code,
    required this.onTap,
  });

  final String name;
  final String? code;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadii.md,
        side: BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.md,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
          child: Row(
            children: [
              Icon(
                Icons.apartment_rounded,
                size: 18,
                color: AppColors.electricBlue,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: name,
                        style: AppTypography.cardTitleMedium.copyWith(
                          fontSize: 14,
                        ),
                      ),
                      if (code != null)
                        TextSpan(
                          text: '  ·  $code',
                          style: AppTypography.cardBodySmall,
                        ),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: 18,
                color: AppColors.cardTextMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TableTabs extends StatelessWidget {
  const _TableTabs({required this.view, required this.onChanged});

  final ProgramTableView view;
  final ValueChanged<ProgramTableView> onChanged;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.md,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          _Tab(
            label: 'GİRİŞ',
            selected: view == ProgramTableView.entry,
            onTap: () => onChanged(ProgramTableView.entry),
          ),
          _Tab(
            label: 'İZLEME',
            selected: view == ProgramTableView.tracking,
            onTap: () => onChanged(ProgramTableView.tracking),
          ),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.md,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: selected
                ? AppColors.electricBlue.withValues(alpha: 0.14)
                : Colors.transparent,
            borderRadius: AppRadii.md,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 9),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: AppTypography.labelSmall.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: 0.7,
                color: selected ? AppColors.electricBlue : AppColors.textMuted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
