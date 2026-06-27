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
  String _input = '';
  bool _showError = false;

  void _onDigit(String digit) {
    final lock = ref.read(appLockProvider);
    if (lock.isTemporarilyLocked) return;
    if (_input.length >= maxPinLength) return;

    setState(() {
      _showError = false;
      _input += digit;
    });
  }

  void _onBackspace() {
    if (_input.isEmpty) return;
    setState(() {
      _showError = false;
      _input = _input.substring(0, _input.length - 1);
    });
  }

  void _submitPin() {
    if (_input.length < minPinLength) return;

    final ok = ref.read(appLockProvider.notifier).verifyPin(_input);
    if (!ok) {
      setState(() {
        _showError = true;
        _input = '';
      });
    }
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
                  children: List.generate(maxPinLength, (i) {
                    final filled = i < _input.length;
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      width: 12,
                      height: 12,
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
              else
                Text(
                  '$minPinLength–$maxPinLength haneli PIN',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
                  textAlign: TextAlign.center,
                ),
              const Spacer(),
              _PinPad(
                enabled: !lock.isTemporarilyLocked,
                canSubmit: _input.length >= minPinLength,
                onDigit: _onDigit,
                onBackspace: _onBackspace,
                onSubmit: _submitPin,
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
    required this.canSubmit,
    required this.onDigit,
    required this.onBackspace,
    required this.onSubmit,
  });

  final bool enabled;
  final bool canSubmit;
  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    const keys = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['✓', '0', '⌫'],
    ];

    return Column(
      children: keys.map((row) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: row.map((key) {
              final isSubmit = key == '✓';
              final isBack = key == '⌫';
              final isAction = isSubmit || isBack;
              final actionEnabled =
                  enabled && (isBack || (isSubmit && canSubmit));

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Material(
                  color: isSubmit && canSubmit
                      ? AppColors.electricBlue.withValues(alpha: 0.18)
                      : AppColors.surfaceElevated,
                  borderRadius: AppRadii.md,
                  child: InkWell(
                    onTap: actionEnabled
                        ? () {
                            if (isBack) {
                              onBackspace();
                            } else if (isSubmit) {
                              onSubmit();
                            } else {
                              onDigit(key);
                            }
                          }
                        : (!isAction && enabled ? () => onDigit(key) : null),
                    borderRadius: AppRadii.md,
                    child: SizedBox(
                      width: 72,
                      height: 56,
                      child: Center(
                        child: Text(
                          key,
                          style: AppTypography.headlineMedium.copyWith(
                            color: actionEnabled || (!isAction && enabled)
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
