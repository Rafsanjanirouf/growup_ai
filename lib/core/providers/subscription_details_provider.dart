import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../services/subscription_service.dart';

class SubscriptionDetails {
  final String category;
  final DateTime startDate;
  final DateTime endDate;
  final int ongoingDays;

  SubscriptionDetails({
    required this.category,
    required this.startDate,
    required this.endDate,
    required this.ongoingDays,
  });
}

final subscriptionDetailsProvider = FutureProvider<SubscriptionDetails?>((ref) async {
  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    // 1. Check RevenueCat first
    try {
      final CustomerInfo customerInfo = await Purchases.getCustomerInfo();
      final EntitlementInfo? entitlement = customerInfo.entitlements.active[RCConfig.entitlement];

      if (entitlement != null) {
        // User is PRO via RevenueCat
        final isTrial = entitlement.periodType == PeriodType.trial;
        final category = isTrial ? 'Trial' : 'Purchase';
        
        final startDateStr = entitlement.latestPurchaseDate;
        final endDateStr = entitlement.expirationDate;

        final startDate = DateTime.parse(startDateStr);
        final endDate = endDateStr != null ? DateTime.parse(endDateStr) : DateTime.now().add(const Duration(days: 365*10)); // Lifetime fallback
        final ongoingDays = DateTime.now().difference(startDate).inDays;

        return SubscriptionDetails(
          category: category,
          startDate: startDate,
          endDate: endDate,
          ongoingDays: ongoingDays >= 0 ? ongoingDays : 0,
        );
      }
    } catch (rcError) {
      // Ignore RevenueCat errors and proceed to check custom override
    }

    // 2. Check Custom Database Override (Firestore)
    final db = FirebaseFirestore.instanceFor(app: Firebase.app(), databaseId: 'v2db');
    final doc = await db.collection('subscription').doc(user.uid).get();

    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      final bool hasCustomSub = data['custom_subscription'] ?? false;
      final String categoryStr = data['subscription_category'] ?? '';
      
      if (hasCustomSub || categoryStr == 'Gift') {
        final dynamic endDateRaw = data['custom_sub_end_date'];
        
        // If there's an end date, check if it's valid
        if (endDateRaw is Timestamp) {
          if (endDateRaw.toDate().isAfter(DateTime.now())) {
            final dynamic startDateRaw = data['custom_sub_start_date'];
            final String category = data['subscription_category'] ?? 'Custom';
            
            final startDate = startDateRaw is Timestamp ? startDateRaw.toDate() : DateTime.now();
            final endDate = endDateRaw.toDate();
            final ongoingDays = DateTime.now().difference(startDate).inDays;

            return SubscriptionDetails(
              category: category,
              startDate: startDate,
              endDate: endDate,
              ongoingDays: ongoingDays >= 0 ? ongoingDays : 0,
            );
          }
        } else {
          // If custom_subscription is true but there's no valid end date, assume lifetime/gift
          final dynamic startDateRaw = data['custom_sub_start_date'];
          final String category = data['subscription_category'] ?? 'Gift/Lifetime';
          
          final startDate = startDateRaw is Timestamp ? startDateRaw.toDate() : DateTime.now();
          final endDate = DateTime.now().add(const Duration(days: 365*10)); // Arbitrary lifetime
          final ongoingDays = DateTime.now().difference(startDate).inDays;

          return SubscriptionDetails(
            category: category,
            startDate: startDate,
            endDate: endDate,
            ongoingDays: ongoingDays >= 0 ? ongoingDays : 0,
          );
        }
      }
    }

    return null;
  } catch (e) {
    return null;
  }
});
