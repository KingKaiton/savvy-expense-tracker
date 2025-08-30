import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';
import '../providers/settings_provider.dart';

class BudgetStatusCard extends StatelessWidget {
  const BudgetStatusCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<ExpenseProvider, SettingsProvider>(
      builder: (context, expenseProvider, settingsProvider, child) {
        // Check if any limits are enabled
        final hasActiveLimit = settingsProvider.dailyLimit.isEnabled ||
            settingsProvider.weeklyLimit.isEnabled ||
            settingsProvider.biweeklyLimit.isEnabled ||
            settingsProvider.monthlyLimit.isEnabled;

        if (!hasActiveLimit) {
          return const SizedBox.shrink();
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.trending_up,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Budget Status',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Daily limit status
                if (settingsProvider.dailyLimit.isEnabled) ...[
                  _buildLimitIndicator(
                    context,
                    'Daily',
                    expenseProvider.todayTotal,
                    settingsProvider.dailyLimit.amount,
                    settingsProvider.isDailyLimitExceeded(expenseProvider.todayTotal),
                    settingsProvider.isDailyLimitApproaching(expenseProvider.todayTotal),
                    settingsProvider.currencySymbol,
                  ),
                  const SizedBox(height: 12),
                ],

                // Weekly limit status
                if (settingsProvider.weeklyLimit.isEnabled) ...[
                  _buildLimitIndicator(
                    context,
                    'Weekly',
                    expenseProvider.weekTotal,
                    settingsProvider.weeklyLimit.amount,
                    settingsProvider.isWeeklyLimitExceeded(expenseProvider.weekTotal),
                    settingsProvider.isWeeklyLimitApproaching(expenseProvider.weekTotal),
                    settingsProvider.currencySymbol,
                  ),
                  const SizedBox(height: 12),
                ],

                // Bi-weekly limit status
                if (settingsProvider.biweeklyLimit.isEnabled) ...[
                  _buildLimitIndicator(
                    context,
                    'Bi-weekly',
                    expenseProvider.biweekTotal,
                    settingsProvider.biweeklyLimit.amount,
                    settingsProvider.isBiweeklyLimitExceeded(expenseProvider.biweekTotal),
                    settingsProvider.isBiweeklyLimitApproaching(expenseProvider.biweekTotal),
                    settingsProvider.currencySymbol,
                  ),
                  const SizedBox(height: 12),
                ],

                // Monthly limit status
                if (settingsProvider.monthlyLimit.isEnabled) ...[
                  _buildLimitIndicator(
                    context,
                    'Monthly',
                    expenseProvider.monthTotal,
                    settingsProvider.monthlyLimit.amount,
                    settingsProvider.isMonthlyLimitExceeded(expenseProvider.monthTotal),
                    settingsProvider.isMonthlyLimitApproaching(expenseProvider.monthTotal),
                    settingsProvider.currencySymbol,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLimitIndicator(
    BuildContext context,
    String period,
    double spent,
    double limit,
    bool isExceeded,
    bool isApproaching,
    String currencySymbol,
  ) {
    final percentage = (spent / limit).clamp(0.0, 1.0);
    
    Color progressColor;
    IconData statusIcon;
    
    if (isExceeded) {
      progressColor = Colors.red;
      statusIcon = Icons.warning;
    } else if (isApproaching) {
      progressColor = Colors.orange;
      statusIcon = Icons.info_outline;
    } else {
      progressColor = Colors.green;
      statusIcon = Icons.check_circle_outline;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  statusIcon,
                  size: 16,
                  color: progressColor,
                ),
                const SizedBox(width: 4),
                Text(
                  period,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            Text(
              '$currencySymbol${spent.toStringAsFixed(0)} / $currencySymbol${limit.toStringAsFixed(0)}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percentage,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            minHeight: 6,
          ),
        ),
        if (isExceeded || isApproaching) ...[
          const SizedBox(height: 4),
          Text(
            isExceeded 
              ? 'Over budget by $currencySymbol${(spent - limit).toStringAsFixed(0)}'
              : 'Budget warning - $currencySymbol${(limit - spent).toStringAsFixed(0)} remaining',
            style: TextStyle(
              fontSize: 11,
              color: progressColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}
