import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../core/strings.dart';
import '../core/theme.dart';
import '../widgets/aurora_background.dart';
import '../widgets/common.dart';
import 'shell.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 2700), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 700),
        pageBuilder: (_, __, ___) => const Shell(),
        transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
      ));
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AuroraBackground(
        intensity: 0.45,
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const AppLogo(size: 112)
                .animate()
                .scale(begin: const Offset(0.2, 0.2), duration: 900.ms, curve: Curves.elasticOut)
                .rotate(begin: -0.25, end: 0, duration: 900.ms, curve: Curves.easeOutBack)
                .then(delay: 150.ms)
                .shimmer(duration: 1200.ms, color: Colors.white54),
            const SizedBox(height: 28),
            Text(context.tr('app_name'), style: display(38))
                .animate(delay: 450.ms)
                .fadeIn(duration: 600.ms)
                .slideY(begin: 0.6, curve: Curves.easeOutCubic),
            const SizedBox(height: 8),
            Text(context.tr('tagline'), style: ts(15, color: AppColors.muted))
                .animate(delay: 700.ms)
                .fadeIn(duration: 600.ms),
            const SizedBox(height: 44),
            Row(mainAxisSize: MainAxisSize.min, children: [
              for (var i = 0; i < 3; i++)
                Container(
                  width: 9,
                  height: 9,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: const BoxDecoration(color: AppColors.mint, shape: BoxShape.circle),
                )
                    .animate(delay: (900 + i * 150).ms, onPlay: (c) => c.repeat(reverse: true))
                    .scale(begin: const Offset(0.6, 0.6), end: const Offset(1.2, 1.2), duration: 450.ms)
                    .fade(begin: 0.4, end: 1),
            ]),
          ]),
        ),
      ),
    );
  }
}
