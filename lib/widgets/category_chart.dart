import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/expense_provider.dart';
import '../providers/settings_provider.dart';

class CategoryChart extends StatelessWidget {
  const CategoryChart({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ExpenseProvider>(
      builder: (context, expenseProvider, child) {
        final categoryTotals = expenseProvider.categoryTotals;
        
        if (categoryTotals.isEmpty) {
          return const SizedBox(
            height: 200,
            child: Center(
              child: Text('No data available'),
            ),
          );
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                SizedBox(
                  height: 200,
                  child: PieChart(
                    PieChartData(
                      sections: _generateSections(categoryTotals),
                      centerSpaceRadius: 40,
                      sectionsSpace: 2,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 16,
                  runSpacing: 8,
                  children: categoryTotals.entries.map((entry) {
                    return _LegendItem(
                      color: _getCategoryColor(entry.key),
                      label: entry.key,
                      amount: entry.value,
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<PieChartSectionData> _generateSections(Map<String, double> categoryTotals) {
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

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final double amount;

  const _LegendItem({
    required this.color,
    required this.label,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settingsProvider, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '$label (${settingsProvider.currencySymbol}${amount.toStringAsFixed(0)})',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        );
      },
    );
  }
}
