import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/routing/app_routes.dart';
import '../../data/providers/kesif_provider.dart';

/// Eski `/kesif-detay/:id` derin bağlantısı → aktif proje + Keşif sekmesi.
class KesifDetailScreen extends ConsumerStatefulWidget {
  const KesifDetailScreen({required this.projectId, super.key});

  final String projectId;

  @override
  ConsumerState<KesifDetailScreen> createState() => _KesifDetailScreenState();
}

class _KesifDetailScreenState extends ConsumerState<KesifDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(activeKesifIdProvider.notifier).set(widget.projectId);
      context.go(AppRoutes.kesif);
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
