import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/income.dart';
import '../../providers/income_provider.dart';
import '../../utils/constants.dart';
import '../../utils/theme.dart';

class IncomeScreen extends StatelessWidget {
  const IncomeScreen({super.key});

  String _fmt(double value) =>
      '${AppConstants.currency}${NumberFormat('#,##,###').format(value)}';

  Future<void> _confirmDelete(BuildContext context, Income income) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete income?'),
        content: Text(
          '${income.source} of ${AppConstants.currency}${income.amount.toStringAsFixed(0)} will be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.expense),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && income.id != null && context.mounted) {
      await context.read<IncomeProvider>().deleteIncome(income.id!);
    }
  }

  Future<void> _edit(BuildContext context, [Income? existing]) async {
    final provider = context.read<IncomeProvider>();
    DateTime selectedDate = existing?.date ?? DateTime.now();
    final amount = TextEditingController(
      text: existing == null ? '0' : existing.amount.toStringAsFixed(0),
    );
    final source = TextEditingController(
      text: existing == null ? 'Salary' : existing.source,
    );
    final notes = TextEditingController(
      text: existing == null
          ? 'Salary ${DateFormat('MMMM').format(selectedDate)}'
          : existing.notes ?? '',
    );
    final formKey = GlobalKey<FormState>();
    var saving = false;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return AlertDialog(
            title: Text(existing == null ? 'Add income' : 'Edit income'),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: amount,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Amount'),
                      validator: (value) => double.tryParse(value ?? '') == null
                          ? 'Enter a valid amount'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: source,
                      decoration: const InputDecoration(labelText: 'Source'),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'Required'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: notes,
                      decoration: const InputDecoration(
                        labelText: 'Notes (optional)',
                      ),
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: saving
                          ? null
                          : () async {
                              final picked = await showDatePicker(
                                context: dialogContext,
                                initialDate: selectedDate,
                                firstDate: DateTime(2000),
                                lastDate: DateTime.now(),
                              );
                              if (picked != null && dialogContext.mounted) {
                                setDialogState(() => selectedDate = picked);
                              }
                            },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Month / date',
                        ),
                        child: Text(
                          DateFormat('d MMMM yyyy').format(selectedDate),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: saving ? null : () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: saving
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;
                        setDialogState(() => saving = true);
                        final income = Income(
                          id: existing?.id,
                          amount: double.parse(amount.text),
                          date: selectedDate,
                          source: source.text.trim(),
                          notes: notes.text.trim().isEmpty
                              ? null
                              : notes.text.trim(),
                          createdAt: existing?.createdAt,
                        );
                        if (existing == null) {
                          await provider.persistIncome(income);
                        } else {
                          await provider.persistIncomeUpdate(income);
                        }
                        if (dialogContext.mounted) {
                          Navigator.pop(dialogContext);
                        }
                      },
                child: saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
    // The dialog future completes when pop is requested, while the route can
    // still be running its reverse transition.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    amount.dispose();
    source.dispose();
    notes.dispose();
    if (!context.mounted) return;
    await provider.load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(title: const Text('Income')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _edit(context),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Consumer<IncomeProvider>(
        builder: (context, provider, _) => Column(
          children: [
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary.withOpacity(0.25)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'This month',
                    style: TextStyle(color: AppColors.textSecondary(context)),
                  ),
                  Text(
                    _fmt(provider.currentMonthIncome),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                itemCount: provider.incomes.length,
                itemBuilder: (context, index) {
                  final income = provider.incomes[index];
                  return Dismissible(
                    key: Key('income_${income.id}'),
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
                      await _confirmDelete(context, income);
                      return false;
                    },
                    child: Card(
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Color(0x222EA043),
                          child: Icon(
                            Icons.arrow_downward,
                            color: AppColors.primary,
                          ),
                        ),
                        title: Text(income.source),
                        subtitle: Text(
                          DateFormat('d MMM yyyy').format(income.date),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _fmt(income.amount),
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            PopupMenuButton<String>(
                              onSelected: (value) async {
                                if (value == 'edit') {
                                  await _edit(context, income);
                                }
                              },
                              itemBuilder: (_) => const [
                                PopupMenuItem(
                                  value: 'edit',
                                  child: Text('Edit'),
                                ),
                              ],
                            ),
                          ],
                        ),
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
  }
}
