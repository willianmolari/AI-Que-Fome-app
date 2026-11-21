import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

/// Informações da versão mais recente publicada no GitHub Releases.
class UpdateInfo {
  final String version;
  final String notes;
  final String apkUrl;
  final String releaseUrl;

  const UpdateInfo({
    required this.version,
    required this.notes,
    required this.apkUrl,
    required this.releaseUrl,
  });
}

/// Consulta a release mais recente do repositório do app.
class UpdateService {
  static const _repo = 'willianmolari/AI-Que-Fome-app';
  static const _apiUrl = 'https://api.github.com/repos/$_repo/releases/latest';

  final http.Client _http;

  UpdateService({http.Client? client}) : _http = client ?? http.Client();

  /// Retorna os dados da atualização quando existe uma versão mais nova.
  /// Erros de rede são silenciosos: o app continua funcionando normalmente.
  Future<UpdateInfo?> check() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final localVersion = _normalize(info.version);

      final response = await _http
          .get(
            Uri.parse(_apiUrl),
            headers: {'Accept': 'application/vnd.github+json'},
          )
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) return null;

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final tag = (body['tag_name'] as String? ?? '').trim();
      if (tag.isEmpty) return null;
      final remoteVersion = _normalize(tag);
      if (!isNewer(remoteVersion, localVersion)) return null;

      final assets = body['assets'] as List<dynamic>? ?? const [];
      final apk = assets
          .whereType<Map<String, dynamic>>()
          .firstWhere(
            (asset) =>
                (asset['name'] as String? ?? '').toLowerCase().endsWith('.apk'),
            orElse: () => const <String, dynamic>{},
          );
      final apkUrl = apk['browser_download_url'] as String? ?? '';

      return UpdateInfo(
        version: remoteVersion,
        notes: (body['body'] as String? ?? '').trim(),
        apkUrl: apkUrl,
        releaseUrl: (body['html_url'] as String? ?? '').toString(),
      );
    } catch (_) {
      return null;
    }
  }

  /// Remove o `v` inicial e o número de build (`1.2.0+3` → `1.2.0`).
  static String _normalize(String value) {
    var result = value.trim();
    if (result.startsWith('v') || result.startsWith('V')) {
      result = result.substring(1);
    }
    final plus = result.indexOf('+');
    if (plus >= 0) result = result.substring(0, plus);
    return result;
  }

  /// Comparação simples de versões semânticas (x.y.z).
  static bool isNewer(String remote, String local) {
    final r = _parts(_normalize(remote));
    final l = _parts(_normalize(local));
    for (var i = 0; i < 3; i++) {
      if (r[i] > l[i]) return true;
      if (r[i] < l[i]) return false;
    }
    return false;
  }

  static List<int> _parts(String value) {
    final raw = value.split(RegExp(r'[.\-]'));
    return List<int>.generate(3, (i) => int.tryParse(raw[i]) ?? 0);
  }

  void dispose() => _http.close();
}
