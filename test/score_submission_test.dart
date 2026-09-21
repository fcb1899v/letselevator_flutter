// Leaderboard submission: only a valid run is sent, and a failure is resent after launch or next finish.
// games_services is a mock channel; no Game Center or Play.

import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:letselevator/constant.dart';
import 'package:letselevator/games_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _channel = MethodChannel("games_services");

/// Every channel call, the submitted scores, and what the mock answers
final List<String> _calls = [];
final List<int> _submitted = [];
bool _submitSucceeds = true;
int? _leaderboardBest;

ChallengeRun _run(int score) => ChallengeRun(score: score);

Future<void> _signedInSync() => syncGamesAfterLaunch(
  onSignIn: (_) {}, onBestScore: (_) {}, signIn: () async => true);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    _calls.clear();
    _submitted.clear();
    resetLaunchResend();
    resetGamesSignIn();
    _submitSucceeds = true;
    _leaderboardBest = null;
    // Signed out unless a test says otherwise; this check never shows sign-in UI
    silentSignInCheck = () async => false;
    // A started sign-in is recorded as the channel's "signIn", as the plugin would receive it
    nativeGamesSignIn = () async {
      _calls.add("signIn");
      return false;
    };
    // Placeholder ids: the mock ignores them, and no real .env is read
    dotenv.loadFromString(envString: "ANDROID_LEADERBOARD_ID=test\nIOS_LEADERBOARD_ID=test");
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(_channel, (call) async {
      _calls.add(call.method);
      switch (call.method) {
        case "submitScore":
          if (!_submitSucceeds) throw PlatformException(code: "failed_to_send_score");
          _submitted.add((call.arguments as Map)["value"] as int);
          return "success";
        case "getPlayerScore":
          return _leaderboardBest;
      }
      return null;
    });
  });
  tearDown(() => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
    .setMockMethodCallHandler(_channel, null));

  test("the cap is the selectable button count, 1049", () {
    expect(selectableButtonCount, 1049);
  });

  group("validation", () {
    test("a run that took 60 s (a stalled timer) is a new best: no time is checked", () async {
      SharedPreferences.setMockInitialValues({"bestScore": 100});
      // The record holds no timestamps, so the 60.1 s run seen on the simulator counts
      expect(_run(120).rejection, isNull);
      expect(await isNewBestRun(_run(120), 100), isTrue);
      await saveAndSubmitBestRun(_run(120), true);
      expect((await SharedPreferences.getInstance()).getInt("bestScore"), 120);
      expect(_submitted, [120]);
    });
    test("a score over 1049 is rejected, and never reaches the channel", () async {
      SharedPreferences.setMockInitialValues({"bestScore": 100});
      expect(_run(1050).rejection, isNotNull);
      expect(await isNewBestRun(_run(1050), 100), isFalse);
      await saveAndSubmitBestRun(_run(1050), true);
      expect(await gamesSubmitScore(1050, true), isFalse);
      expect(_submitted, isEmpty);
      expect((await SharedPreferences.getInstance()).getInt("bestScore"), 100);
    });
  });

  group("submission", () {
    test("a successful finish leaves nothing pending", () async {
      SharedPreferences.setMockInitialValues({"bestScore": 100});
      await saveAndSubmitBestRun(_run(120), true);
      final prefs = await SharedPreferences.getInstance();
      expect(_submitted, [120]);
      expect(prefs.getInt("bestScore"), 120);
      expect(ChallengeRun.read(prefs)?.submitted, isTrue);
    });

    test("a failed finish stays pending and is resent a delay after launch, once", () async {
      SharedPreferences.setMockInitialValues({"bestScore": 100});
      _submitSucceeds = false;
      await saveAndSubmitBestRun(_run(120), true);
      final prefs = await SharedPreferences.getInstance();
      expect(ChallengeRun.read(prefs)?.submitted, isFalse);
      expect(_submitted, isEmpty);

      _submitSucceeds = true;
      _leaderboardBest = 90;
      await _signedInSync();
      expect(_submitted, isEmpty, reason: "the launch sync itself never submits");
      final resend = resendPendingRunAfterLaunch(() => true);
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(_submitted, isEmpty, reason: "not before the delay");
      await resend;
      expect(_submitted, [120]);
      expect(ChallengeRun.read(prefs)?.submitted, isTrue);
      // Once per process, and a submitted record is never sent again
      await resendPendingRunAfterLaunch(() => true);
      await resendPendingRun(true);
      expect(_submitted, [120]);
    });

    test("with no pending record the resend makes no call at all", () async {
      SharedPreferences.setMockInitialValues({"bestScore": 100});
      var checked = false;
      silentSignInCheck = () async => checked = true;
      await resendPendingRun(false);
      expect(_calls, isEmpty, reason: "no sign-in, no submission");
      expect(checked, isFalse);
    });

    test("signed out, the resend never starts a sign-in", () async {
      SharedPreferences.setMockInitialValues({"bestScore": 120});
      await _run(120).write(await SharedPreferences.getInstance());
      await resendPendingRun(false);
      expect(_calls, isNot(contains("signIn")));
      expect(_submitted, isEmpty);
      expect(ChallengeRun.read(await SharedPreferences.getInstance())?.submitted, isFalse);
    });

    test("already signed in per the silent check, the resend submits without a sign-in call", () async {
      SharedPreferences.setMockInitialValues({"bestScore": 120});
      await _run(120).write(await SharedPreferences.getInstance());
      silentSignInCheck = () async => true;
      await resendPendingRun(false);
      expect(_calls, isNot(contains("signIn")));
      expect(_submitted, [120]);
    });

    test("the next finish resends a pending run that is still the best", () async {
      SharedPreferences.setMockInitialValues({"bestScore": 100});
      _submitSucceeds = false;
      await saveAndSubmitBestRun(_run(120), true);
      _submitSucceeds = true;
      // A lower run finishes: buttons.dart resends instead of saving it
      expect(await isNewBestRun(_run(50), 120), isFalse);
      await resendPendingRun(true);
      expect(_submitted, [120]);
    });

    test("an unsent 800 is not overwritten by a 600 run when the leaderboard holds 500", () async {
      SharedPreferences.setMockInitialValues({"bestScore": 700});
      _submitSucceeds = false;
      await saveAndSubmitBestRun(_run(800), true);
      final prefs = await SharedPreferences.getInstance();
      _submitSucceeds = true;
      _leaderboardBest = 500;
      // The page's best comes from getBestScore: the larger, not the leaderboard's 500
      final shown = await getBestScore(true);
      expect(shown, 800);
      // Even against a stale 500 on screen, the stored and pending 800 win
      expect(await isNewBestRun(_run(600), 500), isFalse);
      await saveAndSubmitBestRun(_run(600), true);
      expect(prefs.getInt("bestScore"), 800, reason: "the stored best never goes down");
      expect(ChallengeRun.read(prefs)?.score, 800, reason: "the pending run is kept");
      expect(_submitted, isEmpty, reason: "600 is not sent");
      await resendPendingRun(true);
      expect(_submitted, [800]);
    });

    test("a pending run that is no longer the stored best is not resent", () async {
      SharedPreferences.setMockInitialValues({"bestScore": 100});
      _submitSucceeds = false;
      await saveAndSubmitBestRun(_run(120), true);
      _submitSucceeds = true;
      // The leaderboard holds more, and getBestScore copies it down
      _leaderboardBest = 300;
      await getBestScore(true);
      await resendPendingRun(true);
      expect(_submitted, isEmpty);
    });

    test("an invalid pending record is not resent", () async {
      SharedPreferences.setMockInitialValues({"bestScore": 1050});
      await _run(1050).write(await SharedPreferences.getInstance());
      await resendPendingRun(true);
      expect(_submitted, isEmpty);
    });

    test("a stored best edited with no pending record is never submitted", () async {
      SharedPreferences.setMockInitialValues({"bestScore": 900});
      _leaderboardBest = 100;
      await _signedInSync();
      await resendPendingRun(true);
      expect(_submitted, isEmpty, reason: "the launch does not resend the local best");
    });
  });

  group("shared sign-in", () {
    test("two callers at once start one native sign-in and get the same answer", () async {
      var starts = 0;
      final answer = Completer<bool>();
      nativeGamesSignIn = () {
        starts++;
        return answer.future;
      };
      final first = gamesSignIn(false);
      final second = gamesSignIn(false);
      answer.complete(true);
      expect(await Future.wait([first, second]), [true, true]);
      expect(starts, 1);
    });

    testWidgets("a native answer after the 10 s bound still reaches the launch sync", (tester) async {
      SharedPreferences.setMockInitialValues({"bestScore": 100});
      _leaderboardBest = 300;
      var starts = 0;
      final answer = Completer<bool>();
      nativeGamesSignIn = () {
        starts++;
        return answer.future;
      };
      final signIns = <bool>[];
      final bests = <int>[];
      bool? pageAnswer;
      // The launch sync and a page both wait on the one attempt, with the real bounds
      syncGamesAfterLaunch(onSignIn: signIns.add, onBestScore: bests.add);
      gamesSignIn(false).then((v) => pageAnswer = v);
      await tester.pump(gamesSignInWait + const Duration(seconds: 1));
      expect(pageAnswer, isFalse, reason: "the page stopped waiting at 10 s");
      expect(signIns, isEmpty);
      answer.complete(true);
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pump();
      expect(starts, 1);
      expect(signIns, [true], reason: "the late answer is applied");
      expect(bests, [300]);
    });
  });

  group("launch sync", () {
    test("a sign-in answering after the wait is still applied, with the leaderboard best", () async {
      SharedPreferences.setMockInitialValues({"bestScore": 100});
      _leaderboardBest = 300;
      final answer = Completer<bool>();
      final signIns = <bool>[];
      final bests = <int>[];
      await syncGamesAfterLaunch(onSignIn: signIns.add, onBestScore: bests.add,
        timeout: const Duration(milliseconds: 10), signIn: () => answer.future);
      expect(signIns, isEmpty, reason: "the wait gave up");
      answer.complete(true);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(signIns, [true]);
      expect(bests, [300], reason: "the higher leaderboard best raises the provider");
    });
  });

  group("leaderboard copy", () {
    test("a leaderboard best over the cap is neither copied nor returned", () async {
      SharedPreferences.setMockInitialValues({"bestScore": 100});
      _leaderboardBest = 5000;
      expect(await getBestScore(true), 100);
      expect((await SharedPreferences.getInstance()).getInt("bestScore"), 100);
    });

    test("a leaderboard best within the cap is still copied, and returned", () async {
      SharedPreferences.setMockInitialValues({"bestScore": 100});
      _leaderboardBest = 1049;
      expect(await getBestScore(true), 1049);
      expect((await SharedPreferences.getInstance()).getInt("bestScore"), 1049);
    });
  });

  group("stored best over the cap", () {
    test("reads as 0, and the key is kept", () async {
      SharedPreferences.setMockInitialValues({"bestScore": 5000});
      final prefs = await SharedPreferences.getInstance();
      expect(storedBestScore(prefs), 0);
      expect(prefs.getInt("bestScore"), 5000);
      expect(hadBulkUnlock(savedBestScore: storedBestScore(prefs), shapeLocks: [true, true]), isFalse,
        reason: "an unearned score does not grant the old bulk unlock");
    });

    test("a valid run beats it, since it counts as 0", () async {
      SharedPreferences.setMockInitialValues({"bestScore": 5000});
      expect(await isNewBestRun(_run(10), 0), isTrue);
    });
  });
}
