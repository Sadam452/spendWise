import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/db_helper.dart';
import '../models/lending_models.dart';

class LendingProvider extends ChangeNotifier {
  final DBHelper _db = DBHelper.instance;
  static const sortOptions = {
    'unsettled': 'Unsettled first',
    'highest': 'Highest outstanding',
    'lowest': 'Lowest outstanding',
    'newest': 'Newest first',
    'oldest': 'Oldest first',
  };
  static const _lentSortKey = 'lending_lent_sort';
  static const _borrowedSortKey = 'lending_borrowed_sort';

  List<LentMoney> lentList = [];
  List<BorrowedMoney> borrowedList = [];
  String lentSort = 'unsettled';
  String borrowedSort = 'unsettled';
  bool _sortPreferencesLoaded = false;

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
    await _loadSortPreferences();
    await loadLent();
    await loadBorrowed();
  }

  Future<void> _loadSortPreferences() async {
    if (_sortPreferencesLoaded) return;
    final prefs = await SharedPreferences.getInstance();
    final storedLentSort = prefs.getString(_lentSortKey);
    final storedBorrowedSort = prefs.getString(_borrowedSortKey);
    lentSort = sortOptions.containsKey(storedLentSort)
        ? storedLentSort!
        : 'unsettled';
    borrowedSort = sortOptions.containsKey(storedBorrowedSort)
        ? storedBorrowedSort!
        : 'unsettled';
    _sortPreferencesLoaded = true;
  }

  Future<void> setLentSort(String sort) async {
    if (!sortOptions.containsKey(sort) || sort == lentSort) return;
    lentSort = sort;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lentSortKey, sort);
  }

  Future<void> setBorrowedSort(String sort) async {
    if (!sortOptions.containsKey(sort) || sort == borrowedSort) return;
    borrowedSort = sort;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_borrowedSortKey, sort);
  }

  int _compareEntries(LentMoney a, LentMoney b, String sort) {
    final aSettled = a.outstanding <= 0;
    final bSettled = b.outstanding <= 0;
    if (aSettled != bSettled) return aSettled ? 1 : -1;
    switch (sort) {
      case 'highest':
        return b.outstanding.compareTo(a.outstanding);
      case 'lowest':
        return a.outstanding.compareTo(b.outstanding);
      case 'oldest':
        return a.date.compareTo(b.date);
      case 'newest':
      case 'unsettled':
      default:
        return b.date.compareTo(a.date);
    }
  }

  DateTime _personSortDate(
    PersonLendingSummary person, {
    required bool oldest,
  }) {
    final outstandingEntries = person.entries
        .where((entry) => entry.outstanding > 0)
        .toList();
    final candidates = outstandingEntries.isNotEmpty
        ? outstandingEntries
        : person.entries;
    return candidates
        .map((entry) => entry.date)
        .reduce(
          (a, b) => oldest ? (a.isBefore(b) ? a : b) : (a.isAfter(b) ? a : b),
        );
  }

  List<PersonLendingSummary> _sortPeople(
    List<PersonLendingSummary> people,
    String sort,
  ) {
    for (final person in people) {
      person.entries.sort((a, b) => _compareEntries(a, b, sort));
    }
    people.sort((a, b) {
      final aOutstanding = a.outstanding <= 0;
      final bOutstanding = b.outstanding <= 0;
      if (aOutstanding != bOutstanding) return aOutstanding ? 1 : -1;
      switch (sort) {
        case 'highest':
          return b.outstanding.compareTo(a.outstanding);
        case 'lowest':
          return a.outstanding.compareTo(b.outstanding);
        case 'oldest':
          return _personSortDate(
            a,
            oldest: true,
          ).compareTo(_personSortDate(b, oldest: true));
        case 'newest':
          return _personSortDate(
            b,
            oldest: false,
          ).compareTo(_personSortDate(a, oldest: false));
        case 'unsettled':
        default:
          return _personSortDate(
            b,
            oldest: false,
          ).compareTo(_personSortDate(a, oldest: false));
      }
    });
    return people;
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

    final people = grouped.values.map((entries) {
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
    return _sortPeople(people, lentSort);
  }

  List<PersonLendingSummary> get groupedBorrowed {
    final Map<String, List<BorrowedMoney>> grouped = {};

    for (var item in borrowedList) {
      final key = _personKey(item.phone);

      grouped.putIfAbsent(key, () => []);
      grouped[key]!.add(item);
    }

    final people = grouped.values.map((entries) {
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
    return _sortPeople(people, borrowedSort);
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
