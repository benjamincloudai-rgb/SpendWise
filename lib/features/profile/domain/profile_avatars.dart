import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Resolved visual for a profile avatar (icon + color).
///
/// Mirrors the [CategoryVisual] pattern from the categories feature.
class ProfileAvatar {
  final String key;
  final IconData icon;
  final Color color;

  const ProfileAvatar({
    required this.key,
    required this.icon,
    required this.color,
  });
}

/// Canonical avatar options shown in the Edit Profile avatar picker.
///
/// The first entry is the default fallback avatar.
final List<ProfileAvatar> profileAvatarOptions = [
  ProfileAvatar(key: 'happy', icon: Icons.face_2, color: AppColors.primary),
  ProfileAvatar(
    key: 'cheerful',
    icon: Icons.face_3,
    color: Colors.orange.shade800,
  ),
  ProfileAvatar(key: 'cool', icon: Icons.face_4, color: Colors.blue.shade800),
  ProfileAvatar(key: 'sweet', icon: Icons.face_5, color: Colors.pink.shade800),
  ProfileAvatar(key: 'chill', icon: Icons.face_6, color: Colors.teal.shade800),
  ProfileAvatar(
    key: 'glow',
    icon: Icons.face_retouching_natural,
    color: Colors.purple.shade800,
  ),
  ProfileAvatar(key: 'joyful', icon: Icons.mood, color: Colors.amber.shade800),
  ProfileAvatar(
    key: 'classic',
    icon: Icons.account_circle,
    color: Colors.indigo.shade800,
  ),
];

/// The avatar key used when a user has not chosen one yet.
String get defaultProfileAvatarKey => profileAvatarOptions.first.key;

/// Resolves a [ProfileAvatar] from its stored key, falling back to the
/// first avatar for unknown or missing keys.
ProfileAvatar profileAvatarFor(String key) {
  for (final avatar in profileAvatarOptions) {
    if (avatar.key == key) return avatar;
  }
  return profileAvatarOptions.first;
}

/// Shared circular decoration for an avatar: a soft tint of the avatar color
/// plus an optional ring (e.g. the `primaryContainer` ring on the profile card).
///
/// Pass [ringWidth] of 0 (default) to omit the ring entirely.
BoxDecoration profileAvatarDecoration(
  String key, {
  Color? ringColor,
  double ringWidth = 0,
}) {
  final avatar = profileAvatarFor(key);
  return BoxDecoration(
    shape: BoxShape.circle,
    color: avatar.color.withValues(alpha: 0.12),
    border: ringWidth > 0
        ? Border.all(color: ringColor ?? AppColors.primaryContainer, width: ringWidth)
        : null,
  );
}
