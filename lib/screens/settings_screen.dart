import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../core/strings.dart';
import '../core/theme.dart';
import '../data/medicine.dart';
import '../widgets/common.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        return ListView(
          padding: EdgeInsets.fromLTRB(20, MediaQuery.paddingOf(context).top + 16, 20, 150),
          children: [
            Text(context.tr('settings_title'), style: display(28))
                .animate()
                .fadeIn(duration: 450.ms)
                .slideY(begin: -0.3),
            const SizedBox(height: 22),
            Text(context.tr('language'), style: ts(14, weight: FontWeight.w700, color: AppColors.muted)),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: _LangCard(code: 'en', glyph: 'Aa', name: 'English')),
              const SizedBox(width: 12),
              Expanded(child: _LangCard(code: 'hi', glyph: 'अ', name: 'हिन्दी')),
            ]).animate(delay: 100.ms).fadeIn(duration: 450.ms).slideY(begin: 0.2),
            const SizedBox(height: 26),
            Text(context.tr('reminders'), style: ts(14, weight: FontWeight.w700, color: AppColors.muted)),
            const SizedBox(height: 10),
            GlassCard(
              padding: const EdgeInsets.all(18),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(context.tr('remind_before', {'n': store.reminderDays}),
                    style: ts(15, weight: FontWeight.w700)),
                const SizedBox(height: 14),
                Row(children: [
                  for (final d in const [7, 15, 30, 60])
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Pressable(
                          onTap: () => store.setReminderDays(d),
                          label: '$d',
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 320),
                            curve: Curves.easeOutBack,
                            height: 48,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              gradient: store.reminderDays == d ? AppColors.brandGradient : null,
                              color: store.reminderDays == d ? null : Colors.white.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(context.tr('days', {'n': d}),
                                style: ts(13.5,
                                    weight: FontWeight.w800,
                                    color: store.reminderDays == d ? AppColors.bg : AppColors.text)),
                          ),
                        ),
                      ),
                    ),
                ]),
              ]),
            ).animate(delay: 200.ms).fadeIn(duration: 450.ms).slideY(begin: 0.2),
            const SizedBox(height: 12),
            GlassCard(
              padding: const EdgeInsets.fromLTRB(18, 12, 12, 12),
              child: Row(children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.violet.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.notifications_active_rounded, color: AppColors.violet),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(context.tr('notifications'), style: ts(15, weight: FontWeight.w700)),
                    Text(context.tr('notifications_sub'), style: ts(12.5, color: AppColors.muted)),
                  ]),
                ),
                Switch(
                  value: store.notifications,
                  onChanged: store.setNotifications,
                  activeTrackColor: AppColors.mint,
                ),
              ]),
            ).animate(delay: 280.ms).fadeIn(duration: 450.ms).slideY(begin: 0.2),
            const SizedBox(height: 30),
            Center(
              child: Column(children: [
                const AppLogo(size: 54),
                const SizedBox(height: 10),
                Text(context.tr('about'), style: ts(12.5, color: AppColors.muted)),
              ]),
            ).animate(delay: 380.ms).fadeIn(),
          ],
        );
      },
    );
  }
}

class _LangCard extends StatelessWidget {
  const _LangCard({required this.code, required this.glyph, required this.name});

  final String code;
  final String glyph;
  final String name;

  @override
  Widget build(BuildContext context) {
    final sel = Localizations.localeOf(context).languageCode == code;
    return Pressable(
      onTap: () => appLocale.value = Locale(code),
      label: name,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeOutCubic,
        height: 120,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: sel ? AppColors.mint.withValues(alpha: 0.14) : Colors.white.withValues(alpha: 0.05),
          border: Border.all(
            color: sel ? AppColors.mint : Colors.white.withValues(alpha: 0.10),
            width: sel ? 2 : 1,
          ),
          boxShadow: sel ? [BoxShadow(color: AppColors.mint.withValues(alpha: 0.25), blurRadius: 24)] : const [],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(glyph, style: display(30, color: sel ? AppColors.mint : AppColors.text)),
            const Spacer(),
            AnimatedScale(
              scale: sel ? 1 : 0,
              duration: const Duration(milliseconds: 400),
              curve: Curves.elasticOut,
              child: const Icon(Icons.check_circle_rounded, color: AppColors.mint),
            ),
          ]),
          const Spacer(),
          Text(name, style: ts(16, weight: FontWeight.w800)),
        ]),
      ),
    );
  }
}
