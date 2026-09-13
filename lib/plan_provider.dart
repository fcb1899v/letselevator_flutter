// =============================
// PlanProvider: premium entitlement state
//
// The premium entitlement removes the banner and unlocks every button shape,
// button style and background at once, without watching a rewarded ad and
// without reaching a Game Center best score of 100.
//
// This file holds state only. Everything that talks to the store lives in
// purchase_manager.dart. The entitlement this starts with is the locally
// cached value main.dart reads at startup, and it is replaced by whatever a
// purchase or a restore returns.
// =============================

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
