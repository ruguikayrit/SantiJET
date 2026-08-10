import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:santijet_ana/core/routing/app_routes.dart';
import 'package:santijet_ana/core/theme/theme_provider.dart';
import 'package:santijet_ana/core/widgets/sj_header.dart';
import 'package:santijet_ana/data/constants/yybm_periods.dart';

/// YYBM dönem listesi — RN constants/yybm.ts özet portu.
class YybmScreen extends ConsumerWidget {
  const YybmScreen({super.key});

  Future<void> _open(BuildContext context, YybmPeriod p) async {
    final url = p.url;
    if (url == null || url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bu dönem için bağlantı yok.')),
      );
      return;
    }
    final uri = Uri.parse(url);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bağlantı açılamadı.')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.watch(themeDefinitionProvider).colors;

    return Scaffold(
      backgroundColor: c.background,
      body: Column(
        children: [
          SjHeader(
            title: 'YYBM',
            onBack: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go(AppRoutes.ayarlar);
              }
            },
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                MediaQuery.paddingOf(context).bottom + 24,
              ),
              children: [
                Text(
                  'T.C. Çevre, Şehircilik ve İklim Değişikliği Bakanlığı tarafından yayımlanan yapı yaklaşık birim maliyet tebliğleri.',
                  style: TextStyle(
                    color: c.mutedForeground,
                    fontSize: 13,
                    height: 1.4,
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(height: 16),
                for (final p in yybmPeriods) ...[
                  Material(
                    color: c.card,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: p.url != null ? () => _open(context, p) : null,
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: c.border),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: c.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                p.label,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: c.primary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                  fontFamily: 'Inter',
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Resmi Gazete ${p.gazeteNo}',
                                    style: TextStyle(
                                      color: c.foreground,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: 'Inter',
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    p.gazeteDate,
                                    style: TextStyle(
                                      color: c.mutedForeground,
                                      fontSize: 12,
                                      fontFamily: 'Inter',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (p.url != null)
                              Icon(
                                Icons.open_in_new,
                                size: 18,
                                color: c.mutedForeground,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
