import 'package:flutter/material.dart';
import 'theme.dart';

class AppCategory {
  final int id;
  final String name;
  final IconData icon;
  final Color color;

  const AppCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
  });
}

class AppConstants {
  static const String appName = 'SpendWise';
  static const String currency = '₹';
  static const String version = '1.0.0';

  static const List<AppCategory> categories = [
    AppCategory(
        id: 1,
        name: 'Food & Dining',
        icon: Icons.restaurant_outlined,
        color: AppColors.catFood),
    AppCategory(
        id: 2,
        name: 'Travel',
        icon: Icons.directions_car_outlined,
        color: AppColors.catTravel),
    AppCategory(
        id: 3,
        name: 'Shopping',
        icon: Icons.shopping_bag_outlined,
        color: AppColors.catShopping),
    AppCategory(
        id: 4,
        name: 'Bills & Utilities',
        icon: Icons.receipt_long_outlined,
        color: AppColors.catBills),
    AppCategory(
        id: 5,
        name: 'Health',
        icon: Icons.favorite_outline,
        color: AppColors.catHealth),
    AppCategory(
        id: 6,
        name: 'Entertainment',
        icon: Icons.movie_outlined,
        color: AppColors.catEntertainment),
    AppCategory(
        id: 7,
        name: 'Education',
        icon: Icons.school_outlined,
        color: AppColors.catEducation),
    AppCategory(
        id: 8,
        name: 'Other',
        icon: Icons.more_horiz,
        color: AppColors.catOther),
  ];

  static AppCategory getCategoryById(int id) {
    return categories.firstWhere(
      (c) => c.id == id,
      orElse: () => categories.last,
    );
  }

  static AppCategory getCategoryByName(String name) {
    return categories.firstWhere(
      (c) => c.name == name,
      orElse: () => categories.last,
    );
  }

  // Quick filter options for dashboard
  static const List<String> quickFilters = [
    'Today',
    'This Week',
    'This Month',
    'Last 30 Days',
    'Custom Range',
  ];
}

class AppUtils {
  static void showToast(BuildContext context, String message) {
    ScaffoldMessenger.of(context).clearSnackBars(); // Clears old ones instantly
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white, // White text pops perfectly against your primary color
            fontSize: 14, 
            fontWeight: FontWeight.w600, 
            letterSpacing: 0.3,
          ),
        ),
        // USING YOUR APP'S PRIMARY BRAND COLOR
        backgroundColor: AppColors.primary, 
        behavior: SnackBarBehavior.floating,
        elevation: 6, 
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        margin: const EdgeInsets.only(bottom: 40, left: 60, right: 60), 
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        duration: const Duration(milliseconds: 1500),
      ),
    );
  }
}