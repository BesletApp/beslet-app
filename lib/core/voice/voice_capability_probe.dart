import 'voice_diagnostics.dart';
import 'voice_models.dart';
import 'recording_adapter.dart';

/// What a real capability check found about this device, before any session
/// starts. This is the source of truth for capability questions — never a
/// missing language pack or a plugin gap.
class VoiceCapabilities {
  final bool recorderAvailable;
  final bool microphoneDetected;
  final VoicePermissionState permission;
  final List<String> supportedMimeTypes;
  final String selectedMimeType;

  const VoiceCapabilities({
    required this.recorderAvailable,
    required this.microphoneDetected,
    required this.permission,
    required this.supportedMimeTypes,
    required this.selectedMimeType,
  });
}

/// Runs the real capability probe. It is non-blocking and informational: it
/// never prevents the flow from trying to record, because a probe failure is
/// not proof the microphone is unavailable.
class VoiceCapabilityProbe {
  final RecordingAdapter adapter;

  const VoiceCapabilityProbe({required this.adapter});

  Future<VoiceCapabilities> probe() async {
    VoicePermissionState permission = VoicePermissionState.unknown;
    bool mic = true;
    List<String> mimes = const [];
    String selected = 'audio/wav';
    try {
      permission = await adapter.permissionState();
    } catch (e) {
      VoiceDiagnostics.instance.record(
        lastTechnicalError: 'permission probe failed: $e',
      );
    }
    try {
      mic = await adapter.hasMicrophone();
    } catch (e) {
      VoiceDiagnostics.instance.record(
        lastTechnicalError: 'mic probe failed: $e',
      );
    }
    try {
      mimes = await adapter.supportedMimeTypes();
      selected = await adapter.pickMimeType();
    } catch (e) {
      VoiceDiagnostics.instance.record(
        lastTechnicalError: 'encoder probe failed: $e',
      );
    }
    final capabilities = VoiceCapabilities(
      recorderAvailable: mimes.isNotEmpty,
      microphoneDetected: mic,
      permission: permission,
      supportedMimeTypes: mimes,
      selectedMimeType: selected,
    );
    VoiceDiagnostics.instance.record(
      phase: 'probed',
      permissionStatus: permission.name,
      micDetected: mic,
      supportedMimeTypes: mimes,
      selectedMimeType: selected,
    );
    return capabilities;
  }
}