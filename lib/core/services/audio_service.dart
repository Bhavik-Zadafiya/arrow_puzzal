import 'package:audioplayers/audioplayers.dart';

/// Lightweight singleton that loops background music throughout the game.
///
/// Call [init] once at app startup (fire-and-forget).
/// The player pre-loads the asset so playback begins almost instantly.
class AudioService {
  AudioService._();
  static final AudioService instance = AudioService._();

  final AudioPlayer _player = AudioPlayer();
  bool _initialised = false;

  /// Pre-load + start looping the background track.
  /// Safe to call multiple times — only the first call has any effect.
  Future<void> init() async {
    if (_initialised) return;
    _initialised = true;

    // Loop forever.
    await _player.setReleaseMode(ReleaseMode.loop);

    // Keep volume at a comfortable level so SFX / UI sounds stand out.
    await _player.setVolume(0.5);

    // Play from asset bundle.
    await _player.play(AssetSource('audio/bg_audio.mpeg'));
  }

  /// Pause the music (e.g. when the app goes to background).
  Future<void> pause() => _player.pause();

  /// Resume after a pause.
  Future<void> resume() => _player.resume();

  /// Mute / unmute toggle. Returns the new muted state.
  bool _muted = false;
  bool get isMuted => _muted;

  Future<bool> toggleMute() async {
    _muted = !_muted;
    await _player.setVolume(_muted ? 0.0 : 0.5);
    return _muted;
  }

  /// Full cleanup — call if you ever need to tear down.
  Future<void> dispose() async {
    await _player.stop();
    await _player.dispose();
  }
}
