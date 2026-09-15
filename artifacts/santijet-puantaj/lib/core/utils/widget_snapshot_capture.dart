import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Off-screen [RepaintBoundary] → PNG (rapor PDF gömme).
Future<Uint8List?> captureWidgetToPng(
  BuildContext context,
  Widget child, {
  required Size logicalSize,
  double pixelRatio = 2,
  int frameWait = 4,
}) async {
  final overlay = Overlay.of(context, rootOverlay: true);
  final boundaryKey = GlobalKey();
  late OverlayEntry entry;

  entry = OverlayEntry(
    builder: (ctx) => Positioned(
      left: -logicalSize.width - 48,
      top: 0,
      child: RepaintBoundary(
        key: boundaryKey,
        child: SizedBox(
          width: logicalSize.width,
          height: logicalSize.height,
          child: child,
        ),
      ),
    ),
  );

  overlay.insert(entry);
  try {
    for (var i = 0; i < frameWait; i++) {
      await WidgetsBinding.instance.endOfFrame;
    }
    await Future<void>.delayed(const Duration(milliseconds: 80));

    final ro = boundaryKey.currentContext?.findRenderObject();
    if (ro is! RenderRepaintBoundary) return null;
    if (ro.debugNeedsPaint) {
      await WidgetsBinding.instance.endOfFrame;
    }

    final image = await ro.toImage(pixelRatio: pixelRatio);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data?.buffer.asUint8List();
  } finally {
    entry.remove();
  }
}
