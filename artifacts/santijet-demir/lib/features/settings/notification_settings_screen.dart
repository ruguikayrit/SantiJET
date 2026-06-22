import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:santijet_demir/core/theme/app_spacing.dart';
import 'package:santijet_demir/features/settings/providers/settings_provider.dart';

class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final notifier = ref.read(appSettingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Bildirim Ayarları')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          _SectionHeader('Stok'),
          SwitchListTile(
            title: const Text('Stok uyarıları'),
            subtitle: const Text('Kritik stok seviyesi bildirimleri'),
            value: settings.notifyStock,
            onChanged: (v) => notifier.toggleNotification('stock', v),
          ),
          _SectionHeader('Siparişler'),
          SwitchListTile(
            title: const Text('Sipariş bildirimleri'),
            subtitle: const Text('Onay, verildi, yolda durumları'),
            value: settings.notifyOrders,
            onChanged: (v) => notifier.toggleNotification('orders', v),
          ),
          SwitchListTile(
            title: const Text('Teslimat bildirimleri'),
            subtitle: const Text('Teslim alındı, kısmi, eksik'),
            value: settings.notifyDeliveries,
            onChanged: (v) => notifier.toggleNotification('deliveries', v),
          ),
          _SectionHeader('Raporlar'),
          SwitchListTile(
            title: const Text('Rapor bildirimleri'),
            subtitle: const Text('Yeni rapor oluşturulduğunda'),
            value: settings.notifyReports,
            onChanged: (v) => notifier.toggleNotification('reports', v),
          ),
          _SectionHeader('Analiz'),
          SwitchListTile(
            title: const Text('Analiz içgörüleri'),
            subtitle: const Text('AI destekli uyarılar'),
            value: settings.notifyAnalysis,
            onChanged: (v) => notifier.toggleNotification('analysis', v),
          ),
          SwitchListTile(
            title: const Text('Kritik uyarılar'),
            subtitle: const Text('Acil müdahale gerektiren durumlar'),
            value: settings.notifyCritical,
            onChanged: (v) => notifier.toggleNotification('critical', v),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Text(title, style: Theme.of(context).textTheme.labelLarge),
    );
  }
}
