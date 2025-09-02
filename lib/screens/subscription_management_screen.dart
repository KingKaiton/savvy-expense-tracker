import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/subscription_provider.dart';
import '../providers/settings_provider.dart';
import '../models/subscription.dart';
import 'add_subscription_screen.dart';

class SubscriptionManagementScreen extends StatelessWidget {
  const SubscriptionManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscriptions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddSubscriptionScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer2<SubscriptionProvider, SettingsProvider>(
        builder: (context, subscriptionProvider, settingsProvider, child) {
          if (subscriptionProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final subscriptions = subscriptionProvider.subscriptions;

          if (subscriptions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.subscriptions,
                    size: 64,
                    color: Theme.of(context).colorScheme.secondary.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No subscriptions yet',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Track your recurring subscriptions and get reminders',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AddSubscriptionScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add First Subscription'),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Summary Card
              Card(
                margin: const EdgeInsets.all(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Subscription Summary',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildSummaryItem(
                              context,
                              'Monthly',
                              '${settingsProvider.currencySymbol}${subscriptionProvider.totalMonthlyCost.toStringAsFixed(2)}',
                              Icons.calendar_month,
                            ),
                          ),
                          Expanded(
                            child: _buildSummaryItem(
                              context,
                              'Yearly',
                              '${settingsProvider.currencySymbol}${subscriptionProvider.totalYearlyCost.toStringAsFixed(2)}',
                              Icons.calendar_today,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _buildSummaryItem(
                              context,
                              'Active',
                              '${subscriptionProvider.activeSubscriptions.length}',
                              Icons.check_circle,
                            ),
                          ),
                          Expanded(
                            child: _buildSummaryItem(
                              context,
                              'Due Soon',
                              '${subscriptionProvider.upcomingReminders.length}',
                              Icons.notification_important,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Reminders Section
              if (subscriptionProvider.upcomingReminders.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.notification_important,
                        color: Colors.orange,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Upcoming Bills',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                ...subscriptionProvider.upcomingReminders.map((subscription) =>
                  _buildReminderCard(context, subscription, subscriptionProvider, settingsProvider)
                ).toList(),
                const SizedBox(height: 16),
              ],

              // All Subscriptions
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Text(
                      'All Subscriptions',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Subscription List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: subscriptions.length,
                  itemBuilder: (context, index) {
                    final subscription = subscriptions[index];
                    return _buildSubscriptionCard(context, subscription, subscriptionProvider, settingsProvider);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummaryItem(BuildContext context, String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReminderCard(BuildContext context, Subscription subscription, 
      SubscriptionProvider subscriptionProvider, SettingsProvider settingsProvider) {
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      color: Colors.orange.withOpacity(0.1),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getIconData(subscription.icon ?? 'subscriptions'),
            color: Colors.orange,
            size: 20,
          ),
        ),
        title: Text(
          subscription.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(subscription.getReminderMessage()),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${settingsProvider.currencySymbol}${subscription.amount.toStringAsFixed(2)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
            Text(
              subscription.billingCycle,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
        onTap: () {
          _showSubscriptionActions(context, subscription, subscriptionProvider, settingsProvider);
        },
      ),
    );
  }

  Widget _buildSubscriptionCard(BuildContext context, Subscription subscription, 
      SubscriptionProvider subscriptionProvider, SettingsProvider settingsProvider) {
    final isOverdue = subscription.daysUntilNextBilling() < 0;
    final isDueSoon = subscription.shouldShowReminder() && subscription.daysUntilNextBilling() >= 0;
    final isPaid = subscription.isPaidForCurrentCycle();
    final statusColor = subscription.getStatusColor();
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: isPaid ? Border.all(color: statusColor, width: 2) : null,
        ),
        child: ListTile(
          leading: Stack(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: subscription.isActive 
                      ? Theme.of(context).colorScheme.primaryContainer
                      : Theme.of(context).colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getIconData(subscription.icon ?? 'subscriptions'),
                  color: subscription.isActive 
                      ? Theme.of(context).colorScheme.onPrimaryContainer
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                  size: 20,
                ),
              ),
              // Payment status indicator
              if (isPaid)
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1),
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 10,
                    ),
                  ),
                ),
            ],
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  subscription.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    decoration: subscription.isActive ? null : TextDecoration.lineThrough,
                  ),
                ),
              ),
              // Status badges
              if (isPaid)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'PAID',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              else if (isOverdue)
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
                )
              else if (isDueSoon)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'DUE SOON',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${subscription.category} • ${subscription.billingCycle}'),
              const SizedBox(height: 2),
              Text(
                'Next: ${DateFormat('MMM dd, yyyy').format(subscription.nextBillingDate)}',
                style: TextStyle(
                  color: isPaid 
                      ? statusColor 
                      : (isOverdue ? Colors.red : (isDueSoon ? Colors.orange : null)),
                  fontWeight: isPaid || isOverdue || isDueSoon ? FontWeight.w500 : null,
                ),
              ),
              if (isPaid) ...[
                const SizedBox(height: 2),
                Text(
                  'Paid on ${DateFormat('MMM dd').format(subscription.lastPaidDate!)}',
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${settingsProvider.currencySymbol}${subscription.amount.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isPaid 
                      ? statusColor 
                      : (subscription.isActive ? Theme.of(context).colorScheme.primary : null),
                ),
              ),
              if (!subscription.isActive)
                Text(
                  'Inactive',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
            ],
          ),
          onTap: () {
            _showSubscriptionActions(context, subscription, subscriptionProvider, settingsProvider);
          },
        ),
      ),
    );
  }

  void _showSubscriptionActions(BuildContext context, Subscription subscription, 
      SubscriptionProvider subscriptionProvider, SettingsProvider settingsProvider) {
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
              'Next billing: ${DateFormat('MMM dd, yyyy').format(subscription.nextBillingDate)}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            Text(
              '${settingsProvider.currencySymbol}${subscription.amount.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                // Conditional "Mark as Paid" or "Already Paid" button
                if (!subscription.isPaidForCurrentCycle())
                  ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.pop(context);
                      try {
                        await subscriptionProvider.markSubscriptionAsPaid(subscription.id!);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Marked "${subscription.name}" as paid'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Error marking as paid'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.payment),
                    label: const Text('Mark as Paid'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Paid for this cycle',
                          style: TextStyle(
                            color: Colors.green[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddSubscriptionScreen(subscription: subscription),
                      ),
                    );
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: () async {
                      Navigator.pop(context);
                      try {
                        await subscriptionProvider.toggleSubscriptionStatus(subscription.id!);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(subscription.isActive 
                                ? 'Deactivated "${subscription.name}"'
                                : 'Activated "${subscription.name}"'),
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Error updating subscription'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    icon: Icon(subscription.isActive ? Icons.pause : Icons.play_arrow),
                    label: Text(subscription.isActive ? 'Deactivate' : 'Activate'),
                  ),
                ),
                Expanded(
                  child: TextButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _showDeleteConfirmation(context, subscription, subscriptionProvider);
                    },
                    icon: const Icon(Icons.delete, color: Colors.red),
                    label: const Text('Delete', style: TextStyle(color: Colors.red)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, Subscription subscription, SubscriptionProvider subscriptionProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Subscription'),
        content: Text('Are you sure you want to delete "${subscription.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await subscriptionProvider.deleteSubscription(subscription.id!);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Deleted "${subscription.name}"')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Error deleting subscription')),
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
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
