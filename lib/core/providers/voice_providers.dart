import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../voice/voice_diagnostics.dart';

/// Exposes the shared voice diagnostics singleton to widgets (e.g. the
/// Settings diagnostics screen).
final voiceDiagnosticsProvider = Provider<VoiceDiagnostics>((ref) {
  return VoiceDiagnostics.instance;
});