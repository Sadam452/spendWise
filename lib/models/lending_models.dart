class LentMoney {
  final int? id;
  final double amount;
  final DateTime date;
  final String recipientName;
  final String phone;
  final String? notes;
  final double amountReturned;
  final bool isSettled;
  final DateTime createdAt;

  LentMoney({
    this.id,
    required this.amount,
    required this.date,
    required this.recipientName,
    required this.phone,
    this.notes,
    this.amountReturned = 0,
    this.isSettled = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  double get outstanding => amount - amountReturned;
  double get returnedPercent =>
      amount > 0 ? (amountReturned / amount * 100).clamp(0, 100) : 0;

  Map<String, dynamic> toMap() => {
        'id': id,
        'amount': amount,
        'date': date.toIso8601String(),
        'recipient_name': recipientName,
        'phone': phone,
        'notes': notes,
        'amount_returned': amountReturned,
        'is_settled': isSettled ? 1 : 0,
        'created_at': createdAt.toIso8601String(),
      };

  factory LentMoney.fromMap(Map<String, dynamic> map) => LentMoney(
        id: map['id'],
        amount: map['amount'],
        date: DateTime.parse(map['date']),
        recipientName: map['recipient_name'],
        phone: map['phone'],
        notes: map['notes'],
        amountReturned: map['amount_returned'] ?? 0,
        isSettled: map['is_settled'] == 1,
        createdAt: DateTime.parse(map['created_at']),
      );

  LentMoney copyWith({
    int? id,
    double? amount,
    DateTime? date,
    String? recipientName,
    String? phone,
    String? notes,
    double? amountReturned,
    bool? isSettled,
  }) =>
      LentMoney(
        id: id ?? this.id,
        amount: amount ?? this.amount,
        date: date ?? this.date,
        recipientName: recipientName ?? this.recipientName,
        phone: phone ?? this.phone,
        notes: notes ?? this.notes,
        amountReturned: amountReturned ?? this.amountReturned,
        isSettled: isSettled ?? this.isSettled,
        createdAt: createdAt,
      );
}

class BorrowedMoney {
  final int? id;
  final double amount;
  final DateTime date;
  final String lenderName;
  final String phone;
  final String? notes;
  final double amountReturned;
  final bool isSettled;
  final DateTime createdAt;

  BorrowedMoney({
    this.id,
    required this.amount,
    required this.date,
    required this.lenderName,
    required this.phone,
    this.notes,
    this.amountReturned = 0,
    this.isSettled = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  double get outstanding => amount - amountReturned;
  double get returnedPercent =>
      amount > 0 ? (amountReturned / amount * 100).clamp(0, 100) : 0;

  Map<String, dynamic> toMap() => {
        'id': id,
        'amount': amount,
        'date': date.toIso8601String(),
        'lender_name': lenderName,
        'phone': phone,
        'notes': notes,
        'amount_returned': amountReturned,
        'is_settled': isSettled ? 1 : 0,
        'created_at': createdAt.toIso8601String(),
      };

  factory BorrowedMoney.fromMap(Map<String, dynamic> map) => BorrowedMoney(
        id: map['id'],
        amount: map['amount'],
        date: DateTime.parse(map['date']),
        lenderName: map['lender_name'],
        phone: map['phone'],
        notes: map['notes'],
        amountReturned: map['amount_returned'] ?? 0,
        isSettled: map['is_settled'] == 1,
        createdAt: DateTime.parse(map['created_at']),
      );

  BorrowedMoney copyWith({
    int? id,
    double? amount,
    DateTime? date,
    String? lenderName,
    String? phone,
    String? notes,
    double? amountReturned,
    bool? isSettled,
  }) =>
      BorrowedMoney(
        id: id ?? this.id,
        amount: amount ?? this.amount,
        date: date ?? this.date,
        lenderName: lenderName ?? this.lenderName,
        phone: phone ?? this.phone,
        notes: notes ?? this.notes,
        amountReturned: amountReturned ?? this.amountReturned,
        isSettled: isSettled ?? this.isSettled,
        createdAt: createdAt,
      );
}

class PersonLendingSummary {
  final String name;
  final String phone;
  final double totalAmount;
  final double totalReturned;
  final List<LentMoney> entries;

  PersonLendingSummary({
    required this.name,
    required this.phone,
    required this.totalAmount,
    required this.totalReturned,
    required this.entries,
  });

  double get outstanding => totalAmount - totalReturned;
}

class LendingTransaction {
  final int? id;
  final int lendingId;
  final String type; // 'lent' or 'borrowed'
  final double amount;
  final DateTime date;
  final String? comments;
  final DateTime createdAt;

  LendingTransaction({
    this.id,
    required this.lendingId,
    required this.type,
    required this.amount,
    required this.date,
    this.comments,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'lending_id': lendingId,
      'type': type,
      'amount': amount,
      'date': date.toIso8601String(),
      'comments': comments,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory LendingTransaction.fromMap(Map<String, dynamic> map) {
    return LendingTransaction(
      id: map['id'],
      lendingId: map['lending_id'],
      type: map['type'],
      amount: map['amount'],
      date: DateTime.parse(map['date']),
      comments: map['comments'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}