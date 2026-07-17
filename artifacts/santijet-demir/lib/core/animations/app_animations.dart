import 'package:flutter/material.dart';
import 'package:santijet_demir/core/format/app_format.dart';
import 'package:santijet_demir/core/haptics/app_haptics.dart';
import 'package:santijet_demir/core/theme/app_colors.dart';

/// Uygulama animasyon süreleri ve eğrileri.
abstract final class AppAnimations {
  static const fast = Duration(milliseconds: 200);
  static const normal = Duration(milliseconds: 300);
  static const slow = Duration(milliseconds: 450);
  static const splash = Duration(milliseconds: 800);

  /// KPI sayı sayacı
  static const countUp = Duration(milliseconds: 700);

  /// Progress bar dolumu
  static const progress = Duration(milliseconds: 800);

  /// Checkbox check animasyonu
  static const checkbox = Duration(milliseconds: 80);

  static const curve = Curves.easeOutCubic;
  static const enterCurve = Curves.easeOut;
  static const exitCurve = Curves.easeIn;
  static const countCurve = Curves.easeOutCubic;
}

/// Liste öğeleri için kademeli fade + slide animasyonu.
class StaggeredFadeIn extends StatefulWidget {
  const StaggeredFadeIn({
    super.key,
    required this.index,
    required this.child,
    this.baseDelay = const Duration(milliseconds: 50),
  });

  final int index;
  final Widget child;
  final Duration baseDelay;

  @override
  State<StaggeredFadeIn> createState() => _StaggeredFadeInState();
}

class _StaggeredFadeInState extends State<StaggeredFadeIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: AppAnimations.normal);
    _opacity =
        CurvedAnimation(parent: _controller, curve: AppAnimations.enterCurve);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: AppAnimations.curve),
    );

    Future<void>.delayed(widget.baseDelay * widget.index, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

/// KPI kartı açılış — yumuşak fade + scale (endüstriyel, sakin).
class KpiEntrance extends StatefulWidget {
  const KpiEntrance({
    super.key,
    required this.index,
    required this.child,
    this.baseDelay = const Duration(milliseconds: 45),
  });

  final int index;
  final Widget child;
  final Duration baseDelay;

  @override
  State<KpiEntrance> createState() => _KpiEntranceState();
}

class _KpiEntranceState extends State<KpiEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<double> _scale;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    final curved = CurvedAnimation(
      parent: _controller,
      curve: AppAnimations.curve,
    );
    _opacity = curved;
    _scale = Tween<double>(begin: 0.94, end: 1).animate(curved);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(curved);

    Future<void>.delayed(widget.baseDelay * widget.index, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _slide,
        child: ScaleTransition(scale: _scale, child: widget.child),
      ),
    );
  }
}

/// Basit fade-in wrapper.
class FadeIn extends StatefulWidget {
  const FadeIn({super.key, required this.child, this.delay = Duration.zero});

  final Widget child;
  final Duration delay;

  @override
  State<FadeIn> createState() => _FadeInState();
}

class _FadeInState extends State<FadeIn> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: AppAnimations.splash);
    Future<void>.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: _controller,
        curve: AppAnimations.enterCurve,
      ),
      child: widget.child,
    );
  }
}

/// Dokunma geri bildirimi — hafif scale + isteğe bağlı titreşim.
class TapScale extends StatefulWidget {
  const TapScale({
    super.key,
    required this.child,
    required this.onTap,
    this.haptic = true,
  });

  final Widget child;
  final VoidCallback onTap;
  final bool haptic;

  @override
  State<TapScale> createState() => _TapScaleState();
}

class _TapScaleState extends State<TapScale>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: AppAnimations.fast);
    _scale = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (widget.haptic) AppHaptics.light();
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        _handleTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(scale: _scale, child: widget.child),
    );
  }
}

/// Sayıları ~700 ms içinde sayarak yükseltir; değer değişince önceki sayıdan akar.
class AnimatedCountText extends StatefulWidget {
  const AnimatedCountText({
    super.key,
    required this.value,
    this.numericValue,
    this.style,
    this.textAlign,
    this.overflow,
    this.maxLines,
    this.duration = AppAnimations.countUp,
    this.formatter,
  });

  final String value;
  final num? numericValue;
  final TextStyle? style;
  final TextAlign? textAlign;
  final TextOverflow? overflow;
  final int? maxLines;
  final Duration duration;
  final String Function(num value)? formatter;

  static num? tryParseDisplay(String raw) {
    final s = raw.trim().replaceAll('%', '').replaceAll('t', '').trim();
    if (s.isEmpty || s == '—' || s == '-') return null;

    final thousands = RegExp(r'^-?\d{1,3}(\.\d{3})+$');
    if (thousands.hasMatch(s)) {
      return num.tryParse(s.replaceAll('.', ''));
    }
    return num.tryParse(s.replaceAll(',', '.'));
  }

  @override
  State<AnimatedCountText> createState() => _AnimatedCountTextState();
}

class _AnimatedCountTextState extends State<AnimatedCountText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _animation;
  num? _target;

  String _format(num n) {
    if (widget.formatter != null) return widget.formatter!(n);
    final abs = n.abs();
    if (abs >= 100 || n == n.roundToDouble()) {
      return AppFormat.integer(n.round());
    }
    if (abs >= 10) return n.toStringAsFixed(1);
    return n.toStringAsFixed(2);
  }

  num? get _resolvedTarget =>
      widget.numericValue ?? AnimatedCountText.tryParseDisplay(widget.value);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _target = _resolvedTarget;
    final end = (_target ?? 0).toDouble();
    _animation = Tween<double>(begin: 0, end: end).animate(
      CurvedAnimation(parent: _controller, curve: AppAnimations.countCurve),
    );
    if (_target != null) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(covariant AnimatedCountText oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = _resolvedTarget;
    if (next == null) {
      _target = null;
      return;
    }
    if (oldWidget.duration != widget.duration) {
      _controller.duration = widget.duration;
    }
    if (next != _target) {
      final from = _animation.value;
      _target = next;
      _animation = Tween<double>(begin: from, end: next.toDouble()).animate(
        CurvedAnimation(parent: _controller, curve: AppAnimations.countCurve),
      );
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_target == null) {
      return Text(
        widget.value,
        style: widget.style,
        textAlign: widget.textAlign,
        overflow: widget.overflow,
        maxLines: widget.maxLines,
      );
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        return Text(
          _format(_animation.value),
          style: widget.style,
          textAlign: widget.textAlign,
          overflow: widget.overflow,
          maxLines: widget.maxLines,
        );
      },
    );
  }
}

/// Progress bar — ~800 ms dolum hissi; değer değişince önceki orandan akar.
class AnimatedProgressBar extends StatefulWidget {
  const AnimatedProgressBar({
    super.key,
    required this.percent,
    required this.color,
    this.height = 8,
    this.duration = AppAnimations.progress,
    this.backgroundColor,
  });

  final double percent;
  final Color color;
  final double height;
  final Duration duration;
  final Color? backgroundColor;

  @override
  State<AnimatedProgressBar> createState() => _AnimatedProgressBarState();
}

class _AnimatedProgressBarState extends State<AnimatedProgressBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _animation;

  double get _target => (widget.percent / 100).clamp(0.0, 1.0);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _animation = Tween<double>(begin: 0, end: _target).animate(
      CurvedAnimation(parent: _controller, curve: AppAnimations.curve),
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant AnimatedProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.percent != widget.percent ||
        oldWidget.duration != widget.duration) {
      _controller.duration = widget.duration;
      final from = _animation.value;
      _animation = Tween<double>(begin: from, end: _target).animate(
        CurvedAnimation(parent: _controller, curve: AppAnimations.curve),
      );
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: SizedBox(
            height: widget.height,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ColoredBox(
                  color: widget.backgroundColor ?? AppColors.border,
                ),
                FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: _animation.value,
                  child: ColoredBox(color: widget.color),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Hızlı (80 ms) checkbox işaret animasyonu.
class AppAnimatedCheckbox extends StatefulWidget {
  const AppAnimatedCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    this.visualDensity,
    this.materialTapTargetSize,
  });

  final bool value;
  final ValueChanged<bool?>? onChanged;
  final VisualDensity? visualDensity;
  final MaterialTapTargetSize? materialTapTargetSize;

  @override
  State<AppAnimatedCheckbox> createState() => _AppAnimatedCheckboxState();
}

class _AppAnimatedCheckboxState extends State<AppAnimatedCheckbox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppAnimations.checkbox,
      value: widget.value ? 1 : 0,
    );
    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.82),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.82, end: 1.0),
        weight: 60,
      ),
    ]).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void didUpdateWidget(covariant AppAnimatedCheckbox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(bool? next) {
    AppHaptics.selection();
    widget.onChanged?.call(next);
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: Checkbox(
        value: widget.value,
        onChanged: widget.onChanged == null ? null : _onChanged,
        visualDensity: widget.visualDensity,
        materialTapTargetSize: widget.materialTapTargetSize,
      ),
    );
  }
}
