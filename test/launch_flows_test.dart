// The home screen's launch work: games sync and price prefetch start after the first frame,
// waiting on nothing. TTS init is not launch work; platform replies are driven by _settle.

import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:letselevator/constant.dart';
import 'package:just_audio/just_audio.dart';
import 'package:letselevator/audio_manager.dart';
import 'package:letselevator/games_manager.dart';
import 'package:letselevator/homepage.dart';
import 'package:letselevator/l10n/app_localizations.dart';
import 'package:letselevator/plan_provider.dart';
import 'package:letselevator/purchase_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _tts = MethodChannel("flutter_tts");
const _justAudio = MethodChannel("com.ryanheise.just_audio.methods");

Future<void> _pumpHome(WidgetTester tester, {bool isPremium = false}) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 2.625;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(ProviderScope(
    overrides: [
      planProvider.overrideWith(() => PlanNotifier(PlanState(isPremium: isPremium))),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: const HomePage(),
    ),
  ));
}

/// Lets queued platform replies arrive, one real turn and a frame at a time
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 30; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 2)));
    await tester.pump();
  }
}

/// A player that is playing and fails to stop
class _StuckPlayer extends Fake implements AudioPlayer {
  var stopCalls = 0;
  @override
  bool get playing => true;
  @override
  Future<void> stop() async {
    stopCalls++;
    throw StateError("stop failed");
  }
  @override
  Future<void> setVolume(double volume) async {}
  @override
  Future<Duration?> setAsset(String assetPath, {bool preload = true, String? package, Duration? initialPosition, dynamic tag}) async => null;
  @override
  Future<void> play() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  var signInStarts = 0;
  var priceFetches = 0;
  late List<String> ttsCalls;
  final loading = find.byType(CircularProgressIndicator);
  int ttsInits() => ttsCalls.where((c) => c == "setSharedInstance").length;

  setUp(() {
    ttsCalls = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(_tts, (call) async {
      ttsCalls.add(call.method);
      return call.method == "getVoices" ? <Object>[] : 1;
    });
    // No audio platform in tests: the player cannot start, as a failed warm-up
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(_justAudio, (call) async =>
      (call.method == "disposeAllPlayers") ? <String, dynamic>{}: throw PlatformException(code: "no_audio"));
    SharedPreferences.setMockInitialValues({});
    PurchaseManager.resetPrice();
    resetGamesSignIn();
    resetLaunchResend();
    signInStarts = 0;
    priceFetches = 0;
    // Game Center / Play Games that never answers
    nativeGamesSignIn = () {
      signInStarts++;
      return Completer<bool>().future;
    };
    PurchaseManager.priceSource = () async {
      priceFetches++;
      return "¥500";
    };
    // The banner asks UMP first: ads may not load. Only the method name is read
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMessageHandler(
      "plugins.flutter.io/google_mobile_ads/ump", (message) async {
        final method = const StandardMessageCodec().readValue(ReadBuffer(message!));
        return (method == "ConsentInformation#canRequestAds")
          ? const StandardMethodCodec().encodeSuccessEnvelope(false)
          : const StandardMethodCodec().encodeErrorEnvelope(code: "0", message: "no UMP in tests");
      },
    );
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(_tts, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(_justAudio, null);
    PurchaseManager.resetPrice();
    resetGamesSignIn();
    resetLaunchResend();
    nativeGamesSignIn = () async => false;
    AudioManager.createPlayer = AudioPlayer.new;
  });

  testWidgets("sign-in and price start at launch; TTS init only after its delay; no overlay", (tester) async {
    await _pumpHome(tester);
    await tester.pump();
    expect(signInStarts, 1, reason: "the sign-in starts at the first frame");
    expect(ttsInits(), 0, reason: "TTS init is not launch work");
    expect(loading, findsNothing, reason: "nothing gates interaction at launch");
    await tester.pump(pricePrefetchDelay - const Duration(milliseconds: 100));
    expect(priceFetches, 0, reason: "the prefetch still waits its own delay");
    expect(ttsInits(), 0);
    await tester.pump(const Duration(milliseconds: 200));
    expect(priceFetches, 1, reason: "not held behind the ${gamesLaunchTimeout.inSeconds} s sign-in bound");
    await _settle(tester);
    expect(ttsInits(), 1, reason: "the background warm-up started TTS init");
    await tester.pump(gamesLaunchTimeout + pendingResendDelay);
    await _settle(tester);
    expect(priceFetches, 1);
    expect(ttsInits(), 1);
  });

  testWidgets("premium: no price prefetch, sign-in and TTS warm-up still start", (tester) async {
    await _pumpHome(tester, isPremium: true);
    await tester.pump(soundWarmUpDelay + const Duration(milliseconds: 100));
    await _settle(tester);
    await tester.pump(gamesLaunchTimeout + pendingResendDelay);
    expect(signInStarts, 1);
    expect(ttsInits(), 1);
    expect(priceFetches, 0);
  });

  testWidgets("a floor tap before the warm-up starts TTS init at once, and only once", (tester) async {
    // A tap vibrates; tests have no vibration plugin
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel("vibration"), (_) async => null);
    addTearDown(() => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel("vibration"), null));
    await _pumpHome(tester);
    await tester.pump();
    expect(ttsInits(), 0);
    // A floor that stops (5 is the default restricted one) and not the current: no speech
    // until the ride starts after its wait, so only the tap itself can start TTS init
    await tester.tap(find.text("3"));
    // The button also takes double taps, so a single tap lands after that timeout
    await tester.pump(kDoubleTapTimeout + const Duration(milliseconds: 50));
    await _settle(tester);
    expect(ttsInits(), 1, reason: "the tap started the shared init");
    // The ride runs on: arrival, doors open and close, each step waiting on platform replies
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(seconds: 5));
      await _settle(tester);
    }
    expect(ttsInits(), 1, reason: "the warm-up joined it instead of starting another");
  });

  testWidgets("inactive keeps sound going; hidden stops TTS even when stopping audio fails", (tester) async {
    final player = _StuckPlayer();
    AudioManager.createPlayer = () => player;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await _pumpHome(tester);
    // The warm-up creates the player
    await tester.pump(soundWarmUpDelay + const Duration(milliseconds: 100));
    await _settle(tester);
    ttsCalls.clear();
    // Visible but unfocused (split screen, notification shade): nothing is stopped
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    await _settle(tester);
    expect(player.stopCalls, 0);
    expect(ttsCalls, isNot(contains("stop")));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    await tester.pump();
    await _settle(tester);
    expect(player.stopCalls, greaterThan(0), reason: "control: audio stop was attempted and failed");
    expect(ttsCalls, contains("stop"));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump(gamesLaunchTimeout + pendingResendDelay);
    await _settle(tester);
  });
}
