import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:spendwise/core/widgets/blur_blob.dart';
import 'package:spendwise/core/widgets/entrance_animation.dart';
import 'package:spendwise/features/settings/widgets/pin_pad.dart';
import 'package:spendwise/services/app_lock_controller.dart';
import 'package:spendwise/services/biometric_service.dart';

/// Full-screen lock overlay shown on top of the authenticated app whenever
/// App Lock is engaged. Unlocking simply removes the overlay; the navigation
/// stack underneath is never touched.
class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final AppLockController _controller = AppLockController.instance;
  String _enteredPin = '';
  bool _showError = false;
  bool _isVerifying = false;
  bool _biometricsAvailable = false;
  bool _isAuthenticating = false;
  BiometricKind _biometricKind = BiometricKind.generic;
  Timer? _countdownTimer;

  Color get colorPrimary => Theme.of(context).colorScheme.primary;
  Color get colorBackground => Theme.of(context).colorScheme.surface;
  Color get colorSurfaceContainerLowest =>
      Theme.of(context).colorScheme.surfaceContainerLowest;
  Color get colorSecondary => Theme.of(context).colorScheme.secondary;
  Color get colorOnSurface => Theme.of(context).colorScheme.onSurface;
  Color get colorError => Theme.of(context).colorScheme.error;

  @override
  void initState() {
    super.initState();
    if (_controller.isLockedOut) {
      _startCountdown();
    }
    _maybePromptBiometrics();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_controller.remainingLockoutSeconds <= 0) {
        timer.cancel();
        _controller.clearExpiredLockout();
        if (mounted) setState(() {});
      } else {
        setState(() {});
      }
    });
  }

  void _onDigit(String digit) {
    if (_isVerifying || _controller.isLockedOut) return;
    if (_enteredPin.length >= 4) return;
    setState(() {
      _enteredPin += digit;
      _showError = false;
    });
    if (_enteredPin.length == 4) {
      _verify();
    }
  }

  void _onBackspace() {
    if (_enteredPin.isEmpty || _isVerifying) return;
    setState(() {
      _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
      _showError = false;
    });
  }

  Future<void> _verify() async {
    final pin = _enteredPin;
    setState(() {
      _enteredPin = '';
      _isVerifying = true;
    });
    final valid = await _controller.verifyPin(pin);
    if (!mounted) return;
    setState(() {
      _isVerifying = false;
      _showError = !valid;
    });
    if (!valid && _controller.isLockedOut) {
      _startCountdown();
    }
  }

  String? get _statusMessage {
    if (_controller.isLockedOut) {
      return 'Too many incorrect attempts.\n'
          'Try again in ${_controller.remainingLockoutSeconds} seconds.';
    }
    if (_showError) {
      return 'Incorrect PIN. Try again.';
    }
    return null;
  }

  /// Offers biometrics exactly once per lock engagement, on the first frame
  /// after the overlay becomes visible. Unsupported or unenrolled devices
  /// silently fall back to the PIN keypad.
  Future<void> _maybePromptBiometrics() async {
    if (!_controller.biometricEnabled) return;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final supported = await BiometricService.instance.isSupported();
      if (!mounted || !supported) return;
      final kind = await BiometricService.instance.getPreferredKind();
      if (!mounted) return;
      setState(() {
        _biometricsAvailable = true;
        _biometricKind = kind;
      });
      await _authenticateBiometrics();
    });
  }

  /// Runs the system biometric prompt. On success the existing unlock flow is
  /// reused; failures and cancellations simply leave the PIN screen active and
  /// never touch the PIN attempt counter.
  Future<void> _authenticateBiometrics() async {
    if (_isAuthenticating || !_biometricsAvailable) return;
    setState(() => _isAuthenticating = true);
    final label = BiometricService.instance.labelFor(_biometricKind);
    final ok = await BiometricService.instance.authenticate(
      reason: 'Unlock SpendWise with $label',
    );
    if (!mounted) return;
    setState(() => _isAuthenticating = false);
    if (ok) {
      _controller.unlock();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final lockedOut = _controller.isLockedOut;

    return Scaffold(
      backgroundColor: colorBackground,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: -100,
              right: -100,
              child: BlurBlob(
                color: Theme.of(context)
                    .colorScheme
                    .primaryFixed
                    .withValues(alpha: 0.1),
                size: 500,
                blur: 100,
              ),
            ),
            Positioned(
              bottom: -100,
              left: -100,
              child: BlurBlob(
                color: Theme.of(context)
                    .colorScheme
                    .secondaryFixed
                    .withValues(alpha: 0.2),
                size: 400,
                blur: 80,
              ),
            ),
            Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.08),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: EntranceAnimation(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 96,
                          height: 96,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: colorSurfaceContainerLowest,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Theme.of(context)
                                  .colorScheme
                                  .outlineVariant
                                  .withValues(alpha: 0.4),
                            ),
                          ),
                          child: Image.asset(
                            'assets/images/spendwise_logo.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'SpendWise',
                          style: GoogleFonts.inter(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: colorOnSurface,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Enter your PIN to unlock',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: colorSecondary,
                          ),
                        ),
                        const SizedBox(height: 28),
                        PinDots(length: _enteredPin.length),
                        SizedBox(
                          height: 60,
                          child: Center(
                            child: _statusMessage == null
                                ? const SizedBox.shrink()
                                : Text(
                                    _statusMessage!,
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: colorError,
                                    ),
                                  ),
                          ),
                        ),
                        if (_biometricsAvailable && !_isAuthenticating)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: TextButton.icon(
                              onPressed: _authenticateBiometrics,
                              icon: Icon(
                                Icons.fingerprint,
                                color: colorPrimary,
                                size: 22,
                              ),
                              label: Text(
                                'Use ${BiometricService.instance.labelFor(_biometricKind)} Again',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: colorPrimary,
                                ),
                              ),
                            ),
                          ),
                        PinPad(
                          disabled: lockedOut || _isVerifying,
                          onDigitPressed: _onDigit,
                          onBackspace: _onBackspace,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
