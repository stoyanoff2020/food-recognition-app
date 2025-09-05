enum SubscriptionTierType {
  free,
  premium,
  professional,
}

enum FeatureType {
  recipeBook,
  mealPlanning,
  unlimitedScans,
  adFree,
  priorityProcessing,
}

enum ActionType {
  scanFood,
  saveRecipe,
  createMealPlan,
  watchAd,
}

enum UsageType {
  scan,
  adWatch,
  recipeSave,
  mealPlanCreate,
}

class SubscriptionTier {
  final SubscriptionTierType type;
  final List<FeatureType> features;
  final UsageQuota quotas;
  final double price;
  final String billingPeriod;
  final String displayName;
  final String description;

  const SubscriptionTier({
    required this.type,
    required this.features,
    required this.quotas,
    required this.price,
    required this.billingPeriod,
    required this.displayName,
    required this.description,
  });

  factory SubscriptionTier.fromJson(Map<String, dynamic> json) {
    return SubscriptionTier(
      type: SubscriptionTierType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
      ),
      features: (json['features'] as List<dynamic>)
          .map((f) => FeatureType.values.firstWhere(
                (e) => e.toString().split('.').last == f,
              ))
          .toList(),
      quotas: UsageQuota.fromJson(json['quotas']),
      price: json['price']?.toDouble() ?? 0.0,
      billingPeriod: json['billingPeriod'] ?? 'monthly',
      displayName: json['displayName'] ?? '',
      description: json['description'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.toString().split('.').last,
      'features': features.map((f) => f.toString().split('.').last).toList(),
      'quotas': quotas.toJson(),
      'price': price,
      'billingPeriod': billingPeriod,
      'displayName': displayName,
      'description': description,
    };
  }

  bool hasFeature(FeatureType feature) {
    return features.contains(feature);
  }

  static const SubscriptionTier free = SubscriptionTier(
    type: SubscriptionTierType.free,
    features: [],
    quotas: UsageQuota(
      dailyScans: 1,
      usedScans: 0,
      adWatchesAvailable: 3,
      historyDays: 7,
      resetTime: null,
    ),
    price: 0.0,
    billingPeriod: 'free',
    displayName: 'Free',
    description: '1 scan per 6 hours, watch ads for more',
  );

  static const SubscriptionTier premium = SubscriptionTier(
    type: SubscriptionTierType.premium,
    features: [
      FeatureType.recipeBook,
      FeatureType.adFree,
    ],
    quotas: UsageQuota(
      dailyScans: 5,
      usedScans: 0,
      adWatchesAvailable: 10,
      historyDays: 30,
      resetTime: null,
    ),
    price: 4.99,
    billingPeriod: 'monthly',
    displayName: 'Premium',
    description: '5 scans per day, recipe book, ad-free',
  );

  static const SubscriptionTier professional = SubscriptionTier(
    type: SubscriptionTierType.professional,
    features: [
      FeatureType.recipeBook,
      FeatureType.mealPlanning,
      FeatureType.unlimitedScans,
      FeatureType.adFree,
      FeatureType.priorityProcessing,
    ],
    quotas: UsageQuota(
      dailyScans: -1, // -1 means unlimited
      usedScans: 0,
      adWatchesAvailable: 0, // No ads needed
      historyDays: -1, // Unlimited
      resetTime: null,
    ),
    price: 9.99,
    billingPeriod: 'monthly',
    displayName: 'Professional',
    description: 'Unlimited scans, meal planning, priority support',
  );
}

class UsageQuota {
  final int dailyScans;
  final int usedScans;
  final DateTime? resetTime;
  final int adWatchesAvailable;
  final int historyDays;

  const UsageQuota({
    required this.dailyScans,
    required this.usedScans,
    required this.adWatchesAvailable,
    required this.historyDays,
    this.resetTime,
  });

  factory UsageQuota.fromJson(Map<String, dynamic> json) {
    return UsageQuota(
      dailyScans: json['dailyScans'] ?? 0,
      usedScans: json['usedScans'] ?? 0,
      adWatchesAvailable: json['adWatchesAvailable'] ?? 0,
      historyDays: json['historyDays'] ?? 0,
      resetTime: json['resetTime'] != null
          ? DateTime.parse(json['resetTime'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dailyScans': dailyScans,
      'usedScans': usedScans,
      'adWatchesAvailable': adWatchesAvailable,
      'historyDays': historyDays,
      'resetTime': resetTime?.toIso8601String(),
    };
  }

  UsageQuota copyWith({
    int? dailyScans,
    int? usedScans,
    DateTime? resetTime,
    int? adWatchesAvailable,
    int? historyDays,
  }) {
    return UsageQuota(
      dailyScans: dailyScans ?? this.dailyScans,
      usedScans: usedScans ?? this.usedScans,
      resetTime: resetTime ?? this.resetTime,
      adWatchesAvailable: adWatchesAvailable ?? this.adWatchesAvailable,
      historyDays: historyDays ?? this.historyDays,
    );
  }

  bool get hasScansRemaining {
    if (dailyScans == -1) return true; // Unlimited
    return usedScans < dailyScans;
  }

  bool get needsReset {
    if (resetTime == null) return false;
    return DateTime.now().isAfter(resetTime!);
  }

  int get scansRemaining {
    if (dailyScans == -1) return -1; // Unlimited
    return (dailyScans - usedScans).clamp(0, dailyScans);
  }
}

class UsageRecord {
  final DateTime date;
  final int scansUsed;
  final int adsWatched;
  final ActionType actionType;

  const UsageRecord({
    required this.date,
    required this.scansUsed,
    required this.adsWatched,
    required this.actionType,
  });

  factory UsageRecord.fromJson(Map<String, dynamic> json) {
    return UsageRecord(
      date: DateTime.parse(json['date']),
      scansUsed: json['scansUsed'] ?? 0,
      adsWatched: json['adsWatched'] ?? 0,
      actionType: ActionType.values.firstWhere(
        (e) => e.toString().split('.').last == json['actionType'],
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'scansUsed': scansUsed,
      'adsWatched': adsWatched,
      'actionType': actionType.toString().split('.').last,
    };
  }
}

class SubscriptionData {
  final SubscriptionTierType currentTier;
  final String? subscriptionId;
  final DateTime? purchaseDate;
  final DateTime? expiryDate;
  final List<UsageRecord> usageHistory;
  final DateTime lastQuotaReset;
  final UsageQuota currentQuota;

  const SubscriptionData({
    required this.currentTier,
    this.subscriptionId,
    this.purchaseDate,
    this.expiryDate,
    required this.usageHistory,
    required this.lastQuotaReset,
    required this.currentQuota,
  });

  factory SubscriptionData.fromJson(Map<String, dynamic> json) {
    return SubscriptionData(
      currentTier: SubscriptionTierType.values.firstWhere(
        (e) => e.toString().split('.').last == json['currentTier'],
      ),
      subscriptionId: json['subscriptionId'],
      purchaseDate: json['purchaseDate'] != null
          ? DateTime.parse(json['purchaseDate'])
          : null,
      expiryDate: json['expiryDate'] != null
          ? DateTime.parse(json['expiryDate'])
          : null,
      usageHistory: (json['usageHistory'] as List<dynamic>? ?? [])
          .map((record) => UsageRecord.fromJson(record))
          .toList(),
      lastQuotaReset: DateTime.parse(json['lastQuotaReset']),
      currentQuota: UsageQuota.fromJson(json['currentQuota']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'currentTier': currentTier.toString().split('.').last,
      'subscriptionId': subscriptionId,
      'purchaseDate': purchaseDate?.toIso8601String(),
      'expiryDate': expiryDate?.toIso8601String(),
      'usageHistory': usageHistory.map((record) => record.toJson()).toList(),
      'lastQuotaReset': lastQuotaReset.toIso8601String(),
      'currentQuota': currentQuota.toJson(),
    };
  }

  SubscriptionData copyWith({
    SubscriptionTierType? currentTier,
    String? subscriptionId,
    DateTime? purchaseDate,
    DateTime? expiryDate,
    List<UsageRecord>? usageHistory,
    DateTime? lastQuotaReset,
    UsageQuota? currentQuota,
  }) {
    return SubscriptionData(
      currentTier: currentTier ?? this.currentTier,
      subscriptionId: subscriptionId ?? this.subscriptionId,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      expiryDate: expiryDate ?? this.expiryDate,
      usageHistory: usageHistory ?? this.usageHistory,
      lastQuotaReset: lastQuotaReset ?? this.lastQuotaReset,
      currentQuota: currentQuota ?? this.currentQuota,
    );
  }

  bool get isExpired {
    if (expiryDate == null) return false;
    return DateTime.now().isAfter(expiryDate!);
  }

  bool get isActive {
    return !isExpired && subscriptionId != null;
  }
}