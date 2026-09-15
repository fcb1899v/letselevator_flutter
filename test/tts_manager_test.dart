// TTS init runs once, shared by the background warm-up and every speech: a speech waits
// for an init in flight, a failed or overlong init skips that speech, and the launch
// greeting is spoken once when the warm-up is ready, unless the app is in the background.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:letselevator/l10n/app_localizations.dart';
import 'package:letselevator/tts_manager.dart';

const _tts = MethodChannel("flutter_tts");

const _greeting = "speak Please press the button for the desired floor";

/// Built in the foreground: a paused app draws no frames
Future<TtsManager> _manager(WidgetTester tester) async {
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  late BuildContext context;
  await tester.pumpWidget(MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    home: Builder(builder: (c) {
      context = c;
      return const SizedBox();
    }),
  ));
  return TtsManager(context: context);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<String> calls;
  late Completer<void> initGate;
  Completer<void>? stopGate;
  var initFails = false;

  setUp(() {
    calls = [];
    initGate = Completer<void>()..complete();
    initFails = false;
    stopGate = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(_tts, (call) async {
      calls.add(call.method == "speak" ? "speak ${call.arguments}" : call.method);
      if (call.method == "stop") await stopGate?.future;
      if (call.method == "setSharedInstance") {
        await initGate.future;
        if (initFails) throw PlatformException(code: "no_tts");
      }
      return call.method == "getVoices" ? <Object>[] : 1;
    });
  });
  tearDown(() => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(_tts, null));

  int inits() => calls.where((c) => c == "setSharedInstance").length;
  List<String> spoken() => calls.where((c) => c.startsWith("speak")).toList();

  testWidgets("warm-up, a floor tap and speeches share one init", (tester) async {
    final tts = await _manager(tester);
    await tester.runAsync(() async {
      await Future.wait([tts.ensureReady(), tts.warmUp(), tts.speakText("Going up. ", true), tts.ensureReady()]);
      await tts.speakText("Doors opening. ", true);
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    expect(inits(), 1);
    expect(spoken().where((c) => c == _greeting).length, 1,
      reason: "the greeting is spoken once, although TTS was already used");
    expect(spoken().where((c) => c != _greeting), ["speak Going up. ", "speak Doors opening. "]);
  });

  testWidgets("a speech waits for the init in flight, then speaks", (tester) async {
    final tts = await _manager(tester);
    await tester.runAsync(() async {
      // Made in the real zone, so completing it is not left to fake time
      initGate = Completer<void>();
      var isDone = false;
      unawaited(tts.ensureReady());
      final speech = tts.speakText("Going up. ", true).then((_) => isDone = true);
      await Future<void>.delayed(const Duration(milliseconds: 300));
      expect(isDone, isFalse);
      expect(spoken(), isEmpty, reason: "nothing is spoken before init completes");
      initGate.complete();
      await speech;
    });
    expect(spoken(), ["speak Going up. "]);
    expect(inits(), 1);
  });

  testWidgets("a failed init skips the speech without throwing, and is not retried", (tester) async {
    initFails = true;
    final tts = await _manager(tester);
    await tester.runAsync(() async {
      await tts.speakText("Going up. ", true);
      await tts.speakText("Doors opening. ", true);
      await tts.warmUp();
    });
    expect(spoken(), isEmpty);
    expect(inits(), 1, reason: "control: the init was attempted");
  });

  testWidgets("an init past the wait skips that speech; a later one speaks", (tester) async {
    final tts = await _manager(tester);
    await tester.runAsync(() async {
      // Made in the real zone, so completing it is not left to fake time
      initGate = Completer<void>();
      final wait = Stopwatch()..start();
      await tts.speakText("Going up. ", true);
      expect(wait.elapsed, greaterThanOrEqualTo(TtsManager.initWait), reason: "it waited the full bound");
      expect(spoken(), isEmpty);
      initGate.complete();
      await tts.speakText("Doors opening. ", true);
    });
    expect(spoken(), ["speak Doors opening. "]);
    expect(inits(), 1);
  });

  testWidgets("the warm-up greets once TTS is ready", (tester) async {
    final tts = await _manager(tester);
    await tester.runAsync(() async {
      expect(await tts.warmUp(), isTrue);
      // The greeting is not awaited by the warm-up
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    expect(spoken(), [_greeting]);
  });

  testWidgets("hidden, a speech is not started; inactive and resumed speak", (tester) async {
    final tts = await _manager(tester);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.runAsync(() => tts.speakText("Going up. ", true));
    expect(spoken(), ["speak Going up. "], reason: "inactive is still visible (split screen, shade)");
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    calls.clear();
    await tester.runAsync(() => tts.speakText("Doors closing. ", true));
    expect(spoken(), isEmpty);
    expect(calls, isNot(contains("stop")), reason: "a skipped speech does not stop anything either");
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.runAsync(() => tts.speakText("Doors opening. ", true));
    expect(spoken(), ["speak Doors opening. "]);
  });

  testWidgets("a speech waiting on init is skipped if the app was hidden meanwhile", (tester) async {
    final tts = await _manager(tester);
    await tester.runAsync(() async {
      initGate = Completer<void>();
      final speech = tts.speakText("Going up. ", true);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      initGate.complete();
      await speech;
    });
    expect(spoken(), isEmpty);
  });

  testWidgets("hidden while the previous speech is being stopped, the new one is not spoken", (tester) async {
    final tts = await _manager(tester);
    await tester.runAsync(() async {
      await tts.ensureReady();
      stopGate = Completer<void>();
      final speech = tts.speakText("Going up. ", true);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(calls.last, "stop", reason: "control: the speech is held in its stop");
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      stopGate!.complete();
      await speech;
    });
    expect(spoken(), isEmpty);
  });

  testWidgets("in the background the greeting is skipped, not spoken on return", (tester) async {
    final tts = await _manager(tester);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.runAsync(() async {
      expect(await tts.warmUp(), isTrue, reason: "control: TTS itself became ready");
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    expect(spoken(), isEmpty);
    expect(inits(), 1);
  });
}
