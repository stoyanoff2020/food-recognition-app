import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/subscription.dart';

abstract class SubscriptionService {
  Future<SubscriptionTier> getCurrentSubscription();
  Future<bool> hasFeatureAccess(FeatureType feature);
  Future<bool> upgradeSubscription(SubscriptionTierType tier);
  Future<bool> cancelSubscription();
  Future<UsageQuota> getUsageQuota();
  Future<void> incrementUsage(UsageType type);
  Future<bool> canPerformAction(ActionType action);
  Future<void> resetDailyQuota();
  Future<List<UsageRecord>> getUsageHistory();
  Future<void> watchAd();
  Future<bool> needsQuotaReset();
  Stream<SubscriptionData> get subscriptionStream;
}

class SubscriptionServiceImpl implements SubscriptionService {
  static const String _subscriptionDataKey = 'subscription_data';
  static const String _lastResetKey = 'last_quota_reset';
  
  final SharedPreferences _prefs;
  final StreamController<SubscriptionData> _subscriptionController = 
      StreamController<SubscriptionData>.broadcast();
  
  SubscriptionData? _cachedData;
  Timer? _quotaResetTimer;

  SubscriptionServiceImpl(this._prefs);

  @override
  Stream<SubscriptionData> get subscriptionStream => _subscriptionController.stream;

  Future<void> initialize() async {
    final data = await _getSubscriptionData();
    _subscriptionController.add(data);
    _startQuotaResetTimer();
  }

  void _startQuotaResetTimer() {
    // Check for quota reset every hour
    _quotaResetTimer = Timer.periodic(const Duration(hours: 1), (_) async {
      if (await needsQuotaReset()) {
        await resetDailyQuota();
      }
    });
  }

  Future<SubscriptionData> _getSubscriptionData() async {
    if (_cachedData != null) return _cachedData!;

    final dataJson = _prefs.getString(_subscriptionDataKey);
    if (dataJson != null) {
      try {
        final data = SubscriptionData.fromJson(jsonDecode(dataJson));
        _cachedData = data;
        return data;
      } catch (e) {
        // If data is corrupted, reset to default
        return await _createDefaultSubscriptionData();
      }
    }

    return await _createDefaultSubscriptionData();
  }

  Future<SubscriptionData> _createDefaultSubscriptionData() async {
    final now = DateTime.now();
    final data = SubscriptionData(
      currentTier: SubscriptionTierType.free,
      usageHistory: [],
      lastQuotaReset: now,
      currentQuota: SubscriptionTier.free.quotas.copyWith(
        resetTime: _getNextResetTime(SubscriptionTierType.free),
      ),
    );
    
    await _saveSubscriptionData(data);
    return data;
  }

  Future<void> _saveSubscriptionData(SubscriptionData data) async {
    _cachedData = data;
    await _prefs.setString(_subscriptionDataKey, jsonEncode(data.toJson()));
    _subscriptionController.add(data);
  }

  DateTime _getNextResetTime(SubscriptionTierType tier) {
    final now = DateTime.now();
    if (tier == SubscriptionTierType.free) {
      // Free tier resets every 6 hours
      return now.add(const Duration(hours: 6));
    } else {
      // Premium and Professional reset daily at midnight
      final tomorrow = DateTime(now.year, now.month, now.day + 1);
      return tomorrow;
    }
  }

  @override
  Future<SubscriptionTier> getCurrentSubscription() async {
    final data = await _getSubscriptionData();
    
    switch (data.currentTier) {
      case SubscriptionTierType.free:
        return SubscriptionTier.free;
      case SubscriptionTierType.premium:
        return SubscriptionTier.premium;
      case SubscriptionTierType.professional:
        return SubscriptionTier.professional;
    }
  }

  @override
  Future<bool> hasFeatureAccess(FeatureType feature) async {
    final subscription = await getCurrentSubscription();
    return subscription.hasFeature(feature);
  }

  @override
  Future<bool> upgradeSubscription(SubscriptionTierType tier) async {
    try {
      // In a real implementation, this would integrate with platform-specific
      // in-app purchase systems (iOS App Store, Google Play)
      final data = await _getSubscriptionData();
      final now = DateTime.now();
      
      final updatedData = data.copyWith(
        currentTier: tier,
        subscriptionId: 'sub_${tier.name}_${now.millisecondsSinceEpoch}',
        purchaseDate: now,
        expiryDate: now.add(const Duration(days: 30)), // Monthly subscription
        currentQuota: _getTierQuota(tier).copyWith(
          resetTime: _getNextResetTime(tier),
          usedScans: 0, // Reset usage on upgrade
        ),
      );
      
      await _saveSubscriptionData(updatedData);
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> cancelSubscription() async {
    try {
      final data = await _getSubscriptionData();
      
      // In a real implementation, this would cancel the platform subscription
      final updatedData = data.copyWith(
        currentTier: SubscriptionTierType.free,
        subscriptionId: null,
        purchaseDate: null,
        expiryDate: null,
        currentQuota: SubscriptionTier.free.quotas.copyWith(
          resetTime: _getNextResetTime(SubscriptionTierType.free),
          usedScans: 0,
        ),
      );
      
      await _saveSubscriptionData(updatedData);
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<UsageQuota> getUsageQuota() async {
    final data = await _getSubscriptionData();
    return data.currentQuota;
  }

  @override
  Future<void> incrementUsage(UsageType type) async {
    final data = await _getSubscriptionData();
    
    int scansUsed = data.currentQuota.usedScans;
    int adsWatched = 0;
    ActionType actionType = ActionType.scanFood;
    
    switch (type) {
      case UsageType.scan:
        scansUsed += 1;
        actionType = ActionType.scanFood;
        break;
      case UsageType.adWatch:
        adsWatched = 1;
        actionType = ActionType.watchAd;
        break;
      case UsageType.recipeSave:
        actionType = ActionType.saveRecipe;
        break;
      case UsageType.mealPlanCreate:
        actionType = ActionType.createMealPlan;
        break;
    }
    
    final usageRecord = UsageRecord(
      date: DateTime.now(),
      scansUsed: type == UsageType.scan ? 1 : 0,
      adsWatched: adsWatched,
      actionType: actionType,
    );
    
    final updatedData = data.copyWith(
      currentQuota: data.currentQuota.copyWith(usedScans: scansUsed),
      usageHistory: [...data.usageHistory, usageRecord],
    );
    
    await _saveSubscriptionData(updatedData);
  }

  @override
  Future<bool> canPerformAction(ActionType action) async {
    final data = await _getSubscriptionData();
    final subscription = await getCurrentSubscription();
    
    switch (action) {
      case ActionType.scanFood:
        // Check if user has scans remaining
        if (data.currentQuota.hasScansRemaining) {
          return true;
        }
        // Check if user can watch ads for more scans
        return data.currentQuota.adWatchesAvailable > 0 && 
               !subscription.hasFeature(FeatureType.adFree);
        
      case ActionType.saveRecipe:
        return subscription.hasFeature(FeatureType.recipeBook);
        
      case ActionType.createMealPlan:
        return subscription.hasFeature(FeatureType.mealPlanning);
        
      case ActionType.watchAd:
        return data.currentQuota.adWatchesAvailable > 0 && 
               !subscription.hasFeature(FeatureType.adFree);
    }
  }

  @override
  Future<void> resetDailyQuota() async {
    final data = await _getSubscriptionData();
    final subscription = await getCurrentSubscription();
    
    final updatedQuota = subscription.quotas.copyWith(
      usedScans: 0,
      resetTime: _getNextResetTime(data.currentTier),
      adWatchesAvailable: subscription.quotas.adWatchesAvailable,
    );
    
    final updatedData = data.copyWith(
      currentQuota: updatedQuota,
      lastQuotaReset: DateTime.now(),
    );
    
    await _saveSubscriptionData(updatedData);
  }

  @override
  Future<List<UsageRecord>> getUsageHistory() async {
    final data = await _getSubscriptionData();
    return data.usageHistory;
  }

  @override
  Future<void> watchAd() async {
    final data = await _getSubscriptionData();
    
    // Add extra scans based on tier
    int extraScans = 1;
    if (data.currentTier == SubscriptionTierType.premium) {
      extraScans = 2;
    }
    
    final updatedQuota = data.currentQuota.copyWith(
      adWatchesAvailable: (data.currentQuota.adWatchesAvailable - 1).clamp(0, 100),
    );
    
    await incrementUsage(UsageType.adWatch);
    
    final updatedData = data.copyWith(
      currentQuota: updatedQuota,
    );
    
    await _saveSubscriptionData(updatedData);
  }

  @override
  Future<bool> needsQuotaReset() async {
    final data = await _getSubscriptionData();
    return data.currentQuota.needsReset;
  }

  UsageQuota _getTierQuota(SubscriptionTierType tier) {
    switch (tier) {
      case SubscriptionTierType.free:
        return SubscriptionTier.free.quotas;
      case SubscriptionTierType.premium:
        return SubscriptionTier.premium.quotas;
      case SubscriptionTierType.professional:
        return SubscriptionTier.professional.quotas;
    }
  }

  void dispose() {
    _quotaResetTimer?.cancel();
    _subscriptionController.close();
  }
}