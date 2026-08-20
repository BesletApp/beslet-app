import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';

import 'voice_models.dart';

/// Maps a raw platform/SDK exception or permission status to a [VoiceError].
/// The original error is always logged for diagnostics; the reader never sees
/// a technical string and the pipeline never invents a vague "unsupported
/// device" conclusion from a missing language pack or a plugin gap.
class VoiceErrorMapper {
  const VoiceErrorMapper._();

  /// Converts a permission-handler status into the pipeline's own state.
  static VoicePermissionState toPermissionState(PermissionStatus status) {
    switch (status) {
      case PermissionStatus.granted:
      case PermissionStatus.limited:
      case PermissionStatus.provisional:
        return VoicePermissionState.granted;
      case PermissionStatus.denied:
        return VoicePermissionState.denied;
      case PermissionStatus.permanentlyDenied:
        return VoicePermissionState.permanentlyDenied;
      case PermissionStatus.restricted:
        return VoicePermissionState.restricted;
    }
  }

  static VoiceError fromPermissionState(VoicePermissionState state) {
    switch (state) {
      case VoicePermissionState.granted:
      case VoicePermissionState.unknown:
      case VoicePermissionState.requesting:
        return VoiceError.unknown;
      case VoicePermissionState.denied:
        return VoiceError.permissionDenied;
      case VoicePermissionState.permanentlyDenied:
      case VoicePermissionState.restricted:
        return VoiceError.permissionPermanentlyDenied;
      case VoicePermissionState.hardwareUnavailable:
        return VoiceError.microphoneUnavailable;
      case VoicePermissionState.browserUnavailable:
        return VoiceError.browserRestricted;
    }
  }

  /// Maps an error raised by the recording plugin.
  static VoiceError mapRecordingError(Object error) {
    developer.log('voice: recording error: $error', name: 'voice');
    final m = error.toString().toLowerCase();
    if (m.contains('permission')) return VoiceError.permissionDenied;
    if (m.contains('not_found') || m.contains('not found') || m.contains('no input')) {
      return VoiceError.microphoneUnavailable;
    }
    if (m.contains('busy') ||
        m.contains('occupied') ||
        m.contains('in use') ||
        m.contains('resource')) {
      return VoiceError.microphoneInUse;
    }
    if (m.contains('security') || m.contains('insecure')) {
      return VoiceError.insecureContext;
    }
    if (m.contains('unsupported') || m.contains('notsupported') || m.contains('encoder') ||
        m.contains('format')) {
      return VoiceError.recordingUnavailable;
    }
    return VoiceError.recordingUnavailable;
  }

  /// Maps an error from the Gemini transport/API. [fallback] decides whether a
  /// generic server failure is a transcription or a translation problem.
  static VoiceError mapGeminiError(
    Object error, {
    VoiceError fallback = VoiceError.transcriptionFailed,
  }) {
    developer.log('voice: gemini error: $error', name: 'voice');
    if (error is VoicePipelineException) return error.error;
    if (error is TimeoutException) return VoiceError.timeout;
    if (error is SocketException ||
        error is http.ClientException ||
        error is HandshakeException ||
        error is FileSystemException) {
      return VoiceError.network;
    }
    if (error is InvalidApiKey || error is UnsupportedUserLocation) {
      return VoiceError.authOrConfig;
    }
    if (error is StateError && error.message.contains('no API key')) {
      return VoiceError.authOrConfig;
    }
    if (error is ServerException) {
      final message = error.message.toLowerCase();
      if (message.contains('401') ||
          message.contains('403') ||
          message.contains('404')) {
        return VoiceError.authOrConfig;
      }
      if (message.contains('429') ||
          message.contains('quota') ||
          message.contains('rate') ||
          message.contains('exhausted')) {
        return VoiceError.timeout;
      }
      return fallback;
    }
    return fallback;
  }
}