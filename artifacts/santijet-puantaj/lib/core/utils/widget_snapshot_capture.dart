import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Off-screen [RepaintBoundary] → PNG (rapor PDF gömme).
Future<Uint8List?> captureWidgetToPng(
  BuildContext context,
  Widget child, {
  required Size logicalSize,
  double pixelRatio = 2,
  int frameWait = 6,
}) async {
  if (!context.mounted) return null;

  OverlayState? overlay;
  try {
    overlay = Overlay.of(context, rootOverlay: true);
  } catch (e, st) {
    debugPrint('captureWidgetToPng: overlay yok: $e\n$st');
    return null;
  }

  final boundaryKey = GlobalKey();
  OverlayEntry? entry;

  try {
    entry = OverlayEntry(
      builder: (ctx) => Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.02,
                child: Center(
                  child: RepaintBoundary(
                    key: boundaryKey,
                    child: SizedBox(
                      width: logicalSize.width,
                      height: logicalSize.height,
                      child: child,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    overlay.insert(entry);
    for (var i = 0; i < frameWait; i++) {
      await WidgetsBinding.instance.endOfFrame;
    }
    await Future<void>.delayed(
      Duration(milliseconds: kIsWeb ? 180 : 80),
    );

    if (!context.mounted) return null;

    final ro = boundaryKey.currentContext?.findRenderObject();
    if (ro is! RenderRepaintBoundary) {
      debugPrint('captureWidgetToPng: RepaintBoundary yok');
      return null;
    }
    if (ro.debugNeedsPaint) {
      await WidgetsBinding.instance.endOfFrame;
      await WidgetsBinding.instance.endOfFrame;
    }

    final image = await ro.toImage(pixelRatio: pixelRatio);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data?.buffer.asUint8List();
  } catch (e, st) {
    debugPrint('captureWidgetToPng: $e\n$st');
    return null;
  } finally {
    entry?.remove();
  }
}
