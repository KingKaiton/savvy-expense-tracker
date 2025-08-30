import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'providers/expense_provider.dart';
import 'providers/income_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/expense_preset_provider.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize database only for non-web platforms
  if (!kIsWeb) {
    await _initializeDatabaseForDesktop();
  }
  
  runApp(const SavvyApp());
}

Future<void> _initializeDatabaseForDesktop() async {
  try {
    // Only import and initialize for desktop platforms
    if (!kIsWeb) {
      // We'll handle desktop initialization here if needed
      // For now, let sqflite handle it automatically
    }
  } catch (e) {
    print('Database initialization error: $e');
  }
}

class SavvyApp extends StatelessWidget {
  const SavvyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ExpenseProvider()),
        ChangeNotifierProvider(create: (context) => IncomeProvider()),
        ChangeNotifierProvider(create: (context) => SettingsProvider()),
        ChangeNotifierProvider(create: (context) => ExpensePresetProvider()),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settingsProvider, child) {
          // Load settings on app start
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!settingsProvider.isLoading) {
              settingsProvider.loadSettings();
            }
          });

          return MaterialApp(
            title: 'Savvy - Expense Tracker',
            theme: settingsProvider.lightTheme,
            darkTheme: settingsProvider.darkTheme,
            themeMode: settingsProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            home: const HomeScreen(),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}