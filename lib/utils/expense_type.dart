import 'package:flutter/material.dart';

enum ExpenseTag {
  personal,
  household,
  family,
  work,
  health,
  other,
}

class ExpenseTagHelper {
  static String label(ExpenseTag tag) {
    switch (tag) {
      case ExpenseTag.personal:
        return 'Personal';
      case ExpenseTag.household:
        return 'Household';
      case ExpenseTag.family:
        return 'Family';
      case ExpenseTag.work:
        return 'Work';
      case ExpenseTag.health:
        return 'Health';
      case ExpenseTag.other:
        return 'Other';
    }
  }

  static IconData icon(ExpenseTag tag) {
    switch (tag) {
      case ExpenseTag.personal:
        return Icons.person_outline;
      case ExpenseTag.household:
        return Icons.home_outlined;
      case ExpenseTag.family:
        return Icons.family_restroom_outlined;
      case ExpenseTag.work:
        return Icons.work_outline;
      case ExpenseTag.health:
        return Icons.favorite_outline;
      case ExpenseTag.other:
        return Icons.more_horiz;
    }
  }

  static Color color(ExpenseTag tag) {
    switch (tag) {
      case ExpenseTag.personal:
        return const Color(0xFF58A6FF);
      case ExpenseTag.household:
        return const Color(0xFF2EA043);
      case ExpenseTag.family:
        return const Color(0xFFF0883E);
      case ExpenseTag.work:
        return const Color(0xFF8B5CF6);
      case ExpenseTag.health:
        return const Color(0xFFFF6B6B);
      case ExpenseTag.other:
        return const Color(0xFF8B949E);
    }
  }

  static ExpenseTag fromString(String? val) {
    return ExpenseTag.values.firstWhere(
      (e) => e.name == val,
      orElse: () => ExpenseTag.personal,
    );
  }

  static List<ExpenseTag> get all => ExpenseTag.values;
}