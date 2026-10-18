import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/strings.dart';
import '../core/theme.dart';
import '../data/medicine.dart';
import '../widgets/common.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  final _disposeKey = GlobalKey();

  void _scrollToDispose() {
    final ctx = _disposeKey.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 700), curve: Curves.easeInOutCubic);
    }
  }

  Future<void> _findDropOff() async {
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=medicine+disposal+near+me');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final expired = store.byStatus(MedStatus.expired);
        final upcoming = <Widget>[
          for (final m in store.byStatus(MedStatus.soon))
            _TimelineRow(
              color: AppColors.amber,
              title: m.name,
              subtitle: context.tr('expires_short'),
              trailing: context.fmtDate(m.expiry),
            ),
          for (final m in store.lowStock)
            _TimelineRow(
              color: AppColors.sky,
              title: m.name,
              subtitle: context.tr('running_low'),
              trailing: context.tr('left_short', {'n': m.qty}),
            ),
        ];

        return ListView(
          padding: EdgeInsets.fromLTRB(20, MediaQuery.paddingOf(context).top + 16, 20, 150),
          children: [
            Text(context.tr('alerts_title'), style: display(28))
                .animate()
                .fadeIn(duration: 450.ms)
                .slideY(begin: -0.3),
            const SizedBox(height: 18),
            if (expired.isEmpty)
              GlassCard(
                child: Row(children: [
                  const Icon(Icons.verified_rounded, color: AppColors.mint),
                  const SizedBox(width: 12),
                  Expanded(child: Text(context.tr('all_clear'), style: ts(14))),
                ]),
              ).animate().fadeIn(),
            for (var i = 0; i < expired.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _ExpiredCard(med: expired[i], onHow: _scrollToDispose)
                    .animate(delay: (120 + i * 100).ms)
                    .fadeIn(duration: 450.ms)
                    .slideY(begin: 0.25)
                    .then()
                    .shakeX(hz: 5, amount: 5, duration: 500.ms),
              ),
            const SizedBox(height: 14),
            SectionTitle(title: context.tr('coming_up')).animate(delay: 250.ms).fadeIn(),
            const SizedBox(height: 6),
            GlassCard(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Column(
                children: [
                  for (var i = 0; i < upcoming.length; i++)
                    _WithLine(isLast: i == upcoming.length - 1, child: upcoming[i]),
                ].animate(interval: 90.ms, delay: 320.ms).fadeIn(duration: 400.ms).slideX(begin: 0.12),
              ),
            ),
            const SizedBox(height: 26),
            SectionTitle(key: _disposeKey, title: context.tr('dispose_title'))
                .animate(delay: 450.ms)
                .fadeIn(),
            const SizedBox(height: 6),
            for (var k = 1; k <= 3; k++)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _StepCard(n: k, text: context.tr('dispose_$k'))
                    .animate(delay: (500 + k * 120).ms)
                    .fadeIn(duration: 400.ms)
                    .slideY(begin: 0.3, curve: Curves.easeOutCubic),
              ),
            const SizedBox(height: 4),
            SecondaryButton(
              label: context.tr('find_dropoff'),
              icon: Icons.location_on_rounded,
              color: AppColors.mint,
              onTap: _findDropOff,
            ).animate(delay: 900.ms).fadeIn(),
          ],
        );
      },
    );
  }
}

class _ExpiredCard extends StatelessWidget {
  const _ExpiredCard({required this.med, required this.onHow});

  final Medicine med;
  final VoidCallback onHow;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: LinearGradient(
          colors: [AppColors.coral.withValues(alpha: 0.26), AppColors.coral.withValues(alpha: 0.08)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: AppColors.coral.withValues(alpha: 0.45)),
      ),
      child: Column(children: [
        Row(children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.coral.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: AppColors.coral.withValues(alpha: 0.4), blurRadius: 18)],
            ),
            child: const Icon(Icons.warning_amber_rounded, color: AppColors.coral, size: 26),
          ).pulse(to: 1.1),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(context.tr('expired_title', {'name': med.name}), style: ts(16, weight: FontWeight.w800)),
              const SizedBox(height: 3),
              Text(context.tr('expired_sub', {'n': -med.daysLeft()}),
                  style: ts(13, color: const Color(0xFFFFB3BE))),
            ]),
          ),
        ]),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(
            child: PrimaryButton(label: context.tr('how_dispose'), color: AppColors.coral, onTap: onHow),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: SecondaryButton(
              label: context.tr('mark_disposed'),
              onTap: () {
                final msg = context.tr('disposed_msg', {'name': med.name});
                store.remove(med.id);
                showToast(context, msg);
              },
            ),
          ),
        ]),
      ]),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.color, required this.title, required this.subtitle, required this.trailing});

  final Color color;
  final String title;
  final String subtitle;
  final String trailing;

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: ts(15, weight: FontWeight.w700)),
          Text(subtitle, style: ts(12.5, color: color)),
        ]),
      ),
      Text(trailing, style: ts(13, color: AppColors.muted)),
    ]);
  }
}

class _WithLine extends StatelessWidget {
  const _WithLine({required this.isLast, required this.child});

  final bool isLast;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final row = child is _TimelineRow ? child as _TimelineRow : null;
    final color = row?.color ?? AppColors.mint;
    return IntrinsicHeight(
      child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        SizedBox(
          width: 22,
          child: Column(children: [
            const SizedBox(height: 16),
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: color.withValues(alpha: 0.7), blurRadius: 8)],
              ),
            ),
            if (!isLast)
              Expanded(
                child: Container(width: 2, margin: const EdgeInsets.only(top: 4), color: Colors.white.withValues(alpha: 0.10)),
              ),
          ]),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: child),
        ),
      ]),
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({required this.n, required this.text});

  final int n;
  final String text;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      radius: 20,
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: const BoxDecoration(gradient: AppColors.brandGradient, shape: BoxShape.circle),
          child: Text('$n', style: ts(14, weight: FontWeight.w800, color: AppColors.bg)),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: ts(14, height: 1.45))),
      ]),
    );
  }
}
