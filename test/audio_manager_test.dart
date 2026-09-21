// AudioManager: stopAudio is safe before any player exists, the warm-up loads the first
// sound once, and new sounds start only while visible (inactive counts). The player is fake.

import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:letselevator/audio_manager.dart';
import 'package:letselevator/constant.dart';

/// Records calls in order; a load waits on [loadGate] while it is set
class _FakePlayer extends Fake implements AudioPlayer {
  final List<String> calls = [];
  Completer<void>? loadGate;

  @override
  bool get playing => false;
  @override
  PlayerState get playerState => PlayerState(false, ProcessingState.ready);
  @override
  Future<void> stop() async => calls.add("stop");
  @override
  Future<void> setVolume(double volume) async => calls.add("setVolume");
  @override
  Future<Duration?> setAsset(String assetPath, {bool preload = true, String? package, Duration? initialPosition, dynamic tag}) async {
    calls.add("setAsset $assetPath");
    await loadGate?.future;
    calls.add("loaded $assetPath");
    return null;
  }
  @override
  Future<void> play() async => calls.add("play");
}

void _setLifecycle(AppLifecycleState state) =>
  TestWidgetsFlutterBinding.instance.handleAppLifecycleStateChanged(state);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _FakePlayer player;
  var created = 0;

  setUp(() {
    _setLifecycle(AppLifecycleState.resumed);
    player = _FakePlayer();
    created = 0;
    AudioManager.createPlayer = () {
      created++;
      return player;
    };
  });
  tearDown(() => AudioManager.createPlayer = AudioPlayer.new);

  test("stopAudio with no player returns quietly", () async {
    final logs = <String>[];
    await runZoned(() => AudioManager().stopAudio(),
      zoneSpecification: ZoneSpecification(print: (_, _, _, line) => logs.add(line)));
    expect(logs.where((l) => l.contains("Stop audio failed")), isEmpty);
    expect(created, 0);
    // Control: the log capture does catch a print in this zone
    // ignore: avoid_print
    runZoned(() => print("Stop audio failed: probe"),
      zoneSpecification: ZoneSpecification(print: (_, _, _, line) => logs.add(line)));
    expect(logs, ["Stop audio failed: probe"]);
  });

  test("hidden or paused, a sound neither loads nor plays", () async {
    for (final state in [AppLifecycleState.inactive, AppLifecycleState.hidden, AppLifecycleState.paused]) {
      _setLifecycle(state);
      if (state == AppLifecycleState.inactive) continue;
      await AudioManager().playEffectSound(asset: openSound, volume: 1.0);
      expect(player.calls, isEmpty, reason: "$state");
    }
    // Control: the same call while visible plays
    _setLifecycle(AppLifecycleState.hidden);
    _setLifecycle(AppLifecycleState.inactive);
    _setLifecycle(AppLifecycleState.resumed);
    await AudioManager().playEffectSound(asset: openSound, volume: 1.0);
    expect(player.calls.last, "play");
  });

  test("inactive (visible but unfocused: split screen, notification shade) still plays", () async {
    _setLifecycle(AppLifecycleState.inactive);
    await AudioManager().playEffectSound(asset: openSound, volume: 1.0);
    expect(player.calls.last, "play");
  });

  test("hidden while the sound loads, it stops before play", () async {
    player.loadGate = Completer<void>();
    final sound = AudioManager().playEffectSound(asset: openSound, volume: 1.0);
    await Future<void>.delayed(Duration.zero);
    _setLifecycle(AppLifecycleState.inactive);
    _setLifecycle(AppLifecycleState.hidden);
    player.loadGate!.complete();
    await sound;
    expect(player.calls, ["setVolume", "setAsset $openSound", "loaded $openSound"]);
  });

  test("the warm-up creates the player and loads selectSound, once", () async {
    final audio = AudioManager();
    await Future.wait([audio.warmUp(selectSound), audio.warmUp(selectSound)]);
    expect(created, 1);
    expect(player.calls, ["setAsset $selectSound", "loaded $selectSound"]);
  });

  test("a sound played during the warm-up waits for its load, then loads its own", () async {
    player.loadGate = Completer<void>();
    final audio = AudioManager();
    unawaited(audio.warmUp(selectSound));
    final sound = audio.playEffectSound(asset: openSound, volume: 1.0);
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(player.calls, ["setAsset $selectSound"], reason: "the sound has not started a second load");
    player.loadGate!.complete();
    player.loadGate = null;
    await sound;
    expect(player.calls, [
      "setAsset $selectSound", "loaded $selectSound",
      "setVolume", "setAsset $openSound", "loaded $openSound", "play",
    ]);
    expect(created, 1);
  });

  test("past the bound a sound stops waiting on the warm-up", () async {
    player.loadGate = Completer<void>();
    final audio = AudioManager();
    unawaited(audio.warmUp(selectSound));
    final wait = Stopwatch()..start();
    final sound = audio.playEffectSound(asset: openSound, volume: 1.0);
    // Its own load is held too, so read the calls once it has moved past the wait
    await Future<void>.delayed(AudioManager.warmUpWait + const Duration(milliseconds: 200));
    expect(player.calls, ["setAsset $selectSound", "setVolume", "setAsset $openSound"]);
    expect(wait.elapsed, greaterThanOrEqualTo(AudioManager.warmUpWait));
    player.loadGate!.complete();
    await sound;
    expect(player.calls.last, "play");
  });

  test("with a player already made by a sound, the warm-up loads nothing", () async {
    final audio = AudioManager();
    await audio.playEffectSound(asset: openSound, volume: 1.0);
    final before = List.of(player.calls);
    await audio.warmUp(selectSound);
    expect(player.calls, before, reason: "a load now would cut the sound playing");
    expect(before, contains("setAsset $openSound"), reason: "control: the sound did load");
    expect(created, 1);
  });
}
