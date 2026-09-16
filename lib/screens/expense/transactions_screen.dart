import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/expense_provider.dart';
import '../../models/expense.dart';
import '../../utils/theme.dart';
import '../../utils/constants.dart';
import 'add_expense_screen.dart';
import '../../utils/expense_type.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  String _searchQuery = '';
  ExpenseTag? _filterTag;
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExpenseProvider>().loadRecentExpenses();
    });
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 300) {
      context.read<ExpenseProvider>().loadMoreExpenses();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  List<Expense> _filtered(List<Expense> all) {
    return all.where((e) {
      final matchSearch =
          _searchQuery.isEmpty ||
          e.title.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchTag =
          _filterTag == null ||
          ExpenseTagHelper.fromString(e.tag) == _filterTag;
      return matchSearch && matchTag;
    }).toList();
  }

  Future<void> _deleteExpense(BuildContext context, Expense expense) async {
    final action = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.card(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          expense.isRecurring ? 'Delete recurring expense?' : 'Delete Expense?',
          style: TextStyle(color: AppColors.textPrimary(context)),
        ),
        content: Text(
          expense.isRecurring
              ? 'Choose what should happen to this recurring expense.'
              : '"${expense.title}" of ${AppConstants.currency}${expense.amount.toStringAsFixed(0)} will be deleted.',
          style: TextStyle(color: AppColors.textSecondary(context)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary(context)),
            ),
          ),
          if (expense.isRecurring)
            TextButton(
              onPressed: () => Navigator.pop(context, 'stop'),
              child: const Text('Stop future occurrences'),
            ),
          if (expense.isRecurring)
            TextButton(
              onPressed: () => Navigator.pop(context, 'delete_future'),
              child: const Text('Delete this and future'),
            ),
          ElevatedButton(
            onPressed: () => Navigator.pop(
              context,
              expense.isRecurring ? 'delete_one' : 'delete',
            ),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.expense),
            child: Text(
              expense.isRecurring ? 'Delete this occurrence' : 'Delete',
            ),
          ),
        ],
      ),
    );
    if (action != null && mounted) {
      final provider = context.read<ExpenseProvider>();
      if (action == 'delete_one') {
        await provider.deleteRecurringOccurrence(expense);
      } else if (action == 'stop') {
        await provider.stopRecurringSeries(expense);
      } else if (action == 'delete_future') {
        await provider.deleteRecurringSeriesFrom(expense);
      } else if (action == 'delete') {
        await provider.deleteExpense(expense.id!);
      }
      if (mounted) {
        AppUtils.showToast(
          context,
          action == 'stop' ? 'Future occurrences stopped' : 'Expense deleted',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        title: const Text('Expenses'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list_outlined),
            onPressed: _showFilterSheet,
            tooltip: 'Filter',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'transactions_add_expense',
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddExpenseScreen()),
        ).then((_) => context.read<ExpenseProvider>().loadRecentExpenses()),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              controller: _searchController,
              style: TextStyle(
                color: AppColors.textPrimary(context),
                fontSize: 14,
              ),
              decoration: InputDecoration(
                hintText: 'Search expenses...',
                prefixIcon: Icon(
                  Icons.search,
                  color: AppColors.textSecondary(context),
                  size: 20,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.close,
                          color: AppColors.textSecondary(context),
                          size: 18,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),

          // Tag filter chip
          if (_filterTag != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: ExpenseTagHelper.color(
                        _filterTag!,
                      ).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: ExpenseTagHelper.color(
                          _filterTag!,
                        ).withOpacity(0.4),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          ExpenseTagHelper.icon(_filterTag!),
                          size: 14,
                          color: ExpenseTagHelper.color(_filterTag!),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          ExpenseTagHelper.label(_filterTag!),
                          style: TextStyle(
                            color: ExpenseTagHelper.color(_filterTag!),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: () => setState(() => _filterTag = null),
                          child: Icon(
                            Icons.close,
                            size: 14,
                            color: ExpenseTagHelper.color(_filterTag!),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 12),

          // List
          Expanded(
            child: Consumer<ExpenseProvider>(
              builder: (context, provider, _) {
                final filtered = _filtered(provider.expenses);

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          color: AppColors.textSecondary(
                            context,
                          ).withOpacity(0.4),
                          size: 56,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No expenses found',
                          style: TextStyle(
                            color: AppColors.textSecondary(context),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Tap + to add your first expense',
                          style: TextStyle(
                            color: AppColors.textSecondary(context),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Group by date
                final grouped = <String, List<Expense>>{};
                for (final e in filtered) {
                  final key = DateFormat('d MMMM yyyy').format(e.date);
                  grouped.putIfAbsent(key, () => []).add(e);
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  itemCount:
                      grouped.length + (provider.isLoadingMoreExpenses ? 1 : 0),
                  itemBuilder: (_, i) {
                    if (i == grouped.length) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                        ),
                      );
                    }
                    final date = grouped.keys.elementAt(i);
                    final dayExpenses = grouped[date]!;
                    final dayTotal = dayExpenses.fold(
                      0.0,
                      (sum, e) => sum + e.amount,
                    );

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Date header
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                date,
                                style: TextStyle(
                                  color: AppColors.textSecondary(context),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Text(
                                '-${AppConstants.currency}${NumberFormat('#,##,###').format(dayTotal)}',
                                style: const TextStyle(
                                  color: AppColors.expense,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Expense cards
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.card(context),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: AppColors.border(context),
                            ),
                          ),
                          child: Column(
                            children: dayExpenses.asMap().entries.map((e) {
                              final isLast = e.key == dayExpenses.length - 1;
                              return Column(
                                children: [
                                  _ExpenseCard(
                                    expense: e.value,
                                    onEdit: () =>
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => AddExpenseScreen(
                                              existing: e.value,
                                            ),
                                          ),
                                        ).then(
                                          (_) => context
                                              .read<ExpenseProvider>()
                                              .loadRecentExpenses(),
                                        ),
                                    onDelete: () =>
                                        _deleteExpense(context, e.value),
                                  ),
                                  if (!isLast)
                                    Divider(
                                      height: 1,
                                      color: AppColors.border(context),
                                      indent: 60,
                                    ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card(context),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
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
                  'Filter by Tag',
                  style: TextStyle(
                    color: AppColors.textPrimary(context),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    GestureDetector(
                      onTap: () {
                        setState(() => _filterTag = null);
                        Navigator.pop(context);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: _filterTag == null
                              ? AppColors.primary.withOpacity(0.2)
                              : AppColors.surface(context),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _filterTag == null
                                ? AppColors.primary
                                : AppColors.border(context),
                          ),
                        ),
                        child: Text(
                          'All Tags',
                          style: TextStyle(
                            color: _filterTag == null
                                ? AppColors.primary
                                : AppColors.textSecondary(context),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    ...ExpenseTagHelper.all.map((tag) {
                      final selected = _filterTag == tag;
                      final color = ExpenseTagHelper.color(tag);
                      return GestureDetector(
                        onTap: () {
                          setState(() => _filterTag = tag);
                          Navigator.pop(context);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: selected
                                ? color.withOpacity(0.2)
                                : AppColors.surface(context),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: selected
                                  ? color
                                  : AppColors.border(context),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                ExpenseTagHelper.icon(tag),
                                color: selected
                                    ? color
                                    : AppColors.textSecondary(context),
                                size: 14,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                ExpenseTagHelper.label(tag),
                                style: TextStyle(
                                  color: selected
                                      ? color
                                      : AppColors.textSecondary(context),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Expense Card with Swipe ──────────────────────────────────────────────────

class _ExpenseCard extends StatelessWidget {
  final Expense expense;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ExpenseCard({
    required this.expense,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    // Read from Tag instead of Category
    final tagEnum = ExpenseTagHelper.fromString(expense.tag);
    final color = ExpenseTagHelper.color(tagEnum);
    final icon = ExpenseTagHelper.icon(tagEnum);
    final name = ExpenseTagHelper.label(tagEnum);

    return Dismissible(
      key: Key('expense_${expense.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.expense.withOpacity(0.15),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(
          Icons.delete_outline,
          color: AppColors.expense,
          size: 24,
        ),
      ),
      confirmDismiss: (_) async {
        onDelete();
        return false;
      },
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                expense.title,
                style: TextStyle(
                  color: AppColors.textPrimary(context),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (expense.isRecurring)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.purple.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Recurring',
                  style: TextStyle(
                    color: AppColors.purple,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: TextStyle(
                color: AppColors.textSecondary(context),
                fontSize: 12,
              ),
            ),
            // Left this in just in case old expenses still have comments stored!
            if (expense.comments != null && expense.comments!.isNotEmpty)
              Text(
                expense.comments!,
                style: TextStyle(
                  color: AppColors.textMuted(context),
                  fontSize: 11,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '-${AppConstants.currency}${NumberFormat('#,##,###').format(expense.amount)}',
              style: const TextStyle(
                color: AppColors.expense,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            GestureDetector(
              onTap: onEdit,
              child: const Text(
                'Edit',
                style: TextStyle(
                  color: AppColors.info,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
