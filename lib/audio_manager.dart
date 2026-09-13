import 'package:just_audio/just_audio.dart';
import 'extension.dart';

// ===== AudioManager: just_audio wrapper for SFX =====
/// Manages short sound effect playback; lazy player, each play stops the previous one
class AudioManager {
  /// Lazily created audio player instance for short SFX playback
  AudioPlayer? _audioPlayer;

  /// Initialize the audio player lazily; created once and reused
  Future<void> _initializePlayer() async => _audioPlayer ??= AudioPlayer();

  /// Play an effect sound from a bundled asset at the given volume (0.0 to 1.0)
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

  /// Stop playback; safe to call when nothing is playing
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