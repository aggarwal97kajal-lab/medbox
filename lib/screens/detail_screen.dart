import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../core/strings.dart';
import '../core/theme.dart';
import '../data/medicine.dart';
import '../widgets/aurora_background.dart';
import '../widgets/common.dart';
import 'compare_screen.dart';

class DetailScreen extends StatelessWidget {
  const DetailScreen({super.key, required this.med});

  final Medicine med;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final st = store.statusOf(med);
        final c = statusColor(st);
        final days = med.daysLeft();
        final dup = store.sameGeneric(med);
        final top = MediaQuery.paddingOf(context).top;

        return Scaffold(
          backgroundColor: AppColors.bg,
          body: AuroraBackground(
            colors: [c, AppColors.violet, c],
            intensity: 0.26,
            child: Stack(children: [
              ListView(
                padding: EdgeInsets.fromLTRB(20, top + 12, 20, 130),
                children: [
                  Row(children: [
                    CircleIconButton(
                      icon: Icons.arrow_back_ios_new_rounded,
                      onTap: () => Navigator.of(context).pop(),
                      label: 'Back',
                    ),
                    const Spacer(),
                    const LangToggle(),
                  ]),
                  const SizedBox(height: 18),
                  Center(child: Hero(tag: 'med-${med.id}', child: MedIcon(med: med, size: 84, color: c))),
                  const SizedBox(height: 14),
                  Center(child: Text(med.name, style: display(30)))
                      .animate(delay: 200.ms)
                      .fadeIn(duration: 450.ms)
                      .slideY(begin: 0.4, curve: Curves.easeOutCubic),
                  const SizedBox(height: 4),
                  Center(
                    child: Text('${med.generic} · ${context.tr(med.form)}',
                        style: ts(14, color: AppColors.muted)),
                  ).animate(delay: 260.ms).fadeIn(duration: 450.ms),
                  const SizedBox(height: 22),
                  Center(
                    child: ExpiryRing(
                      progress: switch (st) {
                        MedStatus.expired => 1.0,
                        // urgency: share of the reminder window still left
                        MedStatus.soon => (days / store.reminderDays).clamp(0.05, 1.0),
                        MedStatus.safe => 1 - med.lifeUsed(),
                      },
                      size: 196,
                      stroke: 16,
                      colors: [c, Color.lerp(c, Colors.white, 0.45)!],
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        CountUp(value: days.abs(), style: display(52, color: c)),
                        Text(context.tr(days < 0 ? 'days_ago' : 'days_left'),
                            style: ts(14, color: AppColors.muted)),
                      ]),
                    ),
                  )
                      .animate(delay: 150.ms)
                      .fadeIn(duration: 500.ms)
                      .scale(begin: const Offset(0.8, 0.8), curve: Curves.easeOutBack, duration: 800.ms),
                  const SizedBox(height: 12),
                  Center(
                    child: Text('${context.tr('expires_on')}: ${context.fmtDate(med.expiry)}',
                        style: ts(15, weight: FontWeight.w700)),
                  ).animate(delay: 350.ms).fadeIn(),
                  const SizedBox(height: 22),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1.65,
                    children: [
                      _Info(Icons.inventory_2_rounded, context.tr('left_in_box'),
                          '${med.qty} ${context.tr(med.unit)}'),
                      _Info(Icons.healing_rounded, context.tr('used_for'), context.tr(med.use)),
                      _Info(Icons.person_rounded, context.tr('belongs_to'), context.tr(med.owner)),
                      _Info(Icons.place_rounded, context.tr('kept_in'), context.tr(med.place)),
                    ]
                        .animate(interval: 80.ms, delay: 400.ms)
                        .fadeIn(duration: 400.ms)
                        .slideY(begin: 0.25, curve: Curves.easeOutCubic),
                  ),
                  if (dup != null && st != MedStatus.safe) ...[
                    const SizedBox(height: 12),
                    GlassCard(
                      tint: AppColors.mint,
                      borderColor: AppColors.mint.withValues(alpha: 0.3),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Icon(Icons.lightbulb_rounded, color: AppColors.mint),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            context.tr('tip_duplicate', {
                              'name': dup.name,
                              'date': context.fmtDate(dup.expiry, withDay: false),
                            }),
                            style: ts(14, height: 1.45),
                          ),
                        ),
                      ]),
                    ).animate(delay: 750.ms).fadeIn(duration: 450.ms).slideY(begin: 0.3),
                  ],
                ],
              ),
              Positioned(left: 0, right: 0, bottom: 0, child: _Actions(med: med, status: st)),
            ]),
          ),
        );
      },
    );
  }
}

class _Info extends StatelessWidget {
  const _Info(this.icon, this.label, this.value);

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      radius: 20,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 20, color: AppColors.mint),
        const Spacer(),
        Text(label, style: ts(12, color: AppColors.muted)),
        const SizedBox(height: 2),
        Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: ts(15, weight: FontWeight.w800)),
      ]),
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({required this.med, required this.status});

  final Medicine med;
  final MedStatus status;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return ClipRect(
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: EdgeInsets.fromLTRB(20, 14, 20, bottom + 16),
          decoration: BoxDecoration(
            color: AppColors.sheet.withValues(alpha: 0.88),
            border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
          ),
          child: status == MedStatus.expired
              ? PrimaryButton(
                  label: context.tr('mark_disposed'),
                  icon: Icons.delete_outline_rounded,
                  color: AppColors.coral,
                  onTap: () {
                    final messenger = ScaffoldMessenger.of(context);
                    final msg = context.tr('disposed_msg', {'name': med.name});
                    store.remove(med.id);
                    Navigator.of(context).pop();
                    messenger.showSnackBar(SnackBar(content: Text(msg)));
                  },
                )
              : Row(children: [
                  Expanded(
                    child: SecondaryButton(
                      label: context.tr('mark_used'),
                      icon: Icons.remove_circle_outline_rounded,
                      onTap: () {
                        store.useOne(med);
                        showToast(context, context.tr('used_msg', {'n': med.qty}));
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: PrimaryButton(
                      label: context.tr('compare_prices'),
                      icon: Icons.price_check_rounded,
                      onTap: () => openCompare(context, med),
                    ),
                  ),
                ]),
        ),
      ),
    ).animate(delay: 300.ms).slideY(begin: 1, duration: 500.ms, curve: Curves.easeOutCubic);
  }
}
