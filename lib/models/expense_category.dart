import 'package:material_ui/material_ui.dart';

class ExpenseCategory {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final Color backgroundColor;

  const ExpenseCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.backgroundColor,
  });

  static const ExpenseCategory food = ExpenseCategory(
    id: 'food',
    name: 'Food & Dining',
    icon: Icons.restaurant_rounded,
    color: Color(0xFFEF5350),
    backgroundColor: Color(0xFFFFEBEE),
  );

  static const ExpenseCategory transport = ExpenseCategory(
    id: 'transport',
    name: 'Transportation',
    icon: Icons.directions_subway_rounded,
    color: Color(0xFF29B6F6),
    backgroundColor: Color(0xFFE1F5FE),
  );

  static const ExpenseCategory utilities = ExpenseCategory(
    id: 'utilities',
    name: 'Utilities & Bills',
    icon: Icons.bolt_rounded,
    color: Color(0xFFFFA726),
    backgroundColor: Color(0xFFFFF3E0),
  );

  static const ExpenseCategory leisure = ExpenseCategory(
    id: 'leisure',
    name: 'Leisure & Entertainment',
    icon: Icons.sports_esports_rounded,
    color: Color(0xFFAB47BC),
    backgroundColor: Color(0xFFF3E5F5),
  );

  static const ExpenseCategory shopping = ExpenseCategory(
    id: 'shopping',
    name: 'Shopping',
    icon: Icons.shopping_bag_rounded,
    color: Color(0xFF26A69A),
    backgroundColor: Color(0xFFE0F2F1),
  );

  static const ExpenseCategory health = ExpenseCategory(
    id: 'health',
    name: 'Health & Medical',
    icon: Icons.favorite_rounded,
    color: Color(0xFF66BB6A),
    backgroundColor: Color(0xFFE8F5E9),
  );

  static const ExpenseCategory other = ExpenseCategory(
    id: 'other',
    name: 'Other',
    icon: Icons.category_rounded,
    color: Color(0xFF78909C),
    backgroundColor: Color(0xFFECEFF1),
  );

  static const List<ExpenseCategory> all = [
    food,
    transport,
    utilities,
    leisure,
    shopping,
    health,
    other,
  ];

  static ExpenseCategory getById(String id) {
    return all.firstWhere(
      (cat) => cat.id.toLowerCase() == id.toLowerCase(),
      orElse: () => other,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExpenseCategory &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
