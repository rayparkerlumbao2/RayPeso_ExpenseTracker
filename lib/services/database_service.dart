import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../models/expense.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._internal();
  Database? _database;
  bool _useLocalStorageFallback = false;
  SharedPreferences? _prefs;
  static const String _tableName = 'expenses';
  static const String _prefsKey = 'persisted_expenses_v1';

  DatabaseService._internal();

  bool get isUsingLocalStorageFallback => _useLocalStorageFallback;

  Future<void> init() async {
    if (_database != null || _useLocalStorageFallback) return;

    try {
      if (kIsWeb) {
        // On web, persist locally with SharedPreferences
        _useLocalStorageFallback = true;
        _prefs = await SharedPreferences.getInstance();
        return;
      }

      // 1. Configure appropriate databaseFactory based on platform
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        sqfliteFfiInit();
        databaseFactory = databaseFactoryFfi;
      }

      // 2. Determine path
      String path;
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        try {
          final appDocDir = await getApplicationDocumentsDirectory();
          path = p.join(appDocDir.path, 'expense_tracker_app.db');
        } catch (_) {
          path = 'expense_tracker_app.db';
        }
      } else {
        final dbPath = await getDatabasesPath();
        path = p.join(dbPath, 'expense_tracker_app.db');
      }

      // 3. Open SQLite database using the configured factory
      _database = await databaseFactory.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: (db, version) async {
            await db.execute('''
              CREATE TABLE $_tableName (
                id TEXT PRIMARY KEY,
                amount REAL NOT NULL,
                category_id TEXT NOT NULL,
                date TEXT NOT NULL,
                note TEXT,
                created_at TEXT NOT NULL
              )
            ''');

            await db.execute(
              'CREATE INDEX idx_expenses_date ON $_tableName (date)',
            );
            await db.execute(
              'CREATE INDEX idx_expenses_category ON $_tableName (category_id)',
            );
          },
        ),
      );
    } catch (e) {
      debugPrint(
        'SQLite initialization could not be completed ($e). Enabling LocalStorage fallback.',
      );
      _useLocalStorageFallback = true;
      _prefs = await SharedPreferences.getInstance();
    }
  }

  Future<Database?> _getDatabase() async {
    if (_useLocalStorageFallback) return null;
    if (_database == null) {
      await init();
    }
    return _database;
  }

  // --- LocalStorage Fallback Helpers ---

  Future<List<Expense>> _loadFromLocalStorage() async {
    _prefs ??= await SharedPreferences.getInstance();
    final jsonStr = _prefs!.getString(_prefsKey);
    if (jsonStr == null || jsonStr.isEmpty) return [];

    try {
      final List<dynamic> list = jsonDecode(jsonStr);
      return list
          .map((item) => Expense.fromMap(Map<String, dynamic>.from(item)))
          .toList();
    } catch (e) {
      debugPrint('Error reading from local storage: $e');
      return [];
    }
  }

  Future<void> _saveToLocalStorage(List<Expense> expenses) async {
    _prefs ??= await SharedPreferences.getInstance();
    final list = expenses.map((e) => e.toMap()).toList();
    await _prefs!.setString(_prefsKey, jsonEncode(list));
  }

  // --- Public CRUD Operations ---

  Future<int> insertExpense(Expense expense) async {
    final db = await _getDatabase();
    if (db != null) {
      return await db.insert(
        _tableName,
        expense.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } else {
      final all = await _loadFromLocalStorage();
      all.removeWhere((e) => e.id == expense.id);
      all.add(expense);
      await _saveToLocalStorage(all);
      return 1;
    }
  }

  Future<int> updateExpense(Expense expense) async {
    final db = await _getDatabase();
    if (db != null) {
      return await db.update(
        _tableName,
        expense.toMap(),
        where: 'id = ?',
        whereArgs: [expense.id],
      );
    } else {
      final all = await _loadFromLocalStorage();
      final index = all.indexWhere((e) => e.id == expense.id);
      if (index != -1) {
        all[index] = expense;
        await _saveToLocalStorage(all);
        return 1;
      }
      return 0;
    }
  }

  Future<int> deleteExpense(String id) async {
    final db = await _getDatabase();
    if (db != null) {
      return await db.delete(
        _tableName,
        where: 'id = ?',
        whereArgs: [id],
      );
    } else {
      final all = await _loadFromLocalStorage();
      final initialLen = all.length;
      all.removeWhere((e) => e.id == id);
      if (all.length != initialLen) {
        await _saveToLocalStorage(all);
        return 1;
      }
      return 0;
    }
  }

  Future<List<Expense>> getExpensesForMonth(int year, int month) async {
    final db = await _getDatabase();
    if (db != null) {
      final startDate = DateTime(year, month, 1).toIso8601String();
      final endDate = (month == 12
              ? DateTime(year + 1, 1, 1)
              : DateTime(year, month + 1, 1))
          .toIso8601String();

      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where: 'date >= ? AND date < ?',
        whereArgs: [startDate, endDate],
        orderBy: 'date DESC, created_at DESC',
      );

      return List.generate(maps.length, (i) => Expense.fromMap(maps[i]));
    } else {
      final all = await _loadFromLocalStorage();
      final filtered = all.where((e) {
        return e.date.year == year && e.date.month == month;
      }).toList();
      filtered.sort((a, b) {
        final cmp = b.date.compareTo(a.date);
        return cmp != 0 ? cmp : b.createdAt.compareTo(a.createdAt);
      });
      return filtered;
    }
  }

  Future<List<Expense>> getAllExpenses() async {
    final db = await _getDatabase();
    if (db != null) {
      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        orderBy: 'date DESC, created_at DESC',
      );
      return List.generate(maps.length, (i) => Expense.fromMap(maps[i]));
    } else {
      final all = await _loadFromLocalStorage();
      all.sort((a, b) => b.date.compareTo(a.date));
      return all;
    }
  }

  Future<int> getExpenseCount() async {
    final db = await _getDatabase();
    if (db != null) {
      final result =
          await db.rawQuery('SELECT COUNT(*) as count FROM $_tableName');
      return Sqflite.firstIntValue(result) ?? 0;
    } else {
      final all = await _loadFromLocalStorage();
      return all.length;
    }
  }

  Future<List<DateTime>> getMonthsWithExpenses() async {
    final db = await _getDatabase();
    final months = <DateTime>[];

    if (db != null) {
      final List<Map<String, dynamic>> result = await db.rawQuery('''
        SELECT DISTINCT strftime('%Y-%m', date) as month_key 
        FROM $_tableName 
        ORDER BY month_key DESC
      ''');

      for (final row in result) {
        final monthKey = row['month_key'] as String?;
        if (monthKey != null && monthKey.isNotEmpty) {
          final parts = monthKey.split('-');
          if (parts.length == 2) {
            final year = int.tryParse(parts[0]);
            final month = int.tryParse(parts[1]);
            if (year != null && month != null) {
              months.add(DateTime(year, month, 1));
            }
          }
        }
      }
    } else {
      final all = await _loadFromLocalStorage();
      final keys = <String>{};
      for (final e in all) {
        final key = '${e.date.year}-${e.date.month.toString().padLeft(2, '0')}';
        if (keys.add(key)) {
          months.add(DateTime(e.date.year, e.date.month, 1));
        }
      }
      months.sort((a, b) => b.compareTo(a));
    }
    return months;
  }

  Future<void> clearAllExpenses() async {
    final db = await _getDatabase();
    if (db != null) {
      await db.delete(_tableName);
    } else {
      _prefs ??= await SharedPreferences.getInstance();
      await _prefs!.remove(_prefsKey);
    }
  }

  Future<void> clearSampleDataOnce() async {
    _prefs ??= await SharedPreferences.getInstance();
    final cleared = _prefs!.getBool('clean_user_db_v2') ?? false;
    if (!cleared) {
      await clearAllExpenses();
      await _prefs!.setBool('clean_user_db_v2', true);
    }
  }
}
