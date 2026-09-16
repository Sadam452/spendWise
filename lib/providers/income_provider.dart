import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import '../models/income.dart';

class IncomeProvider extends ChangeNotifier {
  final DBHelper _db = DBHelper.instance;

  List<Income> incomes = [];
  double currentMonthIncome = 0;
  bool isLoading = false;

  Future<void> init() async {
    await load();
  }

  Future<void> load() async {
    isLoading = true;
    notifyListeners();
    incomes = await _db.getAllIncome();
    final now = DateTime.now();
    currentMonthIncome = await _db.getIncomeTotalByDateRange(
      DateTime(now.year, now.month, 1),
      now,
    );
    isLoading = false;
    notifyListeners();
  }

  Future<void> addIncome(Income income) async {
    await _db.insertIncome(income);
    await load();
  }

  Future<void> persistIncome(Income income) async {
    await _db.insertIncome(income);
  }

  Future<void> updateIncome(Income income) async {
    await _db.updateIncome(income);
    await load();
  }

  Future<void> persistIncomeUpdate(Income income) async {
    await _db.updateIncome(income);
  }

  Future<void> deleteIncome(int id) async {
    await _db.deleteIncome(id);
    await load();
  }
}
