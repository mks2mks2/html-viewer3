import 'dart:io';
import 'package:mime/mime.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

/// Servidor HTTP local que serve arquivos da pasta de conteúdo.
class LocalServer {
  static HttpServer? _server;
  static const int _port = 8765;

  static Future<String> start(String contentDir) async {
    await stop();

    final handler = (Request request) async {
      String path = request.url.path;
      if (path.isEmpty || path == '/') path = 'index.html';

      final file = File('$contentDir/$path');

      if (!await file.exists()) {
        return Response.notFound('Arquivo não encontrado: $path');
      }

      final mimeType =
          lookupMimeType(file.path) ?? 'application/octet-stream';
      final bytes = await file.readAsBytes();

      return Response.ok(
        bytes,
        headers: {
          'Content-Type': mimeType,
          'Cache-Control': 'no-cache',
        },
      );
    };

    _server = await shelf_io.serve(handler, 'localhost', _port);
    return 'http://localhost:$_port/';
  }

  static Future<void> stop() async {
    await _server?.close(force: true);
    _server = null;
  }

  static String get baseUrl => 'http://localhost:$_port/';
}
