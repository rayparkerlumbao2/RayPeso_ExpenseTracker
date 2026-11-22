import 'dart:io' show Platform;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:expense_tracker_app/models/expense.dart';
import 'package:expense_tracker_app/models/expense_category.dart';
import 'package:expense_tracker_app/services/database_service.dart';
import 'package:expense_tracker_app/utils/formatters.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  group('ExpenseCategory Tests', () {
    test('Categories are loaded with correct defaults', () {
      expect(ExpenseCategory.all.length, 7);
      expect(ExpenseCategory.getById('food').name, 'Food & Dining');
      expect(ExpenseCategory.getById('transport').name, 'Transportation');
      expect(ExpenseCategory.getById('utilities').name, 'Utilities & Bills');
      expect(
        ExpenseCategory.getById('leisure').name,
        'Leisure & Entertainment',
      );
      expect(ExpenseCategory.getById('shopping').name, 'Shopping');
      expect(ExpenseCategory.getById('health').name, 'Health & Medical');
      expect(ExpenseCategory.getById('other').name, 'Other');
    });

    test('Unknown category falls back to other', () {
      expect(ExpenseCategory.getById('unknown_xyz'), ExpenseCategory.other);
    });
  });

  group('Expense Model Tests', () {
    test('Expense toMap and fromMap serialization', () {
      final date = DateTime(2026, 11, 22, 14, 30);
      final created = DateTime(2026, 11, 22, 14, 31);
      final expense = Expense(
        id: 'test-123',
        amount: 49.99,
        categoryId: 'food',
        date: date,
        note: 'Special dinner',
        createdAt: created,
      );

      final map = expense.toMap();
      expect(map['id'], 'test-123');
      expect(map['amount'], 49.99);
      expect(map['category_id'], 'food');
      expect(map['note'], 'Special dinner');

      final restored = Expense.fromMap(map);
      expect(restored.id, expense.id);
      expect(restored.amount, expense.amount);
      expect(restored.categoryId, expense.categoryId);
      expect(restored.note, expense.note);
      expect(restored.category, ExpenseCategory.food);
      expect(restored.monthKey, '2026-11');
    });

    test('Expense copyWith works correctly', () {
      final expense = Expense(
        id: '1',
        amount: 20.0,
        categoryId: 'food',
        date: DateTime(2026, 11, 1),
        createdAt: DateTime(2026, 11, 1),
      );

      final updated = expense.copyWith(amount: 35.5, note: 'Updated note');
      expect(updated.id, '1');
      expect(updated.amount, 35.5);
      expect(updated.note, 'Updated note');
      expect(updated.categoryId, 'food');
    });
  });

  group('DatabaseService CRUD Tests', () {
    test('Insert, read, and delete expense without databaseFactory error',
        () async {
      final dbService = DatabaseService.instance;
      await dbService.init();

      final expense = Expense(
        id: 'test-db-1',
        amount: 38.50,
        categoryId: 'transport',
        date: DateTime(2026, 11, 22, 10, 0),
        note: 'Taxi ride',
        createdAt: DateTime.now(),
      );

      // Insert
      await dbService.insertExpense(expense);

      // Query
      final expenses = await dbService.getExpensesForMonth(2026, 11);
      expect(expenses.any((e) => e.id == 'test-db-1'), isTrue);

      // Delete
      await dbService.deleteExpense('test-db-1');
      final updatedExpenses = await dbService.getExpensesForMonth(2026, 11);
      expect(updatedExpenses.any((e) => e.id == 'test-db-1'), isFalse);
    });
  });

  group('AppFormatters Tests', () {
    test('Currency formatting', () {
      expect(AppFormatters.formatCurrency(1234.56), '₱1,234.56');
      expect(AppFormatters.formatCurrency(50.0, currencySymbol: '€'), '€50.00');
    });

    test('Month year formatting', () {
      final date = DateTime(2026, 11, 1);
      expect(AppFormatters.formatMonthYear(date), 'November 2026');
    });

    test('Percentage formatting', () {
      expect(AppFormatters.formatPercentage(0.456), '45.6%');
      expect(AppFormatters.formatPercentage(0.1), '10.0%');
    });
  });
}
