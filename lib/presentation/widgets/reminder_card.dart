import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/notification_service.dart';
import '../../core/widgets/glass_container.dart';
import '../../domain/entities/reminder.dart';
import '../../domain/entities/reminder_enums.dart';
import '../providers/reminder_providers.dart';

/// A single reminder rendered as a swipeable, glassmorphic card.
///
/// Mirrors the [TaskCard] pattern: a [Slidable] wraps a [GlassContainer] and
/// exposes one or two swipe actions:
/// - **Swipe right** (start pane): preview the spoken reminder aloud via the
///   TTS engine. Only rendered when the reminder has voice enabled.
/// - **Swipe left** (end pane): delete the reminder (red destructive action).
///
/// The card itself shows an alarm-bell medallion whose color reflects the
/// armed / overdue / disarmed state, the reminder title, an optional note, a
/// row of meta chips (date/time, recurrence, voice), an italic spoken-text
/// preview when voice is enabled, and a compact [Switch] on the right to arm
/// or disarm the reminder. Tapping the card speaks the reminder aloud (when
/// voice is enabled) so the user can audition it without waiting for the
/// alarm. Disarmed reminders are rendered at reduced opacity.
class ReminderCard extends ConsumerWidget {
  const ReminderCard({
    super.key,
    required this.reminder,
    this.index = 0,
  });

  /// The reminder to render.
  final Reminder reminder;

  /// Position in the parent list — used to stagger the entrance animation.
  final int index;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final now = DateTime.now();
    // A reminder is "overdue" when it is still armed but its scheduled time
    // has already passed — for one-off reminders this means it hasn't been
    // marked fired yet; for recurring ones it means the next occurrence is
    // overdue.
    final isOverdue =
        reminder.isActive && reminder.scheduledAt.isBefore(now);

    // Bell medallion color + glyph reflect the current armed state.
    final Color iconColor;
    final IconData iconData;
    if (!reminder.isActive) {
      iconColor = scheme.onSurfaceVariant;
      iconData = Icons.alarm_off_rounded;
    } else if (isOverdue) {
      iconColor = AppColors.error;
      iconData = Icons.alarm_rounded;
    } else {
      iconColor = AppColors.accent;
      iconData = Icons.alarm_rounded;
    }

    return Slidable(
      key: ValueKey('reminder-${reminder.id}'),
      groupTag: 'reminders',
      closeOnScroll: true,
      // Start pane is only useful when there's a voice to preview.
      startActionPane: reminder.voiceEnabled
          ? ActionPane(
              motion: const DrawerMotion(),
              extentRatio: 0.30,
              children: [
                SlidableAction(
                  onPressed: (_) => NotificationService.instance
                      .speak(reminder.spokenText),
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  icon: Icons.record_voice_over_rounded,
                  label: 'Test voice',
                  borderRadius: BorderRadius.circular(16),
                  autoClose: true,
                ),
              ],
            )
          : null,
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: 0.30,
        children: [
          SlidableAction(
            onPressed: (_) =>
                ref.read(reminderListProvider.notifier).deleteReminder(
                      reminder.id,
                    ),
            backgroundColor: AppColors.error,
            foregroundColor: Colors.white,
            icon: Icons.delete_rounded,
            label: 'Delete',
            borderRadius: BorderRadius.circular(16),
            autoClose: true,
          ),
        ],
      ),
      child: GlassContainer(
        borderRadius: BorderRadius.circular(16),
        padding: EdgeInsets.zero,
        color: scheme.surface.withValues(alpha: 0.85),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                if (reminder.voiceEnabled) {
                  NotificationService.instance.speak(reminder.spokenText);
                } else {
                  // Subtle haptic so the tap doesn't feel dead.
                  Feedback.forTap(context);
                }
              },
              child: Opacity(
                // Whole card dims when disarmed.
                opacity: reminder.isActive ? 1 : 0.55,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _AlarmMedallion(color: iconColor, icon: iconData),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              reminder.title,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: scheme.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if ((reminder.note ?? '').isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                reminder.note!,
                                style: TextStyle(
                                  fontSize: 13,
                                  height: 1.3,
                                  color: scheme.onSurfaceVariant,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                            const SizedBox(height: 8),
                            _MetaChipsRow(
                              reminder: reminder,
                              isOverdue: isOverdue,
                            ),
                            if (reminder.voiceEnabled) ...[
                              const SizedBox(height: 6),
                              Text(
                                '"${reminder.spokenText}"',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                  color: scheme.onSurfaceVariant,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      _ToggleSwitch(
                        value: reminder.isActive,
                        onChanged: (_) => ref
                            .read(reminderListProvider.notifier)
                            .toggleActive(reminder.id),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(delay: (index * 60).ms, duration: 300.ms)
        .slideY(begin: 0.05, end: 0, duration: 300.ms);
  }
}

/// The circular alarm-bell medallion on the left of a [ReminderCard].
///
/// Background is the medallion [color] at 15% alpha; the bell glyph itself is
/// rendered at full [color] so the icon "pops" against the tint.
class _AlarmMedallion extends StatelessWidget {
  const _AlarmMedallion({required this.color, required this.icon});

  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 22, color: color),
    );
  }
}

/// Row of meta chips under the reminder title: date/time, recurrence, voice.
///
/// The date/time chip switches to a red filled variant when the reminder is
/// overdue so the user can spot the missed alarm at a glance. The recurrence
/// chip is omitted for one-off reminders; the voice chip is omitted when
/// voice is disabled.
class _MetaChipsRow extends StatelessWidget {
  const _MetaChipsRow({required this.reminder, required this.isOverdue});

  final Reminder reminder;
  final bool isOverdue;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dateLabel = DateFormat('EEE, MMM d · h:mm a')
        .format(reminder.scheduledAt.toLocal());

    return Wrap(
      spacing: 6,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _MetaChip(
          color: isOverdue ? AppColors.error : scheme.onSurfaceVariant,
          label: dateLabel,
          icon: isOverdue
              ? Icons.warning_amber_rounded
              : Icons.event_rounded,
          filled: isOverdue,
        ),
        if (reminder.recurrence != Recurrence.once)
          _MetaChip(
            color: scheme.onSurfaceVariant,
            label: reminder.recurrence.label,
            icon: Icons.repeat_rounded,
          ),
        if (reminder.voiceEnabled)
          _MetaChip(
            color: AppColors.accent,
            label: reminder.voicePrefix.trim().isEmpty
                ? 'Voice'
                : '${reminder.voicePrefix.trim()} voice',
            icon: Icons.record_voice_over_rounded,
            filled: true,
          ),
      ],
    );
  }
}

/// A single pill-shaped meta chip with a colored icon and label.
///
/// When [filled] is true the chip uses a tinted background (the chip color at
/// 16% alpha) and the label takes on the chip color — used to draw attention
/// to overdue / voice chips. Otherwise the chip is a neutral surface pill.
class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.color,
    required this.label,
    required this.icon,
    this.filled = false,
  });

  final Color color;
  final String label;
  final IconData icon;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: filled
            ? color.withValues(alpha: 0.16)
            : scheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: filled ? color : scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact material [Switch] used to arm or disarm a [ReminderCard].
///
/// The native [Switch] is slightly downscaled (0.85) so it fits the card's
/// tight right gutter without overwhelming the title text.
class _ToggleSwitch extends StatelessWidget {
  const _ToggleSwitch({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: 0.85,
      child: Switch(
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}
