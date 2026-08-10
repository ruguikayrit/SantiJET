import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import 'package:santijet_ana/core/routing/app_routes.dart';
import 'package:santijet_ana/core/theme/theme_colors.dart';
import 'package:santijet_ana/core/theme/theme_provider.dart';
import 'package:santijet_ana/core/widgets/sj_header.dart';
import 'package:santijet_ana/data/providers/app_state_provider.dart';

/// Veri yönetimi — JSON dışa/içe aktarma ve tehlikeli temizleme.
class VeriYonetimScreen extends ConsumerStatefulWidget {
  const VeriYonetimScreen({super.key});

  @override
  ConsumerState<VeriYonetimScreen> createState() => _VeriYonetimScreenState();
}

class _VeriYonetimScreenState extends ConsumerState<VeriYonetimScreen> {
  String? _message;
  var _ok = false;

  Future<void> _export() async {
    final json = ref.read(appStateProvider.notifier).exportData();
    final stamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .replaceAll('T', '-')
        .split('.')
        .first;
    final filename = 'santiye-takip-$stamp.json';
    final bytes = Uint8List.fromList(utf8.encode(json));
    try {
      await Share.shareXFiles(
        [
          XFile.fromData(
            bytes,
            name: filename,
            mimeType: 'application/json',
          ),
        ],
        fileNameOverrides: [filename],
      );
      setState(() {
        _ok = true;
        _message = 'Dışa aktarma hazır.';
      });
    } catch (e) {
      setState(() {
        _ok = false;
        _message = 'Dışa aktarma başarısız: $e';
      });
    }
  }

  Future<void> _import() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['json'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    final bytes = file.bytes;
    if (bytes == null) {
      setState(() {
        _ok = false;
        _message = 'Dosya okunamadı.';
      });
      return;
    }
    final text = utf8.decode(bytes);
    if (!mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Verileri Değiştir'),
        content: const Text(
          'Mevcut tüm veriler içe aktarılan dosyayla değiştirilecek. Devam edilsin mi?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Devam Et'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final res = ref.read(appStateProvider.notifier).importData(text);
    if (res.ok) {
      final total =
          res.counts?.values.fold<int>(0, (a, b) => a + b) ?? 0;
      setState(() {
        _ok = true;
        _message =
            'Başarılı: $total kayıt yüklendi. Yeniden giriş yapmanız gerekecek.';
      });
      await Future<void>.delayed(const Duration(milliseconds: 1200));
      if (!mounted) return;
      ref.read(appStateProvider.notifier).logout();
    } else {
      setState(() {
        _ok = false;
        _message = res.error ?? 'İçe aktarma başarısız';
      });
    }
  }

  Future<void> _clearAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tüm Verileri Sil'),
        content: const Text(
          'Projeler, puantaj, malzeme ve diğer tüm kayıtlar silinecek. Bu işlem geri alınamaz.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Vazgeç'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    ref.read(appStateProvider.notifier).clearAllData();
    setState(() {
      _ok = true;
      _message = 'Tüm veriler temizlendi.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = ref.watch(themeDefinitionProvider).colors;

    return Scaffold(
      backgroundColor: c.background,
      body: Column(
        children: [
          SjHeader(
            title: 'Veri Yönetimi',
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
                  'Tüm uygulama verilerini JSON formatında dışa aktarın veya önceden alınan yedeği geri yükleyin.',
                  style: TextStyle(
                    color: c.mutedForeground,
                    fontSize: 13,
                    height: 1.4,
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _actionCard(
                        c,
                        icon: Icons.download_outlined,
                        iconBg: const Color(0xFFDCFCE7),
                        iconColor: const Color(0xFF16A34A),
                        title: 'Dışa Aktar',
                        sub: 'JSON yedek dosyası oluştur',
                        onTap: _export,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _actionCard(
                        c,
                        icon: Icons.upload_outlined,
                        iconBg: const Color(0xFFDBEAFE),
                        iconColor: const Color(0xFF2563EB),
                        title: 'İçe Aktar',
                        sub: 'JSON yedeği geri yükle',
                        onTap: _import,
                      ),
                    ),
                  ],
                ),
                if (_message != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: (_ok ? const Color(0xFF16A34A) : c.destructive)
                          .withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _message!,
                      style: TextStyle(
                        color: _ok ? const Color(0xFF16A34A) : c.destructive,
                        fontFamily: 'Inter',
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                Text(
                  'TEHLİKELİ BÖLGE',
                  style: TextStyle(
                    color: c.destructive,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(height: 10),
                Material(
                  color: c.card,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: _clearAll,
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: c.destructive.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.delete_forever, color: c.destructive),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Tüm Verileri Temizle',
                                  style: TextStyle(
                                    color: c.destructive,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: 'Inter',
                                  ),
                                ),
                                Text(
                                  'Çalışma alanı oturumu korunur; kayıtlar silinir',
                                  style: TextStyle(
                                    color: c.mutedForeground,
                                    fontSize: 12,
                                    fontFamily: 'Inter',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionCard(
    ThemeColors c, {
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String sub,
    required VoidCallback onTap,
  }) {
    return Material(
      color: c.card,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: c.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  color: c.foreground,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Inter',
                ),
              ),
              const SizedBox(height: 4),
              Text(
                sub,
                style: TextStyle(
                  color: c.mutedForeground,
                  fontSize: 12,
                  fontFamily: 'Inter',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
