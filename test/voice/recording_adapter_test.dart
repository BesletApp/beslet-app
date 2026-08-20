import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:beslet_app/core/voice/recording_adapter.dart';
import 'package:beslet_app/core/voice/voice_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:record/record.dart';

/// Minimal in-memory [RecordPlatform] so the real [RecordRecorderAdapter] can
/// be exercised end-to-end (start → write file → stop → cancel) without a mic.
class FakeRecordPlatform extends RecordPlatform {
  final Set<AudioEncoder> supportedEncoders = {
    AudioEncoder.wav,
    AudioEncoder.aacLc,
  };
  List<InputDevice> devices = const [];
  Object? listException;
  String? stopPath;
  final _states = <String, StreamController<RecordState>>{};
  String? lastStartPath;
  RecordConfig? lastConfig;

  @override
  Future<void> create(String recorderId) async {
    _states[recorderId] = StreamController<RecordState>.broadcast();
  }

  @override
  Future<void> start(String recorderId, RecordConfig config, {required String path}) async {
    lastStartPath = path;
    lastConfig = config;
    File(path).createSync(recursive: true);
  }

  @override
  Future<Stream<Uint8List>> startStream(String recorderId, RecordConfig config) async =>
      Stream<Uint8List>.empty();

  @override
  Future<String?> stop(String recorderId) async => stopPath;

  @override
  Future<void> pause(String recorderId) async {}

  @override
  Future<void> resume(String recorderId) async {}

  @override
  Future<bool> isRecording(String recorderId) async => false;

  @override
  Future<bool> isPaused(String recorderId) async => false;

  @override
  Future<bool> hasPermission(String recorderId, {bool request = true}) async => true;

  @override
  Future<void> cancel(String recorderId) async {}

  @override
  Future<void> dispose(String recorderId) async {
    await _states.remove(recorderId)?.close();
  }

  @override
  Future<Amplitude> getAmplitude(String recorderId) async =>
      Amplitude(current: -40, max: -10);

  @override
  Future<bool> isEncoderSupported(String recorderId, AudioEncoder encoder) async =>
      supportedEncoders.contains(encoder);

  @override
  Future<List<InputDevice>> listInputDevices(String recorderId) async {
    final e = listException;
    if (e != null) throw e;
    return devices;
  }

  @override
  Stream<RecordState> onStateChanged(String recorderId) =>
      _states[recorderId]!.stream;

  @override
  void setOnConfigChanged(String recorderId, void Function(RecordConfig config)? handler) {}
}

/// 16 kHz mono 16-bit PCM WAV with the given payload size.
Uint8List _wavBytes({int dataSize = 3200}) {
  final bytes = BytesBuilder();
  const sampleRate = 16000;
  const byteRate = sampleRate * 2;
  final header = <int>[
    0x52, 0x49, 0x46, 0x46, // RIFF
    36 + dataSize, 0, 0, 0, // chunk size
    0x57, 0x41, 0x56, 0x45, // WAVE
    0x66, 0x6D, 0x74, 0x20, // fmt
    16, 0, 0, 0, // fmt size
    1, 0, // PCM
    1, 0, // mono
    sampleRate & 0xFF, (sampleRate >> 8) & 0xFF, (sampleRate >> 16) & 0xFF,
    (sampleRate >> 24) & 0xFF,
    byteRate & 0xFF, (byteRate >> 8) & 0xFF, (byteRate >> 16) & 0xFF,
    (byteRate >> 24) & 0xFF,
    2, 0, // block align
    16, 0, // bits
    0x64, 0x61, 0x74, 0x61, // data
    dataSize & 0xFF, (dataSize >> 8) & 0xFF, (dataSize >> 16) & 0xFF,
    (dataSize >> 24) & 0xFF,
  ];
  bytes.add(header);
  bytes.add(List<int>.filled(dataSize, 0));
  return bytes.toBytes();
}

void main() {
  late Directory dir;
  late FakeRecordPlatform platform;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('voice_adapter_test');
    platform = FakeRecordPlatform();
    RecordPlatform.instance = platform;
  });

  tearDown(() async {
    await dir.delete(recursive: true);
  });

  RecordRecorderAdapter build() => RecordRecorderAdapter(
        tempDirectoryProvider: () async => dir,
      );

  group('RecordRecorderAdapter.supportedMimeTypes / pickMimeType', () {
    test('returns recordable encoders in preference order', () async {
      expect(await build().supportedMimeTypes(), ['audio/wav', 'audio/m4a']);
      expect(await build().pickMimeType(), 'audio/wav');
    });

    test('falls back to the next encoder when wav is missing', () async {
      platform.supportedEncoders.remove(AudioEncoder.wav);
      expect(await build().supportedMimeTypes(), ['audio/m4a']);
      expect(await build().pickMimeType(), 'audio/m4a');
    });

    test('falls back to wav as a sane default when nothing is supported', () async {
      platform.supportedEncoders.clear();
      expect(await build().supportedMimeTypes(), isEmpty);
      expect(await build().pickMimeType(), 'audio/wav');
    });
  });

  group('RecordRecorderAdapter.hasMicrophone', () {
    test('an empty listing is trusted but never blocks', () async {
      platform.devices = const [];
      expect(await build().hasMicrophone(), isTrue);
    });

    test('a listing failure never proves the mic is gone', () async {
      platform.listException = Exception('no permission to list');
      expect(await build().hasMicrophone(), isTrue);
    });
  });

  group('RecordRecorderAdapter start / stop / cancel', () {
    test('records a wav file and derives mime + duration from the header', () async {
      final adapter = build();
      await adapter.start(mimeType: 'audio/wav');
      final files = dir.listSync().whereType<File>().toList();
      expect(files, hasLength(1));
      expect(platform.lastConfig?.sampleRate, 16000);
      expect(platform.lastConfig?.numChannels, 1);
      File(files.first.path).writeAsBytesSync(_wavBytes(dataSize: 3200));

      final rec = await adapter.stop();
      expect(rec.mimeType, 'audio/wav');
      expect(rec.duration, const Duration(milliseconds: 100));
      expect(rec.sizeBytes, greaterThan(44));
      await adapter.dispose();
    });

    test('stop with no produced file is a reader-safe error', () async {
      final adapter = build();
      await adapter.start(mimeType: 'audio/wav');
      final files = dir.listSync().whereType<File>().toList();
      for (final f in files) {
        f.deleteSync();
      }
      await expectLater(
        adapter.stop(),
        throwsA(isA<VoicePipelineException>()
            .having((e) => e.error, 'error', VoiceError.recordingUnavailable)),
      );
      await adapter.dispose();
    });

    test('cancel deletes the temp file', () async {
      final adapter = build();
      await adapter.start(mimeType: 'audio/wav');
      final files = dir.listSync().whereType<File>().toList();
      expect(files, hasLength(1));
      await adapter.cancel();
      expect(dir.listSync().whereType<File>(), isEmpty);
      await adapter.dispose();
    });

    test('picks the m4a encoder when wav is unsupported', () async {
      platform.supportedEncoders.remove(AudioEncoder.wav);
      final adapter = build();
      await adapter.start(mimeType: 'audio/m4a');
      final files = dir.listSync().whereType<File>().toList();
      expect(files, hasLength(1));
      expect(files.first.path, endsWith('.m4a'));
      File(files.first.path).writeAsBytesSync(_wavBytes());
      final rec = await adapter.stop();
      expect(rec.mimeType, 'audio/m4a');
      await adapter.dispose();
    });
  });
}