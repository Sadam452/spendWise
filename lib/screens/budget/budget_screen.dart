import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/expense_provider.dart';
import '../../utils/theme.dart';
import '../../utils/constants.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  final _controller = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final budget =
        context.read<ExpenseProvider>().currentBudget;
    if (budget != null) {
      _controller.text = budget.amount.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final val = double.tryParse(_controller.text.trim());
    if (val == null || val <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Enter a valid budget amount'),
          backgroundColor: AppColors.expense,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    await context.read<ExpenseProvider>().setBudget(val);
    setState(() => _isSaving = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 10),
            Text('Budget set successfully!'),
          ]),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        title: const Text('Monthly Budget'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<ExpenseProvider>(
        builder: (context, provider, _) {
          final now = DateTime.now();
          final budget = provider.currentBudget;
          final spent = provider.currentMonthTotal;
          final percent = provider.budgetUsedPercent;
          final color = provider.isBudgetExceeded
              ? AppColors.expense
              : provider.isBudgetWarning
                  ? AppColors.warning
                  : AppColors.primary;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Current status
                if (budget != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: color.withOpacity(0.2)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          DateFormat('MMMM yyyy').format(now),
                          style: TextStyle(
                              color: AppColors.textSecondary(context),
                              fontSize: 13),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.center,
                          crossAxisAlignment:
                              CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${AppConstants.currency}${NumberFormat('#,##,###').format(spent)}',
                              style: TextStyle(
                                  color: color,
                                  fontSize: 32,
                                  fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(width: 6),
                            Padding(
                              padding:
                                  const EdgeInsets.only(bottom: 4),
                              child: Text(
                                '/ ${AppConstants.currency}${NumberFormat('#,##,###').format(budget.amount)}',
                                style: TextStyle(
                                    color: AppColors.textSecondary(context),
                                    fontSize: 16),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: percent / 100,
                            backgroundColor: AppColors.border(context),
                            valueColor:
                                AlwaysStoppedAnimation<Color>(
                                    color),
                            minHeight: 10,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          provider.isBudgetExceeded
                              ? '🚨 Exceeded by ${AppConstants.currency}${NumberFormat('#,##,###').format(spent - budget.amount)}'
                              : '${AppConstants.currency}${NumberFormat('#,##,###').format(budget.amount - spent)} remaining  ·  ${percent.toStringAsFixed(0)}% used',
                          style: TextStyle(
                              color: color,
                              fontSize: 13,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                ],

                // Set budget
                Text('SET MONTHLY BUDGET',
                    style: TextStyle(
                        color: AppColors.textSecondary(context),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8)),
                const SizedBox(height: 12),

                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: AppColors.primary.withOpacity(0.2)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(AppConstants.currency,
                          style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 32,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 36,
                              fontWeight: FontWeight.w800),
                          decoration: InputDecoration(
                            hintText: '0',
                            hintStyle: TextStyle(
                                color: AppColors.textMuted(context),
                                fontSize: 36,
                                fontWeight: FontWeight.w800),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            filled: false,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Tips
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surface(context),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border(context)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Icon(Icons.lightbulb_outline,
                            color: AppColors.warning, size: 16),
                        SizedBox(width: 8),
                        Text('Smart Budget Tips',
                            style: TextStyle(
                                color: AppColors.warning,
                                fontSize: 13,
                                fontWeight: FontWeight.w700)),
                      ]),
                      SizedBox(height: 8),
                      Text(
                        '• You\'ll get a warning at 80% usage\n'
                        '• Alert shown when budget is exceeded\n'
                        '• Budget resets every month automatically',
                        style: TextStyle(
                            color: AppColors.textSecondary(context),
                            fontSize: 12,
                            height: 1.6),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5),
                          )
                        : const Text('Save Budget',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}