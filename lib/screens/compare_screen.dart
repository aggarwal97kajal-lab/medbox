import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/strings.dart';
import '../core/theme.dart';
import '../data/medicine.dart';
import '../data/prices.dart';
import '../widgets/aurora_background.dart';
import '../widgets/common.dart';
import 'browser_screen.dart';

void openCompare(BuildContext context, Medicine m) {
  Navigator.of(context).push(PageRouteBuilder(
    transitionDuration: const Duration(milliseconds: 550),
    reverseTransitionDuration: const Duration(milliseconds: 350),
    pageBuilder: (_, __, ___) => CompareScreen(med: m),
    transitionsBuilder: (_, a, __, child) {
      final curved = CurvedAnimation(parent: a, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween(begin: const Offset(0, 0.06), end: Offset.zero).animate(curved),
          child: child,
        ),
      );
    },
  ));
}

String rupees(double v) => '₹${v.toStringAsFixed(2)}';

String checkedLabel(BuildContext context, PriceEntry e) {
  final mins = DateTime.now().difference(e.at).inMinutes;
  return mins < 1 ? context.tr('checked_now') : context.tr('checked_ago', {'n': mins});
}

/// "Quick compare": no server. The user opens each pharmacy inside the app,
/// sees the real price, saves it; this screen ranks what they found.
class CompareScreen extends StatelessWidget {
  const CompareScreen({super.key, required this.med});

  final Medicine med;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: AuroraBackground(
        intensity: 0.26,
        child: ListenableBuilder(
          listenable: priceBook,
          builder: (context, _) {
            final entries = priceBook.of(med.id);
            final ranked = priceBook.ranked(med.id);
            final done = entries.length;
            final rows = _orderedRows(entries);
            final bestId = ranked.isEmpty ? null : ranked.first.$1.id;

            return ListView(
              padding: EdgeInsets.fromLTRB(20, top + 12, 20, 40),
              children: [
                Row(children: [
                  CircleIconButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onTap: () => Navigator.of(context).pop(),
                    label: 'Back',
                  ),
                  Expanded(
                    child: Text(context.tr('compare_title'),
                        textAlign: TextAlign.center, style: ts(17, weight: FontWeight.w800)),
                  ),
                  const LangToggle(),
                ]),
                const SizedBox(height: 20),
                _MedHeader(med: med).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2),
                const SizedBox(height: 16),
                _Progress(done: done, total: pharmacies.length)
                    .animate(delay: 100.ms)
                    .fadeIn(duration: 400.ms),
                const SizedBox(height: 16),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  transitionBuilder: (c, a) => FadeTransition(
                    opacity: a,
                    child: ScaleTransition(scale: Tween(begin: 0.95, end: 1.0).animate(a), child: c),
                  ),
                  child: ranked.isEmpty
                      ? _StartCard(key: const ValueKey('start'), onTap: () => _checkNext(context))
                      : _BestCard(
                          key: ValueKey('best-${ranked.first.$1.id}'),
                          med: med,
                          best: ranked.first,
                          costliest: ranked.last,
                        ),
                ),
                const SizedBox(height: 22),
                Text(context.tr('qc_hint'), style: ts(13, color: AppColors.muted, height: 1.4)),
                const SizedBox(height: 12),
                for (var i = 0; i < rows.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _PharmacyRow(
                      pharmacy: rows[i],
                      entry: entries[rows[i].id],
                      isBest: rows[i].id == bestId,
                      onTap: () => openBrowser(context, med, rows[i]),
                    )
                        .animate(delay: (200 + i * 70).ms)
                        .fadeIn(duration: 380.ms)
                        .slideX(begin: 0.15, curve: Curves.easeOutCubic),
                  ),
                const SizedBox(height: 6),
                GlassCard(
                  tint: AppColors.mint,
                  borderColor: AppColors.mint.withValues(alpha: 0.3),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Icon(Icons.lightbulb_rounded, color: AppColors.mint),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(context.tr('generic_title'), style: ts(15, weight: FontWeight.w800)),
                        const SizedBox(height: 4),
                        Text(context.tr('generic_body'), style: ts(13.5, height: 1.45)),
                        const SizedBox(height: 6),
                        Text(context.tr('generic_note'), style: ts(12, color: AppColors.muted, height: 1.4)),
                      ]),
                    ),
                  ]),
                ).animate(delay: 700.ms).fadeIn(duration: 450.ms),
                const SizedBox(height: 14),
                Center(
                  child: Text(context.tr('prices_note'),
                      textAlign: TextAlign.center, style: ts(12, color: AppColors.muted, height: 1.4)),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Found prices (cheapest first), then "not available", then unchecked.
  List<Pharmacy> _orderedRows(Map<String, PriceEntry> entries) {
    int rank(Pharmacy p) {
      final e = entries[p.id];
      if (e == null) return 2;
      return e.available ? 0 : 1;
    }

    return [...pharmacies]..sort((a, b) {
        final r = rank(a).compareTo(rank(b));
        if (r != 0) return r;
        if (rank(a) == 0) return entries[a.id]!.price!.compareTo(entries[b.id]!.price!);
        return pharmacies.indexOf(a).compareTo(pharmacies.indexOf(b));
      });
  }

  void _checkNext(BuildContext context) {
    final p = priceBook.nextUnchecked(med.id) ?? pharmacies.first;
    openBrowser(context, med, p);
  }
}

class _MedHeader extends StatelessWidget {
  const _MedHeader({required this.med});

  final Medicine med;

  @override
  Widget build(BuildContext context) {
    final c = statusColor(store.statusOf(med));
    return GlassCard(
      padding: const EdgeInsets.all(14),
      radius: 22,
      child: Row(children: [
        MedIcon(med: med, size: 52, color: c),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(med.name, style: ts(17, weight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text('${context.tr('pack_of', {'n': 15})} · ${med.generic}',
                maxLines: 1, overflow: TextOverflow.ellipsis, style: ts(13, color: AppColors.muted)),
          ]),
        ),
      ]),
    );
  }
}

class _Progress extends StatelessWidget {
  const _Progress({required this.done, required this.total});

  final int done;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Text(context.tr('qc_checked', {'n': done, 't': total}),
          style: ts(13, weight: FontWeight.w700, color: done == total ? AppColors.mint : AppColors.text)),
      const SizedBox(width: 12),
      Expanded(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Container(
            height: 6,
            color: Colors.white.withValues(alpha: 0.08),
            alignment: Alignment.centerLeft,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: done / total),
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOutCubic,
              builder: (_, v, __) => FractionallySizedBox(
                widthFactor: v,
                child: Container(decoration: const BoxDecoration(gradient: AppColors.brandGradient)),
              ),
            ),
          ),
        ),
      ),
    ]);
  }
}

class PharmacyAvatar extends StatelessWidget {
  const PharmacyAvatar({super.key, required this.p, required this.size});

  final Pharmacy p;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Color.alphaBlend(p.color.withValues(alpha: 0.16), AppColors.bg),
        borderRadius: BorderRadius.circular(size * 0.32),
        border: Border.all(color: p.color.withValues(alpha: 0.4)),
      ),
      child: Text(p.initials, style: ts(size * 0.3, weight: FontWeight.w800, color: p.color)),
    );
  }
}

class _StartCard extends StatelessWidget {
  const _StartCard({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: [AppColors.mint.withValues(alpha: 0.22), AppColors.sky.withValues(alpha: 0.06)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: AppColors.mint.withValues(alpha: 0.5), width: 1.5),
        boxShadow: [BoxShadow(color: AppColors.mint.withValues(alpha: 0.15), blurRadius: 30)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
          height: 44,
          child: Stack(children: [
            for (var i = 0; i < pharmacies.length; i++)
              Positioned(
                left: i * 30.0,
                child: PharmacyAvatar(p: pharmacies[i], size: 44)
                    .animate(delay: (150 + i * 80).ms)
                    .scale(begin: Offset.zero, end: const Offset(1, 1), duration: 500.ms, curve: Curves.easeOutBack),
              ),
          ]),
        ),
        const SizedBox(height: 16),
        Text(context.tr('start_checking'), style: display(22)),
        const SizedBox(height: 4),
        Text(context.tr('start_sub'), style: ts(13, color: AppColors.muted)),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: PrimaryButton(label: context.tr('start_checking'), icon: Icons.travel_explore_rounded, onTap: onTap),
        ),
      ]),
    );
  }
}

class _BestCard extends StatelessWidget {
  const _BestCard({super.key, required this.med, required this.best, required this.costliest});

  final Medicine med;
  final (Pharmacy, PriceEntry) best;
  final (Pharmacy, PriceEntry) costliest;

  @override
  Widget build(BuildContext context) {
    final (p, e) = best;
    final diff = costliest.$2.price! - e.price!;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: [AppColors.mint.withValues(alpha: 0.20), AppColors.sky.withValues(alpha: 0.06)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: AppColors.mint.withValues(alpha: 0.5), width: 1.5),
        boxShadow: [BoxShadow(color: AppColors.mint.withValues(alpha: 0.15), blurRadius: 30)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.workspace_premium_rounded, color: AppColors.mint, size: 20),
          const SizedBox(width: 6),
          Text(context.tr('cheapest_so_far'),
              style: ts(12.5, weight: FontWeight.w800, color: AppColors.mint, letterSpacing: 0.4)),
        ]),
        const SizedBox(height: 14),
        Row(children: [
          PharmacyAvatar(p: p, size: 50),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p.name, style: ts(18, weight: FontWeight.w800)),
              Text(checkedLabel(context, e), style: ts(13, color: AppColors.muted)),
            ]),
          ),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: e.price!),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (_, v, __) => Text(rupees(v), style: display(26)),
          ),
        ]),
        if (diff > 0) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.bg.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(children: [
              const Icon(Icons.savings_rounded, color: AppColors.amber, size: 22)
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .rotate(begin: -0.03, end: 0.03, duration: 600.ms),
              const SizedBox(width: 10),
              Expanded(
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: diff),
                  duration: const Duration(milliseconds: 1200),
                  curve: Curves.easeOutCubic,
                  builder: (_, v, __) => Text(context.tr('cheaper_by', {'n': v.toStringAsFixed(2)}),
                      style: ts(14, weight: FontWeight.w800, color: AppColors.amber, height: 1.35)),
                ),
              ),
            ]),
          ),
        ],
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: PrimaryButton(
            label: context.tr('buy_on', {'name': p.name}),
            icon: Icons.shopping_bag_rounded,
            onTap: () => launchUrl(p.searchUri(med.name), mode: LaunchMode.externalApplication),
          ),
        ),
      ]),
    );
  }
}

class _PharmacyRow extends StatelessWidget {
  const _PharmacyRow({required this.pharmacy, required this.entry, required this.isBest, required this.onTap});

  final Pharmacy pharmacy;
  final PriceEntry? entry;
  final bool isBest;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final e = entry;
    final sub = e == null
        ? context.tr('not_checked')
        : e.available
            ? checkedLabel(context, e)
            : context.tr('unavailable');
    final Widget trailing = e == null
        ? Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.mint.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.mint.withValues(alpha: 0.4)),
            ),
            child: Text(context.tr('check'), style: ts(13, weight: FontWeight.w800, color: AppColors.mint)),
          )
        : e.available
            ? Text(rupees(e.price!),
                style: ts(16, weight: FontWeight.w800, color: isBest ? AppColors.mint : AppColors.text))
            : const Icon(Icons.block_rounded, color: AppColors.muted, size: 20);

    return Pressable(
      onTap: onTap,
      label: pharmacy.name,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: e != null && !e.available ? 0.55 : 1,
        child: GlassCard(
          padding: const EdgeInsets.all(14),
          radius: 20,
          borderColor: isBest ? AppColors.mint.withValues(alpha: 0.6) : null,
          child: Row(children: [
            PharmacyAvatar(p: pharmacy, size: 42),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(pharmacy.name, style: ts(15, weight: FontWeight.w700)),
                Text(sub, style: ts(12.5, color: AppColors.muted)),
              ]),
            ),
            trailing,
          ]),
        ),
      ),
    );
  }
}
