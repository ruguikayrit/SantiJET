import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../core/theme/pro_theme.dart';
import 'module_frame_stub.dart' as stub;

/// iOS ve Android simülatörde modülün yayınlanmış sayfasını açar.
Widget moduleFrame({required String viewType, required String url}) {
  if (Platform.environment['FLUTTER_TEST'] == 'true') {
    return stub.moduleFrame(viewType: viewType, url: url);
  }
  return _ModuleWebView(url: url);
}

class _ModuleWebView extends StatefulWidget {
  const _ModuleWebView({required this.url});

  final String url;

  @override
  State<_ModuleWebView> createState() => _ModuleWebViewState();
}

class _ModuleWebViewState extends State<_ModuleWebView> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(ProColors.canvas)
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return WebViewWidget(controller: _controller);
  }
}
