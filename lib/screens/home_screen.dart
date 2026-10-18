import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../core/strings.dart';
import '../core/theme.dart';
import '../data/medicine.dart';
import '../widgets/common.dart';
import '../widgets/med_tile.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.onSeeAll, required this.onAlerts});

  final VoidCallback onSeeAll;
  final VoidCallback onAlerts;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final soon = store.byStatus(MedStatus.soon);
        final expired = store.byStatus(MedStatus.expired);
        final first = soon.isNotEmpty ? soon.first : null;
        return ListView(
          padding: EdgeInsets.fromLTRB(20, MediaQuery.paddingOf(context).top + 16, 20, 150),
          children: [
            _Header(hasAlert: expired.isNotEmpty, onAlerts: onAlerts)
                .animate()
                .fadeIn(duration: 500.ms)
                .slideY(begin: -0.3, curve: Curves.easeOutCubic),
            const SizedBox(height: 22),
            _HealthCard(soon: soon.length, expired: expired.length)
                .animate(delay: 100.ms)
                .fadeIn(duration: 600.ms)
                .scale(begin: const Offset(0.94, 0.94), curve: Curves.easeOutBack, duration: 700.ms),
            if (first != null) ...[
              const SizedBox(height: 14),
              _UseFirstCard(med: first)
                  .animate(delay: 260.ms)
                  .fadeIn(duration: 500.ms)
                  .slideX(begin: 0.15, curve: Curves.easeOutCubic),
            ],
            const SizedBox(height: 24),
            SectionTitle(
              title: context.tr('expiring_soon'),
              action: context.tr('see_all'),
              onAction: onSeeAll,
            ).animate(delay: 360.ms).fadeIn(),
            const SizedBox(height: 8),
            if (soon.isEmpty)
              GlassCard(child: Text(context.tr('all_clear'), style: ts(14, color: AppColors.muted))),
            for (var i = 0; i < soon.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: MedTile(med: soon[i])
                    .animate(delay: (420 + i * 90).ms)
                    .fadeIn(duration: 450.ms)
                    .slideY(begin: 0.3, curve: Curves.easeOutCubic),
              ),
          ],
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.hasAlert, required this.onAlerts});

  final bool hasAlert;
  final VoidCallback onAlerts;

  @override
  Widget build(BuildContext context) {
    final h = DateTime.now().hour;
    final greet = h < 12 ? 'greet_morning' : (h < 17 ? 'greet_afternoon' : 'greet_evening');
    return Row(children: [
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(context.tr(greet), style: ts(14, color: AppColors.muted)),
          const SizedBox(height: 4),
          Text(context.tr('home_title'), style: display(26)),
        ]),
      ),
      const LangToggle(),
      const SizedBox(width: 10),
      Stack(clipBehavior: Clip.none, children: [
        CircleIconButton(icon: Icons.notifications_rounded, onTap: onAlerts, label: context.tr('nav_alerts'))
            .animate(onPlay: (c) => c.repeat())
            .shake(delay: 2200.ms, duration: 700.ms, hz: 4, rotation: 0.12),
        if (hasAlert)
          Positioned(
            right: 9,
            top: 9,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: AppColors.coral,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.bg, width: 2),
              ),
            ).pulse(),
          ),
      ]),
    ]);
  }
}

class _HealthCard extends StatelessWidget {
  const _HealthCard({required this.soon, required this.expired});

  final int soon;
  final int expired;

  @override
  Widget build(BuildContext context) {
    final total = store.meds.length;
    final pct = (store.health * 100).round();
    return GlassCard(
      padding: const EdgeInsets.all(20),
      radius: 28,
      child: Row(children: [
        ExpiryRing(
          progress: store.health,
          size: 124,
          stroke: 12,
          colors: const [AppColors.mint, AppColors.sky],
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            CountUp(value: pct, suffix: '%', style: display(26)),
            Text(context.tr('safe'), style: ts(12, color: AppColors.muted)),
          ]),
        ),
        const SizedBox(width: 18),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(context.tr('box_health'), style: ts(17, weight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(context.tr('safe_of_total', {'safe': total - expired, 'total': total}),
                style: ts(12.5, color: AppColors.muted, height: 1.35)),
            const SizedBox(height: 12),
            _StatLine(color: AppColors.sky, label: context.tr('medicines'), value: total),
            _StatLine(color: AppColors.amber, label: context.tr('expiring_soon'), value: soon),
            _StatLine(color: AppColors.coral, label: context.tr('expired'), value: expired),
          ]),
        ),
      ]),
    );
  }
}

class _StatLine extends StatelessWidget {
  const _StatLine({required this.color, required this.label, required this.value});

  final Color color;
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: color.withValues(alpha: 0.7), blurRadius: 6)],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: ts(13, color: AppColors.muted))),
        CountUp(value: value, style: ts(15, weight: FontWeight.w800)),
      ]),
    );
  }
}

class _UseFirstCard extends StatelessWidget {
  const _UseFirstCard({required this.med});

  final Medicine med;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: () => openDetail(context, med),
      label: context.tr('view_details'),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          gradient: LinearGradient(
            colors: [AppColors.amber.withValues(alpha: 0.24), AppColors.coral.withValues(alpha: 0.10)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: AppColors.amber.withValues(alpha: 0.40)),
        ),
        child: Row(children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: AppColors.amber.withValues(alpha: 0.20),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.timer_rounded, color: AppColors.amber, size: 28),
          ).pulse(to: 1.08, period: 900.ms),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(context.tr('use_first'),
                  style: ts(12, weight: FontWeight.w800, color: AppColors.amber, letterSpacing: 0.8)),
              const SizedBox(height: 4),
              Text(context.tr('alert_expires', {'name': med.name, 'n': med.daysLeft()}),
                  style: ts(16, weight: FontWeight.w800, height: 1.3)),
              const SizedBox(height: 4),
              Text(context.tr('alert_left', {'n': med.qty, 'unit': context.tr(med.unit)}),
                  style: ts(12.5, color: AppColors.muted, height: 1.35)),
            ]),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.muted),
        ]),
      )
          .animate(onPlay: (c) => c.repeat())
          .shimmer(delay: 1800.ms, duration: 1600.ms, color: Colors.white24),
    );
  }
}
