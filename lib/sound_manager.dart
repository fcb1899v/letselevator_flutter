import 'dart:io';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'extension.dart';

/// For TTS
class TtsManager {

  final BuildContext context;
  TtsManager({required this.context});

  final FlutterTts flutterTts = FlutterTts();

  Future<void> speakText(String text, bool isSoundOn) async {
    if (isSoundOn) {
      await flutterTts.stop();
      await flutterTts.speak(text);
      text.debugPrint();
    }
  }

  Future<void> stopTts() async {
    await flutterTts.stop();
    "Stop TTS".debugPrint();
  }

  Future<void> initTts() async {
    await flutterTts.setSharedInstance(true);
    await flutterTts.setIosAudioCategory(
        IosTextToSpeechAudioCategory.playback,
        [
          IosTextToSpeechAudioCategoryOptions.allowBluetooth,
          IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
          IosTextToSpeechAudioCategoryOptions.mixWithOthers,
          IosTextToSpeechAudioCategoryOptions.defaultToSpeaker
        ]
    );
    await flutterTts.setVolume(1);
    if (context.mounted) await flutterTts.setLanguage(context.ttsLang());
    if (context.mounted) {
      await flutterTts.setVoice({
        "name": context.voiceName(Platform.isAndroid),
        "locale": context.ttsVoice()
      });
    }
    await flutterTts.setSpeechRate(0.5);
    if (context.mounted) context.voiceName(Platform.isAndroid).debugPrint();
    if (context.mounted) speakText(context.pushNumber(), true);
  }
}

/// For Audio
class AudioManager {

  final List<AudioPlayer> audioPlayers;

  static const audioPlayerNumber = 1;
  AudioManager() : audioPlayers = List.generate(audioPlayerNumber, (_) => AudioPlayer());
  PlayerState playerState(int index) => audioPlayers[index].state;
  String playerTitle(int index) => "${["warning", "left train", "right train", "emergency", "effectSound"][index]}Player";

  Future<void> playLoopSound({
    required int index,
    required String asset,
    required double volume,
  }) async {
    final player = audioPlayers[index];
    await player.setVolume(volume);
    await player.setReleaseMode(ReleaseMode.loop);
    await player.play(AssetSource(asset));
    "Loop ${playerTitle(index)}: ${audioPlayers[index].state}".debugPrint();
  }

  Future<void> playEffectSound({
    required int index,
    required String asset,
    required double volume,
  }) async {
    final player = audioPlayers[index];
    await player.setVolume(volume);
    await player.setReleaseMode(ReleaseMode.release);
    await player.play(AssetSource(asset));
    "Play effect sound: ${audioPlayers[index].state}".debugPrint();
  }

  Future<void> stopSound(int index) async {
    await audioPlayers[index].stop();
    "Stop ${playerTitle(index)}: ${audioPlayers[index].state}".debugPrint();
  }

  Future<void> stopAll() async {
    for (final player in audioPlayers) {
      try {
        if (player.state == PlayerState.playing) {
          await player.stop();
          "Stop all players".debugPrint();
        }
      } catch (_) {}
    }
  }
}