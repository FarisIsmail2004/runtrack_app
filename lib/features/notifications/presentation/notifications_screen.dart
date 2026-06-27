import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'package:runtrack_app/core/database/app_database.dart';
import 'package:runtrack_app/features/notifications/application/notification_providers.dart';

const _weekdayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S']; // index 0 = Mon

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final settingsAsync = ref.watch(settingsStreamProvider);
    final dao = ref.watch(databaseProvider).settingsDao;
    final service = ref.watch(localNotificationServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Notifications',
          style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: cs.onSurface),
          tooltip: 'Back',
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/profile'),
        ),
      ),
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (s) => ListView(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          children: [
            SwitchListTile(
              title: const Text('Enable notifications'),
              value: s.notificationsEnabled,
              onChanged: (v) async {
                if (v) {
                  final granted = await service.requestPermission();
                  if (!granted) return; // leave off if denied
                }
                await dao.setNotificationsEnabled(v);
              },
            ),
            const Divider(),
            SwitchListTile(
              title: const Text('Run reminder'),
              subtitle: Text(
                '${_daysSummary(s.runReminderDays)} · ${_timeLabel(s.runReminderTimeMin)}',
              ),
              value: s.runReminderEnabled,
              onChanged: s.notificationsEnabled
                  ? (v) async {
                      if (v && s.runReminderDays.isEmpty) {
                        // Pre-fill from inferred history on first enable.
                        final suggestion = await ref.read(
                          suggestedScheduleProvider.future,
                        );
                        await dao.setRunReminderDays(_daysCsv(suggestion.days));
                        await dao.setRunReminderTimeMin(suggestion.timeMin);
                      }
                      await dao.setRunReminderEnabled(v);
                    }
                  : null,
            ),
            if (s.notificationsEnabled && s.runReminderEnabled) ...[
              _DayPicker(
                selected: _parseDays(s.runReminderDays),
                onChanged: (days) async {
                  await dao.setRunReminderDays(_daysCsv(days));
                },
              ),
              ListTile(
                title: const Text('Time'),
                trailing: Text(_timeLabel(s.runReminderTimeMin)),
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay(
                      hour: s.runReminderTimeMin ~/ 60,
                      minute: s.runReminderTimeMin % 60,
                    ),
                  );
                  if (picked != null) {
                    await dao.setRunReminderTimeMin(
                      picked.hour * 60 + picked.minute,
                    );
                  }
                },
              ),
            ],
            const Divider(),
            // Conditional-type toggles are stored now; Spec 2 acts on them.
            SwitchListTile(
              title: const Text('Streak alerts'),
              value: s.streakAlerts,
              onChanged: s.notificationsEnabled
                  ? (v) => dao.setStreakAlerts(v)
                  : null,
            ),
            SwitchListTile(
              title: const Text('Weekly goal nudges'),
              value: s.weeklyGoalAlerts,
              onChanged: s.notificationsEnabled
                  ? (v) => dao.setWeeklyGoalAlerts(v)
                  : null,
            ),
            SwitchListTile(
              title: const Text('Goal achieved'),
              value: s.goalAchievedAlerts,
              onChanged: s.notificationsEnabled
                  ? (v) => dao.setGoalAchievedAlerts(v)
                  : null,
            ),
            SwitchListTile(
              title: const Text('Comeback nudges'),
              value: s.comebackAlerts,
              onChanged: s.notificationsEnabled
                  ? (v) => dao.setComebackAlerts(v)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _DayPicker extends StatelessWidget {
  const _DayPicker({required this.selected, required this.onChanged});

  final Set<int> selected; // weekday ints 1..7
  final ValueChanged<Set<int>> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          for (var wd = 1; wd <= 7; wd++)
            ChoiceChip(
              label: Text(_weekdayLabels[wd - 1]),
              selected: selected.contains(wd),
              onSelected: (on) {
                final next = {...selected};
                on ? next.add(wd) : next.remove(wd);
                onChanged(next);
              },
            ),
        ],
      ),
    );
  }
}

Set<int> _parseDays(String csv) =>
    csv.split(',').map((d) => int.tryParse(d.trim())).whereType<int>().toSet();

String _daysCsv(Iterable<int> days) => (days.toList()..sort()).join(',');

String _daysSummary(String csv) {
  final days = (_parseDays(csv).toList()..sort());
  if (days.isEmpty) return 'No days';
  return days.map((d) => _weekdayLabels[d - 1]).join(' ');
}

String _timeLabel(int minutes) {
  final h = (minutes ~/ 60).toString().padLeft(2, '0');
  final m = (minutes % 60).toString().padLeft(2, '0');
  return '$h:$m';
}
