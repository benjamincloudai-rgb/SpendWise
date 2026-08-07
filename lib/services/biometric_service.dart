import 'package:local_auth/local_auth.dart';

enum BiometricKind {
  face,
  fingerprint,
  generic,
}

/// Thin wrapper around `local_auth` that isolates all biometric plugin
/// interaction from the App Lock feature. Unlock decisions stay in
/// [AppLockController]; this service only reports capability and runs the
/// system prompt. Every method degrades gracefully so the PIN screen is
/// always the fallback.
class BiometricService {
  BiometricService._();

  /// Global accessor for the single biometric service instance.
  static final BiometricService instance = BiometricService._();

  final LocalAuthentication _auth = LocalAuthentication();

  /// Whether the device can perform biometric authentication and has at least
  /// one enrolled biometric right now. Never throws; any platform or plugin
  /// failure is treated as "not supported".
  Future<bool> isSupported() async {
    try {
      if (!await _auth.isDeviceSupported()) return false;
      if (!await _auth.canCheckBiometrics) return false;
      return (await _auth.getAvailableBiometrics()).isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// The biometric kind to advertise in the unlock retry action. Falls back to
  /// [BiometricKind.generic] when the platform reports nothing specific.
  Future<BiometricKind> getPreferredKind() async {
    try {
      final available = await _auth.getAvailableBiometrics();
      if (available.contains(BiometricType.face)) return BiometricKind.face;
      if (available.contains(BiometricType.fingerprint) ||
          available.contains(BiometricType.strong)) {
        return BiometricKind.fingerprint;
      }
    } catch (_) {
      // Fall through to the generic label.
    }
    return BiometricKind.generic;
  }

  /// Human-readable label for [kind], used on the lock screen.
  String labelFor(BiometricKind kind) {
    switch (kind) {
      case BiometricKind.face:
        return 'Face ID';
      case BiometricKind.fingerprint:
        return 'Fingerprint';
      case BiometricKind.generic:
        return 'Biometrics';
    }
  }

  /// Runs the system biometric prompt. Returns true only on a successful
  /// authentication. Cancellations, failures, missing enrollment and plugin
  /// exceptions all return false so callers simply fall back to the PIN.
  Future<bool> authenticate({required String reason}) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        biometricOnly: true,
        sensitiveTransaction: false,
      );
    } catch (_) {
      return false;
    }
  }
}
