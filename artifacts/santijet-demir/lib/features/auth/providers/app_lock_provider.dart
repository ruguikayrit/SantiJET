import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:santijet_demir/core/security/pin_hasher.dart';
import 'package:santijet_demir/features/settings/providers/settings_provider.dart';

const _pinHashKey = 'app_lock_pin_hash';
const _pinVersionKey = 'app_lock_pin_version';
const _trustedDeviceKey = 'app_lock_trusted_device';
const _enabledKey = 'app_lock_enabled';
const _currentPinVersion = 2;
/// Varsayılan PIN: 22.06.26 → 220626
const defaultAppPin = '220626';
const defaultPinLength = 6;

final appLockProvider =
    StateNotifierProvider<AppLockNotifier, AppLockState>((ref) {
  final box = ref.watch(settingsBoxProvider);
  return AppLockNotifier(box);
});

class AppLockState {
  const AppLockState({
    required this.isEnabled,
    required this.isUnlocked,
    this.failedAttempts = 0,
    this.lockedUntil,
  });

  final bool isEnabled;
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
    bool? isEnabled,
    bool? isUnlocked,
    int? failedAttempts,
    DateTime? lockedUntil,
    bool clearLockedUntil = false,
  }) {
    return AppLockState(
      isEnabled: isEnabled ?? this.isEnabled,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      failedAttempts: failedAttempts ?? this.failedAttempts,
      lockedUntil: clearLockedUntil ? null : (lockedUntil ?? this.lockedUntil),
    );
  }
}

class AppLockNotifier extends StateNotifier<AppLockState> {
  AppLockNotifier(this._box)
      : super(AppLockState(
          isEnabled: _isEnabled(_box),
          isUnlocked: !_isEnabled(_box) || _isTrustedDevice(_box),
        )) {
    _ensureDefaultPin();
  }

  final Box _box;
  static const maxAttempts = 5;
  static const _lockDuration = Duration(seconds: 30);

  static bool _isEnabled(Box box) {
    return box.get(_enabledKey, defaultValue: true) as bool;
  }

  static bool _isTrustedDevice(Box box) {
    return box.get(_trustedDeviceKey, defaultValue: false) as bool;
  }

  Future<void> _setTrustedDevice(bool trusted) async {
    await _box.put(_trustedDeviceKey, trusted);
  }

  void _ensureDefaultPin() {
    final version = _box.get(_pinVersionKey, defaultValue: 0) as int;
    if (!_box.containsKey(_pinHashKey) || version < _currentPinVersion) {
      _box.put(_pinHashKey, PinHasher.hash(defaultAppPin));
      _box.put(_pinVersionKey, _currentPinVersion);
    }
  }

  String get _storedHash => _box.get(_pinHashKey) as String;

  bool verifyPin(String pin) {
    if (state.isTemporarilyLocked) return false;

    final valid = PinHasher.verify(pin, _storedHash);
    if (valid) {
      _setTrustedDevice(true);
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
    if (!state.isEnabled) return;
    _setTrustedDevice(false);
    state = state.copyWith(isUnlocked: false, failedAttempts: 0);
  }

  Future<bool> setEnabled(bool enabled, {String? currentPin}) async {
    if (enabled) {
      await _box.put(_enabledKey, true);
      await _setTrustedDevice(true);
      state = state.copyWith(
        isEnabled: true,
        isUnlocked: true,
        failedAttempts: 0,
        clearLockedUntil: true,
      );
      return true;
    }

    final pin = currentPin?.trim() ?? '';
    if (pin.isEmpty || !PinHasher.verify(pin, _storedHash)) return false;

    await _box.put(_enabledKey, false);
    await _setTrustedDevice(true);
    state = state.copyWith(
      isEnabled: false,
      isUnlocked: true,
      failedAttempts: 0,
      clearLockedUntil: true,
    );
    return true;
  }

  bool get isDefaultPin => PinHasher.verify(defaultAppPin, _storedHash);

  Future<bool> changePin({
    required String currentPin,
    required String newPin,
  }) async {
    if (newPin.length < 4 || newPin.length > 8) return false;
    if (!PinHasher.verify(currentPin, _storedHash)) return false;

    await _box.put(_pinHashKey, PinHasher.hash(newPin));
    await _setTrustedDevice(true);
    state = state.copyWith(isUnlocked: true, failedAttempts: 0, clearLockedUntil: true);
    return true;
  }
}
