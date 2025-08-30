import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import '../models/expense.dart';
import '../models/income.dart';
import '../models/expense_preset.dart';

// Import web-specific storage only if on web
import 'dart:html' as html show window;

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;
  static const String _webStorageKey = 'savvy_expenses';
  static const String _webIncomeStorageKey = 'savvy_income';

  Future<Database> get database async {
    if (kIsWeb) {
      // For web, we don't use SQLite, handle separately
      throw UnsupportedError('Web uses localStorage instead of SQLite');
    }
    
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    try {
      String path = join(await getDatabasesPath(), 'savvy_expenses.db');
      
      print('Database path: $path'); // Debug logging
      return await openDatabase(
        path,
        version: 4, // Increased version for expense presets table
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );
    } catch (e) {
      print('Database initialization error: $e');
      rethrow;
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    print('Creating database tables...');
    await db.execute('''
      CREATE TABLE expenses(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        category TEXT NOT NULL,
        date INTEGER NOT NULL,
        description TEXT,
        created_at INTEGER DEFAULT (strftime('%s', 'now')),
        updated_at INTEGER DEFAULT (strftime('%s', 'now'))
      )
    ''');
    
    // Create income table
    await db.execute('''
      CREATE TABLE income(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        category TEXT NOT NULL,
        date INTEGER NOT NULL,
        notes TEXT,
        created_at INTEGER DEFAULT (strftime('%s', 'now')),
        updated_at INTEGER DEFAULT (strftime('%s', 'now'))
      )
    ''');
    
    // Create expense presets table
    await db.execute('''
      CREATE TABLE expense_presets(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        amount REAL NOT NULL,
        category TEXT NOT NULL,
        description TEXT,
        icon TEXT,
        created_at INTEGER DEFAULT (strftime('%s', 'now')),
        updated_at INTEGER DEFAULT (strftime('%s', 'now'))
      )
    ''');
    
    // Create indexes for better performance
    await db.execute('CREATE INDEX idx_expenses_date ON expenses(date)');
    await db.execute('CREATE INDEX idx_expenses_category ON expenses(category)');
    await db.execute('CREATE INDEX idx_income_date ON income(date)');
    await db.execute('CREATE INDEX idx_income_category ON income(category)');
    print('Database tables created successfully');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    print('Upgrading database from version $oldVersion to $newVersion');
    if (oldVersion < 2) {
      // Add timestamp columns if they don't exist
      await db.execute('ALTER TABLE expenses ADD COLUMN created_at INTEGER DEFAULT (strftime("%s", "now"))');
      await db.execute('ALTER TABLE expenses ADD COLUMN updated_at INTEGER DEFAULT (strftime("%s", "now"))');
      
      // Create indexes
      await db.execute('CREATE INDEX IF NOT EXISTS idx_expenses_date ON expenses(date)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_expenses_category ON expenses(category)');
    }
    
    if (oldVersion < 3) {
      // Create income table
      await db.execute('''
        CREATE TABLE income(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          amount REAL NOT NULL,
          category TEXT NOT NULL,
          date INTEGER NOT NULL,
          notes TEXT,
          created_at INTEGER DEFAULT (strftime('%s', 'now')),
          updated_at INTEGER DEFAULT (strftime('%s', 'now'))
        )
      ''');
      
      // Create income indexes
      await db.execute('CREATE INDEX idx_income_date ON income(date)');
      await db.execute('CREATE INDEX idx_income_category ON income(category)');
    }
    
    if (oldVersion < 4) {
      // Create expense presets table
      await db.execute('''
        CREATE TABLE expense_presets(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          amount REAL NOT NULL,
          category TEXT NOT NULL,
          description TEXT,
          icon TEXT,
          created_at INTEGER DEFAULT (strftime('%s', 'now')),
          updated_at INTEGER DEFAULT (strftime('%s', 'now'))
        )
      ''');
    }
  }

  // Web storage methods
  Future<List<Expense>> _getExpensesFromWebStorage() async {
    if (!kIsWeb) return [];
    
    try {
      final jsonString = html.window.localStorage[_webStorageKey];
      if (jsonString == null || jsonString.isEmpty) return [];
      
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.map((json) => Expense.fromMap(json)).toList();
    } catch (e) {
      print('Error reading from web storage: $e');
      return [];
    }
  }

  Future<void> _saveExpensesToWebStorage(List<Expense> expenses) async {
    if (!kIsWeb) return;
    
    try {
      final jsonList = expenses.map((expense) => expense.toMap()).toList();
      final jsonString = json.encode(jsonList);
      html.window.localStorage[_webStorageKey] = jsonString;
      print('Saved ${expenses.length} expenses to web storage');
    } catch (e) {
      print('Error saving to web storage: $e');
    }
  }

  Future<int> insertExpense(Expense expense) async {
    if (kIsWeb) {
      // Web implementation using localStorage
      final expenses = await _getExpensesFromWebStorage();
      final newId = expenses.isEmpty ? 1 : expenses.map((e) => e.id ?? 0).reduce((a, b) => a > b ? a : b) + 1;
      final newExpense = expense.copyWith(id: newId);
      expenses.add(newExpense);
      await _saveExpensesToWebStorage(expenses);
      print('Inserted expense with ID: $newId (web storage)');
      return newId;
    }
    
    try {
      final db = await database;
      final expenseMap = expense.toMap();
      expenseMap['created_at'] = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      expenseMap['updated_at'] = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      
      final id = await db.insert('expenses', expenseMap);
      print('Inserted expense with ID: $id, Title: ${expense.title}, Amount: ${expense.amount}');
      return id;
    } catch (e) {
      print('Error inserting expense: $e');
      rethrow;
    }
  }

  Future<List<Expense>> getAllExpenses() async {
    if (kIsWeb) {
      final expenses = await _getExpensesFromWebStorage();
      expenses.sort((a, b) => b.date.compareTo(a.date));
      print('Retrieved ${expenses.length} expenses from web storage');
      return expenses;
    }
    
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'expenses',
        orderBy: 'date DESC, created_at DESC',
      );

      print('Retrieved ${maps.length} expenses from database');
      return List.generate(maps.length, (i) {
        return Expense.fromMap(maps[i]);
      });
    } catch (e) {
      print('Error getting all expenses: $e');
      return [];
    }
  }

  Future<List<Expense>> getRecentExpenses({int limit = 5}) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'expenses',
        orderBy: 'date DESC, created_at DESC',
        limit: limit,
      );

      print('Retrieved ${maps.length} recent expenses');
      return List.generate(maps.length, (i) {
        return Expense.fromMap(maps[i]);
      });
    } catch (e) {
      print('Error getting recent expenses: $e');
      return [];
    }
  }

  Future<List<Expense>> getExpensesByDateRange(DateTime start, DateTime end) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'expenses',
        where: 'date >= ? AND date <= ?',
        whereArgs: [start.millisecondsSinceEpoch, end.millisecondsSinceEpoch],
        orderBy: 'date DESC',
      );

      print('Retrieved ${maps.length} expenses for date range: ${start.toIso8601String()} to ${end.toIso8601String()}');
      return List.generate(maps.length, (i) {
        return Expense.fromMap(maps[i]);
      });
    } catch (e) {
      print('Error getting expenses by date range: $e');
      return [];
    }
  }

  Future<List<Expense>> getExpensesByCategory(String category) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'expenses',
        where: 'category = ?',
        whereArgs: [category],
        orderBy: 'date DESC',
      );

      print('Retrieved ${maps.length} expenses for category: $category');
      return List.generate(maps.length, (i) {
        return Expense.fromMap(maps[i]);
      });
    } catch (e) {
      print('Error getting expenses by category: $e');
      return [];
    }
  }

  Future<int> updateExpense(Expense expense) async {
    if (kIsWeb) {
      final expenses = await _getExpensesFromWebStorage();
      final index = expenses.indexWhere((e) => e.id == expense.id);
      if (index != -1) {
        expenses[index] = expense;
        await _saveExpensesToWebStorage(expenses);
        print('Updated expense ID: ${expense.id} (web storage)');
        return 1;
      }
      return 0;
    }
    
    try {
      final db = await database;
      final expenseMap = expense.toMap();
      expenseMap['updated_at'] = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      
      final rowsAffected = await db.update(
        'expenses',
        expenseMap,
        where: 'id = ?',
        whereArgs: [expense.id],
      );
      print('Updated expense ID: ${expense.id}, rows affected: $rowsAffected');
      return rowsAffected;
    } catch (e) {
      print('Error updating expense: $e');
      rethrow;
    }
  }

  Future<int> deleteExpense(int id) async {
    if (kIsWeb) {
      final expenses = await _getExpensesFromWebStorage();
      final initialLength = expenses.length;
      expenses.removeWhere((expense) => expense.id == id);
      await _saveExpensesToWebStorage(expenses);
      final deleted = initialLength - expenses.length;
      print('Deleted expense ID: $id (web storage), removed: $deleted');
      return deleted;
    }
    
    try {
      final db = await database;
      final rowsAffected = await db.delete(
        'expenses',
        where: 'id = ?',
        whereArgs: [id],
      );
      print('Deleted expense ID: $id, rows affected: $rowsAffected');
      return rowsAffected;
    } catch (e) {
      print('Error deleting expense: $e');
      rethrow;
    }
  }

  Future<double> getTotalExpenses() async {
    try {
      final db = await database;
      final result = await db.rawQuery('SELECT SUM(amount) as total FROM expenses');
      final total = result.first['total'] as double? ?? 0.0;
      print('Total expenses: $total');
      return total;
    } catch (e) {
      print('Error getting total expenses: $e');
      return 0.0;
    }
  }

  Future<double> getTotalExpensesByCategory(String category) async {
    try {
      final db = await database;
      final result = await db.rawQuery(
        'SELECT SUM(amount) as total FROM expenses WHERE category = ?',
        [category],
      );
      final total = result.first['total'] as double? ?? 0.0;
      print('Total expenses for $category: $total');
      return total;
    } catch (e) {
      print('Error getting total for category: $e');
      return 0.0;
    }
  }

  Future<Map<String, double>> getCategoryTotals() async {
    try {
      final db = await database;
      final result = await db.rawQuery(
        'SELECT category, SUM(amount) as total FROM expenses GROUP BY category ORDER BY total DESC',
      );
      
      Map<String, double> categoryTotals = {};
      for (var row in result) {
        categoryTotals[row['category'] as String] = row['total'] as double;
      }
      print('Category totals: $categoryTotals');
      return categoryTotals;
    } catch (e) {
      print('Error getting category totals: $e');
      return {};
    }
  }

  // Dashboard-specific queries
  Future<Map<String, dynamic>> getDashboardStats() async {
    if (kIsWeb) {
      // Web implementation using localStorage
      final expensesJson = html.window.localStorage[_webStorageKey];
      if (expensesJson == null) {
        return {
          'todayTotal': 0.0,
          'todayCount': 0,
          'monthTotal': 0.0,
          'monthCount': 0,
          'totalAmount': 0.0,
          'totalCount': 0,
        };
      }

      final List<dynamic> expensesList = jsonDecode(expensesJson);
      final expenses = expensesList.map((e) => Expense.fromMap(e as Map<String, dynamic>)).toList();
      
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final todayEnd = todayStart.add(const Duration(days: 1));
      final monthStart = DateTime(now.year, now.month, 1);
      final monthEnd = DateTime(now.year, now.month + 1, 1);
      
      double todayTotal = 0.0;
      int todayCount = 0;
      double monthTotal = 0.0;
      int monthCount = 0;
      double totalAmount = 0.0;
      int totalCount = expenses.length;
      
      for (final expense in expenses) {
        totalAmount += expense.amount;
        
        if (expense.date.isAfter(todayStart.subtract(const Duration(milliseconds: 1))) &&
            expense.date.isBefore(todayEnd)) {
          todayTotal += expense.amount;
          todayCount++;
        }
        
        if (expense.date.isAfter(monthStart.subtract(const Duration(milliseconds: 1))) &&
            expense.date.isBefore(monthEnd)) {
          monthTotal += expense.amount;
          monthCount++;
        }
      }
      
      final stats = {
        'todayTotal': todayTotal,
        'todayCount': todayCount,
        'monthTotal': monthTotal,
        'monthCount': monthCount,
        'totalAmount': totalAmount,
        'totalCount': totalCount,
      };
      
      print('Dashboard stats (web): $stats');
      return stats;
    }
    
    // SQLite implementation for mobile/desktop
    try {
      final db = await database;
      final now = DateTime.now();
      
      // Today's expenses
      final todayStart = DateTime(now.year, now.month, now.day);
      final todayEnd = todayStart.add(const Duration(days: 1));
      
      final todayResult = await db.rawQuery(
        'SELECT SUM(amount) as total, COUNT(*) as count FROM expenses WHERE date >= ? AND date < ?',
        [todayStart.millisecondsSinceEpoch, todayEnd.millisecondsSinceEpoch],
      );
      
      // This month's expenses
      final monthStart = DateTime(now.year, now.month, 1);
      final monthEnd = DateTime(now.year, now.month + 1, 1);
      
      final monthResult = await db.rawQuery(
        'SELECT SUM(amount) as total, COUNT(*) as count FROM expenses WHERE date >= ? AND date < ?',
        [monthStart.millisecondsSinceEpoch, monthEnd.millisecondsSinceEpoch],
      );
      
      // Total expenses
      final totalResult = await db.rawQuery(
        'SELECT SUM(amount) as total, COUNT(*) as count FROM expenses',
      );
      
      final stats = {
        'todayTotal': todayResult.first['total'] as double? ?? 0.0,
        'todayCount': todayResult.first['count'] as int? ?? 0,
        'monthTotal': monthResult.first['total'] as double? ?? 0.0,
        'monthCount': monthResult.first['count'] as int? ?? 0,
        'totalAmount': totalResult.first['total'] as double? ?? 0.0,
        'totalCount': totalResult.first['count'] as int? ?? 0,
      };
      
      print('Dashboard stats (database): $stats');
      return stats;
    } catch (e) {
      print('Error getting dashboard stats: $e');
      return {
        'todayTotal': 0.0,
        'todayCount': 0,
        'monthTotal': 0.0,
        'monthCount': 0,
        'totalAmount': 0.0,
        'totalCount': 0,
      };
    }
  }

  // Clear all data (for testing/reset purposes)
  Future<void> clearAllExpenses() async {
    try {
      final db = await database;
      await db.delete('expenses');
      print('All expenses cleared');
    } catch (e) {
      print('Error clearing expenses: $e');
    }
  }

  // Income-related methods
  
  // Web storage methods for income
  Future<List<Income>> _getIncomeFromWebStorage() async {
    if (!kIsWeb) return [];
    
    try {
      final jsonString = html.window.localStorage[_webIncomeStorageKey];
      if (jsonString == null || jsonString.isEmpty) return [];
      
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.map((json) => Income.fromMap(json)).toList();
    } catch (e) {
      print('Error reading income from web storage: $e');
      return [];
    }
  }

  Future<void> _saveIncomeToWebStorage(List<Income> incomeList) async {
    if (!kIsWeb) return;
    
    try {
      final jsonList = incomeList.map((income) => income.toMap()).toList();
      final jsonString = json.encode(jsonList);
      html.window.localStorage[_webIncomeStorageKey] = jsonString;
      print('Saved ${incomeList.length} income records to web storage');
    } catch (e) {
      print('Error saving income to web storage: $e');
    }
  }

  Future<int> insertIncome(Income income) async {
    if (kIsWeb) {
      // Web implementation using localStorage
      final incomeList = await _getIncomeFromWebStorage();
      final newId = incomeList.isEmpty ? 1 : incomeList.map((e) => e.id ?? 0).reduce((a, b) => a > b ? a : b) + 1;
      final newIncome = income.copyWith(id: newId);
      incomeList.add(newIncome);
      await _saveIncomeToWebStorage(incomeList);
      print('Inserted income with ID: $newId (web storage)');
      return newId;
    }
    
    try {
      final db = await database;
      final incomeMap = income.toMap();
      incomeMap['created_at'] = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      incomeMap['updated_at'] = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      
      final id = await db.insert('income', incomeMap);
      print('Inserted income with ID: $id, Title: ${income.title}, Amount: ${income.amount}');
      return id;
    } catch (e) {
      print('Error inserting income: $e');
      rethrow;
    }
  }

  Future<List<Income>> getAllIncome() async {
    if (kIsWeb) {
      final incomeList = await _getIncomeFromWebStorage();
      incomeList.sort((a, b) => b.date.compareTo(a.date));
      print('Retrieved ${incomeList.length} income records from web storage');
      return incomeList;
    }
    
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'income',
        orderBy: 'date DESC',
      );
      
      final incomeList = List.generate(maps.length, (i) {
        return Income.fromMap(maps[i]);
      });
      
      print('Retrieved ${incomeList.length} income records from database');
      return incomeList;
    } catch (e) {
      print('Error getting income: $e');
      return [];
    }
  }

  Future<int> updateIncome(Income income) async {
    if (kIsWeb) {
      final incomeList = await _getIncomeFromWebStorage();
      final index = incomeList.indexWhere((i) => i.id == income.id);
      if (index != -1) {
        incomeList[index] = income;
        await _saveIncomeToWebStorage(incomeList);
        print('Updated income with ID: ${income.id} (web storage)');
        return 1;
      }
      return 0;
    }
    
    try {
      final db = await database;
      final incomeMap = income.toMap();
      incomeMap['updated_at'] = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      
      final rowsAffected = await db.update(
        'income',
        incomeMap,
        where: 'id = ?',
        whereArgs: [income.id],
      );
      
      print('Updated income with ID: ${income.id}, rows affected: $rowsAffected');
      return rowsAffected;
    } catch (e) {
      print('Error updating income: $e');
      rethrow;
    }
  }

  Future<int> deleteIncome(int id) async {
    if (kIsWeb) {
      final incomeList = await _getIncomeFromWebStorage();
      final originalLength = incomeList.length;
      incomeList.removeWhere((i) => i.id == id);
      if (incomeList.length < originalLength) {
        await _saveIncomeToWebStorage(incomeList);
        print('Deleted income with ID: $id (web storage)');
        return 1;
      }
      return 0;
    }
    
    try {
      final db = await database;
      final rowsAffected = await db.delete(
        'income',
        where: 'id = ?',
        whereArgs: [id],
      );
      
      print('Deleted income with ID: $id, rows affected: $rowsAffected');
      return rowsAffected;
    } catch (e) {
      print('Error deleting income: $e');
      rethrow;
    }
  }

  Future<void> clearAllIncome() async {
    if (kIsWeb) {
      html.window.localStorage.remove(_webIncomeStorageKey);
      print('All income cleared from web storage');
      return;
    }
    
    try {
      final db = await database;
      await db.delete('income');
      print('All income cleared');
    } catch (e) {
      print('Error clearing income: $e');
    }
  }

  // Expense Preset Methods
  Future<List<ExpensePreset>> getExpensePresets() async {
    if (kIsWeb) {
      // For web, use localStorage
      try {
        final jsonString = html.window.localStorage['savvy_presets'];
        if (jsonString == null || jsonString.isEmpty) return [];
        
        final List<dynamic> jsonList = json.decode(jsonString);
        return jsonList.map((json) => ExpensePreset.fromMap(json)).toList();
      } catch (e) {
        print('Error loading presets from web storage: $e');
        return [];
      }
    }

    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'expense_presets',
        orderBy: 'name ASC',
      );

      return List.generate(maps.length, (i) {
        return ExpensePreset.fromMap(maps[i]);
      });
    } catch (e) {
      print('Error getting expense presets: $e');
      return [];
    }
  }

  Future<ExpensePreset> insertExpensePreset(ExpensePreset preset) async {
    if (kIsWeb) {
      // For web, use localStorage
      try {
        final presets = await getExpensePresets();
        final newId = presets.isEmpty ? 1 : (presets.map((p) => p.id ?? 0).reduce((a, b) => a > b ? a : b) + 1);
        final newPreset = preset.copyWith(id: newId);
        presets.add(newPreset);
        
        await _savePresetsToWebStorage(presets);
        print('Inserted preset: ${newPreset.name} (web storage)');
        return newPreset;
      } catch (e) {
        print('Error inserting preset to web storage: $e');
        rethrow;
      }
    }

    try {
      final db = await database;
      final id = await db.insert('expense_presets', preset.toMap());
      print('Inserted preset: ${preset.name}, ID: $id');
      return preset.copyWith(id: id);
    } catch (e) {
      print('Error inserting expense preset: $e');
      rethrow;
    }
  }

  Future<int> updateExpensePreset(ExpensePreset preset) async {
    if (kIsWeb) {
      // For web, use localStorage
      try {
        final presets = await getExpensePresets();
        final index = presets.indexWhere((p) => p.id == preset.id);
        if (index != -1) {
          presets[index] = preset;
          await _savePresetsToWebStorage(presets);
          print('Updated preset: ${preset.name} (web storage)');
          return 1;
        }
        return 0;
      } catch (e) {
        print('Error updating preset in web storage: $e');
        return 0;
      }
    }

    try {
      final db = await database;
      final rowsAffected = await db.update(
        'expense_presets',
        preset.toMap(),
        where: 'id = ?',
        whereArgs: [preset.id],
      );
      
      print('Updated preset: ${preset.name}, rows affected: $rowsAffected');
      return rowsAffected;
    } catch (e) {
      print('Error updating expense preset: $e');
      rethrow;
    }
  }

  Future<int> deleteExpensePreset(int id) async {
    if (kIsWeb) {
      // For web, use localStorage
      try {
        final presets = await getExpensePresets();
        final originalLength = presets.length;
        presets.removeWhere((p) => p.id == id);
        if (presets.length < originalLength) {
          await _savePresetsToWebStorage(presets);
          print('Deleted preset with ID: $id (web storage)');
          return 1;
        }
        return 0;
      } catch (e) {
        print('Error deleting preset from web storage: $e');
        return 0;
      }
    }

    try {
      final db = await database;
      final rowsAffected = await db.delete(
        'expense_presets',
        where: 'id = ?',
        whereArgs: [id],
      );
      
      print('Deleted preset with ID: $id, rows affected: $rowsAffected');
      return rowsAffected;
    } catch (e) {
      print('Error deleting expense preset: $e');
      rethrow;
    }
  }

  Future<void> _savePresetsToWebStorage(List<ExpensePreset> presets) async {
    if (!kIsWeb) return;
    
    try {
      final jsonString = json.encode(presets.map((p) => p.toMap()).toList());
      html.window.localStorage['savvy_presets'] = jsonString;
    } catch (e) {
      print('Error saving presets to web storage: $e');
    }
  }

  // Get database info
  Future<void> printDatabaseInfo() async {
    try {
      final db = await database;
      final tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table'");
      print('Database tables: $tables');
      
      final count = await db.rawQuery('SELECT COUNT(*) as count FROM expenses');
      print('Total expenses in database: ${count.first['count']}');
    } catch (e) {
      print('Error getting database info: $e');
    }
  }
}
