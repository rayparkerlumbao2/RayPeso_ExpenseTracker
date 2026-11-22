import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/expense.dart';
import '../models/expense_category.dart';
import '../services/database_service.dart';
import '../services/firestore_service.dart';

class ExpenseProvider extends ChangeNotifier {
  final DatabaseService _dbService = DatabaseService.instance;
  final FirestoreService _firestoreService = FirestoreService.instance;
  static const _uuid = Uuid();

  DateTime _selectedMonth =
      DateTime(DateTime.now().year, DateTime.now().month, 1);
  List<Expense> _expenses = [];
  bool _isLoading = true;
  bool _isSyncing = false;
  String _currencySymbol = '₱';
  ThemeMode _themeMode = ThemeMode.system;
  int? _touchedChartIndex;

  Expense? _lastDeletedExpense;

  ExpenseProvider() {
    _init();
  }

  // Getters
  DateTime get selectedMonth => _selectedMonth;
  List<Expense> get expenses => _expenses;
  bool get isLoading => _isLoading;
  bool get isSyncing => _isSyncing;
  bool get isCloudSyncActive => _firestoreService.isInitialized;
  String get currencySymbol => _currencySymbol;
  ThemeMode get themeMode => _themeMode;
  int? get touchedChartIndex => _touchedChartIndex;
  bool get canUndo => _lastDeletedExpense != null;

  bool get isCurrentMonth {
    final now = DateTime.now();
    return _selectedMonth.year == now.year && _selectedMonth.month == now.month;
  }

  double get monthlyTotal {
    return _expenses.fold(0.0, (sum, e) => sum + e.amount);
  }

  int get transactionCount => _expenses.length;

  double get dailyAverage {
    if (_expenses.isEmpty) return 0.0;
    final now = DateTime.now();
    int days;
    if (isCurrentMonth) {
      days = now.day;
    } else {
      final nextMonth = _selectedMonth.month == 12
          ? DateTime(_selectedMonth.year + 1, 1, 1)
          : DateTime(_selectedMonth.year, _selectedMonth.month + 1, 1);
      days = nextMonth.difference(_selectedMonth).inDays;
    }
    if (days <= 0) days = 1;
    return monthlyTotal / days;
  }

  Map<ExpenseCategory, double> get categoryTotals {
    final Map<ExpenseCategory, double> totals = {};
    for (final expense in _expenses) {
      final cat = expense.category;
      totals[cat] = (totals[cat] ?? 0.0) + expense.amount;
    }
    return totals;
  }

  List<MapEntry<ExpenseCategory, double>> get sortedCategoryTotals {
    final entries = categoryTotals.entries.toList();
    entries.sort((a, b) => b.value.compareTo(a.value));
    return entries;
  }

  ExpenseCategory? get topSpendingCategory {
    final sorted = sortedCategoryTotals;
    return sorted.isNotEmpty ? sorted.first.key : null;
  }

  Map<DateTime, List<Expense>> get groupedExpensesByDay {
    final Map<DateTime, List<Expense>> groups = {};
    for (final expense in _expenses) {
      final dayKey = DateTime(
        expense.date.year,
        expense.date.month,
        expense.date.day,
      );
      if (!groups.containsKey(dayKey)) {
        groups[dayKey] = [];
      }
      groups[dayKey]!.add(expense);
    }
    return groups;
  }

  Future<void> _init() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      _currencySymbol = prefs.getString('preferred_currency') ?? '₱';

      // 1. Initialize local DB and clear any previous hardcoded seed data
      await _dbService.init();
      await _dbService.clearSampleDataOnce();
      await _loadExpenses();
    } catch (e) {
      debugPrint('ExpenseProvider initialization error: $e');
    } finally {
      // 2. UNBLOCK UI IMMEDIATELY as soon as local database is ready!
      _isLoading = false;
      notifyListeners();
    }

    // 3. Run cloud sync in the background without blocking the UI
    _backgroundFirestoreSync();
  }

  Future<void> _backgroundFirestoreSync() async {
    try {
      if (!_firestoreService.isInitialized) {
        final ok = await _firestoreService.init();
        if (!ok) return;
      }

      final remoteExpenses = await _firestoreService.fetchExpenses();
      if (remoteExpenses.isNotEmpty) {
        // Merge remote expenses into local database
        for (final exp in remoteExpenses) {
          await _dbService.insertExpense(exp);
        }
        await _loadExpenses();
        notifyListeners();
      } else {
        // Upload initial local data to Firestore if remote is completely empty
        final allLocal = await _dbService.getAllExpenses();
        if (allLocal.isNotEmpty) {
          await _firestoreService.syncAllExpenses(allLocal);
        }
      }
    } catch (e) {
      debugPrint('Background Firestore sync error: $e');
    }
  }

  Future<void> _loadExpenses() async {
    _expenses = await _dbService.getExpensesForMonth(
      _selectedMonth.year,
      _selectedMonth.month,
    );
    _touchedChartIndex = null;
  }

  void setTouchedChartIndex(int? index) {
    _touchedChartIndex = index;
    notifyListeners();
  }

  void toggleTheme() {
    if (_themeMode == ThemeMode.light) {
      _themeMode = ThemeMode.dark;
    } else if (_themeMode == ThemeMode.dark) {
      _themeMode = ThemeMode.system;
    } else {
      _themeMode = ThemeMode.light;
    }
    notifyListeners();
  }

  Future<void> setCurrency(String symbol) async {
    _currencySymbol = symbol;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('preferred_currency', symbol);
    } catch (_) {}
  }

  Future<void> setSelectedMonth(DateTime month) async {
    final normalized = DateTime(month.year, month.month, 1);
    if (normalized != _selectedMonth) {
      _selectedMonth = normalized;
      _isLoading = true;
      notifyListeners();

      await _loadExpenses();

      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> previousMonth() async {
    final prev = _selectedMonth.month == 1
        ? DateTime(_selectedMonth.year - 1, 12, 1)
        : DateTime(_selectedMonth.year, _selectedMonth.month - 1, 1);
    await setSelectedMonth(prev);
  }

  Future<void> nextMonth() async {
    final next = _selectedMonth.month == 12
        ? DateTime(_selectedMonth.year + 1, 1, 1)
        : DateTime(_selectedMonth.year, _selectedMonth.month + 1, 1);
    await setSelectedMonth(next);
  }

  Future<void> goToCurrentMonth() async {
    final now = DateTime.now();
    await setSelectedMonth(DateTime(now.year, now.month, 1));
  }

  Future<void> addExpense({
    required double amount,
    required String categoryId,
    required DateTime date,
    String? note,
  }) async {
    final expense = Expense(
      id: _uuid.v4(),
      amount: amount,
      categoryId: categoryId,
      date: date,
      note: (note != null && note.trim().isNotEmpty) ? note.trim() : null,
      createdAt: DateTime.now(),
    );

    // Save locally
    await _dbService.insertExpense(expense);

    // Sync to Firestore in background
    if (_firestoreService.isInitialized) {
      _firestoreService.syncExpense(expense);
    }

    if (expense.date.year == _selectedMonth.year &&
        expense.date.month == _selectedMonth.month) {
      await _loadExpenses();
      notifyListeners();
    } else {
      await setSelectedMonth(
        DateTime(expense.date.year, expense.date.month, 1),
      );
    }
  }

  Future<void> updateExpense(Expense updatedExpense) async {
    // Update locally
    await _dbService.updateExpense(updatedExpense);

    // Sync update to Firestore
    if (_firestoreService.isInitialized) {
      _firestoreService.syncExpense(updatedExpense);
    }

    await _loadExpenses();
    notifyListeners();
  }

  Future<Expense?> deleteExpense(String id) async {
    final index = _expenses.indexWhere((e) => e.id == id);
    if (index != -1) {
      final removed = _expenses[index];
      _lastDeletedExpense = removed;

      // Delete locally
      await _dbService.deleteExpense(id);

      // Delete from Firestore
      if (_firestoreService.isInitialized) {
        _firestoreService.deleteExpense(id);
      }

      await _loadExpenses();
      notifyListeners();
      return removed;
    }
    return null;
  }

  Future<void> undoDelete() async {
    if (_lastDeletedExpense != null) {
      final restored = _lastDeletedExpense!;
      _lastDeletedExpense = null;

      // Restore locally
      await _dbService.insertExpense(restored);

      // Restore to Firestore
      if (_firestoreService.isInitialized) {
        _firestoreService.syncExpense(restored);
      }

      if (restored.date.year == _selectedMonth.year &&
          restored.date.month == _selectedMonth.month) {
        await _loadExpenses();
      } else {
        await setSelectedMonth(
          DateTime(restored.date.year, restored.date.month, 1),
        );
      }
      notifyListeners();
    }
  }

  Future<bool> syncWithFirestore() async {
    if (!_firestoreService.isInitialized) {
      final initialized = await _firestoreService.init();
      if (!initialized) return false;
    }

    _isSyncing = true;
    notifyListeners();

    try {
      // 1. Fetch remote expenses
      final remoteExpenses = await _firestoreService.fetchExpenses();
      final localExpenses = await _dbService.getAllExpenses();

      // Merge remote to local
      for (final exp in remoteExpenses) {
        await _dbService.insertExpense(exp);
      }

      // Sync any local expenses missing in remote
      final remoteIds = remoteExpenses.map((e) => e.id).toSet();
      final missingRemote =
          localExpenses.where((e) => !remoteIds.contains(e.id)).toList();
      if (missingRemote.isNotEmpty) {
        await _firestoreService.syncAllExpenses(missingRemote);
      }

      await _loadExpenses();
      return true;
    } catch (e) {
      debugPrint('Sync with Firestore failed: $e');
      return false;
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  Future<void> clearAllData() async {
    _isLoading = true;
    notifyListeners();

    await _dbService.clearAllExpenses();
    _expenses.clear();

    if (_firestoreService.isInitialized) {
      await _firestoreService.clearAll();
    }

    _isLoading = false;
    notifyListeners();
  }
}
