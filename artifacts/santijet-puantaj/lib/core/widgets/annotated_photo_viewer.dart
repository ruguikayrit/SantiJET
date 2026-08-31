import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_spacing.dart';
import '../utils/image_rotate.dart';

enum _PhotoTool { view, draw, line, arrow, rect, circle, text }

enum _AnnotationKind { freehand, line, arrow, rect, circle, text }

class _Annotation {
  const _Annotation({
    required this.kind,
    required this.color,
    required this.strokeWidth,
    this.points,
    this.start,
    this.end,
    this.text,
    this.position,
  });

  final _AnnotationKind kind;
  final Color color;
  final double strokeWidth;
  final List<Offset>? points;
  final Offset? start;
  final Offset? end;
  final String? text;
  final Offset? position;

  _Annotation rotatedCw90() {
    Offset rot(Offset p) => Offset(1 - p.dy, p.dx);
    switch (kind) {
      case _AnnotationKind.freehand:
        return _Annotation(
          kind: kind,
          color: color,
          strokeWidth: strokeWidth,
          points: [for (final p in points!) rot(p)],
        );
      case _AnnotationKind.line:
      case _AnnotationKind.arrow:
      case _AnnotationKind.rect:
      case _AnnotationKind.circle:
        return _Annotation(
          kind: kind,
          color: color,
          strokeWidth: strokeWidth,
          start: rot(start!),
          end: rot(end!),
        );
      case _AnnotationKind.text:
        return _Annotation(
          kind: kind,
          color: color,
          strokeWidth: strokeWidth,
          text: text,
          position: rot(position!),
        );
    }
  }
}

/// Tam ekran fotoğraf düzenleyici — çizim, işaretleme, not.
class AnnotatedPhotoViewerPage extends StatefulWidget {
  const AnnotatedPhotoViewerPage({
    super.key,
    required this.imageBytes,
    this.onSave,
    this.startInDrawMode = false,
  });

  final Uint8List imageBytes;
  final Future<void> Function(Uint8List annotatedBytes)? onSave;
  final bool startInDrawMode;

  @override
  State<AnnotatedPhotoViewerPage> createState() =>
      _AnnotatedPhotoViewerPageState();
}

class _AnnotatedPhotoViewerPageState extends State<AnnotatedPhotoViewerPage> {
  ui.Image? _decoded;
  late _PhotoTool _tool;
  final List<_Annotation> _annotations = [];
  _Annotation? _draft;
  Color _color = const Color(0xFFE53935);
  double _strokeWidth = 4;
  bool _dirty = false;
  bool _saving = false;
  bool _rotating = false;

  static const _palette = [
    Color(0xFFE53935),
    Color(0xFFFFB300),
    Color(0xFF1E88E5),
    Color(0xFF43A047),
    Colors.white,
    Colors.black,
  ];

  static const _strokeOptions = [2.0, 4.0, 7.0];

  bool get _canEdit => widget.onSave != null;

  bool get _isLandscape {
    final img = _decoded;
    if (img == null) return true;
    return img.width >= img.height;
  }

  String get _toolHint => switch (_tool) {
        _PhotoTool.view => _canEdit
            ? 'Yakınlaştırmak için sürükleyin'
            : 'Yakınlaştırmak için sürükleyin',
        _PhotoTool.draw => 'Parmağınızla çizin',
        _PhotoTool.line => 'Başlangıç ve bitiş noktasına sürükleyin',
        _PhotoTool.arrow => 'Ok yönü için sürükleyin',
        _PhotoTool.rect => 'Kutu köşelerini sürükleyin',
        _PhotoTool.circle => 'Daire alanını sürükleyin',
        _PhotoTool.text => 'Not eklemek için dokunun',
      };

  @override
  void initState() {
    super.initState();
    _tool = widget.startInDrawMode && _canEdit
        ? _PhotoTool.draw
        : _PhotoTool.view;
    _decodeImage();
  }

  @override
  void dispose() {
    _decoded?.dispose();
    super.dispose();
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
    if (_annotations.isEmpty) return;
    setState(() {
      _annotations.removeLast();
      _dirty = _annotations.isNotEmpty;
    });
  }

  void _clearAll() {
    if (_annotations.isEmpty) return;
    setState(() {
      _annotations.clear();
      _draft = null;
      _dirty = false;
    });
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
          decoration: const InputDecoration(hintText: 'Kısa not…'),
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
      _annotations.add(
        _Annotation(
          kind: _AnnotationKind.text,
          color: _color,
          strokeWidth: _strokeWidth,
          text: text,
          position: norm,
        ),
      );
      _dirty = true;
    });
  }

  Future<void> _rotateCw90() async {
    final image = _decoded;
    if (image == null || _rotating || _saving) return;
    setState(() => _rotating = true);
    try {
      final next = await rotateUiImageCw90(image);
      final remapped = _annotations.map((a) => a.rotatedCw90()).toList();
      if (!mounted) {
        next.dispose();
        return;
      }
      setState(() {
        _decoded?.dispose();
        _decoded = next;
        _annotations
          ..clear()
          ..addAll(remapped);
        _draft = null;
        _dirty = _annotations.isNotEmpty;
      });
    } finally {
      if (mounted) setState(() => _rotating = false);
    }
  }

  Future<void> _setOrientation({required bool landscape}) async {
    if (_decoded == null || _rotating) return;
    if (landscape == _isLandscape) return;
    await _rotateCw90();
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
    for (final a in _annotations) {
      _AnnotationPainter.drawOnCanvas(
        canvas,
        a,
        normToPixel: (norm) =>
            Offset(norm.dx * image.width, norm.dy * image.height),
        strokeScale: scale,
        labelFontSize: 16 * scale,
      );
    }

    final picture = recorder.endRecording();
    final rendered = await picture.toImage(image.width, image.height);
    final data = await rendered.toByteData(format: ui.ImageByteFormat.png);
    rendered.dispose();
    if (data == null) return null;
    return data.buffer.asUint8List();
  }

  void _onPointerDown(Offset local, Rect rect) {
    final norm = _normFromLocal(local, rect);
    if (norm == null) return;

    if (_tool == _PhotoTool.text) {
      _addTextAt(norm);
      return;
    }
    if (_tool == _PhotoTool.draw) {
      setState(() {
        _draft = _Annotation(
          kind: _AnnotationKind.freehand,
          color: _color,
          strokeWidth: _strokeWidth,
          points: [norm],
        );
      });
      return;
    }
    if (_tool == _PhotoTool.line ||
        _tool == _PhotoTool.arrow ||
        _tool == _PhotoTool.rect ||
        _tool == _PhotoTool.circle) {
      final kind = switch (_tool) {
        _PhotoTool.line => _AnnotationKind.line,
        _PhotoTool.arrow => _AnnotationKind.arrow,
        _PhotoTool.rect => _AnnotationKind.rect,
        _PhotoTool.circle => _AnnotationKind.circle,
        _ => _AnnotationKind.line,
      };
      setState(() {
        _draft = _Annotation(
          kind: kind,
          color: _color,
          strokeWidth: _strokeWidth,
          start: norm,
          end: norm,
        );
      });
    }
  }

  void _onPointerMove(Offset local, Rect rect) {
    final norm = _normFromLocal(local, rect);
    if (norm == null || _draft == null) return;

    setState(() {
      if (_draft!.kind == _AnnotationKind.freehand) {
        _draft!.points!.add(norm);
      } else {
        _draft = _Annotation(
          kind: _draft!.kind,
          color: _draft!.color,
          strokeWidth: _draft!.strokeWidth,
          start: _draft!.start,
          end: norm,
        );
      }
    });
  }

  void _onPointerUp() {
    final draft = _draft;
    if (draft == null) return;

    setState(() {
      _draft = null;
      if (draft.kind == _AnnotationKind.freehand) {
        if (draft.points!.length >= 2) {
          _annotations.add(draft);
          _dirty = true;
        }
        return;
      }
      final start = draft.start!;
      final end = draft.end!;
      if ((start - end).distance > 0.008) {
        _annotations.add(draft);
        _dirty = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final canSave = _canEdit;

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
                      _toolHint,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: Colors.white70,
                          ),
                    ),
                  ),
                  if (canSave)
                    FilledButton.tonal(
                      onPressed:
                          _saving || _rotating || !_dirty ? null : _save,
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
                                annotations: _annotations,
                                draft: _draft,
                                localFromNorm: _localFromNorm,
                              ),
                            ),
                            if (_tool != _PhotoTool.view)
                              Listener(
                                behavior: HitTestBehavior.translucent,
                                onPointerDown: (e) =>
                                    _onPointerDown(e.localPosition, rect),
                                onPointerMove: (e) =>
                                    _onPointerMove(e.localPosition, rect),
                                onPointerUp: (_) => _onPointerUp(),
                                onPointerCancel: (_) => _onPointerUp(),
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
            if (canSave)
              DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.9),
                  border: Border(
                    top: BorderSide(
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.sm,
                    AppSpacing.sm,
                    AppSpacing.sm,
                    AppSpacing.sm,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _toolChip(
                              tool: _PhotoTool.view,
                              icon: Icons.zoom_out_map,
                              label: 'Görüntü',
                            ),
                            const SizedBox(width: 6),
                            _toolChip(
                              tool: _PhotoTool.draw,
                              icon: Icons.draw_outlined,
                              label: 'Kalem',
                            ),
                            const SizedBox(width: 6),
                            _toolChip(
                              tool: _PhotoTool.line,
                              icon: Icons.horizontal_rule,
                              label: 'Çizgi',
                            ),
                            const SizedBox(width: 6),
                            _toolChip(
                              tool: _PhotoTool.arrow,
                              icon: Icons.north_east,
                              label: 'Ok',
                            ),
                            const SizedBox(width: 6),
                            _toolChip(
                              tool: _PhotoTool.rect,
                              icon: Icons.crop_square,
                              label: 'Kutu',
                            ),
                            const SizedBox(width: 6),
                            _toolChip(
                              tool: _PhotoTool.circle,
                              icon: Icons.circle_outlined,
                              label: 'Daire',
                            ),
                            const SizedBox(width: 6),
                            _toolChip(
                              tool: _PhotoTool.text,
                              icon: Icons.sticky_note_2_outlined,
                              label: 'Not',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          for (final c in _palette)
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: GestureDetector(
                                onTap: () => setState(() => _color = c),
                                child: Container(
                                  width: 26,
                                  height: 26,
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
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            'Kalınlık',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(color: Colors.white54),
                          ),
                          const SizedBox(width: 6),
                          for (final w in _strokeOptions)
                            Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: _strokeChip(w),
                            ),
                          const Spacer(),
                          IconButton(
                            tooltip: 'Geri al',
                            onPressed:
                                _annotations.isEmpty ? null : _undo,
                            icon: const Icon(Icons.undo, color: Colors.white70),
                          ),
                          IconButton(
                            tooltip: 'Temizle',
                            onPressed:
                                _annotations.isEmpty ? null : _clearAll,
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        children: [
                          _orientChip(
                            label: 'Yatay',
                            icon: Icons.stay_current_landscape,
                            selected: _isLandscape,
                            onTap: _rotating || _saving
                                ? null
                                : () => _setOrientation(landscape: true),
                          ),
                          const SizedBox(width: 6),
                          _orientChip(
                            label: 'Dikey',
                            icon: Icons.stay_current_portrait,
                            selected: !_isLandscape,
                            onTap: _rotating || _saving
                                ? null
                                : () => _setOrientation(landscape: false),
                          ),
                          const Spacer(),
                          IconButton(
                            tooltip: '90° döndür',
                            onPressed:
                                _rotating || _saving ? null : _rotateCw90,
                            icon: _rotating
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white54,
                                    ),
                                  )
                                : const Icon(
                                    Icons.rotate_90_degrees_cw,
                                    color: Colors.white70,
                                  ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _strokeChip(double width) {
    final selected = _strokeWidth == width;
    return Material(
      color: selected
          ? AppColors.electricBlue.withValues(alpha: 0.3)
          : Colors.white.withValues(alpha: 0.08),
      borderRadius: AppRadii.sm,
      child: InkWell(
        borderRadius: AppRadii.sm,
        onTap: () => setState(() => _strokeWidth = width),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Container(
            width: 22,
            height: width.clamp(2, 8),
            decoration: BoxDecoration(
              color: selected ? Colors.white : Colors.white70,
              borderRadius: BorderRadius.circular(width),
            ),
          ),
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
          ? AppColors.electricBlue.withValues(alpha: 0.28)
          : Colors.white.withValues(alpha: 0.08),
      borderRadius: AppRadii.sm,
      child: InkWell(
        borderRadius: AppRadii.sm,
        onTap: () => setState(() {
          _tool = tool;
          _draft = null;
        }),
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
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : Colors.white70,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _orientChip({
    required String label,
    required IconData icon,
    required bool selected,
    VoidCallback? onTap,
  }) {
    return Material(
      color: selected
          ? AppColors.electricBlue.withValues(alpha: 0.35)
          : Colors.white.withValues(alpha: 0.08),
      borderRadius: AppRadii.sm,
      child: InkWell(
        borderRadius: AppRadii.sm,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: Colors.white),
              const SizedBox(width: 5),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnnotationPainter {
  static void drawOnCanvas(
    Canvas canvas,
    _Annotation a, {
    required Offset Function(Offset norm) normToPixel,
    required double strokeScale,
    required double labelFontSize,
  }) {
    switch (a.kind) {
      case _AnnotationKind.freehand:
        _drawFreehand(canvas, a, normToPixel, strokeScale);
      case _AnnotationKind.line:
        _drawLine(canvas, a, normToPixel, strokeScale, arrow: false);
      case _AnnotationKind.arrow:
        _drawLine(canvas, a, normToPixel, strokeScale, arrow: true);
      case _AnnotationKind.rect:
        _drawRect(canvas, a, normToPixel, strokeScale);
      case _AnnotationKind.circle:
        _drawCircle(canvas, a, normToPixel, strokeScale);
      case _AnnotationKind.text:
        _drawText(canvas, a, normToPixel, labelFontSize);
    }
  }

  static Paint _strokePaint(_Annotation a, double scale) {
    return Paint()
      ..color = a.color
      ..strokeWidth = a.strokeWidth * scale
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
  }

  static void _drawFreehand(
    Canvas canvas,
    _Annotation a,
    Offset Function(Offset norm) normToPixel,
    double scale,
  ) {
    final points = a.points;
    if (points == null || points.length < 2) return;
    final paint = _strokePaint(a, scale);
    final path = Path();
    final first = normToPixel(points.first);
    path.moveTo(first.dx, first.dy);
    for (var i = 1; i < points.length; i++) {
      final p = normToPixel(points[i]);
      path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(path, paint);
  }

  static void _drawLine(
    Canvas canvas,
    _Annotation a,
    Offset Function(Offset norm) normToPixel,
    double scale, {
    required bool arrow,
  }) {
    final start = a.start;
    final end = a.end;
    if (start == null || end == null) return;
    final p0 = normToPixel(start);
    final p1 = normToPixel(end);
    final paint = _strokePaint(a, scale);
    canvas.drawLine(p0, p1, paint);
    if (arrow) {
      _drawArrowHead(canvas, p0, p1, paint);
    }
  }

  static void _drawArrowHead(Canvas canvas, Offset start, Offset end, Paint paint) {
    final angle = math.atan2(end.dy - start.dy, end.dx - start.dx);
    final size = paint.strokeWidth * 2.8;
    final path = Path()
      ..moveTo(end.dx, end.dy)
      ..lineTo(
        end.dx - size * math.cos(angle - math.pi / 6),
        end.dy - size * math.sin(angle - math.pi / 6),
      )
      ..lineTo(
        end.dx - size * math.cos(angle + math.pi / 6),
        end.dy - size * math.sin(angle + math.pi / 6),
      )
      ..close();
    canvas.drawPath(
      path,
      paint..style = PaintingStyle.fill,
    );
  }

  static void _drawRect(
    Canvas canvas,
    _Annotation a,
    Offset Function(Offset norm) normToPixel,
    double scale,
  ) {
    final start = a.start;
    final end = a.end;
    if (start == null || end == null) return;
    final p0 = normToPixel(start);
    final p1 = normToPixel(end);
    canvas.drawRect(Rect.fromPoints(p0, p1), _strokePaint(a, scale));
  }

  static void _drawCircle(
    Canvas canvas,
    _Annotation a,
    Offset Function(Offset norm) normToPixel,
    double scale,
  ) {
    final start = a.start;
    final end = a.end;
    if (start == null || end == null) return;
    final p0 = normToPixel(start);
    final p1 = normToPixel(end);
    canvas.drawOval(Rect.fromPoints(p0, p1), _strokePaint(a, scale));
  }

  static void _drawText(
    Canvas canvas,
    _Annotation a,
    Offset Function(Offset norm) normToPixel,
    double fontSize,
  ) {
    final position = a.position;
    final text = a.text;
    if (position == null || text == null || text.isEmpty) return;
    final origin = normToPixel(position);
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: a.color,
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          shadows: const [Shadow(color: Colors.black54, blurRadius: 2)],
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    painter.layout();
    painter.paint(canvas, origin);
  }
}

class _PhotoCanvasPainter extends CustomPainter {
  _PhotoCanvasPainter({
    required this.image,
    required this.rect,
    required this.annotations,
    required this.draft,
    required this.localFromNorm,
  });

  final ui.Image image;
  final Rect rect;
  final List<_Annotation> annotations;
  final _Annotation? draft;
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

    Offset normToPixel(Offset norm) => localFromNorm(norm, rect);

    for (final a in annotations) {
      _AnnotationPainter.drawOnCanvas(
        canvas,
        a,
        normToPixel: normToPixel,
        strokeScale: 1,
        labelFontSize: 14,
      );
    }
    if (draft != null) {
      _AnnotationPainter.drawOnCanvas(
        canvas,
        draft!,
        normToPixel: normToPixel,
        strokeScale: 1,
        labelFontSize: 14,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PhotoCanvasPainter oldDelegate) => true;
}

/// Görev fotoğrafları için tam ekran düzenleyici.
Future<void> openAnnotatedPhotoViewer(
  BuildContext context, {
  required Uint8List imageBytes,
  Future<void> Function(Uint8List annotatedBytes)? onSave,
  bool startInDrawMode = false,
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
            startInDrawMode: startInDrawMode,
          ),
        );
      },
    ),
  );
}
