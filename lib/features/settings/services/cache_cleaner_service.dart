import 'dart:io';

import 'package:flutter/painting.dart';

import '../../export/services/transaction_export_service.dart';

/// Outcome of a cache clear attempt, used by the UI to pick the right feedback.
enum CacheClearStatus { success, failure }

/// Result returned from [CacheCleanerService.clear] so the caller can show a
/// confirmation or an error without inspecting exceptions.
class CacheClearResult {
  const CacheClearResult.success()
      : status = CacheClearStatus.success,
        message =
            'Cache cleared successfully. Temporary files have been removed.';

  const CacheClearResult.failure()
      : status = CacheClearStatus.failure,
        message = 'Could not clear the cache. Please try again.';

  final CacheClearStatus status;
  final String message;
}

/// Removes only temporary runtime data created by SpendWise.
///
/// This never touches Firestore, transactions, categories, budgets, the user
/// profile, authentication, or any persisted preferences. It only clears:
///
///   * Flutter's in-memory image cache.
///   * Temporary files SpendWise has written under
///     [Directory.systemTemp] using the naming convention below.
///
/// ## Temp-file naming convention
///
/// Every feature should write its throwaway files inside the namespaced
/// `spendwise` subfolder of [Directory.systemTemp] (e.g. `.../temp/spendwise/`).
/// The cleaner removes that whole folder recursively, so current and future
/// features (CSV/Excel exports, PDF import, OCR scratch images, ...) are
/// automatically covered without editing this service.
///
/// For backwards compatibility, files that older features wrote flat inside
/// the temp root (matching the export suffix `_spendwise_transactions.csv`)
/// are also removed. Only files SpendWise created are matched — unrelated
/// system or third-party temp files are never touched.
///
/// Mirrors [TransactionExportService]: never throws, and reports problems
/// through a [CacheClearResult] instead.
class CacheCleanerService {
  CacheCleanerService();

  /// Name of the namespaced temp folder owned by SpendWise.
  static const String _spendWiseTempDirName = 'spendwise';

  /// Suffix of flat legacy temp files written directly under the temp root.
  static const String _legacyTempFileSuffix =
      '_${TransactionExportService.fileName}';

  /// Clears SpendWise temporary data. Never throws; problems are reported
  /// through the returned [CacheClearResult].
  Future<CacheClearResult> clear() async {
    try {
      _clearFlutterImageCache();
      await _removeSpendWiseTempFiles();
      return const CacheClearResult.success();
    } catch (_) {
      return const CacheClearResult.failure();
    }
  }

  /// Empties Flutter's in-memory decoded-image cache.
  void _clearFlutterImageCache() {
    final imageCache = PaintingBinding.instance.imageCache;
    imageCache.clear();
    imageCache.clearLiveImages();
  }

  /// Removes every temporary file SpendWise has created under the system temp
  /// directory. Each step is best-effort so a locked or in-use file on
  /// Windows can never fail the whole operation.
  Future<void> _removeSpendWiseTempFiles() async {
    final tempRoot = Directory.systemTemp;
    if (!await tempRoot.exists()) return;

    final spendWiseDir = Directory(
      '${tempRoot.path}${Platform.pathSeparator}$_spendWiseTempDirName',
    );

    // 1. Namespaced folder — covers all current and future SpendWise features.
    if (await spendWiseDir.exists()) {
      try {
        await spendWiseDir.delete(recursive: true);
      } catch (_) {
        // Best effort: retry on the next cache clear.
      }
    }

    // 2. Legacy flat files written directly under the temp root.
    await for (final entity in tempRoot.list()) {
      if (entity is File &&
          entity.path.endsWith(_legacyTempFileSuffix)) {
        try {
          await entity.delete();
        } catch (_) {
          // Best effort: skip files that are currently in use.
        }
      }
    }
  }
}
