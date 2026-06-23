import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Singleton managing background music: play/pause, volume, on/off toggle.
/// Call [init] once at app startup.
class AudioService {
  AudioService._();
  static final AudioService instance = AudioService._();

  final AudioPlayer _player = AudioPlayer();
  bool _initialised = false;
  double _volume = 0.25;
  bool _musicEnabled = true;

  double get volume => _volume;
  bool get musicEnabled => _musicEnabled;

  Future<void> init() async {
    if (_initialised) return;
    _initialised = true;

    final prefs = await SharedPreferences.getInstance();
    _volume = prefs.getDouble('bg_volume') ?? 0.25;
    _musicEnabled = prefs.getBool('music_enabled') ?? true;

    await _player.setReleaseMode(ReleaseMode.loop);
    await _player.setVolume(_musicEnabled ? _volume : 0.0);

    if (_musicEnabled) {
      await _player.play(AssetSource('audio/bg_audio.mpeg'));
    }
  }

  Future<void> pause() => _player.pause();
  Future<void> resume() async {
    if (_musicEnabled) await _player.resume();
  }

  /// Toggle music on/off, persists the preference.
  Future<void> setMusicEnabled(bool enabled) async {
    _musicEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('music_enabled', enabled);

    if (enabled) {
      await _player.setVolume(_volume);
      await _player.resume();
    } else {
      await _player.setVolume(0.0);
      await _player.pause();
    }
  }

  /// Set volume 0.0–1.0 and persist.
  Future<void> setVolume(double v) async {
    _volume = v.clamp(0.0, 1.0);
    if (_musicEnabled) await _player.setVolume(_volume);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('bg_volume', _volume);
  }

  Future<void> dispose() async {
    await _player.stop();
    await _player.dispose();
  }
}
