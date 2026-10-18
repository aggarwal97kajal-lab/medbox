import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../widgets/aurora_background.dart';
import '../widgets/glass_nav_bar.dart';
import 'alerts_screen.dart';
import 'box_screen.dart';
import 'home_screen.dart';
import 'scan_screen.dart';
import 'settings_screen.dart';

class Shell extends StatefulWidget {
  const Shell({super.key});

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int _index = 0;

  void _go(int i) => setState(() => _index = i);

  Widget _page() => switch (_index) {
        0 => HomeScreen(onSeeAll: () => _go(1), onAlerts: () => _go(2)),
        1 => const BoxScreen(),
        2 => const AlertsScreen(),
        _ => const SettingsScreen(),
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      extendBody: true,
      body: AuroraBackground(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 450),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeIn,
          transitionBuilder: (child, a) => FadeTransition(
            opacity: a,
            child: SlideTransition(
              position: Tween(begin: const Offset(0, 0.03), end: Offset.zero).animate(a),
              child: child,
            ),
          ),
          child: KeyedSubtree(key: ValueKey(_index), child: _page()),
        ),
      ),
      bottomNavigationBar: GlassNavBar(
        index: _index,
        onTap: _go,
        onScan: () => openScan(context),
      ),
    );
  }
}
