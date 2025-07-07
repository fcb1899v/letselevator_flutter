// =============================
// GamesManager: Game Services Integration and Leaderboard Management
//
// This file manages game services integration including:
// 1. Authentication: Game services sign-in and connection management
// 2. Score Submission: Leaderboard score submission functionality
// 3. Leaderboard Display: Show leaderboards to users
// 4. Best Score Management: Retrieve and sync best scores from server
// 5. Network Connectivity: Internet connection validation
// =============================

import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:games_services/games_services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'extension.dart';

// --- Authentication ---
// Game services sign-in with connection validation
// Handles authentication flow and error management
Future<bool> gamesSignIn(bool isGamesSignIn) async {
  if (isGamesSignIn) {
    "Already signed in to games services: true".debugPrint();
    return true;
  } else {
    final isConnectInternet = await isConnectedToInternet();
    if (!isConnectInternet) {
      "No internet connection".debugPrint();
      return false;
    }
    "Start games sign in".debugPrint();
    try {
      await GameAuth.signIn();
      final isSignedIn = await GameAuth.isSignedIn;
      if (!isSignedIn) {
        'Fail to sign in to games services: $isSignedIn'.debugPrint();
        return false;
      } else {
        'Success to sign in to games services: $isSignedIn'.debugPrint();
        return true;
      }
    } catch (e) {
      'Fail to sign in to games services: $e'.debugPrint();
      return false;
    }
  }
}

// --- Score Submission ---
// Submit score to leaderboard with authentication check
// Handles score submission to both Android and iOS leaderboards
Future<void> gamesSubmitScore(int value, bool isGamesSignIn) async {
  final isSignedIn = (isGamesSignIn) ? isGamesSignIn: await gamesSignIn(isGamesSignIn);
  if (isSignedIn) {
    "gamesSubmitScore".debugPrint();
    try {
      await Leaderboards.submitScore(
        score: Score(
          androidLeaderboardID: dotenv.get("ANDROID_LEADERBOARD_ID"),
          iOSLeaderboardID: dotenv.get("IOS_LEADERBOARD_ID"),
          value: value,
        ),
      );
      "Success submitting leaderboard: $value".debugPrint();
    } catch (e) {
      'Error submitting score: $e'.debugPrint();
    }
  }
}

// --- Leaderboard Display ---
// Show leaderboards to users with authentication check
// Displays platform-specific leaderboards
Future<void> gamesShowLeaderboard(bool isGamesSignIn) async {
  final isSignedIn = (isGamesSignIn) ? isGamesSignIn: await gamesSignIn(isGamesSignIn);
  if (isSignedIn) {
    "gamesShowLeaderboard".debugPrint();
    try {
      await Leaderboards.showLeaderboards(
        androidLeaderboardID: dotenv.get("ANDROID_LEADERBOARD_ID"),
        iOSLeaderboardID: dotenv.get("IOS_LEADERBOARD_ID")
      );
      "Success showing leaderboard".debugPrint();
    } catch (e) {
      'Error showing leaderboards: $e'.debugPrint();
    }
  }
}

// --- Best Score Management ---
// Retrieve and sync best scores from server and local storage
// Compares local and server scores, updates local storage if needed
Future<int> getBestScore(bool isGamesSignIn) async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final savedBestScore = "bestScore".getSharedPrefInt(prefs, 0);
  "savedBestScore: $savedBestScore".debugPrint();
  final isSignedIn = (isGamesSignIn) ? isGamesSignIn: await gamesSignIn(isGamesSignIn);
  if (isSignedIn) {
    try {
      final gamesBestScore = await Player.getPlayerScore(
        androidLeaderboardID: dotenv.get("ANDROID_LEADERBOARD_ID"),
        iOSLeaderboardID: dotenv.get("IOS_LEADERBOARD_ID"),
      ) ?? savedBestScore;
      "gamesBestScore: $gamesBestScore".debugPrint();
      if (gamesBestScore > savedBestScore) {
        'bestScore'.setSharedPrefInt(prefs, gamesBestScore);
        "bestScore: $gamesBestScore".debugPrint();
        return savedBestScore;
      } else {
        await gamesSubmitScore(savedBestScore, isGamesSignIn);
        "bestScore: $savedBestScore".debugPrint();
        return gamesBestScore;
      }
    } catch (e) {
      "bestScore: $savedBestScore (Fail to get from server)".debugPrint();
      return savedBestScore;
    }
  } else {
    "bestScore: $savedBestScore (Can't sign in the server)".debugPrint();
    return savedBestScore;
  }
}

// --- Network Connectivity ---
// Check internet connectivity for game services
// Validates network connection using DNS lookup
Future<bool> isConnectedToInternet() async {
  try {
    final result = await InternetAddress.lookup('example.com');
    "Connected to internet".debugPrint();
    return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
  } catch (_) {
    "Fail to connect internet".debugPrint();
    return false;
  }
}
