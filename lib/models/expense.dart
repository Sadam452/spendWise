class Expense {
  final int? id;
  final double amount;
  final DateTime date;
  final int categoryId;
  final String title;
  final String? comments;
  final bool isRecurring;
  final String? tag;
  final String? recurrenceGroup;
  final DateTime createdAt;

  Expense({
    this.id,
    required this.amount,
    required this.date,
    required this.categoryId,
    required this.title,
    this.comments,
    this.isRecurring = false,
    this.tag,
    this.recurrenceGroup,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
    'id': id,
    'amount': amount,
    'date': date.toIso8601String(),
    'category_id': categoryId,
    'title': title,
    'comments': comments,
    'is_recurring': isRecurring ? 1 : 0,
    'tag': tag,
    'recurrence_group': recurrenceGroup,
    'created_at': createdAt.toIso8601String(),
  };

  factory Expense.fromMap(Map<String, dynamic> map) => Expense(
    id: map['id'],
    amount: map['amount'],
    date: DateTime.parse(map['date']),
    categoryId: map['category_id'],
    title: map['title'],
    comments: map['comments'],
    isRecurring: map['is_recurring'] == 1,
    tag: map['tag'],
    recurrenceGroup: map['recurrence_group'],
    createdAt: DateTime.parse(map['created_at']),
  );

  Expense copyWith({
    int? id,
    double? amount,
    DateTime? date,
    int? categoryId,
    String? title,
    String? comments,
    bool? isRecurring,
    String? tag,
    String? recurrenceGroup,
  }) => Expense(
    id: id ?? this.id,
    amount: amount ?? this.amount,
    date: date ?? this.date,
    categoryId: categoryId ?? this.categoryId,
    title: title ?? this.title,
    comments: comments ?? this.comments,
    isRecurring: isRecurring ?? this.isRecurring,
    tag: tag ?? this.tag,
    recurrenceGroup: recurrenceGroup ?? this.recurrenceGroup,
    createdAt: createdAt,
  );
}
