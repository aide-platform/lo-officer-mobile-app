import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:liaison_officer/features/liaison_officer/data/models/cap/cap_models.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Push + local notification facade.
///
/// - Always schedules **local** task lead-time reminders via
///   `flutter_local_notifications` (no Firebase required).
/// - Real FCM stays opt-in with `--dart-define=ENABLE_FCM=true` after adding
///   Firebase configs and packages.
class PushNotificationService {
  PushNotificationService._();
  static final PushNotificationService instance = PushNotificationService._();

  static const _enableFcm = bool.fromEnvironment(
    'ENABLE_FCM',
    defaultValue: false,
  );

  static const _channelId = 'lo_task_reminders';
  static const _channelName = 'Task reminders';
  static const _channelDesc = 'Lead-time alerts for assigned LO tasks';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  void Function(String link)? onDeepLink;
  bool _fcmReady = false;
  bool _localReady = false;

  bool get isFcmEnabled => _enableFcm && _fcmReady;
  bool get isLocalReady => _localReady;

  Future<void> initialize() async {
    await _initLocal();
    await _initFcmStub();
  }

  Future<void> _initLocal() async {
    try {
      tz_data.initializeTimeZones();
      // Aero India LO field ops are IST; device offset rarely differs for this app.
      try {
        tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));
      } catch (_) {
        tz.setLocalLocation(tz.UTC);
      }
      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      const ios = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const init = InitializationSettings(android: android, iOS: ios);
      await _plugin.initialize(
        settings: init,
        onDidReceiveNotificationResponse: (response) {
          final payload = response.payload;
          if (payload != null && payload.isNotEmpty) {
            onDeepLink?.call(payload);
          }
        },
      );

      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.requestNotificationsPermission();
      await androidPlugin?.createNotificationChannel(
        const AndroidNotificationChannel(
          _channelId,
          _channelName,
          description: _channelDesc,
          importance: Importance.high,
        ),
      );

      _localReady = true;
      debugPrint('PushNotificationService: local notifications ready.');
    } catch (e) {
      debugPrint('PushNotificationService: local init failed: $e');
      _localReady = false;
    }
  }

  Future<void> _initFcmStub() async {
    if (!_enableFcm) {
      debugPrint(
        'PushNotificationService: FCM stub '
        '(add Firebase configs + --dart-define=ENABLE_FCM=true).',
      );
      return;
    }

    final hasAndroidConfig = await _assetOrFileExists(
      'android/app/google-services.json',
    );
    final hasIosConfig = await _assetOrFileExists(
      'ios/Runner/GoogleService-Info.plist',
    );
    if (!hasAndroidConfig && !hasIosConfig) {
      debugPrint(
        'PushNotificationService: ENABLE_FCM set but no Firebase config '
        'files found — FCM stays stub.',
      );
      return;
    }

    debugPrint(
      'PushNotificationService: Firebase configs detected. Add '
      'firebase_core + firebase_messaging and call Firebase.initializeApp '
      'here to complete FCM.',
    );
    _fcmReady = false;
  }

  Future<String?> getToken() async => null;

  /// Simulate an incoming push for QA of deep-link handling.
  void debugInject(String link) {
    debugPrint('PushNotificationService.debugInject: $link');
    onDeepLink?.call(link);
  }

  /// Cancel prior task reminders and schedule new ones at
  /// `scheduledAt - leadMinutes`. Shows immediately if already within window.
  Future<void> scheduleTaskLeadReminders({
    required List<LoTaskDto> tasks,
    required int leadMinutes,
  }) async {
    if (!_localReady) return;
    try {
      await _plugin.cancelAll();
    } catch (_) {}

    final now = tz.TZDateTime.now(tz.local);
    var id = 1000;
    for (final t in tasks) {
      final status = (t.statusCode ?? '').toUpperCase();
      if (status.contains('COMPLETE') || status.contains('CANCEL')) continue;
      final scheduled = _parseTaskDateTime(t.scheduledDate, t.scheduledTime);
      if (scheduled == null) continue;

      final fireAt = scheduled.subtract(Duration(minutes: leadMinutes));
      final title = 'Upcoming task';
      final body =
          '${t.taskTitle ?? 'Task'} · ${t.delegateName ?? 'delegate'} '
          'at ${t.scheduledDate ?? ''} ${t.scheduledTime ?? ''}'.trim();
      final payload = 'task:${t.id ?? id}';

      if (fireAt.isBefore(now)) {
        if (scheduled.isAfter(now)) {
          await _showNow(id: id, title: title, body: body, payload: payload);
        }
      } else {
        await _schedule(
          id: id,
          when: fireAt,
          title: title,
          body: body,
          payload: payload,
        );
      }
      id++;
    }
  }

  Future<void> _showNow({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    await _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: payload,
    );
  }

  Future<void> _schedule({
    required int id,
    required tz.TZDateTime when,
    required String title,
    required String body,
    String? payload,
  }) async {
    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: when,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: payload,
    );
  }

  tz.TZDateTime? _parseTaskDateTime(String? date, String? time) {
    final d = (date ?? '').trim();
    if (d.isEmpty) return null;
    final t = (time ?? '09:00').trim();
    final parsed = DateTime.tryParse('${d}T$t');
    if (parsed == null) return null;
    return tz.TZDateTime.from(parsed, tz.local);
  }

  Future<bool> _assetOrFileExists(String relativePath) async {
    try {
      final file = File(relativePath);
      if (await file.exists()) return true;
    } catch (_) {}
    try {
      await rootBundle.load(relativePath);
      return true;
    } catch (_) {
      return false;
    }
  }
}
