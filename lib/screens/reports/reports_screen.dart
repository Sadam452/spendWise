import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../database/db_helper.dart';
import '../../providers/expense_provider.dart';
import '../../providers/income_provider.dart';
import '../../providers/lending_provider.dart';
import '../../utils/constants.dart';
import '../../utils/expense_type.dart';
import '../../utils/theme.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  double _income = 0;
  double _expenses = 0;
  double _lifetimeIncome = 0;
  double _lifetimeExpenses = 0;
  List<Map<String, dynamic>> _tags = [];
  List<Map<String, dynamic>> _monthlyTrend = [];
  bool _isLoading = true;
  Object? _loadError;
  bool _refreshScheduled = false;
  int _loadGeneration = 0;
  ExpenseProvider? _expenseProvider;
  IncomeProvider? _incomeProvider;

  String _fmt(double value) =>
      '${AppConstants.currency}${NumberFormat('#,##,##0.##').format(value)}';

  String _compactAmount(double value) {
    if (value >= 10000000) return '${(value / 10000000).toStringAsFixed(1)}cr';
    if (value >= 100000) return '${(value / 100000).toStringAsFixed(1)}L';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}k';
    return value.toStringAsFixed(0);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadReport());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final expenses = context.read<ExpenseProvider>();
    if (_expenseProvider != expenses) {
      _expenseProvider?.removeListener(_scheduleRefresh);
      _expenseProvider = expenses..addListener(_scheduleRefresh);
    }
    final income = context.read<IncomeProvider>();
    if (_incomeProvider != income) {
      _incomeProvider?.removeListener(_scheduleRefresh);
      _incomeProvider = income..addListener(_scheduleRefresh);
    }
  }

  @override
  void dispose() {
    _expenseProvider?.removeListener(_scheduleRefresh);
    _incomeProvider?.removeListener(_scheduleRefresh);
    super.dispose();
  }

  void _scheduleRefresh() {
    if (_refreshScheduled) return;
    _refreshScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshScheduled = false;
      if (mounted) _loadReport();
    });
  }

  Future<void> _loadReport() async {
    final month = _selectedMonth;
    final generation = ++_loadGeneration;
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final start = DateTime(month.year, month.month);
      final end = DateTime(month.year, month.month + 1, 0);
      final results = await Future.wait<dynamic>([
        DBHelper.instance.getTotalByDateRange(start, end),
        DBHelper.instance.getIncomeTotalByDateRange(start, end),
        DBHelper.instance.getCategoryTotals(start, end),
        DBHelper.instance.getMonthlyCashFlow(month),
        DBHelper.instance.getLifetimeIncomeAndExpenseTotals(),
      ]);
      if (!mounted ||
          generation != _loadGeneration ||
          month != _selectedMonth) {
        return;
      }
      setState(() {
        _expenses = results[0] as double;
        _income = results[1] as double;
        _tags = List<Map<String, dynamic>>.from(results[2] as List);
        _monthlyTrend = List<Map<String, dynamic>>.from(results[3] as List);
        final lifetime = results[4] as Map<String, double>;
        _lifetimeIncome = lifetime['income']!;
        _lifetimeExpenses = lifetime['expenses']!;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted || generation != _loadGeneration) return;
      setState(() {
        _loadError = error;
        _isLoading = false;
      });
    }
  }

  void _changeMonth(int offset) {
    final target = DateTime(_selectedMonth.year, _selectedMonth.month + offset);
    final now = DateTime.now();
    if (target.isAfter(DateTime(now.year, now.month))) return;
    setState(() => _selectedMonth = target);
    _loadReport();
  }

  Future<void> _pickMonth() async {
    final now = DateTime.now();
    final selected = await showDialog<DateTime>(
      context: context,
      builder: (dialogContext) {
        var visibleYear = _selectedMonth.year;
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) => AlertDialog(
            title: const Text('Select month'),
            contentPadding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            content: SizedBox(
              width: 320,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: visibleYear > 2000
                            ? () => setDialogState(() => visibleYear--)
                            : null,
                        tooltip: 'Previous year',
                        icon: const Icon(Icons.chevron_left),
                      ),
                      Text(
                        '$visibleYear',
                        style: TextStyle(
                          color: AppColors.textPrimary(dialogContext),
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      IconButton(
                        onPressed: visibleYear < now.year
                            ? () => setDialogState(() => visibleYear++)
                            : null,
                        tooltip: 'Next year',
                        icon: const Icon(Icons.chevron_right),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: 12,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 2.2,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                    itemBuilder: (context, index) {
                      final month = index + 1;
                      final isFuture = DateTime(
                        visibleYear,
                        month,
                      ).isAfter(DateTime(now.year, now.month));
                      final isSelected =
                          visibleYear == _selectedMonth.year &&
                          month == _selectedMonth.month;
                      final color = isSelected
                          ? AppColors.primary
                          : AppColors.cardAlt(dialogContext);
                      return InkWell(
                        onTap: isFuture
                            ? null
                            : () => Navigator.pop(
                                dialogContext,
                                DateTime(visibleYear, month),
                              ),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.border(dialogContext),
                            ),
                          ),
                          child: Text(
                            DateFormat(
                              'MMM',
                            ).format(DateTime(visibleYear, month)),
                            style: TextStyle(
                              color: isFuture
                                  ? AppColors.textMuted(dialogContext)
                                  : isSelected
                                  ? Colors.white
                                  : AppColors.textPrimary(dialogContext),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
            ],
          ),
        );
      },
    );
    if (selected == null || !mounted) return;
    setState(() => _selectedMonth = selected);
    _loadReport();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(title: const Text('Reports')),
      body: Consumer<LendingProvider>(
        builder: (context, lending, _) => RefreshIndicator(
          onRefresh: _loadReport,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              _buildMonthSelector(),
              const SizedBox(height: 14),
              if (_loadError != null)
                _buildError()
              else if (_isLoading)
                const SizedBox(
                  height: 150,
                  child: Center(child: CircularProgressIndicator()),
                )
              else ...[
                _buildLifetimeTotals(),
                const SizedBox(height: 14),
                _buildCashFlowSummary(),
                const SizedBox(height: 24),
                _buildMonthlyTrend(),
                const SizedBox(height: 24),
                _buildTagBreakdown(),
                const SizedBox(height: 24),
                _buildLendingSummary(lending),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLifetimeTotals() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _lifetimeValue(
              'Income to date',
              _lifetimeIncome,
              AppColors.primary,
            ),
          ),
          Container(
            width: 1,
            height: 34,
            color: AppColors.border(context),
            margin: const EdgeInsets.symmetric(horizontal: 12),
          ),
          Expanded(
            child: _lifetimeValue(
              'Expenses to date',
              _lifetimeExpenses,
              AppColors.expense,
            ),
          ),
        ],
      ),
    );
  }

  Widget _lifetimeValue(String label, double value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.textSecondary(context),
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          _fmt(value),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: color,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildMonthSelector() {
    final now = DateTime.now();
    final isCurrentMonth =
        _selectedMonth.year == now.year && _selectedMonth.month == now.month;
    return Row(
      children: [
        IconButton(
          onPressed: () => _changeMonth(-1),
          visualDensity: VisualDensity.compact,
          tooltip: 'Previous month',
          icon: const Icon(Icons.chevron_left),
        ),
        InkWell(
          onTap: _pickMonth,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            child: Row(
              children: [
                Text(
                  DateFormat('MMMM yyyy').format(_selectedMonth),
                  style: TextStyle(
                    color: AppColors.textPrimary(context),
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_drop_down, size: 20),
              ],
            ),
          ),
        ),
        IconButton(
          onPressed: isCurrentMonth ? null : () => _changeMonth(1),
          visualDensity: VisualDensity.compact,
          tooltip: 'Next month',
          icon: const Icon(Icons.chevron_right),
        ),
        const Spacer(),
        Text(
          'Monthly report',
          style: TextStyle(
            color: AppColors.textMuted(context),
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }

  Widget _buildCashFlowSummary() {
    final cashFlow = _income - _expenses;
    final cashColor = cashFlow > 0
        ? AppColors.primary
        : cashFlow < 0
        ? AppColors.expense
        : AppColors.textSecondary(context);
    final barTotal = _income + _expenses;
    final incomeShare = barTotal == 0 ? 0.5 : _income / barTotal;

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
          Text(
            'Net cash flow',
            style: TextStyle(
              color: AppColors.textSecondary(context),
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _fmt(cashFlow),
            style: TextStyle(
              color: cashColor,
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 7,
              child: barTotal == 0
                  ? Container(color: AppColors.border(context))
                  : Row(
                      children: [
                        Expanded(
                          flex: (incomeShare * 1000).round().clamp(1, 999),
                          child: Container(color: AppColors.primary),
                        ),
                        Expanded(
                          flex: ((1 - incomeShare) * 1000).round().clamp(
                            1,
                            999,
                          ),
                          child: Container(color: AppColors.expense),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _cashFlowValue('Income', _income, AppColors.primary),
              ),
              Expanded(
                child: _cashFlowValue('Expenses', _expenses, AppColors.expense),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _cashFlowValue(String label, double amount, Color color) {
    return Row(
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: AppColors.textSecondary(context),
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _fmt(amount),
                style: TextStyle(
                  color: AppColors.textPrimary(context),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMonthlyTrend() {
    final start = DateTime(_selectedMonth.year, _selectedMonth.month - 5);
    final values = List.generate(6, (index) {
      final month = DateTime(start.year, start.month + index);
      final key = DateFormat('yyyy-MM').format(month);
      final row = _monthlyTrend.where((item) => item['month'] == key);
      final data = row.isEmpty ? null : row.first;
      return (
        month: month,
        income: (data?['income'] as num?)?.toDouble() ?? 0.0,
        expenses: (data?['expenses'] as num?)?.toDouble() ?? 0.0,
      );
    });
    final maxValue = values.fold<double>(
      0,
      (max, item) =>
          [max, item.income, item.expenses].reduce((a, b) => a > b ? a : b),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('Income vs expenses'),
        const SizedBox(height: 3),
        Text(
          'Six months ending ${DateFormat('MMM yyyy').format(_selectedMonth)}',
          style: TextStyle(
            color: AppColors.textSecondary(context),
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 10),
        const Row(
          children: [
            _LegendDot(label: 'Income', color: AppColors.primary),
            SizedBox(width: 14),
            _LegendDot(label: 'Expenses', color: AppColors.expense),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
          decoration: BoxDecoration(
            color: AppColors.card(context),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border(context)),
          ),
          child: SizedBox(
            height: 138,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: values.map((item) {
                final isSelected =
                    item.month.year == _selectedMonth.year &&
                    item.month.month == _selectedMonth.month;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1),
                    child: Column(
                      children: [
                        Expanded(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Expanded(
                                child: _verticalTrendBar(
                                  item.income,
                                  maxValue,
                                  AppColors.primary,
                                ),
                              ),
                              Expanded(
                                child: _verticalTrendBar(
                                  item.expenses,
                                  maxValue,
                                  AppColors.expense,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          DateFormat('MMM').format(item.month),
                          style: TextStyle(
                            color: isSelected
                                ? AppColors.textPrimary(context)
                                : AppColors.textSecondary(context),
                            fontSize: 9,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _verticalTrendBar(double amount, double maxValue, Color color) {
    final height = maxValue == 0
        ? 2.0
        : (amount / maxValue * 76).clamp(2.0, 76.0).toDouble();
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            _compactAmount(amount),
            maxLines: 1,
            style: TextStyle(
              color: AppColors.textSecondary(context),
              fontSize: 7,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 3),
        Container(
          width: 10,
          height: height,
          decoration: BoxDecoration(
            color: amount == 0 ? color.withOpacity(0.25) : color,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
          ),
        ),
      ],
    );
  }

  Widget _buildTagBreakdown() {
    final topTags = _tags.take(5).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('Top spending tags'),
        const SizedBox(height: 10),
        if (topTags.isEmpty)
          _emptyCard('No expenses recorded for this month')
        else
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.card(context),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border(context)),
            ),
            child: Column(
              children: topTags.map((item) {
                final tag = ExpenseTagHelper.fromString(
                  item['tag'] as String? ?? 'personal',
                );
                final amount = (item['total'] as num).toDouble();
                final share = _expenses > 0 ? amount / _expenses : 0.0;
                final color = ExpenseTagHelper.color(tag);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  child: Row(
                    children: [
                      Icon(ExpenseTagHelper.icon(tag), color: color, size: 17),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          ExpenseTagHelper.label(tag),
                          style: TextStyle(
                            color: AppColors.textPrimary(context),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 62,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: share.clamp(0, 1),
                            minHeight: 5,
                            backgroundColor: AppColors.border(context),
                            valueColor: AlwaysStoppedAnimation(color),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 78,
                        child: Text(
                          _fmt(amount),
                          textAlign: TextAlign.end,
                          style: TextStyle(
                            color: AppColors.textPrimary(context),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      SizedBox(
                        width: 31,
                        child: Text(
                          '${(share * 100).round()}%',
                          textAlign: TextAlign.end,
                          style: TextStyle(
                            color: AppColors.textSecondary(context),
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildLendingSummary(LendingProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('Lending at a glance'),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            color: AppColors.card(context),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border(context)),
          ),
          child: Row(
            children: [
              Expanded(
                child: _lendingValue(
                  'Owed to you',
                  provider.outstandingLent,
                  AppColors.purple,
                ),
              ),
              Container(
                width: 1,
                height: 34,
                color: AppColors.border(context),
                margin: const EdgeInsets.symmetric(horizontal: 14),
              ),
              Expanded(
                child: _lendingValue(
                  'You owe',
                  provider.outstandingBorrowed,
                  AppColors.teal,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _lendingValue(String label, double value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.textSecondary(context),
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          _fmt(value),
          style: TextStyle(
            color: color,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _emptyCard(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Text(
        message,
        style: TextStyle(color: AppColors.textSecondary(context), fontSize: 12),
      ),
    );
  }

  Widget _buildError() {
    return _emptyCard(
      'Could not load report data. Pull down to retry.\n$_loadError',
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: TextStyle(
      color: AppColors.textPrimary(context),
      fontSize: 14,
      fontWeight: FontWeight.w700,
    ),
  );
}

class _LegendDot extends StatelessWidget {
  final String label;
  final Color color;

  const _LegendDot({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 5),
      Text(
        label,
        style: TextStyle(color: AppColors.textSecondary(context), fontSize: 10),
      ),
    ],
  );
}
