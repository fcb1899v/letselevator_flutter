// =============================
// PurchaseManager: the premium unlock, bought once
//
// The premium entitlement removes the banner and unlocks every button shape,
// button style and background straight away. The rewarded ad and the Game
// Center best score of 100 still unlock the same things for free: buying is a
// shortcut, not the only road. Taking the free road away to sell the paid one
// would make the app worse for everyone who does not pay.
//
// The store SDK is NOT started during launch. configure() runs the first time
// something actually needs the store, behind a shared future, so a launch that
// never opens the settings screen never touches RevenueCat. Same shape as
// elevatorneo_flutter/lib/purchase_manager.dart, and for the same reason: the
// startup path is kept empty on purpose.
//
// main() therefore reads the entitlement from the local cache (premiumKey) and
// nothing else. That cache is written on every purchase and restore, so it is
// right for the whole life of an install. It is wrong only after a reinstall
// or on a second device, and the Restore button covers both. Both stores
// require that button anyway, so it is not extra surface.
// =============================

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'analytics_manager.dart';
import 'constant.dart';
import 'extension.dart';
import 'plan_provider.dart';

/// The store answered, but there is nothing to sell. Distinct from a purchase
/// that was attempted and failed, because the message the user reads is different
class StoreUnavailableException implements Exception {
  final String reason;
  const StoreUnavailableException(this.reason);
  @override
  String toString() => "StoreUnavailableException: $reason";
}

class PurchaseManager {

  /// Guards against a second purchase flow while one is still running
  static bool _isPurchasing = false;

  // --- Setup ---

  /// The one configure() call, shared by everyone who needs the store.
  /// Held so a second caller joins the first instead of configuring twice
  static Future<bool>? _configuring;

  /// Starts the store SDK on first use. Every other call here awaits this:
  /// reaching any Purchases API before configure() throws.
  /// Returns false when there is no API key, which is the state a build ships
  /// in before the key is added. The caller must then leave the purchase UI
  /// out rather than showing a button that cannot do anything
  static Future<bool> _ensureConfigured() => _configuring ??= _configure();

  static Future<bool> _configure() async {
    try {
      final apiKey = dotenv.maybeGet(revenueCatApiKey);
      if (apiKey == null || apiKey.isEmpty) {
        "No RevenueCat API key: purchases stay off".debugPrint();
        return false;
      }
      if (await Purchases.isConfigured) return true;
      await Purchases.setLogLevel(kDebugMode ? LogLevel.debug: LogLevel.warn);
      await Purchases.configure(PurchasesConfiguration(apiKey));
      if (Platform.isIOS || Platform.isMacOS) {
        await Purchases.enableAdServicesAttributionTokenCollection();
      }
      return true;
    } catch (e) {
      // Clear the shared future so a later attempt can try again: a failure
      // here is usually the network, and the user may well tap the lock twice
      _configuring = null;
      "RevenueCat configure failed: $e".debugPrint();
      return false;
    }
  }

  /// Picks the package to sell: the lifetime one, otherwise the first available
  static Package? _premiumPackage(Offerings offerings) {
    final current = offerings.current;
    if (current == null) return null;
    if (current.lifetime != null) return current.lifetime;
    return current.availablePackages.isNotEmpty ? current.availablePackages.first: null;
  }

  // --- Entitlement ---

  /// Writes the entitlement to the local cache so the next launch can read it
  static Future<void> _cachePremium(bool isPremium) async {
    final prefs = await SharedPreferences.getInstance();
    premiumKey.setSharedPrefBool(prefs, isPremium);
  }

  /// Fetches the localized price of the premium package for display
  ///
  /// This is the only honest test of whether anything can be sold right now,
  /// and every purchase entry point is drawn from its answer. A configure()
  /// that did not throw is NOT such a test: it validates no product, reaches
  /// no offering and needs no network, so it returns true just as readily for
  /// a build whose RevenueCat project has no offering, whose store product is
  /// still unapproved, or whose user is offline. A button drawn on that answer
  /// is a button that does nothing when pressed, which is what NEO's Android
  /// 1.5.25 shipped: 499 presses over nine days and not one purchase
  /// (00_Corporate_Planning/decisions/active/DEC-20260906-neo-purchase-test-mode-release.md)
  ///
  /// Null no longer hides the purchase entry points. An app's first In-App
  /// Purchase has to be attached to the same submission as the binary, and
  /// Apple documents that StoreKit can return no products in the App Review
  /// sandbox in exactly that state. Hiding on null would show the reviewer an
  /// app with no purchase at all, and the purchase would be rejected with it
  static Future<String?> fetchPrice() async {
    try {
      if (!await _ensureConfigured()) return null;
      final Offerings offerings = await Purchases.getOfferings();
      final package = _premiumPackage(offerings);
      if (package == null) return null;
      "premium price: ${package.storeProduct.priceString}".debugPrint();
      return package.storeProduct.priceString;
    } catch (e) {
      "Error fetching offerings: $e".debugPrint();
      return null;
    }
  }

  // --- Purchase and Restore ---

  /// Fetches available offerings and initiates purchase
  ///
  /// The PlatformException is deliberately not wrapped. buyPremium tells a
  /// user-initiated cancel apart from a real failure by reading the error code
  /// off it, and a wrapped one arrives there as a plain Exception, so every
  /// cancel would be reported to the user as a failed purchase
  static Future<bool> _purchasePremium() async {
    if (!await _ensureConfigured()) {
      throw const StoreUnavailableException("configure");
    }
    // Only this call is wrapped. getOfferings throws when the dashboard has no
    // product, which is "nothing to sell", not a purchase that failed
    final Offerings offerings;
    try {
      offerings = await Purchases.getOfferings();
    } catch (e) {
      throw StoreUnavailableException("offerings: $e");
    }
    if (offerings.current == null) {
      throw const StoreUnavailableException("no offering");
    }
    final package = _premiumPackage(offerings);
    if (package == null) {
      throw const StoreUnavailableException("no package");
    }
    final purchaseResult = await Purchases.purchase(PurchaseParams.package(package));
    final isPremium = purchaseResult.customerInfo.entitlements.active[premiumEntitlementID]?.isActive ?? false;
    "purchased isPremium: $isPremium".debugPrint();
    return isPremium;
  }

  /// Restores previous purchases from the app store
  /// Returns the premium status carried by the restored entitlements
  static Future<bool> _restorePremium() async {
    if (!await _ensureConfigured()) {
      throw const StoreUnavailableException("configure");
    }
    final restoredInfo = await Purchases.restorePurchases();
    final isPremium = restoredInfo.entitlements.active[premiumEntitlementID]?.isActive ?? false;
    "restored isPremium: $isPremium".debugPrint();
    return isPremium;
  }

  /// Main purchase/restore function for the UI to call
  /// Returns true when the user ends up with the premium entitlement
  /// Throws on failure so the UI can show a message; cancellation returns false
  static Future<bool> buyPremium({required bool isRestore, required String source}) async {
    if (_isPurchasing) return false;
    _isPurchasing = true;
    try {
      final bool isPremium;
      if (isRestore) {
        isPremium = await _restorePremium();
        await AnalyticsManager.upgradeRestored(isPremium);
      } else {
        await AnalyticsManager.upgradeStarted(source);
        isPremium = await _purchasePremium();
        if (isPremium) await AnalyticsManager.upgradePurchased(source);
      }
      // Cache only an upgrade. A restore that finds nothing is not proof the
      // user is not premium (wrong store account, for one), and a lifetime
      // entitlement never expires, so nothing here may write false: the
      // next launch reads this cache and would show ads to a paying user
      if (isPremium) await _cachePremium(true);
      _isPurchasing = false;
      return isPremium;
    } catch (e) {
      "Purchase flow error: $e".debugPrint();
      _isPurchasing = false;
      if (e is PlatformException) {
        final errorCode = PurchasesErrorHelper.getErrorCode(e);
        // A user-initiated cancel is not an error worth surfacing
        if (errorCode == PurchasesErrorCode.purchaseCancelledError) return false;
      }
      rethrow;
    }
  }
}
