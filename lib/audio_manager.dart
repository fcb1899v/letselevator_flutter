// =============================
// AudioManager: Audio Playback Management
//
// This file manages audio playback functionality including:
// 1. Audio Player Management: Multiple audio player instances
// 2. Sound Playback: Effect sounds and loop sounds
// 3. Audio Control: Play, stop, and volume control
// 4. Player State Management: Track and manage player states
// =============================

import 'package:audioplayers/audioplayers.dart';
import 'extension.dart';

class AudioManager {

  final List<AudioPlayer> audioPlayers;

  static const audioPlayerNumber = 1;
  AudioManager() : audioPlayers = List.generate(audioPlayerNumber, (_) => AudioPlayer());
  
  // --- Audio Player Management ---
  // Get player state for specific index
  PlayerState playerState(int index) => audioPlayers[index].state;
  
  // Get player title for debugging
  String playerTitle(int index) => "${["warning", "left train", "right train", "emergency", "effectSound"][index]}Player";

  // --- Sound Playback ---
  // Play loop sound with volume control
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

  // Play effect sound with volume control
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

  // --- Audio Control ---
  // Stop specific audio player
  Future<void> stopSound(int index) async {
    await audioPlayers[index].stop();
    "Stop ${playerTitle(index)}: ${audioPlayers[index].state}".debugPrint();
  }

  // Stop all playing audio players
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