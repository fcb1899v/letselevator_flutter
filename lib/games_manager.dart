// ===== GamesManager: game services sign-in, leaderboards, best score sync =====

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:games_services/games_services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'constant.dart';
import 'extension.dart';

// --- Authentication ---
/// Longest any caller waits on a sign-in; the shared attempt itself goes on
const Duration gamesSignInWait = Duration(seconds: 10);
Future<bool>? _signInInFlight;

/// One native sign-in at a time, shared by every caller: on Android a second
/// call replaces the first, whose result then never arrives (Auth.kt:61-62)
Future<bool> sharedGamesSignIn() =>
  _signInInFlight ??= nativeGamesSignIn().whenComplete(() => _signInInFlight = null);

/// Tests run each case in its own zone, where an attempt left by the last one never ends
@visibleForTesting
void resetGamesSignIn() => _signInInFlight = null;

// Game services sign-in, time-bounded for the caller
Future<bool> gamesSignIn(bool isGamesSignIn) async {
  if (isGamesSignIn) {
    "Already signed in to games services: true".debugPrint();
    return true;
  }
  return sharedGamesSignIn().timeout(gamesSignInWait, onTimeout: () {
    "Games sign-in still pending after ${gamesSignInWait.inSeconds} s".debugPrint();
    return false;
  });
}

/// Signed in already, checked without any sign-in UI; false if it does not answer
@visibleForTesting
Future<bool> Function() silentSignInCheck = () => GameAuth.isSignedIn;

/// The platform sign-in; tests have no Game Center and swap it (test/flutter_test_config.dart)
@visibleForTesting
Future<bool> Function() nativeGamesSignIn = _nativeSignIn;

Future<bool> _nativeSignIn() async {
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

// --- Launch Sync ---
/// Longest the launch waits on games services; an answer after it is still applied
const Duration gamesLaunchTimeout = Duration(seconds: 10);

/// Sign in and fetch the leaderboard best after the first frame. The wait is capped;
/// the results are applied whenever the shared attempt answers, even after that
Future<void> syncGamesAfterLaunch({
  required void Function(bool isSignedIn) onSignIn,
  required void Function(int bestScore) onBestScore,
  Duration timeout = gamesLaunchTimeout,
  @visibleForTesting Future<bool> Function() signIn = sharedGamesSignIn,
}) async {
  final Future<void> sync = signIn().then((isSignedIn) async {
    onSignIn(isSignedIn);
    // Signed out, the stored best loaded before runApp is already the answer
    if (isSignedIn) onBestScore(await getBestScore(true));
  });
  await sync.timeout(timeout,
    onTimeout: () => "Games sync still pending after ${timeout.inSeconds} s".debugPrint());
}

/// Buttons a run can select, so the highest possible score: the 9x11x11 grid less
/// the cells rowMinus removes and the two transparent ones (1089 - 38 - 2 = 1049)
final int selectableButtonCount = [
  for (int p = 0; p < panelMax; p++)
    for (int col = 0; col < columnMax; col++)
      for (int row = 0; row < rowMax - rowMinus[p][col]; row++)
        if (!p.isTranspButton(row, col)) 1,
].length;

const String pendingRunKey = "pendingRunKey";
const Duration gamesSubmitTimeout = Duration(seconds: 10);

/// No run can reach a score over the button count, so such a value was not earned
bool isPossibleScore(int score) => score >= 0 && score <= selectableButtonCount;

/// The stored best, read as 0 when it is over the cap. The key itself is left alone
int storedBestScore(SharedPreferences prefs) {
  final score = "bestScore".getSharedPrefInt(prefs, 0);
  if (isPossibleScore(score)) return score;
  "Stored best $score is over $selectableButtonCount: read as 0".debugPrint();
  return 0;
}

/// A finished 30 s run's score, kept in prefs until it reaches the leaderboard.
/// No time window: a stalled or interrupted run is still genuine
class ChallengeRun {
  const ChallengeRun({required this.score, this.submitted = false});

  final int score;
  final bool submitted;

  /// Why the run cannot count, or null when it can
  String? get rejection => isPossibleScore(score) ? null: "score $score is over $selectableButtonCount";

  /// Unsent and valid, so a lower run must not replace it
  bool get isOpen => !submitted && rejection == null;

  ChallengeRun asSubmitted() => ChallengeRun(score: score, submitted: true);

  Future<void> write(SharedPreferences prefs) =>
    prefs.setString(pendingRunKey, jsonEncode({"score": score, "submitted": submitted}));

  static ChallengeRun? read(SharedPreferences prefs) {
    try {
      final json = jsonDecode(prefs.getString(pendingRunKey) ?? "null");
      if (json is! Map) return null;
      return ChallengeRun(score: json["score"] as int, submitted: json["submitted"] as bool);
    } catch (e) {
      "Unreadable pending run: $e".debugPrint();
      return null;
    }
  }
}

/// The score a run must beat: the shown best, the stored best and an unsent pending run
Future<int> bestToBeat(int shownBest) async {
  final prefs = await SharedPreferences.getInstance();
  final pending = ChallengeRun.read(prefs);
  return [shownBest, storedBestScore(prefs), if (pending != null && pending.isOpen) pending.score]
    .reduce((a, b) => a > b ? a : b);
}

/// A new best only if valid and above everything held; a rejected run is logged
Future<bool> isNewBestRun(ChallengeRun run, int shownBest) async {
  final rejection = run.rejection;
  if (rejection != null) {
    "Run rejected: $rejection".debugPrint();
    return false;
  }
  return run.score > await bestToBeat(shownBest);
}

/// Save a new best run, then submit it. A failed submission stays pending for the resend.
/// Never lowers the stored best or replaces a higher unsent run
Future<void> saveAndSubmitBestRun(ChallengeRun run, bool isGamesSignIn) async {
  if (!await isNewBestRun(run, 0)) {
    "Run ${run.score} not saved: not above the stored or pending best".debugPrint();
    return;
  }
  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt('bestScore', run.score);
  await run.write(prefs);
  if (await gamesSubmitScore(run.score, isGamesSignIn)) await run.asSubmitted().write(prefs);
}

/// Wait after the home screen's launch work before the resend, as for the price prefetch
const Duration pendingResendDelay = Duration(seconds: 3);
Future<void>? _launchResend;

/// Once per process, a delay after launch work. The sign-in state is read when it fires
Future<void> resendPendingRunAfterLaunch(bool Function() isGamesSignIn) =>
  _launchResend ??= Future.delayed(pendingResendDelay, () => resendPendingRun(isGamesSignIn()));

@visibleForTesting
void resetLaunchResend() => _launchResend = null;

/// Resend the pending run, only while it is valid, unsent and still the stored best.
/// Never starts a sign-in: signed out, it does nothing. No record, no platform call
Future<void> resendPendingRun(bool isGamesSignIn) async {
  final prefs = await SharedPreferences.getInstance();
  final run = ChallengeRun.read(prefs);
  if (run == null || run.submitted) return;
  final reason = run.rejection ?? (run.score != storedBestScore(prefs) ? "not the stored best": null);
  if (reason != null) {
    "Pending run ${run.score} not resent: $reason".debugPrint();
    return;
  }
  final isSignedIn = isGamesSignIn || await silentSignInCheck()
    .timeout(gamesSignInWait, onTimeout: () => false).catchError((_) => false);
  if (!isSignedIn) {
    "Pending run ${run.score} not resent: signed out".debugPrint();
    return;
  }
  "Resending pending run ${run.score}".debugPrint();
  if (await gamesSubmitScore(run.score, true)) await run.asSubmitted().write(prefs);
}

// --- Score Submission ---
/// Submit a score to the Android and iOS leaderboards. True only once the store accepted it
Future<bool> gamesSubmitScore(int value, bool isGamesSignIn) async {
  if (!isPossibleScore(value)) return false;
  Future<bool> submit() async {
    final isSignedIn = isGamesSignIn || await gamesSignIn(false);
    if (!isSignedIn) return false;
    "gamesSubmitScore".debugPrint();
    await Leaderboards.submitScore(
      score: Score(
        androidLeaderboardID: dotenv.get("ANDROID_LEADERBOARD_ID"),
        iOSLeaderboardID: dotenv.get("IOS_LEADERBOARD_ID"),
        value: value,
      ),
    );
    "Success submitting leaderboard: $value".debugPrint();
    return true;
  }
  try {
    return await submit().timeout(gamesSubmitTimeout);
  } catch (e) {
    'Error submitting score: $e'.debugPrint();
    return false;
  }
}

// --- Leaderboard Display ---
// Show the platform leaderboard after an authentication check
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
// Compare local and server best scores, update local storage if needed
Future<int> getBestScore(bool isGamesSignIn) async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final savedBestScore = storedBestScore(prefs);
  "savedBestScore: $savedBestScore".debugPrint();
  final isSignedIn = (isGamesSignIn) ? isGamesSignIn: await gamesSignIn(isGamesSignIn);
  if (isSignedIn) {
    try {
      final gamesBestScore = await Player.getPlayerScore(
        androidLeaderboardID: dotenv.get("ANDROID_LEADERBOARD_ID"),
        iOSLeaderboardID: dotenv.get("IOS_LEADERBOARD_ID"),
      ) ?? savedBestScore;
      "gamesBestScore: $gamesBestScore".debugPrint();
      // Over the cap it was not earned: neither copied locally nor returned
      if (!isPossibleScore(gamesBestScore)) {
        "bestScore: $savedBestScore (leaderboard $gamesBestScore ignored)".debugPrint();
        return savedBestScore;
      } else if (gamesBestScore > savedBestScore) {
        'bestScore'.setSharedPrefInt(prefs, gamesBestScore);
        "bestScore: $gamesBestScore".debugPrint();
        return gamesBestScore;
      } else {
        // The larger, as both sides now hold. No resend: only a finished run submits
        "bestScore: $savedBestScore".debugPrint();
        return savedBestScore;
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
// Check internet connectivity for game services via DNS lookup
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
