import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../core/strings.dart';
import '../core/theme.dart';
import '../data/medicine.dart';
import '../widgets/common.dart';

void openScan(BuildContext context) {
  Navigator.of(context).push(PageRouteBuilder(
    transitionDuration: const Duration(milliseconds: 550),
    reverseTransitionDuration: const Duration(milliseconds: 350),
    pageBuilder: (_, __, ___) => const ScanScreen(),
    transitionsBuilder: (_, a, __, child) {
      final curved = CurvedAnimation(parent: a, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(scale: Tween(begin: 1.08, end: 1.0).animate(curved), child: child),
      );
    },
  ));
}

/// Scanner UI.
///
/// The camera area is a styled placeholder. To read real strips, replace
/// [_CameraMock] with `CameraPreview` from the `camera` package and run the
/// frame through `google_mlkit_text_recognition`, then parse "EXP MM/YYYY".
/// The detection timer below simulates that result.
class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _laser =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1700))
        ..repeat(reverse: true);
  Timer? _timer;
  bool _detected = false;
  int _mode = 0;
  int _qty = 15;
  DateTime _expiry = DateTime(2027, 3, 31);

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 2600), () {
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      setState(() => _detected = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _laser.dispose();
    super.dispose();
  }

  Future<void> _editDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiry,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 10),
    );
    if (picked != null) setState(() => _expiry = picked);
  }

  void _add() {
    final messenger = ScaffoldMessenger.of(context);
    final msg = context.tr('added', {'name': 'Dolo 650'});
    store.add(Medicine(
      id: 'scan-${DateTime.now().millisecondsSinceEpoch}',
      name: 'Dolo 650',
      generic: 'Paracetamol 650 mg',
      form: 'form_tablet',
      use: 'use_fever',
      owner: 'owner_everyone',
      place: 'place_kitchen',
      unit: 'unit_tablets',
      qty: _qty,
      expiry: _expiry,
      bought: DateTime.now(),
    ));
    Navigator.of(context).pop();
    messenger.showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return Scaffold(
      backgroundColor: const Color(0xFF05080B),
      body: Stack(children: [
        const Positioned.fill(child: _CameraMock()),
        Positioned(
          left: 20,
          right: 20,
          top: top + 12,
          child: Row(children: [
            CircleIconButton(icon: Icons.close_rounded, onTap: () => Navigator.of(context).pop(), label: 'Close'),
            Expanded(
              child: Text(context.tr('scan_title'),
                  textAlign: TextAlign.center, style: ts(16, weight: FontWeight.w800)),
            ),
            CircleIconButton(icon: Icons.flash_on_rounded, onTap: () {}, label: 'Flash'),
          ]).animate().fadeIn(duration: 400.ms).slideY(begin: -0.5),
        ),
        Align(
          alignment: const Alignment(0, -0.42),
          child: SizedBox(
            width: 300,
            height: 300,
            child: Stack(children: [
              Center(
                child: _StripMock(detected: _detected)
                    .animate()
                    .fadeIn(duration: 600.ms)
                    .scale(begin: const Offset(0.85, 0.85), curve: Curves.easeOutBack, duration: 700.ms),
              ),
              Positioned.fill(
                child: CustomPaint(painter: _CornerPainter(_detected ? AppColors.mint : Colors.white))
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .scale(begin: const Offset(1, 1), end: const Offset(1.035, 1.035), duration: 900.ms),
              ),
              if (!_detected)
                AnimatedBuilder(
                  animation: _laser,
                  builder: (context, _) => Positioned(
                    left: 22,
                    right: 22,
                    top: 20 + 256 * _laser.value,
                    child: Container(
                      height: 3,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [
                          AppColors.mint.withValues(alpha: 0),
                          AppColors.mint,
                          AppColors.mint.withValues(alpha: 0),
                        ]),
                        boxShadow: [BoxShadow(color: AppColors.mint.withValues(alpha: 0.8), blurRadius: 16)],
                      ),
                    ),
                  ),
                ),
            ]),
          ),
        ),
        Align(
          alignment: const Alignment(0, 0.24),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _detected
                ? const SizedBox.shrink()
                : Text(context.tr('scanning'), style: ts(15, weight: FontWeight.w700, color: AppColors.mint))
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .fade(begin: 0.35, end: 1, duration: 700.ms),
          ),
        ),
        Align(
          alignment: const Alignment(0, 0.42),
          child: _ModeSelector(index: _mode, onChanged: (i) => setState(() => _mode = i))
              .animate(delay: 300.ms)
              .fadeIn()
              .slideY(begin: 0.5),
        ),
        AnimatedPositioned(
          duration: const Duration(milliseconds: 650),
          curve: Curves.easeOutCubic,
          left: 0,
          right: 0,
          bottom: _detected ? 0 : -460,
          child: _ResultSheet(
            detected: _detected,
            qty: _qty,
            expiry: _expiry,
            onQty: (v) => setState(() => _qty = v.clamp(1, 999)),
            onEdit: _editDate,
            onAdd: _add,
          ),
        ),
      ]),
    );
  }
}

class _CameraMock extends StatelessWidget {
  const _CameraMock();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -0.4),
          radius: 1.1,
          colors: [Color(0xFF22303A), Color(0xFF05080B)],
        ),
      ),
    );
  }
}

class _StripMock extends StatelessWidget {
  const _StripMock({required this.detected});

  final bool detected;

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF26323A);
    return Transform.rotate(
      angle: -0.1,
      child: Container(
        width: 232,
        height: 136,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [Color(0xFFE6EBEF), Color(0xFFB4BEC6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 30, offset: const Offset(0, 14))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            for (var i = 0; i < 5; i++)
              Container(
                width: 34,
                height: 24,
                margin: const EdgeInsets.only(right: 7),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFA9B3BA)),
                ),
              ),
          ]),
          const Spacer(),
          Text('PARACETAMOL 650 mg',
              style: ts(11, weight: FontWeight.w800, color: ink, letterSpacing: 0.6)),
          const SizedBox(height: 6),
          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.amber,
              borderRadius: BorderRadius.circular(5),
              border: Border.all(color: detected ? AppColors.mint : Colors.transparent, width: 2),
              boxShadow: detected
                  ? [BoxShadow(color: AppColors.mint.withValues(alpha: 0.9), blurRadius: 18, spreadRadius: 2)]
                  : const [],
            ),
            child: Text('EXP 03/2027', style: ts(11, weight: FontWeight.w800, color: AppColors.bg)),
          )
              .animate(target: detected ? 1 : 0)
              .scale(begin: const Offset(1, 1), end: const Offset(1.18, 1.18), curve: Curves.easeOutBack, duration: 450.ms),
        ]),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  _CornerPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const len = 42.0;
    const r = 22.0;
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    final w = size.width, h = size.height;
    final corners = [
      Path()
        ..moveTo(0, len)
        ..lineTo(0, r)
        ..quadraticBezierTo(0, 0, r, 0)
        ..lineTo(len, 0),
      Path()
        ..moveTo(w - len, 0)
        ..lineTo(w - r, 0)
        ..quadraticBezierTo(w, 0, w, r)
        ..lineTo(w, len),
      Path()
        ..moveTo(w, h - len)
        ..lineTo(w, h - r)
        ..quadraticBezierTo(w, h, w - r, h)
        ..lineTo(w - len, h),
      Path()
        ..moveTo(len, h)
        ..lineTo(r, h)
        ..quadraticBezierTo(0, h, 0, h - r)
        ..lineTo(0, h - len),
    ];
    for (final c in corners) {
      canvas.drawPath(c, p);
    }
  }

  @override
  bool shouldRepaint(_CornerPainter old) => old.color != color;
}

class _ModeSelector extends StatelessWidget {
  const _ModeSelector({required this.index, required this.onChanged});

  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final labels = [context.tr('mode_strip'), context.tr('mode_bill'), context.tr('mode_barcode')];
    return Container(
      width: 300,
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Stack(children: [
        AnimatedAlign(
          alignment: Alignment(-1.0 + index, 0),
          duration: const Duration(milliseconds: 380),
          curve: Curves.easeOutBack,
          child: FractionallySizedBox(
            widthFactor: 1 / 3,
            child: Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
            ),
          ),
        ),
        Row(children: [
          for (var i = 0; i < 3; i++)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onChanged(i),
                child: Center(
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 250),
                    style: ts(13.5,
                        weight: i == index ? FontWeight.w800 : FontWeight.w600,
                        color: i == index ? AppColors.bg : Colors.white),
                    child: Text(labels[i]),
                  ),
                ),
              ),
            ),
        ]),
      ]),
    );
  }
}

class _ResultSheet extends StatelessWidget {
  const _ResultSheet({
    required this.detected,
    required this.qty,
    required this.expiry,
    required this.onQty,
    required this.onEdit,
    required this.onAdd,
  });

  final bool detected;
  final int qty;
  final DateTime expiry;
  final ValueChanged<int> onQty;
  final VoidCallback onEdit;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          padding: EdgeInsets.fromLTRB(22, 12, 22, bottom + 22),
          decoration: BoxDecoration(
            color: AppColors.sheet.withValues(alpha: 0.92),
            border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.12))),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(
              child: Container(
                width: 42,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(children: [
              Container(
                width: 30,
                height: 30,
                decoration: const BoxDecoration(color: AppColors.mint, shape: BoxShape.circle),
                child: const Icon(Icons.check_rounded, color: AppColors.bg, size: 20),
              )
                  .animate(target: detected ? 1 : 0)
                  .scale(begin: Offset.zero, end: const Offset(1, 1), delay: 300.ms, duration: 900.ms, curve: Curves.elasticOut),
              const SizedBox(width: 10),
              Text(context.tr('detected'), style: ts(14, weight: FontWeight.w800, color: AppColors.mint)),
            ]),
            const SizedBox(height: 12),
            Text('Dolo 650', style: display(28)),
            const SizedBox(height: 2),
            Text('Paracetamol 650 mg · ${context.tr('form_tablet')} · ${context.tr('use_fever')}',
                style: ts(13.5, color: AppColors.muted)),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(
                child: _Field(
                  label: context.tr('expiry'),
                  child: Text(context.fmtDate(expiry, withDay: false), style: ts(17, weight: FontWeight.w800)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _Field(
                  label: context.tr('quantity'),
                  child: Row(children: [
                    _Step(icon: Icons.remove_rounded, onTap: () => onQty(qty - 1)),
                    Expanded(
                      child: Center(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
                          child: Text('$qty', key: ValueKey(qty), style: ts(17, weight: FontWeight.w800)),
                        ),
                      ),
                    ),
                    _Step(icon: Icons.add_rounded, onTap: () => onQty(qty + 1)),
                  ]),
                ),
              ),
            ]),
            const SizedBox(height: 18),
            Row(children: [
              Expanded(child: SecondaryButton(label: context.tr('edit'), icon: Icons.edit_calendar_rounded, onTap: onEdit)),
              const SizedBox(width: 10),
              Expanded(
                child: PrimaryButton(label: context.tr('add_to_box'), icon: Icons.add_rounded, onTap: onAdd),
              ),
            ]),
          ]),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 74,
      padding: const EdgeInsets.fromLTRB(14, 10, 10, 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: ts(12, color: AppColors.muted)),
        const Spacer(),
        child,
      ]),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 18, color: AppColors.text),
      ),
    );
  }
}
