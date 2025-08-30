import 'package:flutter/material.dart';
import '../models/expense.dart';
import '../services/database_helper.dart';
import '../services/notification_service.dart';
import 'settings_provider.dart';

class ExpenseProvider with ChangeNotifier {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  List<Expense> _expenses = [];
  Map<String, dynamic> _dashboardStats = {};
  bool _isLoading = false;
  String? _error;

  // Cached values for performance
  double _cachedWeekTotal = 0.0;
  double _cachedBiweekTotal = 0.0;
  DateTime? _lastCalculationDate;

  List<Expense> get expenses => _expenses;
  Map<String, dynamic> get dashboardStats => _dashboardStats;
  bool get isLoading => _isLoading;
  String? get error => _error;

  double get totalExpenses => _expenses.fold(0, (sum, expense) => sum + expense.amount);

  Map<String, double> get categoryTotals {
    Map<String, double> totals = {};
    for (var expense in _expenses) {
      totals[expense.category] = (totals[expense.category] ?? 0) + expense.amount;
    }
    return totals;
  }

  List<String> get categories {
    Set<String> categorySet = _expenses.map((expense) => expense.category).toSet();
    List<String> sortedCategories = categorySet.toList();
    sortedCategories.sort();
    return sortedCategories;
  }

  Future<void> loadExpenses() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('Loading expenses from database...');
      _expenses = await _databaseHelper.getAllExpenses();
      _dashboardStats = await _databaseHelper.getDashboardStats();
      
      // Print database info for debugging
      await _databaseHelper.printDatabaseInfo();
      
      print('Loaded ${_expenses.length} expenses successfully');
    } catch (e) {
      print('Error loading expenses: $e');
      _error = 'Failed to load expenses: ${e.toString()}';
      _expenses = [];
      _dashboardStats = {};
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addExpense(Expense expense) async {
    try {
      print('Adding expense: ${expense.title} - ${expense.amount}');
      final id = await _databaseHelper.insertExpense(expense);
      
      if (id > 0) {
        // Create a new expense with the generated ID
        final newExpense = expense.copyWith(id: id);
        _expenses.insert(0, newExpense); // Add to beginning of list
        
        // Refresh dashboard stats
        _dashboardStats = await _databaseHelper.getDashboardStats();
        
        // Force recalculation of cached values
        _forceRecalculate();
        
        // Force recalculation of all dynamic values by notifying listeners
        notifyListeners();
        print('Expense added successfully with ID: $id');
        return true;
      } else {
        _error = 'Failed to add expense';
        return false;
      }
    } catch (e) {
      print('Error adding expense: $e');
      _error = 'Failed to add expense: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateExpense(Expense expense) async {
    try {
      print('Updating expense: ${expense.id}');
      final rowsAffected = await _databaseHelper.updateExpense(expense);
      
      if (rowsAffected > 0) {
        // Update the expense in the local list
        final index = _expenses.indexWhere((e) => e.id == expense.id);
        if (index != -1) {
          _expenses[index] = expense;
        }
        
        // Refresh dashboard stats
        _dashboardStats = await _databaseHelper.getDashboardStats();
        
        // Force recalculation of cached values
        _forceRecalculate();
        
        // Force recalculation of all dynamic values by notifying listeners
        notifyListeners();
        print('Expense updated successfully');
        return true;
      } else {
        _error = 'Failed to update expense';
        return false;
      }
    } catch (e) {
      print('Error updating expense: $e');
      _error = 'Failed to update expense: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteExpense(int id) async {
    try {
      print('Deleting expense: $id');
      final rowsAffected = await _databaseHelper.deleteExpense(id);
      
      if (rowsAffected > 0) {
        // Remove from local list
        _expenses.removeWhere((expense) => expense.id == id);
        
        // Refresh dashboard stats
        _dashboardStats = await _databaseHelper.getDashboardStats();
        
        // Force recalculation of cached values
        _forceRecalculate();
        
        // Force recalculation of all dynamic values by notifying listeners
        notifyListeners();
        print('Expense deleted successfully');
        return true;
      } else {
        _error = 'Failed to delete expense';
        return false;
      }
    } catch (e) {
      print('Error deleting expense: $e');
      _error = 'Failed to delete expense: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  List<Expense> getExpensesByDateRange(DateTime start, DateTime end) {
    return _expenses.where((expense) {
      return expense.date.isAfter(start.subtract(const Duration(days: 1))) &&
             expense.date.isBefore(end.add(const Duration(days: 1)));
    }).toList();
  }

  List<Expense> getExpensesByCategory(String category) {
    return _expenses.where((expense) => expense.category == category).toList();
  }

  double getTotalForCategory(String category) {
    return _expenses
        .where((expense) => expense.category == category)
        .fold(0, (sum, expense) => sum + expense.amount);
  }

  List<Expense> getRecentExpenses({int limit = 5}) {
    List<Expense> sortedExpenses = List.from(_expenses);
    sortedExpenses.sort((a, b) => b.date.compareTo(a.date));
    return sortedExpenses.take(limit).toList();
  }

  // Dashboard-specific getters
  double get todayTotal {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));
    
    return _expenses
        .where((expense) => 
            expense.date.isAfter(todayStart.subtract(const Duration(milliseconds: 1))) &&
            expense.date.isBefore(todayEnd))
        .fold(0.0, (sum, expense) => sum + expense.amount);
  }
  
  int get todayCount {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));
    
    return _expenses
        .where((expense) => 
            expense.date.isAfter(todayStart.subtract(const Duration(milliseconds: 1))) &&
            expense.date.isBefore(todayEnd))
        .length;
  }
  
  double get monthTotal {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 1);
    
    return _expenses
        .where((expense) => 
            expense.date.isAfter(monthStart.subtract(const Duration(milliseconds: 1))) &&
            expense.date.isBefore(monthEnd))
        .fold(0.0, (sum, expense) => sum + expense.amount);
  }
  
  int get monthCount {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 1);
    
    return _expenses
        .where((expense) => 
            expense.date.isAfter(monthStart.subtract(const Duration(milliseconds: 1))) &&
            expense.date.isBefore(monthEnd))
        .length;
  }
  int get totalCount => _expenses.length;

  // Get weekly spending
  double get weekTotal {
    _recalculateIfNeeded();
    return _cachedWeekTotal;
  }

  // Get bi-weekly spending (last 14 days)
  double get biweekTotal {
    _recalculateIfNeeded();
    return _cachedBiweekTotal;
  }

  // Recalculate cached values if needed
  void _recalculateIfNeeded() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    // Recalculate if it's a new day or if we haven't calculated before
    if (_lastCalculationDate == null || !_isSameDay(_lastCalculationDate!, today)) {
      _forceRecalculate();
      _lastCalculationDate = today;
    }
  }

  // Force recalculation of weekly and bi-weekly totals
  void _forceRecalculate() {
    final now = DateTime.now();
    
    // Calculate weekly total
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final startDate = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
    final endDate = startDate.add(const Duration(days: 7));
    
    _cachedWeekTotal = getExpensesByDateRange(startDate, endDate)
        .fold(0.0, (sum, expense) => sum + expense.amount);
    
    // Calculate bi-weekly total (last 14 days)
    final twoWeeksAgo = now.subtract(const Duration(days: 14));
    _cachedBiweekTotal = getExpensesByDateRange(twoWeeksAgo, now)
        .fold(0.0, (sum, expense) => sum + expense.amount);
    
    print('Recalculated: WeekTotal=$_cachedWeekTotal, BiweekTotal=$_cachedBiweekTotal');
  }

  // Helper to check if two dates are the same day
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }

  // Method to check spending limits and show notifications
  void checkSpendingLimits(BuildContext context, SettingsProvider settingsProvider) {
    if (!settingsProvider.notificationsEnabled) return;

    final notificationService = NotificationService();

    // Check daily limit
    if (settingsProvider.dailyLimit.isEnabled) {
      if (settingsProvider.isDailyLimitExceeded(todayTotal)) {
        notificationService.showSpendingLimitAlert(
          context,
          title: 'Daily Limit Exceeded!',
          message: settingsProvider.getDailyLimitMessage(todayTotal),
          isExceeded: true,
        );
      } else if (settingsProvider.isDailyLimitApproaching(todayTotal)) {
        notificationService.showSpendingLimitSnackBar(
          context,
          message: settingsProvider.getDailyLimitMessage(todayTotal),
          isExceeded: false,
        );
      }
    }

    // Check weekly limit
    if (settingsProvider.weeklyLimit.isEnabled) {
      if (settingsProvider.isWeeklyLimitExceeded(weekTotal)) {
        notificationService.showSpendingLimitAlert(
          context,
          title: 'Weekly Limit Exceeded!',
          message: settingsProvider.getWeeklyLimitMessage(weekTotal),
          isExceeded: true,
        );
      } else if (settingsProvider.isWeeklyLimitApproaching(weekTotal)) {
        notificationService.showSpendingLimitSnackBar(
          context,
          message: settingsProvider.getWeeklyLimitMessage(weekTotal),
          isExceeded: false,
        );
      }
    }

    // Check bi-weekly limit
    if (settingsProvider.biweeklyLimit.isEnabled) {
      if (settingsProvider.isBiweeklyLimitExceeded(biweekTotal)) {
        notificationService.showSpendingLimitAlert(
          context,
          title: 'Bi-weekly Limit Exceeded!',
          message: settingsProvider.getBiweeklyLimitMessage(biweekTotal),
          isExceeded: true,
        );
      } else if (settingsProvider.isBiweeklyLimitApproaching(biweekTotal)) {
        notificationService.showSpendingLimitSnackBar(
          context,
          message: settingsProvider.getBiweeklyLimitMessage(biweekTotal),
          isExceeded: false,
        );
      }
    }

    // Check monthly limit
    if (settingsProvider.monthlyLimit.isEnabled) {
      if (settingsProvider.isMonthlyLimitExceeded(monthTotal)) {
        notificationService.showSpendingLimitAlert(
          context,
          title: 'Monthly Limit Exceeded!',
          message: settingsProvider.getMonthlyLimitMessage(monthTotal),
          isExceeded: true,
        );
      } else if (settingsProvider.isMonthlyLimitApproaching(monthTotal)) {
        notificationService.showSpendingLimitSnackBar(
          context,
          message: settingsProvider.getMonthlyLimitMessage(monthTotal),
          isExceeded: false,
        );
      }
    }
  }

  // Method to refresh dashboard data
  Future<void> refreshDashboard() async {
    try {
      _dashboardStats = await _databaseHelper.getDashboardStats();
      notifyListeners();
      print('Dashboard refreshed - Today: $todayTotal, Month: $monthTotal, Week: $weekTotal, Biweek: $biweekTotal');
    } catch (e) {
      print('Error refreshing dashboard: $e');
    }
  }

  // Force complete data refresh
  Future<void> forceRefresh() async {
    try {
      await loadExpenses();
      await refreshDashboard();
    } catch (e) {
      print('Error in force refresh: $e');
    }
  }

  // Clear error message
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Method for testing - clear all expenses
  Future<void> clearAllExpenses() async {
    try {
      await _databaseHelper.clearAllExpenses();
      _expenses.clear();
      _dashboardStats = {};
      notifyListeners();
    } catch (e) {
      print('Error clearing all expenses: $e');
    }
  }
}
