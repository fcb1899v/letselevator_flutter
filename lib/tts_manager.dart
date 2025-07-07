// =============================
// TtsManager: Text-to-Speech Management
//
// This class handles text-to-speech functionality with:
// 1. Language Configuration: Multi-language TTS support
// 2. Voice Settings: Platform-specific voice configurations
// 3. TTS Operations: Playback control and initialization
// 4. Error Handling: Comprehensive error handling for stability
// 5. Resource Management: Proper cleanup and memory management
// =============================

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/foundation.dart';
import 'extension.dart';

class TtsManager {
  final BuildContext context;
  TtsManager({required this.context});

  final FlutterTts flutterTts = FlutterTts();
  bool _isInitialized = false;

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

  // --- Safe TTS Operations ---
  // Wrapper for safe TTS operations with error handling
  Future<void> safeTtsOperation(Future<void> Function() operation) async {
    try {
      if (!_isInitialized) {
        "TTS not initialized, skipping operation".debugPrint();
        return;
      }
      await operation();
    } catch (e) {
      "TTS operation error: $e".debugPrint();
    }
  }

  // --- TTS Operations ---
  // Play text-to-speech with sound control and error handling
  Future<void> speakText(String text, bool isSoundOn) async {
    if (!isSoundOn || text.isEmpty) return;
    
    await safeTtsOperation(() async {
      await flutterTts.stop();
      await flutterTts.speak(text);
      text.debugPrint();
    });
  }

  // Stop text-to-speech playback with error handling
  Future<void> stopTts() async {
    await safeTtsOperation(() async {
      await flutterTts.stop();
      "Stop TTS".debugPrint();
    });
  }

  // Initialize text-to-speech with platform-specific settings and error handling
  Future<void> initTts() async {
    if (_isInitialized) {
      "TTS already initialized".debugPrint();
      return;
    }
    
    try {
      await flutterTts.setSharedInstance(true);
      
      // iOS specific configuration
      if (Platform.isIOS) {
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
      
      await flutterTts.setVolume(1);
      
      if (context.mounted) {
        await flutterTts.setLanguage(ttsLang());
        await flutterTts.setVoice({
          "name": voiceName(Platform.isAndroid),
          "locale": ttsVoice()
        });
      }
      
      await flutterTts.setSpeechRate(0.5);
      
      if (context.mounted) {
        voiceName(Platform.isAndroid).debugPrint();
        await speakText(context.pushNumber(), true);
      }
      
      _isInitialized = true;
      "TTS initialized successfully".debugPrint();
    } catch (e) {
      "Error initializing TTS: $e".debugPrint();
      _isInitialized = false;
    }
  }

  // --- Resource Management ---
  // Dispose TTS resources to prevent memory leaks
  Future<void> dispose() async {
    try {
      await stopTts();
      await flutterTts.setSharedInstance(false);
      _isInitialized = false;
      "TTS disposed successfully".debugPrint();
    } catch (e) {
      "Error disposing TTS: $e".debugPrint();
    }
  }

  // --- Health Check ---
  // Check if TTS is in a healthy state
  bool isHealthy() {
    return _isInitialized;
  }

  // --- Recovery ---
  // Attempt to recover from TTS errors
  Future<void> recover() async {
    try {
      await stopTts();
      _isInitialized = false;
      // Small delay to allow system to stabilize
      await Future.delayed(const Duration(milliseconds: 100));
      await initTts();
      "TTS recovery completed".debugPrint();
    } catch (e) {
      "Error during TTS recovery: $e".debugPrint();
    }
  }
} 