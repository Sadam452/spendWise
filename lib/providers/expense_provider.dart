import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';
import '../database/db_helper.dart';
import '../models/expense.dart';
import '../models/budget.dart';

class ExpenseProvider extends ChangeNotifier {
  final DBHelper _db = DBHelper.instance;

  // ─── State ────────────────────────────────────────────────────────────────
  List<Expense> expenses = [];
  List<Expense> filteredExpenses = [];
  double last30DaysTotal = 0;
  double currentMonthTotal = 0;
  double customRangeTotal = 0;
  List<Map<String, dynamic>> monthlyTotals = [];
  List<Map<String, dynamic>> categoryTotals = [];
  Budget? currentBudget;
  bool isLoading = false;
  bool isLoadingMoreExpenses = false;
  bool hasMoreExpenses = true;

  static const int _expensePageSize = 50;
  int _expenseOffset = 0;

  DateTime? customStart;
  DateTime? customEnd;

  String selectedFilter = 'This Month';

  // ─── Init ─────────────────────────────────────────────────────────────────
  Future<void> init() async {
    await _db.createMissingRecurringExpenses();
    await loadDashboard();
    await loadRecentExpenses();
  }

  Future<void> loadDashboard() async {
    isLoading = true;
    notifyListeners();

    final now = DateTime.now();

    // Last 30 days
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    last30DaysTotal = await _db.getTotalByDateRange(thirtyDaysAgo, now);

    // Current month
    final monthStart = DateTime(now.year, now.month, 1);
    currentMonthTotal = await _db.getTotalByDateRange(monthStart, now);

    // Monthly totals for chart
    monthlyTotals = await _db.getMonthlyTotals(now.year);

    // Category totals for current month
    categoryTotals = await _db.getCategoryTotals(monthStart, now);

    // Budget
    currentBudget = await _db.getBudget(now.month, now.year);

    isLoading = false;
    notifyListeners();
  }

  Future<void> loadRecentExpenses({int limit = _expensePageSize}) async {
    _expenseOffset = 0;
    hasMoreExpenses = true;
    final firstPage = await _db.getRecentExpenses(limit: limit);
    expenses = firstPage;
    _expenseOffset = firstPage.length;
    hasMoreExpenses = firstPage.length == limit;
    filteredExpenses = expenses;
    notifyListeners();
  }

  Future<void> loadMoreExpenses() async {
    if (isLoadingMoreExpenses || !hasMoreExpenses) return;

    isLoadingMoreExpenses = true;
    notifyListeners();
    try {
      final nextPage = await _db.getRecentExpenses(
        limit: _expensePageSize,
        offset: _expenseOffset,
      );
      expenses = [...expenses, ...nextPage];
      filteredExpenses = expenses;
      _expenseOffset += nextPage.length;
      hasMoreExpenses = nextPage.length == _expensePageSize;
    } finally {
      isLoadingMoreExpenses = false;
      notifyListeners();
    }
  }

  Future<void> loadByDateRange(DateTime start, DateTime end) async {
    isLoading = true;
    notifyListeners();
    filteredExpenses = await _db.getExpensesByDateRange(start, end);
    customRangeTotal = await _db.getTotalByDateRange(start, end);
    categoryTotals = await _db.getCategoryTotals(start, end);
    customStart = start;
    customEnd = end;
    isLoading = false;
    notifyListeners();
  }

  Future<void> loadByFilter(String filter) async {
    selectedFilter = filter;
    final now = DateTime.now();
    DateTime start;
    DateTime end = now;

    switch (filter) {
      case 'Today':
        start = DateTime(now.year, now.month, now.day);
        break;
      case 'This Week':
        start = now.subtract(Duration(days: now.weekday - 1));
        start = DateTime(start.year, start.month, start.day);
        break;
      case 'This Month':
        start = DateTime(now.year, now.month, 1);
        break;
      case 'Last 30 Days':
        start = now.subtract(const Duration(days: 30));
        break;
      default:
        start = DateTime(now.year, now.month, 1);
    }

    await loadByDateRange(start, end);
  }

  // ─── CRUD ─────────────────────────────────────────────────────────────────
  Future<void> addExpense(Expense expense) async {
    final expenseToSave = expense.isRecurring
        ? expense.copyWith(recurrenceGroup: Uuid().v4())
        : expense;
    await _db.insertExpense(expenseToSave);
    await loadDashboard();
    await loadRecentExpenses();
  }

  Future<void> updateExpense(
    Expense expense, {
    bool applyToFuture = false,
  }) async {
    await _db.updateExpense(expense);
    if (applyToFuture) {
      await _db.updateFutureRecurringExpenses(expense, fromDate: expense.date);
    }
    await loadDashboard();
    await loadRecentExpenses();
  }

  Future<void> deleteExpense(int id) async {
    await _db.deleteExpense(id);
    await loadDashboard();
    await loadRecentExpenses();
  }

  Future<void> deleteRecurringOccurrence(Expense expense) async {
    await _db.deleteRecurringOccurrence(expense);
    await loadDashboard();
    await loadRecentExpenses();
  }

  Future<void> stopRecurringSeries(Expense expense) async {
    await _db.stopRecurringSeries(expense);
    await loadDashboard();
    await loadRecentExpenses();
  }

  Future<void> deleteRecurringSeriesFrom(Expense expense) async {
    await _db.deleteRecurringSeriesFrom(expense);
    await loadDashboard();
    await loadRecentExpenses();
  }

  // ─── Budget ───────────────────────────────────────────────────────────────
  Future<void> setBudget(double amount) async {
    final now = DateTime.now();
    final budget = Budget(month: now.month, year: now.year, amount: amount);
    await _db.setBudget(budget);
    currentBudget = budget;
    notifyListeners();
  }

  double get budgetUsedPercent {
    if (currentBudget == null || currentBudget!.amount == 0) {
      return 0;
    }
    return (currentMonthTotal / currentBudget!.amount * 100).clamp(0, 100);
  }

  bool get isBudgetExceeded =>
      currentBudget != null && currentMonthTotal > currentBudget!.amount;

  bool get isBudgetWarning => currentBudget != null && budgetUsedPercent >= 80;

  // ─── Backup ───────────────────────────────────────────────────────────────
  Future<void> exportBackup() async {
    final data = await _db.exportAllData();
    final json = jsonEncode(data);
    final dir = await getTemporaryDirectory();
    final fileName =
        'spendwise_backup_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.json';
    final file = File('${dir.path}/$fileName');
    await file.writeAsString(json);
    await Share.shareXFiles(
      [XFile(file.path)],
      text:
          'SpendWise Backup - ${DateFormat('dd MMM yyyy').format(DateTime.now())}',
    );
  }

  Future<String> importBackup() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (result == null || result.files.isEmpty) return 'cancelled';

    final file = File(result.files.single.path!);
    final jsonStr = await file.readAsString();
    final data = jsonDecode(jsonStr) as Map<String, dynamic>;

    if (!data.containsKey('expenses')) return 'invalid';

    await _db.importAllData(data);
    await init();
    return 'success';
  }
}
