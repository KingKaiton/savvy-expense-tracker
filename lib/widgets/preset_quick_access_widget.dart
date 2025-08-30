import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/expense_preset_provider.dart';
import '../providers/settings_provider.dart';
import '../models/expense_preset.dart';
import '../screens/add_expense_screen.dart';
import '../screens/preset_management_screen.dart';

class PresetQuickAccessWidget extends StatelessWidget {
  const PresetQuickAccessWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<ExpensePresetProvider, SettingsProvider>(
      builder: (context, presetProvider, settingsProvider, child) {
        if (presetProvider.isLoading) {
          return const SizedBox.shrink();
        }

        final presets = presetProvider.presets.take(4).toList(); // Show max 4 presets

        if (presets.isEmpty) {
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.receipt_long,
                        size: 20,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Quick Expense Presets',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const PresetManagementScreen(),
                            ),
                          );
                        },
                        child: const Text('Manage'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create presets for your frequent expenses to add them quickly.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PresetManagementScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Create First Preset'),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.receipt_long,
                      size: 20,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Quick Expense Presets',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PresetManagementScreen(),
                          ),
                        );
                      },
                      child: const Text('See All'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 80,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: presets.length,
                    itemBuilder: (context, index) {
                      final preset = presets[index];
                      return _buildPresetChip(context, preset, settingsProvider);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPresetChip(BuildContext context, ExpensePreset preset, SettingsProvider settingsProvider) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AddExpenseScreen(preset: preset),
          ),
        );
      },
      child: Container(
        width: 120,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getIconData(preset.icon ?? 'receipt'),
              color: Theme.of(context).colorScheme.primary,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              preset.name,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              '${settingsProvider.currencySymbol}${preset.amount.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName.toLowerCase()) {
      case 'food':
        return Icons.restaurant;
      case 'transport':
        return Icons.directions_car;
      case 'shopping':
        return Icons.shopping_bag;
      case 'entertainment':
        return Icons.movie;
      case 'health':
        return Icons.local_hospital;
      case 'utilities':
        return Icons.home;
      case 'education':
        return Icons.school;
      case 'coffee':
        return Icons.local_cafe;
      case 'gas':
        return Icons.local_gas_station;
      case 'subscription':
        return Icons.subscriptions;
      default:
        return Icons.receipt_long;
    }
  }
}
