import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Slowly drifting, heavily blurred colour blobs behind the content.
class AuroraBackground extends StatefulWidget {
  const AuroraBackground({
    super.key,
    required this.child,
    this.colors = const [AppColors.mint, AppColors.violet, AppColors.sky],
    this.intensity = 0.32,
  });

  final Widget child;

  /// Exactly three colours.
  final List<Color> colors;
  final double intensity;

  @override
  State<AuroraBackground> createState() => _AuroraBackgroundState();
}

class _AuroraBackgroundState extends State<AuroraBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 18))
        ..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  // Soft radial-gradient blobs: looks like a heavy blur but costs almost
  // nothing to draw, so it stays smooth on low-end phones.
  Widget _blob(double x, double y, double d, Color color) => Positioned(
        left: x - d,
        top: y - d,
        child: Container(
          width: d * 2,
          height: d * 2,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [
              color.withValues(alpha: widget.intensity),
              color.withValues(alpha: widget.intensity * 0.45),
              color.withValues(alpha: 0),
            ], stops: const [0, 0.4, 1]),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return Stack(children: [
      const Positioned.fill(child: ColoredBox(color: AppColors.bg)),
      Positioned.fill(
        child: IgnorePointer(
          child: RepaintBoundary(
            child: AnimatedBuilder(
              animation: _c,
              builder: (context, _) {
                final t = _c.value * 2 * math.pi;
                return Stack(children: [
                    _blob(size.width * (0.15 + 0.12 * math.sin(t)),
                        size.height * (0.08 + 0.05 * math.cos(t)), 260,
                        widget.colors[0]),
                    _blob(size.width * (0.85 + 0.10 * math.cos(t * 1.3)),
                        size.height * (0.30 + 0.06 * math.sin(t)), 220,
                        widget.colors[1]),
                    _blob(size.width * (0.40 + 0.15 * math.sin(t + 2)),
                        size.height * (0.78 + 0.05 * math.cos(t)), 280,
                        widget.colors[2]),
                  ]);
              },
            ),
          ),
        ),
      ),
      Positioned.fill(child: widget.child),
    ]);
  }
}
