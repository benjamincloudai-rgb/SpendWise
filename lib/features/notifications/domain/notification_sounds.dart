import 'package:flutter/material.dart';

/// A selectable notification sound shown across SpendWise.
class NotificationSoundOption {
  final String key;
  final String label;
  final IconData icon;

  const NotificationSoundOption({
    required this.key,
    required this.label,
    required this.icon,
  });
}

/// Canonical list of supported notification sounds.
///
/// The first entry (`default`) is the fallback when no sound is stored.
const List<NotificationSoundOption> notificationSoundOptions = [
  NotificationSoundOption(
    key: 'default',
    label: 'Default',
    icon: Icons.notifications_outlined,
  ),
  NotificationSoundOption(key: 'bell', label: 'Bell', icon: Icons.notifications_active),
  NotificationSoundOption(key: 'chime', label: 'Chime', icon: Icons.music_note),
  NotificationSoundOption(key: 'soft', label: 'Soft', icon: Icons.graphic_eq),
];

/// Resolves a [NotificationSoundOption] from its stored key, falling back to
/// the first option for unknown or missing keys.
NotificationSoundOption notificationSoundOptionFor(String key) {
  for (final option in notificationSoundOptions) {
    if (option.key == key) return option;
  }
  return notificationSoundOptions.first;
}

/// Returns the human-friendly label for [key], e.g. `Bell`.
String notificationSoundLabelFor(String key) =>
    notificationSoundOptionFor(key).label;
