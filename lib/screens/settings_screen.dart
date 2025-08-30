import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../models/currency.dart';
import '../utils/theme.dart';
import 'budget_settings_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Consumer<SettingsProvider>(
        builder: (context, settingsProvider, child) {
          if (settingsProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Theme Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.palette,
                            color: Theme.of(context).primaryColor,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Theme & Appearance',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        title: const Text('Color Theme'),
                        subtitle: Text(settingsProvider.themeColors.name),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _showThemeSelector(context),
                      ),
                      SwitchListTile(
                        title: const Text('Dark Mode'),
                        subtitle: const Text('Switch to dark theme'),
                        value: settingsProvider.isDarkMode,
                        onChanged: (value) => settingsProvider.setDarkMode(value),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Currency Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.attach_money,
                            color: Theme.of(context).primaryColor,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Currency',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        title: const Text('Selected Currency'),
                        subtitle: Text(
                          '${settingsProvider.selectedCurrency.name} (${settingsProvider.selectedCurrency.symbol})',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _showCurrencySelector(context),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Budget Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.account_balance_wallet,
                            color: Theme.of(context).primaryColor,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Budget & Spending Limits',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        title: const Text('Spending Limits'),
                        subtitle: const Text('Set daily, weekly, and monthly budget limits'),
                        leading: const Icon(Icons.trending_up),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const BudgetSettingsScreen(),
                            ),
                          );
                        },
                      ),
                      ListTile(
                        title: const Text('Budget Notifications'),
                        subtitle: Text(
                          settingsProvider.notificationsEnabled 
                            ? 'Enabled' 
                            : 'Disabled'
                        ),
                        leading: Icon(
                          settingsProvider.notificationsEnabled 
                            ? Icons.notifications_active 
                            : Icons.notifications_off
                        ),
                        trailing: Switch(
                          value: settingsProvider.notificationsEnabled,
                          onChanged: (value) => settingsProvider.setNotificationsEnabled(value),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Preview Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.preview,
                            color: Theme.of(context).primaryColor,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Preview',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              settingsProvider.themeColors.primary.withOpacity(0.1),
                              settingsProvider.themeColors.secondary.withOpacity(0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: settingsProvider.themeColors.accent.withOpacity(0.3),
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Sample Expense:'),
                                Text(
                                  settingsProvider.formatAmount(25.50),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: settingsProvider.themeColors.accent,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Total Expenses:'),
                                Text(
                                  settingsProvider.formatAmount(1250.75),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: settingsProvider.themeColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // About Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Theme.of(context).primaryColor,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'About',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Savvy Expense Tracker',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Version 1.0.0',
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'A comprehensive expense tracking application with beautiful themes and multi-currency support.',
                        style: TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showThemeSelector(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const _ThemeSelectionDialog(),
    );
  }

  void _showCurrencySelector(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const _CurrencySelectionDialog(),
    );
  }
}

class _ThemeSelectionDialog extends StatelessWidget {
  const _ThemeSelectionDialog();

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settingsProvider, child) {
        return AlertDialog(
          title: const Text('Select Theme'),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: ListView.builder(
              itemCount: AppThemeColors.allThemes.length,
              itemBuilder: (context, index) {
                final themeColors = AppThemeColors.allThemes[index];
                final themeType = AppThemeType.values[index];
                final isSelected = themeType == settingsProvider.selectedTheme;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            themeColors.primary,
                            themeColors.secondary,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(8),
                        border: isSelected
                            ? Border.all(color: themeColors.accent, width: 3)
                            : null,
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, color: Colors.white)
                          : null,
                    ),
                    title: Text(
                      themeColors.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(themeColors.description),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _ColorDot(themeColors.primary),
                            _ColorDot(themeColors.secondary),
                            _ColorDot(themeColors.accent),
                          ],
                        ),
                      ],
                    ),
                    onTap: () async {
                      await settingsProvider.setTheme(themeType);
                      if (context.mounted) {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Theme changed to ${themeColors.name}'),
                            backgroundColor: themeColors.primary,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }
}

class _ColorDot extends StatelessWidget {
  final Color color;

  const _ColorDot(this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 16,
      height: 16,
      margin: const EdgeInsets.only(right: 4),
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1),
      ),
    );
  }
}

class _CurrencySelectionDialog extends StatelessWidget {
  const _CurrencySelectionDialog();

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settingsProvider, child) {
        return AlertDialog(
          title: const Text('Select Currency'),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: ListView.builder(
              itemCount: Currency.supportedCurrencies.length,
              itemBuilder: (context, index) {
                final currency = Currency.supportedCurrencies[index];
                final isSelected = currency == settingsProvider.selectedCurrency;

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isSelected 
                        ? Theme.of(context).primaryColor 
                        : Colors.grey[300],
                    child: Text(
                      currency.symbol,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(currency.name),
                  subtitle: Text('${currency.code} • ${currency.symbol}'),
                  trailing: isSelected 
                      ? Icon(
                          Icons.check,
                          color: Theme.of(context).primaryColor,
                        )
                      : null,
                  onTap: () async {
                    await settingsProvider.setCurrency(currency);
                    if (context.mounted) {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Currency changed to ${currency.name}'),
                          backgroundColor: Colors.green,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }
}
