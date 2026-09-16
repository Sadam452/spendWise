import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../providers/lending_provider.dart';
import '../../models/lending_models.dart';
import '../../utils/theme.dart';
import '../../utils/constants.dart';

// ─── TOP LEVEL UTILITIES ─────────────────────────────────────────────────────

Future<void> _sendWhatsApp(
  BuildContext context,
  String phone,
  String name,
  double amount,
  DateTime date,
) async {
  final amountStr = amount.toStringAsFixed(0);
  final dateStr = DateFormat('d MMM yyyy').format(date);
  final msg = Uri.encodeComponent(
    'Hi $name, just a friendly reminder that ₹$amountStr is pending from $dateStr. Please settle when convenient. Thanks!',
  );

  String formattedPhone = phone.trim().replaceAll('+', '');
  if (!formattedPhone.startsWith('91') && formattedPhone.length == 10) {
    formattedPhone = '91$formattedPhone';
  }

  final appUrl = Uri.parse('whatsapp://send?phone=$formattedPhone&text=$msg');
  final webUrl = Uri.parse('https://wa.me/$formattedPhone?text=$msg');

  try {
    if (await canLaunchUrl(appUrl)) {
      await launchUrl(appUrl);
    } else {
      await launchUrl(webUrl, mode: LaunchMode.externalApplication);
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not launch WhatsApp')),
      );
    }
  }
}

Future<void> _confirmSettle(
  BuildContext context,
  int lendingId,
  String type,
  double remainingAmount,
  String name,
) async {
  final themeColor = type == 'lent' ? AppColors.purple : AppColors.teal;

  final confirm = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      backgroundColor: AppColors.card(context),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        'Settle Full Amount?',
        style: TextStyle(color: AppColors.textPrimary(context)),
      ),
      content: Text(
        'This will record a final repayment of ${AppConstants.currency}${remainingAmount.toStringAsFixed(0)} and mark the record with $name as completely settled.',
        style: TextStyle(color: AppColors.textSecondary(context)),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(
            'Cancel',
            style: TextStyle(color: AppColors.textSecondary(context)),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(backgroundColor: themeColor),
          child: const Text('Confirm'),
        ),
      ],
    ),
  );

  if (confirm == true && context.mounted) {
    await context.read<LendingProvider>().addPartialReturn(
      lendingId: lendingId,
      type: type,
      amount: remainingAmount,
      date: DateTime.now(),
      comments: 'Settled in full',
    );
    if (context.mounted) {
      AppUtils.showToast(context, 'Marked as fully settled!');
    }
  }
}

void _showPartialReturnDialog(
  BuildContext context,
  int lendingId,
  String type,
  double maxAmount,
) {
  final amountCtrl = TextEditingController();
  final commentCtrl = TextEditingController();
  DateTime selectedDate = DateTime.now();
  final formKey = GlobalKey<FormState>();

  final themeColor = type == 'lent' ? AppColors.purple : AppColors.teal;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.card(context),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setSheetState) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: 24,
          right: 24,
          top: 24,
        ),
        child: Form(
          key: formKey,
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
                'Record Repayment',
                style: TextStyle(
                  color: AppColors.textPrimary(context),
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Remaining: ${AppConstants.currency}${maxAmount.toStringAsFixed(0)}',
                style: const TextStyle(
                  color: AppColors.warning,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                autofocus: true,
                style: TextStyle(
                  color: AppColors.textPrimary(context),
                  fontSize: 16,
                ),
                decoration: InputDecoration(
                  labelText: 'Amount Paid',
                  prefixText: '${AppConstants.currency} ',
                  prefixStyle: TextStyle(
                    color: themeColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Enter amount';
                  final val = double.tryParse(v);
                  if (val == null || val <= 0) return 'Invalid amount';
                  if (val > maxAmount) return 'Cannot exceed remaining balance';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null)
                    setSheetState(() => selectedDate = picked);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border(context)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today, color: themeColor, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        DateFormat('dd MMM yyyy').format(selectedDate),
                        style: TextStyle(
                          color: AppColors.textPrimary(context),
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: commentCtrl,
                textCapitalization: TextCapitalization.sentences,
                style: TextStyle(
                  color: AppColors.textPrimary(context),
                  fontSize: 16,
                ),
                decoration: InputDecoration(
                  labelText: 'Comment (Optional)',
                  hintText: 'e.g., GPay, Cash, Bank Transfer',
                  prefixIcon: Icon(Icons.notes, color: themeColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    await context.read<LendingProvider>().addPartialReturn(
                      lendingId: lendingId,
                      type: type,
                      amount: double.parse(amountCtrl.text),
                      date: selectedDate,
                      comments: commentCtrl.text.trim().isEmpty
                          ? null
                          : commentCtrl.text.trim(),
                    );
                    if (ctx.mounted) {
                      AppUtils.showToast(ctx, 'Repayment recorded');
                      Navigator.pop(ctx);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Save Repayment',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    ),
  );
}

void _showHistorySheet(BuildContext context, int lendingId, String type) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true, // FIX 1: Allows the sheet to expand properly
    backgroundColor: AppColors.card(context),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => FutureBuilder<List<LendingTransaction>>(
      future: context.read<LendingProvider>().getReturnHistory(lendingId, type),
      builder: (ctx, snapshot) {
        if (!snapshot.hasData)
          return const SizedBox(
            height: 200,
            child: Center(child: CircularProgressIndicator()),
          );
        final history = snapshot.data!;

        return SafeArea(
          child: Container(
            // FIX 2: Caps the max height safely at 80% of the screen
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize:
                  MainAxisSize.min, // Shrinks neatly if there's only 1 item
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
                  'Repayment History',
                  style: TextStyle(
                    color: AppColors.textPrimary(context),
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),

                if (history.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 30),
                    child: Center(
                      child: Text(
                        'No repayments yet.',
                        style: TextStyle(
                          color: AppColors.textSecondary(context),
                        ),
                      ),
                    ),
                  )
                else
                  // FIX 3: Flexible + default ListView allows infinite safe scrolling
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: history.length,
                      separatorBuilder: (_, __) =>
                          Divider(color: AppColors.border(context)),
                      itemBuilder: (_, i) {
                        final h = history[i];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: AppColors.primary.withOpacity(
                              0.15,
                            ),
                            child: const Icon(
                              Icons.check,
                              color: AppColors.primary,
                              size: 18,
                            ),
                          ),
                          title: Text(
                            '${AppConstants.currency}${h.amount.toStringAsFixed(0)}',
                            style: TextStyle(
                              color: AppColors.textPrimary(context),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          subtitle: Text(
                            h.comments ?? 'No comment',
                            style: TextStyle(
                              color: AppColors.textSecondary(context),
                              fontSize: 12,
                            ),
                          ),
                          trailing: Text(
                            DateFormat('dd MMM yyyy').format(h.date),
                            style: TextStyle(
                              color: AppColors.textSecondary(context),
                              fontSize: 12,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    ),
  );
}
// ─── MAIN SCREEN ──────────────────────────────────────────────────────────────

class LendingScreen extends StatefulWidget {
  const LendingScreen({super.key});

  @override
  State<LendingScreen> createState() => _LendingScreenState();
}

class _LendingScreenState extends State<LendingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LendingProvider>().loadAll();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        title: const Text('Lend & Borrow'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.purple,
          indicatorWeight: 3,
          labelColor: AppColors.purple,
          unselectedLabelColor: AppColors.textSecondary(context),
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          tabs: const [
            Tab(icon: Icon(Icons.arrow_upward, size: 18), text: 'I Lent'),
            Tab(icon: Icon(Icons.arrow_downward, size: 18), text: 'I Borrowed'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_LentTab(), _BorrowedTab()],
      ),
    );
  }
}

// ─── LENT TAB ─────────────────────────────────────────────────────────────────

class _LentTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<LendingProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          backgroundColor: AppColors.background(context),
          floatingActionButton: FloatingActionButton(
            heroTag: 'add_lent_money',
            onPressed: () => _showLentDialog(context, null),
            backgroundColor: AppColors.purple,
            child: const Icon(Icons.add, color: Colors.white),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            child: Column(
              children: [
                _LendingSummary(
                  totalLabel: 'Total Lent',
                  total: provider.totalLent,
                  returnedLabel: 'Returned',
                  returned: provider.totalLentReturned,
                  outstandingLabel: 'Outstanding',
                  outstanding: provider.outstandingLent,
                  color: AppColors.purple,
                ),
                const SizedBox(height: 20),
                if (provider.lentList.isEmpty)
                  _buildEmpty(
                    context,
                    'No lent money records',
                    'Tap + to record money you lent',
                    Icons.arrow_upward,
                  )
                else
                  Column(
                    children: provider.groupedLent
                        .map(
                          (person) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _PersonLentCard(
                              person: person,
                              onAddMore: (entry) => _showLentDialog(
                                context,
                                null,
                                prefillName: person.name,
                                prefillPhone: person.phone,
                              ),
                              onEdit: (entry) =>
                                  _showLentDialog(context, entry),
                              onDelete: (entry) => _deleteLent(context, entry),
                              onReturn: (entry) => _showPartialReturnDialog(
                                context,
                                entry.id!,
                                'lent',
                                entry.outstanding,
                              ),
                              onHistory: (entry) =>
                                  _showHistorySheet(context, entry.id!, 'lent'),
                              onSettle: (entry) => _confirmSettle(
                                context,
                                entry.id!,
                                'lent',
                                entry.outstanding,
                                entry.recipientName,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _deleteLent(BuildContext context, LentMoney entry) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.card(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete Record?',
          style: TextStyle(color: AppColors.textPrimary(context)),
        ),
        content: Text(
          'Lent ${AppConstants.currency}${entry.amount.toStringAsFixed(0)} to ${entry.recipientName} will be deleted.',
          style: TextStyle(color: AppColors.textSecondary(context)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary(context)),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.expense),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true && context.mounted) {
      context.read<LendingProvider>().deleteLent(entry.id!);
      AppUtils.showToast(context, 'Record deleted');
    }
  }
}

// ─── BORROWED TAB ─────────────────────────────────────────────────────────────

class _BorrowedTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<LendingProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          backgroundColor: AppColors.background(context),
          floatingActionButton: FloatingActionButton(
            heroTag: 'add_borrowed_money',
            onPressed: () => _showBorrowedDialog(context, null),
            backgroundColor: AppColors.teal,
            child: const Icon(Icons.add, color: Colors.white),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            child: Column(
              children: [
                _LendingSummary(
                  totalLabel: 'Total Borrowed',
                  total: provider.totalBorrowed,
                  returnedLabel: 'Returned',
                  returned: provider.totalBorrowedReturned,
                  outstandingLabel: 'Still Owe',
                  outstanding: provider.outstandingBorrowed,
                  color: AppColors.teal,
                ),
                const SizedBox(height: 20),
                if (provider.borrowedList.isEmpty)
                  _buildEmpty(
                    context,
                    'No borrowed money records',
                    'Tap + to record money you borrowed',
                    Icons.arrow_downward,
                  )
                else
                  Column(
                    children: provider.groupedBorrowed
                        .map(
                          (person) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _PersonBorrowedCard(
                              person: person,
                              onAddMore: (entry) => _showBorrowedDialog(
                                context,
                                null,
                                prefillName: person.name,
                                prefillPhone: person.phone,
                              ),
                              onEdit: (entry) {
                                _showBorrowedDialog(
                                  context,
                                  BorrowedMoney(
                                    id: entry.id,
                                    amount: entry.amount,
                                    date: entry.date,
                                    lenderName: entry.recipientName,
                                    phone: entry.phone,
                                    notes: entry.notes,
                                    amountReturned: entry.amountReturned,
                                    isSettled: entry.isSettled,
                                  ),
                                );
                              },
                              onDelete: (entry) {
                                _deleteBorrowed(
                                  context,
                                  BorrowedMoney(
                                    id: entry.id,
                                    amount: entry.amount,
                                    date: entry.date,
                                    lenderName: entry.recipientName,
                                    phone: entry.phone,
                                    notes: entry.notes,
                                    amountReturned: entry.amountReturned,
                                    isSettled: entry.isSettled,
                                  ),
                                );
                              },
                              onReturn: (entry) => _showPartialReturnDialog(
                                context,
                                entry.id!,
                                'borrowed',
                                entry.outstanding,
                              ),
                              onHistory: (entry) => _showHistorySheet(
                                context,
                                entry.id!,
                                'borrowed',
                              ),
                              onSettle: (entry) => _confirmSettle(
                                context,
                                entry.id!,
                                'borrowed',
                                entry.outstanding,
                                entry.recipientName,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _deleteBorrowed(
    BuildContext context,
    BorrowedMoney entry,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.card(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete Record?',
          style: TextStyle(color: AppColors.textPrimary(context)),
        ),
        content: Text(
          'Borrowed ${AppConstants.currency}${entry.amount.toStringAsFixed(0)} from ${entry.lenderName} will be deleted.',
          style: TextStyle(color: AppColors.textSecondary(context)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary(context)),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.expense),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true && context.mounted) {
      context.read<LendingProvider>().deleteBorrowed(entry.id!);
      AppUtils.showToast(context, 'Record deleted');
    }
  }
}

// ─── SHARED WIDGETS & CARDS ───────────────────────────────────────────────────

class _LendingSummary extends StatelessWidget {
  final String totalLabel;
  final double total;
  final String returnedLabel;
  final double returned;
  final String outstandingLabel;
  final double outstanding;
  final Color color;

  const _LendingSummary({
    required this.totalLabel,
    required this.total,
    required this.returnedLabel,
    required this.returned,
    required this.outstandingLabel,
    required this.outstanding,
    required this.color,
  });

  String _fmt(double v) =>
      '${AppConstants.currency}${NumberFormat('#,##,###').format(v)}';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Expanded(child: _statItem(context, totalLabel, _fmt(total), color)),
          _divider(context),
          Expanded(
            child: _statItem(
              context,
              returnedLabel,
              _fmt(returned),
              AppColors.primary,
            ),
          ),
          _divider(context),
          Expanded(
            child: _statItem(
              context,
              outstandingLabel,
              _fmt(outstanding),
              outstanding > 0 ? AppColors.warning : AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statItem(BuildContext context, String label, String value, Color c) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(color: c, fontSize: 16, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: AppColors.textSecondary(context),
            fontSize: 11,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _divider(BuildContext context) => Container(
    width: 1,
    height: 40,
    color: AppColors.border(context),
    margin: const EdgeInsets.symmetric(horizontal: 8),
  );
}

class _PersonLentCard extends StatefulWidget {
  final PersonLendingSummary person;
  final Function(LentMoney) onAddMore;
  final Function(LentMoney) onDelete;
  final Function(LentMoney) onEdit;
  final Function(LentMoney) onReturn;
  final Function(LentMoney) onHistory;
  final Function(LentMoney) onSettle;

  const _PersonLentCard({
    required this.person,
    required this.onAddMore,
    required this.onDelete,
    required this.onEdit,
    required this.onReturn,
    required this.onHistory,
    required this.onSettle,
  });

  @override
  State<_PersonLentCard> createState() => _PersonLentCardState();
}

class _PersonLentCardState extends State<_PersonLentCard> {
  bool _expanded = false;

  String _fmt(double v) =>
      '${AppConstants.currency}${NumberFormat('#,##,###').format(v)}';

  @override
  Widget build(BuildContext context) {
    final p = widget.person;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.purple.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        p.name[0].toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.purple,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.name,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: TextStyle(
                            color: AppColors.textPrimary(context),
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          p.phone,
                          style: TextStyle(
                            color: AppColors.textSecondary(context),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _fmt(p.totalAmount),
                        style: const TextStyle(
                          color: AppColors.purple,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'Due: ${_fmt(p.outstanding)}',
                        style: TextStyle(
                          color: p.outstanding > 0
                              ? AppColors.warning
                              : AppColors.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: AppColors.textSecondary(context),
                  ),
                ],
              ),
            ),
          ),
          if (_expanded)
            Column(
              children: p.entries.map((entry) {
                final bool isSettled = entry.isSettled;

                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.background(context),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSettled
                            ? AppColors.primary.withOpacity(0.5)
                            : AppColors.border(context),
                      ),
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          DateFormat(
                                            'd MMM yyyy',
                                          ).format(entry.date),
                                          style: TextStyle(
                                            color: AppColors.textSecondary(
                                              context,
                                            ),
                                            fontSize: 11,
                                          ),
                                        ),
                                        if (isSettled) ...[
                                          const SizedBox(width: 6),
                                          const Icon(
                                            Icons.check_circle,
                                            color: AppColors.primary,
                                            size: 12,
                                          ),
                                          const SizedBox(width: 2),
                                          const Text(
                                            "Settled",
                                            style: TextStyle(
                                              color: AppColors.primary,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    if (entry.notes != null &&
                                        entry.notes!.isNotEmpty)
                                      Text(
                                        entry.notes!,
                                        style: TextStyle(
                                          color: AppColors.textMuted(context),
                                          fontSize: 11,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    _fmt(entry.amount),
                                    style: TextStyle(
                                      color: isSettled
                                          ? AppColors.textSecondary(context)
                                          : AppColors.purple,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  if (entry.amountReturned > 0)
                                    Text(
                                      'Returned: ${_fmt(entry.amountReturned)}',
                                      style: const TextStyle(
                                        color: AppColors.primary,
                                        fontSize: 10,
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.only(
                            left: 12,
                            right: 4,
                            top: 4,
                            bottom: 4,
                          ),
                          decoration: BoxDecoration(
                            border: Border(
                              top: BorderSide(color: AppColors.border(context)),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  TextButton.icon(
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      foregroundColor: AppColors.primary,
                                    ),
                                    onPressed: isSettled
                                        ? null
                                        : () => widget.onReturn(entry),
                                    icon: const Icon(
                                      Icons.check_circle_outline,
                                      size: 18,
                                    ),
                                    label: const Text(
                                      'Return',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  TextButton.icon(
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      foregroundColor: AppColors.purple,
                                    ),
                                    onPressed: isSettled
                                        ? null
                                        : () => widget.onSettle(entry),
                                    icon: const Icon(Icons.done_all, size: 18),
                                    label: const Text(
                                      'Settle All',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              PopupMenuButton<String>(
                                icon: Icon(
                                  Icons.more_vert,
                                  color: AppColors.textSecondary(context),
                                ),
                                color: AppColors.card(context),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                onSelected: (value) {
                                  if (value == 'history')
                                    widget.onHistory(entry);
                                  else if (value == 'notify') {
                                    final oldest = widget.person.entries.reduce(
                                      (a, b) => a.date.isBefore(b.date) ? a : b,
                                    );
                                    _sendWhatsApp(
                                      context,
                                      widget.person.phone,
                                      widget.person.name,
                                      widget.person.totalAmount,
                                      oldest.date,
                                    );
                                  } else if (value == 'add_more')
                                    widget.onAddMore(entry);
                                  else if (value == 'edit')
                                    widget.onEdit(entry);
                                  else if (value == 'delete')
                                    widget.onDelete(entry);
                                },
                                itemBuilder: (context) => [
                                  PopupMenuItem(
                                    value: 'add_more',
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.add_circle_outline,
                                          size: 18,
                                          color: AppColors.purple,
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          'Add more to this person',
                                          style: TextStyle(
                                            color: AppColors.textPrimary(
                                              context,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 'history',
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.history,
                                          size: 18,
                                          color: AppColors.info,
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          'History',
                                          style: TextStyle(
                                            color: AppColors.textPrimary(
                                              context,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (!isSettled)
                                    PopupMenuItem(
                                      value: 'notify',
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.chat_bubble_outline,
                                            size: 18,
                                            color: AppColors.warning,
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            'Notify',
                                            style: TextStyle(
                                              color: AppColors.textPrimary(
                                                context,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  if (!isSettled)
                                    PopupMenuItem(
                                      value: 'edit',
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.edit_outlined,
                                            size: 18,
                                            color: AppColors.textPrimary(
                                              context,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            'Edit',
                                            style: TextStyle(
                                              color: AppColors.textPrimary(
                                                context,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  if (!isSettled)
                                    PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.delete_outline,
                                            size: 18,
                                            color: AppColors.expense,
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            'Delete',
                                            style: TextStyle(
                                              color: AppColors.expense,
                                            ),
                                          ),
                                        ],
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
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}

class _PersonBorrowedCard extends StatefulWidget {
  final PersonLendingSummary person;
  final Function(LentMoney) onAddMore;
  final Function(dynamic) onEdit;
  final Function(dynamic) onDelete;
  final Function(dynamic) onReturn;
  final Function(dynamic) onHistory;
  final Function(dynamic) onSettle;

  const _PersonBorrowedCard({
    required this.person,
    required this.onAddMore,
    required this.onEdit,
    required this.onDelete,
    required this.onReturn,
    required this.onHistory,
    required this.onSettle,
  });

  @override
  State<_PersonBorrowedCard> createState() => _PersonBorrowedCardState();
}

class _PersonBorrowedCardState extends State<_PersonBorrowedCard> {
  bool _expanded = false;

  String _fmt(double v) =>
      '${AppConstants.currency}${NumberFormat('#,##,###').format(v)}';

  @override
  Widget build(BuildContext context) {
    final p = widget.person;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.teal.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        p.name[0].toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.teal,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.name,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: TextStyle(
                            color: AppColors.textPrimary(context),
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          p.phone,
                          style: TextStyle(
                            color: AppColors.textSecondary(context),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _fmt(p.totalAmount),
                        style: const TextStyle(
                          color: AppColors.teal,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'Owe: ${_fmt(p.outstanding)}',
                        style: TextStyle(
                          color: p.outstanding > 0
                              ? AppColors.expense
                              : AppColors.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: AppColors.textSecondary(context),
                  ),
                ],
              ),
            ),
          ),
          if (_expanded)
            Column(
              children: p.entries.map((entry) {
                final bool isSettled = entry.isSettled;

                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.background(context),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSettled
                            ? AppColors.primary.withOpacity(0.5)
                            : AppColors.border(context),
                      ),
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          DateFormat(
                                            'd MMM yyyy',
                                          ).format(entry.date),
                                          style: TextStyle(
                                            color: AppColors.textSecondary(
                                              context,
                                            ),
                                            fontSize: 11,
                                          ),
                                        ),
                                        if (isSettled) ...[
                                          const SizedBox(width: 6),
                                          const Icon(
                                            Icons.check_circle,
                                            color: AppColors.primary,
                                            size: 12,
                                          ),
                                          const SizedBox(width: 2),
                                          const Text(
                                            "Settled",
                                            style: TextStyle(
                                              color: AppColors.primary,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    if (entry.notes != null &&
                                        entry.notes!.isNotEmpty)
                                      Text(
                                        entry.notes!,
                                        style: TextStyle(
                                          color: AppColors.textMuted(context),
                                          fontSize: 11,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    _fmt(entry.amount),
                                    style: TextStyle(
                                      color: isSettled
                                          ? AppColors.textSecondary(context)
                                          : AppColors.teal,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  if (entry.amountReturned > 0)
                                    Text(
                                      'Paid: ${_fmt(entry.amountReturned)}',
                                      style: const TextStyle(
                                        color: AppColors.primary,
                                        fontSize: 10,
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.only(
                            left: 12,
                            right: 4,
                            top: 4,
                            bottom: 4,
                          ),
                          decoration: BoxDecoration(
                            border: Border(
                              top: BorderSide(color: AppColors.border(context)),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  TextButton.icon(
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      foregroundColor: AppColors.teal,
                                    ),
                                    onPressed: isSettled
                                        ? null
                                        : () => widget.onReturn(entry),
                                    icon: const Icon(
                                      Icons.check_circle_outline,
                                      size: 18,
                                    ),
                                    label: const Text(
                                      'Pay',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  TextButton.icon(
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      foregroundColor: AppColors.teal,
                                    ),
                                    onPressed: isSettled
                                        ? null
                                        : () => widget.onSettle(entry),
                                    icon: const Icon(Icons.done_all, size: 18),
                                    label: const Text(
                                      'Settle All',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              PopupMenuButton<String>(
                                icon: Icon(
                                  Icons.more_vert,
                                  color: AppColors.textSecondary(context),
                                ),
                                color: AppColors.card(context),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                onSelected: (value) {
                                  if (value == 'history')
                                    widget.onHistory(entry);
                                  else if (value == 'add_more')
                                    widget.onAddMore(entry);
                                  else if (value == 'edit')
                                    widget.onEdit(entry);
                                  else if (value == 'delete')
                                    widget.onDelete(entry);
                                },
                                itemBuilder: (context) => [
                                  PopupMenuItem(
                                    value: 'add_more',
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.add_circle_outline,
                                          size: 18,
                                          color: AppColors.teal,
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          'Add more to this person',
                                          style: TextStyle(
                                            color: AppColors.textPrimary(
                                              context,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 'history',
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.history,
                                          size: 18,
                                          color: AppColors.info,
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          'History',
                                          style: TextStyle(
                                            color: AppColors.textPrimary(
                                              context,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (!isSettled)
                                    PopupMenuItem(
                                      value: 'edit',
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.edit_outlined,
                                            size: 18,
                                            color: AppColors.textPrimary(
                                              context,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            'Edit',
                                            style: TextStyle(
                                              color: AppColors.textPrimary(
                                                context,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  if (!isSettled)
                                    PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.delete_outline,
                                            size: 18,
                                            color: AppColors.expense,
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            'Delete',
                                            style: TextStyle(
                                              color: AppColors.expense,
                                            ),
                                          ),
                                        ],
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
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}

Widget _buildEmpty(
  BuildContext context,
  String title,
  String sub,
  IconData icon,
) {
  return Container(
    padding: const EdgeInsets.all(40),
    decoration: BoxDecoration(
      color: AppColors.card(context),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppColors.border(context)),
    ),
    child: Center(
      child: Column(
        children: [
          Icon(
            icon,
            color: AppColors.textSecondary(context).withOpacity(0.4),
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              color: AppColors.textSecondary(context),
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            sub,
            style: TextStyle(
              color: AppColors.textSecondary(context),
              fontSize: 13,
            ),
          ),
        ],
      ),
    ),
  );
}

// ─── ADD/EDIT DIALOGS ─────────────────────────────────────────────────────────

void _showLentDialog(
  BuildContext context,
  LentMoney? existing, {
  String? prefillName,
  String? prefillPhone,
}) {
  final nameCtrl = TextEditingController(
    text: existing?.recipientName ?? prefillName ?? '',
  );
  final phoneCtrl = TextEditingController(
    text: existing?.phone ?? prefillPhone ?? '',
  );
  final amountCtrl = TextEditingController(
    text: existing != null ? existing.amount.toStringAsFixed(0) : '',
  );
  final notesCtrl = TextEditingController(text: existing?.notes ?? '');
  DateTime selectedDate = existing?.date ?? DateTime.now();
  final formKey = GlobalKey<FormState>();

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.card(context),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setModalState) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: formKey,
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
                  existing == null ? 'Lent Money' : 'Edit Lent Record',
                  style: TextStyle(
                    color: AppColors.textPrimary(context),
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 20),
                _field(
                  context,
                  amountCtrl,
                  'Amount *',
                  '0',
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (v) => v!.trim().isEmpty ? 'Required' : null,
                  prefixText: '${AppConstants.currency} ',
                ),
                const SizedBox(height: 14),
                _field(
                  context,
                  nameCtrl,
                  'Recipient Name *',
                  'Who did you lend to?',
                  validator: (v) => v!.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 14),
                _field(
                  context,
                  phoneCtrl,
                  'Phone Number *',
                  '10-digit number',
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  validator: (v) => v!.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 14),
                _field(
                  context,
                  notesCtrl,
                  'Notes (optional)',
                  'Any additional notes...',
                ),
                const SizedBox(height: 14),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                      builder: (context, child) => Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: ColorScheme.dark(
                            primary: AppColors.purple,
                            surface: AppColors.card(context),
                            onSurface: AppColors.textPrimary(context),
                          ),
                        ),
                        child: child!,
                      ),
                    );
                    if (picked != null)
                      setModalState(() => selectedDate = picked);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.inputFill(context),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border(context)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          color: AppColors.purple,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          DateFormat('d MMM yyyy').format(selectedDate),
                          style: TextStyle(
                            color: AppColors.textPrimary(context),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      if (!formKey.currentState!.validate()) return;
                      final provider = context.read<LendingProvider>();

                      if (existing == null) {
                        provider.addLent(
                          LentMoney(
                            amount: double.parse(amountCtrl.text),
                            date: selectedDate,
                            recipientName: nameCtrl.text.trim(),
                            phone: phoneCtrl.text.trim(),
                            notes: notesCtrl.text.trim().isEmpty
                                ? null
                                : notesCtrl.text.trim(),
                          ),
                        );
                        AppUtils.showToast(context, 'Lent record added');
                      } else {
                        provider.updateLent(
                          existing.copyWith(
                            amount: double.parse(amountCtrl.text),
                            date: selectedDate,
                            recipientName: nameCtrl.text.trim(),
                            phone: phoneCtrl.text.trim(),
                            notes: notesCtrl.text.trim().isEmpty
                                ? null
                                : notesCtrl.text.trim(),
                          ),
                        );
                        AppUtils.showToast(context, 'Record updated');
                      }
                      Navigator.pop(ctx);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.purple,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      existing == null ? 'Save Record' : 'Update Record',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

void _showBorrowedDialog(
  BuildContext context,
  BorrowedMoney? existing, {
  String? prefillName,
  String? prefillPhone,
}) {
  final nameCtrl = TextEditingController(
    text: existing?.lenderName ?? prefillName ?? '',
  );
  final phoneCtrl = TextEditingController(
    text: existing?.phone ?? prefillPhone ?? '',
  );
  final amountCtrl = TextEditingController(
    text: existing != null ? existing.amount.toStringAsFixed(0) : '',
  );
  final notesCtrl = TextEditingController(text: existing?.notes ?? '');
  DateTime selectedDate = existing?.date ?? DateTime.now();
  final formKey = GlobalKey<FormState>();

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.card(context),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setModalState) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: formKey,
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
                  existing == null ? 'Borrowed Money' : 'Edit Borrowed Record',
                  style: TextStyle(
                    color: AppColors.textPrimary(context),
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 20),
                _field(
                  context,
                  amountCtrl,
                  'Amount *',
                  '0',
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (v) => v!.trim().isEmpty ? 'Required' : null,
                  prefixText: '${AppConstants.currency} ',
                ),
                const SizedBox(height: 14),
                _field(
                  context,
                  nameCtrl,
                  'Lender Name *',
                  'Who did you borrow from?',
                  validator: (v) => v!.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 14),
                _field(
                  context,
                  phoneCtrl,
                  'Phone Number *',
                  '10-digit number',
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  validator: (v) => v!.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 14),
                _field(
                  context,
                  notesCtrl,
                  'Notes (optional)',
                  'Any additional notes...',
                ),
                const SizedBox(height: 14),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                      builder: (context, child) => Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: ColorScheme.dark(
                            primary: AppColors.teal,
                            surface: AppColors.card(context),
                            onSurface: AppColors.textPrimary(context),
                          ),
                        ),
                        child: child!,
                      ),
                    );
                    if (picked != null)
                      setModalState(() => selectedDate = picked);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.inputFill(context),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border(context)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          color: AppColors.teal,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          DateFormat('d MMM yyyy').format(selectedDate),
                          style: TextStyle(
                            color: AppColors.textPrimary(context),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      if (!formKey.currentState!.validate()) return;
                      final provider = context.read<LendingProvider>();

                      if (existing == null) {
                        provider.addBorrowed(
                          BorrowedMoney(
                            amount: double.parse(amountCtrl.text),
                            date: selectedDate,
                            lenderName: nameCtrl.text.trim(),
                            phone: phoneCtrl.text.trim(),
                            notes: notesCtrl.text.trim().isEmpty
                                ? null
                                : notesCtrl.text.trim(),
                          ),
                        );
                        AppUtils.showToast(context, 'Borrowed record added');
                      } else {
                        provider.updateBorrowed(
                          existing.copyWith(
                            amount: double.parse(amountCtrl.text),
                            date: selectedDate,
                            lenderName: nameCtrl.text.trim(),
                            phone: phoneCtrl.text.trim(),
                            notes: notesCtrl.text.trim().isEmpty
                                ? null
                                : notesCtrl.text.trim(),
                          ),
                        );
                        AppUtils.showToast(context, 'Record updated');
                      }
                      Navigator.pop(ctx);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.teal,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      existing == null ? 'Save Record' : 'Update Record',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

Widget _field(
  BuildContext context,
  TextEditingController controller,
  String label,
  String hint, {
  TextInputType? keyboardType,
  List<TextInputFormatter>? inputFormatters,
  String? Function(String?)? validator,
  String? prefixText,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: TextStyle(
          color: AppColors.textSecondary(context),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
      const SizedBox(height: 6),
      TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        style: TextStyle(color: AppColors.textPrimary(context), fontSize: 15),
        decoration: InputDecoration(hintText: hint, prefixText: prefixText),
        validator: validator,
      ),
    ],
  );
}
