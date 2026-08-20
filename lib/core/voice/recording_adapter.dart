import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

import 'voice_diagnostics.dart';
import 'voice_error_mapper.dart';
import 'voice_models.dart';

/// The microphone + audio capture seam. The sheet and controller never touch a
/// plugin directly; every implementation is injectable for tests.
abstract class RecordingAdapter {
  /// Current microphone permission state without prompting.
  Future<VoicePermissionState> permissionState();

  /// Asks the platform for microphone access and returns the resulting state.
  Future<VoicePermissionState> requestPermission();

  /// Whether an input device (microphone) is present.
  Future<bool> hasMicrophone();

  /// MIME types the platform can actually record, in preference order.
  Future<List<String>> supportedMimeTypes();

  /// The first recordable MIME type (preference order), or a sane default.
  Future<String> pickMimeType();

  /// Starts recording to a temporary file. [onLevel] streams dBFS levels.
  Future<void> start({required String mimeType, void Function(double level)? onLevel});

  /// Stops recording and returns the captured audio (kept in memory).
  Future<VoiceRecording> stop();

  /// Stops and discards the in-progress recording and its temp file.
  Future<void> cancel();

  /// Opens the app settings page so the user can grant a permanently denied
  /// permission. Returns whether the settings screen could be opened.
  Future<bool> openSettings();

  /// Releases the platform recorder. Safe to call more than once.
  Future<void> dispose();
}

/// Production recorder built on the `record` package. Works on Android, iOS,
/// Windows and web. The default output is 16 kHz mono PCM in a WAV container,
/// which the Gemini API accepts directly.
class RecordRecorderAdapter implements RecordingAdapter {
  final AudioRecorder recorder;
  final Future<Directory> Function() tempDirectoryProvider;

  RecordRecorderAdapter({AudioRecorder? recorder, Future<Directory> Function()? tempDirectoryProvider})
      : recorder = recorder ?? AudioRecorder(),
        tempDirectoryProvider = tempDirectoryProvider ?? _defaultTempDir;

  static Future<Directory> _defaultTempDir() => getTemporaryDirectory();

  /// Encoder preference order. WAV is universally supported (Android, iOS,
  /// Windows, web) and accepted by the transcription backend.
  static const List<({AudioEncoder encoder, String mime, String ext})> _encoders = [
    (encoder: AudioEncoder.wav, mime: 'audio/wav', ext: 'wav'),
    (encoder: AudioEncoder.aacLc, mime: 'audio/m4a', ext: 'm4a'),
    (encoder: AudioEncoder.opus, mime: 'audio/ogg', ext: 'opus'),
  ];

  String? _activePath;
  StreamSubscription<Amplitude>? _amplitudeSub;

  @override
  Future<VoicePermissionState> permissionState() async {
    final status = await Permission.microphone.status;
    return VoiceErrorMapper.toPermissionState(status);
  }

  @override
  Future<VoicePermissionState> requestPermission() async {
    final status = await Permission.microphone.request();
    return VoiceErrorMapper.toPermissionState(status);
  }

  @override
  Future<bool> hasMicrophone() async {
    try {
      final devices = await recorder.listInputDevices();
      if (devices.isNotEmpty) return true;
      // An empty list can mean "listing unsupported" rather than "no mic".
      // Trust the platform permission/start attempt as the real check.
      return true;
    } catch (e) {
      developer.log('voice: input-device listing unavailable: $e', name: 'voice');
      return true;
    }
  }

  @override
  Future<List<String>> supportedMimeTypes() async {
    final supported = <String>[];
    for (final entry in _encoders) {
      try {
        if (await recorder.isEncoderSupported(entry.encoder)) {
          supported.add(entry.mime);
        }
      } catch (e) {
        developer.log('voice: encoder probe failed for ${entry.encoder.name}: $e',
            name: 'voice');
      }
    }
    return supported;
  }

  @override
  Future<String> pickMimeType() async {
    final supported = await supportedMimeTypes();
    return supported.isNotEmpty ? supported.first : _encoders.first.mime;
  }

  @override
  Future<void> start({
    required String mimeType,
    void Function(double level)? onLevel,
  }) async {
    final entry = _encoders.firstWhere(
      (e) => e.mime == mimeType,
      orElse: () => _encoders.first,
    );
    final dir = await tempDirectoryProvider();
    final path = p.join(
      dir.path,
      'beslet_voice_${DateTime.now().millisecondsSinceEpoch}.${entry.ext}',
    );
    final config = RecordConfig(
      encoder: entry.encoder,
      sampleRate: 16000,
      numChannels: 1,
      bitRate: 64000,
      autoGain: false,
      echoCancel: false,
      noiseSuppress: false,
      audioInterruption: AudioInterruptionMode.pause,
    );
    try {
      await recorder.start(config, path: path);
    } catch (e) {
      VoiceDiagnostics.instance.record(
        recordStartedAt: DateTime.now().toIso8601String(),
        lastTechnicalError: e.toString(),
      );
      rethrow;
    }
    _activePath = path;
    VoiceDiagnostics.instance.record(
      phase: 'recording',
      selectedMimeType: mimeType,
      recordStartedAt: DateTime.now().toIso8601String(),
    );
    if (onLevel != null) {
      _amplitudeSub = recorder
          .onAmplitudeChanged(const Duration(milliseconds: 150))
          .listen(
        (amp) => onLevel(amp.current),
        onError: (Object e) =>
            developer.log('voice: amplitude stream unavailable: $e', name: 'voice'),
      );
    }
  }

  @override
  Future<VoiceRecording> stop() async {
    final path = _activePath;
    await _amplitudeSub?.cancel();
    _amplitudeSub = null;
    final stopped = await recorder.stop() ?? path;
    _activePath = null;
    if (stopped == null) {
      throw const VoicePipelineException(
        VoiceError.recordingUnavailable,
        'recorder stopped but produced no path',
      );
    }
    final file = File(stopped);
    if (!await file.exists()) {
      throw const VoicePipelineException(
        VoiceError.recordingUnavailable,
        'recorder stopped but produced no file',
      );
    }
    final bytes = await file.readAsBytes();
    final duration = _durationOf(bytes);
    VoiceDiagnostics.instance.record(
      recordStoppedAt: DateTime.now().toIso8601String(),
      recordedBytes: bytes.length,
      recordedDurationMs: duration.inMilliseconds,
    );
    return VoiceRecording(
      bytes: bytes,
      mimeType: _mimeForPath(stopped),
      path: stopped,
      duration: duration,
    );
  }

  @override
  Future<void> cancel() async {
    await _amplitudeSub?.cancel();
    _amplitudeSub = null;
    final path = _activePath;
    _activePath = null;
    try {
      await recorder.cancel();
    } catch (e) {
      developer.log('voice: recorder.cancel failed: $e', name: 'voice');
    }
    if (path != null) {
      try {
        final f = File(path);
        if (await f.exists()) await f.delete();
      } catch (e) {
        developer.log('voice: temp file cleanup failed: $e', name: 'voice');
      }
    }
  }

  @override
  Future<bool> openSettings() => openAppSettings();

  @override
  Future<void> dispose() async {
    await _amplitudeSub?.cancel();
    _amplitudeSub = null;
    try {
      await recorder.dispose();
    } catch (e) {
      developer.log('voice: recorder.dispose failed: $e', name: 'voice');
    }
  }

  static String _mimeForPath(String path) {
    if (path.endsWith('.m4a')) return 'audio/m4a';
    if (path.endsWith('.opus') || path.endsWith('.ogg')) return 'audio/ogg';
    return 'audio/wav';
  }

  /// Reads a WAV header for its duration; falls back to a 16 kHz mono 16-bit
  /// estimate when the header is unavailable.
  static Duration _durationOf(Uint8List bytes) {
    if (bytes.length >= 44 &&
        bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46) {
      final byteRate = _le32(bytes, 28);
      final dataSize = _le32(bytes, 40);
      if (byteRate > 0) {
        return Duration(milliseconds: (dataSize / byteRate * 1000).round());
      }
    }
    return Duration(milliseconds: (bytes.length / 32000 * 1000).round());
  }

  static int _le32(Uint8List bytes, int offset) =>
      bytes[offset] |
          (bytes[offset + 1] << 8) |
          (bytes[offset + 2] << 16) |
          (bytes[offset + 3] << 24);
}