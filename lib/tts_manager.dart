import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'extension.dart';

// =============================
// TtsManager: Text-to-Speech management
// Handles multi-language TTS for the app
// =============================

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

  /// Speak text if sound is on
  Future<void> speakText(String text, bool isSoundOn) async {
    if (isSoundOn) {
      await flutterTts.stop();
      await flutterTts.speak(text);
      text.debugPrint();
    }
  }

  /// Stop TTS
  Future<void> stopTts() async {
    await flutterTts.stop();
    "Stop TTS".debugPrint();
  }

  /// Initialize TTS
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
    if (context.mounted) speakText(context.pushNumber(), true);
  }
}