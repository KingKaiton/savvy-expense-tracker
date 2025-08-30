import 'package:flutter/material.dart';
import '../models/income.dart';
import '../services/database_helper.dart';

class IncomeProvider with ChangeNotifier {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  List<Income> _incomes = [];
  bool _isLoading = false;
  String? _error;

  List<Income> get incomes => _incomes;
  bool get isLoading => _isLoading;
  String? get error => _error;

  double get totalIncome => _incomes.fold(0, (sum, income) => sum + income.amount);

  Map<String, double> get categoryTotals {
    Map<String, double> totals = {};
    for (var income in _incomes) {
      totals[income.category] = (totals[income.category] ?? 0) + income.amount;
    }
    return totals;
  }

  List<String> get categories {
    Set<String> categorySet = _incomes.map((income) => income.category).toSet();
    List<String> sortedCategories = categorySet.toList();
    sortedCategories.sort();
    return sortedCategories;
  }

  // Dashboard-specific getters
  double get todayTotal {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    
    return _incomes
        .where((income) => income.date.isAfter(today.subtract(const Duration(milliseconds: 1))) && 
                          income.date.isBefore(tomorrow))
        .fold(0, (sum, income) => sum + income.amount);
  }

  int get todayCount {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    
    return _incomes
        .where((income) => income.date.isAfter(today.subtract(const Duration(milliseconds: 1))) && 
                          income.date.isBefore(tomorrow))
        .length;
  }

  double get monthTotal {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 1);
    
    return _incomes
        .where((income) => income.date.isAfter(startOfMonth.subtract(const Duration(milliseconds: 1))) && 
                          income.date.isBefore(endOfMonth))
        .fold(0, (sum, income) => sum + income.amount);
  }

  int get monthCount {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 1);
    
    return _incomes
        .where((income) => income.date.isAfter(startOfMonth.subtract(const Duration(milliseconds: 1))) && 
                          income.date.isBefore(endOfMonth))
        .length;
  }

  int get totalCount => _incomes.length;

  Future<void> loadIncomes() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('Loading incomes from database...');
      _incomes = await _databaseHelper.getAllIncome();
      print('Loaded ${_incomes.length} incomes successfully');
    } catch (e) {
      print('Error loading incomes: $e');
      _error = 'Failed to load incomes: ${e.toString()}';
      _incomes = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addIncome(Income income) async {
    try {
      print('Adding income: ${income.title} - ${income.amount}');
      final id = await _databaseHelper.insertIncome(income);
      
      if (id > 0) {
        // Create a new income with the generated ID
        final newIncome = income.copyWith(id: id);
        _incomes.insert(0, newIncome); // Add to beginning of list
        
        notifyListeners();
        print('Income added successfully with ID: $id');
        return true;
      } else {
        _error = 'Failed to add income';
        return false;
      }
    } catch (e) {
      print('Error adding income: $e');
      _error = 'Failed to add income: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateIncome(Income income) async {
    try {
      print('Updating income: ${income.id}');
      final rowsAffected = await _databaseHelper.updateIncome(income);
      
      if (rowsAffected > 0) {
        // Update the income in the local list
        final index = _incomes.indexWhere((i) => i.id == income.id);
        if (index != -1) {
          _incomes[index] = income;
        }
        
        notifyListeners();
        print('Income updated successfully');
        return true;
      } else {
        _error = 'Failed to update income';
        return false;
      }
    } catch (e) {
      print('Error updating income: $e');
      _error = 'Failed to update income: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteIncome(int id) async {
    try {
      print('Deleting income: $id');
      final rowsAffected = await _databaseHelper.deleteIncome(id);
      
      if (rowsAffected > 0) {
        _incomes.removeWhere((income) => income.id == id);
        notifyListeners();
        print('Income deleted successfully');
        return true;
      } else {
        _error = 'Failed to delete income';
        return false;
      }
    } catch (e) {
      print('Error deleting income: $e');
      _error = 'Failed to delete income: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  List<Income> getIncomesByDateRange(DateTime startDate, DateTime endDate) {
    return _incomes.where((income) {
      return income.date.isAfter(startDate.subtract(const Duration(milliseconds: 1))) &&
             income.date.isBefore(endDate.add(const Duration(milliseconds: 1)));
    }).toList();
  }

  List<Income> getIncomesByCategory(String category) {
    return _incomes.where((income) => income.category == category).toList();
  }

  double getTotalForCategory(String category) {
    return _incomes
        .where((income) => income.category == category)
        .fold(0, (sum, income) => sum + income.amount);
  }

  List<Income> getRecentIncomes({int limit = 5}) {
    List<Income> sortedIncomes = List.from(_incomes);
    sortedIncomes.sort((a, b) => b.date.compareTo(a.date));
    return sortedIncomes.take(limit).toList();
  }

  // Clear error message
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Method for testing - clear all incomes
  Future<void> clearAllIncomes() async {
    try {
      await _databaseHelper.clearAllIncome();
      _incomes.clear();
      notifyListeners();
    } catch (e) {
      print('Error clearing all incomes: $e');
    }
  }
}
