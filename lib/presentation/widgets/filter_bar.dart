import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/filter_providers.dart';

/// Display label for each [TaskFilter] in the filter strip.
String _filterLabel(TaskFilter filter) {
  switch (filter) {
    case TaskFilter.all:
      return 'All';
    case TaskFilter.active:
      return 'Active';
    case TaskFilter.completed:
      return 'Done';
    case TaskFilter.overdue:
      return 'Overdue';
    case TaskFilter.today:
      return 'Today';
  }
}

/// A horizontally scrollable strip of filter chips plus a sort menu.
///
/// Reads the active [TaskFilter] from [filterProvider] and writes back via
/// `setFilter`. The trailing sort button opens a [PopupMenuButton] listing all
/// [SortOption]s; selecting one calls `setSort`.
///
/// Designed to sit just below the search bar on the home screen.
class FilterBar extends ConsumerWidget {
  const FilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filterState = ref.watch(filterProvider);
    final scheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        children: [
          // Filter chips for every TaskFilter value.
          for (final filter in TaskFilter.values) ...[
            _FilterChipItem(
              label: _filterLabel(filter),
              selected: filterState.filter == filter,
              onTap: () =>
                  ref.read(filterProvider.notifier).setFilter(filter),
            ),
            const SizedBox(width: 8),
          ],
          // Sort menu button at the end of the strip.
          PopupMenuButton<SortOption>(
            tooltip: 'Sort tasks',
            icon: Icon(
              Icons.sort_rounded,
              color: scheme.onSurfaceVariant,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            position: PopupMenuPosition.under,
            onSelected: (option) =>
                ref.read(filterProvider.notifier).setSort(option),
            itemBuilder: (context) => [
              for (final option in SortOption.values)
                PopupMenuItem<SortOption>(
                  value: option,
                  child: Row(
                    children: [
                      Icon(
                        filterState.sort == option
                            ? Icons.check_rounded
                            : Icons.sort_rounded,
                        size: 18,
                        color: filterState.sort == option
                            ? scheme.primary
                            : scheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 10),
                      Text(option.label),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A single selectable chip rendered as a [FilterChip] with the app's visual
/// language. Kept private to this file as it is an implementation detail.
class _FilterChipItem extends StatelessWidget {
  const _FilterChipItem({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? scheme.primary
                : scheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(20),
            border: selected
                ? null
                : Border.all(
                    color: scheme.outlineVariant.withValues(alpha: 0.4),
                  ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? scheme.onPrimary : scheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
