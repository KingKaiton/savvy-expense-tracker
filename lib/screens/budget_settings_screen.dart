import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';

class BudgetSettingsScreen extends StatefulWidget {
  const BudgetSettingsScreen({super.key});

  @override
  State<BudgetSettingsScreen> createState() => _BudgetSettingsScreenState();
}

class _BudgetSettingsScreenState extends State<BudgetSettingsScreen> {
  final _dailyController = TextEditingController();
  final _weeklyController = TextEditingController();
  final _biweeklyController = TextEditingController();
  final _monthlyController = TextEditingController();

  bool _dailyEnabled = false;
  bool _weeklyEnabled = false;
  bool _biweeklyEnabled = false;
  bool _monthlyEnabled = false;
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentSettings();
  }

  void _loadCurrentSettings() {
    final settingsProvider = context.read<SettingsProvider>();
    
    _dailyController.text = settingsProvider.dailyLimit.amount.toString();
    _weeklyController.text = settingsProvider.weeklyLimit.amount.toString();
    _biweeklyController.text = settingsProvider.biweeklyLimit.amount.toString();
    _monthlyController.text = settingsProvider.monthlyLimit.amount.toString();
    
    _dailyEnabled = settingsProvider.dailyLimit.isEnabled;
    _weeklyEnabled = settingsProvider.weeklyLimit.isEnabled;
    _biweeklyEnabled = settingsProvider.biweeklyLimit.isEnabled;
    _monthlyEnabled = settingsProvider.monthlyLimit.isEnabled;
    _notificationsEnabled = settingsProvider.notificationsEnabled;
  }

  @override
  void dispose() {
    _dailyController.dispose();
    _weeklyController.dispose();
    _biweeklyController.dispose();
    _monthlyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Budget Settings'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Consumer<SettingsProvider>(
        builder: (context, settingsProvider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.account_balance_wallet,
                        color: Theme.of(context).primaryColor,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Budget Management',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Set spending limits to help control your expenses',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Notifications Setting
                Card(
                  child: SwitchListTile(
                    title: const Text(
                      'Budget Notifications',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: const Text('Get alerts when approaching or exceeding limits'),
                    value: _notificationsEnabled,
                    onChanged: (value) {
                      setState(() {
                        _notificationsEnabled = value;
                      });
                      settingsProvider.setNotificationsEnabled(value);
                    },
                    secondary: Icon(
                      _notificationsEnabled ? Icons.notifications_active : Icons.notifications_off,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Daily Limit
                _buildLimitCard(
                  title: 'Daily Spending Limit',
                  subtitle: 'Control your daily expenses',
                  icon: Icons.today,
                  controller: _dailyController,
                  isEnabled: _dailyEnabled,
                  onEnabledChanged: (value) {
                    setState(() {
                      _dailyEnabled = value;
                    });
                    _saveDailyLimit();
                  },
                  onSave: _saveDailyLimit,
                  currencySymbol: settingsProvider.currencySymbol,
                ),
                const SizedBox(height: 16),

                // Weekly Limit
                _buildLimitCard(
                  title: 'Weekly Spending Limit',
                  subtitle: 'Manage your weekly budget',
                  icon: Icons.calendar_view_week,
                  controller: _weeklyController,
                  isEnabled: _weeklyEnabled,
                  onEnabledChanged: (value) {
                    setState(() {
                      _weeklyEnabled = value;
                    });
                    _saveWeeklyLimit();
                  },
                  onSave: _saveWeeklyLimit,
                  currencySymbol: settingsProvider.currencySymbol,
                ),
                const SizedBox(height: 16),

                // Bi-weekly Limit
                _buildLimitCard(
                  title: 'Bi-weekly Spending Limit',
                  subtitle: 'Control your bi-weekly expenses (every 2 weeks)',
                  icon: Icons.date_range,
                  controller: _biweeklyController,
                  isEnabled: _biweeklyEnabled,
                  onEnabledChanged: (value) {
                    setState(() {
                      _biweeklyEnabled = value;
                    });
                    _saveBiweeklyLimit();
                  },
                  onSave: _saveBiweeklyLimit,
                  currencySymbol: settingsProvider.currencySymbol,
                ),
                const SizedBox(height: 16),

                // Monthly Limit
                _buildLimitCard(
                  title: 'Monthly Spending Limit',
                  subtitle: 'Keep your monthly expenses in check',
                  icon: Icons.calendar_month,
                  controller: _monthlyController,
                  isEnabled: _monthlyEnabled,
                  onEnabledChanged: (value) {
                    setState(() {
                      _monthlyEnabled = value;
                    });
                    _saveMonthlyLimit();
                  },
                  onSave: _saveMonthlyLimit,
                  currencySymbol: settingsProvider.currencySymbol,
                ),
                const SizedBox(height: 24),

                // Budget Tips
                _buildBudgetTips(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLimitCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required TextEditingController controller,
    required bool isEnabled,
    required ValueChanged<bool> onEnabledChanged,
    required VoidCallback onSave,
    required String currencySymbol,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).primaryColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: isEnabled,
                  onChanged: onEnabledChanged,
                ),
              ],
            ),
            if (isEnabled) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: controller,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Amount',
                        prefixText: currencySymbol,
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      onChanged: (value) => onSave(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: onSave,
                    child: const Text('Save'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetTips() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.lightbulb,
                  color: Colors.amber[600],
                ),
                const SizedBox(width: 12),
                const Text(
                  'Budget Tips',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildTip('Start with realistic limits based on your spending history'),
            _buildTip('Set daily limits 20-30% lower than your average to create a buffer'),
            _buildTip('Review and adjust your limits monthly'),
            _buildTip('Use the 80% warning to stay ahead of your budget'),
          ],
        ),
      ),
    );
  }

  Widget _buildTip(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 4,
            margin: const EdgeInsets.only(top: 8, right: 12),
            decoration: BoxDecoration(
              color: Colors.amber[600],
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _saveDailyLimit() {
    final amount = double.tryParse(_dailyController.text) ?? 0.0;
    if (amount > 0) {
      context.read<SettingsProvider>().setDailyLimit(amount, _dailyEnabled);
    }
  }

  void _saveWeeklyLimit() {
    final amount = double.tryParse(_weeklyController.text) ?? 0.0;
    if (amount > 0) {
      context.read<SettingsProvider>().setWeeklyLimit(amount, _weeklyEnabled);
    }
  }

  void _saveBiweeklyLimit() {
    final amount = double.tryParse(_biweeklyController.text) ?? 0.0;
    if (amount > 0) {
      context.read<SettingsProvider>().setBiweeklyLimit(amount, _biweeklyEnabled);
    }
  }

  void _saveMonthlyLimit() {
    final amount = double.tryParse(_monthlyController.text) ?? 0.0;
    if (amount > 0) {
      context.read<SettingsProvider>().setMonthlyLimit(amount, _monthlyEnabled);
    }
  }
}
