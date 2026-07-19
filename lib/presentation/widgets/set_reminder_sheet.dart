import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/notification_service.dart';
import '../../core/widgets/glass_container.dart';
import '../../domain/entities/reminder.dart';
import '../../domain/entities/reminder_enums.dart';
import '../providers/reminder_providers.dart';

/// A bottom sheet for creating or editing a reminder with optional voice
/// playback.
///
/// When [existing] is `null` the sheet operates in **create** mode: the title
/// reads "New Reminder", the action button reads "Set Reminder", and submitting
/// calls [ReminderListNotifier.addReminder]. When [existing] is provided the
/// sheet is in **edit** mode: all fields are prefilled, the title reads
/// "Edit Reminder", the button reads "Update Reminder", and submitting calls
/// [ReminderListNotifier.updateReminder].
///
/// The sheet lets the user pick a date + time, choose a repeat cadence from
/// [Recurrence.values], and configure the headline voice-reminder feature: a
/// spoken prefix (default "Boss") that the TTS engine says before the reminder
/// title when the alarm fires. A "Preview voice" button speaks the current
/// composition aloud so the user can hear it before scheduling.
///
/// The widget is intended to be displayed via [showModalBottomSheet] — it is
/// the sheet's content, not the trigger.
class SetReminderSheet extends ConsumerStatefulWidget {
  const SetReminderSheet({super.key, this.existing});

  /// Optional reminder to edit. When `null` the sheet creates a new reminder.
  final Reminder? existing;

  @override
  ConsumerState<SetReminderSheet> createState() => _SetReminderSheetState();
}

class _SetReminderSheetState extends ConsumerState<SetReminderSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _noteController;
  late final TextEditingController _prefixController;
  late final FocusNode _titleFocus;

  late DateTime _selectedDateTime;
  late Recurrence _recurrence;

  bool _voiceEnabled = true;
  bool _saving = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _titleController = TextEditingController(text: existing?.title ?? '');
    _noteController = TextEditingController(text: existing?.note ?? '');
    _prefixController = TextEditingController(
      text: existing?.voicePrefix ?? AppConstants.defaultVoicePrefix,
    );
    _titleFocus = FocusNode();

    if (existing != null) {
      _selectedDateTime = existing.scheduledAt;
      _recurrence = existing.recurrence;
      _voiceEnabled = existing.voiceEnabled;
    } else {
      // Default: next top-of-the-hour from now (e.g. 14:32 → 15:00).
      final now = DateTime.now();
      _selectedDateTime = DateTime(
        now.year,
        now.month,
        now.day,
        now.hour,
        0,
      ).add(const Duration(hours: 1));
      _recurrence = Recurrence.once;
      _voiceEnabled = true;
    }

    // Rebuild when the title or prefix changes so the Save button's enabled
    // state and the live voice preview stay in sync with the field values.
    _titleController.addListener(_fieldChanged);
    _prefixController.addListener(_fieldChanged);
  }

  void _fieldChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _titleController.removeListener(_fieldChanged);
    _prefixController.removeListener(_fieldChanged);
    _titleController.dispose();
    _noteController.dispose();
    _prefixController.dispose();
    _titleFocus.dispose();
    super.dispose();
  }

  /// Formats [dt] for display in the "When" row. Uses the year-skip form when
  /// the date is in a different calendar year than today.
  String _formatWhen(DateTime dt) {
    final now = DateTime.now();
    final sameYear = dt.year == now.year;
    final pattern = sameYear
        ? 'EEE, MMM d · h:mm a'
        : 'EEE, MMM d, yyyy · h:mm a';
    return DateFormat(pattern).format(dt);
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final initialDate =
        _selectedDateTime.isBefore(today) ? today : _selectedDateTime;

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365 * 5)),
      helpText: 'Select date',
    );
    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
      helpText: 'Select time',
    );
    // If the user cancels the time picker, keep the existing time of day.
    final time = pickedTime ?? TimeOfDay.fromDateTime(_selectedDateTime);
    if (!mounted) return;

    setState(() {
      _selectedDateTime = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        time.hour,
        time.minute,
      );
    });
  }

  void _setNow() {
    setState(() {
      _selectedDateTime = DateTime.now().add(const Duration(minutes: 1));
    });
  }

  Future<void> _previewVoice() async {
    final title = _titleController.text.trim();
    final prefix = _prefixController.text.trim().isEmpty
        ? AppConstants.defaultVoicePrefix
        : _prefixController.text.trim();
    final spoken = title.isEmpty ? '$prefix, your task' : '$prefix, $title';
    await NotificationService.instance.speak(spoken);
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a reminder title'),
          duration: Duration(seconds: 2),
        ),
      );
      _titleFocus.requestFocus();
      return;
    }

    setState(() => _saving = true);
    try {
      // Ensure the OS will let us schedule alarms. On platforms where
      // permission was already granted this is a fast no-op.
      await NotificationService.instance.requestPermissions();

      final note = _noteController.text.trim();
      final noteValue = note.isEmpty ? null : note;
      final prefix = _prefixController.text.trim().isEmpty
          ? AppConstants.defaultVoicePrefix
          : _prefixController.text.trim();

      final notifier = ref.read(reminderListProvider.notifier);

      if (_isEditing) {
        final existing = widget.existing!;
        await notifier.updateReminder(
          existing.copyWith(
            title: title,
            note: noteValue,
            scheduledAt: _selectedDateTime,
            recurrence: _recurrence,
            voiceEnabled: _voiceEnabled,
            voicePrefix: prefix,
            updatedAt: DateTime.now(),
          ),
        );
      } else {
        await notifier.addReminder(
          title: title,
          note: noteValue,
          scheduledAt: _selectedDateTime,
          recurrence: _recurrence,
          voiceEnabled: _voiceEnabled,
          voicePrefix: prefix,
        );
      }
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
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
              const _DragHandle(),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                child: Row(
                  children: [
                    Text(
                      _isEditing ? 'Edit Reminder' : 'New Reminder',
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
                          // 1. Title field.
                          TextField(
                            controller: _titleController,
                            focusNode: _titleFocus,
                            autofocus: true,
                            textCapitalization: TextCapitalization.sentences,
                            textInputAction: TextInputAction.next,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                            decoration: const InputDecoration(
                              hintText: 'What do you need to remember?',
                            ),
                          ),
                          const SizedBox(height: 12),
                          // 2. Note field.
                          TextField(
                            controller: _noteController,
                            maxLines: 2,
                            textCapitalization: TextCapitalization.sentences,
                            style: const TextStyle(fontSize: 14),
                            decoration: const InputDecoration(
                              hintText: 'Add a note (optional)',
                            ),
                          ),
                          const SizedBox(height: 16),
                          // 3. When (date + time).
                          _WhenRow(
                            formatted: _formatWhen(_selectedDateTime),
                            onPick: _pickDateTime,
                            onNow: _setNow,
                          ),
                          const SizedBox(height: 16),
                          // 4. Repeat cadence.
                          const _SectionLabel(text: 'Repeat'),
                          const SizedBox(height: 8),
                          _RecurrenceSelector(
                            selected: _recurrence,
                            onChanged: (r) =>
                                setState(() => _recurrence = r),
                          ),
                          const SizedBox(height: 16),
                          // 5. Voice reminder.
                          _VoiceSection(
                            voiceEnabled: _voiceEnabled,
                            onToggle: (v) =>
                                setState(() => _voiceEnabled = v),
                            prefixController: _prefixController,
                            titleController: _titleController,
                            onPreview: _previewVoice,
                          ),
                          const SizedBox(height: 24),
                          // 6. Save button.
                          FilledButton.icon(
                            onPressed: (_saving ||
                                    _titleController.text.trim().isEmpty)
                                ? null
                                : _save,
                            style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(52),
                            ),
                            icon: _saving
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
                                        : Icons.alarm_add_rounded,
                                  ),
                            label: Text(
                              _isEditing ? 'Update Reminder' : 'Set Reminder',
                            ),
                          ),
                          // Small breathing room below the button so it's not
                          // flush with the home indicator when the keyboard is
                          // dismissed.
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
  const _DragHandle();

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

/// Tappable card showing the selected date + time, with a "Now" quick-action.
class _WhenRow extends StatelessWidget {
  const _WhenRow({
    required this.formatted,
    required this.onPick,
    required this.onNow,
  });

  /// Pre-formatted date+time string to display.
  final String formatted;

  /// Opens the date + time pickers.
  final VoidCallback onPick;

  /// Snaps the scheduled time to one minute from now.
  final VoidCallback onNow;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GlassContainer(
      borderRadius: const BorderRadius.all(Radius.circular(16)),
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'When',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: onNow,
                child: const Text('Now'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPick,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 20,
                      color: scheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        formatted,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: scheme.onSurface,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: scheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Wrap of selectable [Recurrence] chips.
class _RecurrenceSelector extends StatelessWidget {
  const _RecurrenceSelector({
    required this.selected,
    required this.onChanged,
  });

  final Recurrence selected;
  final ValueChanged<Recurrence> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final recurrence in Recurrence.values)
          _RecurrenceChip(
            recurrence: recurrence,
            selected: recurrence == selected,
            onTap: () => onChanged(recurrence),
          ),
      ],
    );
  }
}

class _RecurrenceChip extends StatelessWidget {
  const _RecurrenceChip({
    required this.recurrence,
    required this.selected,
    required this.onTap,
  });

  final Recurrence recurrence;
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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: selected ? scheme.primary : scheme.surfaceContainerHigh,
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
              if (selected) ...[
                const Icon(
                  Icons.check_rounded,
                  size: 14,
                  color: Colors.white,
                ),
                const SizedBox(width: 6),
              ],
              Text(
                recurrence.label,
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

/// Glass card containing the voice-reminder toggle, prefix field, preview
/// button, and a live italic preview of what the TTS engine will say.
class _VoiceSection extends StatelessWidget {
  const _VoiceSection({
    required this.voiceEnabled,
    required this.onToggle,
    required this.prefixController,
    required this.titleController,
    required this.onPreview,
  });

  final bool voiceEnabled;
  final ValueChanged<bool> onToggle;
  final TextEditingController prefixController;
  final TextEditingController titleController;
  final VoidCallback onPreview;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final prefix = prefixController.text.trim().isEmpty
        ? AppConstants.defaultVoicePrefix
        : prefixController.text.trim();
    final title = titleController.text.trim().isEmpty
        ? 'your task'
        : titleController.text.trim();
    final previewText = '"$prefix, $title"';
    final canPreview = titleController.text.trim().isNotEmpty;

    return GlassContainer(
      borderRadius: const BorderRadius.all(Radius.circular(20)),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.record_voice_over_rounded,
                color: AppColors.accent,
                size: 22,
              ),
              const SizedBox(width: 10),
              Text(
                'Voice reminder',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurface,
                ),
              ),
              const Spacer(),
              Switch(
                value: voiceEnabled,
                onChanged: onToggle,
              ),
            ],
          ),
          if (voiceEnabled) ...[
            const SizedBox(height: 12),
            TextField(
              controller: prefixController,
              maxLength: 20,
              textCapitalization: TextCapitalization.sentences,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Spoken prefix',
                counterText: '',
                helperText: 'The app will say: "$prefix, $title"',
                helperStyle: TextStyle(
                  fontSize: 12,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: canPreview ? onPreview : null,
                icon: const Icon(Icons.volume_up_rounded, size: 18),
                label: const Text('Preview voice'),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              previewText,
              style: const TextStyle(
                fontSize: 13,
                fontStyle: FontStyle.italic,
                color: AppColors.accent,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
