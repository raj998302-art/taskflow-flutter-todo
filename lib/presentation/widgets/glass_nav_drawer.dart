import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/extensions.dart';
import '../../core/widgets/glass_container.dart';
import '../providers/stats_provider.dart';
import '../providers/task_providers.dart';

/// A floating, glassmorphic navigation drawer that slides in from the left.
///
/// Unlike a standard Material [Drawer], this widget is rendered as an overlay
/// (via [showDialog] semantics) with a translucent scrim and a frosted-glass
/// panel that floats over the content — giving the app a premium, modern feel.
///
/// Usage: call [showGlassDrawer] from any button (e.g. the header's menu icon).
class GlassNavDrawer extends ConsumerWidget {
  const GlassNavDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(statsProvider);
    final tasksAsync = ref.watch(taskListProvider);
    final tasks = tasksAsync.valueOrNull ?? [];

    return Stack(
      children: [
        // ---- Scrim (tap to close) ----
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            color: Colors.black.withValues(alpha: 0.45),
          ),
        )
            .animate()
            .fadeIn(duration: 250.ms),

        // ---- Floating glass panel ----
        Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.only(
              top: 16,
              bottom: 16,
              left: 16,
            ),
            child: GlassContainer(
              padding: EdgeInsets.zero,
              borderRadius: BorderRadius.circular(28),
              blur: 24,
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.glassDark
                  : AppColors.glassLight,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: context.isTablet ? 360 : 300,
                  maxHeight: MediaQuery.of(context).size.height - 32,
                ),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _DrawerHeader(stats: stats, taskCount: tasks.length),
                      const SizedBox(height: 8),
                      _NavItem(
                        icon: Icons.task_alt_rounded,
                        label: 'Tasks',
                        subtitle: '${stats.active} active · ${stats.completed} done',
                        onTap: () {
                          Navigator.of(context).pop();
                          context.go('/home');
                        },
                      ),
                      _NavItem(
                        icon: Icons.alarm_rounded,
                        label: 'Reminders',
                        subtitle: stats.overdue > 0
                            ? '${stats.overdue} overdue'
                            : 'Voice alarms',
                        onTap: () {
                          Navigator.of(context).pop();
                          context.go('/home');
                        },
                      ),
                      _NavItem(
                        icon: Icons.insights_rounded,
                        label: 'Statistics',
                        subtitle: '${(stats.completionRate * 100).round()}% complete',
                        onTap: () {
                          Navigator.of(context).pop();
                          context.push('/statistics');
                        },
                      ),
                      _NavItem(
                        icon: Icons.timer_rounded,
                        label: 'Focus Timer',
                        subtitle: 'Pomodoro',
                        onTap: () {
                          Navigator.of(context).pop();
                          context.go('/home');
                        },
                      ),
                      const _DrawerDivider(),
                      _NavItem(
                        icon: Icons.settings_rounded,
                        label: 'Settings',
                        subtitle: 'Theme, lock, data',
                        onTap: () {
                          Navigator.of(context).pop();
                          context.push('/settings');
                        },
                      ),
                      _NavItem(
                        icon: Icons.info_outline_rounded,
                        label: 'About',
                        subtitle: 'Taskflow v1.0.0',
                        onTap: () {
                          Navigator.of(context).pop();
                          _showAboutDialog(context);
                        },
                      ),
                      const SizedBox(height: 12),
                      _QuoteCard(),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ),
        )
            .animate()
            .slideX(
              begin: -1.0,
              end: 0.0,
              duration: 350.ms,
              curve: Curves.easeOutCubic,
            )
            .fadeIn(duration: 350.ms),
      ],
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.check_circle_rounded, color: AppColors.primary),
            const SizedBox(width: 8),
            const Text('Taskflow'),
          ],
        ),
        content: const Text(
          'Premium Todo & Reminder app\n\n'
          'Features:\n'
          '• Tasks, categories, priorities\n'
          '• Voice reminders with TTS\n'
          '• Biometric app lock\n'
          '• Statistics dashboard\n'
          '• Pomodoro focus timer\n'
          '• Fully offline (Hive)\n\n'
          'Built with Flutter, Material 3, Riverpod',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

/// Shows the floating glass navigation drawer as a full-screen overlay.
void showGlassDrawer(BuildContext context) {
  showDialog<void>(
    context: context,
    barrierColor: Colors.transparent,
    builder: (_) => const GlassNavDrawer(),
  );
}

// ---------------------------------------------------------------------------

class _DrawerHeader extends StatelessWidget {
  const _DrawerHeader({required this.stats, required this.taskCount});
  final dynamic stats; // TaskStats
  final int taskCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.primary.withValues(alpha: 0.7),
          ],
        ),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.task_alt_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppConstants.appName,
                      style: context.textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'Your day, organised',
                      style: context.textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _MiniStat(
                label: 'Active',
                value: '${stats.active}',
                icon: Icons.flash_on_rounded,
              ),
              const SizedBox(width: 12),
              _MiniStat(
                label: 'Done',
                value: '${stats.completed}',
                icon: Icons.check_circle_rounded,
              ),
              const SizedBox(width: 12),
              _MiniStat(
                label: 'Today',
                value: '${stats.dueToday}',
                icon: Icons.today_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
    required this.icon,
  });
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 16, color: Colors.white.withValues(alpha: 0.9)),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 20, color: AppColors.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: context.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: context.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: scheme.onSurfaceVariant,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: 100.ms).slideX(begin: 0.1, end: 0);
  }
}

class _DrawerDivider extends StatelessWidget {
  const _DrawerDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Divider(
        color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3),
      ),
    );
  }
}

class _QuoteCard extends StatelessWidget {
  // Rotating motivational quotes.
  static const _quotes = <String>[
    '“The secret of getting ahead is getting started.” — Mark Twain',
    '“Focus on being productive, not busy.” — Tim Ferriss',
    '“You don’t have to be great to start, but you have to start to be great.” — Zig Ziglar',
    '“Small progress is still progress.”',
    '“Done is better than perfect.”',
  ];

  @override
  Widget build(BuildContext context) {
    final quote = _quotes[DateTime.now().day % _quotes.length];
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.accent.withValues(alpha: 0.15),
            AppColors.secondary.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.format_quote_rounded,
            color: AppColors.accent,
            size: 24,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              quote,
              style: context.textTheme.bodySmall?.copyWith(
                fontStyle: FontStyle.italic,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .shimmer(duration: 3000.ms);
  }
}
