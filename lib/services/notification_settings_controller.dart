import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../features/notifications/domain/notification_sounds.dart';

/// App-wide notification preferences backed by `users/{uid}.notificationSettings`.
///
/// Mirrors [CurrencyController]: a single Firestore subscription loads the
/// persisted preferences once and reuses them everywhere via
/// [NotificationSettingsController.instance]. Every preference is persisted
/// immediately (optimistically) to the existing user document — no separate
/// collection and no Save button. Callers read the getters during build;
/// [notifyListeners] refreshes the Notifications screen on change.
class NotificationSettingsController extends ChangeNotifier {
  NotificationSettingsController._();

  /// Global accessor for the single notification-settings controller instance.
  static final NotificationSettingsController instance =
      NotificationSettingsController._();

  static const int _defaultReminderMinutes = 20 * 60; // 8:00 PM

  bool _budgetAlerts = true;
  bool _dailyReminder = false;
  bool _weeklySummary = true;
  bool _monthlyReport = true;
  bool _smartInsights = true;
  int _reminderMinutes = _defaultReminderMinutes;
  String _notificationSound = 'default';
  bool _loaded = false;

  bool get budgetAlerts => _budgetAlerts;
  bool get dailyReminder => _dailyReminder;
  bool get weeklySummary => _weeklySummary;
  bool get monthlyReport => _monthlyReport;
  bool get smartInsights => _smartInsights;

  /// Whether the persisted preferences have been loaded at least once.
  bool get loaded => _loaded;

  /// The selected daily reminder time.
  TimeOfDay get reminderTime => TimeOfDay(
    hour: _reminderMinutes ~/ 60,
    minute: _reminderMinutes % 60,
  );

  /// Human-friendly reminder label, e.g. `8:30 PM`.
  String get reminderTimeLabel => formatTimeLabel(reminderTime);

  /// Currently selected notification-sound key.
  String get notificationSound => _notificationSound;

  /// Human-friendly notification-sound label, e.g. `Bell`.
  String get notificationSoundLabel =>
      notificationSoundLabelFor(_notificationSound);

  /// Whether every customizable notification toggle is off.
  bool get allNotificationsOff =>
      !_budgetAlerts &&
      !_dailyReminder &&
      !_weeklySummary &&
      !_monthlyReport &&
      !_smartInsights;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _subscription;

  String? get _uid => _auth.currentUser?.uid;

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) =>
      _firestore.collection('users').doc(uid);

  /// Loads the persisted notification settings once, then keeps them in sync
  /// via a single Firestore subscription. Idempotent; safe to call again
  /// after login.
  ///
  /// Await this before rendering the toggles so no temporary defaults flash.
  Future<void> init() async {
    final uid = _uid;
    if (uid == null) return;

    final docRef = _userDoc(uid);

    try {
      final snapshot = await docRef.get();
      _applySettings(_readSettings(snapshot.data()));
    } catch (_) {
      // Offline or missing doc: keep the defaults; the subscription resyncs.
    } finally {
      _subscription ??= docRef.snapshots().listen((snapshot) {
        _applySettings(_readSettings(snapshot.data()));
      });
    }
  }

  Map<String, dynamic> _readSettings(Map<String, dynamic>? data) {
    final raw = data?['notificationSettings'];
    return raw is Map<String, dynamic> ? raw : <String, dynamic>{};
  }

  void _applySettings(Map<String, dynamic> settings) {
    final wasLoaded = _loaded;
    var changed = false;

    if (settings['budgetAlerts'] is bool) {
      final value = settings['budgetAlerts'] as bool;
      if (value != _budgetAlerts) {
        _budgetAlerts = value;
        changed = true;
      }
    }
    if (settings['dailyReminder'] is bool) {
      final value = settings['dailyReminder'] as bool;
      if (value != _dailyReminder) {
        _dailyReminder = value;
        changed = true;
      }
    }
    if (settings['weeklySummary'] is bool) {
      final value = settings['weeklySummary'] as bool;
      if (value != _weeklySummary) {
        _weeklySummary = value;
        changed = true;
      }
    }
    if (settings['monthlyReport'] is bool) {
      final value = settings['monthlyReport'] as bool;
      if (value != _monthlyReport) {
        _monthlyReport = value;
        changed = true;
      }
    }
    if (settings['smartInsights'] is bool) {
      final value = settings['smartInsights'] as bool;
      if (value != _smartInsights) {
        _smartInsights = value;
        changed = true;
      }
    }
    if (settings['reminderMinutes'] is int) {
      final value = settings['reminderMinutes'] as int;
      if (value >= 0 && value < 24 * 60 && value != _reminderMinutes) {
        _reminderMinutes = value;
        changed = true;
      }
    }
    if (settings['notificationSound'] is String) {
      final value = settings['notificationSound'] as String;
      if (value != _notificationSound &&
          notificationSoundOptionFor(value).key == value) {
        _notificationSound = value;
        changed = true;
      }
    }

    _loaded = true;
    if (changed || !wasLoaded) notifyListeners();
  }

  /// Persists [updates] into `users/{uid}.notificationSettings`, merging so
  /// sibling keys are preserved. Reuses the existing user document.
  Future<void> _update(Map<String, dynamic> updates) async {
    final uid = _uid;
    if (uid == null) return;

    try {
      await _userDoc(uid).set(
        {
          'notificationSettings': updates,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } catch (_) {
      // Keep the local selection; the snapshot subscription resyncs.
    }
  }

  void setBudgetAlerts(bool value) {
    if (value == _budgetAlerts) return;
    _budgetAlerts = value;
    notifyListeners();
    _update({'budgetAlerts': value});
  }

  void setDailyReminder(bool value) {
    if (value == _dailyReminder) return;
    _dailyReminder = value;
    notifyListeners();
    _update({'dailyReminder': value});
  }

  void setWeeklySummary(bool value) {
    if (value == _weeklySummary) return;
    _weeklySummary = value;
    notifyListeners();
    _update({'weeklySummary': value});
  }

  void setMonthlyReport(bool value) {
    if (value == _monthlyReport) return;
    _monthlyReport = value;
    notifyListeners();
    _update({'monthlyReport': value});
  }

  void setSmartInsights(bool value) {
    if (value == _smartInsights) return;
    _smartInsights = value;
    notifyListeners();
    _update({'smartInsights': value});
  }

  /// Persists [time] as minutes since midnight inside `notificationSettings`.
  void setReminderTime(TimeOfDay time) {
    final minutes = time.hour * 60 + time.minute;
    if (minutes == _reminderMinutes) return;
    _reminderMinutes = minutes;
    notifyListeners();
    _update({'reminderMinutes': minutes});
  }

  /// Persists [key] (one of the [notificationSoundOptions] keys).
  void setNotificationSound(String key) {
    if (key == _notificationSound) return;
    _notificationSound = key;
    notifyListeners();
    _update({'notificationSound': key});
  }

  /// Turns every customizable notification toggle back on.
  void enableAll() {
    if (_budgetAlerts &&
        _dailyReminder &&
        _weeklySummary &&
        _monthlyReport &&
        _smartInsights) {
      return;
    }
    _budgetAlerts = true;
    _dailyReminder = true;
    _weeklySummary = true;
    _monthlyReport = true;
    _smartInsights = true;
    notifyListeners();
    _update({
      'budgetAlerts': true,
      'dailyReminder': true,
      'weeklySummary': true,
      'monthlyReport': true,
      'smartInsights': true,
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

/// Formats [time] as a 12-hour label, e.g. `8:30 PM`.
String formatTimeLabel(TimeOfDay time) {
  final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
  final minute = time.minute.toString().padLeft(2, '0');
  final period = time.period == DayPeriod.am ? 'AM' : 'PM';
  return '$hour:$minute $period';
}
