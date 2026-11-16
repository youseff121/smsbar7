import 'dart:convert';
import 'package:http/http.dart' as http;

class UpdateInfo {
  final String currentVersion;
  final String latestVersion;
  final String downloadUrl;

  const UpdateInfo({
    required this.currentVersion,
    required this.latestVersion,
    required this.downloadUrl,
  });

  bool get hasUpdate {
    return UpdateService.compareVersions(latestVersion, currentVersion) > 0;
  }
}

class UpdateService {
  static const String currentVersion = '1.0.2';

  static const String updateUrl = 'http://185.18.214.136:9000/update.json';

  static Future<UpdateInfo?> checkForUpdate() async {
    try {
      final response = await http
          .get(
            Uri.parse(updateUrl),
            headers: {
              'Accept': 'application/json',
              'Cache-Control': 'no-cache',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        return null;
      }

      final dynamic decoded = jsonDecode(response.body);

      if (decoded is! Map<String, dynamic>) {
        return null;
      }

      final latestVersion = decoded['version']?.toString().trim();
      final downloadUrl = decoded['url']?.toString().trim();

      if (latestVersion == null ||
          latestVersion.isEmpty ||
          downloadUrl == null ||
          downloadUrl.isEmpty) {
        return null;
      }

      final updateInfo = UpdateInfo(
        currentVersion: currentVersion,
        latestVersion: latestVersion,
        downloadUrl: downloadUrl,
      );

      if (updateInfo.hasUpdate) {
        return updateInfo;
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  static int compareVersions(String a, String b) {
    final aParts = _parseVersion(a);
    final bParts = _parseVersion(b);

    final maxLength = aParts.length > bParts.length
        ? aParts.length
        : bParts.length;

    for (int i = 0; i < maxLength; i++) {
      final aValue = i < aParts.length ? aParts[i] : 0;
      final bValue = i < bParts.length ? bParts[i] : 0;

      if (aValue > bValue) {
        return 1;
      }

      if (aValue < bValue) {
        return -1;
      }
    }

    return 0;
  }

  static List<int> _parseVersion(String version) {
    return version
        .split('.')
        .map((part) => int.tryParse(part.trim()) ?? 0)
        .toList();
  }
}
