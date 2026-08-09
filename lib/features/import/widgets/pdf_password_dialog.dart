import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Drives a single, persistent password dialog across the multiple attempts a
/// password-protected PDF may require.
///
/// pdfrx asks its `passwordProvider` for a password every time an open attempt
/// fails. Rather than popping and re-pushing a dialog per attempt, this
/// controller keeps one dialog on screen and flips it between three states:
///
///  * asking (obscured field, autofocused, no error)
///  * loading (spinner while pdfrx validates the submitted password)
///  * retry ("Incorrect password. Please try again." + the field again)
///
/// The dialog is dismissed exactly twice: when the PDF opens successfully, or
/// when the user presses Cancel. Passwords only ever live in memory — nothing
/// here stores, logs, or persists them, and they are discarded as soon as the
/// import finishes or is cancelled.
class PdfPasswordDialogController {
  PdfPasswordDialogController({required this._context});

  final BuildContext _context;

  /// True after a submitted password was rejected, which surfaces the inline
  /// "Incorrect password. Please try again." error.
  final ValueNotifier<bool> showError = ValueNotifier<bool>(false);

  /// True while pdfrx is retrying to open the document with a submitted
  /// password, which surfaces the in-dialog loading state.
  final ValueNotifier<bool> isLoading = ValueNotifier<bool>(false);

  Completer<String?> _password = Completer<String?>();
  BuildContext? _dialogRouteContext;
  bool _dialogOpen = false;
  bool _firstAttempt = true;
  bool _cancelRequested = false;

  /// Invoked by the pdfrx `passwordProvider` every time a password is needed.
  ///
  /// Returns the password the user submits on this attempt, or `null` when the
  /// user cancels — pdfrx then treats it as a silent cancellation.
  Future<String?> awaitPassword() {
    if (_firstAttempt) {
      _firstAttempt = false;
      _openDialog();
    } else {
      showError.value = true;
      isLoading.value = false;
    }
    _password = Completer<String?>();
    if (_cancelRequested) {
      _cancelRequested = false;
      _password.complete(null);
    }
    return _password.future;
  }

  /// Called when the user presses Unlock in the dialog.
  void submit(String password) {
    if (_password.isCompleted) return;
    isLoading.value = true;
    _password.complete(password);
  }

  /// Called when the user presses Cancel in the dialog. Silently aborts the
  /// import exactly like dismissing the file picker would.
  void cancel() {
    if (_password.isCompleted) {
      _cancelRequested = true;
    } else {
      _password.complete(null);
    }
  }

  void _openDialog() {
    if (_dialogOpen) return;
    if (!_context.mounted) {
      _password.complete(null);
      return;
    }
    _dialogOpen = true;
    unawaited(
      showDialog<void>(
        context: _context,
        barrierDismissible: false,
        builder: (dialogContext) {
          _dialogRouteContext = dialogContext;
          return PdfPasswordDialog(controller: this);
        },
      ),
    );
  }

  /// Dismisses the dialog once the import has finished — either the PDF opened
  /// successfully or the user cancelled.
  void closeDialog() {
    if (_dialogOpen && _dialogRouteContext != null) {
      _dialogOpen = false;
      Navigator.of(_dialogRouteContext!, rootNavigator: true).pop();
    }
  }
}

/// Modal dialog that asks for a password-protected PDF's password.
///
/// Provides the obscured [TextField] with a show/hide toggle, autofocus,
/// Enter-to-submit, an inline error and an in-dialog loading spinner. It never
/// closes itself on an incorrect password — only
/// [PdfPasswordDialogController.closeDialog] (success/cancel) dismisses it.
class PdfPasswordDialog extends StatefulWidget {
  const PdfPasswordDialog({super.key, required this.controller});

  final PdfPasswordDialogController controller;

  @override
  State<PdfPasswordDialog> createState() => _PdfPasswordDialogState();
}

class _PdfPasswordDialogState extends State<PdfPasswordDialog> {
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _passwordFocus = FocusNode();
  bool _obscureText = true;

  @override
  void initState() {
    super.initState();
    widget.controller.showError.addListener(_handleStateChanged);
    widget.controller.isLoading.addListener(_handleStateChanged);
  }

  @override
  void dispose() {
    widget.controller.showError.removeListener(_handleStateChanged);
    widget.controller.isLoading.removeListener(_handleStateChanged);
    _passwordController.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  /// Rebuilds for the new error/loading state and, on a rejected password,
  /// clears the field and refocuses so the user can retry immediately.
  void _handleStateChanged() {
    if (!mounted) return;
    setState(_passwordController.clear);
    _passwordFocus.requestFocus();
  }

  void _submit() {
    final password = _passwordController.text;
    if (password.isEmpty) return;
    widget.controller.submit(password);
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final bool showError = widget.controller.showError.value;
    final bool isLoading = widget.controller.isLoading.value;

    return AlertDialog(
      icon: Icon(Icons.lock_outline, size: 32, color: colorScheme.primary),
      title: Text(
        'Enter PDF Password',
        style: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: colorScheme.onSurface,
          letterSpacing: -0.4,
        ),
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'This bank statement is password protected. '
                'Enter the password to continue.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _passwordController,
                focusNode: _passwordFocus,
                autofocus: true,
                obscureText: _obscureText,
                enabled: !isLoading,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: colorScheme.onSurface,
                ),
                decoration: InputDecoration(
                  labelText: 'Password',
                  labelStyle: GoogleFonts.inter(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  prefixIcon: Icon(
                    Icons.password,
                    color: colorScheme.secondary,
                  ),
                  suffixIcon: IconButton(
                    onPressed: () =>
                        setState(() => _obscureText = !_obscureText),
                    icon: Icon(
                      _obscureText ? Icons.visibility : Icons.visibility_off,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              if (showError) ...[
                const SizedBox(height: 12),
                Text(
                  'Incorrect password. Please try again.',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.error,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Text(
                "If you're unsure of the password, check the email or SMS from "
                'your bank explaining how the statement password is formed.',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: widget.controller.cancel,
          child: Text(
            'Cancel',
            style: GoogleFonts.inter(color: colorScheme.onSurfaceVariant),
          ),
        ),
        FilledButton(
          onPressed: isLoading ? null : _submit,
          child: isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text('Unlock', style: GoogleFonts.inter()),
        ),
      ],
    );
  }
}
