import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/subscription_provider.dart';
import '../providers/settings_provider.dart';
import '../models/subscription.dart';
import '../screens/subscription_management_screen.dart';

class SubscriptionReminderWidget extends StatelessWidget {
  const SubscriptionReminderWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<SubscriptionProvider, SettingsProvider>(
      builder: (context, subscriptionProvider, settingsProvider, child) {
        if (subscriptionProvider.isLoading) {
          return const SizedBox.shrink();
        }

        final upcomingReminders = subscriptionProvider.upcomingReminders;
        final overdueSubscriptions = subscriptionProvider.overdueSubscriptions;

        // Show nothing if no reminders or overdue subscriptions
        if (upcomingReminders.isEmpty && overdueSubscriptions.isEmpty) {
          return const SizedBox.shrink();
        }

        return Card(
          margin: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.notification_important,
                      color: overdueSubscriptions.isNotEmpty ? Colors.red : Colors.orange,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      overdueSubscriptions.isNotEmpty ? 'Overdue Subscriptions' : 'Upcoming Bills',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: overdueSubscriptions.isNotEmpty ? Colors.red : Colors.orange,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SubscriptionManagementScreen(),
                          ),
                        );
                      },
                      child: const Text('View All'),
                    ),
                  ],
                ),
              ),
              
              // Show overdue subscriptions first
              ...overdueSubscriptions.take(2).map((subscription) =>
                _buildSubscriptionItem(context, subscription, settingsProvider, isOverdue: true)
              ).toList(),
              
              // Then show upcoming reminders
              ...upcomingReminders.take(3 - overdueSubscriptions.length).map((subscription) =>
                _buildSubscriptionItem(context, subscription, settingsProvider)
              ).toList(),
              
              if (upcomingReminders.length + overdueSubscriptions.length > 3)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: Text(
                      '+${upcomingReminders.length + overdueSubscriptions.length - 3} more',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSubscriptionItem(BuildContext context, Subscription subscription, 
      SettingsProvider settingsProvider, {bool isOverdue = false}) {
    final daysUntil = subscription.daysUntilNextBilling();
    String subtitle;
    
    if (isOverdue) {
      final daysPast = -daysUntil;
      subtitle = daysPast == 1 ? 'Due yesterday' : 'Due $daysPast days ago';
    } else if (daysUntil == 0) {
      subtitle = 'Due today';
    } else if (daysUntil == 1) {
      subtitle = 'Due tomorrow';
    } else {
      subtitle = 'Due in $daysUntil days';
    }

    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isOverdue 
              ? Colors.red.withOpacity(0.2)
              : Colors.orange.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          _getIconData(subscription.icon ?? 'subscriptions'),
          color: isOverdue ? Colors.red : Colors.orange,
          size: 20,
        ),
      ),
      title: Text(
        subscription.name,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Row(
        children: [
          Expanded(child: Text(subtitle)),
          if (isOverdue)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'OVERDUE',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '${settingsProvider.currencySymbol}${subscription.amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isOverdue ? Colors.red : Colors.orange,
            ),
          ),
          Text(
            DateFormat('MMM dd').format(subscription.nextBillingDate),
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
      onTap: () {
        _showQuickActions(context, subscription, settingsProvider);
      },
    );
  }

  void _showQuickActions(BuildContext context, Subscription subscription, SettingsProvider settingsProvider) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              subscription.name,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${settingsProvider.currencySymbol}${subscription.amount.toStringAsFixed(2)} • ${subscription.billingCycle}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subscription.getReminderMessage(),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: subscription.daysUntilNextBilling() < 0 ? Colors.red : Colors.orange,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      final subscriptionProvider = Provider.of<SubscriptionProvider>(context, listen: false);
                      subscriptionProvider.markAsPaid(subscription.id!);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Marked "${subscription.name}" as paid'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                    icon: const Icon(Icons.payment),
                    label: const Text('Mark Paid'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SubscriptionManagementScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.manage_accounts),
                    label: const Text('Manage'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName.toLowerCase()) {
      case 'netflix':
        return Icons.movie;
      case 'spotify':
        return Icons.music_note;
      case 'gym':
        return Icons.fitness_center;
      case 'phone':
        return Icons.phone;
      case 'internet':
        return Icons.wifi;
      case 'cloud':
        return Icons.cloud;
      case 'gaming':
        return Icons.games;
      case 'news':
        return Icons.newspaper;
      case 'food':
        return Icons.restaurant;
      case 'transport':
        return Icons.directions_car;
      default:
        return Icons.subscriptions;
    }
  }
}
