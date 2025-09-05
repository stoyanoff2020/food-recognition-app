import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/app_state.dart';
import '../../models/subscription.dart';
import '../../services/meal_planning_service.dart';
import '../../services/subscription_service.dart';
import '../../widgets/meal_planning/meal_plan_calendar.dart';
import '../../widgets/meal_planning/nutrition_dashboard.dart';
import '../../widgets/meal_planning/meal_plan_list.dart';
import '../../widgets/meal_planning/upgrade_prompt_widget.dart';

class MealPlanningScreen extends StatefulWidget {
  const MealPlanningScreen({super.key});

  @override
  State<MealPlanningScreen> createState() => _MealPlanningScreenState();
}

class _MealPlanningScreenState extends State<MealPlanningScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late MealPlanningServiceInterface _mealPlanningService;
  late SubscriptionService _subscriptionService;
  
  List<MealPlan> _mealPlans = [];
  MealPlan? _selectedMealPlan;
  bool _isLoading = true;
  String? _error;
  bool _hasAccess = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeServices();
    _checkAccess();
  }

  void _initializeServices() {
    // In a real app, these would be injected via dependency injection
    try {
      final storageService = context.read<StorageServiceInterface>();
      final subscriptionService = context.read<SubscriptionService>();
      
      _mealPlanningService = MealPlanningServiceFactory.create(
        storageService: storageService,
        subscriptionService: subscriptionService,
      );
      _subscriptionService = subscriptionService;
    } catch (e) {
      // Fallback for testing or when services are not available
      debugPrint('Error initializing services: $e');
    }
  }

  Future<void> _checkAccess() async {
    try {
      final hasAccess = await _mealPlanningService.hasMealPlanningAccess();
      setState(() {
        _hasAccess = hasAccess;
      });
      
      if (hasAccess) {
        await _loadMealPlans();
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to check meal planning access: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMealPlans() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final mealPlans = await _mealPlanningService.getMealPlans();
      setState(() {
        _mealPlans = mealPlans;
        _selectedMealPlan = mealPlans.isNotEmpty ? mealPlans.first : null;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load meal plans: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _createMealPlan() async {
    if (!_hasAccess) return;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _CreateMealPlanDialog(),
    );

    if (result != null) {
      try {
        setState(() {
          _isLoading = true;
        });

        final mealPlan = await _mealPlanningService.createMealPlan(
          result['name'] as String,
          result['startDate'] as String,
          result['type'] as MealPlanType,
        );

        setState(() {
          _mealPlans.insert(0, mealPlan);
          _selectedMealPlan = mealPlan;
          _isLoading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Meal plan "${mealPlan.name}" created successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        setState(() {
          _error = 'Failed to create meal plan: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteMealPlan(MealPlan mealPlan) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Meal Plan'),
        content: Text('Are you sure you want to delete "${mealPlan.name}"?'),
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

    if (confirmed == true) {
      try {
        await _mealPlanningService.deleteMealPlan(mealPlan.id);
        setState(() {
          _mealPlans.removeWhere((plan) => plan.id == mealPlan.id);
          if (_selectedMealPlan?.id == mealPlan.id) {
            _selectedMealPlan = _mealPlans.isNotEmpty ? _mealPlans.first : null;
          }
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Meal plan "${mealPlan.name}" deleted'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete meal plan: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasAccess) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Meal Planning'),
        ),
        body: const MealPlanningUpgradePrompt(),
      );
    }

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Meal Planning'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Meal Planning'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red[300],
              ),
              const SizedBox(height: 16),
              Text(
                'Error',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _checkAccess,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meal Planning'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.calendar_month), text: 'Calendar'),
            Tab(icon: Icon(Icons.analytics), text: 'Nutrition'),
            Tab(icon: Icon(Icons.list), text: 'Plans'),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _createMealPlan,
            icon: const Icon(Icons.add),
            tooltip: 'Create Meal Plan',
          ),
        ],
      ),
      body: _mealPlans.isEmpty
          ? _buildEmptyState()
          : TabBarView(
              controller: _tabController,
              children: [
                MealPlanCalendar(
                  mealPlan: _selectedMealPlan,
                  onMealPlanChanged: (mealPlan) {
                    setState(() {
                      _selectedMealPlan = mealPlan;
                    });
                  },
                  mealPlans: _mealPlans,
                ),
                NutritionDashboard(
                  mealPlan: _selectedMealPlan,
                ),
                MealPlanList(
                  mealPlans: _mealPlans,
                  selectedMealPlan: _selectedMealPlan,
                  onMealPlanSelected: (mealPlan) {
                    setState(() {
                      _selectedMealPlan = mealPlan;
                    });
                  },
                  onMealPlanDeleted: _deleteMealPlan,
                ),
              ],
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.restaurant_menu,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Meal Plans',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first meal plan to get started',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _createMealPlan,
            icon: const Icon(Icons.add),
            label: const Text('Create Meal Plan'),
          ),
        ],
      ),
    );
  }
}

class _CreateMealPlanDialog extends StatefulWidget {
  @override
  State<_CreateMealPlanDialog> createState() => _CreateMealPlanDialogState();
}

class _CreateMealPlanDialogState extends State<_CreateMealPlanDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  DateTime _startDate = DateTime.now();
  MealPlanType _type = MealPlanType.weekly;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Meal Plan'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Plan Name',
                hintText: 'e.g., Weekly Meal Plan',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a plan name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Start Date'),
              subtitle: Text(
                '${_startDate.day}/${_startDate.month}/${_startDate.year}',
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _startDate,
                  firstDate: DateTime.now().subtract(const Duration(days: 30)),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null) {
                  setState(() {
                    _startDate = date;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<MealPlanType>(
              value: _type,
              decoration: const InputDecoration(
                labelText: 'Plan Type',
              ),
              items: MealPlanType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(_getMealPlanTypeLabel(type)),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _type = value;
                  });
                }
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.of(context).pop({
                'name': _nameController.text.trim(),
                'startDate': _startDate.toIso8601String().split('T')[0],
                'type': _type,
              });
            }
          },
          child: const Text('Create'),
        ),
      ],
    );
  }

  String _getMealPlanTypeLabel(MealPlanType type) {
    switch (type) {
      case MealPlanType.weekly:
        return 'Weekly (7 days)';
      case MealPlanType.monthly:
        return 'Monthly';
      case MealPlanType.custom:
        return 'Custom';
    }
  }
}