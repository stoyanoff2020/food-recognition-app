import 'dart:async';
import '../models/subscription.dart';
import 'subscription_service.dart';

enum AdType {
  rewarded,
  interstitial,
  banner,
}

enum AdLoadState {
  loading,
  loaded,
  failed,
  showing,
  closed,
  rewarded,
}

class AdReward {
  final String type;
  final int amount;

  const AdReward({
    required this.type,
    required this.amount,
  });
}

abstract class AdService {
  Future<void> initialize();
  Future<bool> loadRewardedAd();
  Future<bool> showRewardedAd();
  Future<bool> isRewardedAdReady();
  Future<bool> canShowAds();
  Stream<AdLoadState> get adStateStream;
  Stream<AdReward> get rewardStream;
  void dispose();
}

class AdServiceImpl implements AdService {
  final SubscriptionService _subscriptionService;
  final StreamController<AdLoadState> _adStateController = 
      StreamController<AdLoadState>.broadcast();
  final StreamController<AdReward> _rewardController = 
      StreamController<AdReward>.broadcast();
  
  bool _isInitialized = false;
  bool _isRewardedAdLoaded = false;
  AdLoadState _currentState = AdLoadState.loading;

  AdServiceImpl(this._subscriptionService);

  @override
  Stream<AdLoadState> get adStateStream => _adStateController.stream;

  @override
  Stream<AdReward> get rewardStream => _rewardController.stream;

  @override
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // In a real implementation, this would initialize the ad SDK
      // For example: GoogleMobileAds.instance.initialize()
      
      // Simulate initialization delay
      await Future.delayed(const Duration(milliseconds: 500));
      
      _isInitialized = true;
      _updateAdState(AdLoadState.loaded);
      
      // Pre-load a rewarded ad
      await loadRewardedAd();
    } catch (e) {
      _updateAdState(AdLoadState.failed);
      rethrow;
    }
  }

  @override
  Future<bool> loadRewardedAd() async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      _updateAdState(AdLoadState.loading);
      
      // In a real implementation, this would load a rewarded ad
      // For example: RewardedAd.load()
      
      // Simulate ad loading
      await Future.delayed(const Duration(seconds: 2));
      
      // Simulate 90% success rate
      final success = DateTime.now().millisecond % 10 != 0;
      
      if (success) {
        _isRewardedAdLoaded = true;
        _updateAdState(AdLoadState.loaded);
        return true;
      } else {
        _isRewardedAdLoaded = false;
        _updateAdState(AdLoadState.failed);
        return false;
      }
    } catch (e) {
      _isRewardedAdLoaded = false;
      _updateAdState(AdLoadState.failed);
      return false;
    }
  }

  @override
  Future<bool> showRewardedAd() async {
    if (!_isRewardedAdLoaded) {
      // Try to load an ad first
      final loaded = await loadRewardedAd();
      if (!loaded) return false;
    }

    // Check if user can watch ads based on subscription
    final canShow = await canShowAds();
    if (!canShow) return false;

    try {
      _updateAdState(AdLoadState.showing);
      
      // In a real implementation, this would show the rewarded ad
      // For example: rewardedAd.show()
      
      // Simulate ad showing duration
      await Future.delayed(const Duration(seconds: 3));
      
      // Simulate user completing the ad (90% completion rate)
      final completed = DateTime.now().millisecond % 10 != 0;
      
      if (completed) {
        // User watched the ad, give reward
        await _giveReward();
        _updateAdState(AdLoadState.rewarded);
        
        // Mark ad as consumed
        _isRewardedAdLoaded = false;
        
        // Pre-load next ad (don't await to avoid blocking)
        Future.microtask(() => loadRewardedAd());
        
        return true;
      } else {
        // User closed ad early, no reward
        _updateAdState(AdLoadState.closed);
        _isRewardedAdLoaded = false;
        return false;
      }
    } catch (e) {
      _updateAdState(AdLoadState.failed);
      _isRewardedAdLoaded = false;
      return false;
    }
  }

  @override
  Future<bool> isRewardedAdReady() async {
    return _isRewardedAdLoaded && _isInitialized;
  }

  @override
  Future<bool> canShowAds() async {
    final subscription = await _subscriptionService.getCurrentSubscription();
    
    // Ad-free subscribers shouldn't see ads (except when they choose to for rewards)
    // But we still allow rewarded ads for extra scans
    
    // Check if user can perform the watch ad action
    return await _subscriptionService.canPerformAction(ActionType.watchAd);
  }

  Future<void> _giveReward() async {
    try {
      // Track the ad watch in subscription service
      await _subscriptionService.watchAd();
      
      // Emit reward event
      const reward = AdReward(
        type: 'extra_scan',
        amount: 1,
      );
      
      if (!_rewardController.isClosed) {
        _rewardController.add(reward);
      }
    } catch (e) {
      // Handle reward error
      rethrow;
    }
  }

  void _updateAdState(AdLoadState state) {
    _currentState = state;
    if (!_adStateController.isClosed) {
      _adStateController.add(state);
    }
  }

  @override
  void dispose() {
    _adStateController.close();
    _rewardController.close();
  }
}

// Mock implementation for testing
class MockAdService implements AdService {
  final StreamController<AdLoadState> _adStateController = 
      StreamController<AdLoadState>.broadcast();
  final StreamController<AdReward> _rewardController = 
      StreamController<AdReward>.broadcast();
  
  bool _isInitialized = false;
  bool _isRewardedAdLoaded = false;
  bool _shouldFailLoading = false;
  bool _shouldFailShowing = false;

  @override
  Stream<AdLoadState> get adStateStream => _adStateController.stream;

  @override
  Stream<AdReward> get rewardStream => _rewardController.stream;

  // Test helpers
  void setShouldFailLoading(bool shouldFail) {
    _shouldFailLoading = shouldFail;
  }

  void setShouldFailShowing(bool shouldFail) {
    _shouldFailShowing = shouldFail;
  }

  @override
  Future<void> initialize() async {
    await Future.delayed(const Duration(milliseconds: 100));
    _isInitialized = true;
    _adStateController.add(AdLoadState.loaded);
  }

  @override
  Future<bool> loadRewardedAd() async {
    _adStateController.add(AdLoadState.loading);
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (_shouldFailLoading) {
      _adStateController.add(AdLoadState.failed);
      return false;
    }
    
    _isRewardedAdLoaded = true;
    _adStateController.add(AdLoadState.loaded);
    return true;
  }

  @override
  Future<bool> showRewardedAd() async {
    if (!_isRewardedAdLoaded) return false;
    
    _adStateController.add(AdLoadState.showing);
    await Future.delayed(const Duration(milliseconds: 100));
    
    if (_shouldFailShowing) {
      _adStateController.add(AdLoadState.failed);
      return false;
    }
    
    _adStateController.add(AdLoadState.rewarded);
    _rewardController.add(const AdReward(type: 'extra_scan', amount: 1));
    _isRewardedAdLoaded = false;
    return true;
  }

  @override
  Future<bool> isRewardedAdReady() async {
    return _isRewardedAdLoaded && _isInitialized;
  }

  @override
  Future<bool> canShowAds() async {
    return true; // Mock always allows ads
  }

  @override
  void dispose() {
    _adStateController.close();
    _rewardController.close();
  }
}