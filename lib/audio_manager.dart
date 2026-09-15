import 'package:flutter/widgets.dart';
import 'package:just_audio/just_audio.dart';
import 'constant.dart';
import 'extension.dart';

// ===== AudioManager: just_audio wrapper for SFX =====
/// Manages short sound effect playback; lazy player, each play stops the previous one
class AudioManager {
  /// Lazily created audio player instance for short SFX playback
  AudioPlayer? _audioPlayer;

  /// Builds the player; tests replace it to hold a load
  @visibleForTesting
  static AudioPlayer Function() createPlayer = AudioPlayer.new;

  /// Initialize the audio player lazily; created once and reused
  Future<void> _initializePlayer() async => _audioPlayer ??= createPlayer();

  /// Longest a sound waits on an in-flight warm-up
  static const Duration warmUpWait = Duration(seconds: 2);
  Future<void>? _warmUp;

  /// Creates the player and loads asset in the background, once. Skipped if a sound
  /// already made the player: loading now would cut what is playing
  Future<void> warmUp(String asset) => _warmUp ??= (_audioPlayer != null) ? Future.value(): _load(asset);

  Future<void> _load(String asset) async {
    try {
      await _initializePlayer();
      await _audioPlayer!.setAsset(asset);
    } catch (e) {
      'Audio warm-up failed for $asset: $e'.debugPrint();
    }
  }

  /// New sounds start only while the app is visible (inactive counts); a skip is logged
  static bool _isForeground(String asset) {
    final state = WidgetsBinding.instance.lifecycleState;
    if (!notVisibleStates.contains(state)) return true;
    'Sound skipped, app is $state: $asset'.debugPrint();
    return false;
  }

  /// Play an effect sound from a bundled asset at the given volume (0.0 to 1.0)
  Future<void> playEffectSound({
    required String asset,
    required double volume,
  }) async {
    if (!_isForeground(asset)) return;
    try {
      // A load running alongside this one would interrupt it
      await _warmUp?.timeout(warmUpWait, onTimeout: () {});
      await _initializePlayer();
      if (_audioPlayer == null) {
        'Audio player is null'.debugPrint();
        return;
      }
      if (_audioPlayer!.playing) await _audioPlayer!.stop();
      await _audioPlayer!.setVolume(volume);
      await _audioPlayer!.setAsset(asset);
      // The app may have been hidden while this loaded
      if (!_isForeground(asset)) return;
      await _audioPlayer!.play();
      'Play $asset: ${_audioPlayer!.playerState}'.debugPrint();
    } catch (e) {
      'Play sound failed for $asset: $e'.debugPrint();
    }
  }

  /// Stop playback; safe to call when nothing is playing or no player exists yet
  Future<void> stopAudio() async {
    final player = _audioPlayer;
    if (player == null) return;
    try {
      if (player.playing) {
        await player.stop();
        'Stop audio: ${player.playerState}'.debugPrint();
      }
    } catch (e) {
      'Stop audio failed: $e'.debugPrint();
    }
  }
} 