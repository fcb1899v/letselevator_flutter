// =============================
// TtsManager: Text-to-Speech Management
//
// This class handles text-to-speech functionality with:
// 1. Language Configuration: Multi-language TTS support
// 2. Voice Settings: Platform-specific voice configurations
// 3. TTS Operations: Playback control and initialization
// =============================

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'extension.dart';

class TtsManager {

  final BuildContext context;
  TtsManager({required this.context});

  final FlutterTts flutterTts = FlutterTts();

  // --- TTS Configuration ---
  // Language setting for text-to-speech
  String ttsLang() =>
    (context.lang() != "en") ? context.lang(): "en";
  
  // Voice locale setting for TTS
  String ttsVoice() =>
    (context.lang() == "ja") ? "ja-JP":
    (context.lang() == "ko") ? "ko-KR":
    (context.lang() == "zh") ? "zh-CN":
    "en-US";
  
  // Platform-specific voice name configuration
  String voiceName(bool isAndroid) =>
    isAndroid ? (
        context.lang() == "ja" ? "ja-JP-language":
        context.lang() == "ko" ? "ko-KR-language":
        context.lang() == "zh" ? "ko-CN-language":
        "en-US-language"
    ): (
        context.lang() == "ja" ? "Kyoko":
        context.lang() == "ko" ? "Yuna":
        context.lang() == "zh" ? "Lili":
        "Samantha"
    );

  // --- TTS Operations ---
  // Play text-to-speech with sound control
  Future<void> speakText(String text, bool isSoundOn) async {
    if (isSoundOn) {
      await flutterTts.stop();
      await flutterTts.speak(text);
      text.debugPrint();
    }
  }

  // Stop text-to-speech playback
  Future<void> stopTts() async {
    await flutterTts.stop();
    "Stop TTS".debugPrint();
  }

  // Initialize text-to-speech with platform-specific settings
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
    if (context.mounted) await flutterTts.setLanguage(ttsLang());
    if (context.mounted) {
      await flutterTts.setVoice({
        "name": voiceName(Platform.isAndroid),
        "locale": ttsVoice()
      });
    }
    await flutterTts.setSpeechRate(0.5);
    if (context.mounted) voiceName(Platform.isAndroid).debugPrint();
    if (context.mounted) speakText(context.pushNumber(), true);
  }
} 