import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/expense_provider.dart';
import '../../models/expense.dart';
import '../../utils/theme.dart';
import '../../utils/constants.dart';
import '../../utils/expense_type.dart';

class AddExpenseScreen extends StatefulWidget {
  final Expense? existing;
  const AddExpenseScreen({super.key, this.existing});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _titleController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  // We keep this variable so the database doesn't crash,
  // but it is no longer shown in the UI.
  int _selectedCategoryId = 1;
  bool _isRecurring = false;
  bool _applyToFuture = false;
  ExpenseTag _selectedTag = ExpenseTag.personal;
  bool _isSaving = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final e = widget.existing!;
      _amountController.text = e.amount.toStringAsFixed(0);
      _titleController.text = e.title;
      _selectedDate = e.date;
      _selectedCategoryId = e.categoryId;
      _isRecurring = e.isRecurring;
      _selectedTag = ExpenseTagHelper.fromString(e.tag);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  Widget _buildTagPicker() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: ExpenseTagHelper.all.map((tag) {
        final selected = _selectedTag == tag;
        final color = ExpenseTagHelper.color(tag);
        return GestureDetector(
          onTap: () => setState(() => _selectedTag = tag),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: selected
                  ? color.withOpacity(0.15)
                  : AppColors.card(context),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected ? color : AppColors.border(context),
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  ExpenseTagHelper.icon(tag),
                  color: selected ? color : AppColors.textSecondary(context),
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  ExpenseTagHelper.label(tag),
                  style: TextStyle(
                    color: selected ? color : AppColors.textSecondary(context),
                    fontSize: 14,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(DateTime.now().year - 2),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.dark(
            primary: AppColors.primary,
            onPrimary: Colors.white,
            surface: AppColors.card(context),
            onSurface: AppColors.textPrimary(context),
          ),
          dialogTheme: DialogThemeData(
            backgroundColor: AppColors.surface(context),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final expense = Expense(
        id: widget.existing?.id,
        amount: double.parse(_amountController.text.trim()),
        date: _selectedDate,
        categoryId: _selectedCategoryId, // Hidden, defaults to 1
        title: _titleController.text.trim(),
        comments: null, // Removed from UI
        isRecurring: _isRecurring,
        tag: _selectedTag.name,
        createdAt: widget.existing?.createdAt,
      );

      final provider = context.read<ExpenseProvider>();
      if (_isEditing) {
        await provider.updateExpense(
          expense.copyWith(recurrenceGroup: widget.existing!.recurrenceGroup),
          applyToFuture: _applyToFuture,
        );
      } else {
        await provider.addExpense(expense);
      }

      if (mounted) {
        AppUtils.showToast(
          context,
          _isEditing ? 'Expense updated' : 'Expense added',
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        AppUtils.showToast(context, 'Error: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Expense' : 'New Expense'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Modern Minimalist Amount Field
              _buildAmountField(),
              const SizedBox(height: 30),

              // 2. Title field
              _buildLabel('What was this for?'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                textCapitalization: TextCapitalization.sentences,
                style: TextStyle(
                  color: AppColors.textPrimary(context),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  hintText: 'e.g. Lunch, Uber, Groceries...',
                  hintStyle: TextStyle(
                    color: AppColors.textSecondary(context).withOpacity(0.5),
                  ),
                  filled: true,
                  fillColor: AppColors.card(context),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.border(context)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.border(context)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 1.5,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
                validator: (v) =>
                    v!.trim().isEmpty ? 'Please describe this expense' : null,
              ),
              const SizedBox(height: 24),

              // 3. Date picker
              _buildLabel('Date'),
              const SizedBox(height: 8),
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.card(context),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border(context)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_outlined,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        DateFormat('EEEE, d MMMM yyyy').format(_selectedDate),
                        style: TextStyle(
                          color: AppColors.textPrimary(context),
                          fontSize: 15,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.chevron_right,
                        color: AppColors.textSecondary(context),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 4. Tags
              _buildLabel('Expense Tag'),
              const SizedBox(height: 10),
              _buildTagPicker(),
              const SizedBox(height: 24),

              // 5. Recurring toggle
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.card(context),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border(context)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.purple.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.repeat,
                        color: AppColors.purple,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Recurring Expense',
                            style: TextStyle(
                              color: AppColors.textPrimary(context),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            _isEditing &&
                                    widget.existing?.recurrenceGroup != null
                                ? 'Apply changes to future occurrences'
                                : 'Mark as monthly recurring',
                            style: TextStyle(
                              color: AppColors.textSecondary(context),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_isEditing &&
                        widget.existing?.recurrenceGroup != null) ...[
                      Checkbox(
                        value: _applyToFuture,
                        activeColor: AppColors.purple,
                        onChanged: (v) =>
                            setState(() => _applyToFuture = v ?? false),
                      ),
                      Text(
                        'Apply',
                        style: TextStyle(
                          color: AppColors.textSecondary(context),
                          fontSize: 11,
                        ),
                      ),
                    ] else
                      Switch(
                        value: _isRecurring,
                        activeColor: AppColors.purple,
                        onChanged: (v) => setState(() => _isRecurring = v),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // 6. Clean Save button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor: AppColors.primary.withOpacity(0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(
                          _isEditing ? 'Update Expense' : 'Save Expense',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // Modern, box-less amount field
  // Modern, fixed-center amount field
  // Modern, left-aligned, overflow-safe amount field
  Widget _buildAmountField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Using your exact standard label style
        _buildLabel('Amount'),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              '${AppConstants.currency} ',
              style: const TextStyle(
                color: AppColors.expense,
                fontSize: 52,
                fontWeight: FontWeight.w800,
              ),
            ),
            // The Expanded widget safely constrains the text field width,
            // completely fixing the "RIGHT OVERFLOWED" error!
            Expanded(
              child: TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                textAlign: TextAlign.left,
                autofocus: true,
                style: TextStyle(
                  color: AppColors.textPrimary(context),
                  fontSize: 52,
                  fontWeight: FontWeight.w800,
                ),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  filled: false,
                  hintText: '0',
                  hintStyle: TextStyle(
                    color: AppColors.textMuted(context),
                    fontSize: 52,
                    fontWeight: FontWeight.w800,
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  if (double.tryParse(v) == null || double.parse(v) <= 0) {
                    return 'Invalid amount';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLabel(String text) => Text(
    text,
    style: TextStyle(
      color: AppColors.textSecondary(context),
      fontSize: 13,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.3,
    ),
  );
}
