import 'dart:async';
import 'dart:io';

import 'package:beslet_app/core/voice/voice_error_mapper.dart';
import 'package:beslet_app/core/voice/voice_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';

void main() {
  group('VoiceErrorMapper.toPermissionState', () {
    test('treats grant-like statuses as granted', () {
      expect(VoiceErrorMapper.toPermissionState(PermissionStatus.granted),
          VoicePermissionState.granted);
      expect(VoiceErrorMapper.toPermissionState(PermissionStatus.limited),
          VoicePermissionState.granted);
      expect(VoiceErrorMapper.toPermissionState(PermissionStatus.provisional),
          VoicePermissionState.granted);
    });

    test('maps the rest 1:1', () {
      expect(VoiceErrorMapper.toPermissionState(PermissionStatus.denied),
          VoicePermissionState.denied);
      expect(VoiceErrorMapper.toPermissionState(PermissionStatus.permanentlyDenied),
          VoicePermissionState.permanentlyDenied);
      expect(VoiceErrorMapper.toPermissionState(PermissionStatus.restricted),
          VoicePermissionState.restricted);
    });
  });

  group('VoiceErrorMapper.fromPermissionState', () {
    test('blocking states become reader-safe errors', () {
      expect(VoiceErrorMapper.fromPermissionState(VoicePermissionState.denied),
          VoiceError.permissionDenied);
      expect(VoiceErrorMapper.fromPermissionState(VoicePermissionState.permanentlyDenied),
          VoiceError.permissionPermanentlyDenied);
      expect(VoiceErrorMapper.fromPermissionState(VoicePermissionState.restricted),
          VoiceError.permissionPermanentlyDenied);
      expect(VoiceErrorMapper.fromPermissionState(VoicePermissionState.hardwareUnavailable),
          VoiceError.microphoneUnavailable);
      expect(VoiceErrorMapper.fromPermissionState(VoicePermissionState.browserUnavailable),
          VoiceError.browserRestricted);
    });
  });

  group('VoiceErrorMapper.mapRecordingError', () {
    test('permission keyword', () {
      expect(VoiceErrorMapper.mapRecordingError(Exception('microphone permission denied')),
          VoiceError.permissionDenied);
    });

    test('no device', () {
      expect(VoiceErrorMapper.mapRecordingError(Exception('no input device found')),
          VoiceError.microphoneUnavailable);
      expect(VoiceErrorMapper.mapRecordingError(Exception('device not found')),
          VoiceError.microphoneUnavailable);
    });

    test('busy', () {
      expect(VoiceErrorMapper.mapRecordingError(Exception('microphone is busy')),
          VoiceError.microphoneInUse);
      expect(VoiceErrorMapper.mapRecordingError(Exception('resource already in use')),
          VoiceError.microphoneInUse);
    });

    test('insecure context', () {
      expect(VoiceErrorMapper.mapRecordingError(Exception('insecure context')),
          VoiceError.insecureContext);
    });

    test('unknown failures are recordingUnavailable, never a vague pass', () {
      expect(VoiceErrorMapper.mapRecordingError(Exception('boom')),
          VoiceError.recordingUnavailable);
      expect(VoiceErrorMapper.mapRecordingError(Exception('encoder not supported')),
          VoiceError.recordingUnavailable);
    });
  });

  group('VoiceErrorMapper.mapGeminiError', () {
    test('timeouts are their own category', () {
      expect(VoiceErrorMapper.mapGeminiError(TimeoutException('slow')),
          VoiceError.timeout);
    });

    test('connectivity failures become network', () {
      expect(VoiceErrorMapper.mapGeminiError(const SocketException('no route')),
          VoiceError.network);
      expect(VoiceErrorMapper.mapGeminiError(http.ClientException('connection refused')),
          VoiceError.network);
      expect(VoiceErrorMapper.mapGeminiError(HandshakeException('tls')),
          VoiceError.network);
      expect(VoiceErrorMapper.mapGeminiError(FileSystemException('disk')),
          VoiceError.network);
    });

    test('key/location problems become authOrConfig', () {
      expect(VoiceErrorMapper.mapGeminiError(InvalidApiKey('bad')),
          VoiceError.authOrConfig);
      expect(VoiceErrorMapper.mapGeminiError(UnsupportedUserLocation()),
          VoiceError.authOrConfig);
      expect(VoiceErrorMapper.mapGeminiError(StateError('no API key')),
          VoiceError.authOrConfig);
    });

    test('server status codes classify correctly', () {
      expect(VoiceErrorMapper.mapGeminiError(ServerException('401 Unauthorized')),
          VoiceError.authOrConfig);
      expect(VoiceErrorMapper.mapGeminiError(ServerException('403 Forbidden')),
          VoiceError.authOrConfig);
      expect(VoiceErrorMapper.mapGeminiError(ServerException('404 not found')),
          VoiceError.authOrConfig);
      expect(VoiceErrorMapper.mapGeminiError(ServerException('429 rate limit exceeded')),
          VoiceError.timeout);
      expect(VoiceErrorMapper.mapGeminiError(ServerException('quota exhausted')),
          VoiceError.timeout);
      expect(VoiceErrorMapper.mapGeminiError(ServerException('500 internal')),
          VoiceError.transcriptionFailed);
    });

    test('an explicit pipeline error is preserved', () {
      final e = const VoicePipelineException(VoiceError.timeout, 'nope');
      expect(VoiceErrorMapper.mapGeminiError(e), VoiceError.timeout);
    });

    test('unknown failures fall back, and translation can choose its own', () {
      expect(VoiceErrorMapper.mapGeminiError(Exception('oops')),
          VoiceError.transcriptionFailed);
      expect(VoiceErrorMapper.mapGeminiError(Exception('oops'),
              fallback: VoiceError.translationFailed),
          VoiceError.translationFailed);
    });
  });
}