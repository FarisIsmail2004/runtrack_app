import 'package:flutter/material.dart';

import '../theme/app_motion.dart';

/// One-shot fade + slide-up entrance for a child.
///
/// The optional [delay] is folded into the animation timeline (via an
/// [Interval]) rather than a [Timer], so the whole thing is frame-driven and
/// settles cleanly under `pumpAndSettle` in widget tests. Honors reduced motion
/// by showing the child instantly.
class RevealIn extends StatefulWidget {
  const RevealIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration,
    this.offset = 12,
  });

  final Widget child;
  final Duration delay;
  final Duration? duration;

  /// Pixels to slide up from.
  final double offset;

  @override
  State<RevealIn> createState() => _RevealInState();
}

class _RevealInState extends State<RevealIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _t;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    final anim = widget.duration ?? AppMotion.standard;
    final total = widget.delay + anim;
    _controller = AnimationController(vsync: this, duration: total);
    final totalUs = total.inMicroseconds;
    final start = totalUs == 0 ? 0.0 : widget.delay.inMicroseconds / totalUs;
    _t = CurvedAnimation(
      parent: _controller,
      curve: Interval(start, 1, curve: AppMotion.emphasized),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (AppMotion.reduceMotionOf(context)) {
      _controller.value = 1;
    } else {
      _controller.forward();
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
      animation: _t,
      builder: (context, child) => Opacity(
        opacity: _t.value.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, (1 - _t.value) * widget.offset),
          child: child,
        ),
      ),
      child: widget.child,
    );
  }
}
