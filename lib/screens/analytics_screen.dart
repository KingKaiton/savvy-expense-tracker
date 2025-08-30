import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../providers/expense_provider.dart';
import '../providers/settings_provider.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  int _selectedPeriod = 0; // 0: This Month, 1: Last 3 Months, 2: This Year
  final List<String> _periods = ['This Month', 'Last 3 Months', 'This Year'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        actions: [
          PopupMenuButton<int>(
            icon: const Icon(Icons.date_range),
            onSelected: (value) {
              setState(() {
                _selectedPeriod = value;
              });
            },
            itemBuilder: (context) => _periods
                .asMap()
                .entries
                .map((entry) => PopupMenuItem(
                      value: entry.key,
                      child: Row(
                        children: [
                          if (_selectedPeriod == entry.key)
                            const Icon(Icons.check, size: 16),
                          if (_selectedPeriod != entry.key)
                            const SizedBox(width: 16),
                          const SizedBox(width: 8),
                          Text(entry.value),
                        ],
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
      body: Consumer2<ExpenseProvider, SettingsProvider>(
        builder: (context, expenseProvider, settingsProvider, child) {
          if (expenseProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (expenseProvider.expenses.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.analytics,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No data to analyze',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Add some expenses to see analytics',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final filteredExpenses = _getFilteredExpenses(expenseProvider);
          final categoryTotals = _getCategoryTotals(filteredExpenses);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Period Summary
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text(
                          _periods[_selectedPeriod],
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${settingsProvider.currencySymbol}${NumberFormat('#,##0.00').format(_getTotalAmount(filteredExpenses))}',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                        Text(
                          '${filteredExpenses.length} transactions',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Category Breakdown
                const Text(
                  'Category Breakdown',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        if (categoryTotals.isNotEmpty) ...[
                          SizedBox(
                            height: 200,
                            child: PieChart(
                              PieChartData(
                                sections: _generatePieChartSections(categoryTotals),
                                centerSpaceRadius: 40,
                                sectionsSpace: 2,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          ...categoryTotals.entries.map((entry) => 
                            _CategoryItem(
                              category: entry.key,
                              amount: entry.value,
                              percentage: (entry.value / _getTotalAmount(filteredExpenses)) * 100,
                              currencySymbol: settingsProvider.currencySymbol,
                            ),
                          ),
                        ] else
                          const Text('No data available for this period'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Spending Trends
                const Text(
                  'Spending Trends',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        SizedBox(
                          height: 200,
                          child: _buildTrendChart(filteredExpenses),
                        ),
                        const SizedBox(height: 16),
                        _buildTrendStats(filteredExpenses, settingsProvider),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<dynamic> _getFilteredExpenses(ExpenseProvider provider) {
    final now = DateTime.now();
    
    switch (_selectedPeriod) {
      case 0: // This Month
        final startOfMonth = DateTime(now.year, now.month, 1);
        final endOfMonth = DateTime(now.year, now.month + 1, 0);
        return provider.getExpensesByDateRange(startOfMonth, endOfMonth);
      
      case 1: // Last 3 Months
        final threeMonthsAgo = DateTime(now.year, now.month - 3, now.day);
        return provider.getExpensesByDateRange(threeMonthsAgo, now);
      
      case 2: // This Year
        final startOfYear = DateTime(now.year, 1, 1);
        final endOfYear = DateTime(now.year, 12, 31);
        return provider.getExpensesByDateRange(startOfYear, endOfYear);
      
      default:
        return provider.expenses;
    }
  }

  Map<String, double> _getCategoryTotals(List<dynamic> expenses) {
    Map<String, double> totals = {};
    for (var expense in expenses) {
      totals[expense.category] = (totals[expense.category] ?? 0) + expense.amount;
    }
    return totals;
  }

  double _getTotalAmount(List<dynamic> expenses) {
    return expenses.fold(0.0, (sum, expense) => sum + expense.amount);
  }

  List<PieChartSectionData> _generatePieChartSections(Map<String, double> categoryTotals) {
    final total = categoryTotals.values.fold(0.0, (sum, amount) => sum + amount);
    
    return categoryTotals.entries.map((entry) {
      final percentage = (entry.value / total) * 100;
      return PieChartSectionData(
        color: _getCategoryColor(entry.key),
        value: entry.value,
        title: '${percentage.toStringAsFixed(1)}%',
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  Widget _buildTrendChart(List<dynamic> expenses) {
    if (expenses.isEmpty) {
      return const Center(child: Text('No data available'));
    }

    // Group expenses by day for trend analysis
    Map<DateTime, double> dailyTotals = {};
    for (var expense in expenses) {
      final day = DateTime(expense.date.year, expense.date.month, expense.date.day);
      dailyTotals[day] = (dailyTotals[day] ?? 0) + expense.amount;
    }

    final sortedDays = dailyTotals.keys.toList()..sort();
    
    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  '\$${value.toInt()}',
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
          bottomTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: sortedDays.asMap().entries.map((entry) {
              return FlSpot(
                entry.key.toDouble(),
                dailyTotals[entry.value]!,
              );
            }).toList(),
            isCurved: true,
            color: Theme.of(context).primaryColor,
            barWidth: 3,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: Theme.of(context).primaryColor.withOpacity(0.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendStats(List<dynamic> expenses, SettingsProvider settingsProvider) {
    if (expenses.isEmpty) return const SizedBox();

    final totalAmount = _getTotalAmount(expenses);
    final averagePerDay = totalAmount / expenses.length;
    final highestExpense = expenses.fold(0.0, (max, expense) => 
        expense.amount > max ? expense.amount : max);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _StatItem(
          label: 'Average/Day',
          value: '${settingsProvider.currencySymbol}${averagePerDay.toStringAsFixed(2)}',
        ),
        _StatItem(
          label: 'Highest',
          value: '${settingsProvider.currencySymbol}${highestExpense.toStringAsFixed(2)}',
        ),
        _StatItem(
          label: 'Total Days',
          value: expenses.length.toString(),
        ),
      ],
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return Colors.orange;
      case 'transportation':
        return Colors.blue;
      case 'shopping':
        return Colors.purple;
      case 'entertainment':
        return Colors.red;
      case 'healthcare':
        return Colors.green;
      case 'education':
        return Colors.indigo;
      case 'utilities':
        return Colors.brown;
      case 'travel':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }
}

class _CategoryItem extends StatelessWidget {
  final String category;
  final double amount;
  final double percentage;
  final String currencySymbol;

  const _CategoryItem({
    required this.category,
    required this.amount,
    required this.percentage,
    required this.currencySymbol,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: _getCategoryColor(category),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              category,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            '${currencySymbol}${amount.toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          Text(
            '${percentage.toStringAsFixed(1)}%',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return Colors.orange;
      case 'transportation':
        return Colors.blue;
      case 'shopping':
        return Colors.purple;
      case 'entertainment':
        return Colors.red;
      case 'healthcare':
        return Colors.green;
      case 'education':
        return Colors.indigo;
      case 'utilities':
        return Colors.brown;
      case 'travel':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}
