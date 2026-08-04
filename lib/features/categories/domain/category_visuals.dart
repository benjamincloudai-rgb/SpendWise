import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Canonical category icon keys and their Material [IconData]s.
///
/// These are the exact pairs previously hardcoded in the manage-categories
/// picker and in per-screen `_iconForKey` / `_keyForIcon` methods.
const List<(String, IconData)> categoryIconOptions = [
  ('restaurant', Icons.restaurant),
  ('shopping_bag', Icons.shopping_bag),
  ('directions_car', Icons.directions_car),
  ('movie', Icons.movie),
  ('local_hospital', Icons.local_hospital),
  ('home', Icons.home),
  ('school', Icons.school),
  ('flight', Icons.flight),
  ('pets', Icons.pets),
  ('savings', Icons.savings),
];

/// Maps a stored category icon key to its Material icon.
///
/// Matches the previous `_iconForKey` implementations.
IconData categoryIconFor(String key) {
  switch (key) {
    case 'restaurant':
      return Icons.restaurant;
    case 'shopping_bag':
      return Icons.shopping_bag;
    case 'directions_car':
      return Icons.directions_car;
    case 'movie':
      return Icons.movie;
    case 'local_hospital':
      return Icons.local_hospital;
    case 'home':
      return Icons.home;
    case 'school':
      return Icons.school;
    case 'flight':
      return Icons.flight;
    case 'pets':
      return Icons.pets;
    case 'savings':
      return Icons.savings;
    default:
      return Icons.category_outlined;
  }
}

/// Maps a Material icon back to its stored category icon key.
///
/// Matches the previous `_keyForIcon` implementation.
String categoryKeyFor(IconData icon) {
  if (icon == Icons.restaurant) return 'restaurant';
  if (icon == Icons.shopping_bag) return 'shopping_bag';
  if (icon == Icons.directions_car) return 'directions_car';
  if (icon == Icons.movie) return 'movie';
  if (icon == Icons.local_hospital) return 'local_hospital';
  if (icon == Icons.home) return 'home';
  if (icon == Icons.school) return 'school';
  if (icon == Icons.flight) return 'flight';
  if (icon == Icons.pets) return 'pets';
  if (icon == Icons.savings) return 'savings';
  return 'category';
}

/// Resolved visual styling for a category (icon + colors).
///
/// Replaces the private `_CategoryStyle` classes.
class CategoryVisual {
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;

  const CategoryVisual({
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
  });
}

/// Resolves a visual style for a category by keyword.
///
/// Canonical source of truth: the 17-branch mapper previously used in
/// [transactions_screen] and [recent_transactions_widget]. All other modules
/// should adopt this visual language.
CategoryVisual categoryVisualFor(String name) {
  final normalized = name.toLowerCase().trim();

  IconData icon = Icons.attach_money;
  Color iconColor = AppColors.primary;
  Color bgColor = AppColors.primaryContainer.withValues(alpha: 0.15);

  if (normalized.contains('food') ||
      normalized.contains('dining') ||
      normalized.contains('restaurant')) {
    icon = Icons.restaurant;
    iconColor = Colors.orange.shade800;
    bgColor = Colors.orange.shade50;
  } else if (normalized.contains('transport') ||
      normalized.contains('commute')) {
    icon = Icons.directions_car_outlined;
    iconColor = Colors.blue.shade800;
    bgColor = Colors.blue.shade50;
  } else if (normalized.contains('shopping')) {
    icon = Icons.shopping_bag_outlined;
    iconColor = Colors.pink.shade800;
    bgColor = Colors.pink.shade50;
  } else if (normalized.contains('bills') ||
      normalized.contains('utilities')) {
    icon = Icons.electrical_services_outlined;
    iconColor = Colors.red.shade800;
    bgColor = Colors.red.shade50;
  } else if (normalized.contains('entertainment') ||
      normalized.contains('movie')) {
    icon = Icons.movie_outlined;
    iconColor = Colors.purple.shade800;
    bgColor = Colors.purple.shade50;
  } else if (normalized.contains('healthcare') ||
      normalized.contains('medical')) {
    icon = Icons.local_hospital_outlined;
    iconColor = Colors.teal.shade800;
    bgColor = Colors.teal.shade50;
  } else if (normalized.contains('travel') || normalized.contains('flight')) {
    icon = Icons.flight_outlined;
    iconColor = Colors.cyan.shade800;
    bgColor = Colors.cyan.shade50;
  } else if (normalized.contains('education') ||
      normalized.contains('school')) {
    icon = Icons.school_outlined;
    iconColor = Colors.brown.shade800;
    bgColor = Colors.brown.shade50;
  } else if (normalized.contains('groceries')) {
    icon = Icons.shopping_basket_outlined;
    iconColor = Colors.amber.shade900;
    bgColor = Colors.amber.shade50;
  } else if (normalized.contains('salary')) {
    icon = Icons.account_balance_wallet_outlined;
    iconColor = AppColors.primary;
    bgColor = AppColors.primaryContainer.withValues(alpha: 0.15);
  } else if (normalized.contains('freelance') ||
      normalized.contains('work')) {
    icon = Icons.work_outline;
    iconColor = Colors.indigo.shade800;
    bgColor = Colors.indigo.shade50;
  } else if (normalized.contains('investment')) {
    icon = Icons.trending_up_outlined;
    iconColor = Colors.lightGreen.shade800;
    bgColor = Colors.lightGreen.shade50;
  } else if (normalized.contains('business')) {
    icon = Icons.storefront_outlined;
    iconColor = Colors.blueGrey.shade800;
    bgColor = Colors.blueGrey.shade50;
  } else if (normalized.contains('gift')) {
    icon = Icons.card_giftcard_outlined;
    iconColor = Colors.pinkAccent.shade700;
    bgColor = Colors.pink.shade50;
  } else if (normalized.contains('cashback')) {
    icon = Icons.savings_outlined;
    iconColor = Colors.deepOrange.shade800;
    bgColor = Colors.deepOrange.shade50;
  } else if (normalized.contains('transfer')) {
    icon = Icons.swap_horiz;
    iconColor = Colors.blue.shade800;
    bgColor = Colors.blue.shade50;
  } else if (normalized.contains('savings')) {
    icon = Icons.savings_outlined;
    iconColor = Colors.green.shade800;
    bgColor = Colors.green.shade50;
  }

  return CategoryVisual(
    icon: icon,
    iconColor: iconColor,
    backgroundColor: bgColor,
  );
}
