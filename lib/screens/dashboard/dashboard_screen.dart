import 'package:spendwise/screens/main_screen.dart';

import '../../providers/theme_provider.dart';
import '../../widgets/insights_widget.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/expense_provider.dart';
import '../../utils/theme.dart';
import '../../utils/constants.dart';
import '../../models/expense.dart';
import '../../utils/expense_type.dart'; // <--- ADDED IMPORT FOR TAGS
import '../expense/add_expense_screen.dart';
import '../budget/budget_screen.dart';
import '../../widgets/settings_drawer.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  DateTime? _customStart;
  DateTime? _customEnd;

  String _fmt(double amount) =>
      '${AppConstants.currency}${NumberFormat('#,##,###').format(amount)}';

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: now,
      initialDateRange: DateTimeRange(
        start: _customStart ?? DateTime(now.year, now.month, 1),
        end: _customEnd ?? now,
      ),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.dark(
            primary: AppColors.primary,
            onPrimary: Colors.white,
            surface: AppColors.card(context),
            onSurface: AppColors.textPrimary(context),
          ),
          dialogTheme:
              DialogThemeData(backgroundColor: AppColors.surface(context)),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _customStart = picked.start;
        _customEnd = picked.end;
      });
      if (mounted) {
        await context
            .read<ExpenseProvider>()
            .loadByDateRange(picked.start, picked.end);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background(context),
      drawer: const SettingsDrawer(),
      appBar: AppBar(
        titleSpacing: -10, 
        leading: Builder(
      builder: (context) {
        return IconButton(
          icon: Icon(Icons.settings, color: AppColors.textSecondary(context)),
          tooltip: 'Open Settings',
          onPressed: () {
            Scaffold.of(context).openDrawer();
          },
        );
      }
    ),
        title: Row(
          children: [
            const Text('SpendWise'),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.savings_outlined,color: AppColors.textSecondary(context)),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BudgetScreen()),
            ).then(
                (_) => context.read<ExpenseProvider>().loadDashboard()),
            tooltip: 'Set Budget',
          ),
          IconButton(
            icon: Icon(Icons.refresh_outlined, color: AppColors.textSecondary(context)),
            onPressed: () =>
                context.read<ExpenseProvider>().loadDashboard(),
          ),
          Consumer<ThemeProvider>(
            builder: (_, tp, __) => IconButton(
              icon: Icon(tp.isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,color: AppColors.textSecondary(context)),
              onPressed: tp.toggle,
              tooltip: 'Toggle Theme',
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'dashboard_add_expense',
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddExpenseScreen()),
        ).then((_) => context.read<ExpenseProvider>().init()),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Consumer<ExpenseProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(
                child:
                    CircularProgressIndicator(color: AppColors.primary));
          }
          return RefreshIndicator(
            color: AppColors.primary,
            backgroundColor: AppColors.card(context),
            onRefresh: () => provider.loadDashboard(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSummaryCards(provider),
                  const SizedBox(height: 20),
                  _buildDateRangePicker(provider),
                  const SizedBox(height: 20),
                  _buildQuickFilters(provider),
                  const SizedBox(height: 20),
                  InsightsWidget(expenses: provider.filteredExpenses),
                  const SizedBox(height: 20),
                  _buildMonthlyChart(provider),
                  const SizedBox(height: 20),
                  _buildCategoryBreakdown(provider),
                  const SizedBox(height: 20),
                  _buildRecentExpenses(provider),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryCards(ExpenseProvider provider) {
    final now = DateTime.now();
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                label: 'Last 30 Days',
                amount: _fmt(provider.last30DaysTotal),
                icon: Icons.history_outlined,
                color: AppColors.info,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SummaryCard(
                label: '${DateFormat('MMM').format(now)} (${now.day}d)',
                amount: _fmt(provider.currentMonthTotal),
                icon: Icons.calendar_today_outlined,
                color: AppColors.expense,
              ),
            ),
          ],
        ),
        if (provider.currentBudget != null) ...[
          const SizedBox(height: 12),
          _buildBudgetCard(provider),
        ],
      ],
    );
  }

Widget _buildBudgetCard(ExpenseProvider provider) {
    final budget = provider.currentBudget!;
    
    // SAFE MATH: Prevents the progress bar from vanishing due to NaN/Infinity errors
    final safePercent = budget.amount > 0 
        ? (provider.currentMonthTotal / budget.amount) 
        : 0.0;
    
    final bool isExceeded = provider.isBudgetExceeded;
    final bool isWarning = provider.isBudgetWarning;

    final color = isExceeded
        ? AppColors.expense
        : isWarning
            ? AppColors.warning
            : AppColors.primary;

    // Clean, objective data with no filler words
    String headerText = isExceeded 
        ? 'Exceeded by ${_fmt(provider.currentMonthTotal - budget.amount)}'
        : '${_fmt(provider.currentMonthTotal)} / ${_fmt(budget.amount)}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Monthly Budget',
                  style: TextStyle(
                      color: AppColors.textSecondary(context),
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
              Text(headerText,
                  style: TextStyle(
                      color: color,
                      fontSize: 13,
                      fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 12),
          // THE PROGRESS BAR
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: safePercent.clamp(0.0, 1.0), // Safely capped at 100%
              backgroundColor: AppColors.border(context),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
            ),
          ),
          if (!isExceeded) ...[
            const SizedBox(height: 8),
            Text(
              '${_fmt(budget.amount - provider.currentMonthTotal)} remaining',
              style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ]
        ],
      ),
    );
  }
  Widget _buildDateRangePicker(ExpenseProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel('Custom date range'), // SENTENCE CASE
        const SizedBox(height: 10),
        InkWell(
          onTap: _pickDateRange,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.card(context),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _customStart != null
                    ? AppColors.primary
                    : AppColors.border(context),
                width: _customStart != null ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.date_range_outlined,
                    color: _customStart != null
                        ? AppColors.primary
                        : AppColors.textSecondary(context),
                    size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: _customStart == null
                      ? Text('Tap to select date range',
                          style: TextStyle(
                              color: AppColors.textSecondary(context),
                              fontSize: 14))
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${DateFormat('d MMM yyyy').format(_customStart!)}  →  ${DateFormat('d MMM yyyy').format(_customEnd!)}',
                              style: TextStyle(
                                  color: AppColors.textPrimary(context),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Total: ${_fmt(provider.customRangeTotal)}',
                              style: const TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                ),
                if (_customStart != null)
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _customStart = null;
                        _customEnd = null;
                      });
                      provider.loadDashboard();
                    },
                    child: Icon(Icons.close,
                        color: AppColors.textSecondary(context), size: 18),
                  )
                else
                  Icon(Icons.chevron_right,
                      color: AppColors.textSecondary(context)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickFilters(ExpenseProvider provider) {
    final filters = [
      'Today',
      'This Week',
      'This Month',
      'Last 30 Days'
    ];
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final f = filters[i];
          final selected = provider.selectedFilter == f;
          return GestureDetector(
            onTap: () {
              setState(() {
                _customStart = null;
                _customEnd = null;
              });
              provider.loadByFilter(f);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : AppColors.card(context),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected
                      ? AppColors.primary
                      : AppColors.border(context),
                ),
              ),
              child: Text(
                f,
                style: TextStyle(
                  color: selected
                      ? Colors.white
                      : AppColors.textSecondary(context),
                  fontSize: 13,
                  fontWeight: selected
                      ? FontWeight.w600
                      : FontWeight.normal,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMonthlyChart(ExpenseProvider provider) {
    final data = provider.monthlyTotals;
    if (data.isEmpty) return const SizedBox();
    final maxVal = data
        .map((e) => (e['total'] as num).toDouble())
        .reduce((a, b) => a > b ? a : b);
    final months = [
      'J', 'F', 'M', 'A', 'M', 'J',
      'J', 'A', 'S', 'O', 'N', 'D'
    ];
    final currentMonth = DateTime.now().month;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel('Monthly overview'), // SENTENCE CASE
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.card(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border(context)),
          ),
          child: SizedBox(
            height: 160, // FIX: Increased from 140 to 160 to prevent bottom overflow
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(12, (i) {
                final monthNum =
                    (i + 1).toString().padLeft(2, '0');
                final entry = data.firstWhere(
                  (e) => e['month'] == monthNum,
                  orElse: () => {'total': 0.0},
                );
                final val = (entry['total'] as num).toDouble();
                final height =
                    maxVal > 0 ? (val / maxVal * 100) : 0.0;
                final isCurrentMonth = (i + 1) == currentMonth;

                return Expanded(
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 2),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (val > 0)
                          Text(
                            val >= 1000
                                ? '${(val / 1000).toStringAsFixed(0)}k'
                                : val.toStringAsFixed(0),
                            style: TextStyle(
                              color: isCurrentMonth
                                  ? AppColors.primary
                                  : AppColors.textSecondary(context),
                              fontSize: 7,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        const SizedBox(height: 2),
                        AnimatedContainer(
                          duration:
                              const Duration(milliseconds: 600),
                          height: height.clamp(4, 100),
                          decoration: BoxDecoration(
                            color: isCurrentMonth
                                ? AppColors.primary
                                : AppColors.primary
                                    .withOpacity(0.35),
                            borderRadius:
                                const BorderRadius.vertical(
                              top: Radius.circular(4),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          months[i],
                          style: TextStyle(
                            color: isCurrentMonth
                                ? AppColors.primary
                                : AppColors.textSecondary(context),
                            fontSize: 10,
                            fontWeight: isCurrentMonth
                                ? FontWeight.w700
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryBreakdown(ExpenseProvider provider) {
    // Note: Provider is now returning TAGS instead of Category IDs because of our DB update!
    final data = provider.categoryTotals; 
    if (data.isEmpty) return const SizedBox();
    final total = data.fold(
        0.0, (sum, e) => sum + (e['total'] as num).toDouble());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel('Expense breakdown'), // SENTENCE CASE
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AppColors.card(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border(context)),
          ),
          child: Column(
            children: data.take(5).toList().asMap().entries.map((e) {
              final index = e.key;
              final item = e.value;
              
              // NEW LOGIC: Map the tag string to our UI colors and icons
              final tagString = item['tag'] as String? ?? 'personal';
              final tagEnum = ExpenseTagHelper.fromString(tagString);
              final icon = ExpenseTagHelper.icon(tagEnum);
              final color = ExpenseTagHelper.color(tagEnum);
              final name = ExpenseTagHelper.label(tagEnum);

              final amount = (item['total'] as num).toDouble();
              final count = item['count'] as int;
              final percent =
                  total > 0 ? (amount / total * 100) : 0.0;
              final isLast =
                  index == data.take(5).length - 1;

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(icon, color: color, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(name,
                                      style: TextStyle(
                                          color:
                                              AppColors.textPrimary(context),
                                          fontSize: 13,
                                          fontWeight:
                                              FontWeight.w600)),
                                  Text(_fmt(amount),
                                      style: TextStyle(
                                          color:
                                              AppColors.textPrimary(context),
                                          fontSize: 13,
                                          fontWeight:
                                              FontWeight.w700)),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius:
                                          BorderRadius.circular(3),
                                      child: LinearProgressIndicator(
                                        value: percent / 100,
                                        backgroundColor:
                                            AppColors.border(context),
                                        valueColor:
                                            AlwaysStoppedAnimation(color),
                                        minHeight: 5,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${percent.toStringAsFixed(0)}%',
                                    style: TextStyle(
                                        color: color,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text('$count transactions',
                                  style: TextStyle(
                                      color: AppColors.textSecondary(context),
                                      fontSize: 11)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isLast)
                    Divider(height: 1, color: AppColors.border(context)),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentExpenses(ExpenseProvider provider) {
    final expenses = provider.filteredExpenses.take(5).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const _SectionLabel('Recent expenses'), // SENTENCE CASE
            TextButton(
              onPressed: () {
                final mainScreen = context.findAncestorStateOfType<MainScreenState>();
                mainScreen?.switchTab(1);
              },
              child: const Text('See All',
                  style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        expenses.isEmpty
            ? Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: AppColors.card(context),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border(context)),
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.receipt_long_outlined,
                          color: AppColors.textSecondary(context)
                              .withOpacity(0.4),
                          size: 40),
                      const SizedBox(height: 10),
                      Text('No expenses yet',
                          style: TextStyle(
                              color: AppColors.textSecondary(context),
                              fontSize: 15)),
                      const SizedBox(height: 4),
                      Text('Tap + to add your first expense',
                          style: TextStyle(
                              color: AppColors.textSecondary(context),
                              fontSize: 12)),
                    ],
                  ),
                ),
              )
            : Container(
                decoration: BoxDecoration(
                  color: AppColors.card(context),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border(context)),
                ),
                child: Column(
                  children: expenses.asMap().entries.map((e) {
                    final isLast = e.key == expenses.length - 1;
                    return Column(
                      children: [
                        _ExpenseTile(expense: e.value),
                        if (!isLast)
                          Divider(
                              height: 1,
                              color: AppColors.border(context),
                              indent: 60),
                      ],
                    );
                  }).toList(),
                ),
              ),
      ],
    );
  }
}

// ─── Widgets ──────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(text,
      style: TextStyle(
          color: AppColors.textSecondary(context),
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5));
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String amount;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.label,
    required this.amount,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 12),
          Text(amount,
              style: TextStyle(
                  color: color,
                  fontSize: 20,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(
                  color: AppColors.textSecondary(context), fontSize: 11)),
        ],
      ),
    );
  }
}

class _ExpenseTile extends StatelessWidget {
  final Expense expense;
  const _ExpenseTile({required this.expense});

  @override
  Widget build(BuildContext context) {
    // NEW LOGIC: Read from the Tag instead of Category
    final tagEnum = ExpenseTagHelper.fromString(expense.tag);
    final color = ExpenseTagHelper.color(tagEnum);
    final icon = ExpenseTagHelper.icon(tagEnum);
    final name = ExpenseTagHelper.label(tagEnum);

    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(expense.title,
          style: TextStyle(
              color: AppColors.textPrimary(context),
              fontSize: 14,
              fontWeight: FontWeight.w500)),
      subtitle: Text(
        '$name · ${DateFormat('d MMM').format(expense.date)}',
        style: TextStyle(
            color: AppColors.textSecondary(context), fontSize: 12),
      ),
      trailing: Text(
        '-${AppConstants.currency}${NumberFormat('#,##,###').format(expense.amount)}',
        style: const TextStyle(
            color: AppColors.expense,
            fontSize: 15,
            fontWeight: FontWeight.w700),
      ),
    );
  }
}