import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:santijet_demir/core/security/pin_hasher.dart';
import 'package:santijet_demir/features/settings/providers/settings_provider.dart';

const _pinHashKey = 'app_lock_pin_hash';
const defaultAppPin = '1234';

final appLockProvider =
    StateNotifierProvider<AppLockNotifier, AppLockState>((ref) {
  final box = ref.watch(settingsBoxProvider);
  return AppLockNotifier(box);
});

class AppLockState {
  const AppLockState({
    required this.isUnlocked,
    this.failedAttempts = 0,
    this.lockedUntil,
  });

  final bool isUnlocked;
  final int failedAttempts;
  final DateTime? lockedUntil;

  bool get isTemporarilyLocked {
    if (lockedUntil == null) return false;
    return DateTime.now().isBefore(lockedUntil!);
  }

  Duration? get lockRemaining {
    if (lockedUntil == null) return null;
    final remaining = lockedUntil!.difference(DateTime.now());
    return remaining.isNegative ? null : remaining;
  }

  AppLockState copyWith({
    bool? isUnlocked,
    int? failedAttempts,
    DateTime? lockedUntil,
    bool clearLockedUntil = false,
  }) {
    return AppLockState(
      isUnlocked: isUnlocked ?? this.isUnlocked,
      failedAttempts: failedAttempts ?? this.failedAttempts,
      lockedUntil: clearLockedUntil ? null : (lockedUntil ?? this.lockedUntil),
    );
  }
}

class AppLockNotifier extends StateNotifier<AppLockState> {
  AppLockNotifier(this._box) : super(const AppLockState(isUnlocked: false)) {
    _ensureDefaultPin();
  }

  final Box _box;
  static const maxAttempts = 5;
  static const _lockDuration = Duration(seconds: 30);

  void _ensureDefaultPin() {
    if (!_box.containsKey(_pinHashKey)) {
      _box.put(_pinHashKey, PinHasher.hash(defaultAppPin));
    }
  }

  String get _storedHash => _box.get(_pinHashKey) as String;

  bool verifyPin(String pin) {
    if (state.isTemporarilyLocked) return false;

    final valid = PinHasher.verify(pin, _storedHash);
    if (valid) {
      state = state.copyWith(
        isUnlocked: true,
        failedAttempts: 0,
        clearLockedUntil: true,
      );
      return true;
    }

    final attempts = state.failedAttempts + 1;
    if (attempts >= maxAttempts) {
      state = state.copyWith(
        failedAttempts: 0,
        lockedUntil: DateTime.now().add(_lockDuration),
      );
    } else {
      state = state.copyWith(failedAttempts: attempts);
    }
    return false;
  }

  void lock() {
    state = state.copyWith(isUnlocked: false, failedAttempts: 0);
  }

  bool get isDefaultPin => PinHasher.verify(defaultAppPin, _storedHash);

  Future<bool> changePin({
    required String currentPin,
    required String newPin,
  }) async {
    if (newPin.length < 4 || newPin.length > 6) return false;
    if (!PinHasher.verify(currentPin, _storedHash)) return false;

    await _box.put(_pinHashKey, PinHasher.hash(newPin));
    state = state.copyWith(isUnlocked: true, failedAttempts: 0, clearLockedUntil: true);
    return true;
  }
}
