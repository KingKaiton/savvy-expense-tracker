import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/expense_provider.dart';
import '../providers/income_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/expense_card.dart';
import '../widgets/income_card.dart';
import '../widgets/category_chart.dart';
import '../widgets/summary_card.dart';
import '../widgets/budget_status_card.dart';
import '../widgets/subscription_reminder_widget.dart';
import '../widgets/preset_quick_access_widget.dart';
import 'add_expense_screen.dart';
import 'add_income_screen.dart';
import 'expense_list_screen.dart';
import 'analytics_screen.dart';
import 'settings_screen.dart';
import 'subscription_management_screen.dart';
import 'preset_management_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final expenseProvider = context.read<ExpenseProvider>();
    final incomeProvider = context.read<IncomeProvider>();
    final settingsProvider = context.read<SettingsProvider>();
    
    // Load settings first
    await settingsProvider.loadSettings();
    
    // Then load expenses and income
    await Future.wait([
      expenseProvider.loadExpenses(),
      incomeProvider.loadIncomes(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      const _HomeTab(),
      const ExpenseListScreen(),
      const AnalyticsScreen(),
    ];

    return Scaffold(
      body: screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).primaryColor,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'Expenses',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Analytics',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddOptions(context);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Add Transaction',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const AddExpenseScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.remove, color: Colors.white),
                      label: const Text('Add Expense'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const AddIncomeScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.add, color: Colors.white),
                      label: const Text('Add Income'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Savvy'),
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const PresetManagementScreen()),
              );
            },
            tooltip: 'Expense Presets',
          ),
          IconButton(
            icon: const Icon(Icons.subscriptions),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const SubscriptionManagementScreen()),
              );
            },
            tooltip: 'Subscriptions',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: Consumer3<ExpenseProvider, IncomeProvider, SettingsProvider>(
        builder: (context, expenseProvider, incomeProvider, settingsProvider, child) {
          if (expenseProvider.isLoading || incomeProvider.isLoading || settingsProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

            return RefreshIndicator(
              onRefresh: () async {
                await expenseProvider.loadExpenses();
                await incomeProvider.loadIncomes();
                await expenseProvider.refreshDashboard();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Error message if any
                    if (expenseProvider.error != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: Colors.red),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                expenseProvider.error!,
                                style: const TextStyle(color: Colors.red),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.red),
                              onPressed: () => expenseProvider.clearError(),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Enhanced Summary Cards
                    Row(
                      children: [
                        Expanded(
                          child: SummaryCard(
                            title: 'Current Balance',
                            amount: incomeProvider.totalIncome - expenseProvider.totalExpenses,
                            icon: Icons.account_balance_wallet,
                            color: (incomeProvider.totalIncome - expenseProvider.totalExpenses) >= 0 
                                ? Colors.green 
                                : Colors.red,
                            subtitle: 'Income - Expenses',
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: SummaryCard(
                            title: 'Total Income',
                            amount: incomeProvider.totalIncome,
                            icon: Icons.trending_up,
                            color: Colors.green,
                            subtitle: '${incomeProvider.totalCount} transactions',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Additional Summary Cards
                    Row(
                      children: [
                        Expanded(
                          child: SummaryCard(
                            title: 'Total Expenses',
                            amount: expenseProvider.totalExpenses,
                            icon: Icons.trending_down,
                            color: Colors.red,
                            subtitle: '${expenseProvider.totalCount} transactions',
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: SummaryCard(
                            title: 'This Month',
                            amount: expenseProvider.monthTotal,
                            icon: Icons.calendar_today,
                            color: Colors.blue,
                            subtitle: '${expenseProvider.monthCount} this month',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Budget Status Card
                    const BudgetStatusCard(),
                    
                    // Subscription reminders
                    const SubscriptionReminderWidget(),

                    const SizedBox(height: 8),

                    // Quick Access Presets
                    const PresetQuickAccessWidget(),

                    // Category Chart
                    if (expenseProvider.expenses.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'Spending by Category',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const CategoryChart(),
                      const SizedBox(height: 24),
                    ],                  // Recent Transactions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Recent Transactions',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          // Switch to expenses tab
                        },
                        child: const Text('View All'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  if (expenseProvider.expenses.isEmpty && incomeProvider.incomes.isEmpty)
                    const _EmptyState()
                  else
                    ..._getRecentTransactions(expenseProvider, incomeProvider).map(
                      (transaction) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: transaction['type'] == 'expense' 
                            ? ExpenseCard(expense: transaction['data'])
                            : IncomeCard(income: transaction['data']),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  List<Map<String, dynamic>> _getRecentTransactions(ExpenseProvider expenseProvider, IncomeProvider incomeProvider) {
    List<Map<String, dynamic>> allTransactions = [];

    // Add expenses
    for (var expense in expenseProvider.getRecentExpenses()) {
      allTransactions.add({
        'type': 'expense',
        'data': expense,
        'date': expense.date,
      });
    }

    // Add incomes
    for (var income in incomeProvider.getRecentIncomes()) {
      allTransactions.add({
        'type': 'income',
        'data': income,
        'date': income.date,
      });
    }

    // Sort by date (most recent first)
    allTransactions.sort((a, b) => b['date'].compareTo(a['date']));

    // Return top 10 transactions
    return allTransactions.take(10).toList();
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
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
            'No transactions yet',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the + button to add your first transaction',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}
