// =============================
// AnalyticsManager: Firebase Analytics event logging
//
// Centralizes the custom events that make the purchase funnel measurable:
// locked feature reached -> offer shown -> purchase started -> purchased.
//
// The event names and parameter names are deliberately identical to the ones
// LETS ELEVATOR NEO sends (elevatorneo_flutter/lib/analytics_manager.dart).
// Both apps sell the same one-off unlock, so a per-app conversion rate is only
// comparable, and a combined LTV only computable, while the names match.
// Renaming an event here silently splits the funnel in two.
// =============================

import 'package:firebase_analytics/firebase_analytics.dart';
import 'extension.dart';

class AnalyticsManager {

  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  // --- Internal Helper ---

  /// Log an event and swallow any failure so analytics never breaks the app
  static Future<void> _log(String name, [Map<String, Object>? params]) async {
    try {
      await _analytics.logEvent(name: name, parameters: params);
      "Analytics: $name ${params ?? ""}".debugPrint();
    } catch (e) {
      "Analytics error: $name: $e".debugPrint();
    }
  }

  // --- Unlock Funnel Events ---

  /// Log that a user faced a locked feature: the core demand signal
  /// `feature` identifies which lock was hit, so pricing can be tuned per feature
  ///
  /// NEO sends required_point and current_point here because its locks are
  /// priced in EV miles. This app has no such currency: a lock opens by
  /// watching a rewarded ad. Button shapes and styles also open at a Game
  /// Center best score of 100, and for those the two parameters carry that
  /// threshold and the user's own score. Backgrounds and floors do not open on
  /// a score, so they send a required_point of 0
  static Future<void> unlockBlocked({
    required String feature,
    required int requiredPoint,
    required int currentPoint,
  }) => _log("unlock_blocked", {
    "feature": feature,
    "required_point": requiredPoint,
    "current_point": currentPoint,
    "shortage": (requiredPoint - currentPoint).clamp(0, requiredPoint),
  });

  // --- Purchase Events ---

  /// Log that the upgrade dialog was shown, with the trigger that opened it
  static Future<void> upgradeOffered(String source) =>
      _log("upgrade_offered", {"source": source});

  /// Log that the user started the purchase flow
  static Future<void> upgradeStarted(String source) =>
      _log("upgrade_started", {"source": source});

  /// Log a completed purchase
  static Future<void> upgradePurchased(String source) =>
      _log("upgrade_purchased", {"source": source});

  /// Log a restore attempt and whether it granted the entitlement
  static Future<void> upgradeRestored(bool isPremium) =>
      _log("upgrade_restored", {"is_premium": isPremium ? 1 : 0});
}
