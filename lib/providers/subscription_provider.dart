import 'package:flutter/foundation.dart';
import '../models/subscription.dart';
import '../services/database_helper.dart';

class SubscriptionProvider extends ChangeNotifier {
  List<Subscription> _subscriptions = [];
  bool _isLoading = false;
  List<Subscription> _upcomingReminders = [];

  List<Subscription> get subscriptions => _subscriptions;
  List<Subscription> get activeSubscriptions => _subscriptions.where((s) => s.isActive).toList();
  List<Subscription> get upcomingReminders => _upcomingReminders;
  bool get isLoading => _isLoading;

  final DatabaseHelper _databaseHelper = DatabaseHelper();

  SubscriptionProvider() {
    loadSubscriptions();
  }

  // Calculate total monthly subscription cost
  double get totalMonthlyCost {
    double total = 0.0;
    for (final subscription in activeSubscriptions) {
      switch (subscription.billingCycle.toLowerCase()) {
        case 'weekly':
          total += subscription.amount * 4.33; // Approximate weeks per month
          break;
        case 'bi-weekly':
          total += subscription.amount * 2.17; // Approximate bi-weeks per month
          break;
        case 'monthly':
          total += subscription.amount;
          break;
        case 'yearly':
          total += subscription.amount / 12;
          break;
      }
    }
    return total;
  }

  // Calculate total yearly subscription cost
  double get totalYearlyCost {
    double total = 0.0;
    for (final subscription in activeSubscriptions) {
      switch (subscription.billingCycle.toLowerCase()) {
        case 'weekly':
          total += subscription.amount * 52;
          break;
        case 'bi-weekly':
          total += subscription.amount * 26;
          break;
        case 'monthly':
          total += subscription.amount * 12;
          break;
        case 'yearly':
          total += subscription.amount;
          break;
      }
    }
    return total;
  }

  Future<void> loadSubscriptions() async {
    _isLoading = true;
    notifyListeners();

    try {
      _subscriptions = await _databaseHelper.getSubscriptions();
      _updateUpcomingReminders();
      print('Loaded ${_subscriptions.length} subscriptions');
    } catch (e) {
      print('Error loading subscriptions: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addSubscription(Subscription subscription) async {
    try {
      final newSubscription = await _databaseHelper.insertSubscription(subscription);
      _subscriptions.add(newSubscription);
      _subscriptions.sort((a, b) => a.nextBillingDate.compareTo(b.nextBillingDate));
      _updateUpcomingReminders();
      print('Added subscription: ${newSubscription.name}');
      notifyListeners();
    } catch (e) {
      print('Error adding subscription: $e');
      rethrow;
    }
  }

  Future<void> updateSubscription(Subscription subscription) async {
    try {
      await _databaseHelper.updateSubscription(subscription);
      final index = _subscriptions.indexWhere((s) => s.id == subscription.id);
      if (index != -1) {
        _subscriptions[index] = subscription;
        _subscriptions.sort((a, b) => a.nextBillingDate.compareTo(b.nextBillingDate));
        _updateUpcomingReminders();
        print('Updated subscription: ${subscription.name}');
        notifyListeners();
      }
    } catch (e) {
      print('Error updating subscription: $e');
      rethrow;
    }
  }

  Future<void> deleteSubscription(int id) async {
    try {
      await _databaseHelper.deleteSubscription(id);
      _subscriptions.removeWhere((s) => s.id == id);
      _updateUpcomingReminders();
      print('Deleted subscription with ID: $id');
      notifyListeners();
    } catch (e) {
      print('Error deleting subscription: $e');
      rethrow;
    }
  }

  Future<void> toggleSubscriptionStatus(int id) async {
    try {
      final subscription = _subscriptions.firstWhere((s) => s.id == id);
      final updatedSubscription = subscription.copyWith(
        isActive: !subscription.isActive,
        updatedAt: DateTime.now(),
      );
      await updateSubscription(updatedSubscription);
    } catch (e) {
      print('Error toggling subscription status: $e');
      rethrow;
    }
  }

  // Mark subscription as paid and update next billing date
  Future<void> markAsPaid(int id) async {
    try {
      final subscription = _subscriptions.firstWhere((s) => s.id == id);
      final newNextBillingDate = subscription.calculateNextBillingDate();
      
      final updatedSubscription = subscription.copyWith(
        nextBillingDate: newNextBillingDate,
        updatedAt: DateTime.now(),
      );
      
      await updateSubscription(updatedSubscription);
      
      // Optionally, automatically create an expense entry for this payment
      // You can uncomment this if you want automatic expense tracking
      /*
      final expenseProvider = Provider.of<ExpenseProvider>(context, listen: false);
      final expense = Expense(
        title: subscription.name,
        amount: subscription.amount,
        category: subscription.category,
        date: DateTime.now(),
        description: 'Subscription payment - ${subscription.billingCycle}',
      );
      await expenseProvider.addExpense(expense);
      */
      
    } catch (e) {
      print('Error marking subscription as paid: $e');
      rethrow;
    }
  }

  // Get subscriptions due within specified days
  List<Subscription> getSubscriptionsDueWithin(int days) {
    final cutoffDate = DateTime.now().add(Duration(days: days));
    return activeSubscriptions.where((subscription) {
      return subscription.nextBillingDate.isBefore(cutoffDate) ||
             subscription.nextBillingDate.isAtSameMomentAs(cutoffDate);
    }).toList();
  }

  // Get overdue subscriptions
  List<Subscription> get overdueSubscriptions {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    return activeSubscriptions.where((subscription) {
      final billingDay = DateTime(
        subscription.nextBillingDate.year,
        subscription.nextBillingDate.month,
        subscription.nextBillingDate.day,
      );
      return billingDay.isBefore(today);
    }).toList();
  }

  void _updateUpcomingReminders() {
    _upcomingReminders = activeSubscriptions.where((subscription) {
      return subscription.shouldShowReminder();
    }).toList();
    
    // Sort by next billing date
    _upcomingReminders.sort((a, b) => a.nextBillingDate.compareTo(b.nextBillingDate));
  }

  Subscription? getSubscriptionById(int id) {
    try {
      return _subscriptions.firstWhere((s) => s.id == id);
    } catch (e) {
      return null;
    }
  }

  List<Subscription> getSubscriptionsByCategory(String category) {
    return _subscriptions.where((s) => s.category == category).toList();
  }

  // Get subscription statistics
  Map<String, int> get subscriptionStats {
    final stats = <String, int>{};
    for (final subscription in activeSubscriptions) {
      stats[subscription.category] = (stats[subscription.category] ?? 0) + 1;
    }
    return stats;
  }

  // Force refresh
  void forceRefresh() {
    loadSubscriptions();
  }

  // Mark subscription as paid for current cycle
  Future<void> markSubscriptionAsPaid(int subscriptionId) async {
    try {
      final subscription = getSubscriptionById(subscriptionId);
      if (subscription == null) return;

      final paidSubscription = subscription.markAsPaid();
      await _databaseHelper.updateSubscription(paidSubscription);
      
      final index = _subscriptions.indexWhere((s) => s.id == subscriptionId);
      if (index != -1) {
        _subscriptions[index] = paidSubscription;
        print('Marked subscription as paid: ${paidSubscription.name}');
        notifyListeners();
      }
    } catch (e) {
      print('Error marking subscription as paid: $e');
      rethrow;
    }
  }

  // Update all subscriptions - check for billing cycles that have passed
  Future<void> updateBillingCycles() async {
    final now = DateTime.now();
    bool hasUpdates = false;
    
    for (final subscription in List.from(_subscriptions)) {
      if (subscription.isActive && subscription.nextBillingDate.isBefore(now)) {
        // Auto-update the next billing date if it has passed
        final newNextBillingDate = subscription.calculateNextBillingDate();
        final updatedSubscription = subscription.copyWith(
          nextBillingDate: newNextBillingDate,
          updatedAt: DateTime.now(),
        );
        
        try {
          await _databaseHelper.updateSubscription(updatedSubscription);
          final index = _subscriptions.indexWhere((s) => s.id == subscription.id);
          if (index != -1) {
            _subscriptions[index] = updatedSubscription;
            hasUpdates = true;
          }
        } catch (e) {
          print('Error updating billing cycle for ${subscription.name}: $e');
        }
      }
    }
    
    if (hasUpdates) {
      _subscriptions.sort((a, b) => a.nextBillingDate.compareTo(b.nextBillingDate));
      _updateUpcomingReminders();
      notifyListeners();
    }
  }
}
