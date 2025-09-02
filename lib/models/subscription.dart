import 'package:flutter/material.dart';

class Subscription {
  final int? id;
  final String name;
  final double amount;
  final String category;
  final DateTime startDate;
  final String billingCycle; // 'monthly', 'yearly', 'weekly', 'bi-weekly'
  final DateTime nextBillingDate;
  final String? description;
  final String? icon;
  final bool isActive;
  final String? reminderDays; // e.g., '3,7' for 3 and 7 days before
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? lastPaidDate; // New field to track when last payment was made
  final String? paymentStatus; // New field: 'paid', 'pending', 'overdue'

  Subscription({
    this.id,
    required this.name,
    required this.amount,
    required this.category,
    required this.startDate,
    required this.billingCycle,
    required this.nextBillingDate,
    this.description,
    this.icon,
    this.isActive = true,
    this.reminderDays = '3,7', // Default: remind 3 and 7 days before
    this.createdAt,
    this.updatedAt,
    this.lastPaidDate,
    this.paymentStatus = 'pending',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'amount': amount,
      'category': category,
      'start_date': startDate.millisecondsSinceEpoch,
      'billing_cycle': billingCycle,
      'next_billing_date': nextBillingDate.millisecondsSinceEpoch,
      'description': description,
      'icon': icon,
      'is_active': isActive ? 1 : 0,
      'reminder_days': reminderDays,
      'created_at': createdAt?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch,
      'updated_at': updatedAt?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch,
      'last_paid_date': lastPaidDate?.millisecondsSinceEpoch,
      'payment_status': paymentStatus,
    };
  }

  factory Subscription.fromMap(Map<String, dynamic> map) {
    return Subscription(
      id: map['id']?.toInt(),
      name: map['name'] ?? '',
      amount: map['amount']?.toDouble() ?? 0.0,
      category: map['category'] ?? '',
      startDate: DateTime.fromMillisecondsSinceEpoch(map['start_date'] ?? 0),
      billingCycle: map['billing_cycle'] ?? 'monthly',
      nextBillingDate: DateTime.fromMillisecondsSinceEpoch(map['next_billing_date'] ?? 0),
      description: map['description'],
      icon: map['icon'],
      isActive: (map['is_active'] ?? 1) == 1,
      reminderDays: map['reminder_days'],
      createdAt: map['created_at'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['created_at'])
          : null,
      updatedAt: map['updated_at'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['updated_at'])
          : null,
      lastPaidDate: map['last_paid_date'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['last_paid_date'])
          : null,
      paymentStatus: map['payment_status'] ?? 'pending',
    );
  }

  Subscription copyWith({
    int? id,
    String? name,
    double? amount,
    String? category,
    DateTime? startDate,
    String? billingCycle,
    DateTime? nextBillingDate,
    String? description,
    String? icon,
    bool? isActive,
    String? reminderDays,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastPaidDate,
    String? paymentStatus,
  }) {
    return Subscription(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      startDate: startDate ?? this.startDate,
      billingCycle: billingCycle ?? this.billingCycle,
      nextBillingDate: nextBillingDate ?? this.nextBillingDate,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      isActive: isActive ?? this.isActive,
      reminderDays: reminderDays ?? this.reminderDays,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastPaidDate: lastPaidDate ?? this.lastPaidDate,
      paymentStatus: paymentStatus ?? this.paymentStatus,
    );
  }

  // Calculate next billing date based on current next billing date and billing cycle
  DateTime calculateNextBillingDate() {
    switch (billingCycle.toLowerCase()) {
      case 'weekly':
        return nextBillingDate.add(const Duration(days: 7));
      case 'bi-weekly':
        return nextBillingDate.add(const Duration(days: 14));
      case 'monthly':
        // Add one month to the current next billing date
        final year = nextBillingDate.year;
        final month = nextBillingDate.month;
        final day = nextBillingDate.day;
        
        if (month == 12) {
          return DateTime(year + 1, 1, day);
        } else {
          // Handle cases where the day doesn't exist in the next month (e.g., Jan 31 -> Feb 28)
          final lastDayOfNextMonth = DateTime(year, month + 2, 0).day;
          final adjustedDay = day > lastDayOfNextMonth ? lastDayOfNextMonth : day;
          return DateTime(year, month + 1, adjustedDay);
        }
      case 'yearly':
        return DateTime(nextBillingDate.year + 1, nextBillingDate.month, nextBillingDate.day);
      default:
        return nextBillingDate.add(const Duration(days: 30)); // Default to 30 days
    }
  }

  // Get days until next billing
  int daysUntilNextBilling() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final billingDay = DateTime(nextBillingDate.year, nextBillingDate.month, nextBillingDate.day);
    return billingDay.difference(today).inDays;
  }

  // Check if reminder should be shown
  bool shouldShowReminder() {
    if (!isActive || reminderDays == null) return false;
    
    final daysUntil = daysUntilNextBilling();
    final reminderDaysList = reminderDays!.split(',').map((d) => int.tryParse(d.trim()) ?? 0).toList();
    
    return reminderDaysList.contains(daysUntil) || daysUntil <= 0;
  }

  // Get reminder message
  String getReminderMessage() {
    final daysUntil = daysUntilNextBilling();
    
    if (daysUntil < 0) {
      return 'Your $name subscription was due ${-daysUntil} days ago!';
    } else if (daysUntil == 0) {
      return 'Your $name subscription is due today!';
    } else if (daysUntil == 1) {
      return 'Your $name subscription is due tomorrow!';
    } else {
      return 'Your $name subscription is due in $daysUntil days!';
    }
  }

  // Check if subscription is paid for current billing cycle
  bool isPaidForCurrentCycle() {
    if (lastPaidDate == null) return false;
    
    // Get the start of current billing cycle
    final currentCycleStart = _getCurrentCycleStartDate();
    
    return lastPaidDate!.isAfter(currentCycleStart.subtract(const Duration(days: 1)));
  }

  // Get the start date of the current billing cycle
  DateTime _getCurrentCycleStartDate() {
    final now = DateTime.now();
    
    switch (billingCycle.toLowerCase()) {
      case 'weekly':
        // Find the most recent start date that's a multiple of 7 days from startDate
        final daysSinceStart = now.difference(startDate).inDays;
        final cyclesPassed = (daysSinceStart / 7).floor();
        return startDate.add(Duration(days: cyclesPassed * 7));
        
      case 'bi-weekly':
        // Find the most recent start date that's a multiple of 14 days from startDate
        final daysSinceStart = now.difference(startDate).inDays;
        final cyclesPassed = (daysSinceStart / 14).floor();
        return startDate.add(Duration(days: cyclesPassed * 14));
        
      case 'monthly':
        // Find the most recent monthly cycle start
        if (now.day >= startDate.day) {
          return DateTime(now.year, now.month, startDate.day);
        } else {
          if (now.month == 1) {
            return DateTime(now.year - 1, 12, startDate.day);
          } else {
            return DateTime(now.year, now.month - 1, startDate.day);
          }
        }
        
      case 'yearly':
        // Find the most recent yearly cycle start
        if (now.month > startDate.month || 
            (now.month == startDate.month && now.day >= startDate.day)) {
          return DateTime(now.year, startDate.month, startDate.day);
        } else {
          return DateTime(now.year - 1, startDate.month, startDate.day);
        }
        
      default:
        return startDate;
    }
  }

  // Get payment status with more detailed information
  String getDetailedPaymentStatus() {
    if (isPaidForCurrentCycle()) {
      return 'paid';
    }
    
    final daysUntil = daysUntilNextBilling();
    if (daysUntil < 0) {
      return 'overdue';
    } else if (daysUntil <= 7) {
      return 'due_soon';
    } else {
      return 'pending';
    }
  }

  // Get status color for UI
  Color getStatusColor() {
    switch (getDetailedPaymentStatus()) {
      case 'paid':
        return const Color(0xFF4CAF50); // Green
      case 'overdue':
        return const Color(0xFFD32F2F); // Red
      case 'due_soon':
        return const Color(0xFFFF9800); // Orange
      default:
        return const Color(0xFF757575); // Gray
    }
  }

  // Mark as paid for current cycle
  Subscription markAsPaid() {
    return copyWith(
      lastPaidDate: DateTime.now(),
      paymentStatus: 'paid',
      updatedAt: DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'Subscription(id: $id, name: $name, amount: $amount, nextBillingDate: $nextBillingDate)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is Subscription &&
        other.id == id &&
        other.name == name &&
        other.amount == amount &&
        other.category == category &&
        other.startDate == startDate &&
        other.billingCycle == billingCycle;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        amount.hashCode ^
        category.hashCode ^
        startDate.hashCode ^
        billingCycle.hashCode;
  }
}
