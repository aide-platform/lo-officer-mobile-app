import 'dart:async';

import 'package:liaison_officer/core/notifications/mock_email_notifier.dart';
import 'package:liaison_officer/features/liaison_officer/data/models/lo_assignment.dart';
import 'package:liaison_officer/features/liaison_officer/presentation/screens/lo_notifications_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// LO.9.4 — fires portal + mock email alerts before scheduled tasks.
class UpcomingTaskReminderService {
  UpcomingTaskReminderService._();

  static const leadTime = Duration(minutes: 60);
  static const _prefsPrefix = 'lo_upcoming_fired_';

  static Timer? _timer;

  static void start(String loEmail) {
    stop();
    _check(loEmail);
    _timer = Timer.periodic(const Duration(minutes: 1), (_) => _check(loEmail));
  }

  static void stop() {
    _timer?.cancel();
    _timer = null;
  }

  static Future<void> _check(String loEmail) async {
    try {
      final tasks = await LoTaskAssignment.forLo(loEmail);
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();

      for (final task in tasks) {
        if (task.status == 'Completed') continue;
        final diff = task.scheduledDate.difference(now);
        if (diff.isNegative || diff > leadTime) continue;

        final key = '$_prefsPrefix${task.id}';
        if (prefs.getBool(key) == true) continue;
        await prefs.setBool(key, true);

        final minutes = diff.inMinutes.clamp(0, leadTime.inMinutes);
        LoNotificationStore.instance.add(
          LoNotification(
            id: 'upcoming_${task.id.hashCode}_$minutes',
            title: 'Upcoming task in ${minutes}m',
            body:
                '${task.taskTitle} for ${task.delegateName}'
                '${task.location.isNotEmpty ? ' at ${task.location}' : ''}.',
            type: LoNotifType.urgent,
            timestamp: DateTime.now(),
          ),
        );

        await MockEmailNotifier.send(
          to: loEmail,
          subject: 'Upcoming task: ${task.taskTitle}',
          body:
              'Reminder: ${task.taskTitle} for ${task.delegateName} starts in '
              'about $minutes minutes'
              '${task.location.isNotEmpty ? ' at ${task.location}' : ''}.',
        );
      }
    } catch (e) {
      // Web/storage failures should not crash the LO shell.
      assert(() {
        // ignore: avoid_print
        print('UpcomingTaskReminderService._check failed: $e');
        return true;
      }());
    }
  }
}
