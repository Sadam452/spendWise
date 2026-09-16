import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import '../models/lending_models.dart';

class LendingProvider extends ChangeNotifier {
  final DBHelper _db = DBHelper.instance;

  List<LentMoney> lentList = [];
  List<BorrowedMoney> borrowedList = [];

  double totalLent = 0;
  double totalLentReturned = 0;
  double totalBorrowed = 0;
  double totalBorrowedReturned = 0;

  double get outstandingLent => totalLent - totalLentReturned;
  double get outstandingBorrowed => totalBorrowed - totalBorrowedReturned;

  // ─── Load ─────────────────────────────────────────────────────────────────
  Future<void> loadLent() async {
    lentList = await _db.getAllLentMoney();
    final summary = await _db.getLentSummary();
    totalLent = summary['total_lent'] ?? 0;
    totalLentReturned = summary['total_returned'] ?? 0;
    notifyListeners();
  }

  Future<void> loadBorrowed() async {
    borrowedList = await _db.getAllBorrowedMoney();
    final summary = await _db.getBorrowedSummary();
    totalBorrowed = summary['total_borrowed'] ?? 0;
    totalBorrowedReturned = summary['total_returned'] ?? 0;
    notifyListeners();
  }

  Future<void> loadAll() async {
    await loadLent();
    await loadBorrowed();
  }

  String _personKey(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    return digits.length > 10 && digits.startsWith('91')
        ? digits.substring(digits.length - 10)
        : digits;
  }

  // ─── Lent CRUD ────────────────────────────────────────────────────────────
  Future<void> addLent(LentMoney entry) async {
    await _db.insertLentMoney(entry);
    await loadLent();
  }

  Future<void> updateLent(LentMoney entry) async {
    await _db.updateLentMoney(entry);
    await loadLent();
  }

  Future<void> deleteLent(int id) async {
    await _db.deleteLentMoney(id);
    await loadLent();
  }

  Future<void> markLentReturned(LentMoney entry, double returnedAmount) async {
    final updated = entry.copyWith(
      amountReturned: (entry.amountReturned + returnedAmount).clamp(
        0,
        entry.amount,
      ),
      isSettled: (entry.amountReturned + returnedAmount) >= entry.amount,
    );
    await _db.updateLentMoney(updated);
    await loadLent();
  }

  // ─── Borrowed CRUD ────────────────────────────────────────────────────────
  Future<void> addBorrowed(BorrowedMoney entry) async {
    await _db.insertBorrowedMoney(entry);
    await loadBorrowed();
  }

  Future<void> updateBorrowed(BorrowedMoney entry) async {
    await _db.updateBorrowedMoney(entry);
    await loadBorrowed();
  }

  Future<void> deleteBorrowed(int id) async {
    await _db.deleteBorrowedMoney(id);
    await loadBorrowed();
  }

  Future<void> markBorrowedReturned(
    BorrowedMoney entry,
    double returnedAmount,
  ) async {
    final updated = entry.copyWith(
      amountReturned: (entry.amountReturned + returnedAmount).clamp(
        0,
        entry.amount,
      ),
      isSettled: (entry.amountReturned + returnedAmount) >= entry.amount,
    );
    await _db.updateBorrowedMoney(updated);
    await loadBorrowed();
  }

  List<PersonLendingSummary> get groupedLent {
    final Map<String, List<LentMoney>> grouped = {};

    for (var item in lentList) {
      final key = _personKey(item.phone);

      if (!grouped.containsKey(key)) {
        grouped[key] = [];
      }
      grouped[key]!.add(item);
    }

    return grouped.values.map((entries) {
      final first = entries.first;

      final total = entries.fold(0.0, (sum, e) => sum + e.amount);

      final returned = entries.fold(0.0, (sum, e) => sum + e.amountReturned);

      return PersonLendingSummary(
        name: first.recipientName,
        phone: first.phone,
        totalAmount: total,
        totalReturned: returned,
        entries: entries,
      );
    }).toList();
  }

  List<PersonLendingSummary> get groupedBorrowed {
    final Map<String, List<BorrowedMoney>> grouped = {};

    for (var item in borrowedList) {
      final key = _personKey(item.phone);

      grouped.putIfAbsent(key, () => []);
      grouped[key]!.add(item);
    }

    return grouped.values.map((entries) {
      final first = entries.first;

      final total = entries.fold(0.0, (sum, e) => sum + e.amount);

      final returned = entries.fold(0.0, (sum, e) => sum + e.amountReturned);

      return PersonLendingSummary(
        name: first.lenderName,
        phone: first.phone,
        totalAmount: total,
        totalReturned: returned,
        entries: entries
            .map(
              (e) => LentMoney(
                id: e.id,
                amount: e.amount,
                date: e.date,
                recipientName: e.lenderName,
                phone: e.phone,
                notes: e.notes,
                amountReturned: e.amountReturned,
                isSettled: e.isSettled,
              ),
            )
            .toList(),
      );
    }).toList();
  }

  // Adds a partial return to history AND updates the main balance
  Future<void> addPartialReturn({
    required int lendingId,
    required String type, // 'lent' or 'borrowed'
    required double amount,
    required DateTime date,
    String? comments,
  }) async {
    // 1. Save the history record
    final transaction = LendingTransaction(
      lendingId: lendingId,
      type: type,
      amount: amount,
      date: date,
      comments: comments,
      createdAt: DateTime.now(),
    );
    await DBHelper.instance.insertLendingTransaction(transaction.toMap());

    // 2. Update the main card's total returned amount
    if (type == 'lent') {
      final existing = lentList.firstWhere((e) => e.id == lendingId);
      final newReturned = existing.amountReturned + amount;
      final isSettled = newReturned >= existing.amount;
      await updateLent(
        existing.copyWith(amountReturned: newReturned, isSettled: isSettled),
      );
    } else {
      final existing = borrowedList.firstWhere((e) => e.id == lendingId);
      final newReturned = existing.amountReturned + amount;
      final isSettled = newReturned >= existing.amount;
      await updateBorrowed(
        existing.copyWith(amountReturned: newReturned, isSettled: isSettled),
      );
    }
    notifyListeners();
  }

  // Fetches the history timeline for a specific person
  Future<List<LendingTransaction>> getReturnHistory(
    int lendingId,
    String type,
  ) async {
    final maps = await DBHelper.instance.getLendingTransactions(
      lendingId,
      type,
    );
    return maps.map((m) => LendingTransaction.fromMap(m)).toList();
  }
}
