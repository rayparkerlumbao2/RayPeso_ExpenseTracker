import 'expense_category.dart';

class Expense {
  final String id;
  final double amount;
  final String categoryId;
  final DateTime date;
  final String? note;
  final DateTime createdAt;

  const Expense({
    required this.id,
    required this.amount,
    required this.categoryId,
    required this.date,
    this.note,
    required this.createdAt,
  });

  ExpenseCategory get category => ExpenseCategory.getById(categoryId);

  String get monthKey =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'category_id': categoryId,
      'date': date.toIso8601String(),
      'note': note,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'] as String,
      amount: (map['amount'] as num).toDouble(),
      categoryId: map['category_id'] as String,
      date: DateTime.parse(map['date'] as String),
      note: map['note'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.now(),
    );
  }

  Expense copyWith({
    String? id,
    double? amount,
    String? categoryId,
    DateTime? date,
    String? note,
    DateTime? createdAt,
  }) {
    return Expense(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      categoryId: categoryId ?? this.categoryId,
      date: date ?? this.date,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
