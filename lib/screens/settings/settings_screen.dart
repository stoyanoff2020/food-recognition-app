import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_router.dart';
import '../../services/onboarding_service.dart';
import '../../services/storage_service.dart';
import '../../services/subscription_service.dart';
import '../../models/subscription.dart';
import '../../providers/app_state_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final OnboardingService _onboardingService;
  late final StorageServiceInterface _storageService;
  late final SubscriptionService _subscriptionService;
  
  SubscriptionTier? _currentSubscription;
  UsageQuota? _currentQuota;
  bool _isLoading = true;
  
  // App preferences
  bool _notificationsEnabled = true;
  bool _cameraPermissionGranted = false;
  String _selectedTheme = 'System';
  List<String> _dietaryRestrictions = [];
  
  @override
  void initState() {
    super.initState();
    _onboardingService = OnboardingServiceFactory.create();
    _storageService = StorageServiceFactory.create();
    _subscriptionService = context.read<SubscriptionService>();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final subscription = await _subscriptionService.getCurrentSubscription();
      final quota = await _subscriptionService.getUsageQuota();
      final preferences = await _storageService.getUserPreferencesMap();
      
      setState(() {
        _currentSubscription = subscription;
        _currentQuota = quota;
        _notificationsEnabled = preferences['notifications'] ?? true;
        _cameraPermissionGranted = preferences['cameraPermission'] ?? false;
        _selectedTheme = preferences['theme'] ?? 'System';
        _dietaryRestrictions = List<String>.from(preferences['dietaryRestrictions'] ?? []);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _savePreference(String key, dynamic value) async {
    try {
      await _storageService.saveUserPreference(key, value);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save preference: $e')),
        );
      }
    }
  }

  Future<void> _replayOnboarding() async {
    try {
      await _onboardingService.resetOnboarding();
      if (mounted) {
        final appStateProvider = context.read<AppStateProvider>();
        appStateProvider.resetOnboarding();
        context.goToOnboarding();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to reset onboarding: $e')),
        );
      }
    }
  }

  Future<void> _clearAppData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear App Data'),
        content: const Text(
          'This will delete all your saved preferences, history, and cached data. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear Data'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _storageService.clearAllData();
        await _onboardingService.resetOnboarding();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('App data cleared successfully')),
          );
          context.goToOnboarding();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to clear data: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Subscription Section
          _buildSectionHeader('Subscription'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(
                    Icons.star,
                    color: _getSubscriptionColor(),
                  ),
                  title: Text(_currentSubscription?.displayName ?? 'Free'),
                  subtitle: Text(_getSubscriptionSubtitle()),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.goToSubscription(),
                ),
                if (_currentQuota != null) ...[
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: _buildUsageIndicator(),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),

          // App Preferences Section
          _buildSectionHeader('App Preferences'),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.notifications),
                  title: const Text('Notifications'),
                  subtitle: const Text('Receive app notifications'),
                  value: _notificationsEnabled,
                  onChanged: (value) {
                    setState(() {
                      _notificationsEnabled = value;
                    });
                    _savePreference('notifications', value);
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.palette),
                  title: const Text('Theme'),
                  subtitle: Text(_selectedTheme),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showThemeSelector(),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.restaurant),
                  title: const Text('Dietary Restrictions'),
                  subtitle: Text(_dietaryRestrictions.isEmpty 
                    ? 'None selected' 
                    : _dietaryRestrictions.join(', ')),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showDietaryRestrictionsDialog(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Privacy & Data Section
          _buildSectionHeader('Privacy & Data'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('Camera Permission'),
                  subtitle: Text(_cameraPermissionGranted 
                    ? 'Granted' 
                    : 'Not granted'),
                  trailing: Icon(
                    _cameraPermissionGranted 
                      ? Icons.check_circle 
                      : Icons.error,
                    color: _cameraPermissionGranted 
                      ? Colors.green 
                      : Colors.orange,
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.history),
                  title: const Text('Usage History'),
                  subtitle: const Text('View your app usage data'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showUsageHistory(),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.delete_sweep),
                  title: const Text('Clear App Data'),
                  subtitle: const Text('Delete all saved data'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _clearAppData,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Help & Support Section
          _buildSectionHeader('Help & Support'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.replay),
                  title: const Text('Replay Onboarding'),
                  subtitle: const Text('Go through the app tutorial again'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _replayOnboarding,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.help),
                  title: const Text('Help & FAQ'),
                  subtitle: const Text('Get help and find answers'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showHelpDialog(),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.feedback),
                  title: const Text('Send Feedback'),
                  subtitle: const Text('Help us improve the app'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showFeedbackDialog(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // About Section
          _buildSectionHeader('About'),
          Card(
            child: Column(
              children: [
                const ListTile(
                  leading: Icon(Icons.info),
                  title: Text('App Version'),
                  subtitle: Text('1.0.0'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.description),
                  title: const Text('Terms of Service'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showTermsDialog(),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.privacy_tip),
                  title: const Text('Privacy Policy'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showPrivacyDialog(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _getSubscriptionColor() {
    switch (_currentSubscription?.type) {
      case SubscriptionTierType.premium:
        return Colors.amber;
      case SubscriptionTierType.professional:
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _getSubscriptionSubtitle() {
    if (_currentSubscription == null) return 'Loading...';
    
    final tier = _currentSubscription!;
    if (tier.type == SubscriptionTierType.free) {
      return 'Upgrade for more features';
    }
    
    return tier.description;
  }

  Widget _buildUsageIndicator() {
    if (_currentQuota == null) return const SizedBox.shrink();
    
    final quota = _currentQuota!;
    final isUnlimited = quota.dailyScans == -1;
    
    if (isUnlimited) {
      return const Row(
        children: [
          Icon(Icons.all_inclusive, color: Colors.green),
          SizedBox(width: 8),
          Text('Unlimited scans'),
        ],
      );
    }
    
    final remaining = quota.scansRemaining;
    final total = quota.dailyScans;
    final progress = quota.usedScans / total;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Daily Scans'),
            Text('$remaining/$total remaining'),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(
            remaining > 0 ? Colors.green : Colors.red,
          ),
        ),
        if (quota.resetTime != null) ...[
          const SizedBox(height: 4),
          Text(
            'Resets at ${_formatTime(quota.resetTime!)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ],
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = time.difference(now);
    
    if (difference.inHours > 0) {
      return '${difference.inHours}h ${difference.inMinutes % 60}m';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'Soon';
    }
  }

  void _showThemeSelector() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('System'),
              value: 'System',
              groupValue: _selectedTheme,
              onChanged: (value) {
                setState(() {
                  _selectedTheme = value!;
                });
                _savePreference('theme', value);
                Navigator.of(context).pop();
              },
            ),
            RadioListTile<String>(
              title: const Text('Light'),
              value: 'Light',
              groupValue: _selectedTheme,
              onChanged: (value) {
                setState(() {
                  _selectedTheme = value!;
                });
                _savePreference('theme', value);
                Navigator.of(context).pop();
              },
            ),
            RadioListTile<String>(
              title: const Text('Dark'),
              value: 'Dark',
              groupValue: _selectedTheme,
              onChanged: (value) {
                setState(() {
                  _selectedTheme = value!;
                });
                _savePreference('theme', value);
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDietaryRestrictionsDialog() {
    final availableRestrictions = [
      'Vegetarian',
      'Vegan',
      'Gluten-Free',
      'Dairy-Free',
      'Nut-Free',
      'Keto',
      'Paleo',
      'Low-Carb',
      'Low-Fat',
      'Halal',
      'Kosher',
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Dietary Restrictions'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: availableRestrictions.map((restriction) {
              return CheckboxListTile(
                title: Text(restriction),
                value: _dietaryRestrictions.contains(restriction),
                onChanged: (checked) {
                  setState(() {
                    if (checked == true) {
                      _dietaryRestrictions.add(restriction);
                    } else {
                      _dietaryRestrictions.remove(restriction);
                    }
                  });
                  _savePreference('dietaryRestrictions', _dietaryRestrictions);
                },
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _showUsageHistory() async {
    try {
      final history = await _subscriptionService.getUsageHistory();
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Usage History'),
            content: SizedBox(
              width: double.maxFinite,
              height: 300,
              child: history.isEmpty
                ? const Center(child: Text('No usage history available'))
                : ListView.builder(
                    itemCount: history.length,
                    itemBuilder: (context, index) {
                      final record = history[index];
                      return ListTile(
                        title: Text(_getActionDescription(record.actionType)),
                        subtitle: Text(_formatDate(record.date)),
                        trailing: record.scansUsed > 0 
                          ? Text('${record.scansUsed} scans')
                          : null,
                      );
                    },
                  ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load usage history: $e')),
        );
      }
    }
  }

  String _getActionDescription(ActionType action) {
    switch (action) {
      case ActionType.scanFood:
        return 'Food Scan';
      case ActionType.saveRecipe:
        return 'Recipe Saved';
      case ActionType.createMealPlan:
        return 'Meal Plan Created';
      case ActionType.watchAd:
        return 'Ad Watched';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Today ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Help & FAQ'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'How to use the app:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('1. Take a photo of food items'),
              Text('2. Wait for AI to identify ingredients'),
              Text('3. Browse recipe suggestions'),
              Text('4. Add custom ingredients if needed'),
              SizedBox(height: 16),
              Text(
                'Subscription Benefits:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Premium: More scans, recipe book, ad-free'),
              Text('• Professional: Unlimited scans, meal planning'),
              SizedBox(height: 16),
              Text(
                'Need more help?',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('Contact us at support@foodrecognition.app'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showFeedbackDialog() {
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send Feedback'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Help us improve the app by sharing your feedback:'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Enter your feedback here...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // In a real app, this would send feedback to a server
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Thank you for your feedback!')),
              );
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  void _showTermsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terms of Service'),
        content: const SingleChildScrollView(
          child: Text(
            'Terms of Service\n\n'
            '1. Acceptance of Terms\n'
            'By using this app, you agree to these terms.\n\n'
            '2. Use of Service\n'
            'You may use this app for personal, non-commercial purposes.\n\n'
            '3. Privacy\n'
            'We respect your privacy and handle data according to our Privacy Policy.\n\n'
            '4. Subscriptions\n'
            'Subscription fees are charged according to your selected plan.\n\n'
            '5. Limitation of Liability\n'
            'The app is provided "as is" without warranties.\n\n'
            'For complete terms, visit our website.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: const SingleChildScrollView(
          child: Text(
            'Privacy Policy\n\n'
            '1. Information We Collect\n'
            'We collect photos you take for food recognition and usage data.\n\n'
            '2. How We Use Information\n'
            'Photos are processed by AI services and not stored permanently.\n\n'
            '3. Data Security\n'
            'We use encryption and secure connections to protect your data.\n\n'
            '4. Data Retention\n'
            'Photos are deleted after processing. Usage data is kept for analytics.\n\n'
            '5. Your Rights\n'
            'You can delete your data anytime through app settings.\n\n'
            'For complete privacy policy, visit our website.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}