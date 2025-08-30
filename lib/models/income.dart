class Income {
  final int? id;
  final String title;
  final double amount;
  final String category;
  final DateTime date;
  final String? notes;

  Income({
    this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'category': category,
      'date': date.millisecondsSinceEpoch,
      'notes': notes,
    };
  }

  factory Income.fromMap(Map<String, dynamic> map) {
    return Income(
      id: map['id']?.toInt(),
      title: map['title'] ?? '',
      amount: map['amount']?.toDouble() ?? 0.0,
      category: map['category'] ?? '',
      date: DateTime.fromMillisecondsSinceEpoch(map['date']),
      notes: map['notes'],
    );
  }

  Income copyWith({
    int? id,
    String? title,
    double? amount,
    String? category,
    DateTime? date,
    String? notes,
  }) {
    return Income(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      date: date ?? this.date,
      notes: notes ?? this.notes,
    );
  }

  // Common income categories
  static const List<String> categories = [
    'Salary',
    'Freelance',
    'Business',
    'Investment',
    'Gift',
    'Bonus',
    'Side Hustle',
    'Rental Income',
    'Other',
  ];
}
