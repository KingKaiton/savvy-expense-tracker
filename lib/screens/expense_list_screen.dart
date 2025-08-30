import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/expense_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/expense_card.dart';
import 'add_expense_screen.dart';

class ExpenseListScreen extends StatefulWidget {
  const ExpenseListScreen({super.key});

  @override
  State<ExpenseListScreen> createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends State<ExpenseListScreen> {
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'This Month', 'Last 7 Days', 'Today'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expenses'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() {
                _selectedFilter = value;
              });
            },
            itemBuilder: (context) => _filters
                .map((filter) => PopupMenuItem(
                      value: filter,
                      child: Row(
                        children: [
                          if (_selectedFilter == filter)
                            const Icon(Icons.check, size: 16),
                          if (_selectedFilter != filter)
                            const SizedBox(width: 16),
                          const SizedBox(width: 8),
                          Text(filter),
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

          final filteredExpenses = _getFilteredExpenses(expenseProvider);
          final totalAmount = filteredExpenses.fold(0.0, (sum, expense) => sum + expense.amount);

          return Column(
            children: [
              // Summary header
              Container(
                width: double.infinity,
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      _selectedFilter,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${settingsProvider.currencySymbol}${NumberFormat('#,##0.00').format(totalAmount)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${filteredExpenses.length} expense${filteredExpenses.length == 1 ? '' : 's'}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              // Expense list
              Expanded(
                child: filteredExpenses.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.receipt_long,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No expenses found',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Try adjusting your filter or add a new expense',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => expenseProvider.loadExpenses(),
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: filteredExpenses.length,
                          itemBuilder: (context, index) {
                            final expense = filteredExpenses[index];
                            return ExpenseCard(
                              expense: expense,
                              onEdit: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => AddExpenseScreen(expense: expense),
                                  ),
                                );
                              },
                              onDelete: () => _deleteExpense(expense.id!),
                            );
                          },
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<dynamic> _getFilteredExpenses(ExpenseProvider provider) {
    final now = DateTime.now();
    
    switch (_selectedFilter) {
      case 'Today':
        final today = DateTime(now.year, now.month, now.day);
        final tomorrow = today.add(const Duration(days: 1));
        return provider.getExpensesByDateRange(today, tomorrow);
      
      case 'Last 7 Days':
        final sevenDaysAgo = DateTime(now.year, now.month, now.day - 7);
        return provider.getExpensesByDateRange(sevenDaysAgo, now);
      
      case 'This Month':
        final startOfMonth = DateTime(now.year, now.month, 1);
        final endOfMonth = DateTime(now.year, now.month + 1, 0);
        return provider.getExpensesByDateRange(startOfMonth, endOfMonth);
      
      default:
        return provider.expenses;
    }
  }

  Future<void> _deleteExpense(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Expense'),
        content: const Text('Are you sure you want to delete this expense?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await context.read<ExpenseProvider>().deleteExpense(id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Expense deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error deleting expense'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
