import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/extensions.dart';
import '../../core/widgets/glass_container.dart';
import '../providers/stats_provider.dart';

/// A premium "hero" glass card shown at the top of the home page.
///
/// Combines the completion ring, today's count, and an overdue alert into one
/// frosted-glass panel with a gradient accent — replacing the old plain stat
/// pill with something more dashboard-like.
class GlassHeroStats extends ConsumerWidget {
  const GlassHeroStats({super.key, this.onTap});
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(statsProvider);
    final pct = (stats.completionRate * 100).round();
    final hasOverdue = stats.overdue > 0;

    return GestureDetector(
      onTap: onTap,
      child: GlassContainer(
        padding: const EdgeInsets.all(18),
        borderRadius: BorderRadius.circular(24),
        blur: 22,
        shadows: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
        child: Column(
          children: [
            // Top row: progress ring + headline
            Row(
              children: [
                _ProgressRing(
                  progress: stats.completionRate,
                  pct: pct,
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Today\'s progress',
                        style: context.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        stats.completionRate >= 0.8
                            ? 'Almost there! 🎉'
                            : stats.completionRate >= 0.5
                                ? 'Great pace — keep going! 💪'
                                : 'A good start. One task at a time. 🌱',
                        style: context.textTheme.bodySmall?.copyWith(
                          color: context.colors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _Chip(
                            icon: Icons.flash_on_rounded,
                            label: '${stats.active} active',
                            color: AppColors.primary,
                          ),
                          _Chip(
                            icon: Icons.check_circle_rounded,
                            label: '${stats.completed} done',
                            color: AppColors.success,
                          ),
                          if (stats.dueToday > 0)
                            _Chip(
                              icon: Icons.today_rounded,
                              label: '${stats.dueToday} today',
                              color: AppColors.accent,
                            ),
                          if (hasOverdue)
                            _Chip(
                              icon: Icons.warning_amber_rounded,
                              label: '${stats.overdue} overdue',
                              color: AppColors.error,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.05, end: 0)
        .shimmer(duration: 2000.ms, color: Colors.white.withValues(alpha: 0.1));
  }
}

/// Circular progress indicator showing overall completion %.
class _ProgressRing extends StatelessWidget {
  const _ProgressRing({required this.progress, required this.pct});
  final double progress;
  final int pct;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 76,
      height: 76,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 76,
            height: 76,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 7,
              backgroundColor:
                  AppColors.primary.withValues(alpha: 0.12),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.primary),
              strokeCap: StrokeCap.round,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$pct%',
                style: context.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                ),
              ),
              Text(
                'done',
                style: context.textTheme.labelSmall?.copyWith(
                  fontSize: 9,
                  color: context.colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.icon,
    required this.label,
    required this.color,
  });
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: context.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
