import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:santijet_demir/core/security/pin_hasher.dart';
import 'package:santijet_demir/features/settings/providers/settings_provider.dart';

const _pinHashKey = 'app_lock_pin_hash';
const _pinVersionKey = 'app_lock_pin_version';
const _trustedDeviceKey = 'app_lock_trusted_device';
const _enabledKey = 'app_lock_enabled';
const _migratedOptionalLockKey = 'app_lock_optional_migrated';
const _currentPinVersion = 3;

/// Eski kurulumlarda zorunlu tutulan varsayılan PIN (migration için).
const _legacyDefaultPin = '220626';

const minPinLength = 4;
const maxPinLength = 8;

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
    _migrateToOptionalLock();
  }

  final Box _box;
  static const maxAttempts = 5;
  static const _lockDuration = Duration(seconds: 30);

  static bool _isEnabled(Box box) {
    return box.get(_enabledKey, defaultValue: false) as bool;
  }

  static bool _isTrustedDevice(Box box) {
    return box.get(_trustedDeviceKey, defaultValue: false) as bool;
  }

  Future<void> _setTrustedDevice(bool trusted) async {
    await _box.put(_trustedDeviceKey, trusted);
  }

  void _migrateToOptionalLock() {
    if (_box.get(_migratedOptionalLockKey, defaultValue: false) as bool) {
      return;
    }

    final enabled = _box.get(_enabledKey) as bool?;
    final hash = _box.get(_pinHashKey) as String?;

    // Eski sürüm: kilitleme varsayılan açık + fabrika PIN — şifresiz girişe geç.
    if (enabled == true &&
        hash != null &&
        PinHasher.verify(_legacyDefaultPin, hash)) {
      _box.put(_enabledKey, false);
      state = state.copyWith(isEnabled: false, isUnlocked: true);
    }

    if (!_box.containsKey(_enabledKey)) {
      _box.put(_enabledKey, false);
    }

    _box.put(_migratedOptionalLockKey, true);
    _box.put(_pinVersionKey, _currentPinVersion);

    if (!state.isEnabled) {
      state = state.copyWith(isUnlocked: true, clearLockedUntil: true);
    }
  }

  bool get hasPin => _box.containsKey(_pinHashKey);

  String? get _storedHash => _box.get(_pinHashKey) as String?;

  static bool isValidPin(String pin) {
    final trimmed = pin.trim();
    return trimmed.length >= minPinLength && trimmed.length <= maxPinLength;
  }

  bool verifyPin(String pin) {
    if (state.isTemporarilyLocked) return false;

    final hash = _storedHash;
    if (hash == null) return false;

    final valid = PinHasher.verify(pin, hash);
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

  Future<bool> enableWithPin(String newPin) async {
    if (!isValidPin(newPin)) return false;

    await _box.put(_pinHashKey, PinHasher.hash(newPin.trim()));
    await _box.put(_pinVersionKey, _currentPinVersion);
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

  Future<bool> disable({required String currentPin}) async {
    final pin = currentPin.trim();
    final hash = _storedHash;
    if (hash == null || pin.isEmpty || !PinHasher.verify(pin, hash)) {
      return false;
    }

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

  Future<bool> changePin({
    required String currentPin,
    required String newPin,
  }) async {
    if (!isValidPin(newPin)) return false;
    final hash = _storedHash;
    if (hash == null || !PinHasher.verify(currentPin, hash)) return false;

    await _box.put(_pinHashKey, PinHasher.hash(newPin.trim()));
    await _setTrustedDevice(true);
    state = state.copyWith(
      isUnlocked: true,
      failedAttempts: 0,
      clearLockedUntil: true,
    );
    return true;
  }
}
