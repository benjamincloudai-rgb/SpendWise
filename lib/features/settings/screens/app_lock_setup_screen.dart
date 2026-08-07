import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:spendwise/core/widgets/blur_blob.dart';
import 'package:spendwise/core/widgets/entrance_animation.dart';
import 'package:spendwise/features/settings/widgets/pin_pad.dart';
import 'package:spendwise/services/app_lock_controller.dart';

enum _Flow { manage, enable, disable, change }

enum _Step { currentPin, newPin, confirmPin }

/// Settings screen for enabling, disabling and changing the App Lock PIN.
class AppLockSetupScreen extends StatefulWidget {
  const AppLockSetupScreen({super.key});

  @override
  State<AppLockSetupScreen> createState() => _AppLockSetupScreenState();
}

class _AppLockSetupScreenState extends State<AppLockSetupScreen> {
  final AppLockController _controller = AppLockController.instance;

  _Flow _flow = _Flow.manage;
  _Step _step = _Step.currentPin;
  String _enteredPin = '';
  String _newPin = '';
  String _currentPin = '';
  bool _isLoading = false;
  String? _error;

  Color get colorPrimary => Theme.of(context).colorScheme.primary;
  Color get colorBackground => Theme.of(context).colorScheme.surface;
  Color get colorSurfaceContainerLowest =>
      Theme.of(context).colorScheme.surfaceContainerLowest;
  Color get colorSurfaceContainerLow =>
      Theme.of(context).colorScheme.surfaceContainerLow;
  Color get colorSecondary => Theme.of(context).colorScheme.secondary;
  Color get colorOnSurface => Theme.of(context).colorScheme.onSurface;
  Color get colorOnSurfaceVariant =>
      Theme.of(context).colorScheme.onSurfaceVariant;
  Color get colorOutlineVariant => Theme.of(context).colorScheme.outlineVariant;
  Color get colorError => Theme.of(context).colorScheme.error;
  Color get colorErrorContainer => Theme.of(context).colorScheme.errorContainer;

  @override
  void initState() {
    super.initState();
    if (!_controller.enabled) {
      _flow = _Flow.enable;
      _step = _Step.newPin;
    }
  }

  void _onDigit(String digit) {
    if (_isLoading) return;
    if (_enteredPin.length >= 4) return;
    setState(() {
      _enteredPin += digit;
      _error = null;
    });
    if (_enteredPin.length == 4) {
      _handlePinComplete();
    }
  }

  void _onBackspace() {
    if (_enteredPin.isEmpty || _isLoading) return;
    setState(() {
      _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
      _error = null;
    });
  }

  Future<void> _handlePinComplete() async {
    final pin = _enteredPin;
    switch (_flow) {
      case _Flow.enable:
        if (_step == _Step.newPin) {
          setState(() {
            _newPin = pin;
            _enteredPin = '';
            _step = _Step.confirmPin;
          });
        } else {
          if (pin == _newPin) {
            await _submitEnable();
          } else {
            setState(() {
              _error = 'PINs do not match. Try again.';
              _newPin = '';
              _enteredPin = '';
              _step = _Step.newPin;
            });
          }
        }
        break;

      case _Flow.change:
        switch (_step) {
          case _Step.currentPin:
            final valid = await _controller.verifyPin(pin);
            if (!mounted) return;
            if (valid) {
              setState(() {
                _currentPin = pin;
                _enteredPin = '';
                _error = null;
                _step = _Step.newPin;
              });
            } else {
              setState(() {
                _enteredPin = '';
                _error = 'Incorrect PIN. Try again.';
              });
            }
            break;

          case _Step.newPin:
            setState(() {
              _newPin = pin;
              _enteredPin = '';
              _error = null;
              _step = _Step.confirmPin;
            });
            break;

          case _Step.confirmPin:
            if (pin == _newPin) {
              await _submitChange();
            } else {
              setState(() {
                _error = 'PINs do not match. Try again.';
                _newPin = '';
                _enteredPin = '';
                _step = _Step.newPin;
              });
            }
            break;
        }
        break;

      case _Flow.disable:
        await _submitDisable(pin);
        break;

      case _Flow.manage:
        break;
    }
  }

  Future<void> _submitEnable() async {
    setState(() => _isLoading = true);
    await _controller.enable(_newPin);
    if (!mounted) return;
    setState(() => _isLoading = false);
    _showSnackBar('App Lock enabled');
    Navigator.pop(context);
  }

  Future<void> _submitChange() async {
    setState(() => _isLoading = true);
    final ok = await _controller.changePin(_currentPin, _newPin);
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (ok) {
      _showSnackBar('PIN updated successfully');
      Navigator.pop(context);
    } else {
      setState(() {
        _error = 'Could not update PIN. Try again.';
        _enteredPin = '';
        _step = _Step.currentPin;
      });
    }
  }

  Future<void> _submitDisable(String pin) async {
    setState(() => _isLoading = true);
    final ok = await _controller.disable(pin);
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (ok) {
      _showSnackBar('App Lock disabled');
      Navigator.pop(context);
    } else {
      setState(() {
        _error = 'Incorrect PIN. Try again.';
        _enteredPin = '';
      });
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message, style: GoogleFonts.inter(fontSize: 14)),
        ),
      );
  }

  void _startChange() {
    setState(() {
      _flow = _Flow.change;
      _step = _Step.currentPin;
      _enteredPin = '';
      _error = null;
    });
  }

  Future<void> _confirmDisable() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: colorSurfaceContainerLowest,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Text(
            'Disable App Lock?',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.bold,
              color: colorOnSurface,
            ),
          ),
          content: Text(
            'You will need to enter your current PIN to disable App Lock.',
            style: GoogleFonts.inter(color: colorSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(
                  color: colorSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(
                'Disable',
                style: GoogleFonts.inter(
                  color: colorError,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      _flow = _Flow.disable;
      _step = _Step.currentPin;
      _enteredPin = '';
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;

    return Scaffold(
      backgroundColor: colorBackground,
      body: SafeArea(
        bottom: false,
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
            Positioned.fill(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.only(
                  left: screenWidth * 0.05,
                  right: screenWidth * 0.05,
                  top: 92,
                  bottom: 40,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        EntranceAnimation(
                          delayMs: 100,
                          child: _flow == _Flow.manage
                              ? _buildManageSection()
                              : _buildPinEntrySection(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: EntranceAnimation(
                delayMs: 50,
                child: _buildHeader(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    return Container(
      color: colorBackground.withValues(alpha: 0.95),
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.05,
        vertical: 16,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.arrow_back, color: colorOnSurface, size: 28),
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'App Lock',
                      style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: colorSecondary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _flow == _Flow.manage
                          ? 'Manage your app lock'
                          : _stepTitle(),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: colorSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _stepTitle() {
    switch (_flow) {
      case _Flow.enable:
        return _step == _Step.newPin
            ? 'Create your PIN'
            : 'Confirm your PIN';
      case _Flow.disable:
        return 'Enter your current PIN';
      case _Flow.change:
        switch (_step) {
          case _Step.currentPin:
            return 'Enter your current PIN';
          case _Step.newPin:
            return 'Create a new PIN';
          case _Step.confirmPin:
            return 'Confirm your new PIN';
        }
      case _Flow.manage:
        return 'Manage your app lock';
    }
  }

  String _stepSubtitle() {
    switch (_flow) {
      case _Flow.enable:
        return _step == _Step.newPin
            ? 'Set a 4-digit PIN to lock SpendWise.'
            : 'Enter the same PIN again.';
      case _Flow.disable:
        return 'Your PIN is required to turn off App Lock.';
      case _Flow.change:
        switch (_step) {
          case _Step.currentPin:
            return 'Verify your identity to change the PIN.';
          case _Step.newPin:
            return 'Choose a new 4-digit PIN.';
          case _Step.confirmPin:
            return 'Enter the new PIN again.';
        }
      case _Flow.manage:
        return 'Manage your app lock';
    }
  }

  Widget _buildManageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 8),
          child: Text(
            'SECURITY',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: colorOnSurfaceVariant,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: colorSurfaceContainerLowest,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: colorSurfaceContainerLow),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildManageRow(
                icon: Icons.lock_outline,
                iconColor: colorPrimary,
                iconBgColor: colorPrimary.withValues(alpha: 0.1),
                title: 'App Lock is enabled',
                trailing: Icon(
                  Icons.check_circle,
                  color: colorPrimary,
                  size: 20,
                ),
              ),
              _buildDivider(),
              _buildManageRow(
                icon: Icons.password_outlined,
                title: 'Change PIN',
                onTap: _startChange,
              ),
              _buildDivider(),
              _buildManageRow(
                icon: Icons.lock_open_outlined,
                iconColor: colorError,
                iconBgColor: colorErrorContainer.withValues(alpha: 0.5),
                textColor: colorError,
                title: 'Disable App Lock',
                onTap: _confirmDisable,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildManageRow({
    required IconData icon,
    required String title,
    VoidCallback? onTap,
    Widget? trailing,
    Color? iconColor,
    Color? iconBgColor,
    Color? textColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconBgColor ?? colorPrimary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor ?? colorPrimary, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: textColor ?? colorOnSurface,
                ),
              ),
            ),
            if (trailing != null)
              trailing
            else
              Icon(Icons.chevron_right, color: colorOutlineVariant, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      height: 1,
      color: colorOutlineVariant.withValues(alpha: 0.2),
    );
  }

  Widget _buildPinEntrySection() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _stepTitle(),
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: colorOnSurface,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _stepSubtitle(),
              style: GoogleFonts.inter(
                fontSize: 14,
                color: colorOnSurfaceVariant,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 36),
            Center(child: PinDots(length: _enteredPin.length)),
            SizedBox(
              height: 60,
              child: Center(
                child: _error == null
                    ? const SizedBox.shrink()
                    : Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: colorError,
                        ),
                      ),
              ),
            ),
            if (_isLoading)
              Center(
                child: CircularProgressIndicator(color: colorPrimary),
              )
            else
              PinPad(
                onDigitPressed: _onDigit,
                onBackspace: _onBackspace,
              ),
          ],
        ),
      ),
    );
  }
}
