import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

final _registeredViews = <String>{};

/// Kaynak uygulamanın yayınını olduğu gibi gösterir. Ekran koduna dokunulmaz.
Widget moduleFrame({required String viewType, required String url}) {
  try {
    if (_registeredViews.add(viewType)) {
      ui_web.platformViewRegistry.registerViewFactory(viewType, (int viewId) {
        final frame = web.HTMLIFrameElement()
          ..src = url
          ..allow = 'fullscreen; clipboard-read; clipboard-write';
        frame.style
          ..border = '0'
          ..width = '100%'
          ..height = '100%'
          ..display = 'block';
        frame.setAttribute('title', viewType);
        return frame;
      });
    }
    return HtmlElementView(viewType: viewType);
  } catch (error) {
    return ColoredBox(
      color: const Color(0xFF05070A),
      child: Center(
        child: Text(
          '$error',
          style: const TextStyle(color: Color(0xFFFFFFFF)),
        ),
      ),
    );
  }
}
