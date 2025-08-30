class ExpensePreset {
  final int? id;
  final String name;
  final double amount;
  final String category;
  final String? description;
  final String? icon; // Icon name for visual representation

  ExpensePreset({
    this.id,
    required this.name,
    required this.amount,
    required this.category,
    this.description,
    this.icon,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'amount': amount,
      'category': category,
      'description': description,
      'icon': icon,
    };
  }

  factory ExpensePreset.fromMap(Map<String, dynamic> map) {
    return ExpensePreset(
      id: map['id']?.toInt(),
      name: map['name'] ?? '',
      amount: map['amount']?.toDouble() ?? 0.0,
      category: map['category'] ?? '',
      description: map['description'],
      icon: map['icon'],
    );
  }

  ExpensePreset copyWith({
    int? id,
    String? name,
    double? amount,
    String? category,
    String? description,
    String? icon,
  }) {
    return ExpensePreset(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      description: description ?? this.description,
      icon: icon ?? this.icon,
    );
  }

  // Convert preset to expense with current timestamp
  Map<String, dynamic> toExpenseMap() {
    return {
      'title': name,
      'amount': amount,
      'category': category,
      'date': DateTime.now().millisecondsSinceEpoch,
      'description': description,
    };
  }

  // Common preset categories with suggested icons
  static const Map<String, String> categoryIcons = {
    'Food': 'restaurant',
    'Transportation': 'directions_car',
    'Entertainment': 'movie',
    'Shopping': 'shopping_bag',
    'Bills': 'receipt',
    'Health': 'local_hospital',
    'Education': 'school',
    'Travel': 'flight',
    'Gas': 'local_gas_station',
    'Groceries': 'shopping_cart',
    'Coffee': 'local_cafe',
    'Gym': 'fitness_center',
    'Other': 'category',
  };

  // Suggested default presets
  static List<ExpensePreset> getDefaultPresets() {
    return [
      ExpensePreset(
        name: 'Morning Coffee',
        amount: 5.0,
        category: 'Food',
        description: 'Daily coffee',
        icon: 'local_cafe',
      ),
      ExpensePreset(
        name: 'Lunch',
        amount: 15.0,
        category: 'Food',
        description: 'Daily lunch',
        icon: 'restaurant',
      ),
      ExpensePreset(
        name: 'Gas Fill-up',
        amount: 60.0,
        category: 'Transportation',
        description: 'Car gas refill',
        icon: 'local_gas_station',
      ),
      ExpensePreset(
        name: 'Gym Membership',
        amount: 50.0,
        category: 'Health',
        description: 'Monthly gym fee',
        icon: 'fitness_center',
      ),
      ExpensePreset(
        name: 'Groceries',
        amount: 100.0,
        category: 'Food',
        description: 'Weekly grocery shopping',
        icon: 'shopping_cart',
      ),
    ];
  }
}
