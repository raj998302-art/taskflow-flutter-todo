import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/task_enums.dart';

/// Which set of tasks the home list should show.
enum TaskFilter { all, active, completed, overdue, today }

/// How the list should be ordered.
enum SortOption {
  byDateCreated('Newest first'),
  byDueDate('Due date'),
  byPriority('Priority'),
  alphabetical('A–Z');

  const SortOption(this.label);
  final String label;
}

/// Filter & search state for the home screen.
class FilterState {
  const FilterState({
    this.filter = TaskFilter.all,
    this.category,
    this.priority,
    this.searchQuery = '',
    this.sort = SortOption.byDateCreated,
  });

  final TaskFilter filter;
  final TaskCategory? category;
  final Priority? priority;
  final String searchQuery;
  final SortOption sort;

  FilterState copyWith({
    TaskFilter? filter,
    TaskCategory? category,
    Priority? priority,
    String? searchQuery,
    SortOption? sort,
    bool clearCategory = false,
    bool clearPriority = false,
  }) {
    return FilterState(
      filter: filter ?? this.filter,
      category: clearCategory ? null : category ?? this.category,
      priority: clearPriority ? null : priority ?? this.priority,
      searchQuery: searchQuery ?? this.searchQuery,
      sort: sort ?? this.sort,
    );
  }

  bool get hasActiveFilters =>
      filter != TaskFilter.all ||
      category != null ||
      priority != null ||
      searchQuery.isNotEmpty ||
      sort != SortOption.byDateCreated;
}

class FilterNotifier extends StateNotifier<FilterState> {
  FilterNotifier() : super(const FilterState());

  void setFilter(TaskFilter f) => state = state.copyWith(filter: f);
  void setCategory(TaskCategory? c) =>
      state = state.copyWith(category: c, clearCategory: c == null);
  void setPriority(Priority? p) =>
      state = state.copyWith(priority: p, clearPriority: p == null);
  void setSearch(String q) => state = state.copyWith(searchQuery: q);
  void setSort(SortOption s) => state = state.copyWith(sort: s);
  void reset() => state = const FilterState();
}

final filterProvider =
    StateNotifierProvider<FilterNotifier, FilterState>((ref) {
  return FilterNotifier();
});
