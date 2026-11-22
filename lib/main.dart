import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'providers/expense_provider.dart';
import 'screens/home_screen.dart';
import 'screens/splash_screen.dart';
import 'services/database_service.dart';
import 'services/firestore_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize SQLite FFI on desktop platforms
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // 2. Pre-initialize local database / storage service
  await DatabaseService.instance.init();

  // 3. Kick off Firestore initialization asynchronously in the background so it never blocks app launch
  FirestoreService.instance.init();

  final expenseProvider = ExpenseProvider();

  runApp(ExpenseTrackerApp(provider: expenseProvider));
}

class ExpenseTrackerApp extends StatelessWidget {
  final ExpenseProvider provider;

  const ExpenseTrackerApp({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: provider,
      builder: (context, _) {
        return MaterialApp(
          title: 'PesoRay',
          debugShowCheckedModeBanner: false,
          themeMode: provider.themeMode,
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF2563EB),
              brightness: Brightness.light,
            ),
            scaffoldBackgroundColor: const Color(0xFFF8FAFC),
            appBarTheme: const AppBarTheme(
              elevation: 0,
              scrolledUnderElevation: 1,
              centerTitle: false,
              backgroundColor: Color(0xFFF8FAFC),
            ),
            cardTheme: CardThemeData(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            floatingActionButtonTheme: FloatingActionButtonThemeData(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF3B82F6),
              brightness: Brightness.dark,
              surface: const Color(0xFF131720),
            ),
            scaffoldBackgroundColor: const Color(0xFF0F1218),
            appBarTheme: const AppBarTheme(
              elevation: 0,
              scrolledUnderElevation: 1,
              centerTitle: false,
              backgroundColor: Color(0xFF0F1218),
            ),
            cardTheme: CardThemeData(
              elevation: 0,
              color: const Color(0xFF191F2D),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            floatingActionButtonTheme: FloatingActionButtonThemeData(
              backgroundColor: const Color(0xFF3B82F6),
              foregroundColor: Colors.white,
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          home: SplashScreen(provider: provider),
        );
      },
    );
  }
}
