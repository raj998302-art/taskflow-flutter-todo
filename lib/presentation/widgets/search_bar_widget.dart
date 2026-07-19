import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/filter_providers.dart';
import '../../core/widgets/glass_container.dart';

/// A frosted-glass search field that writes its value to [filterProvider].
///
/// On every keystroke the widget calls
/// `ref.read(filterProvider.notifier).setSearch(value)` so the filtered task
/// list updates instantly. The initial text is hydrated from the current
/// filter state so the field survives screen rebuilds and navigation.
class AppSearchBar extends ConsumerStatefulWidget {
  const AppSearchBar({
    super.key,
    this.hintText = 'Search tasks...',
    this.autofocus = false,
  });

  /// Placeholder text shown when the field is empty.
  final String hintText;

  /// Whether to request focus immediately when the widget mounts.
  final bool autofocus;

  @override
  ConsumerState<AppSearchBar> createState() => _AppSearchBarState();
}

class _AppSearchBarState extends ConsumerState<AppSearchBar> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    // Hydrate from the existing filter state so the field restores the
    // previous search query when the home screen rebuilds.
    final initial = ref.read(filterProvider).searchQuery;
    _controller = TextEditingController(text: initial);
    _focusNode = FocusNode();
    _controller.addListener(_onControllerChanged);
  }

  void _onControllerChanged() {
    final value = _controller.text;
    final current = ref.read(filterProvider).searchQuery;
    // Avoid redundant provider writes when the value is already in sync.
    if (current != value) {
      ref.read(filterProvider.notifier).setSearch(value);
    }
    setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasText = _controller.text.isNotEmpty;

    return GlassContainer(
      borderRadius: BorderRadius.circular(16),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        autofocus: widget.autofocus,
        textInputAction: TextInputAction.search,
        textCapitalization: TextCapitalization.sentences,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: scheme.onSurface,
        ),
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: TextStyle(
            color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
            fontWeight: FontWeight.w400,
          ),
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: scheme.onSurfaceVariant,
            size: 22,
          ),
          prefixIconConstraints:
              const BoxConstraints(minWidth: 40, minHeight: 40),
          suffixIcon: hasText
              ? IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 40, minHeight: 40),
                  color: scheme.onSurfaceVariant,
                  tooltip: 'Clear search',
                  onPressed: () {
                    _controller.clear();
                    _focusNode.requestFocus();
                  },
                )
              : null,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          filled: false,
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 300.ms)
        .slideY(begin: 0.05, end: 0, duration: 300.ms);
  }
}
