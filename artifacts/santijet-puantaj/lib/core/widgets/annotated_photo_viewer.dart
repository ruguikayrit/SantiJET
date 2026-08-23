import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_spacing.dart';

enum _PhotoTool { view, draw, text }

class _NormStroke {
  _NormStroke({
    required this.points,
    required this.color,
    required this.strokeWidth,
  });

  final List<Offset> points;
  final Color color;
  final double strokeWidth;
}

class _TextLabel {
  _TextLabel({
    required this.position,
    required this.text,
    required this.color,
  });

  final Offset position;
  final String text;
  final Color color;
}

/// Tam ekran fotoğraf görüntüleyici — çizim ve metin notu.
class AnnotatedPhotoViewerPage extends StatefulWidget {
  const AnnotatedPhotoViewerPage({
    super.key,
    required this.imageBytes,
    this.onSave,
  });

  final Uint8List imageBytes;
  final Future<void> Function(Uint8List annotatedBytes)? onSave;

  @override
  State<AnnotatedPhotoViewerPage> createState() =>
      _AnnotatedPhotoViewerPageState();
}

class _AnnotatedPhotoViewerPageState extends State<AnnotatedPhotoViewerPage> {
  ui.Image? _decoded;
  _PhotoTool _tool = _PhotoTool.view;
  final List<_NormStroke> _strokes = [];
  final List<_TextLabel> _labels = [];
  _NormStroke? _activeStroke;
  Color _color = const Color(0xFFE53935);
  bool _dirty = false;
  bool _saving = false;

  static const _palette = [
    Color(0xFFE53935),
    Color(0xFFFFB300),
    Color(0xFF1E88E5),
    Color(0xFF43A047),
    Colors.white,
    Colors.black,
  ];

  @override
  void initState() {
    super.initState();
    _decodeImage();
  }

  Future<void> _decodeImage() async {
    try {
      final codec = await ui.instantiateImageCodec(widget.imageBytes);
      final frame = await codec.getNextFrame();
      if (!mounted) return;
      setState(() => _decoded = frame.image);
    } catch (_) {}
  }

  Rect _imageRect(Size canvas, Size imageSize) {
    final fitted = applyBoxFit(BoxFit.contain, imageSize, canvas);
    return Alignment.center.inscribe(fitted.destination, Offset.zero & canvas);
  }

  Offset? _normFromLocal(Offset local, Rect rect) {
    if (!rect.contains(local)) return null;
    return Offset(
      (local.dx - rect.left) / rect.width,
      (local.dy - rect.top) / rect.height,
    );
  }

  Offset _localFromNorm(Offset norm, Rect rect) {
    return Offset(
      rect.left + norm.dx * rect.width,
      rect.top + norm.dy * rect.height,
    );
  }

  void _undo() {
    if (_labels.isNotEmpty) {
      setState(() {
        _labels.removeLast();
        _dirty = _strokes.isNotEmpty || _labels.isNotEmpty;
      });
      return;
    }
    if (_strokes.isNotEmpty) {
      setState(() {
        _strokes.removeLast();
        _dirty = _strokes.isNotEmpty || _labels.isNotEmpty;
      });
    }
  }

  Future<void> _addTextAt(Offset norm) async {
    final ctrl = TextEditingController();
    final text = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Not ekle'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          maxLines: 3,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            hintText: 'Kısa not yazın…',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('Ekle'),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (text == null || text.isEmpty) return;
    setState(() {
      _labels.add(_TextLabel(position: norm, text: text, color: _color));
      _dirty = true;
    });
  }

  Future<void> _save() async {
    if (widget.onSave == null || _decoded == null) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _saving = true);
    try {
      final bytes = await _flattenToPng();
      if (bytes == null) return;
      await widget.onSave!(bytes);
      if (!mounted) return;
      Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<Uint8List?> _flattenToPng() async {
    final image = _decoded;
    if (image == null) return null;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
    );
    canvas.drawImage(image, Offset.zero, Paint());

    final scale = image.width / 360.0;

    for (final stroke in _strokes) {
      if (stroke.points.isEmpty) continue;
      final paint = Paint()
        ..color = stroke.color
        ..strokeWidth = stroke.strokeWidth * scale
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      final path = Path();
      final first = stroke.points.first;
      path.moveTo(first.dx * image.width, first.dy * image.height);
      for (var i = 1; i < stroke.points.length; i++) {
        final p = stroke.points[i];
        path.lineTo(p.dx * image.width, p.dy * image.height);
      }
      canvas.drawPath(path, paint);
    }

    for (final label in _labels) {
      final painter = TextPainter(
        text: TextSpan(
          text: label.text,
          style: TextStyle(
            color: label.color,
            fontSize: 16 * scale,
            fontWeight: FontWeight.w700,
            shadows: const [
              Shadow(color: Colors.black54, blurRadius: 2),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      painter.layout(maxWidth: image.width.toDouble() * 0.9);
      painter.paint(
        canvas,
        Offset(
          label.position.dx * image.width,
          label.position.dy * image.height,
        ),
      );
    }

    final picture = recorder.endRecording();
    final rendered = await picture.toImage(image.width, image.height);
    final data =
        await rendered.toByteData(format: ui.ImageByteFormat.png);
    if (data == null) return null;
    return data.buffer.asUint8List();
  }

  @override
  Widget build(BuildContext context) {
    final canSave = widget.onSave != null;
    final canEdit = canSave;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Kapat',
                    onPressed: _saving ? null : () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                  Expanded(
                    child: Text(
                      _tool == _PhotoTool.draw
                          ? 'Çizim modu'
                          : _tool == _PhotoTool.text
                              ? 'Not modu — dokunun'
                              : 'Yakınlaştırmak için sürükleyin',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: Colors.white70,
                          ),
                    ),
                  ),
                  if (canSave)
                    FilledButton.tonal(
                      onPressed:
                          _saving || !_dirty ? null : () => _save(),
                      style: FilledButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: AppColors.electricBlue,
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Kaydet'),
                    )
                  else
                    const SizedBox(width: 48),
                ],
              ),
            ),
            Expanded(
              child: _decoded == null
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.white54),
                    )
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        final canvas = Size(
                          constraints.maxWidth,
                          constraints.maxHeight,
                        );
                        final imageSize = Size(
                          _decoded!.width.toDouble(),
                          _decoded!.height.toDouble(),
                        );
                        final rect = _imageRect(canvas, imageSize);

                        Widget canvasChild = Stack(
                          fit: StackFit.expand,
                          children: [
                            CustomPaint(
                              painter: _PhotoCanvasPainter(
                                image: _decoded!,
                                rect: rect,
                                strokes: _strokes,
                                activeStroke: _activeStroke,
                                labels: _labels,
                                localFromNorm: _localFromNorm,
                              ),
                            ),
                            if (_tool != _PhotoTool.view)
                              Listener(
                                behavior: HitTestBehavior.translucent,
                                onPointerDown: (e) {
                                  final norm =
                                      _normFromLocal(e.localPosition, rect);
                                  if (norm == null) return;
                                  if (_tool == _PhotoTool.text) {
                                    _addTextAt(norm);
                                    return;
                                  }
                                  setState(() {
                                    _activeStroke = _NormStroke(
                                      points: [norm],
                                      color: _color,
                                      strokeWidth: 3,
                                    );
                                  });
                                },
                                onPointerMove: (e) {
                                  if (_tool != _PhotoTool.draw ||
                                      _activeStroke == null) {
                                    return;
                                  }
                                  final norm =
                                      _normFromLocal(e.localPosition, rect);
                                  if (norm == null) return;
                                  setState(() {
                                    _activeStroke!.points.add(norm);
                                  });
                                },
                                onPointerUp: (_) {
                                  if (_tool != _PhotoTool.draw ||
                                      _activeStroke == null) {
                                    return;
                                  }
                                  setState(() {
                                    _strokes.add(_activeStroke!);
                                    _activeStroke = null;
                                    _dirty = true;
                                  });
                                },
                              ),
                          ],
                        );

                        if (_tool == _PhotoTool.view) {
                          canvasChild = InteractiveViewer(
                            minScale: 0.8,
                            maxScale: 5,
                            child: canvasChild,
                          );
                        }

                        return canvasChild;
                      },
                    ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.85),
                border: Border(
                  top: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
                ),
              ),
              child: canEdit
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md,
                        AppSpacing.sm,
                        AppSpacing.md,
                        AppSpacing.sm,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              _toolChip(
                                tool: _PhotoTool.view,
                                icon: Icons.pan_tool_alt_outlined,
                                label: 'Görüntü',
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              _toolChip(
                                tool: _PhotoTool.draw,
                                icon: Icons.draw_outlined,
                                label: 'Çiz',
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              _toolChip(
                                tool: _PhotoTool.text,
                                icon: Icons.sticky_note_2_outlined,
                                label: 'Not',
                              ),
                              const Spacer(),
                              IconButton(
                                tooltip: 'Geri al',
                                onPressed:
                                    (_strokes.isEmpty && _labels.isEmpty)
                                        ? null
                                        : _undo,
                                icon:
                                    const Icon(Icons.undo, color: Colors.white70),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Row(
                            children: [
                              Text(
                                'Renk',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                      color: Colors.white54,
                                    ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              for (final c in _palette)
                                Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: GestureDetector(
                                    onTap: () => setState(() => _color = c),
                                    child: Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        color: c,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: _color == c
                                              ? AppColors.electricBlue
                                              : Colors.white30,
                                          width: _color == c ? 2.5 : 1,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _toolChip({
    required _PhotoTool tool,
    required IconData icon,
    required String label,
  }) {
    final selected = _tool == tool;
    return Material(
      color: selected
          ? AppColors.electricBlue.withValues(alpha: 0.25)
          : Colors.white.withValues(alpha: 0.08),
      borderRadius: AppRadii.sm,
      child: InkWell(
        borderRadius: AppRadii.sm,
        onTap: () => setState(() => _tool = tool),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: selected ? AppColors.electricBlue : Colors.white70,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : Colors.white70,
                  fontWeight:
                      selected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhotoCanvasPainter extends CustomPainter {
  _PhotoCanvasPainter({
    required this.image,
    required this.rect,
    required this.strokes,
    required this.activeStroke,
    required this.labels,
    required this.localFromNorm,
  });

  final ui.Image image;
  final Rect rect;
  final List<_NormStroke> strokes;
  final _NormStroke? activeStroke;
  final List<_TextLabel> labels;
  final Offset Function(Offset norm, Rect rect) localFromNorm;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(
        0,
        0,
        image.width.toDouble(),
        image.height.toDouble(),
      ),
      rect,
      Paint(),
    );

    void drawStroke(_NormStroke stroke) {
      if (stroke.points.isEmpty) return;
      final paint = Paint()
        ..color = stroke.color
        ..strokeWidth = stroke.strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      final path = Path();
      final first = localFromNorm(stroke.points.first, rect);
      path.moveTo(first.dx, first.dy);
      for (var i = 1; i < stroke.points.length; i++) {
        final p = localFromNorm(stroke.points[i], rect);
        path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(path, paint);
    }

    for (final stroke in strokes) {
      drawStroke(stroke);
    }
    if (activeStroke != null) {
      drawStroke(activeStroke!);
    }

    for (final label in labels) {
      final origin = localFromNorm(label.position, rect);
      final painter = TextPainter(
        text: TextSpan(
          text: label.text,
          style: TextStyle(
            color: label.color,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            shadows: const [
              Shadow(color: Colors.black54, blurRadius: 2),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      painter.layout(maxWidth: rect.width * 0.9);
      painter.paint(canvas, origin);
    }
  }

  @override
  bool shouldRepaint(covariant _PhotoCanvasPainter oldDelegate) => true;
}

/// Görev / rapor fotoğrafları için tam ekran açıcı.
Future<void> openAnnotatedPhotoViewer(
  BuildContext context, {
  required Uint8List imageBytes,
  Future<void> Function(Uint8List annotatedBytes)? onSave,
}) {
  return Navigator.of(context).push<void>(
    PageRouteBuilder<void>(
      opaque: false,
      barrierColor: Colors.black.withValues(alpha: 0.92),
      pageBuilder: (context, animation, secondaryAnimation) {
        return FadeTransition(
          opacity: animation,
          child: AnnotatedPhotoViewerPage(
            imageBytes: imageBytes,
            onSave: onSave,
          ),
        );
      },
    ),
  );
}
