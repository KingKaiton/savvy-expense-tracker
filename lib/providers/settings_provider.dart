import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/currency.dart';
import '../utils/theme.dart';

enum SpendingLimitType { daily, weekly, biweekly, monthly }

class SpendingLimit {
  final double amount;
  final SpendingLimitType type;
  final bool isEnabled;

  SpendingLimit({
    required this.amount,
    required this.type,
    this.isEnabled = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'amount': amount,
      'type': type.index,
      'isEnabled': isEnabled,
    };
  }

  factory SpendingLimit.fromMap(Map<String, dynamic> map) {
    return SpendingLimit(
      amount: map['amount']?.toDouble() ?? 0.0,
      type: SpendingLimitType.values[map['type'] ?? 0],
      isEnabled: map['isEnabled'] ?? true,
    );
  }
}

class SettingsProvider with ChangeNotifier {
  Currency _selectedCurrency = Currency.supportedCurrencies.first; // Default to USD
  AppThemeType _selectedTheme = AppThemeType.modernTrust; // Default theme
  bool _isDarkMode = false;
  bool _isLoading = false;
  
  // Spending limits
  SpendingLimit _dailyLimit = SpendingLimit(amount: 100.0, type: SpendingLimitType.daily, isEnabled: false);
  SpendingLimit _weeklyLimit = SpendingLimit(amount: 500.0, type: SpendingLimitType.weekly, isEnabled: false);
  SpendingLimit _biweeklyLimit = SpendingLimit(amount: 1000.0, type: SpendingLimitType.biweekly, isEnabled: false);
  SpendingLimit _monthlyLimit = SpendingLimit(amount: 2000.0, type: SpendingLimitType.monthly, isEnabled: false);
  bool _notificationsEnabled = true;

  Currency get selectedCurrency => _selectedCurrency;
  AppThemeType get selectedTheme => _selectedTheme;
  bool get isDarkMode => _isDarkMode;
  bool get isLoading => _isLoading;
  String get currencySymbol => _selectedCurrency.symbol;
  AppThemeColors get themeColors => AppThemeColors.getTheme(_selectedTheme);

  // Spending limit getters
  SpendingLimit get dailyLimit => _dailyLimit;
  SpendingLimit get weeklyLimit => _weeklyLimit;
  SpendingLimit get biweeklyLimit => _biweeklyLimit;
  SpendingLimit get monthlyLimit => _monthlyLimit;
  bool get notificationsEnabled => _notificationsEnabled;

  ThemeData get lightTheme => AppTheme.createTheme(themeColors);
  ThemeData get darkTheme => AppTheme.createDarkTheme(themeColors);

  Future<void> loadSettings() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load currency
      final currencyCode = prefs.getString('selected_currency') ?? 'USD';
      _selectedCurrency = Currency.findByCode(currencyCode);
      
      // Load theme
      final themeIndex = prefs.getInt('selected_theme') ?? 0;
      _selectedTheme = AppThemeType.values[themeIndex];
      
      // Load dark mode preference
      _isDarkMode = prefs.getBool('dark_mode') ?? false;
      
      // Load spending limits
      final dailyLimitData = prefs.getString('daily_limit');
      if (dailyLimitData != null) {
        _dailyLimit = SpendingLimit.fromMap(Map<String, dynamic>.from(
          Uri.splitQueryString(dailyLimitData).map((key, value) => 
            MapEntry(key, _parseValue(value)))));
      }
      
      final weeklyLimitData = prefs.getString('weekly_limit');
      if (weeklyLimitData != null) {
        _weeklyLimit = SpendingLimit.fromMap(Map<String, dynamic>.from(
          Uri.splitQueryString(weeklyLimitData).map((key, value) => 
            MapEntry(key, _parseValue(value)))));
      }
      
      final biweeklyLimitData = prefs.getString('biweekly_limit');
      if (biweeklyLimitData != null) {
        _biweeklyLimit = SpendingLimit.fromMap(Map<String, dynamic>.from(
          Uri.splitQueryString(biweeklyLimitData).map((key, value) => 
            MapEntry(key, _parseValue(value)))));
      }
      
      final monthlyLimitData = prefs.getString('monthly_limit');
      if (monthlyLimitData != null) {
        _monthlyLimit = SpendingLimit.fromMap(Map<String, dynamic>.from(
          Uri.splitQueryString(monthlyLimitData).map((key, value) => 
            MapEntry(key, _parseValue(value)))));
      }
      
      // Load notifications setting
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
    } catch (e) {
      print('Error loading settings: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  dynamic _parseValue(String value) {
    if (value == 'true') return true;
    if (value == 'false') return false;
    final doubleValue = double.tryParse(value);
    if (doubleValue != null) return doubleValue;
    final intValue = int.tryParse(value);
    if (intValue != null) return intValue;
    return value;
  }

  Future<void> setCurrency(Currency currency) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('selected_currency', currency.code);
      _selectedCurrency = currency;
      notifyListeners();
    } catch (e) {
      print('Error saving currency: $e');
    }
  }

  Future<void> setTheme(AppThemeType theme) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('selected_theme', theme.index);
      _selectedTheme = theme;
      notifyListeners();
    } catch (e) {
      print('Error saving theme: $e');
    }
  }

  Future<void> setDarkMode(bool isDark) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('dark_mode', isDark);
      _isDarkMode = isDark;
      notifyListeners();
    } catch (e) {
      print('Error saving dark mode: $e');
    }
  }

  // Spending limit methods
  Future<void> setDailyLimit(double amount, bool isEnabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _dailyLimit = SpendingLimit(
        amount: amount,
        type: SpendingLimitType.daily,
        isEnabled: isEnabled,
      );
      final limitData = _encodeLimit(_dailyLimit);
      await prefs.setString('daily_limit', limitData);
      notifyListeners();
    } catch (e) {
      print('Error saving daily limit: $e');
    }
  }

  Future<void> setWeeklyLimit(double amount, bool isEnabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _weeklyLimit = SpendingLimit(
        amount: amount,
        type: SpendingLimitType.weekly,
        isEnabled: isEnabled,
      );
      final limitData = _encodeLimit(_weeklyLimit);
      await prefs.setString('weekly_limit', limitData);
      notifyListeners();
    } catch (e) {
      print('Error saving weekly limit: $e');
    }
  }

  Future<void> setBiweeklyLimit(double amount, bool isEnabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _biweeklyLimit = SpendingLimit(
        amount: amount,
        type: SpendingLimitType.biweekly,
        isEnabled: isEnabled,
      );
      final limitData = _encodeLimit(_biweeklyLimit);
      await prefs.setString('biweekly_limit', limitData);
      notifyListeners();
    } catch (e) {
      print('Error saving bi-weekly limit: $e');
    }
  }

  Future<void> setMonthlyLimit(double amount, bool isEnabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _monthlyLimit = SpendingLimit(
        amount: amount,
        type: SpendingLimitType.monthly,
        isEnabled: isEnabled,
      );
      final limitData = _encodeLimit(_monthlyLimit);
      await prefs.setString('monthly_limit', limitData);
      notifyListeners();
    } catch (e) {
      print('Error saving monthly limit: $e');
    }
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('notifications_enabled', enabled);
      _notificationsEnabled = enabled;
      notifyListeners();
    } catch (e) {
      print('Error saving notifications setting: $e');
    }
  }

  String _encodeLimit(SpendingLimit limit) {
    final map = limit.toMap();
    return Uri(queryParameters: map.map((key, value) => MapEntry(key, value.toString()))).query;
  }

  // Check if spending limits are exceeded
  bool isDailyLimitExceeded(double todaySpending) {
    return _dailyLimit.isEnabled && todaySpending > _dailyLimit.amount;
  }

  bool isWeeklyLimitExceeded(double weekSpending) {
    return _weeklyLimit.isEnabled && weekSpending > _weeklyLimit.amount;
  }

  bool isBiweeklyLimitExceeded(double biweekSpending) {
    return _biweeklyLimit.isEnabled && biweekSpending > _biweeklyLimit.amount;
  }

  bool isMonthlyLimitExceeded(double monthSpending) {
    return _monthlyLimit.isEnabled && monthSpending > _monthlyLimit.amount;
  }

  // Check if approaching limit (80% threshold)
  bool isDailyLimitApproaching(double todaySpending) {
    return _dailyLimit.isEnabled && todaySpending > (_dailyLimit.amount * 0.8);
  }

  bool isWeeklyLimitApproaching(double weekSpending) {
    return _weeklyLimit.isEnabled && weekSpending > (_weeklyLimit.amount * 0.8);
  }

  bool isBiweeklyLimitApproaching(double biweekSpending) {
    return _biweeklyLimit.isEnabled && biweekSpending > (_biweeklyLimit.amount * 0.8);
  }

  bool isMonthlyLimitApproaching(double monthSpending) {
    return _monthlyLimit.isEnabled && monthSpending > (_monthlyLimit.amount * 0.8);
  }

  // Get limit status messages
  String getDailyLimitMessage(double todaySpending) {
    if (!_dailyLimit.isEnabled) return '';
    
    if (isDailyLimitExceeded(todaySpending)) {
      final over = todaySpending - _dailyLimit.amount;
      return 'Daily limit exceeded by ${formatAmount(over)}!';
    } else if (isDailyLimitApproaching(todaySpending)) {
      final remaining = _dailyLimit.amount - todaySpending;
      return 'Daily limit warning: ${formatAmount(remaining)} remaining';
    }
    
    final remaining = _dailyLimit.amount - todaySpending;
    return 'Daily budget: ${formatAmount(remaining)} remaining';
  }

  String getWeeklyLimitMessage(double weekSpending) {
    if (!_weeklyLimit.isEnabled) return '';
    
    if (isWeeklyLimitExceeded(weekSpending)) {
      final over = weekSpending - _weeklyLimit.amount;
      return 'Weekly limit exceeded by ${formatAmount(over)}!';
    } else if (isWeeklyLimitApproaching(weekSpending)) {
      final remaining = _weeklyLimit.amount - weekSpending;
      return 'Weekly limit warning: ${formatAmount(remaining)} remaining';
    }
    
    final remaining = _weeklyLimit.amount - weekSpending;
    return 'Weekly budget: ${formatAmount(remaining)} remaining';
  }

  String getBiweeklyLimitMessage(double biweekSpending) {
    if (!_biweeklyLimit.isEnabled) return '';
    
    if (isBiweeklyLimitExceeded(biweekSpending)) {
      final over = biweekSpending - _biweeklyLimit.amount;
      return 'Bi-weekly limit exceeded by ${formatAmount(over)}!';
    } else if (isBiweeklyLimitApproaching(biweekSpending)) {
      final remaining = _biweeklyLimit.amount - biweekSpending;
      return 'Bi-weekly limit warning: ${formatAmount(remaining)} remaining';
    }
    
    final remaining = _biweeklyLimit.amount - biweekSpending;
    return 'Bi-weekly budget: ${formatAmount(remaining)} remaining';
  }

  String getMonthlyLimitMessage(double monthSpending) {
    if (!_monthlyLimit.isEnabled) return '';
    
    if (isMonthlyLimitExceeded(monthSpending)) {
      final over = monthSpending - _monthlyLimit.amount;
      return 'Monthly limit exceeded by ${formatAmount(over)}!';
    } else if (isMonthlyLimitApproaching(monthSpending)) {
      final remaining = _monthlyLimit.amount - monthSpending;
      return 'Monthly limit warning: ${formatAmount(remaining)} remaining';
    }
    
    final remaining = _monthlyLimit.amount - monthSpending;
    return 'Monthly budget: ${formatAmount(remaining)} remaining';
  }

  String formatAmount(double amount) {
    return '${_selectedCurrency.symbol}${amount.toStringAsFixed(2)}';
  }

  String formatAmountWithoutSymbol(double amount) {
    return amount.toStringAsFixed(2);
  }
}
