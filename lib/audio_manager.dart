import 'package:just_audio/just_audio.dart';
import 'extension.dart';

// =============================
// AudioManager: Audio management using just_audio
// - Centralized, lightweight wrapper around just_audio for SFX
// - Lazily initializes a single AudioPlayer instance on first use
// - Exposes simple play/stop APIs with error-safe handling and debug logs
// =============================
/// Manages short sound effect playback across the app.
///
/// Notes:
/// - Player is created lazily on first play via `_initializePlayer()`.
/// - Consecutive plays will stop the current sound before starting the next.
/// - All methods are exception-safe and emit debug logs in debug mode.
class AudioManager {
  /// Lazily created audio player instance for short SFX playback
  AudioPlayer? _audioPlayer;

  /// Initialize audio player (lazy)
  ///
  /// Creates the internal player once and reuses it.
  Future<void> _initializePlayer() async => _audioPlayer ??= AudioPlayer();

  /// Play effect sound
  ///
  /// - [asset]: path to bundled asset declared in pubspec
  /// - [volume]: 0.0 ~ 1.0
  Future<void> playEffectSound({
    required String asset,
    required double volume,
  }) async {
    try {
      await _initializePlayer();
      if (_audioPlayer == null) {
        'Audio player is null'.debugPrint();
        return;
      }
      if (_audioPlayer!.playing) await _audioPlayer!.stop();
      await _audioPlayer!.setVolume(volume);
      await _audioPlayer!.setAsset(asset);
      await _audioPlayer!.play();
      'Play $asset: ${_audioPlayer!.playerState}'.debugPrint();
    } catch (e) {
      'Play sound failed for $asset: $e'.debugPrint();
    }
  }

  /// Stop audio playback
  ///
  /// Safe to call even when nothing is playing.
  Future<void> stopAudio() async {
    try {
      if (_audioPlayer!.playing) {
        await _audioPlayer!.stop();
        'Stop audio: ${_audioPlayer!.playerState}'.debugPrint();
      }
    } catch (e) {
      'Stop audio failed: $e'.debugPrint();
    }
  }
} 