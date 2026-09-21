// PurchaseManager: the one-off premium unlock, also earned free by a rewarded ad or a best score of 100.
// The SDK never starts at launch: main() reads premiumKey, Restore fixes it.

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
      // Clear the shared future so a later attempt can try again.
      // A failure here is usually the network, and the user may well tap the lock twice.
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

  /// Whether the customer holds the active premium entitlement. Purchase and restore both read it
  static bool isPremiumIn(CustomerInfo info) =>
    info.entitlements.active[premiumEntitlementID]?.isActive ?? false;

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
  ///
  /// Null hides every purchase entry point: the offer is drawn only from a real price.
  /// Always a network round-trip; the answer, null included, replaces the known price
  static Future<String?> fetchPrice() async => _knownPrice = await priceSource();

  /// The store lookup behind fetchPrice. Tests replace it so a screen's own fetch cannot race their pumps
  @visibleForTesting
  static Future<String?> Function() priceSource = _fetchPrice;

  /// Forgets the known price and any fetch, so each test starts from a fresh launch
  @visibleForTesting
  static void resetPrice() {
    _knownPrice = null;
    _pricing = null;
    _prefetch = null;
    priceSource = _fetchPrice;
  }

  // --- Price cache ---

  /// The last answer fetchPrice got, so a screen opened later needs no round-trip
  static String? _knownPrice;
  static String? get knownPrice => _knownPrice;
  /// The fetch in flight, joined by a second caller instead of starting another
  static Future<String?>? _pricing;
  /// The one prefetch per process, however often the home screen is rebuilt
  static Future<String?>? _prefetch;

  /// Fetches the price once, a few seconds after launch, so the menu opens with it
  static Future<String?> prefetchPrice() =>
    _prefetch ??= Future.delayed(pricePrefetchDelay, loadPrice);

  /// The known price, else the fetch in flight, else a new fetch
  static Future<String?> loadPrice() async =>
    _knownPrice ?? await (_pricing ??= fetchPrice().whenComplete(() => _pricing = null));

  static Future<String?> _fetchPrice() async {
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
    // Only this call is wrapped.
    // getOfferings throws when the dashboard has no product: that is "nothing to sell", not a failed purchase.
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
    final isPremium = isPremiumIn(purchaseResult.customerInfo);
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
    final isPremium = isPremiumIn(restoredInfo);
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
      // Cache only an upgrade: finding nothing on restore is no proof of no premium (wrong store account).
      // The next launch reads this, and false would show ads.
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
