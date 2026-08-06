import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../core/currency/currencies.dart';

/// App-wide currency state backed by `users/{uid}.currencyCode`.
///
/// A single Firestore subscription loads the persisted currency once and
/// reuses it everywhere through [CurrencyController.instance]. Callers read
/// [code] / [symbol] / [format] during build; [notifyListeners] triggers the
/// app-level [AnimatedBuilder] (see HomeShell) so the UI updates when the
/// selected currency changes, without per-screen Firestore queries.
class CurrencyController extends ChangeNotifier {
  CurrencyController._();

  /// Global accessor for the single currency controller instance.
  static final CurrencyController instance = CurrencyController._();

  static const String _defaultCode = 'INR';

  String _code = _defaultCode;
  bool _loaded = false;

  /// Currently selected ISO currency code (defaults to `INR`).
  String get code => _code;

  /// Whether the persisted currency has been loaded at least once.
  bool get loaded => _loaded;

  /// Display symbol for the selected currency.
  String get symbol => currencySymbolFor(_code);

  /// Formats [amount] using the currently selected currency.
  String format(double amount) => formatCurrency(amount, _code);

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _subscription;

  String? get _uid => _auth.currentUser?.uid;

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) =>
      _firestore.collection('users').doc(uid);

  /// Loads the persisted currency once, then keeps it in sync via a single
  /// Firestore subscription. Idempotent; safe to call again after login.
  ///
  /// Await this before showing HomeShell so the correct symbol is rendered
  /// on first frame (no flicker).
  Future<void> init() async {
    final uid = _uid;
    if (uid == null) return;

    final docRef = _userDoc(uid);

    try {
      final snapshot = await docRef.get();
      _applyCode(_readCode(snapshot.data()));
    } catch (_) {
      // Offline or missing doc: keep the default; the subscription resyncs.
    } finally {
      _subscription ??= docRef.snapshots().listen((snapshot) {
        _applyCode(_readCode(snapshot.data()));
      });
    }
  }

  String _readCode(Map<String, dynamic>? data) {
    final raw = data?['currencyCode'];
    if (raw is String && raw.trim().isNotEmpty) return raw;
    return _defaultCode;
  }

  void _applyCode(String code) {
    if (code == _code) {
      _loaded = true;
      return;
    }
    _code = code;
    _loaded = true;
    notifyListeners();
  }

  /// Persists [code] to `users/{uid}.currencyCode` and updates the UI
  /// immediately. Reuses the existing user document; no new collection.
  Future<void> setCode(String code) async {
    final uid = _uid;
    if (uid == null) return;

    _applyCode(code);

    try {
      await _userDoc(uid).set(
        {
          'currencyCode': code,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } catch (_) {
      // Keep the local selection; the snapshot subscription resyncs.
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
