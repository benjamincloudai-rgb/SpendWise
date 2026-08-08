import 'dart:async';
import 'dart:typed_data';

import 'package:pdfrx/pdfrx.dart';

/// Thrown when the user cancels the password prompt for an encrypted PDF.
///
/// This is a deliberate, silent cancellation — the same behaviour as dismissing
/// the file picker — and must never surface a SnackBar or error UI.
class PdfImportCancellationException implements Exception {
  const PdfImportCancellationException();
}

/// Thrown when a PDF's text layer cannot be extracted.
class PdfTextExtractionException implements Exception {
  final String message;

  const PdfTextExtractionException(this.message);

  @override
  String toString() => 'PdfTextExtractionException: $message';
}

/// Thin adapter around the pdfrx package — the only component that touches the
/// PDF library itself.
///
/// Extracts the embedded text layer of a text-based PDF. Image-only (scanned)
/// documents simply yield empty text; that is left for the caller to detect so
/// the statement parser stays pure Dart and unit-testable.
class PdfTextExtractor {
  /// Matches the `/Encrypt <obj> <gen> R` reference carried by encrypted PDFs.
  static final RegExp _encryptRef = RegExp(
    r'/Encrypt\s+\d+\s+\d+\s+R',
    caseSensitive: false,
  );

  /// Extracts and concatenates the text layer of every page of [bytes].
  ///
  /// Encrypted PDFs prompt through [passwordProvider] exactly as pdfrx
  /// intends — the empty-password attempt happens first
  /// (`firstAttemptByEmptyPassword`), and the provider is only consulted when
  /// the document genuinely requests a password.
  ///
  /// Throws a [PdfTextExtractionException] with a user-friendly message when
  /// the document is password-protected, corrupt, or cannot be opened/read, and
  /// a [PdfImportCancellationException] when the user dismisses the password
  /// prompt.
  Future<String> extractText(
    Uint8List bytes, {
    FutureOr<String?> Function()? passwordProvider,
  }) async {
    final encrypted = _looksEncrypted(bytes);

    final PdfDocument document;
    try {
      document = await PdfDocument.openData(
        bytes,
        passwordProvider: encrypted ? passwordProvider : null,
        firstAttemptByEmptyPassword: true,
      );
    } on PdfPasswordException catch (error) {
      if (encrypted && _isProviderCancellation(error)) {
        throw const PdfImportCancellationException();
      }
      throw const PdfTextExtractionException(
        'This PDF could not be read. Please choose a valid PDF file.',
      );
    } on PdfException catch (_) {
      throw const PdfTextExtractionException(
        'This PDF could not be read. Please choose a valid PDF file.',
      );
    }

    try {
      final buffer = StringBuffer();
      for (final page in document.pages) {
        final text = await page.loadStructuredText();
        if (text.fullText.trim().isNotEmpty) buffer.writeln(text.fullText);
      }
      return buffer.toString();
    } catch (_) {
      throw const PdfTextExtractionException(
        'This PDF could not be read. Please choose a valid PDF file.',
      );
    } finally {
      await document.dispose();
    }
  }

  /// pdfrx throws this exact message when its password provider yields `null`
  /// (i.e. the user pressed Cancel in the dialog).
  bool _isProviderCancellation(PdfPasswordException error) =>
      error.message.contains('No password supplied');

  /// Lightweight pre-check for an encryption dictionary.
  ///
  /// Encrypted PDFs reference their encryption dictionary from the trailer via
  /// `/Encrypt <obj> <gen> R`. Scanning the raw bytes means a
  /// [passwordProvider] is only handed to pdfrx when one is genuinely needed:
  /// a corrupt but unencrypted file must fail with the plain "could not be
  /// read" message instead of ever showing the password dialog.
  bool _looksEncrypted(Uint8List bytes) =>
      _encryptRef.hasMatch(String.fromCharCodes(bytes));
}
