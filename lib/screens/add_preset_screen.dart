import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/expense_preset_provider.dart';
import '../providers/settings_provider.dart';
import '../models/expense_preset.dart';

class AddPresetScreen extends StatefulWidget {
  final ExpensePreset? preset;

  const AddPresetScreen({super.key, this.preset});

  @override
  State<AddPresetScreen> createState() => _AddPresetScreenState();
}

class _AddPresetScreenState extends State<AddPresetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  String _selectedCategory = 'Food';
  String _selectedIcon = 'food';
  bool _isLoading = false;

  final List<String> _categories = [
    'Food', 'Transport', 'Shopping', 'Entertainment', 'Health',
    'Utilities', 'Education', 'Other'
  ];

  final List<Map<String, dynamic>> _icons = [
    {'name': 'food', 'icon': Icons.restaurant, 'label': 'Food'},
    {'name': 'transport', 'icon': Icons.directions_car, 'label': 'Transport'},
    {'name': 'shopping', 'icon': Icons.shopping_bag, 'label': 'Shopping'},
    {'name': 'entertainment', 'icon': Icons.movie, 'label': 'Entertainment'},
    {'name': 'health', 'icon': Icons.local_hospital, 'label': 'Health'},
    {'name': 'utilities', 'icon': Icons.home, 'label': 'Utilities'},
    {'name': 'education', 'icon': Icons.school, 'label': 'Education'},
    {'name': 'coffee', 'icon': Icons.local_cafe, 'label': 'Coffee'},
    {'name': 'gas', 'icon': Icons.local_gas_station, 'label': 'Gas'},
    {'name': 'subscription', 'icon': Icons.subscriptions, 'label': 'Subscription'},
    {'name': 'receipt', 'icon': Icons.receipt_long, 'label': 'General'},
  ];

  @override
  void initState() {
    super.initState();
    
    if (widget.preset != null) {
      _nameController.text = widget.preset!.name;
      _amountController.text = widget.preset!.amount.toString();
      _descriptionController.text = widget.preset!.description ?? '';
      _selectedCategory = widget.preset!.category;
      _selectedIcon = widget.preset!.icon ?? 'receipt';
    }
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
    final isEditing = widget.preset != null;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Preset' : 'Create Preset'),
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
              onPressed: _savePreset,
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

              // Name field
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Preset Name',
                  hintText: 'e.g., Morning Coffee',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a preset name';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Amount field
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

              // Category dropdown
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

              // Description field
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  hintText: 'Additional notes about this preset',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),

              const SizedBox(height: 32),

              // Save button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _savePreset,
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
                      : Text(isEditing ? 'Update Preset' : 'Create Preset'),
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

  Future<void> _savePreset() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final preset = ExpensePreset(
        id: widget.preset?.id,
        name: _nameController.text.trim(),
        amount: double.parse(_amountController.text),
        category: _selectedCategory,
        description: _descriptionController.text.trim().isEmpty 
            ? null 
            : _descriptionController.text.trim(),
        icon: _selectedIcon,
      );

      final presetProvider = Provider.of<ExpensePresetProvider>(context, listen: false);

      if (widget.preset != null) {
        // Update existing preset
        await presetProvider.updatePreset(preset);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Updated "${preset.name}"')),
          );
        }
      } else {
        // Create new preset
        await presetProvider.addPreset(preset);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Created "${preset.name}"')),
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
            content: Text('Error saving preset. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
