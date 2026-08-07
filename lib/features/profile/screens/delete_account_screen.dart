import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:spendwise/core/widgets/blur_blob.dart';
import 'package:spendwise/core/widgets/entrance_animation.dart';
import 'package:spendwise/features/authentication/screens/login_screen.dart';
import 'package:spendwise/services/account_deletion_service.dart';
import 'package:spendwise/services/app_lock_controller.dart';

class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _passwordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isDeleting = false;

  // Strict colors matching the SpendWise design system
  Color get colorPrimary => Theme.of(context).colorScheme.primary;
  Color get colorBackground => Theme.of(context).colorScheme.surface;
  Color get colorSurfaceContainerLowest =>
      Theme.of(context).colorScheme.surfaceContainerLowest;
  Color get colorSurfaceContainerLow =>
      Theme.of(context).colorScheme.surfaceContainerLow;
  Color get colorOnSurfaceVariant => Theme.of(context).colorScheme.onSurfaceVariant;
  Color get colorOnSurface => Theme.of(context).colorScheme.onSurface;
  Color get colorPrimaryFixed => Theme.of(context).colorScheme.primaryFixed;
  Color get colorSecondaryFixed => Theme.of(context).colorScheme.secondaryFixed;

  // Secondary and Error colors matching specs
  Color get colorSecondary => Theme.of(context).colorScheme.secondary;
  Color get colorTertiary => Theme.of(context).colorScheme.tertiary;
  Color get colorError => Theme.of(context).colorScheme.error;
  Color get colorErrorContainer => Theme.of(context).colorScheme.errorContainer;
  Color get colorOnErrorContainer => Theme.of(context).colorScheme.onErrorContainer;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _onDeletePressed() async {
    if (!_formKey.currentState!.validate()) return;

    final confirmed = await _showConfirmDialog();
    if (confirmed != true || !mounted) return;

    await _deleteAccount();
  }

  Future<bool?> _showConfirmDialog() {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: colorSurfaceContainerLowest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        icon: Icon(Icons.warning_amber_rounded, color: colorError, size: 40),
        title: Text(
          'Delete your account?',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: colorOnSurface,
          ),
        ),
        content: Text(
          'Your profile, transactions, categories, budgets and settings will be '
          'permanently removed. This action cannot be undone.',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: colorOnSurfaceVariant,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colorSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              'Delete',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: colorError,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount() async {
    setState(() {
      _isDeleting = true;
    });

    try {
      await AccountDeletionService().deleteAccount(_passwordController.text);

      // Never cache passwords: clear the controller after success.
      _passwordController.clear();

      // Clear local device state so a future account is not locked behind
      // the deleted account's App Lock PIN.
      await AppLockController.instance.reset();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your account has been deleted.')),
      );
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } on AccountDeletionException catch (e) {
      if (!mounted) return;
      setState(() {
        _isDeleting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isDeleting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Something went wrong. Please try again.'),
        ),
      );
    }
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
            // --- Atmospheric Background Blurs (Aligned with other screens) ---
            Positioned(
              top: -100,
              right: -100,
              child: BlurBlob(
                color: colorPrimaryFixed.withValues(alpha: 0.1),
                size: 500,
                blur: 100,
              ),
            ),
            Positioned(
              bottom: -100,
              left: -100,
              child: BlurBlob(
                color: colorSecondaryFixed.withValues(alpha: 0.2),
                size: 400,
                blur: 80,
              ),
            ),

            // --- Scrollable Form Content ---
            Positioned.fill(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.only(
                  left: screenWidth * 0.05,
                  right: screenWidth * 0.05,
                  top: 76, // Clears top sticky App Bar
                  bottom: 40, // Secure padding at the bottom
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 16),
                          EntranceAnimation(
                            delayMs: 100,
                            child: _buildWarningCard(),
                          ),
                          const SizedBox(height: 16),
                          EntranceAnimation(
                            delayMs: 160,
                            child: _buildFormCard(),
                          ),
                          const SizedBox(height: 24),
                          EntranceAnimation(
                            delayMs: 240,
                            child: _buildDeleteButton(),
                          ),
                          const SizedBox(height: 16),
                          EntranceAnimation(
                            delayMs: 300,
                            child: _buildHelperText(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // --- Sticky Top App Bar ---
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

  // Header Component (Sticky Top App Bar)
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
              Text(
                'Delete Account',
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: colorSecondary,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Warning banner (destructive, irreversible)
  Widget _buildWarningCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorErrorContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorError.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, color: colorError, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Deleting your account is permanent. Your profile, transactions, '
              'categories, budgets and settings will be removed immediately and '
              'cannot be recovered.',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: colorOnSurface,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Form card with the password field
  Widget _buildFormCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Current Password',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: colorSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          _buildPasswordField(),
          const SizedBox(height: 12),
          Text(
            'Enter your current password to confirm you own this account.',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: colorSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: !_isPasswordVisible,
      textInputAction: TextInputAction.done,
      onFieldSubmitted: (_) => _onDeletePressed(),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your current password.';
        }
        return null;
      },
      decoration: InputDecoration(
        hintText: 'Enter your current password...',
        hintStyle: GoogleFonts.inter(color: colorTertiary, fontSize: 14),
        prefixIcon: Icon(Icons.lock_outline, color: colorOnSurfaceVariant, size: 22),
        suffixIcon: IconButton(
          icon: Icon(
            _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
            size: 20,
            color: colorOnSurfaceVariant,
          ),
          onPressed: () {
            setState(() {
              _isPasswordVisible = !_isPasswordVisible;
            });
          },
        ),
        filled: true,
        fillColor: colorSurfaceContainerLow,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorError, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorError, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorError, width: 2),
        ),
      ),
      style: GoogleFonts.inter(fontSize: 14, color: colorOnSurface),
    );
  }

  // Delete button with loading state (error colored)
  Widget _buildDeleteButton() {
    return ElevatedButton(
      onPressed: _isDeleting ? null : _onDeletePressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: colorError,
        foregroundColor: colorOnErrorContainer,
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 1,
      ),
      child: _isDeleting
          ? const SizedBox(
              height: 22,
              width: 22,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3,
              ),
            )
          : Text(
              'Delete Account',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
    );
  }

  Widget _buildHelperText() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text(
        'This will sign you out and return you to the login screen.',
        textAlign: TextAlign.center,
        style: GoogleFonts.inter(
          fontSize: 12,
          color: colorSecondary,
        ),
      ),
    );
  }
}
