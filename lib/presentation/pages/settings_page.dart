import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/notification_service.dart';
import '../../core/utils/extensions.dart';
import '../../core/widgets/glass_container.dart';
import '../../domain/entities/lock_type.dart';
import '../providers/app_settings_provider.dart';
import '../providers/lock_provider.dart';
import '../providers/reminder_providers.dart';
import '../providers/task_providers.dart';
import '../providers/theme_provider.dart';

/// Premium Settings page organised into four glass-card sections:
/// Appearance, Security, Data, and About.
///
/// The page is fully reactive — it watches [appSettingsProvider] and
/// [themeModeProvider] and writes back through their notifiers, so no local
/// state is required for the page itself. The single exception is the
/// app-lock toggle, which performs an async biometric check before enabling;
/// that tile is wrapped in a small [ConsumerStatefulWidget] so it can show a
/// spinner during the auth flow.
///
/// Each section fades + slides in with a staggered delay for a polished
/// entrance.
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              pinned: true,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                tooltip: 'Back',
                onPressed: () => context.go('/home'),
              ),
              title: const Text('Settings'),
              backgroundColor: context.theme.scaffoldBackgroundColor,
              surfaceTintColor: Colors.transparent,
              scrolledUnderElevation: 0,
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _SectionCard(
                    index: 0,
                    icon: Icons.palette_rounded,
                    title: 'Appearance',
                    child: _AppearanceSection(
                      themeMode: themeMode,
                      accentIndex: settings.accentColorIndex,
                      onThemeChanged: (mode) =>
                          ref.read(themeModeProvider.notifier).set(mode),
                      onAccentChanged: (i) => ref
                          .read(appSettingsProvider.notifier)
                          .setAccentColor(i),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SectionCard(
                    index: 1,
                    icon: Icons.lock_outline_rounded,
                    title: 'Security',
                    child: _SecuritySection(
                      onSetupLock: () => context.push('/lock-setup'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SectionCard(
                    index: 2,
                    icon: Icons.storage_rounded,
                    title: 'Data',
                    child: _DataSection(
                      onReplayOnboarding: () {
                        ref.read(appSettingsProvider.notifier).resetOnboarding();
                        context.go('/onboarding');
                      },
                      onClearTasks: () => _confirmClearTasks(context, ref),
                      onClearReminders: () =>
                          _confirmClearReminders(context, ref),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const _SectionCard(
                    index: 3,
                    icon: Icons.info_outline_rounded,
                    title: 'About',
                    child: _AboutSection(),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---- Confirmation dialogs ------------------------------------------------

  Future<void> _confirmClearTasks(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.delete_sweep_rounded, color: AppColors.error),
        title: const Text('Clear all tasks?'),
        content: const Text(
          'This will permanently delete every task on this device. '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(taskListProvider.notifier).clearAllTasks();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All tasks cleared')),
    );
  }

  Future<void> _confirmClearReminders(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.notifications_off_rounded, color: AppColors.error),
        title: const Text('Clear all reminders?'),
        content: const Text(
          'This will cancel every scheduled reminder and delete them from '
          'this device. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await NotificationService.instance.cancelAll();
    await ref.read(reminderListProvider.notifier).clearAll();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All reminders cleared')),
    );
  }
}

/// A frosted-glass section card with a header row (icon + uppercase title)
/// and the body content below. Staggered entrance animation.
class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.index,
    required this.icon,
    required this.title,
    required this.child,
  });

  final int index;
  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: context.colors.primary),
              const SizedBox(width: 8),
              Text(
                title.toUpperCase(),
                style: context.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: context.colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          child,
        ],
      ),
    )
        .animate()
        .fadeIn(delay: (index * 80).ms, duration: 300.ms)
        .slideY(begin: 0.05, end: 0, duration: 300.ms);
  }
}

// ===========================================================================
// Appearance
// ===========================================================================

class _AppearanceSection extends StatelessWidget {
  const _AppearanceSection({
    required this.themeMode,
    required this.accentIndex,
    required this.onThemeChanged,
    required this.onAccentChanged,
  });

  final ThemeMode themeMode;
  final int accentIndex;
  final ValueChanged<ThemeMode> onThemeChanged;
  final ValueChanged<int> onAccentChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          leading: Icon(
            Icons.brightness_6_rounded,
            size: 20,
            color: context.colors.onSurfaceVariant,
          ),
          title: Text(
            'Theme',
            style: context.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 4, right: 4, bottom: 8),
          child: SegmentedButton<ThemeMode>(
            showSelectedIcon: false,
            style: const ButtonStyle(
              visualDensity: VisualDensity(horizontal: 0, vertical: -2),
            ),
            segments: const [
              ButtonSegment<ThemeMode>(
                value: ThemeMode.system,
                icon: Icon(Icons.brightness_auto_rounded, size: 18),
                label: Text('System'),
              ),
              ButtonSegment<ThemeMode>(
                value: ThemeMode.light,
                icon: Icon(Icons.light_mode_rounded, size: 18),
                label: Text('Light'),
              ),
              ButtonSegment<ThemeMode>(
                value: ThemeMode.dark,
                icon: Icon(Icons.dark_mode_rounded, size: 18),
                label: Text('Dark'),
              ),
            ],
            selected: <ThemeMode>{themeMode},
            onSelectionChanged: (selected) => onThemeChanged(selected.first),
          ),
        ),
        ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          leading: Icon(
            Icons.color_lens_rounded,
            size: 20,
            color: context.colors.onSurfaceVariant,
          ),
          title: Text(
            'Accent color',
            style: context.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            AccentPresets.labels[accentIndex],
            style: context.textTheme.bodySmall,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 8, 12),
          child: Wrap(
            spacing: 14,
            runSpacing: 14,
            children: [
              for (int i = 0; i < AccentPresets.colors.length; i++)
                _AccentSwatch(
                  color: AccentPresets.colors[i],
                  label: AccentPresets.labels[i],
                  selected: accentIndex == i,
                  onTap: () => onAccentChanged(i),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A single circular accent color swatch with a check icon when selected.
class _AccentSwatch extends StatelessWidget {
  const _AccentSwatch({
    required this.color,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: 200.ms,
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            border: Border.all(
              color: selected
                  ? context.colors.onSurface
                  : color.withValues(alpha: 0.0),
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: selected ? 0.45 : 0.25),
                blurRadius: selected ? 12 : 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: selected
              ? const Icon(Icons.check_rounded, color: Colors.white, size: 22)
              : null,
        ),
      ),
    );
  }
}

// ===========================================================================
// Security
// ===========================================================================

class _SecuritySection extends ConsumerWidget {
  const _SecuritySection({required this.onSetupLock});
  final VoidCallback onSetupLock;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(lockRepositoryProvider);
    final lockType = repo.isLockEnabled ? repo.lockType : LockType.none;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Current lock status card
        InkWell(
          onTap: onSetupLock,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: (lockType == LockType.none
                      ? AppColors.error
                      : AppColors.success)
                  .withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: (lockType == LockType.none
                        ? AppColors.error
                        : AppColors.success)
                    .withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: (lockType == LockType.none
                            ? AppColors.error
                            : AppColors.success)
                        .withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    lockType == LockType.none
                        ? Icons.lock_open_rounded
                        : Icons.lock_rounded,
                    size: 22,
                    color: lockType == LockType.none
                        ? AppColors.error
                        : AppColors.success,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lockType == LockType.none
                            ? 'App lock is off'
                            : '${lockType.label} lock is on',
                        style: context.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        lockType == LockType.none
                            ? 'Tap to set up a lock'
                            : lockType.description,
                        style: context.textTheme.bodySmall?.copyWith(
                          color: context.colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded,
                    color: context.colors.onSurfaceVariant),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Quick link
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(
            Icons.manage_accounts_rounded,
            size: 22,
            color: context.colors.primary,
          ),
          title: Text(
            'Configure lock',
            style: context.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            'Choose biometric, pattern, or PIN',
            style: context.textTheme.bodySmall,
          ),
          trailing: Icon(Icons.chevron_right_rounded,
              color: context.colors.onSurfaceVariant),
          onTap: onSetupLock,
        ),
      ],
    );
  }
}

// ===========================================================================
// Data
// ===========================================================================

class _DataSection extends StatelessWidget {
  const _DataSection({
    required this.onReplayOnboarding,
    required this.onClearTasks,
    required this.onClearReminders,
  });

  final VoidCallback onReplayOnboarding;
  final VoidCallback onClearTasks;
  final VoidCallback onClearReminders;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(
            Icons.replay_rounded,
            color: context.colors.primary,
          ),
          title: const Text('Replay onboarding'),
          subtitle: Text(
            'Walk through the intro screens again',
            style: context.textTheme.bodySmall,
          ),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: onReplayOnboarding,
        ),
        Divider(
          height: 1,
          color: context.colors.outlineVariant.withValues(alpha: 0.5),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(
            Icons.delete_sweep_rounded,
            color: AppColors.error,
          ),
          title: const Text(
            'Clear all tasks',
            style: TextStyle(color: AppColors.error),
          ),
          subtitle: Text(
            'Permanently delete every task',
            style: context.textTheme.bodySmall,
          ),
          onTap: onClearTasks,
        ),
        Divider(
          height: 1,
          color: context.colors.outlineVariant.withValues(alpha: 0.5),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(
            Icons.notifications_off_rounded,
            color: AppColors.error,
          ),
          title: const Text(
            'Clear all reminders',
            style: TextStyle(color: AppColors.error),
          ),
          subtitle: Text(
            'Cancel scheduled reminders and delete them',
            style: context.textTheme.bodySmall,
          ),
          onTap: onClearReminders,
        ),
      ],
    );
  }
}

// ===========================================================================
// About
// ===========================================================================

class _AboutSection extends StatelessWidget {
  const _AboutSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: <Color>[AppColors.primary, AppColors.primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(
                Icons.task_alt_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Taskflow v1.0.0',
                    style: context.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'Made with Flutter ❤️',
                    style: context.textTheme.bodySmall?.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            _FeatureBadge(label: 'Material 3'),
            _FeatureBadge(label: 'Riverpod'),
            _FeatureBadge(label: 'Hive'),
            _FeatureBadge(label: 'Offline'),
          ],
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

/// Small pill badge used in the About section.
class _FeatureBadge extends StatelessWidget {
  const _FeatureBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: context.colors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: context.colors.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Text(
        label,
        style: context.textTheme.labelSmall?.copyWith(
          color: context.colors.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
