import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/subscription_service.dart';
import '../../models/subscription.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  late final SubscriptionService _subscriptionService;
  
  SubscriptionTier? _currentSubscription;
  UsageQuota? _currentQuota;
  bool _isLoading = true;
  bool _isUpgrading = false;
  
  final List<SubscriptionTier> _availableTiers = [
    SubscriptionTier.free,
    SubscriptionTier.premium,
    SubscriptionTier.professional,
  ];

  @override
  void initState() {
    super.initState();
    _subscriptionService = context.read<SubscriptionService>();
    _loadSubscriptionData();
  }

  Future<void> _loadSubscriptionData() async {
    try {
      final subscription = await _subscriptionService.getCurrentSubscription();
      final quota = await _subscriptionService.getUsageQuota();
      
      setState(() {
        _currentSubscription = subscription;
        _currentQuota = quota;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load subscription data: $e')),
        );
      }
    }
  }

  Future<void> _upgradeSubscription(SubscriptionTierType tier) async {
    setState(() {
      _isUpgrading = true;
    });

    try {
      final success = await _subscriptionService.upgradeSubscription(tier);
      
      if (success) {
        await _loadSubscriptionData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Successfully upgraded to ${tier.name.toUpperCase()}!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Upgrade failed. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upgrade error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isUpgrading = false;
      });
    }
  }

  Future<void> _cancelSubscription() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Subscription'),
        content: const Text(
          'Are you sure you want to cancel your subscription? '
          'You will lose access to premium features at the end of your billing period.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep Subscription'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Cancel Subscription'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _isUpgrading = true;
      });

      try {
        final success = await _subscriptionService.cancelSubscription();
        
        if (success) {
          await _loadSubscriptionData();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Subscription cancelled successfully'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to cancel subscription'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Cancellation error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        setState(() {
          _isUpgrading = false;
        });
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
        title: const Text('Subscription'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current Subscription Status
            _buildCurrentSubscriptionCard(),
            const SizedBox(height: 24),

            // Usage Overview
            if (_currentQuota != null) ...[
              _buildUsageOverviewCard(),
              const SizedBox(height: 24),
            ],

            // Available Plans
            Text(
              'Available Plans',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            ..._availableTiers.map((tier) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildSubscriptionTierCard(tier),
            )),

            const SizedBox(height: 24),

            // Features Comparison
            _buildFeaturesComparisonCard(),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentSubscriptionCard() {
    if (_currentSubscription == null) return const SizedBox.shrink();

    final tier = _currentSubscription!;
    final isActive = tier.type != SubscriptionTierType.free;

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.star,
                  color: _getTierColor(tier.type),
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current Plan',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        tier.displayName,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: _getTierColor(tier.type),
                        ),
                      ),
                    ],
                  ),
                ),
                if (isActive)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'ACTIVE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              tier.description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (isActive) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isUpgrading ? null : _cancelSubscription,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                      ),
                      child: _isUpgrading
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Cancel Subscription'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildUsageOverviewCard() {
    if (_currentQuota == null) return const SizedBox.shrink();

    final quota = _currentQuota!;
    final isUnlimited = quota.dailyScans == -1;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Usage Overview',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            if (isUnlimited) ...[
              Row(
                children: [
                  const Icon(Icons.all_inclusive, color: Colors.green, size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Unlimited Scans',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Scan as many items as you want',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ] else ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Daily Scans',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  Text(
                    '${quota.scansRemaining}/${quota.dailyScans} remaining',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: quota.scansRemaining > 0 ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: quota.usedScans / quota.dailyScans,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(
                  quota.scansRemaining > 0 ? Colors.green : Colors.red,
                ),
              ),
              if (quota.resetTime != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Resets in ${_formatTimeRemaining(quota.resetTime!)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ],

            if (quota.adWatchesAvailable > 0) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.play_circle_outline, color: Colors.blue),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Watch Ads for More Scans',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        Text(
                          '${quota.adWatchesAvailable} ads available',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => _watchAd(),
                    child: const Text('Watch Ad'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSubscriptionTierCard(SubscriptionTier tier) {
    final isCurrentTier = _currentSubscription?.type == tier.type;
    final canUpgrade = _currentSubscription != null && 
                      tier.type.index > _currentSubscription!.type.index;

    return Card(
      elevation: isCurrentTier ? 4 : 1,
      color: isCurrentTier ? Theme.of(context).colorScheme.primaryContainer : null,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.star,
                  color: _getTierColor(tier.type),
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tier.displayName,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: _getTierColor(tier.type),
                        ),
                      ),
                      if (tier.price > 0)
                        Text(
                          '\$${tier.price.toStringAsFixed(2)}/${tier.billingPeriod}',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                ),
                if (isCurrentTier)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getTierColor(tier.type),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'CURRENT',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              tier.description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            
            // Features list
            ...tier.features.map((feature) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: _getTierColor(tier.type),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(_getFeatureDescription(feature)),
                  ),
                ],
              ),
            )),

            // Quota information
            if (tier.quotas.dailyScans != -1) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.camera_alt,
                    color: _getTierColor(tier.type),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text('${tier.quotas.dailyScans} scans per day'),
                ],
              ),
            ] else ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.all_inclusive,
                    color: _getTierColor(tier.type),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Text('Unlimited scans'),
                ],
              ),
            ],

            if (canUpgrade) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isUpgrading 
                    ? null 
                    : () => _upgradeSubscription(tier.type),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _getTierColor(tier.type),
                    foregroundColor: Colors.white,
                  ),
                  child: _isUpgrading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text('Upgrade to ${tier.displayName}'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturesComparisonCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Feature Comparison',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            Table(
              columnWidths: const {
                0: FlexColumnWidth(2),
                1: FlexColumnWidth(1),
                2: FlexColumnWidth(1),
                3: FlexColumnWidth(1),
              },
              children: [
                // Header
                TableRow(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                  ),
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text(
                        'Feature',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        'Free',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _getTierColor(SubscriptionTierType.free),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        'Premium',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _getTierColor(SubscriptionTierType.premium),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        'Pro',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _getTierColor(SubscriptionTierType.professional),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
                
                // Features
                _buildFeatureRow('Daily Scans', '1 per 6h', '5 per day', 'Unlimited'),
                _buildFeatureRow('Recipe Book', '✗', '✓', '✓'),
                _buildFeatureRow('Meal Planning', '✗', '✗', '✓'),
                _buildFeatureRow('Ad-Free Experience', '✗', '✓', '✓'),
                _buildFeatureRow('Priority Support', '✗', '✗', '✓'),
                _buildFeatureRow('History Storage', '7 days', '30 days', 'Unlimited'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  TableRow _buildFeatureRow(String feature, String free, String premium, String pro) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(feature),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            free,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: free == '✗' ? Colors.red : Colors.black,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            premium,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: premium == '✗' ? Colors.red : Colors.green,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            pro,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: pro == '✗' ? Colors.red : Colors.green,
            ),
          ),
        ),
      ],
    );
  }

  Color _getTierColor(SubscriptionTierType type) {
    switch (type) {
      case SubscriptionTierType.free:
        return Colors.grey;
      case SubscriptionTierType.premium:
        return Colors.amber;
      case SubscriptionTierType.professional:
        return Colors.purple;
    }
  }

  String _getFeatureDescription(FeatureType feature) {
    switch (feature) {
      case FeatureType.recipeBook:
        return 'Save and organize favorite recipes';
      case FeatureType.mealPlanning:
        return 'Plan meals and track nutrition';
      case FeatureType.unlimitedScans:
        return 'Unlimited food recognition scans';
      case FeatureType.adFree:
        return 'Ad-free experience';
      case FeatureType.priorityProcessing:
        return 'Faster processing and priority support';
    }
  }

  String _formatTimeRemaining(DateTime resetTime) {
    final now = DateTime.now();
    final difference = resetTime.difference(now);
    
    if (difference.inHours > 0) {
      return '${difference.inHours}h ${difference.inMinutes % 60}m';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'soon';
    }
  }

  Future<void> _watchAd() async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading ad...'),
          ],
        ),
      ),
    );

    // Simulate ad watching
    await Future.delayed(const Duration(seconds: 2));
    
    if (mounted) {
      Navigator.of(context).pop(); // Close loading dialog
      
      try {
        await _subscriptionService.watchAd();
        await _loadSubscriptionData();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Thanks for watching! You earned extra scans.'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to process ad reward: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}