import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/expense_provider.dart';
import '../../providers/lending_provider.dart';
import '../../providers/income_provider.dart';
import '../../utils/theme.dart';
import '../../utils/constants.dart';
import '../../utils/expense_type.dart'; // <--- ADDED to read the tags

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  int _selectedYear = DateTime.now().year;

  String _fmt(double v) =>
      '${AppConstants.currency}${NumberFormat('#,##,###').format(v)}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        title: const Text('Reports'),
        actions: [
          IconButton(
            icon: const Icon(Icons.backup_outlined),
            onPressed: _showBackupSheet,
            tooltip: 'Backup',
          ),
        ],
      ),
      body: Consumer3<ExpenseProvider, LendingProvider, IncomeProvider>(
        builder: (context, expProvider, lendProvider, incomeProvider, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildOverallSummary(expProvider, lendProvider, incomeProvider),
                const SizedBox(height: 20),
                _buildYearlyChart(expProvider),
                const SizedBox(height: 20),
                _buildCategoryReport(expProvider),
                const SizedBox(height: 20),
                _buildLendingReport(lendProvider),
                const SizedBox(height: 20),
                _buildExportSection(expProvider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildOverallSummary(
    ExpenseProvider exp,
    LendingProvider lend,
    IncomeProvider income,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel('Financial overview'), // SENTENCE CASE
        const SizedBox(height: 12),
        _buildCashFlowCard(exp, income),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'This Month',
                value: _fmt(exp.currentMonthTotal),
                icon: Icons.calendar_today_outlined,
                color: AppColors.expense,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                label: 'Last 30 Days',
                value: _fmt(exp.last30DaysTotal),
                icon: Icons.history_outlined,
                color: AppColors.info,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'Outstanding Lent',
                value: _fmt(lend.outstandingLent),
                icon: Icons.arrow_upward,
                color: AppColors.purple,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                label: 'Outstanding Owe',
                value: _fmt(lend.outstandingBorrowed),
                icon: Icons.arrow_downward,
                color: AppColors.teal,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCashFlowCard(ExpenseProvider exp, IncomeProvider income) {
    final cashFlow = income.currentMonthIncome - exp.currentMonthTotal;
    final positive = cashFlow >= 0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: (positive ? AppColors.primary : AppColors.expense).withOpacity(
          0.1,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (positive ? AppColors.primary : AppColors.expense).withOpacity(
            0.25,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            positive ? Icons.trending_up : Icons.trending_down,
            color: positive ? AppColors.primary : AppColors.expense,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'This month cash flow',
              style: TextStyle(color: AppColors.textSecondary(context)),
            ),
          ),
          Text(
            _fmt(cashFlow),
            style: TextStyle(
              color: positive ? AppColors.primary : AppColors.expense,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildYearlyChart(ExpenseProvider provider) {
    final data = provider.monthlyTotals;
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    final yearTotal = data.fold(
      0.0,
      (sum, e) => sum + (e['total'] as num).toDouble(),
    );
    final avgMonthly = data.isNotEmpty ? yearTotal / 12 : 0.0;
    final maxVal = data.isNotEmpty
        ? data
              .map((e) => (e['total'] as num).toDouble())
              .reduce((a, b) => a > b ? a : b)
        : 1.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const _SectionLabel('Yearly breakdown'), // SENTENCE CASE
            Row(
              children: [
                IconButton(
                  onPressed: () => setState(() => _selectedYear--),
                  icon: Icon(
                    Icons.chevron_left,
                    color: AppColors.textSecondary(context),
                    size: 20,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                Text(
                  '$_selectedYear',
                  style: TextStyle(
                    color: AppColors.textPrimary(context),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                IconButton(
                  onPressed: _selectedYear < DateTime.now().year
                      ? () => setState(() => _selectedYear++)
                      : null,
                  icon: Icon(
                    Icons.chevron_right,
                    color: _selectedYear < DateTime.now().year
                        ? AppColors.textSecondary(context)
                        : AppColors.textMuted(context),
                    size: 20,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.card(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border(context)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Spent',
                        style: TextStyle(
                          color: AppColors.textSecondary(context),
                          fontSize: 11,
                        ),
                      ),
                      Text(
                        _fmt(yearTotal),
                        style: const TextStyle(
                          color: AppColors.expense,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Monthly Avg',
                        style: TextStyle(
                          color: AppColors.textSecondary(context),
                          fontSize: 11,
                        ),
                      ),
                      Text(
                        _fmt(avgMonthly),
                        style: const TextStyle(
                          color: AppColors.info,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 135,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(12, (i) {
                    final mNum = (i + 1).toString().padLeft(2, '0');
                    final entry = data.firstWhere(
                      (e) => e['month'] == mNum,
                      orElse: () => {'total': 0.0},
                    );
                    final val = (entry['total'] as num).toDouble();
                    final height = maxVal > 0
                        ? (val / maxVal * 90).clamp(4, 90)
                        : 4.0;
                    final isCurrent =
                        (i + 1) == DateTime.now().month &&
                        _selectedYear == DateTime.now().year;

                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (val > 0)
                              Text(
                                val >= 1000
                                    ? '${(val / 1000).toStringAsFixed(0)}k'
                                    : val.toStringAsFixed(0),
                                style: TextStyle(
                                  color: isCurrent
                                      ? AppColors.expense
                                      : AppColors.textSecondary(context),
                                  fontSize: 7,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            const SizedBox(height: 2),
                            Container(
                              height: height.toDouble(),
                              decoration: BoxDecoration(
                                color: isCurrent
                                    ? AppColors.expense
                                    : AppColors.expense.withOpacity(0.35),
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(4),
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              months[i].substring(0, 1),
                              style: TextStyle(
                                color: isCurrent
                                    ? AppColors.expense
                                    : AppColors.textSecondary(context),
                                fontSize: 10,
                                fontWeight: isCurrent
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
              const SizedBox(height: 8),
              // Month table
              ...data.map((item) {
                final mIdx = int.parse(item['month'] as String) - 1;
                final val = (item['total'] as num).toDouble();
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 36,
                        child: Text(
                          months[mIdx],
                          style: TextStyle(
                            color: AppColors.textSecondary(context),
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: maxVal > 0 ? val / maxVal : 0,
                            backgroundColor: AppColors.border(context),
                            valueColor: AlwaysStoppedAnimation(
                              AppColors.expense.withOpacity(0.7),
                            ),
                            minHeight: 6,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _fmt(val),
                        style: TextStyle(
                          color: AppColors.textPrimary(context),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryReport(ExpenseProvider provider) {
    final data = provider.categoryTotals;
    if (data.isEmpty) return const SizedBox();

    final total = data.fold(
      0.0,
      (sum, e) => sum + (e['total'] as num).toDouble(),
    );

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
            children: data.asMap().entries.map((e) {
              final isLast = e.key == data.length - 1;
              final item = e.value;

              // FIX: Now reading from Tags just like Dashboard!
              final tagString = item['tag'] as String? ?? 'personal';
              final tagEnum = ExpenseTagHelper.fromString(tagString);
              final icon = ExpenseTagHelper.icon(tagEnum);
              final color = ExpenseTagHelper.color(tagEnum);
              final name = ExpenseTagHelper.label(tagEnum);

              final amount = (item['total'] as num).toDouble();
              final count = item['count'] as int;
              final pct = total > 0 ? amount / total * 100 : 0.0;

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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    name,
                                    style: TextStyle(
                                      color: AppColors.textPrimary(context),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    _fmt(amount),
                                    style: TextStyle(
                                      color: AppColors.textPrimary(context),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(3),
                                      child: LinearProgressIndicator(
                                        value: pct / 100,
                                        backgroundColor: AppColors.border(
                                          context,
                                        ),
                                        valueColor: AlwaysStoppedAnimation(
                                          color,
                                        ),
                                        minHeight: 5,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${pct.toStringAsFixed(0)}% · $count txns',
                                    style: TextStyle(
                                      color: color,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
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

  Widget _buildLendingReport(LendingProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel('Lending summary'), // SENTENCE CASE
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.card(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border(context)),
          ),
          child: Column(
            children: [
              _lendRow('Total Lent', provider.totalLent, AppColors.purple),
              Divider(color: AppColors.border(context), height: 20),
              _lendRow(
                'Returned to You',
                provider.totalLentReturned,
                AppColors.primary,
              ),
              Divider(color: AppColors.border(context), height: 20),
              _lendRow(
                'Still Outstanding',
                provider.outstandingLent,
                AppColors.warning,
              ),
              Divider(
                color: AppColors.border(context),
                height: 20,
                thickness: 2,
              ),
              _lendRow(
                'Total Borrowed',
                provider.totalBorrowed,
                AppColors.teal,
              ),
              Divider(color: AppColors.border(context), height: 20),
              _lendRow(
                'You Returned',
                provider.totalBorrowedReturned,
                AppColors.primary,
              ),
              Divider(color: AppColors.border(context), height: 20),
              _lendRow(
                'Still You Owe',
                provider.outstandingBorrowed,
                AppColors.expense,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _lendRow(String label, double value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.textSecondary(context),
            fontSize: 13,
          ),
        ),
        Text(
          _fmt(value),
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildExportSection(ExpenseProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel('Data management'), // SENTENCE CASE
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AppColors.card(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border(context)),
          ),
          child: Column(
            children: [
              _actionTile(
                icon: Icons.upload_outlined,
                color: AppColors.primary,
                title: 'Export Backup',
                subtitle: 'Save all data as JSON file',
                onTap: () async {
                  try {
                    await provider.exportBackup();
                    if (mounted) {
                      AppUtils.showToast(
                        context,
                        'Backup exported!',
                      ); // Updated to new Toast
                    }
                  } catch (e) {
                    if (mounted) {
                      AppUtils.showToast(context, 'Export failed');
                    }
                  }
                },
              ),

              Divider(height: 1, color: AppColors.border(context)),
              _actionTile(
                icon: Icons.download_outlined,
                color: AppColors.warning,
                title: 'Restore Backup',
                subtitle: 'Import JSON backup file',
                onTap: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      backgroundColor: AppColors.card(context),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      title: Text(
                        'Restore Backup?',
                        style: TextStyle(color: AppColors.textPrimary(context)),
                      ),
                      content: Text(
                        'This replaces ALL current data. Cannot be undone.',
                        style: TextStyle(
                          color: AppColors.textSecondary(context),
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              color: AppColors.textSecondary(context),
                            ),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.expense,
                          ),
                          child: const Text('Restore'),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true && mounted) {
                    final result = await provider.importBackup();

                    if (mounted) {
                      // ─── THE FIX: Force Lending & Borrowing to refresh! ───
                      if (result == 'success') {
                        context.read<LendingProvider>().loadAll();
                      }
                      // ──────────────────────────────────────────────────────

                      AppUtils.showToast(
                        context,
                        result == 'success'
                            ? 'Data restored successfully!'
                            : result == 'cancelled'
                            ? 'Import cancelled'
                            : 'Invalid backup file',
                      );
                    }
                  }
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _actionTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: AppColors.textPrimary(context),
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: AppColors.textSecondary(context), fontSize: 12),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: AppColors.textSecondary(context),
        size: 20,
      ),
    );
  }

  void _showBackupSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border(context),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'About SpendWise',
              style: TextStyle(
                color: AppColors.textPrimary(context),
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            _infoRow(Icons.info_outline, 'Version', '1.0.0'),
            const SizedBox(height: 10),
            _infoRow(Icons.storage_outlined, 'Storage', 'Local · Offline'),
            const SizedBox(height: 10),
            _infoRow(Icons.phone_android_outlined, 'Platform', 'Android & iOS'),
            const SizedBox(height: 16),
            Divider(color: AppColors.border(context)),
            const SizedBox(height: 12),
            Center(
              child: Text(
                'Developed by Sadam · linkedin.com/in/sadam452',
                style: TextStyle(
                  color: AppColors.textSecondary(context),
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 18),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            color: AppColors.textSecondary(context),
            fontSize: 13,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            color: AppColors.textPrimary(context),
            fontSize: 13,
            fontWeight: FontWeight.w600,
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
  Widget build(BuildContext context) => Text(
    text,
    style: TextStyle(
      color: AppColors.textSecondary(context),
      fontSize: 12, // Matched Dashboard Size
      fontWeight: FontWeight.w700, // Matched Dashboard Weight
      letterSpacing: 0.5,
    ),
  ); // Matched Dashboard Spacing
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
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
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: AppColors.textSecondary(context),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
