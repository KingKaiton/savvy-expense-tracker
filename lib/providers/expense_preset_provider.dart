import 'package:flutter/foundation.dart';
import '../models/expense_preset.dart';
import '../services/database_helper.dart';

class ExpensePresetProvider extends ChangeNotifier {
  List<ExpensePreset> _presets = [];
  bool _isLoading = false;

  List<ExpensePreset> get presets => _presets;
  bool get isLoading => _isLoading;

  final DatabaseHelper _databaseHelper = DatabaseHelper();

  ExpensePresetProvider() {
    loadPresets();
  }

  Future<void> loadPresets() async {
    _isLoading = true;
    notifyListeners();

    try {
      _presets = await _databaseHelper.getExpensePresets();
      print('Loaded ${_presets.length} expense presets');
    } catch (e) {
      print('Error loading expense presets: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addPreset(ExpensePreset preset) async {
    try {
      final newPreset = await _databaseHelper.insertExpensePreset(preset);
      _presets.add(newPreset);
      _presets.sort((a, b) => a.name.compareTo(b.name));
      print('Added expense preset: ${newPreset.name}');
      notifyListeners();
    } catch (e) {
      print('Error adding expense preset: $e');
      rethrow;
    }
  }

  Future<void> updatePreset(ExpensePreset preset) async {
    try {
      await _databaseHelper.updateExpensePreset(preset);
      final index = _presets.indexWhere((p) => p.id == preset.id);
      if (index != -1) {
        _presets[index] = preset;
        _presets.sort((a, b) => a.name.compareTo(b.name));
        print('Updated expense preset: ${preset.name}');
        notifyListeners();
      }
    } catch (e) {
      print('Error updating expense preset: $e');
      rethrow;
    }
  }

  Future<void> deletePreset(int id) async {
    try {
      await _databaseHelper.deleteExpensePreset(id);
      _presets.removeWhere((p) => p.id == id);
      print('Deleted expense preset with ID: $id');
      notifyListeners();
    } catch (e) {
      print('Error deleting expense preset: $e');
      rethrow;
    }
  }

  ExpensePreset? getPresetById(int id) {
    try {
      return _presets.firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
    }
  }

  List<ExpensePreset> getPresetsByCategory(String category) {
    return _presets.where((p) => p.category == category).toList();
  }

  void forceRefresh() {
    loadPresets();
  }
}
