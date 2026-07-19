import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/extensions.dart';
import '../../core/widgets/glass_container.dart';
import '../../core/widgets/loading_animation.dart';
import '../../domain/entities/task_enums.dart';
import '../providers/stats_provider.dart';
import '../providers/task_providers.dart';

/// Statistics dashboard: completion ring, key metrics, weekly activity chart,
/// and breakdowns by category and priority.
class StatisticsPage extends ConsumerWidget {
  const StatisticsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(taskListProvider);
    final stats = ref.watch(statsProvider);

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
                onPressed: () => context.go('/'),
              ),
              title: const Text('Statistics'),
              backgroundColor: context.theme.scaffoldBackgroundColor,
              surfaceTintColor: Colors.transparent,
            ),
            tasksAsync.when(
              loading: () => const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: AppLoading()),
              ),
              error: (e, _) => SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Text('Could not load statistics: $e'),
                ),
              ),
              data: (_) => SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _CompletionRing(stats: stats),
                    const SizedBox(height: 16),
                    _MetricGrid(stats: stats),
                    const SizedBox(height: 16),
                    _WeeklyChart(stats: stats),
                    const SizedBox(height: 16),
                    _BreakdownCard(
                      title: 'By Category',
                      icon: Icons.category_rounded,
                      segments: _categorySegments(stats),
                      emptyMessage: 'No tasks to categorise yet.',
                    ),
                    const SizedBox(height: 16),
                    _BreakdownCard(
                      title: 'By Priority',
                      icon: Icons.flag_rounded,
                      segments: _prioritySegments(stats),
                      emptyMessage: 'No tasks to prioritise yet.',
                    ),
                  ]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<_Segment> _categorySegments(TaskStats stats) {
    const colorMap = <TaskCategory, Color>{
      TaskCategory.personal: AppColors.personal,
      TaskCategory.work: AppColors.work,
      TaskCategory.shopping: AppColors.shopping,
      TaskCategory.health: AppColors.health,
      TaskCategory.other: AppColors.other,
    };
    return stats.byCategory.entries
        .where((e) => e.value > 0)
        .map((e) => _Segment(
              label: e.key.label,
              value: e.value,
              color: colorMap[e.key] ?? AppColors.other,
            ))
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
  }

  List<_Segment> _prioritySegments(TaskStats stats) {
    const colorMap = <Priority, Color>{
      Priority.high: AppColors.highPriority,
      Priority.medium: AppColors.mediumPriority,
      Priority.low: AppColors.lowPriority,
    };
    return stats.byPriority.entries
        .where((e) => e.value > 0)
        .map((e) => _Segment(
              label: _priorityLabel(e.key),
              value: e.value,
              color: colorMap[e.key] ?? AppColors.mediumPriority,
            ))
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
  }

  String _priorityLabel(Priority p) =>
      p == Priority.high ? 'High' : p == Priority.low ? 'Low' : 'Medium';
}

/// Circular progress ring showing overall completion percentage.
class _CompletionRing extends StatelessWidget {
  const _CompletionRing({required this.stats});
  final TaskStats stats;

  @override
  Widget build(BuildContext context) {
    final pct = (stats.completionRate * 100).round();
    return GlassContainer(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            height: 120,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: stats.completionRate,
                  strokeWidth: 12,
                  backgroundColor:
                      context.colors.primary.withValues(alpha: 0.12),
                  valueColor: AlwaysStoppedAnimation(context.colors.primary),
                  strokeCap: StrokeCap.round,
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$pct%',
                      style: context.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'complete',
                      style: context.textTheme.labelSmall?.copyWith(
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your progress',
                  style: context.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  stats.completionRate >= 0.8
                      ? 'Outstanding work! Almost everything is done.'
                      : stats.completionRate >= 0.5
                          ? 'Great pace — keep the momentum going!'
                          : 'A good start. Tackle one task at a time.',
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [
                    _MiniBadge(
                      label: '${stats.completed} done',
                      color: AppColors.success,
                    ),
                    _MiniBadge(
                      label: '${stats.active} left',
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0);
  }
}

class _MiniBadge extends StatelessWidget {
  const _MiniBadge({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: context.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// 2×2 grid of key metrics.
class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.stats});
  final TaskStats stats;

  @override
  Widget build(BuildContext context) {
    final cards = <_MetricData>[
      _MetricData(
        label: 'Total',
        value: '${stats.total}',
        icon: Icons.inventory_2_rounded,
        color: AppColors.primary,
      ),
      _MetricData(
        label: 'Active',
        value: '${stats.active}',
        icon: Icons.flash_on_rounded,
        color: AppColors.secondary,
      ),
      _MetricData(
        label: 'Overdue',
        value: '${stats.overdue}',
        icon: Icons.warning_amber_rounded,
        color: AppColors.highPriority,
      ),
      _MetricData(
        label: 'Due Today',
        value: '${stats.dueToday}',
        icon: Icons.today_rounded,
        color: AppColors.accent,
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 600 ? 4 : 2;
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.05,
          children: [
            for (var i = 0; i < cards.length; i++)
              _MetricTile(data: cards[i])
                  .animate()
                  .fadeIn(delay: (i * 80).ms, duration: 300.ms)
                  .slideY(begin: 0.1, end: 0),
          ],
        );
      },
    );
  }
}

class _MetricData {
  const _MetricData({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
  final String label;
  final String value;
  final IconData icon;
  final Color color;
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.data});
  final _MetricData data;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: data.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(data.icon, size: 20, color: data.color),
          ),
          const Spacer(),
          Text(
            data.value,
            style: context.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            data.label,
            style: context.textTheme.labelSmall?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Weekly completed-tasks bar chart using fl_chart.
class _WeeklyChart extends StatelessWidget {
  const _WeeklyChart({required this.stats});
  final TaskStats stats;

  @override
  Widget build(BuildContext context) {
    final data = stats.weeklyCompleted;
    final maxY = (data.reduce((a, b) => a > b ? a : b)).clamp(1, 10).toDouble();
    final labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return GlassContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bar_chart_rounded,
                  size: 20, color: context.colors.primary),
              const SizedBox(width: 8),
              Text(
                'This week',
                style: context.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                'Completed tasks',
                style: context.textTheme.labelSmall?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 150,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxY + 1,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, gIdx, rod, rIdx) =>
                        BarTooltipItem(
                      '${rod.toY.toInt()} done',
                      TextStyle(
                        color: context.colors.onInverseSurface,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      getTitlesWidget: (value, _) {
                        final i = value.toInt();
                        if (i < 0 || i >= labels.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            labels[i],
                            style: context.textTheme.labelSmall?.copyWith(
                              color: context.colors.onSurfaceVariant,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: [
                  for (var i = 0; i < data.length; i++)
                    BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: data[i].toDouble(),
                          width: 18,
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(8)),
                          color: i == 6
                              ? context.colors.primary
                              : context.colors.primary.withValues(alpha: 0.55),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 150.ms, duration: 400.ms).slideY(begin: 0.05);
  }
}

class _Segment {
  const _Segment({required this.label, required this.value, required this.color});
  final String label;
  final int value;
  final Color color;
}

/// Horizontal bar breakdown card for categories/priorities.
class _BreakdownCard extends StatelessWidget {
  const _BreakdownCard({
    required this.title,
    required this.icon,
    required this.segments,
    required this.emptyMessage,
  });

  final String title;
  final IconData icon;
  final List<_Segment> segments;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    final total = segments.fold<int>(0, (s, e) => s + e.value);
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: context.colors.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: context.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (segments.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  emptyMessage,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
              ),
            )
          else ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                height: 12,
                child: Row(
                  children: [
                    for (final s in segments)
                      Expanded(
                        flex: s.value,
                        child: Container(color: s.color),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                for (final s in segments)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: s.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        s.label,
                        style: context.textTheme.bodySmall,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${s.value}',
                        style: context.textTheme.bodySmall?.copyWith(
                          color: context.colors.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${total == 0 ? 0 : ((s.value / total) * 100).round()}%',
                        style: context.textTheme.labelSmall?.copyWith(
                          color: context.colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ],
      ),
    ).animate().fadeIn(delay: 250.ms, duration: 400.ms).slideY(begin: 0.05);
  }
}
