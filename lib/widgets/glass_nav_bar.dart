import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../core/strings.dart';
import '../core/theme.dart';

class GlassNavBar extends StatelessWidget {
  const GlassNavBar({super.key, required this.index, required this.onTap, required this.onScan});

  final int index;
  final ValueChanged<int> onTap;
  final VoidCallback onScan;

  static const _items = [
    (Icons.home_rounded, 'nav_home'),
    (Icons.inventory_2_rounded, 'nav_box'),
    (Icons.notifications_rounded, 'nav_alerts'),
    (Icons.tune_rounded, 'nav_settings'),
  ];

  Widget _item(BuildContext context, int i) {
    final sel = i == index;
    final (icon, key) = _items[i];
    return Expanded(
      child: Semantics(
        button: true,
        selected: sel,
        label: context.tr(key),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onTap(i),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOutBack,
              padding: EdgeInsets.symmetric(horizontal: sel ? 16 : 8, vertical: 5),
              decoration: BoxDecoration(
                color: sel ? AppColors.mint.withValues(alpha: 0.16) : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: AnimatedScale(
                scale: sel ? 1.12 : 1,
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOutBack,
                child: Icon(icon, size: 22, color: sel ? AppColors.mint : AppColors.muted),
              ),
            ),
            const SizedBox(height: 3),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 300),
              style: ts(11,
                  weight: sel ? FontWeight.w800 : FontWeight.w500,
                  color: sel ? AppColors.text : AppColors.muted),
              child: Text(context.tr(key), maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
        child: SizedBox(
          height: 96,
          child: Stack(clipBehavior: Clip.none, alignment: Alignment.bottomCenter, children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 22, sigmaY: 22),
                child: Container(
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.sheet.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
                  ),
                  child: Row(children: [
                    _item(context, 0),
                    _item(context, 1),
                    const SizedBox(width: 76),
                    _item(context, 2),
                    _item(context, 3),
                  ]),
                ),
              ),
            ),
            Positioned(top: 0, child: ScanFab(onTap: onScan)),
          ]),
        ),
      ),
    );
  }
}

/// Glowing scan button with a radar-style pulse ring.
class ScanFab extends StatelessWidget {
  const ScanFab({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: context.tr('scan_title'),
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: 66,
          height: 66,
          child: Stack(alignment: Alignment.center, children: [
            Container(
              width: 66,
              height: 66,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.mint, width: 2),
              ),
            )
                .animate(onPlay: (c) => c.repeat())
                .scale(begin: const Offset(1, 1), end: const Offset(1.55, 1.55), duration: 1600.ms)
                .fadeOut(duration: 1600.ms),
            Container(
              width: 66,
              height: 66,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.brandGradient,
                boxShadow: [
                  BoxShadow(color: AppColors.mint.withValues(alpha: 0.55), blurRadius: 24, offset: const Offset(0, 6)),
                ],
              ),
              child: const Icon(Icons.qr_code_scanner_rounded, color: AppColors.bg, size: 30),
            ),
          ]),
        ),
      ),
    );
  }
}
