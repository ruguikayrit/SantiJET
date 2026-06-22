import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:santijet_demir/core/theme/app_colors.dart';
import 'package:santijet_demir/core/theme/app_radii.dart';
import 'package:santijet_demir/core/theme/app_spacing.dart';
import 'package:santijet_demir/core/theme/app_typography.dart';
import 'package:santijet_demir/features/auth/providers/app_lock_provider.dart';

class AppLockScreen extends ConsumerStatefulWidget {
  const AppLockScreen({super.key});

  @override
  ConsumerState<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends ConsumerState<AppLockScreen> {
  static final _pinLength = defaultPinLength;
  String _input = '';
  bool _showError = false;

  void _onDigit(String digit) {
    final lock = ref.read(appLockProvider);
    if (lock.isTemporarilyLocked) return;
    if (_input.length >= _pinLength) return;

    setState(() {
      _showError = false;
      _input += digit;
    });

    if (_input.length == _pinLength) {
      final ok = ref.read(appLockProvider.notifier).verifyPin(_input);
      if (!ok) {
        setState(() {
          _showError = true;
          _input = '';
        });
      }
    }
  }

  void _onBackspace() {
    if (_input.isEmpty) return;
    setState(() {
      _showError = false;
      _input = _input.substring(0, _input.length - 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final lock = ref.watch(appLockProvider);
    final remaining = lock.lockRemaining;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              const Spacer(),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  'assets/images/s_logo.png',
                  width: 72,
                  height: 72,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 20),
              Text('ŞantiJET DEMİR', style: AppTypography.headlineMedium),
              const SizedBox(height: 8),
              Text(
                'Devam etmek için PIN girin',
                style: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted),
              ),
              const SizedBox(height: 28),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  color: _showError
                      ? AppColors.critical.withValues(alpha: 0.12)
                      : AppColors.surfaceElevated,
                  borderRadius: AppRadii.md,
                  border: Border.all(
                    color: _showError ? AppColors.critical : AppColors.border,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_pinLength, (i) {
                    final filled = i < _input.length;
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 10),
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: filled
                            ? AppColors.electricBlueLight
                            : AppColors.border,
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 12),
              if (lock.isTemporarilyLocked && remaining != null)
                Text(
                  'Çok fazla deneme. ${remaining.inSeconds} sn bekleyin.',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.warning),
                  textAlign: TextAlign.center,
                )
              else if (_showError)
                Text(
                  'Hatalı PIN (${lock.failedAttempts}/${AppLockNotifier.maxAttempts})',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.critical),
                )
              else if (ref.read(appLockProvider.notifier).isDefaultPin)
                Text(
                  'Varsayılan PIN ayarlı — Ayarlardan değiştirebilirsiniz',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
                  textAlign: TextAlign.center,
                )
              else
                const SizedBox.shrink(),
              const Spacer(),
              _PinPad(
                enabled: !lock.isTemporarilyLocked,
                onDigit: _onDigit,
                onBackspace: _onBackspace,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _PinPad extends StatelessWidget {
  const _PinPad({
    required this.enabled,
    required this.onDigit,
    required this.onBackspace,
  });

  final bool enabled;
  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;

  @override
  Widget build(BuildContext context) {
    const keys = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['', '0', '⌫'],
    ];

    return Column(
      children: keys.map((row) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: row.map((key) {
              if (key.isEmpty) {
                return const SizedBox(width: 88, height: 56);
              }
              final isBack = key == '⌫';
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Material(
                  color: AppColors.surfaceElevated,
                  borderRadius: AppRadii.md,
                  child: InkWell(
                    onTap: enabled
                        ? () => isBack ? onBackspace() : onDigit(key)
                        : null,
                    borderRadius: AppRadii.md,
                    child: SizedBox(
                      width: 72,
                      height: 56,
                      child: Center(
                        child: Text(
                          key,
                          style: AppTypography.headlineMedium.copyWith(
                            color: enabled
                                ? AppColors.textPrimary
                                : AppColors.textMuted,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }
}
