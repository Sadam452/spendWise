import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/expense.dart';
import '../models/lending_models.dart';
import '../models/budget.dart';
import '../models/income.dart';

class DBHelper {
  static final DBHelper instance = DBHelper._init();
  static Database? _database;

  DBHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('spendwise.db');
    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);
    return await openDatabase(
      path,
      version: 4,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE expenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        category_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        comments TEXT,
        is_recurring INTEGER DEFAULT 0,
        tag TEXT DEFAULT 'personal',
        recurrence_group TEXT,
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE income (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        source TEXT NOT NULL,
        notes TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE lent_money (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        recipient_name TEXT NOT NULL,
        phone TEXT NOT NULL,
        notes TEXT,
        amount_returned REAL DEFAULT 0,
        is_settled INTEGER DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE borrowed_money (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        lender_name TEXT NOT NULL,
        phone TEXT NOT NULL,
        notes TEXT,
        amount_returned REAL DEFAULT 0,
        is_settled INTEGER DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE budgets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        month INTEGER NOT NULL,
        year INTEGER NOT NULL,
        amount REAL NOT NULL,
        UNIQUE(month, year)
      )
    ''');
    await db.execute('''
      CREATE TABLE lending_transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        lending_id INTEGER NOT NULL,
        type TEXT NOT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        comments TEXT,
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE recurring_series (
        id TEXT PRIMARY KEY,
        amount REAL NOT NULL,
        category_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        comments TEXT,
        tag TEXT,
        day_of_month INTEGER NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 1
      )
    ''');
    await db.execute('''
      CREATE TABLE recurring_skips (
        recurrence_group TEXT NOT NULL,
        occurrence_date TEXT NOT NULL,
        PRIMARY KEY (recurrence_group, occurrence_date)
      )
    ''');
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      final columns = await db.rawQuery('PRAGMA table_info(expenses)');
      final hasRecurrenceGroup = columns.any(
        (column) => column['name'] == 'recurrence_group',
      );
      if (!hasRecurrenceGroup) {
        await db.execute(
          'ALTER TABLE expenses ADD COLUMN recurrence_group TEXT',
        );
      }
      await db.execute('''
        CREATE TABLE IF NOT EXISTS recurring_series (
          id TEXT PRIMARY KEY,
          amount REAL NOT NULL,
          category_id INTEGER NOT NULL,
          title TEXT NOT NULL,
          comments TEXT,
          tag TEXT,
          day_of_month INTEGER NOT NULL,
          is_active INTEGER NOT NULL DEFAULT 1
        )
      ''');
      final rows = await db.query('expenses', where: 'is_recurring = 1');
      for (final row in rows) {
        final group = 'legacy_${row['id']}';
        final existingGroup = row['recurrence_group'] as String?;
        if (existingGroup == null) {
          await db.update(
            'expenses',
            {'recurrence_group': group},
            where: 'id = ?',
            whereArgs: [row['id']],
          );
        }
        await db.insert('recurring_series', {
          'id': existingGroup ?? group,
          'amount': row['amount'],
          'category_id': row['category_id'],
          'title': row['title'],
          'comments': row['comments'],
          'tag': row['tag'],
          'day_of_month': DateTime.parse(row['date'] as String).day,
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      }
    }
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS recurring_skips (
          recurrence_group TEXT NOT NULL,
          occurrence_date TEXT NOT NULL,
          PRIMARY KEY (recurrence_group, occurrence_date)
        )
      ''');
    }
    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS income (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          amount REAL NOT NULL,
          date TEXT NOT NULL,
          source TEXT NOT NULL,
          notes TEXT,
          created_at TEXT NOT NULL
        )
      ''');
    }
  }

  // ─── EXPENSES ─────────────────────────────────────────────────────────────

  Future<Expense> insertExpense(Expense expense) async {
    final db = await database;
    final values = expense.toMap();
    final id = await db.insert('expenses', values);
    if (expense.isRecurring && expense.recurrenceGroup != null) {
      await db.insert('recurring_series', {
        'id': expense.recurrenceGroup,
        'amount': expense.amount,
        'category_id': expense.categoryId,
        'title': expense.title,
        'comments': expense.comments,
        'tag': expense.tag,
        'day_of_month': expense.date.day,
      });
    }
    return expense.copyWith(id: id);
  }

  Future<void> createMissingRecurringExpenses() async {
    final db = await database;
    final series = await db.query('recurring_series', where: 'is_active = 1');

    final now = DateTime.now();
    for (final template in series) {
      final group = template['id'] as String;
      final latestRows = await db.query(
        'expenses',
        where: 'recurrence_group = ?',
        whereArgs: [group],
        orderBy: 'date DESC, id DESC',
        limit: 1,
      );
      if (latestRows.isEmpty) continue;
      var nextDate = DateTime.parse(latestRows.first['date'] as String);
      while (true) {
        final nextMonth = nextDate.month == 12
            ? DateTime(nextDate.year + 1, 1, 1)
            : DateTime(nextDate.year, nextDate.month + 1, 1);
        final day = (template['day_of_month'] as int).clamp(
          1,
          DateTime(nextMonth.year, nextMonth.month + 1, 0).day,
        );
        final occurrence = DateTime(nextMonth.year, nextMonth.month, day);
        if (occurrence.isAfter(now)) break;
        final occurrenceKey = DateTime(
          occurrence.year,
          occurrence.month,
          occurrence.day,
        ).toIso8601String();
        final skipped = await db.query(
          'recurring_skips',
          where: 'recurrence_group = ? AND occurrence_date = ?',
          whereArgs: [group, occurrenceKey],
          limit: 1,
        );
        if (skipped.isNotEmpty) {
          nextDate = occurrence;
          continue;
        }
        await db.insert('expenses', {
          'amount': template['amount'],
          'category_id': template['category_id'],
          'title': template['title'],
          'comments': template['comments'],
          'is_recurring': 1,
          'tag': template['tag'],
          'recurrence_group': group,
          'id': null,
          'date': occurrence.toIso8601String(),
          'created_at': DateTime.now().toIso8601String(),
        });
        nextDate = occurrence;
      }
    }
  }

  Future<List<Expense>> getExpensesByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final db = await database;
    final result = await db.query(
      'expenses',
      where: 'date >= ? AND date <= ?',
      whereArgs: [
        start.toIso8601String(),
        DateTime(end.year, end.month, end.day, 23, 59, 59).toIso8601String(),
      ],
      orderBy: 'date DESC, id DESC',
    );
    return result.map((e) => Expense.fromMap(e)).toList();
  }

  Future<List<Expense>> getAllExpenses() async {
    final db = await database;
    final result = await db.query('expenses', orderBy: 'date DESC');
    return result.map((e) => Expense.fromMap(e)).toList();
  }

  Future<List<Expense>> getRecentExpenses({
    int limit = 50,
    int offset = 0,
  }) async {
    final db = await database;
    final result = await db.query(
      'expenses',
      orderBy: 'date DESC, id DESC',
      limit: limit,
      offset: offset,
    );
    return result.map((e) => Expense.fromMap(e)).toList();
  }

  Future<double> getTotalByDateRange(DateTime start, DateTime end) async {
    final db = await database;
    final result = await db.rawQuery(
      '''SELECT SUM(amount) as total FROM expenses
         WHERE date >= ? AND date <= ?''',
      [
        start.toIso8601String(),
        DateTime(end.year, end.month, end.day, 23, 59, 59).toIso8601String(),
      ],
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  Future<List<Map<String, dynamic>>> getMonthlyTotals(int year) async {
    final db = await database;
    final result = await db.rawQuery(
      '''
      SELECT 
        strftime('%m', date) as month,
        SUM(amount) as total
      FROM expenses
      WHERE strftime('%Y', date) = ?
      GROUP BY strftime('%m', date)
      ORDER BY month ASC
    ''',
      [year.toString()],
    );
    return result;
  }

  Future<List<Map<String, dynamic>>> getCategoryTotals(
    DateTime start,
    DateTime end,
  ) async {
    final db = await database;

    // CHANGED: We now group by 'tag' instead of 'category_id'
    final result = await db.rawQuery(
      '''
      SELECT 
        tag,
        SUM(amount) as total,
        COUNT(*) as count
      FROM expenses
      WHERE date >= ? AND date <= ?
      GROUP BY tag
      ORDER BY total DESC
    ''',
      [
        start.toIso8601String(),
        DateTime(end.year, end.month, end.day, 23, 59, 59).toIso8601String(),
      ],
    );
    return result;
  }

  Future<int> updateExpense(Expense expense) async {
    final db = await database;
    return await db.update(
      'expenses',
      expense.toMap(),
      where: 'id = ?',
      whereArgs: [expense.id],
    );
  }

  Future<void> updateFutureRecurringExpenses(
    Expense expense, {
    required DateTime fromDate,
  }) async {
    final db = await database;
    if (expense.recurrenceGroup == null) return;
    await db.update(
      'recurring_series',
      {
        'amount': expense.amount,
        'category_id': expense.categoryId,
        'title': expense.title,
        'comments': expense.comments,
        'tag': expense.tag,
        'day_of_month': expense.date.day,
        'is_active': expense.isRecurring ? 1 : 0,
      },
      where: 'id = ?',
      whereArgs: [expense.recurrenceGroup],
    );
    await db.update(
      'expenses',
      {
        'amount': expense.amount,
        'category_id': expense.categoryId,
        'title': expense.title,
        'comments': expense.comments,
        'is_recurring': expense.isRecurring ? 1 : 0,
        'tag': expense.tag,
      },
      where: 'recurrence_group = ? AND date >= ?',
      whereArgs: [expense.recurrenceGroup, fromDate.toIso8601String()],
    );
  }

  Future<int> deleteExpense(int id) async {
    final db = await database;
    return await db.delete('expenses', where: 'id = ?', whereArgs: [id]);
  }

  Future<Income> insertIncome(Income income) async {
    final db = await database;
    final id = await db.insert('income', income.toMap());
    return Income(
      id: id,
      amount: income.amount,
      date: income.date,
      source: income.source,
      notes: income.notes,
      createdAt: income.createdAt,
    );
  }

  Future<List<Income>> getAllIncome() async {
    final db = await database;
    final rows = await db.query('income', orderBy: 'date DESC, id DESC');
    return rows.map(Income.fromMap).toList();
  }

  Future<double> getIncomeTotalByDateRange(DateTime start, DateTime end) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT SUM(amount) AS total FROM income WHERE date >= ? AND date <= ?',
      [
        start.toIso8601String(),
        DateTime(end.year, end.month, end.day, 23, 59, 59).toIso8601String(),
      ],
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0;
  }

  Future<int> updateIncome(Income income) async {
    final db = await database;
    return db.update(
      'income',
      income.toMap(),
      where: 'id = ?',
      whereArgs: [income.id],
    );
  }

  Future<int> deleteIncome(int id) async {
    final db = await database;
    return db.delete('income', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteRecurringOccurrence(Expense expense) async {
    final db = await database;
    if (expense.id == null || expense.recurrenceGroup == null) {
      if (expense.id != null)
        await db.delete('expenses', where: 'id = ?', whereArgs: [expense.id]);
      return;
    }
    await db.transaction((txn) async {
      await txn.delete('expenses', where: 'id = ?', whereArgs: [expense.id]);
      await txn.insert('recurring_skips', {
        'recurrence_group': expense.recurrenceGroup,
        'occurrence_date': DateTime(
          expense.date.year,
          expense.date.month,
          expense.date.day,
        ).toIso8601String(),
      });
    });
  }

  Future<void> stopRecurringSeries(Expense expense) async {
    final db = await database;
    if (expense.recurrenceGroup == null) return;
    await db.update(
      'recurring_series',
      {'is_active': 0},
      where: 'id = ?',
      whereArgs: [expense.recurrenceGroup],
    );
  }

  Future<void> deleteRecurringSeriesFrom(Expense expense) async {
    final db = await database;
    if (expense.recurrenceGroup == null) return;
    await db.transaction((txn) async {
      await txn.delete(
        'expenses',
        where: 'recurrence_group = ? AND date >= ?',
        whereArgs: [expense.recurrenceGroup, expense.date.toIso8601String()],
      );
      await txn.update(
        'recurring_series',
        {'is_active': 0},
        where: 'id = ?',
        whereArgs: [expense.recurrenceGroup],
      );
    });
  }

  // ─── LENT MONEY ───────────────────────────────────────────────────────────

  Future<LentMoney> insertLentMoney(LentMoney entry) async {
    final db = await database;
    final id = await db.insert('lent_money', entry.toMap());
    return entry.copyWith(id: id);
  }

  Future<List<LentMoney>> getAllLentMoney() async {
    final db = await database;
    final result = await db.query('lent_money', orderBy: 'date DESC');
    return result.map((e) => LentMoney.fromMap(e)).toList();
  }

  Future<int> updateLentMoney(LentMoney entry) async {
    final db = await database;
    return await db.update(
      'lent_money',
      entry.toMap(),
      where: 'id = ?',
      whereArgs: [entry.id],
    );
  }

  Future<int> deleteLentMoney(int id) async {
    final db = await database;
    return await db.delete('lent_money', where: 'id = ?', whereArgs: [id]);
  }

  Future<Map<String, double>> getLentSummary() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT 
        SUM(amount) as total_lent,
        SUM(amount_returned) as total_returned
      FROM lent_money
    ''');
    return {
      'total_lent': (result.first['total_lent'] as num?)?.toDouble() ?? 0,
      'total_returned':
          (result.first['total_returned'] as num?)?.toDouble() ?? 0,
    };
  }

  // ─── BORROWED MONEY ───────────────────────────────────────────────────────

  Future<BorrowedMoney> insertBorrowedMoney(BorrowedMoney entry) async {
    final db = await database;
    final id = await db.insert('borrowed_money', entry.toMap());
    return entry.copyWith(id: id);
  }

  Future<List<BorrowedMoney>> getAllBorrowedMoney() async {
    final db = await database;
    final result = await db.query('borrowed_money', orderBy: 'date DESC');
    return result.map((e) => BorrowedMoney.fromMap(e)).toList();
  }

  Future<int> updateBorrowedMoney(BorrowedMoney entry) async {
    final db = await database;
    return await db.update(
      'borrowed_money',
      entry.toMap(),
      where: 'id = ?',
      whereArgs: [entry.id],
    );
  }

  Future<int> deleteBorrowedMoney(int id) async {
    final db = await database;
    return await db.delete('borrowed_money', where: 'id = ?', whereArgs: [id]);
  }

  Future<Map<String, double>> getBorrowedSummary() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT 
        SUM(amount) as total_borrowed,
        SUM(amount_returned) as total_returned
      FROM borrowed_money
    ''');
    return {
      'total_borrowed':
          (result.first['total_borrowed'] as num?)?.toDouble() ?? 0,
      'total_returned':
          (result.first['total_returned'] as num?)?.toDouble() ?? 0,
    };
  }

  // ─── BUDGET ───────────────────────────────────────────────────────────────

  Future<Budget?> getBudget(int month, int year) async {
    final db = await database;
    final result = await db.query(
      'budgets',
      where: 'month = ? AND year = ?',
      whereArgs: [month, year],
    );
    if (result.isEmpty) return null;
    return Budget.fromMap(result.first);
  }

  Future<void> setBudget(Budget budget) async {
    final db = await database;
    await db.insert(
      'budgets',
      budget.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ─── BACKUP & RESTORE ─────────────────────────────────────────────────────

  Future<Map<String, dynamic>> exportAllData() async {
    final db = await database;
    return {
      'version': 4,
      'exported_at': DateTime.now().toIso8601String(),
      'expenses': await db.query('expenses'),
      'income': await db.query('income'),
      'lent_money': await db.query('lent_money'),
      'borrowed_money': await db.query('borrowed_money'),
      'budgets': await db.query('budgets'), // Safely extracting budgets
      'lending_transactions': await db.query(
        'lending_transactions',
      ), // NEW: Saving your repayment history!
      'recurring_series': await db.query('recurring_series'),
      'recurring_skips': await db.query('recurring_skips'),
    };
  }

  Future<void> importAllData(Map<String, dynamic> data) async {
    final db = await database;

    // We use a transaction so if anything fails, it rolls back and doesn't destroy your data
    await db.transaction((txn) async {
      // 1. Wipe current data cleanly
      await txn.delete('expenses');
      await txn.delete('income');
      await txn.delete('lent_money');
      await txn.delete('borrowed_money');
      await txn.delete('budgets');
      await txn.delete('lending_transactions'); // NEW: Clear old history
      await txn.delete('recurring_series');
      await txn.delete('recurring_skips');

      // 2. Restore all data safely
      for (final row in data['expenses'] ?? []) {
        await txn.insert('expenses', Map<String, dynamic>.from(row));
      }
      for (final row in data['income'] ?? []) {
        await txn.insert('income', Map<String, dynamic>.from(row));
      }
      for (final row in data['lent_money'] ?? []) {
        await txn.insert('lent_money', Map<String, dynamic>.from(row));
      }
      for (final row in data['borrowed_money'] ?? []) {
        await txn.insert('borrowed_money', Map<String, dynamic>.from(row));
      }
      for (final row in data['budgets'] ?? []) {
        await txn.insert('budgets', Map<String, dynamic>.from(row));
      }

      // NEW: Restore the repayment history!
      for (final row in data['lending_transactions'] ?? []) {
        await txn.insert(
          'lending_transactions',
          Map<String, dynamic>.from(row),
        );
      }
      for (final row in data['recurring_series'] ?? []) {
        await txn.insert('recurring_series', Map<String, dynamic>.from(row));
      }
      for (final row in data['recurring_skips'] ?? []) {
        await txn.insert('recurring_skips', Map<String, dynamic>.from(row));
      }
    });
  }

  // ─── LENDING TRANSACTIONS (PARTIAL RETURNS) ───────────────────────────────

  Future<int> insertLendingTransaction(Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert('lending_transactions', data);
  }

  Future<List<Map<String, dynamic>>> getLendingTransactions(
    int lendingId,
    String type,
  ) async {
    final db = await database;
    return await db.query(
      'lending_transactions',
      where: 'lending_id = ? AND type = ?',
      whereArgs: [lendingId, type],
      orderBy: 'date DESC, created_at DESC', // Shows newest payments first
    );
  }
}
