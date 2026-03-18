class UrlService {
  static String? normalize(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;

    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return _validate(trimmed) ? trimmed : null;
    }

    final ipRegex = RegExp(
      r'^(\d{1,3}\.){3}\d{1,3}(:\d+)?(/.*)?$',
    );
    if (ipRegex.hasMatch(trimmed)) {
      return 'http://$trimmed';
    }

    if (trimmed.contains('.')) {
      return 'https://$trimmed';
    }

    return null;
  }

  static bool _validate(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && uri.host.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  static bool isLocal(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    final host = uri.host;
    return host.startsWith('192.168.') ||
        host.startsWith('10.') ||
        host.startsWith('172.') ||
        host == 'localhost' ||
        host == '127.0.0.1';
  }
}
