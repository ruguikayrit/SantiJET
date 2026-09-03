import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:santijet_demir/domain/enums/subscription_plan.dart';
import 'package:santijet_demir/domain/subscription/subscription_access.dart';
import 'package:santijet_demir/domain/subscription/subscription_catalog.dart';
import 'package:santijet_demir/features/auth/providers/auth_provider.dart';

final currentSubscriptionPlanProvider = Provider<SubscriptionPlan>((ref) {
  return ref.watch(authProvider).user?.subscriptionPlan ??
      SubscriptionPlan.demirTakip;
});

final currentSubscriptionPackageProvider =
    Provider<SubscriptionPackageInfo>((ref) {
  return SubscriptionCatalog.infoFor(ref.watch(currentSubscriptionPlanProvider));
});

final canAccessAnalysisBySubscriptionProvider = Provider<bool>((ref) {
  return SubscriptionAccess.canAccessAnalysis(
    ref.watch(currentSubscriptionPlanProvider),
  );
});

final canAccessPredictionBySubscriptionProvider = Provider<bool>((ref) {
  return SubscriptionAccess.canAccessPrediction(
    ref.watch(currentSubscriptionPlanProvider),
  );
});

final isGuestSessionProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).user?.isGuest ?? false;
});

final canPurchaseSubscriptionProvider = Provider<bool>((ref) {
  final user = ref.watch(authProvider).user;
  if (user == null) return false;
  return user.canPurchaseSubscription;
});

final hasActiveSubscriptionProvider = Provider<bool>((ref) {
  return ref.watch(currentSubscriptionPlanProvider).isPaid;
});
