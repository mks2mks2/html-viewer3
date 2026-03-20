import 'dart:io';
import 'package:mime/mime.dart';

class LocalServer {
  static HttpServer? _server;
  static const int _port = 8765;
  static String _contentDir = '';

  static Future<String> start(String contentDir) async {
    await stop();
    _contentDir = contentDir;

    _server = await HttpServer.bind(InternetAddress.loopbackIPv4, _port);

    _server!.listen((HttpRequest request) async {
      String path = request.uri.path;
      if (path == '/' || path.isEmpty) path = '/index.html';

      // Remover a barra inicial
      final relativePath = path.startsWith('/') ? path.substring(1) : path;
      final file = File('$_contentDir/$relativePath');

      if (!await file.exists()) {
        request.response
          ..statusCode = HttpStatus.notFound
          ..write('Not found: $relativePath')
          ..close();
        return;
      }

      final mimeType = lookupMimeType(file.path) ?? 'application/octet-stream';
      final bytes = await file.readAsBytes();

      request.response
        ..statusCode = HttpStatus.ok
        ..headers.set('Content-Type', mimeType)
        ..headers.set('Cache-Control', 'no-cache')
        ..headers.set('Access-Control-Allow-Origin', '*')
        ..add(bytes);
      await request.response.close();
    });

    return 'http://127.0.0.1:$_port/';
  }

  static Future<void> stop() async {
    await _server?.close(force: true);
    _server = null;
  }

  static bool get isRunning => _server != null;
}
