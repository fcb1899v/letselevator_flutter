// =============================
// Main: Elevator Simulator Application Entry Point
//
// This file contains the main application entry point with:
// 1. Dependencies: External packages and local imports
// 2. State Management: Riverpod providers for app-wide state
// 3. Initialization: Firebase, ads, and app configuration
// 4. App Configuration: Theme, localization, and routing setup
// 5. Privacy: App Tracking Transparency implementation
// =============================

import 'dart:async';
import 'dart:io';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
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
import 'settings.dart';

// --- Configuration Constants ---
// Test mode flag for development and testing purposes
const isTest = false;

// --- State Management Providers ---
// Riverpod providers for app-wide state management
final isShimadaProvider = StateProvider<bool>((ref) => false);
final isMenuProvider = StateProvider<bool>((ref) => false);
final floorNumbersProvider = StateProvider<List<int>>((ref) => initialFloorNumbers);
final floorStopsProvider = StateProvider<List<bool>>((ref) => initialFloorStops);
final buttonShapeProvider = StateProvider<String>((ref) => initialButtonShape);
final buttonStyleProvider = StateProvider<int>((ref) => initialButtonStyle);
final backgroundStyleProvider = StateProvider<String>((ref) => initialBackgroundStyle);
final gamesSignInProvider =  StateProvider<bool>((ref) => false);
final bestScoreProvider = StateProvider<int>((ref) => 0);

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
  // Configure transparent status bar and navigation
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  // --- Environment and Data Loading ---
  // Load environment variables from .env file
  await dotenv.load(fileName: "assets/.env");
  // --- Shared Preferences Loading ---
  // Load saved user preferences and settings
  final prefs = await SharedPreferences.getInstance();
  final savedFloorNumbers = "numbersKey".getSharedPrefListInt(prefs, initialFloorNumbers);
  final savedFloorStops = "stopsKey".getSharedPrefListBool(prefs, initialFloorStops);
  final savedButtonShape = "buttonShapeKey".getSharedPrefString(prefs, initialButtonShape);
  final savedButtonStyle = "buttonStyleKey".getSharedPrefInt(prefs, initialButtonStyle);
  final savedBackgroundStyle = "backgroundStyleKey".getSharedPrefString(prefs, initialBackgroundStyle);
  // --- Games Services Integration ---
  // Initialize games sign-in and load best score
  final isGamesSignIn = await gamesSignIn(false);
  final savedBestScore = await getBestScore(isGamesSignIn);
  // --- Firebase Configuration ---
  // Initialize Firebase with platform-specific options
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // --- App Launch ---
  // Launch app with provider overrides for saved state
  runApp(ProviderScope(
    overrides: [
      floorNumbersProvider.overrideWith((ref) => savedFloorNumbers),
      floorStopsProvider.overrideWith((ref) => savedFloorStops),
      buttonStyleProvider.overrideWith((ref) => savedButtonStyle),
      buttonShapeProvider.overrideWith((ref) => savedButtonShape),
      backgroundStyleProvider.overrideWith((ref) => savedBackgroundStyle),
      gamesSignInProvider.overrideWith((ref) => isGamesSignIn),
      bestScoreProvider.overrideWith((ref) => savedBestScore),
    ],
    child: const MyApp())
  );
  // Activate Firebase App Check for security
  await FirebaseAppCheck.instance.activate(
    androidProvider: androidProvider,
    appleProvider: appleProvider,
  );
  // --- Mobile Ads Initialization ---
  // Initialize Google Mobile Ads for monetization
  await MobileAds.instance.initialize();
  // --- Privacy Configuration ---
  // Initialize App Tracking Transparency for iOS
  await initATTPlugin();
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

// --- Privacy Management ---
// App Tracking Transparency implementation for iOS privacy compliance
Future<void> initATTPlugin() async {
  // Only request tracking permission on iOS and macOS platforms
  if (Platform.isIOS || Platform.isMacOS) {
    final status = await AppTrackingTransparency.trackingAuthorizationStatus;
    // Request permission if not yet determined
    if (status == TrackingStatus.notDetermined) {
      await AppTrackingTransparency.requestTrackingAuthorization();
    }
  }
}
