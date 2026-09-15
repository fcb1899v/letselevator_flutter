import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'constant.dart';
import 'extension.dart';

// ===== TtsManager: multi-language text-to-speech for the app =====

class TtsManager {
  final BuildContext context;
  TtsManager({required this.context});

  final FlutterTts flutterTts = FlutterTts();

  /// Get TTS locale based on current language
  String ttsLocale() =>
      (context.lang() == "ja") ? "ja-JP":
      (context.lang() == "zh") ? "zh-CN":
      (context.lang() == "ko") ? "ko-KR":
      (context.lang() == "es") ? "es-ES":
      (context.lang() == "fr") ? "fr-FR":
      "en-US";

  /// Get Android voice name
  String androidVoiceName() =>
      (context.lang() == "ja") ? "ja-JP-language":
      (context.lang() == "zh") ? "zh-CN-language":
      (context.lang() == "ko") ? "ko-KR-language":
      (context.lang() == "es") ? "es-ES-language":
      (context.lang() == "fr") ? "fr-FR-language":
      "en-US-language";

  /// Get iOS voice name
  String iOSVoiceName() =>
      (context.lang() == "ja") ? "Kyoko":
      (context.lang() == "zh") ? "婷婷":
      (context.lang() == "ko") ? "유나":
      (context.lang() == "es") ? "Mónica":
      (context.lang() == "fr") ? "Audrey":
      "Samantha";

  /// Get default voice name by platform
  String defaultVoiceName() =>
      (Platform.isIOS || Platform.isMacOS) ? iOSVoiceName(): androidVoiceName();

  /// Set TTS voice
  Future<void> setTtsVoice() async {
    final voices = await flutterTts.getVoices;
    List<dynamic> localFemaleVoices = (Platform.isIOS || Platform.isMacOS) ? voices.where((voice) {
      final isLocalMatch = voice['locale'].toString().contains(context.lang());
      final isFemale = voice['gender'].toString().contains('female');
      return isLocalMatch && isFemale;
    }).toList(): [];
    "localFemaleVoices: $localFemaleVoices".debugPrint();
    if (context.mounted) {
      final isExistDefaultVoice = localFemaleVoices.any((voice) => voice['name'] == defaultVoiceName()) || localFemaleVoices.isEmpty;
      final voiceName = isExistDefaultVoice ? defaultVoiceName(): localFemaleVoices[0]['name'];
      final voiceLocale = isExistDefaultVoice ? ttsLocale(): localFemaleVoices[0]['locale'];
      final result = await flutterTts.setVoice({'name': voiceName, 'locale': voiceLocale,});
      "setVoice: $voiceName, setLocale: $voiceLocale, result: $result".debugPrint();
    }
  }

  /// Longest a speech waits on the first init; past it, that speech is skipped
  static const Duration initWait = Duration(seconds: 3);
  Future<bool>? _ready;
  bool _isInitDone = false;

  Future<bool> get _sharedInit => _ready ??= _initOnce();

  /// Initializes once, shared by every caller; false if it failed
  Future<bool> ensureReady() => _sharedInit;

  Future<bool> _initOnce() async {
    try {
      await initTts();
      return true;
    } catch (e) {
      "TTS init failed: $e".debugPrint();
      return false;
    } finally {
      _isInitDone = true;
    }
  }

  /// Background init after launch, then the greeting once, not awaited.
  /// Skipped, not queued, while the app is not visible (the guard in _speak)
  Future<bool> warmUp() async {
    final isReady = await _sharedInit;
    if (isReady && context.mounted) {
      unawaited(_speak(context.pushNumber()).catchError((Object e) => "TTS greeting failed: $e".debugPrint()));
    }
    return isReady;
  }

  /// Speak text if sound is on, once TTS is ready
  Future<void> speakText(String text, bool isSoundOn) async {
    if (isSoundOn) {
      final wait = _isInitDone ? null: (Stopwatch()..start());
      if (!await ensureReady().timeout(initWait, onTimeout: () => false)) {
        "TTS not ready after ${wait?.elapsedMilliseconds} ms: skipped $text".debugPrint();
        return;
      }
      if (wait != null) "TTS waited ${wait.elapsedMilliseconds} ms for init: $text".debugPrint();
      await _speak(text);
    }
  }

  /// True while the app is visible; a skip is logged
  static bool _isVisible(String text) {
    final state = WidgetsBinding.instance.lifecycleState;
    if (!notVisibleStates.contains(state)) return true;
    "Speech skipped, app is $state: $text".debugPrint();
    return false;
  }

  /// Every speech ends here: a new one starts only while the app is visible
  Future<void> _speak(String text) async {
    if (!_isVisible(text)) return;
    await flutterTts.stop();
    // The app may have been hidden while the previous speech stopped
    if (!_isVisible(text)) return;
    await flutterTts.speak(text);
    text.debugPrint();
  }

  /// Stop TTS
  Future<void> stopTts() async {
    await flutterTts.stop();
    "Stop TTS".debugPrint();
  }

  /// Initialize TTS; callers go through ensureReady so it runs once
  Future<void> initTts() async {
    await flutterTts.setSharedInstance(true);
    if (Platform.isIOS || Platform.isMacOS) {
      await flutterTts.setIosAudioCategory(
          IosTextToSpeechAudioCategory.playback,
          [
            IosTextToSpeechAudioCategoryOptions.allowBluetooth,
            IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
            IosTextToSpeechAudioCategoryOptions.mixWithOthers,
            IosTextToSpeechAudioCategoryOptions.defaultToSpeaker
          ]
      );
    }
    await flutterTts.awaitSpeakCompletion(true);
    await flutterTts.awaitSynthCompletion(true);
    if (context.mounted) await flutterTts.setLanguage(context.lang());
    if (context.mounted) await flutterTts.isLanguageAvailable(context.lang());
    if (context.mounted) await setTtsVoice();
    await flutterTts.setVolume(1);
    await flutterTts.setSpeechRate(0.5);
  }
}