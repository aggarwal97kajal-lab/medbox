import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../core/strings.dart';
import '../core/theme.dart';
import '../data/medicine.dart';
import '../widgets/common.dart';
import '../widgets/med_tile.dart';
import 'scan_screen.dart';

class BoxScreen extends StatefulWidget {
  const BoxScreen({super.key});

  @override
  State<BoxScreen> createState() => _BoxScreenState();
}

class _BoxScreenState extends State<BoxScreen> {
  MedStatus? _filter; // null = all
  String _query = '';

  static const _filters = <(MedStatus?, String)>[
    (null, 'filter_all'),
    (MedStatus.soon, 'filter_soon'),
    (MedStatus.expired, 'filter_expired'),
    (MedStatus.safe, 'filter_safe'),
  ];

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final q = _query.trim().toLowerCase();
        final list = store.sorted.where((m) {
          if (_filter != null && store.statusOf(m) != _filter) return false;
          if (q.isEmpty) return true;
          return m.name.toLowerCase().contains(q) ||
              m.generic.toLowerCase().contains(q) ||
              context.tr(m.use).toLowerCase().contains(q);
        }).toList();

        return ListView(
          padding: EdgeInsets.fromLTRB(20, MediaQuery.paddingOf(context).top + 16, 20, 150),
          children: [
            Row(children: [
              Expanded(child: Text(context.tr('nav_box'), style: display(28))),
              Pressable(
                onTap: () => openScan(context),
                label: context.tr('scan_title'),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.brandGradient,
                    boxShadow: [BoxShadow(color: AppColors.mint.withValues(alpha: 0.4), blurRadius: 16)],
                  ),
                  child: const Icon(Icons.add_rounded, color: AppColors.bg, size: 26),
                ),
              ),
            ]).animate().fadeIn(duration: 450.ms).slideY(begin: -0.3),
            const SizedBox(height: 16),
            GlassCard(
              radius: 18,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: TextField(
                onChanged: (v) => setState(() => _query = v),
                style: ts(15),
                cursorColor: AppColors.mint,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  icon: const Icon(Icons.search_rounded, color: AppColors.muted),
                  hintText: context.tr('search_hint'),
                  hintStyle: ts(15, color: AppColors.muted),
                ),
              ),
            ).animate(delay: 80.ms).fadeIn(duration: 450.ms),
            const SizedBox(height: 14),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              child: Row(children: [
                for (final (status, key) in _filters)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _Chip(
                      label: context.tr(key),
                      selected: _filter == status,
                      onTap: () => setState(() => _filter = status),
                    ),
                  ),
              ]),
            ).animate(delay: 150.ms).fadeIn(duration: 450.ms).slideX(begin: 0.1),
            const SizedBox(height: 14),
            Text(context.tr('count_meds', {'n': list.length}), style: ts(13, color: AppColors.muted)),
            const SizedBox(height: 10),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Column(
                key: ValueKey('$_filter|$q|${list.length}'),
                children: [
                  for (var i = 0; i < list.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: MedTile(med: list[i])
                          .animate(delay: (60 * i).ms)
                          .fadeIn(duration: 400.ms)
                          .slideX(begin: 0.15, curve: Curves.easeOutCubic),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      label: label,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          gradient: selected ? AppColors.brandGradient : null,
          color: selected ? null : Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: selected ? Colors.transparent : Colors.white.withValues(alpha: 0.12)),
          boxShadow: selected
              ? [BoxShadow(color: AppColors.mint.withValues(alpha: 0.35), blurRadius: 16)]
              : const [],
        ),
        child: Text(label,
            style: ts(13.5,
                weight: selected ? FontWeight.w800 : FontWeight.w600,
                color: selected ? AppColors.bg : AppColors.text)),
      ),
    );
  }
}
