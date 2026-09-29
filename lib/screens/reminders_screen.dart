import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../copy.dart';
import '../data/reminders.dart';
import '../theme.dart';
import '../widgets/empty_state.dart';
import '../widgets/section_label.dart';
import '../widgets/vavaka_app_bar.dart';

/// "Tsiahy" tab: daily prayer reminders, as in the Figma "07 · Reminders"
/// (empty) and "07b · Reminders list" frames.
class RemindersScreen extends HookWidget {
  const RemindersScreen({super.key, required this.reminders});

  final Reminders reminders;

  @override
  Widget build(BuildContext context) {
    final items = useValueListenable(reminders);

    void notifyIfDenied(bool granted) {
      if (!granted && context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text(Copy.permissionDenied)));
      }
    }

    Future<void> add() async {
      final time = await showTimePicker(
        context: context,
        initialTime: const TimeOfDay(hour: 6, minute: 0),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        ),
      );
      if (time != null) {
        notifyIfDenied(await reminders.add(time.hour, time.minute));
      }
    }

    final addButton = _AddReminderButton(onPressed: add);

    return Scaffold(
      appBar: const VavakaAppBar(),
      body: switch (items) {
        null => const SizedBox.shrink(),
        [] => EmptyState(
          icon: Icons.notifications_none,
          message: 'Mametraha fampahatsiahivana mba hivavaka isan’andro.',
          action: addButton,
        ),
        _ => ListView(
          padding: const EdgeInsets.only(top: 16, bottom: 16),
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: SectionLabel(Copy.remindersLabel),
            ),
            Material(
              color: VavakaColors.of(context).surface,
              child: Column(
                children: [
                  for (final (index, reminder) in items.indexed) ...[
                    if (index > 0)
                      const Divider(height: 1, indent: 8, endIndent: 8),
                    _ReminderRow(
                      reminder: reminder,
                      onEnabledChanged: (enabled) async => notifyIfDenied(
                        await reminders.setEnabled(reminder, enabled),
                      ),
                      onDelete: () => reminders.remove(reminder),
                    ),
                  ],
                ],
              ),
            ),
            Padding(padding: const EdgeInsets.all(16), child: addButton),
          ],
        ),
      },
    );
  }
}

class _ReminderRow extends StatelessWidget {
  const _ReminderRow({
    required this.reminder,
    required this.onEnabledChanged,
    required this.onDelete,
  });

  final Reminder reminder;
  final ValueChanged<bool> onEnabledChanged;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = VavakaColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reminder.label,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    color: reminder.enabled ? colors.text : colors.textMuted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  Copy.daily,
                  style: VavakaText.footnote.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(value: reminder.enabled, onChanged: onEnabledChanged),
          IconButton(
            tooltip: Copy.deleteReminder,
            onPressed: onDelete,
            icon: Icon(Icons.delete_outline, color: colors.textMuted),
          ),
        ],
      ),
    );
  }
}

class _AddReminderButton extends StatelessWidget {
  const _AddReminderButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = VavakaColors.of(context);
    return Material(
      color: colors.surfaceRaised,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add, size: 20, color: colors.accent),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  Copy.addReminder,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colors.accent,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
