import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';

import '../../core/theme/pro_theme.dart';
import '../../modules/pro_module.dart';
import 'module_frame.dart';

/// Modül tam ekran açılır. İçerik kaynak uygulamanın kendi arayüzüdür.
class ModuleHostScreen extends StatelessWidget {
  const ModuleHostScreen({super.key, required this.module});

  final ProModule module;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ProColors.canvas,
      body: Stack(
        children: [
          Positioned.fill(
            child: moduleFrame(
              viewType: 'pro-module-${module.id}',
              url: module.url,
            ),
          ),
          Positioned(
            left: 8,
            top: 8,
            child: PointerInterceptor(
              child: const _ReturnHandle(),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReturnHandle extends StatelessWidget {
  const _ReturnHandle();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ProColors.surface,
      elevation: 2,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        key: const Key('pro-return'),
        borderRadius: BorderRadius.circular(8),
        onTap: () => context.go('/'),
        child: Tooltip(
          message: 'Modüllere dön',
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.chevron_left, color: ProColors.text, size: 18),
                const SizedBox(height: 2),
                Text(
                  'PRO',
                  style: TextStyle(
                    fontFamily: 'Rajdhani',
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                    letterSpacing: 0.6,
                    color: ProColors.electricBlue,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
