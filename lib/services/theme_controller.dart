import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// App-wide dark-mode state backed by `users/{uid}.darkMode`.
///
/// Mirrors [CurrencyController]: a single Firestore subscription loads the
/// persisted preference once and reuses it everywhere via
/// [ThemeController.instance]. The app-level [AnimatedBuilder] (see
/// `main.dart`) rebuilds `MaterialApp` on change so the active theme swaps
/// instantly, without per-screen Firestore queries.
class ThemeController extends ChangeNotifier {
  ThemeController._();

  /// Global accessor for the single theme controller instance.
  static final ThemeController instance = ThemeController._();

  bool _isDarkMode = false;
  bool _loaded = false;

  /// Whether dark mode is currently active (defaults to light mode).
  bool get isDarkMode => _isDarkMode;

  /// Whether the persisted preference has been loaded at least once.
  bool get loaded => _loaded;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _subscription;

  String? get _uid => _auth.currentUser?.uid;

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) =>
      _firestore.collection('users').doc(uid);

  /// Loads the persisted dark-mode preference once, then keeps it in sync via
  /// a single Firestore subscription. Idempotent; safe to call again after
  /// login.
  ///
  /// Await this before showing HomeShell so the correct theme is active on
  /// first frame (no flicker).
  Future<void> init() async {
    final uid = _uid;
    if (uid == null) return;

    final docRef = _userDoc(uid);

    try {
      final snapshot = await docRef.get();
      _applyDarkMode(_readDarkMode(snapshot.data()));
    } catch (_) {
      // Offline or missing doc: keep the default; the subscription resyncs.
    } finally {
      _subscription ??= docRef.snapshots().listen((snapshot) {
        _applyDarkMode(_readDarkMode(snapshot.data()));
      });
    }
  }

  bool _readDarkMode(Map<String, dynamic>? data) {
    final raw = data?['darkMode'];
    return raw is bool ? raw : false;
  }

  void _applyDarkMode(bool value) {
    if (value == _isDarkMode) {
      _loaded = true;
      return;
    }
    _isDarkMode = value;
    _loaded = true;
    notifyListeners();
  }

  /// Persists [value] to `users/{uid}.darkMode` and updates the UI
  /// immediately. Reuses the existing user document; no new collection.
  Future<void> setDarkMode(bool value) async {
    _applyDarkMode(value);

    final uid = _uid;
    if (uid == null) return;

    try {
      await _userDoc(uid).set(
        {
          'darkMode': value,
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
