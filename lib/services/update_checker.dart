import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

class UpdateChecker {
  static const String versionUrl =
      'https://raw.githubusercontent.com/GITHUB_USERNAME/beslet-releases/main/version.json';

  static Future<UpdateInfo?> checkForUpdate() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentCode = int.parse(packageInfo.buildNumber);

      final response = await http
          .get(Uri.parse(versionUrl))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final latestCode = data['versionCode'] as int;

        if (latestCode > currentCode) {
          return UpdateInfo(
            latestVersion: data['version'] as String,
            downloadUrl: data['downloadUrl'] as String,
            releaseNotes: data['releaseNotes'] as String,
          );
        }
      }
    } catch (_) {
      // No internet or server error — fail silently, never crash the app
    }
    return null;
  }
}

class UpdateInfo {
  final String latestVersion;
  final String downloadUrl;
  final String releaseNotes;

  const UpdateInfo({
    required this.latestVersion,
    required this.downloadUrl,
    required this.releaseNotes,
  });
}
