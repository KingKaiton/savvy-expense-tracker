import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/subscription_provider.dart';
import '../providers/settings_provider.dart';
import '../models/subscription.dart';

class AddSubscriptionScreen extends StatefulWidget {
  final Subscription? subscription;

  const AddSubscriptionScreen({super.key, this.subscription});

  @override
  State<AddSubscriptionScreen> createState() => _AddSubscriptionScreenState();
}

class _AddSubscriptionScreenState extends State<AddSubscriptionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  String _selectedCategory = 'Entertainment';
  String _selectedIcon = 'subscriptions';
  String _selectedBillingCycle = 'monthly';
  DateTime _startDate = DateTime.now();
  DateTime _nextBillingDate = DateTime.now().add(const Duration(days: 30));
  List<String> _selectedReminderDays = ['3', '7'];
  bool _isLoading = false;

  final List<String> _categories = [
    'Entertainment', 'Utilities', 'Health & Fitness', 'Communication', 
    'Software', 'News & Media', 'Food & Delivery', 'Transportation', 'Other'
  ];

  final List<String> _billingCycles = [
    'weekly', 'bi-weekly', 'monthly', 'yearly'
  ];

  final List<Map<String, dynamic>> _icons = [
    {'name': 'subscriptions', 'icon': Icons.subscriptions, 'label': 'General'},
    {'name': 'netflix', 'icon': Icons.movie, 'label': 'Streaming'},
    {'name': 'spotify', 'icon': Icons.music_note, 'label': 'Music'},
    {'name': 'gym', 'icon': Icons.fitness_center, 'label': 'Fitness'},
    {'name': 'phone', 'icon': Icons.phone, 'label': 'Phone'},
    {'name': 'internet', 'icon': Icons.wifi, 'label': 'Internet'},
    {'name': 'cloud', 'icon': Icons.cloud, 'label': 'Cloud'},
    {'name': 'gaming', 'icon': Icons.games, 'label': 'Gaming'},
    {'name': 'news', 'icon': Icons.newspaper, 'label': 'News'},
    {'name': 'food', 'icon': Icons.restaurant, 'label': 'Food'},
  ];

  final List<Map<String, dynamic>> _reminderOptions = [
    {'value': '1', 'label': '1 day before'},
    {'value': '3', 'label': '3 days before'},
    {'value': '7', 'label': '1 week before'},
    {'value': '14', 'label': '2 weeks before'},
  ];

  @override
  void initState() {
    super.initState();
    
    if (widget.subscription != null) {
      final sub = widget.subscription!;
      _nameController.text = sub.name;
      _amountController.text = sub.amount.toString();
      _descriptionController.text = sub.description ?? '';
      _selectedCategory = sub.category;
      _selectedIcon = sub.icon ?? 'subscriptions';
      _selectedBillingCycle = sub.billingCycle;
      _startDate = sub.startDate;
      _nextBillingDate = sub.nextBillingDate;
      _selectedReminderDays = sub.reminderDays?.split(',').map((e) => e.trim()).toList() ?? ['3', '7'];
    } else {
      _updateNextBillingDate();
    }
  }

  void _updateNextBillingDate() {
    switch (_selectedBillingCycle) {
      case 'weekly':
        _nextBillingDate = _startDate.add(const Duration(days: 7));
        break;
      case 'bi-weekly':
        _nextBillingDate = _startDate.add(const Duration(days: 14));
        break;
      case 'monthly':
        _nextBillingDate = DateTime(_startDate.year, _startDate.month + 1, _startDate.day);
        break;
      case 'yearly':
        _nextBillingDate = DateTime(_startDate.year + 1, _startDate.month, _startDate.day);
        break;
    }
    setState(() {});
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.subscription != null;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Subscription' : 'Add Subscription'),
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _saveSubscription,
              child: Text(isEditing ? 'Update' : 'Save'),
            ),
        ],
      ),
      body: Consumer<SettingsProvider>(
        builder: (context, settingsProvider, child) {
          return Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon selection
                  Text(
                    'Icon',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    height: 80,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _icons.length,
                      itemBuilder: (context, index) {
                        final iconData = _icons[index];
                        final isSelected = _selectedIcon == iconData['name'];
                        
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedIcon = iconData['name'];
                            });
                          },
                          child: Container(
                            width: 60,
                            margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              color: isSelected 
                                  ? Theme.of(context).colorScheme.primaryContainer
                                  : Theme.of(context).colorScheme.surfaceVariant,
                              borderRadius: BorderRadius.circular(12),
                              border: isSelected
                                  ? Border.all(
                                      color: Theme.of(context).colorScheme.primary,
                                      width: 2,
                                    )
                                  : null,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  iconData['icon'],
                                  color: isSelected
                                      ? Theme.of(context).colorScheme.onPrimaryContainer
                                      : Theme.of(context).colorScheme.onSurfaceVariant,
                                  size: 24,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  iconData['label'],
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: isSelected
                                        ? Theme.of(context).colorScheme.onPrimaryContainer
                                        : Theme.of(context).colorScheme.onSurfaceVariant,
                                    fontSize: 10,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  
                  const SizedBox(height: 24),

                  // Subscription name
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Subscription Name',
                      hintText: 'e.g., Netflix, Spotify',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a subscription name';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // Amount
                  TextFormField(
                    controller: _amountController,
                    decoration: InputDecoration(
                      labelText: 'Amount',
                      hintText: '0.00',
                      prefixText: '${settingsProvider.currencySymbol} ',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter an amount';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Please enter a valid number';
                      }
                      if (double.parse(value) <= 0) {
                        return 'Amount must be greater than 0';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // Category
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(),
                    ),
                    items: _categories.map((category) {
                      return DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCategory = value!;
                      });
                    },
                  ),

                  const SizedBox(height: 16),

                  // Billing cycle
                  DropdownButtonFormField<String>(
                    value: _selectedBillingCycle,
                    decoration: const InputDecoration(
                      labelText: 'Billing Cycle',
                      border: OutlineInputBorder(),
                    ),
                    items: _billingCycles.map((cycle) {
                      return DropdownMenuItem(
                        value: cycle,
                        child: Text(cycle.replaceFirst(cycle[0], cycle[0].toUpperCase())),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedBillingCycle = value!;
                        _updateNextBillingDate();
                      });
                    },
                  ),

                  const SizedBox(height: 16),

                  // Start date
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Start Date'),
                    subtitle: Text('${_startDate.day}/${_startDate.month}/${_startDate.year}'),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _startDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) {
                        setState(() {
                          _startDate = date;
                          _updateNextBillingDate();
                        });
                      }
                    },
                  ),

                  const Divider(),

                  // Next billing date (calculated)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Next Billing Date'),
                    subtitle: Text('${_nextBillingDate.day}/${_nextBillingDate.month}/${_nextBillingDate.year}'),
                    trailing: const Icon(Icons.event_note),
                  ),

                  const SizedBox(height: 16),

                  // Reminder settings
                  Text(
                    'Reminder Settings',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _reminderOptions.map((option) {
                      final isSelected = _selectedReminderDays.contains(option['value']);
                      return FilterChip(
                        label: Text(option['label']),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedReminderDays.add(option['value']);
                            } else {
                              _selectedReminderDays.remove(option['value']);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 16),

                  // Description
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description (Optional)',
                      hintText: 'Additional notes about this subscription',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),

                  const SizedBox(height: 32),

                  // Save button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveSubscription,
                      child: _isLoading
                          ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                                SizedBox(width: 12),
                                Text('Saving...'),
                              ],
                            )
                          : Text(isEditing ? 'Update Subscription' : 'Add Subscription'),
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

  Future<void> _saveSubscription() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedReminderDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one reminder option'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final subscription = Subscription(
        id: widget.subscription?.id,
        name: _nameController.text.trim(),
        amount: double.parse(_amountController.text),
        category: _selectedCategory,
        startDate: _startDate,
        billingCycle: _selectedBillingCycle,
        nextBillingDate: _nextBillingDate,
        description: _descriptionController.text.trim().isEmpty 
            ? null 
            : _descriptionController.text.trim(),
        icon: _selectedIcon,
        reminderDays: _selectedReminderDays.join(','),
      );

      final subscriptionProvider = Provider.of<SubscriptionProvider>(context, listen: false);

      if (widget.subscription != null) {
        // Update existing subscription
        await subscriptionProvider.updateSubscription(subscription);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Updated "${subscription.name}"')),
          );
        }
      } else {
        // Create new subscription
        await subscriptionProvider.addSubscription(subscription);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Added "${subscription.name}"')),
          );
        }
      }

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error saving subscription. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
