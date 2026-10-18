import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../core/strings.dart';
import '../core/theme.dart';
import '../data/medicine.dart';
import '../data/prices.dart';
import '../widgets/common.dart';
import 'compare_screen.dart';

void openBrowser(BuildContext context, Medicine med, Pharmacy start) {
  Navigator.of(context).push(PageRouteBuilder(
    transitionDuration: const Duration(milliseconds: 500),
    reverseTransitionDuration: const Duration(milliseconds: 350),
    pageBuilder: (_, __, ___) => BrowserScreen(med: med, start: start),
    transitionsBuilder: (_, a, __, child) {
      final curved = CurvedAnimation(parent: a, curve: Curves.easeOutCubic);
      return SlideTransition(
        position: Tween(begin: const Offset(0, 1), end: Offset.zero).animate(curved),
        child: child,
      );
    },
  ));
}

/// Opens each pharmacy's real search page inside the app. The user reads the
/// price on the page and types it in the bar at the bottom. Nothing is
/// scraped: the page is shown exactly like a normal browser shows it.
class BrowserScreen extends StatefulWidget {
  const BrowserScreen({super.key, required this.med, required this.start});

  final Medicine med;
  final Pharmacy start;

  @override
  State<BrowserScreen> createState() => _BrowserScreenState();
}

class _BrowserScreenState extends State<BrowserScreen> {
  late Pharmacy _current = widget.start;
  final _price = TextEditingController();
  final _tabs = ScrollController();
  int _progress = 0;
  bool _savedPop = false;

  late final WebViewController _web = WebViewController()
    ..setJavaScriptMode(JavaScriptMode.unrestricted)
    ..setBackgroundColor(Colors.white)
    ..setNavigationDelegate(NavigationDelegate(
      onProgress: (p) {
        if (mounted) setState(() => _progress = p);
      },
    ))
    ..loadRequest(widget.start.searchUri(widget.med.name));

  @override
  void dispose() {
    _price.dispose();
    _tabs.dispose();
    super.dispose();
  }

  void _go(Pharmacy p) {
    if (p.id == _current.id) return;
    final prev = priceBook.of(widget.med.id)[p.id];
    setState(() {
      _current = p;
      _progress = 0;
      _price.text = prev?.price?.toStringAsFixed(2) ?? '';
    });
    _web.loadRequest(p.searchUri(widget.med.name));
    final i = pharmacies.indexOf(p);
    if (_tabs.hasClients) {
      _tabs.animateTo(
        (i * 128.0 - 60).clamp(0.0, _tabs.position.maxScrollExtent),
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
      );
    }
  }

  Future<void> _save({required bool available}) async {
    double? value;
    if (available) {
      value = double.tryParse(_price.text.replaceAll(',', '').replaceAll('₹', '').trim());
      if (value == null || value <= 0) return;
    }
    HapticFeedback.lightImpact();
    FocusScope.of(context).unfocus();
    priceBook.save(widget.med.id, _current.id, value);
    setState(() => _savedPop = true);
    await Future<void>.delayed(const Duration(milliseconds: 650));
    if (!mounted) return;
    setState(() => _savedPop = false);
    final next = priceBook.nextUnchecked(widget.med.id, afterId: _current.id);
    if (next == null) {
      final msg = context.tr('all_done');
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop();
      messenger.showSnackBar(SnackBar(content: Text(msg)));
    } else {
      _go(next);
    }
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(children: [
        SizedBox(height: top + 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(children: [
            CircleIconButton(icon: Icons.close_rounded, onTap: () => Navigator.of(context).pop(), label: 'Close'),
            const SizedBox(width: 12),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Column(
                  key: ValueKey(_current.id),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_current.name, style: ts(16, weight: FontWeight.w800)),
                    Row(children: [
                      const Icon(Icons.lock_rounded, size: 12, color: AppColors.muted),
                      const SizedBox(width: 4),
                      Text(_current.domain, style: ts(12, color: AppColors.muted)),
                    ]),
                  ],
                ),
              ),
            ),
            CircleIconButton(
              icon: Icons.open_in_new_rounded,
              label: context.tr('open_browser'),
              onTap: () => launchUrl(_current.searchUri(widget.med.name), mode: LaunchMode.externalApplication),
            ),
          ]),
        ),
        const SizedBox(height: 12),
        ListenableBuilder(
          listenable: priceBook,
          builder: (context, _) => SizedBox(
            height: 44,
            child: ListView.separated(
              controller: _tabs,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: pharmacies.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final p = pharmacies[i];
                final e = priceBook.of(widget.med.id)[p.id];
                final sel = p.id == _current.id;
                return Pressable(
                  onTap: () => _go(p),
                  label: p.name,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.fromLTRB(6, 6, 12, 6),
                    decoration: BoxDecoration(
                      color: sel ? p.color.withValues(alpha: 0.18) : Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: sel ? p.color : Colors.white.withValues(alpha: 0.10)),
                    ),
                    child: Row(children: [
                      PharmacyAvatar(p: p, size: 30),
                      const SizedBox(width: 8),
                      Text(p.name.split(' ').first, style: ts(13, weight: FontWeight.w700)),
                      if (e != null) ...[
                        const SizedBox(width: 6),
                        Icon(e.available ? Icons.check_circle_rounded : Icons.block_rounded,
                                size: 16, color: e.available ? AppColors.mint : AppColors.muted)
                            .animate()
                            .scale(begin: Offset.zero, end: const Offset(1, 1), curve: Curves.elasticOut, duration: 600.ms),
                      ],
                    ]),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 10),
        AnimatedOpacity(
          duration: const Duration(milliseconds: 300),
          opacity: _progress < 100 ? 1 : 0,
          child: LinearProgressIndicator(
            value: _progress / 100,
            minHeight: 3,
            color: AppColors.mint,
            backgroundColor: Colors.transparent,
          ),
        ),
        Expanded(
          child: Stack(children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: WebViewWidget(controller: _web),
              ),
            ),
            if (_savedPop)
              Positioned.fill(
                child: ColoredBox(
                  color: AppColors.bg.withValues(alpha: 0.55),
                  child: Center(
                    child: Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        gradient: AppColors.brandGradient,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: AppColors.mint.withValues(alpha: 0.6), blurRadius: 40)],
                      ),
                      child: const Icon(Icons.check_rounded, color: AppColors.bg, size: 56),
                    ).animate().scale(begin: Offset.zero, end: const Offset(1, 1), curve: Curves.elasticOut, duration: 600.ms),
                  ),
                ),
              ).animate().fadeIn(duration: 150.ms),
          ]),
        ),
        _PriceBar(
          controller: _price,
          onSave: () => _save(available: true),
          onUnavailable: () => _save(available: false),
        ),
      ]),
    );
  }
}

class _PriceBar extends StatelessWidget {
  const _PriceBar({required this.controller, required this.onSave, required this.onUnavailable});

  final TextEditingController controller;
  final VoidCallback onSave;
  final VoidCallback onUnavailable;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return ClipRect(
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: EdgeInsets.fromLTRB(16, 12, 16, bottom + 12),
          decoration: BoxDecoration(
            color: AppColors.sheet.withValues(alpha: 0.96),
            border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.10))),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(context.tr('enter_price'), style: ts(12.5, color: AppColors.muted))),
              GestureDetector(
                onTap: onUnavailable,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Text(context.tr('not_available'),
                      style: ts(12.5, weight: FontWeight.w700, color: AppColors.muted)
                          .copyWith(decoration: TextDecoration.underline)),
                ),
              ),
            ]),
            const SizedBox(height: 6),
            Row(children: [
              Expanded(
                child: Container(
                  height: 54,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.mint.withValues(alpha: 0.4)),
                  ),
                  child: Row(children: [
                    Text('₹', style: ts(20, weight: FontWeight.w800, color: AppColors.mint)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: TextField(
                        controller: controller,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                        style: ts(20, weight: FontWeight.w800),
                        cursorColor: AppColors.mint,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: '0.00',
                          hintStyle: ts(20, weight: FontWeight.w800, color: AppColors.muted.withValues(alpha: 0.5)),
                        ),
                        onSubmitted: (_) => onSave(),
                      ),
                    ),
                  ]),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 164,
                child: PrimaryButton(label: context.tr('save_next'), icon: Icons.check_rounded, onTap: onSave),
              ),
            ]),
          ]),
        ),
      ),
    );
  }
}
