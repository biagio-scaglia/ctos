import 'package:audioplayers/audioplayers.dart';

class AudioService {
  static final _player = AudioPlayer();
  static bool _enabled = true;

  static void setEnabled(bool val) => _enabled = val;

  static Future<void> playScanStart() => _play('scan_start.wav');
  static Future<void> playScanComplete() => _play('scan_complete.wav');
  static Future<void> playBeep() => _play('beep.wav');
  static Future<void> playAlert() => _play('alert.wav');
  static Future<void> playThreatFound() => _play('threat_found.wav');
  static Future<void> playVpnDetected() => _play('vpn_detected.wav');
  static Future<void> playNavClick() => _play('nav_click.wav');

  static Future<void> _play(String filename) async {
    if (!_enabled) return;
    try {
      await _player.play(AssetSource('sounds/$filename'));
    } catch (_) {
      // Audio files may not exist in dev — fail silently
    }
  }

  static Future<void> dispose() => _player.dispose();
}
