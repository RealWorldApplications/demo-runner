import 'dart:math';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';

/// Zero-asset procedural WAV synthesizer for Web & mobile game audio.
///
/// Generates 16-bit mono 22.05 kHz PCM WAV buffers in memory at startup so the
/// app ships with zero external `.wav` or `.mp3` assets and tiny bundle size.
class OceanAudio {
  OceanAudio._();

  static final OceanAudio instance = OceanAudio._();

  static const int _sampleRate = 22050;

  bool isMuted = false;
  bool _initialized = false;

  late final Uint8List _swimWav;
  late final Uint8List _pearlWav;
  late final Uint8List _crashWav;

  AudioPlayer? _swimPlayerA;
  AudioPlayer? _swimPlayerB;
  bool _useFirstSwimPlayer = true;
  AudioPlayer? _pearlPlayer;
  AudioPlayer? _crashPlayer;

  /// Synthesizes the in-memory WAV sound effects once.
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    _swimWav = _buildSwimWav();
    _pearlWav = _buildPearlWav();
    _crashWav = _buildCrashWav();
  }

  /// Toggles mute state and returns the updated mute flag.
  bool toggleMute() {
    isMuted = !isMuted;
    return isMuted;
  }

  /// Plays a bubbly hydro-thruster pulse when the mini-sub climbs.
  Future<void> playSwim() async {
    if (isMuted) return;
    await init();
    try {
      final player = _useFirstSwimPlayer
          ? (_swimPlayerA ??= AudioPlayer())
          : (_swimPlayerB ??= AudioPlayer());
      _useFirstSwimPlayer = !_useFirstSwimPlayer;
      await player.setVolume(0.32);
      await player.play(BytesSource(_swimWav, mimeType: 'audio/wav'));
    } catch (_) {
      // Ignore platform audio failures in headless/restricted environments.
    }
  }

  /// Plays a sparkling two-note harmonic chime on pearl collection.
  Future<void> playPearl() async {
    if (isMuted) return;
    await init();
    try {
      final player = _pearlPlayer ??= AudioPlayer();
      await player.setVolume(0.45);
      await player.play(BytesSource(_pearlWav, mimeType: 'audio/wav'));
    } catch (_) {
      // Ignore platform audio failures in headless/restricted environments.
    }
  }

  /// Plays a muffled underwater hull thud when hitting a hazard.
  Future<void> playCrash() async {
    if (isMuted) return;
    await init();
    try {
      final player = _crashPlayer ??= AudioPlayer();
      await player.setVolume(0.55);
      await player.play(BytesSource(_crashWav, mimeType: 'audio/wav'));
    } catch (_) {
      // Ignore platform audio failures in headless/restricted environments.
    }
  }

  Uint8List _buildSwimWav() {
    const durationSec = 0.14;
    final sampleCount = (_sampleRate * durationSec).round();
    final samples = Int16List(sampleCount);
    var phase = 0.0;

    for (var i = 0; i < sampleCount; i++) {
      final t = i / sampleCount;
      final freq = 190.0 + (260.0 * t * t);
      phase += 2 * pi * freq / _sampleRate;
      final envelope = sin(pi * t) * (1.0 - t * 0.25);
      final wobble = 0.8 + 0.2 * sin(2 * pi * 32 * (i / _sampleRate));
      final value = sin(phase) * envelope * wobble * 0.55;
      samples[i] = (value * 32767).round().clamp(-32768, 32767);
    }

    return _encodePcm16Wav(samples);
  }

  Uint8List _buildPearlWav() {
    const durationSec = 0.24;
    final sampleCount = (_sampleRate * durationSec).round();
    final samples = Int16List(sampleCount);

    for (var i = 0; i < sampleCount; i++) {
      final sec = i / _sampleRate;
      final t = i / sampleCount;
      final freq = t < 0.38 ? 587.33 : 880.0; // D5 -> A5
      final envelope = exp(-t * 4.5) * min(1.0, i / 120.0);
      final tone =
          sin(2 * pi * freq * sec) * 0.7 + sin(4 * pi * freq * sec) * 0.25;
      samples[i] = (tone * envelope * 0.55 * 32767).round().clamp(-32768, 32767);
    }

    return _encodePcm16Wav(samples);
  }

  Uint8List _buildCrashWav() {
    const durationSec = 0.35;
    final sampleCount = (_sampleRate * durationSec).round();
    final samples = Int16List(sampleCount);
    final rng = Random(42);
    var phase = 0.0;

    for (var i = 0; i < sampleCount; i++) {
      final t = i / sampleCount;
      final freq = 140.0 * (1.0 - 0.7 * t);
      phase += 2 * pi * freq / _sampleRate;
      final envelope = exp(-t * 5.2);
      final noise = (rng.nextDouble() * 2.0 - 1.0) * 0.45;
      final thud = sin(phase) * 0.75 + noise * (1.0 - t * 0.6);
      samples[i] = (thud * envelope * 0.65 * 32767).round().clamp(-32768, 32767);
    }

    return _encodePcm16Wav(samples);
  }

  Uint8List _encodePcm16Wav(Int16List samples) {
    const headerSize = 44;
    final dataByteLength = samples.length * 2;
    final bytes = ByteData(headerSize + dataByteLength);

    // RIFF chunk descriptor
    _writeAscii(bytes, 0, 'RIFF');
    bytes.setUint32(4, 36 + dataByteLength, Endian.little);
    _writeAscii(bytes, 8, 'WAVE');

    // fmt sub-chunk
    _writeAscii(bytes, 12, 'fmt ');
    bytes.setUint32(16, 16, Endian.little); // PCM subchunk size
    bytes.setUint16(20, 1, Endian.little); // AudioFormat = 1 (PCM)
    bytes.setUint16(22, 1, Endian.little); // NumChannels = 1 (Mono)
    bytes.setUint32(24, _sampleRate, Endian.little);
    bytes.setUint32(28, _sampleRate * 2, Endian.little); // ByteRate
    bytes.setUint16(32, 2, Endian.little); // BlockAlign
    bytes.setUint16(34, 16, Endian.little); // BitsPerSample

    // data sub-chunk
    _writeAscii(bytes, 36, 'data');
    bytes.setUint32(40, dataByteLength, Endian.little);

    for (var i = 0; i < samples.length; i++) {
      bytes.setInt16(headerSize + i * 2, samples[i], Endian.little);
    }

    return bytes.buffer.asUint8List();
  }

  void _writeAscii(ByteData bytes, int offset, String value) {
    for (var i = 0; i < value.length; i++) {
      bytes.setUint8(offset + i, value.codeUnitAt(i));
    }
  }
}
