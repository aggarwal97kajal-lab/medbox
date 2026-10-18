import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../core/strings.dart';
import '../core/theme.dart';
import '../data/medicine.dart';

/// Frosted-glass card.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 24,
    this.tint,
    this.borderColor,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? tint;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(radius);
    // Translucent fill instead of a live BackdropFilter: lists of blurred
    // cards are very slow on many Android phones.
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: r,
        color: tint == null
            ? const Color(0xFF141C25).withValues(alpha: 0.72)
            : Color.alphaBlend(tint!.withValues(alpha: 0.12), const Color(0xFF141C25)).withValues(alpha: 0.85),
        border: Border.all(color: borderColor ?? Colors.white.withValues(alpha: 0.10)),
      ),
      child: child,
    );
  }
}

/// Springy press feedback for anything tappable.
class Pressable extends StatefulWidget {
  const Pressable({super.key, required this.child, required this.onTap, this.label});

  final Widget child;
  final VoidCallback? onTap;
  final String? label;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  void _set(bool v) => setState(() => _down = v);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _set(true),
        onTapUp: (_) => _set(false),
        onTapCancel: () => _set(false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _down ? 0.96 : 1,
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOut,
          child: widget.child,
        ),
      ),
    );
  }
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({super.key, required this.label, required this.onTap, this.icon, this.color});

  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final glow = color ?? AppColors.mint;
    return Pressable(
      onTap: onTap,
      child: Container(
        height: 54,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          gradient: color == null
              ? AppColors.brandGradient
              : LinearGradient(colors: [color!, Color.lerp(color, Colors.white, 0.25)!]),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(color: glow.withValues(alpha: 0.35), blurRadius: 22, offset: const Offset(0, 8)),
          ],
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[
            Icon(icon, color: AppColors.bg, size: 20),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: ts(15, weight: FontWeight.w800, color: AppColors.bg)),
          ),
        ]),
      ),
    );
  }
}

class SecondaryButton extends StatelessWidget {
  const SecondaryButton({super.key, required this.label, required this.onTap, this.icon, this.color = AppColors.text});

  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        height: 54,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: ts(15, weight: FontWeight.w700, color: color)),
          ),
        ]),
      ),
    );
  }
}

class CircleIconButton extends StatelessWidget {
  const CircleIconButton({super.key, required this.icon, required this.onTap, required this.label});

  final IconData icon;
  final VoidCallback onTap;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      label: label,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.07),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: Icon(icon, size: 20, color: AppColors.text),
      ),
    );
  }
}

/// Number that counts up from 0 when it first appears.
class CountUp extends StatelessWidget {
  const CountUp({
    super.key,
    required this.value,
    required this.style,
    this.suffix = '',
    this.duration = const Duration(milliseconds: 1200),
  });

  final num value;
  final TextStyle style;
  final String suffix;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.toDouble()),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (_, v, __) => Text('${v.round()}$suffix', style: style),
    );
  }
}

/// Animated circular progress with gradient stroke and glow.
class ExpiryRing extends StatelessWidget {
  const ExpiryRing({
    super.key,
    required this.progress,
    required this.size,
    required this.colors,
    this.stroke = 12,
    this.child,
  });

  final double progress;
  final double size;
  final List<Color> colors;
  final double stroke;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: progress.clamp(0.0, 1.0)),
      duration: const Duration(milliseconds: 1500),
      curve: Curves.easeOutCubic,
      child: child,
      builder: (context, v, child) => CustomPaint(
        painter: _RingPainter(v, colors, stroke),
        child: SizedBox.square(dimension: size, child: Center(child: child)),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.v, this.colors, this.stroke);

  final double v;
  final List<Color> colors;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(stroke / 2 + 4);
    final track = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    canvas.drawArc(rect, 0, 2 * math.pi, false, track);
    if (v <= 0.001) return;

    final shader = SweepGradient(
      colors: [...colors, colors.first],
      transform: const GradientRotation(-math.pi / 2),
    ).createShader(rect);
    final sweep = 2 * math.pi * v;

    final glow = Paint()
      ..shader = shader
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawArc(rect, -math.pi / 2, sweep, false, glow);

    final fg = Paint()
      ..shader = shader
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, -math.pi / 2, sweep, false, fg);
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.v != v || old.colors != colors;
}

/// EN | हिं switch with a springy sliding thumb.
class LangToggle extends StatelessWidget {
  const LangToggle({super.key});

  @override
  Widget build(BuildContext context) {
    final hi = context.isHindi;
    return Semantics(
      button: true,
      label: 'Switch language / भाषा बदलें',
      child: GestureDetector(
        onTap: toggleLanguage,
        child: Container(
          width: 96,
          height: 44,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: Stack(children: [
            AnimatedAlign(
              alignment: hi ? Alignment.centerRight : Alignment.centerLeft,
              duration: const Duration(milliseconds: 420),
              curve: Curves.easeOutBack,
              child: Container(
                width: 44,
                height: 36,
                decoration: BoxDecoration(
                  gradient: AppColors.brandGradient,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(color: AppColors.mint.withValues(alpha: 0.45), blurRadius: 14),
                  ],
                ),
              ),
            ),
            Row(children: [
              Expanded(
                child: Center(
                  child: Text('EN',
                      style: ts(13, weight: FontWeight.w800, color: hi ? AppColors.muted : AppColors.bg)),
                ),
              ),
              Expanded(
                child: Center(
                  child: Text('हिं',
                      style: ts(14, weight: FontWeight.w800, color: hi ? AppColors.bg : AppColors.muted)),
                ),
              ),
            ]),
          ]),
        ),
      ),
    );
  }
}

class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(text, style: ts(12, weight: FontWeight.w800, color: color)),
    );
  }
}

class MedIcon extends StatelessWidget {
  const MedIcon({super.key, required this.med, required this.size, required this.color});

  final Medicine med;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.32),
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.30), color.withValues(alpha: 0.08)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Icon(med.icon, color: color, size: size * 0.48),
    );
  }
}

/// Thin bar showing how much of the shelf life is used.
class LifeBar extends StatelessWidget {
  const LifeBar({super.key, required this.value, required this.color});

  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Container(
        height: 5,
        color: Colors.white.withValues(alpha: 0.08),
        alignment: Alignment.centerLeft,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: value),
          duration: const Duration(milliseconds: 1100),
          curve: Curves.easeOutCubic,
          builder: (_, v, __) => FractionallySizedBox(
            widthFactor: v,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [color.withValues(alpha: 0.5), color]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 100});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: BorderRadius.circular(size * 0.3),
        boxShadow: [
          BoxShadow(color: AppColors.mint.withValues(alpha: 0.5), blurRadius: 40),
        ],
      ),
      child: Stack(children: [
        Center(child: Icon(Icons.medication_rounded, color: AppColors.bg, size: size * 0.52)),
        Positioned(
          right: size * 0.12,
          bottom: size * 0.12,
          child: Container(
            padding: EdgeInsets.all(size * 0.03),
            decoration: const BoxDecoration(color: AppColors.bg, shape: BoxShape.circle),
            child: Icon(Icons.schedule_rounded, color: AppColors.mint, size: size * 0.22),
          ),
        ),
      ]),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle({super.key, required this.title, this.action, this.onAction});

  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(child: Text(title, style: ts(18, weight: FontWeight.w800))),
      if (action != null)
        TextButton(
          onPressed: onAction,
          child: Text(action!, style: ts(14, weight: FontWeight.w700, color: AppColors.mint)),
        ),
    ]);
  }
}

/// Small looping pulse used for "live" dots.
extension PulseX on Widget {
  Widget pulse({double to = 1.25, Duration period = const Duration(milliseconds: 800)}) =>
      animate(onPlay: (c) => c.repeat(reverse: true))
          .scale(begin: const Offset(1, 1), end: Offset(to, to), duration: period, curve: Curves.easeInOut);
}
