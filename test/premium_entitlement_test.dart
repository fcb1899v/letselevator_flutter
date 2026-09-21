import 'package:flutter_test/flutter_test.dart';
import 'package:letselevator/constant.dart';
import 'package:letselevator/purchase_manager.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

/// A CustomerInfo whose active entitlements are exactly [activeIds]
CustomerInfo _customerWith(List<String> activeIds, {bool isActive = true}) {
  final entitlements = {
    for (final id in activeIds)
      id: EntitlementInfo(id, isActive, false, "2026-09-15T00:00:00Z",
        "2026-09-15T00:00:00Z", "elevator_premium_unlock", true),
  };
  return CustomerInfo(EntitlementInfos(entitlements, entitlements),
    const {}, const [], const ["elevator_premium_unlock"], const [],
    "2026-09-15T00:00:00Z", "test_user", const {}, "2026-09-15T00:00:00Z");
}

void main() {
  test("entitlement id is the one attached in RevenueCat", () {
    expect(premiumEntitlementID, "letselevator_premium");
  });

  test("letselevator_premium active: premium", () {
    expect(PurchaseManager.isPremiumIn(_customerWith(["letselevator_premium"])), isTrue);
  });

  test("only another app's premium entitlement: not premium", () {
    expect(PurchaseManager.isPremiumIn(_customerWith(["premium"])), isFalse);
  });

  test("no entitlement, or an inactive one: not premium", () {
    expect(PurchaseManager.isPremiumIn(_customerWith([])), isFalse);
    expect(PurchaseManager.isPremiumIn(
      _customerWith(["letselevator_premium"], isActive: false)), isFalse);
  });
}
