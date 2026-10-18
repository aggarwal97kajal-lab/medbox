import 'package:flutter/material.dart';

import '../core/strings.dart';
import '../core/theme.dart';
import '../data/medicine.dart';
import '../screens/detail_screen.dart';
import 'common.dart';

String statusLabel(BuildContext context, Medicine m) {
  final st = store.statusOf(m);
  return switch (st) {
    MedStatus.expired => context.tr('expired'),
    MedStatus.safe => context.tr('safe'),
    MedStatus.soon => context.tr('days', {'n': m.daysLeft()}),
  };
}

void openDetail(BuildContext context, Medicine m) {
  Navigator.of(context).push(PageRouteBuilder(
    transitionDuration: const Duration(milliseconds: 650),
    reverseTransitionDuration: const Duration(milliseconds: 450),
    pageBuilder: (_, __, ___) => DetailScreen(med: m),
    transitionsBuilder: (_, a, __, child) {
      final curved = CurvedAnimation(parent: a, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween(begin: 0.94, end: 1.0).animate(curved),
          child: child,
        ),
      );
    },
  ));
}

class MedTile extends StatelessWidget {
  const MedTile({super.key, required this.med});

  final Medicine med;

  @override
  Widget build(BuildContext context) {
    final st = store.statusOf(med);
    final c = statusColor(st);
    return Pressable(
      onTap: () => openDetail(context, med),
      label: med.name,
      child: GlassCard(
        padding: const EdgeInsets.all(14),
        radius: 22,
        child: Row(children: [
          Hero(tag: 'med-${med.id}', child: MedIcon(med: med, size: 50, color: c)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(med.name, style: ts(16, weight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(med.meta(context),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ts(13, color: AppColors.muted)),
              const SizedBox(height: 10),
              LifeBar(value: med.lifeUsed(), color: c),
            ]),
          ),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            StatusPill(text: statusLabel(context, med), color: c),
            const SizedBox(height: 8),
            Text(context.fmtDate(med.expiry, withDay: st != MedStatus.safe),
                style: ts(12, color: AppColors.muted)),
          ]),
        ]),
      ),
    );
  }
}
