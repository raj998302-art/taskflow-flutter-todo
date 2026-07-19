import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/extensions.dart';
import '../../domain/entities/task.dart';
import '../../domain/entities/task_enums.dart';
import '../providers/task_providers.dart';
import 'category_chip.dart';

/// A bottom sheet for creating a new task or editing an existing one.
///
/// When [existing] is `null` the sheet operates in **create** mode: the title
/// reads "New Task", the action button reads "Add Task", and submitting calls
/// [TaskListNotifier.addTask]. When [existing] is provided the sheet is in
/// **edit** mode: fields are prefilled, the title reads "Edit Task", the
/// button reads "Save Changes", and submitting calls
/// [TaskListNotifier.updateTask].
///
/// The widget is intended to be displayed via [showModalBottomSheet] — it is
/// the sheet's content, not the trigger.
class AddTaskSheet extends ConsumerStatefulWidget {
  const AddTaskSheet({super.key, this.existing});

  /// Optional task to edit. When `null` the sheet creates a new task.
  final Task? existing;

  @override
  ConsumerState<AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends ConsumerState<AddTaskSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _descController;
  late final FocusNode _titleFocus;

  late Priority _selectedPriority;
  late TaskCategory _selectedCategory;
  DateTime? _selectedDueDate;

  bool _isSaving = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final task = widget.existing;
    _titleController = TextEditingController(text: task?.title ?? '');
    _descController = TextEditingController(text: task?.description ?? '');
    _titleFocus = FocusNode();
    _selectedPriority = task?.priority ?? Priority.medium;
    _selectedCategory = task?.category ?? TaskCategory.personal;
    _selectedDueDate = task?.dueDate;

    _titleController.addListener(() {
      // Rebuild so the Save button's enabled state tracks the field.
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _titleFocus.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate ?? today,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365 * 5)),
      helpText: 'Select due date',
    );
    if (picked != null) {
      setState(() => _selectedDueDate = picked);
    }
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a task title'),
          duration: Duration(seconds: 2),
        ),
      );
      _titleFocus.requestFocus();
      return;
    }

    final description = _descController.text.trim();
    final descriptionValue = description.isEmpty ? null : description;

    setState(() => _isSaving = true);
    try {
      final notifier = ref.read(taskListProvider.notifier);
      if (_isEditing) {
        final existing = widget.existing!;
        // Construct the updated Task directly so nullable fields
        // (description, dueDate) can be *cleared* — Task.copyWith falls back
        // to the existing value when given null, which would prevent users
        // from removing a due date they previously set.
        final updated = Task(
          id: existing.id,
          title: title,
          description: descriptionValue,
          isCompleted: existing.isCompleted,
          priority: _selectedPriority,
          category: _selectedCategory,
          dueDate: _selectedDueDate,
          createdAt: existing.createdAt,
          updatedAt: DateTime.now(),
        );
        await notifier.updateTask(updated);
      } else {
        await notifier.addTask(
          title: title,
          description: descriptionValue,
          priority: _selectedPriority,
          category: _selectedCategory,
          dueDate: _selectedDueDate,
        );
      }
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final viewInsets = MediaQuery.of(context).viewInsets;
    final isWide = MediaQuery.of(context).size.width >= 600;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(bottom: viewInsets.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _DragHandle(),
              Padding(
                padding:
                    const EdgeInsets.fromLTRB(20, 4, 20, 12),
                child: Row(
                  children: [
                    Text(
                      _isEditing ? 'Edit Task' : 'New Task',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      tooltip: 'Close',
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  reverse: false,
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Center(
                    // Constrain the form width on tablets for ergonomics.
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: isWide ? 600 : double.infinity,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _TitleField(
                            controller: _titleController,
                            focusNode: _titleFocus,
                          ),
                          const SizedBox(height: 12),
                          _DescriptionField(controller: _descController),
                          const SizedBox(height: 16),
                          _SectionLabel(text: 'Priority'),
                          const SizedBox(height: 8),
                          _PrioritySelector(
                            selected: _selectedPriority,
                            onChanged: (p) =>
                                setState(() => _selectedPriority = p),
                          ),
                          const SizedBox(height: 16),
                          _SectionLabel(text: 'Category'),
                          const SizedBox(height: 8),
                          _CategorySelector(
                            selected: _selectedCategory,
                            onChanged: (c) =>
                                setState(() => _selectedCategory = c),
                          ),
                          const SizedBox(height: 16),
                          _SectionLabel(text: 'Due date'),
                          const SizedBox(height: 8),
                          _DueDateRow(
                            dueDate: _selectedDueDate,
                            onPick: _pickDueDate,
                            onClear: () =>
                                setState(() => _selectedDueDate = null),
                          ),
                          const SizedBox(height: 24),
                          FilledButton.icon(
                            onPressed: _isSaving ||
                                    _titleController.text.trim().isEmpty
                                ? null
                                : _save,
                            icon: _isSaving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor:
                                          AlwaysStoppedAnimation<Color>(
                                              Colors.white),
                                    ),
                                  )
                                : Icon(
                                    _isEditing
                                        ? Icons.save_outlined
                                        : Icons.add_rounded,
                                  ),
                            label: Text(
                              _isEditing ? 'Save Changes' : 'Add Task',
                            ),
                          ),
                          // Small breathing room below the button so it's not
                          // flush with the home indicator when the keyboard
                          // is dismissed.
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 250.ms)
        .slideY(begin: 0.05, end: 0, duration: 250.ms);
  }
}

/// A small rounded bar shown at the top of the sheet to indicate it can be
/// dragged down to dismiss.
class _DragHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: Center(
        child: Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Theme.of(context)
                .colorScheme
                .onSurfaceVariant
                .withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}

/// Small uppercase label above a form section.
class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        color: scheme.onSurfaceVariant,
      ),
    );
  }
}

/// Title text field with autofocus.
class _TitleField extends StatelessWidget {
  const _TitleField({required this.controller, required this.focusNode});

  final TextEditingController controller;
  final FocusNode focusNode;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      autofocus: true,
      textCapitalization: TextCapitalization.sentences,
      textInputAction: TextInputAction.next,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      decoration: const InputDecoration(
        hintText: 'What needs to be done?',
      ),
    );
  }
}

/// Multi-line description field.
class _DescriptionField extends StatelessWidget {
  const _DescriptionField({required this.controller});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: 3,
      minLines: 2,
      textCapitalization: TextCapitalization.sentences,
      style: const TextStyle(fontSize: 14),
      decoration: const InputDecoration(
        hintText: 'Add a note (optional)',
      ),
    );
  }
}

/// Priority selector built from a [Wrap] of custom chips coloured per priority.
class _PrioritySelector extends StatelessWidget {
  const _PrioritySelector({
    required this.selected,
    required this.onChanged,
  });

  final Priority selected;
  final ValueChanged<Priority> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final priority in Priority.values)
          _PriorityChip(
            priority: priority,
            selected: priority == selected,
            onTap: () => onChanged(priority),
          ),
      ],
    );
  }
}

class _PriorityChip extends StatelessWidget {
  const _PriorityChip({
    required this.priority,
    required this.selected,
    required this.onTap,
  });

  final Priority priority;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = priorityColor(priority.value);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: selected ? color : scheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(20),
            border: selected
                ? null
                : Border.all(
                    color: scheme.outlineVariant.withValues(alpha: 0.4),
                  ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                selected ? Icons.check_rounded : Icons.flag_rounded,
                size: 14,
                color: selected ? Colors.white : color,
              ),
              const SizedBox(width: 6),
              Text(
                priorityLabel(priority.value),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : scheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Category selector built from the shared [CategoryChip] widget.
class _CategorySelector extends StatelessWidget {
  const _CategorySelector({
    required this.selected,
    required this.onChanged,
  });

  final TaskCategory selected;
  final ValueChanged<TaskCategory> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final category in TaskCategory.values)
          CategoryChip(
            category: category,
            selected: category == selected,
            onTap: () => onChanged(category),
          ),
      ],
    );
  }
}

/// Row that shows the selected due date and lets the user pick or clear it.
class _DueDateRow extends StatelessWidget {
  const _DueDateRow({
    required this.dueDate,
    required this.onPick,
    required this.onClear,
  });

  final DateTime? dueDate;
  final VoidCallback onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasDate = dueDate != null;
    final isOverdue = hasDate && dueDate!.isOverdue;

    return Material(
      color: scheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onPick,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(
                Icons.calendar_today_rounded,
                size: 20,
                color: isOverdue ? AppColors.error : scheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  hasDate ? dueDate!.dueLabel : 'No date',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: hasDate
                        ? (isOverdue ? AppColors.error : scheme.onSurface)
                        : scheme.onSurfaceVariant,
                  ),
                ),
              ),
              if (isOverdue)
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Icon(
                    Icons.warning_amber_rounded,
                    size: 18,
                    color: AppColors.error,
                  ),
                ),
              if (hasDate)
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  tooltip: 'Clear date',
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 32, minHeight: 32),
                  visualDensity: VisualDensity.compact,
                  color: scheme.onSurfaceVariant,
                  onPressed: onClear,
                )
              else
                Icon(
                  Icons.chevron_right_rounded,
                  color: scheme.onSurfaceVariant,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
