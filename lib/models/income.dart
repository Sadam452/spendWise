class Income {
  final int? id;
  final double amount;
  final DateTime date;
  final String source;
  final String? notes;
  final DateTime createdAt;

  Income({
    this.id,
    required this.amount,
    required this.date,
    required this.source,
    this.notes,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
    'id': id,
    'amount': amount,
    'date': date.toIso8601String(),
    'source': source,
    'notes': notes,
    'created_at': createdAt.toIso8601String(),
  };

  factory Income.fromMap(Map<String, dynamic> map) => Income(
    id: map['id'] as int?,
    amount: (map['amount'] as num).toDouble(),
    date: DateTime.parse(map['date'] as String),
    source: map['source'] as String,
    notes: map['notes'] as String?,
    createdAt: DateTime.parse(map['created_at'] as String),
  );
}
