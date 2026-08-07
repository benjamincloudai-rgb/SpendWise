import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App-wide App Lock state persisted locally via [SharedPreferences].
///
/// Mirrors [ThemeController], [CurrencyController] and
/// [NotificationSettingsController]: a single [ChangeNotifier] singleton
/// reused everywhere through [AppLockController.instance]. Unlike those
/// controllers it never touches Firestore — the lock is a per-device feature.
///
/// The PIN is never stored in plaintext; only `SHA256(salt + ":" + pin)` is
/// persisted. After 5 consecutive incorrect attempts the PIN entry is
/// disabled for 30 seconds (both values are persisted so the lockout survives
/// process death).
class AppLockController extends ChangeNotifier {
  AppLockController._();

  /// Global accessor for the single app-lock controller instance.
  static final AppLockController instance = AppLockController._();

  static const int _maxFailedAttempts = 5;
  static const Duration _lockoutDuration = Duration(seconds: 30);

  static const String _kEnabled = 'app_lock_enabled';
  static const String _kPinHash = 'app_lock_pin_hash';
  static const String _kSalt = 'app_lock_salt';
  static const String _kFailedAttempts = 'app_lock_failed_attempts';
  static const String _kLockedUntil = 'app_lock_locked_until';

  bool _enabled = false;
  bool _isLocked = false;
  bool _initialized = false;
  String? _pinHash;
  String? _salt;
  int _failedAttempts = 0;
  DateTime? _lockedUntil;

  /// Whether App Lock is switched on.
  bool get enabled => _enabled;

  /// Whether the lock overlay should be visible right now.
  bool get isLocked => _isLocked;

  /// Whether persisted state has been loaded at least once.
  bool get initialized => _initialized;

  /// Whether a PIN has been created.
  bool get hasPin => _pinHash != null;

  /// Whether PIN entry is currently frozen by the lockout window.
  bool get isLockedOut {
    final until = _lockedUntil;
    if (until == null) return false;
    return DateTime.now().isBefore(until);
  }

  /// Whole seconds remaining in the current lockout window (0 if none).
  int get remainingLockoutSeconds {
    final until = _lockedUntil;
    if (until == null) return 0;
    final remaining = until.difference(DateTime.now());
    return remaining.isNegative ? 0 : remaining.inSeconds;
  }

  /// Loads the persisted App Lock state once. Call before `runApp` so the
  /// lock can engage on the first frame when enabled.
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _enabled = prefs.getBool(_kEnabled) ?? false;
    _pinHash = prefs.getString(_kPinHash);
    _salt = prefs.getString(_kSalt);
    _failedAttempts = prefs.getInt(_kFailedAttempts) ?? 0;
    final raw = prefs.getString(_kLockedUntil);
    _lockedUntil = raw == null ? null : DateTime.tryParse(raw);
    if (_lockedUntil != null && !DateTime.now().isBefore(_lockedUntil!)) {
      _lockedUntil = null;
      _failedAttempts = 0;
    }
    _initialized = true;
    if (_enabled && _pinHash != null) {
      _isLocked = true;
    }
    notifyListeners();
  }

  /// Turns App Lock on and stores the salted hash of [pin].
  Future<bool> enable(String pin) async {
    await _storePin(pin);
    _enabled = true;
    _failedAttempts = 0;
    _lockedUntil = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kEnabled, true);
    await prefs.setInt(_kFailedAttempts, 0);
    await prefs.remove(_kLockedUntil);
    notifyListeners();
    return true;
  }

  /// Turns App Lock off, but only after [pin] matches the stored PIN.
  Future<bool> disable(String pin) async {
    final valid = await _validatePin(pin);
    if (!valid) return false;

    _enabled = false;
    _pinHash = null;
    _salt = null;
    _failedAttempts = 0;
    _lockedUntil = null;
    _isLocked = false;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kEnabled);
    await prefs.remove(_kPinHash);
    await prefs.remove(_kSalt);
    await prefs.remove(_kFailedAttempts);
    await prefs.remove(_kLockedUntil);
    notifyListeners();
    return true;
  }

  /// Replaces the PIN, verifying [currentPin] first.
  Future<bool> changePin(String currentPin, String newPin) async {
    final valid = await _validatePin(currentPin);
    if (!valid) return false;

    await _storePin(newPin);
    notifyListeners();
    return true;
  }

  /// Checks [pin] against the stored hash. A correct PIN also unlocks the
  /// app. Wrong attempts count towards the 5-strike lockout.
  Future<bool> verifyPin(String pin) async {
    final valid = await _validatePin(pin);
    if (valid && _isLocked) {
      _isLocked = false;
      notifyListeners();
    }
    return valid;
  }

  /// Engages the lock. A no-op unless App Lock is enabled and a PIN exists.
  void lock() {
    if (_enabled && _pinHash != null && !_isLocked) {
      _isLocked = true;
      notifyListeners();
    }
  }

  /// Removes the lock overlay without verifying anything.
  void unlock() {
    if (_isLocked) {
      _isLocked = false;
      notifyListeners();
    }
  }

  /// Clears an expired lockout window and resets the attempt counter.
  Future<void> clearExpiredLockout() async {
    final until = _lockedUntil;
    if (until != null && !DateTime.now().isBefore(until)) {
      _lockedUntil = null;
      _failedAttempts = 0;
      await _persistAttempts();
      notifyListeners();
    }
  }

  Future<bool> _validatePin(String pin) async {
    await clearExpiredLockout();
    if (isLockedOut || _pinHash == null) return false;

    if (_hashWithSalt(_salt ?? '', pin) == _pinHash) {
      if (_failedAttempts > 0 || _lockedUntil != null) {
        _failedAttempts = 0;
        _lockedUntil = null;
        await _persistAttempts();
      }
      return true;
    }

    _failedAttempts += 1;
    if (_failedAttempts >= _maxFailedAttempts) {
      _lockedUntil = DateTime.now().add(_lockoutDuration);
    }
    await _persistAttempts();
    notifyListeners();
    return false;
  }

  Future<void> _storePin(String pin) async {
    final salt = _generateSalt();
    _salt = salt;
    _pinHash = _hashWithSalt(salt, pin);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kSalt, salt);
    await prefs.setString(_kPinHash, _pinHash!);
  }

  Future<void> _persistAttempts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kFailedAttempts, _failedAttempts);
    final until = _lockedUntil;
    if (until != null) {
      await prefs.setString(_kLockedUntil, until.toIso8601String());
    } else {
      await prefs.remove(_kLockedUntil);
    }
  }

  String _generateSalt() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return base64UrlEncode(bytes);
  }

  String _hashWithSalt(String salt, String pin) {
    return sha256.convert(utf8.encode('$salt:$pin')).toString();
  }
}
