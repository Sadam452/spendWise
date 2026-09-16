class Budget {
  final int? id;
  final int month;
  final int year;
  final double amount;

  Budget({
    this.id,
    required this.month,
    required this.year,
    required this.amount,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'month': month,
        'year': year,
        'amount': amount,
      };

  factory Budget.fromMap(Map<String, dynamic> map) => Budget(
        id: map['id'],
        month: map['month'],
        year: map['year'],
        amount: map['amount'],
      );

  Budget copyWith({int? id, double? amount}) => Budget(
        id: id ?? this.id,
        month: month,
        year: year,
        amount: amount ?? this.amount,
      );
}