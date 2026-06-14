import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// RevenueCat entitlement identifier — must match your RevenueCat dashboard.
/// ─────────────────────────────────────────────────────────────────────────────
class RCConfig {
  /// RevenueCat Android API key (test key — swap for prod before release).
  static const String androidApiKey = 'goog_FWqbrJpdtdoYPhClYIEqImlcBkH';

  /// Entitlement ID configured on the RevenueCat dashboard.
  static const String entitlement = 'MobTeam Pro';

  /// Offering identifier (use 'default' unless you created a custom one).
  static const String offering = 'New Offer 2';
}

/// ─────────────────────────────────────────────────────────────────────────────
/// RevenueCat-based subscription service.
///
/// Replaces the previous `in_app_purchase` / Google Play Billing
/// implementation. RevenueCat handles receipt validation, entitlement
/// management and cross-platform normalisation.
///
/// Usage:
///   await SubscriptionService().init(userId: uid);
///   final isPro = await SubscriptionService().isProEntitled();
/// ─────────────────────────────────────────────────────────────────────────────
class SubscriptionService {
  static final SubscriptionService _instance = SubscriptionService._();
  factory SubscriptionService() => _instance;
  SubscriptionService._();

  bool _initialized = false;

  // ── Init ─────────────────────────────────────────────────────────────────────

  /// Configure and start the RevenueCat SDK.
  /// Call once after Firebase auth confirms a logged-in user.
  /// [userId] should be the Firebase UID so receipts are tied to the account.
  Future<void> init({required String userId}) async {
    if (_initialized) {
      // If already initialized, just identify the (possibly new) user.
      try {
        await Purchases.logIn(userId);
      } catch (e) {
        debugPrint('SubscriptionService.logIn error: $e');
      }
      return;
    }

    try {
      await Purchases.setLogLevel(LogLevel.info);

      final config = PurchasesConfiguration(RCConfig.androidApiKey)
        ..appUserID = userId;

      await Purchases.configure(config);
      _initialized = true;
      debugPrint('SubscriptionService: RevenueCat configured for user $userId');
    } catch (e) {
      debugPrint('SubscriptionService.init error: $e');
    }
  }

  // ── Entitlement check ────────────────────────────────────────────────────────

  /// Returns true if the user currently has an active "MobTeam Pro" entitlement
  /// OR a custom valid subscription mapped in Firestore.
  Future<bool> isProEntitled() async {
    // 1. RevenueCat Check
    try {
      final info = await Purchases.getCustomerInfo();
      if (info.entitlements.active.containsKey(RCConfig.entitlement)) {
        return true;
      }
    } catch (e) {
      debugPrint('SubscriptionService.isProEntitled RC error: $e');
    }

    // 2. Custom Firestore Check
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final db = FirebaseFirestore.instance;
        final subDoc = await db.collection('subscription').doc(user.uid).get();
        if (subDoc.exists) {
          final data = subDoc.data() as Map<String, dynamic>;
          final bool hasCustomSub = data['custom_subscription'] ?? false;
          final String category = data['subscription_category'] ?? '';
          if (hasCustomSub || category == 'Gift') {
            final dynamic endDateRaw = data['custom_sub_end_date'];
            if (endDateRaw is Timestamp) {
              if (endDateRaw.toDate().isAfter(DateTime.now())) {
                return true;
              }
            } else {
              // If there's no end date but custom_subscription is true, assume lifetime/gift
              return true;
            }
          }
        }
      }
    } catch (e) {
      debugPrint('SubscriptionService.isProEntitled Firestore check error: $e');
    }

    return false;
  }

  /// Synchronous cached check — use only when async is not possible.
  /// Falls back to false if SDK not yet initialized.
  bool get isProCached {
    // RevenueCat does not expose a sync entitlement getter; always false here.
    // Use isProEntitled() for reliable checks.
    return false;
  }

  // ── Offerings ────────────────────────────────────────────────────────────────

  /// Fetch the current RevenueCat offering.
  Future<Offering?> getCurrentOffering() async {
    try {
      final offerings = await Purchases.getOfferings();
      // First try to explicitly get the offering we configured (e.g., 'default')
      final configuredOffering = offerings.getOffering(RCConfig.offering);
      if (configuredOffering != null &&
          configuredOffering.availablePackages.isNotEmpty) {
        return configuredOffering;
      }
      // Fallback to whatever is marked as current in the dashboard
      return offerings.current;
    } catch (e) {
      debugPrint('SubscriptionService.getCurrentOffering error: $e');
      return null;
    }
  }

  // ── Purchase ─────────────────────────────────────────────────────────────────

  /// Purchase a specific [package] from the current offering.
  /// Returns [CustomerInfo] on success, null on cancellation or error.
  Future<CustomerInfo?> purchasePackage(Package package) async {
    try {
      final result = await Purchases.purchase(PurchaseParams.package(package));
      return result.customerInfo;
    } on PurchasesErrorCode catch (e) {
      if (e == PurchasesErrorCode.purchaseCancelledError) {
        debugPrint('SubscriptionService: purchase cancelled by user');
      } else {
        debugPrint('SubscriptionService.purchasePackage error: $e');
      }
      return null;
    } catch (e) {
      debugPrint('SubscriptionService.purchasePackage unexpected error: $e');
      return null;
    }
  }

  // ── Restore ──────────────────────────────────────────────────────────────────

  /// Restore previous purchases and return updated CustomerInfo.
  Future<CustomerInfo?> restorePurchases() async {
    try {
      final info = await Purchases.restorePurchases();
      debugPrint('SubscriptionService: purchases restored');
      return info;
    } catch (e) {
      debugPrint('SubscriptionService.restorePurchases error: $e');
      return null;
    }
  }

  // ── Customer info ────────────────────────────────────────────────────────────

  /// Get the latest [CustomerInfo] from RevenueCat.
  Future<CustomerInfo?> getCustomerInfo() async {
    try {
      return await Purchases.getCustomerInfo();
    } catch (e) {
      debugPrint('SubscriptionService.getCustomerInfo error: $e');
      return null;
    }
  }

  // ── Sign out ─────────────────────────────────────────────────────────────────

  /// Call on Firebase sign-out to reset RevenueCat's user identity.
  Future<void> logOut() async {
    try {
      await Purchases.logOut();
      _initialized = false;
      debugPrint('SubscriptionService: RevenueCat logged out');
    } catch (e) {
      debugPrint('SubscriptionService.logOut error: $e');
    }
  }

  // ── Legacy shim ──────────────────────────────────────────────────────────────
  // Kept so existing call sites in main.dart compile without changes.

  /// Purchase directly by product ID — used as fallback when RC offerings
  /// are not yet configured in the dashboard.
  /// Fetches the StoreProduct first, then purchases it.
  Future<CustomerInfo?> purchaseProductById(String productId) async {
    try {
      // Fetch the StoreProduct list for these IDs
      final products = await Purchases.getProducts([productId]);
      if (products.isEmpty) {
        debugPrint(
          'SubscriptionService.purchaseProductById: product not found → $productId',
        );
        return null;
      }
      final result = await Purchases.purchase(PurchaseParams.storeProduct(products.first));
      return result.customerInfo;
    } on PurchasesErrorCode catch (e) {
      if (e == PurchasesErrorCode.purchaseCancelledError) {
        debugPrint('SubscriptionService: purchase cancelled by user');
      } else {
        debugPrint('SubscriptionService.purchaseProductById error: $e');
      }
      return null;
    } catch (e) {
      debugPrint(
        'SubscriptionService.purchaseProductById unexpected error: $e',
      );
      return null;
    }
  }

  /// @deprecated Use [isProEntitled] instead.
  Future<bool> hasActiveSubscription() => isProEntitled();
}
