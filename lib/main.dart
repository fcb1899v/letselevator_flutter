// ===== Main: elevator simulator application entry point =====
// Riverpod providers, Firebase and ads initialization, theme, localization, routing

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'l10n/app_localizations.dart' show AppLocalizations;
import 'firebase_options.dart';
import 'games_manager.dart';
import 'constant.dart';
import 'extension.dart';
import 'homepage.dart';
import 'buttons.dart';
import 'plan_provider.dart';
import 'settings.dart';

// --- Configuration Constants ---
// Test mode flag for development and testing purposes
const isTest = false;

// --- State Management Providers ---
// Initial values for provider overrides (set in main() before runApp)
List<int>? _overrideFloorNumbers;
List<bool>? _overrideFloorStops;
int? _overrideButtonStyle;
String? _overrideButtonShape;
String? _overrideBackgroundStyle;
bool? _overrideGamesSignIn;
int? _overrideBestScore;

// Notifier classes for app-wide state (Riverpod 3 Notifier API)
// Each notifier exposes an update method for external state changes.
class IsShimadaNotifier extends Notifier<bool> {
  @override
  bool build() => false;
  void update(bool value) => state = value;
}

class IsMenuNotifier extends Notifier<bool> {
  @override
  bool build() => false;
  void update(bool value) => state = value;
}

class FloorNumbersNotifier extends Notifier<List<int>> {
  @override
  List<int> build() {
    final override = _overrideFloorNumbers;
    _overrideFloorNumbers = null;
    return override ?? initialFloorNumbers;
  }
  void update(List<int> value) => state = value;
}

class FloorStopsNotifier extends Notifier<List<bool>> {
  @override
  List<bool> build() {
    final override = _overrideFloorStops;
    _overrideFloorStops = null;
    return override ?? initialFloorStops;
  }
  void update(List<bool> value) => state = value;
}

class ButtonShapeNotifier extends Notifier<String> {
  @override
  String build() {
    final override = _overrideButtonShape;
    _overrideButtonShape = null;
    return override ?? initialButtonShape;
  }
  void update(String value) => state = value;
}

class ButtonStyleNotifier extends Notifier<int> {
  @override
  int build() {
    final override = _overrideButtonStyle;
    _overrideButtonStyle = null;
    return override ?? initialButtonStyle;
  }
  void update(int value) => state = value;
}

class BackgroundStyleNotifier extends Notifier<String> {
  @override
  String build() {
    final override = _overrideBackgroundStyle;
    _overrideBackgroundStyle = null;
    return override ?? initialBackgroundStyle;
  }
  void update(String value) => state = value;
}

class GamesSignInNotifier extends Notifier<bool> {
  @override
  bool build() {
    final override = _overrideGamesSignIn;
    _overrideGamesSignIn = null;
    return override ?? false;
  }
  void update(bool value) => state = value;
}

class BestScoreNotifier extends Notifier<int> {
  @override
  int build() {
    final override = _overrideBestScore;
    _overrideBestScore = null;
    return override ?? 0;
  }
  void update(int value) => state = value;
}

// Riverpod providers for app-wide state management
final isShimadaProvider = NotifierProvider<IsShimadaNotifier, bool>(IsShimadaNotifier.new);
final isMenuProvider = NotifierProvider<IsMenuNotifier, bool>(IsMenuNotifier.new);
final floorNumbersProvider = NotifierProvider<FloorNumbersNotifier, List<int>>(FloorNumbersNotifier.new);
final floorStopsProvider = NotifierProvider<FloorStopsNotifier, List<bool>>(FloorStopsNotifier.new);
final buttonShapeProvider = NotifierProvider<ButtonShapeNotifier, String>(ButtonShapeNotifier.new);
final buttonStyleProvider = NotifierProvider<ButtonStyleNotifier, int>(ButtonStyleNotifier.new);
final backgroundStyleProvider = NotifierProvider<BackgroundStyleNotifier, String>(BackgroundStyleNotifier.new);
final gamesSignInProvider = NotifierProvider<GamesSignInNotifier, bool>(GamesSignInNotifier.new);
final bestScoreProvider = NotifierProvider<BestScoreNotifier, int>(BestScoreNotifier.new);

// --- Application Entry Point ---
// Main function for app initialization and configuration
Future<void> main() async {
  // Initialize Flutter bindings for platform integration
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  // --- Device Configuration ---
  // Set portrait orientation for consistent UI layout
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  // Enable edge-to-edge display for modern UI
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  // Configure edge-to-edge display for Android 15+ compatibility
  // Note: Removed deprecated statusBarColor and systemNavigationBarColor parameters
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  // --- Environment and Data Loading ---
  // Load environment variables from .env file
  await dotenv.load(fileName: "assets/.env");
  // --- Shared Preferences Loading ---
  // Load saved user preferences and settings
  final prefs = await SharedPreferences.getInstance();
  final savedFloorNumbers = normalizedFloorNumbers(
    "numbersKey".getSharedPrefListInt(prefs, initialFloorNumbers));
  final savedFloorStops = normalizedFloorStops(
    "stopsKey".getSharedPrefListBool(prefs, initialFloorStops));
  final savedButtonShape = "buttonShapeKey".getSharedPrefString(prefs, initialButtonShape);
  final savedButtonStyle = "buttonStyleKey".getSharedPrefInt(prefs, initialButtonStyle);
  final savedBackgroundStyle = "backgroundStyleKey".getSharedPrefString(prefs, initialBackgroundStyle);
  // --- Premium Entitlement --- read from the local cache, not the store, so launch
  // costs nothing; purchase_manager.dart writes the cache on every purchase and restore
  final savedPremium = premiumKey.getSharedPrefBool(prefs, false);
  // --- Games Services Integration ---
  // Initialize games sign-in and load best score
  final isGamesSignIn = await gamesSignIn(false);
  final savedBestScore = await getBestScore(isGamesSignIn);
  // --- Firebase Configuration ---
  // Initialize Firebase with platform-specific options
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // --- App Launch ---
  // Set initial state overrides for Notifiers (read in each Notifier.build())
  _overrideFloorNumbers = savedFloorNumbers;
  _overrideFloorStops = savedFloorStops;
  _overrideButtonStyle = savedButtonStyle;
  _overrideButtonShape = savedButtonShape;
  _overrideBackgroundStyle = savedBackgroundStyle;
  _overrideGamesSignIn = isGamesSignIn;
  _overrideBestScore = savedBestScore;
  runApp(ProviderScope(
    overrides: [
      floorNumbersProvider.overrideWith(FloorNumbersNotifier.new),
      floorStopsProvider.overrideWith(FloorStopsNotifier.new),
      buttonStyleProvider.overrideWith(ButtonStyleNotifier.new),
      buttonShapeProvider.overrideWith(ButtonShapeNotifier.new),
      backgroundStyleProvider.overrideWith(BackgroundStyleNotifier.new),
      gamesSignInProvider.overrideWith(GamesSignInNotifier.new),
      bestScoreProvider.overrideWith(BestScoreNotifier.new),
      planProvider.overrideWith(() => PlanNotifier(PlanState(isPremium: savedPremium))),
    ],
    child: const MyApp())
  );
  // --- Mobile Ads Initialization ---
  // Initialize Google Mobile Ads for monetization
  await MobileAds.instance.initialize();
  // --- Privacy Configuration --- no ATT call here: on iOS the UMP form raises the
  // system ATT prompt itself, so asking again showed a second explainer
}

// --- Main Application Widget ---
// Root application widget with configuration and routing
class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    // --- UI Configuration ---
    // Disable text scaling for consistent UI layout
    builder: (BuildContext context, Widget? child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1)),
      child: child!,
    ),
    // --- Localization Configuration ---
    // Set up multi-language support with delegates and locales
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    // --- App Metadata ---
    title: appTitle,
    theme: ThemeData(primarySwatch: Colors.grey),
    debugShowCheckedModeBanner: false,
    // --- Routing Configuration ---
    // Set initial route and define app navigation structure
    initialRoute: "/h",
    routes: {
      "/h": (context) => const HomePage(),      // Main elevator interface
      "/r": (context) => const ButtonsPage(),   // Button customization page
      "/s": (context) => const SettingsPage(),  // Settings and configuration page
    },
    // --- Analytics and Navigation Observers ---
    // Firebase Analytics integration for user behavior tracking
    navigatorObservers: <NavigatorObserver>[
      FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance),
      RouteObserver<ModalRoute>()
    ],
  );
}
