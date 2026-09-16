import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/expense.dart';
import '../utils/theme.dart';
import '../utils/constants.dart';
import '../utils/expense_type.dart';

class InsightsWidget extends StatelessWidget {
  final List<Expense> expenses;

  const InsightsWidget({super.key, required this.expenses});

  String _fmt(double v) =>
      '${AppConstants.currency}${NumberFormat('#,##,###').format(v)}';

  @override
  Widget build(BuildContext context) {
    if (expenses.isEmpty) return const SizedBox();

    final now = DateTime.now();
    final today = expenses.where(
      (e) =>
          e.date.year == now.year &&
          e.date.month == now.month &&
          e.date.day == now.day,
    );

    final todayTotal = today.fold(0.0, (sum, e) => sum + e.amount);

    // Daily average
    final days = expenses.isNotEmpty
        ? now.difference(expenses.last.date).inDays.clamp(1, 365)
        : 1;
    final total = expenses.fold(0.0, (sum, e) => sum + e.amount);
    final dailyAvg = total / days;

    // Top tag
    final tagMap = <ExpenseTag, double>{};
    for (final e in expenses) {
      final tag = ExpenseTagHelper.fromString(e.tag);
      tagMap[tag] = (tagMap[tag] ?? 0) + e.amount;
    }

    // Streak — consecutive days with expense
    int streak = 0;
    DateTime check = DateTime(now.year, now.month, now.day);
    while (true) {
      final hasExpense = expenses.any(
        (e) =>
            e.date.year == check.year &&
            e.date.month == check.month &&
            e.date.day == check.day,
      );
      if (!hasExpense) break;
      streak++;
      check = check.subtract(const Duration(days: 1));
    }

    final topTag = tagMap.isNotEmpty
        ? tagMap.entries.reduce((a, b) => a.value > b.value ? a : b).key
        : ExpenseTag.personal;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel('Insights'),
        const SizedBox(height: 12),

        // Scrollable insight cards
        SizedBox(
          height: 110,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _InsightCard(
                icon: Icons.today_outlined,
                label: "Today's Spend",
                value: _fmt(todayTotal),
                sub: today.isEmpty
                    ? 'Nothing logged yet'
                    : '${today.length} transactions',
                color: AppColors.info,
              ),
              const SizedBox(width: 12),
              _InsightCard(
                icon: Icons.trending_up_outlined,
                label: 'Daily Average',
                value: _fmt(dailyAvg),
                sub: 'Over $days days',
                color: AppColors.warning,
              ),
              const SizedBox(width: 12),
              _InsightCard(
                icon: ExpenseTagHelper.icon(topTag),
                label: 'Top Tag',
                value: ExpenseTagHelper.label(topTag),
                sub: _fmt(tagMap[topTag] ?? 0),
                color: ExpenseTagHelper.color(topTag),
              ),
              const SizedBox(width: 12),
              _InsightCard(
                icon: Icons.local_fire_department_outlined,
                label: 'Logging Streak',
                value: '$streak day${streak == 1 ? '' : 's'}',
                sub: streak > 0 ? '🔥 Keep it up!' : 'Start logging today',
                color: streak > 3
                    ? AppColors.expense
                    : AppColors.textSecondary(context),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InsightCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String sub;
  final Color color;

  const _InsightCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.sub,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: AppColors.textSecondary(context),
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            sub,
            style: TextStyle(
              color: AppColors.textSecondary(context),
              fontSize: 11,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: TextStyle(
      color: AppColors.textSecondary(context),
      fontSize: 11,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.8,
    ),
  );
}
