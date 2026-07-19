import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/extensions.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/error_widget.dart';
import '../../core/widgets/glass_container.dart';
import '../../core/widgets/loading_animation.dart';
import '../providers/filter_providers.dart';
import '../providers/reminder_providers.dart';
import '../providers/stats_provider.dart';
import '../providers/task_providers.dart';
import '../providers/theme_provider.dart';
import '../widgets/add_task_sheet.dart';
import '../widgets/filter_bar.dart';
import '../widgets/reminder_card.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/set_reminder_sheet.dart';
import '../widgets/task_card.dart';

/// The main screen of the app — a tabbed layout with "Tasks" and "Reminders"
/// sections. The header shows a greeting, quick stats, and a theme toggle.
/// Each tab has its own floating action button (add task / set reminder).
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final ScrollController _taskScrollController = ScrollController();
  bool _showClearCompleted = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _taskScrollController.addListener(() {
      final show = _taskScrollController.offset > 200;
      if (show != _showClearCompleted) {
        setState(() => _showClearCompleted = show);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _taskScrollController.dispose();
    super.dispose();
  }

  Future<void> _openAddTaskSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (_) => const AddTaskSheet(),
    );
  }

  Future<void> _openSetReminderSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (_) => const SetReminderSheet(),
    );
  }

  Future<void> _confirmClearCompleted() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear completed tasks?'),
        content: const Text(
          'This will permanently remove all completed tasks. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      final count =
          await ref.read(taskListProvider.notifier).deleteCompletedTasks();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Cleared $count completed task${count == 1 ? '' : 's'}.')),
        );
      }
    }
  }

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(taskListProvider);
    final filtered = ref.watch(filteredTasksProvider);
    final stats = ref.watch(statsProvider);
    final themeMode = ref.watch(themeModeProvider);
    final remindersAsync = ref.watch(reminderListProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ---- Header (fixed, non-scrolling) ----
            _Header(
              greeting: _greeting,
              activeCount: stats.active,
              completedCount: stats.completed,
              themeMode: themeMode,
              onToggleTheme: () =>
                  ref.read(themeModeProvider.notifier).toggle(),
              onStatsTap: () => context.push('/statistics'),
            ),

            // ---- Tab bar ----
            _TabBarSection(tabController: _tabController),

            // ---- Tab content ----
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // -- TASKS TAB --
                  CustomScrollView(
                    controller: _taskScrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(16, 4, 16, 12),
                          child: AppSearchBar(),
                        ),
                      ),
                      const SliverToBoxAdapter(child: FilterBar()),
                      const SliverToBoxAdapter(child: SizedBox(height: 8)),
                      tasksAsync.when(
                        loading: () => const SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
                              child: AppLoading(label: 'Loading your tasks...')),
                        ),
                        error: (e, _) => SliverFillRemaining(
                          hasScrollBody: false,
                          child: AppErrorWidget(
                            message: 'Could not load tasks. ${e.toString()}',
                            onRetry: () =>
                                ref.read(taskListProvider.notifier).refresh(),
                          ),
                        ),
                        data: (_) {
                          if (filtered.isEmpty) {
                            return SliverFillRemaining(
                              hasScrollBody: false,
                              child: _buildTaskEmptyState(),
                            );
                          }
                          return SliverPadding(
                            padding: const EdgeInsets.only(bottom: 120),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, i) => Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: i == 0 ? 0 : 5,
                                  ),
                                  child: TaskCard(task: filtered[i], index: i),
                                ),
                                childCount: filtered.length,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),

                  // -- REMINDERS TAB --
                  CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(
                        child: _ReminderIntro(),
                      ),
                      remindersAsync.when(
                        loading: () => const SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
                              child:
                                  AppLoading(label: 'Loading reminders...')),
                        ),
                        error: (e, _) => SliverFillRemaining(
                          hasScrollBody: false,
                          child: AppErrorWidget(
                            message: 'Could not load reminders. ${e.toString()}',
                            onRetry: () =>
                                ref.read(reminderListProvider.notifier).refresh(),
                          ),
                        ),
                        data: (reminders) {
                          // Sort: upcoming active first, then inactive, then past.
                          final sorted = _sortReminders(reminders);
                          if (sorted.isEmpty) {
                            return const SliverFillRemaining(
                              hasScrollBody: false,
                              child: AppEmptyState(
                                icon: Icons.alarm_add_rounded,
                                title: 'No reminders yet',
                                subtitle:
                                    'Tap "Set Reminder" to create a voice alarm '
                                    '— e.g. "Boss, sabji lena hai" at 8:05 PM.',
                              ),
                            );
                          }
                          return SliverPadding(
                            padding: const EdgeInsets.only(bottom: 120),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, i) => Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: i == 0 ? 0 : 5,
                                  ),
                                  child:
                                      ReminderCard(reminder: sorted[i], index: i),
                                ),
                                childCount: sorted.length,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _tabController.index == 1
          ? FloatingActionButton.extended(
              heroTag: 'set_reminder',
              onPressed: _openSetReminderSheet,
              icon: const Icon(Icons.alarm_add_rounded),
              label: const Text('Set Reminder'),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (_showClearCompleted && stats.completed > 0)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: FloatingActionButton.small(
                      heroTag: 'clear_completed',
                      onPressed: _confirmClearCompleted,
                      tooltip: 'Clear completed',
                      child: const Icon(Icons.cleaning_services_rounded),
                    ),
                  ),
                FloatingActionButton.extended(
                  heroTag: 'add_task',
                  onPressed: _openAddTaskSheet,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('New Task'),
                ),
              ],
            ),
    );
  }

  Widget _buildTaskEmptyState() {
    final hasFilters = ref.read(filterProvider).hasActiveFilters;
    if (hasFilters) {
      return AppEmptyState(
        icon: Icons.search_off_rounded,
        title: 'No matching tasks',
        subtitle: 'Try adjusting your filters or search query.',
        actionLabel: 'Clear filters',
        onAction: () => ref.read(filterProvider.notifier).reset(),
      );
    }
    return const AppEmptyState(
      icon: Icons.task_alt_rounded,
      title: 'No tasks yet',
      subtitle: 'Tap "New Task" to add your first task and get organised.',
    );
  }

  List<dynamic> _sortReminders(List<dynamic> reminders) {
    final now = DateTime.now();
    final active = <dynamic>[];
    final inactive = <dynamic>[];
    for (final r in reminders) {
      if (r.isActive) {
        active.add(r);
      } else {
        inactive.add(r);
      }
    }
    active.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    // Upcoming first (scheduledAt after now), then past.
    final upcoming =
        active.where((r) => r.scheduledAt.isAfter(now)).toList();
    final past = active.where((r) => !r.scheduledAt.isAfter(now)).toList();
    inactive.sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));
    return [...upcoming, ...past, ...inactive];
  }
}

/// A compact intro banner at the top of the Reminders tab explaining the
/// voice feature.
class _ReminderIntro extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: GlassContainer(
        padding: const EdgeInsets.all(14),
        color: AppColors.accent.withValues(alpha: 0.12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.record_voice_over_rounded,
                  color: AppColors.accent, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Voice Reminders',
                    style: context.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Set an alarm and the app will speak it aloud — '
                    '"Boss, apko sabji lena hai"',
                    style: context.textTheme.bodySmall
                        ?.copyWith(color: context.colors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 350.ms)
        .slideY(begin: 0.05, end: 0);
  }
}

/// Tab bar section with glassmorphic background.
class _TabBarSection extends StatelessWidget {
  const _TabBarSection({required this.tabController});
  final TabController tabController;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: GlassContainer(
        padding: const EdgeInsets.all(4),
        borderRadius: BorderRadius.circular(16),
        child: TabBar(
          controller: tabController,
          indicator: BoxDecoration(
            color: context.colors.primary,
            borderRadius: BorderRadius.circular(12),
          ),
          dividerColor: Colors.transparent,
          indicatorSize: TabBarIndicatorSize.tab,
          labelColor: context.colors.onPrimary,
          unselectedLabelColor: context.colors.onSurfaceVariant,
          labelStyle: context.textTheme.labelLarge
              ?.copyWith(fontWeight: FontWeight.w700),
          unselectedLabelStyle: context.textTheme.labelLarge,
          tabs: const [
            Tab(
              icon: Icon(Icons.task_alt_rounded, size: 18),
              text: 'Tasks',
            ),
            Tab(
              icon: Icon(Icons.alarm_rounded, size: 18),
              text: 'Reminders',
            ),
          ],
        ),
      ),
    );
  }
}

/// Top header with greeting, theme toggle and a compact stat pill.
class _Header extends StatelessWidget {
  const _Header({
    required this.greeting,
    required this.activeCount,
    required this.completedCount,
    required this.themeMode,
    required this.onToggleTheme,
    required this.onStatsTap,
  });

  final String greeting;
  final int activeCount;
  final int completedCount;
  final ThemeMode themeMode;
  final VoidCallback onToggleTheme;
  final VoidCallback onStatsTap;

  @override
  Widget build(BuildContext context) {
    final isDark = themeMode == ThemeMode.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      greeting,
                      style: context.textTheme.titleMedium?.copyWith(
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      AppConstants.appName,
                      style: context.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              _GlassIconButton(
                icon: isDark
                    ? Icons.light_mode_rounded
                    : Icons.dark_mode_rounded,
                onTap: onToggleTheme,
              ),
            ],
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: onStatsTap,
            child: GlassContainer(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  _HeaderStat(
                    icon: Icons.flash_on_rounded,
                    value: '$activeCount',
                    label: 'Active',
                    color: AppColors.primary,
                  ),
                  Container(
                    width: 1,
                    height: 36,
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    color: context.colors.outlineVariant
                        .withValues(alpha: 0.4),
                  ),
                  _HeaderStat(
                    icon: Icons.check_circle_rounded,
                    value: '$completedCount',
                    label: 'Done',
                    color: AppColors.success,
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: context.colors.primaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.insights_rounded,
                          size: 16,
                          color: context.colors.onPrimaryContainer,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Stats',
                          style: context.textTheme.labelSmall?.copyWith(
                            color: context.colors.onPrimaryContainer,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.05, end: 0);
  }
}

class _HeaderStat extends StatelessWidget {
  const _HeaderStat({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: context.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              label,
              style: context.textTheme.labelSmall?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  const _GlassIconButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: GlassContainer(
          padding: const EdgeInsets.all(10),
          borderRadius: BorderRadius.circular(14),
          child: Icon(icon, size: 20, color: context.colors.onSurface),
        ),
      ),
    );
  }
}
