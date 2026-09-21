// PlanProvider: premium entitlement state only; the store lives in purchase_manager.dart.
// It starts from the cache main.dart reads, replaced by what a purchase or restore returns.

import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'extension.dart';

/// Provider for managing premium plan state across the app
final planProvider = NotifierProvider<PlanNotifier, PlanState>(PlanNotifier.new);

/// SharedPreferences key holding the cached entitlement status
const String premiumKey = "premiumKey";

/// Immutable state class for premium plan information
@immutable
class PlanState {
  /// Whether the user has premium access
  final bool isPremium;
  /// Whether a purchase/restore operation is currently in progress
  final bool isPurchasing;
  /// Localized price string of the premium package, empty until offerings load
  final String priceString;

  const PlanState({
    this.isPremium = false,
    this.isPurchasing = false,
    this.priceString = "",
  });

  PlanState copyWith({bool? isPremium, bool? isPurchasing, String? priceString}) => PlanState(
    isPremium: isPremium ?? this.isPremium,
    isPurchasing: isPurchasing ?? this.isPurchasing,
    priceString: priceString ?? this.priceString,
  );
}

/// Notifier for managing premium plan state
class PlanNotifier extends Notifier<PlanState> {
  final PlanState? _initial;

  PlanNotifier([this._initial]);

  @override
  PlanState build() => _initial ?? const PlanState();

  /// Updates the current premium plan status and caches it locally
  Future<void> setCurrentPlan(bool isPremium) async {
    state = state.copyWith(isPremium: isPremium);
    final prefs = await SharedPreferences.getInstance();
    premiumKey.setSharedPrefBool(prefs, isPremium);
  }

  /// Updates the purchasing state (loading indicator)
  void setPurchasing(bool isPurchasing) {
    state = state.copyWith(isPurchasing: isPurchasing);
  }

  /// Stores the localized price so every upgrade entry point shows the same one
  void setPrice(String priceString) {
    state = state.copyWith(priceString: priceString);
  }
}
