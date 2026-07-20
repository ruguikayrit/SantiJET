import 'package:santijet_demir/domain/enums/subscription_plan.dart';

/// Abonelik planına göre özellik erişimi (kurumsal RBAC ile AND kullanılır).
abstract final class SubscriptionAccess {
  static bool canAccessAnalysis(SubscriptionPlan plan) => plan.includesAnalysis;

  static bool canAccessPrediction(SubscriptionPlan plan) =>
      plan.includesPrediction;

  /// Metraj / keşif her planda açık.
  static bool canAccessMetraj(SubscriptionPlan plan) => true;
}
