import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

/// Gömülü LibreDWG (WASM) ile DWG okur. Dosya cihazdan çıkmaz; yalnızca
/// 127.0.0.1 üzerinde açılan bir sunucu ve görünmez WebView kullanılır.
class DwgEmbeddedExtractor {
  DwgEmbeddedExtractor._();

  static final DwgEmbeddedExtractor instance = DwgEmbeddedExtractor._();

  static const _assetRoot = 'assets/dwg/';
  static const _allowedAssets = <String, String>{
    'dwg_host.html': 'text/html; charset=utf-8',
    'dwg_bridge.js': 'text/javascript; charset=utf-8',
    'libredwg-web.js': 'text/javascript; charset=utf-8',
    'wasm/libredwg-web.js': 'text/javascript; charset=utf-8',
    'wasm/libredwg-web.wasm': 'application/wasm',
  };

  HttpServer? _server;
  HeadlessInAppWebView? _webView;
  Completer<void>? _ready;
  Future<void> _queue = Future.value();
  int _nextJobId = 0;
  final Map<String, Uint8List> _inputs = {};
  final Map<String, Completer<String>> _results = {};

  Future<List<Map<String, dynamic>>> extract(List<int> bytes) {
    final job = _queue.then((_) => _run(Uint8List.fromList(bytes)));
    _queue = job.then((_) {}, onError: (_) {});
    return job;
  }

  Future<List<Map<String, dynamic>>> _run(Uint8List bytes) async {
    await _ensureStarted();

    final id = '${_nextJobId++}';
    final completer = Completer<String>();
    _inputs[id] = bytes;
    _results[id] = completer;

    try {
      await _webView!.webViewController!.evaluateJavascript(
        source: 'window.santijetRunDwgJob("$id");',
      );
      final body = await completer.future.timeout(const Duration(seconds: 180));
      final decoded = jsonDecode(body) as Map<String, dynamic>;
      final texts = decoded['texts'] as List<dynamic>? ?? const [];
      return texts.whereType<Map<String, dynamic>>().toList(growable: false);
    } on TimeoutException {
      await _reset();
      throw const FormatException('DWG okuma zaman aşımına uğradı.');
    } finally {
      _inputs.remove(id);
      _results.remove(id);
    }
  }

  Future<void> _ensureStarted() async {
    final existing = _ready;
    if (existing != null) return existing.future;

    final ready = Completer<void>();
    _ready = ready;
    try {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      _server = server;
      server.listen(_handle);

      final webView = HeadlessInAppWebView(
        initialUrlRequest: URLRequest(
          url: WebUri('http://127.0.0.1:${server.port}/dwg_host.html'),
        ),
        initialSettings: InAppWebViewSettings(
          javaScriptEnabled: true,
          isInspectable: kDebugMode,
        ),
        onConsoleMessage: (_, message) {
          debugPrint('[DWG] ${message.message}');
        },
        onReceivedError: (_, request, error) {
          debugPrint('[DWG] load error ${request.url}: ${error.description}');
        },
      );
      _webView = webView;
      await webView.run();
      await ready.future.timeout(const Duration(seconds: 60));
    } catch (e) {
      await _reset();
      if (e is FormatException) rethrow;
      throw const FormatException(
        'DWG modülü başlatılamadı. Uygulamayı yeniden açıp tekrar deneyin.',
      );
    }
  }

  Future<void> _reset() async {
    final ready = _ready;
    _ready = null;
    if (ready != null && !ready.isCompleted) {
      ready.completeError(const FormatException('DWG modülü kapatıldı.'));
      unawaited(ready.future.catchError((_) {}));
    }
    for (final pending in _results.values) {
      if (!pending.isCompleted) {
        pending.completeError(const FormatException('DWG modülü kapatıldı.'));
      }
    }
    final webView = _webView;
    _webView = null;
    final server = _server;
    _server = null;
    try {
      await webView?.dispose();
    } catch (_) {}
    await server?.close(force: true);
  }

  Future<void> _handle(HttpRequest request) async {
    final response = request.response;
    final segments = request.uri.pathSegments
        .where((s) => s.isNotEmpty)
        .toList(growable: false);
    try {
      if (request.method == 'POST' && segments.isNotEmpty) {
        final body = await utf8.decoder.bind(request).join();
        _onPost(segments, body);
        response.statusCode = HttpStatus.noContent;
        return;
      }

      if (segments.length == 2 && segments.first == 'input') {
        final bytes = _inputs[segments[1]];
        if (bytes == null) {
          response.statusCode = HttpStatus.notFound;
          return;
        }
        response.headers.contentType = ContentType.binary;
        response.add(bytes);
        return;
      }

      final path = segments.join('/');
      final mime = _allowedAssets[path];
      if (mime == null) {
        debugPrint('[DWG] 404 $path');
        response.statusCode = HttpStatus.notFound;
        return;
      }
      final data = await rootBundle.load('$_assetRoot$path');
      debugPrint('[DWG] serve $path ${data.lengthInBytes}');
      response.headers.set(HttpHeaders.contentTypeHeader, mime);
      response.add(data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes));
    } catch (_) {
      response.statusCode = HttpStatus.internalServerError;
    } finally {
      await response.close();
    }
  }

  void _onPost(List<String> segments, String body) {
    if (segments.first == 'ready') {
      final ready = _ready;
      if (ready == null || ready.isCompleted) return;
      if (body.startsWith('error')) {
        debugPrint('[DWG] ready $body');
        ready.completeError(
          FormatException('DWG modülü başlatılamadı ($body).'),
        );
      } else {
        ready.complete();
      }
      return;
    }

    if (segments.length != 2) return;
    final completer = _results[segments[1]];
    if (completer == null || completer.isCompleted) return;

    if (segments.first == 'result') {
      completer.complete(body);
    } else if (segments.first == 'error') {
      completer.completeError(
        FormatException(
          body.isNotEmpty ? 'DWG dosyası okunamadı: $body' : 'DWG dosyası okunamadı.',
        ),
      );
    }
  }
}
