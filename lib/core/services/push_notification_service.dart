import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:liaison_officer/features/liaison_officer/data/models/cap/cap_models.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Background isolate entry. Notification payloads are shown by the OS.
@pragma('vm:entry-point')
Future<void> loFirebaseBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

/// Push + local notification facade.
///
/// - Always schedules **local** task lead-time reminders via
///   `flutter_local_notifications` (no Firebase required).
/// - Remote FCM starts when `--dart-define=ENABLE_FCM=true` and
///   `android/app/google-services.json` was present at build time.
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
  static const _pushChannelId = 'lo_push';
  static const _pushChannelName = 'Alerts';
  static const _pushChannelDesc = 'Schedule, task, and meeting alerts';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  void Function(String link)? onDeepLink;
  void Function(String token)? onToken;
  String? pendingDeepLink;
  bool _fcmReady = false;
  bool _localReady = false;
  String? _token;
  StreamSubscription<String>? _tokenSub;

  bool get isFcmEnabled => _enableFcm && _fcmReady;
  bool get isLocalReady => _localReady;

  Future<void> initialize() async {
    await _initLocal();
    await _initFcm();
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
            _dispatchLink(payload);
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
      await androidPlugin?.createNotificationChannel(
        const AndroidNotificationChannel(
          _pushChannelId,
          _pushChannelName,
          description: _pushChannelDesc,
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

  Future<void> _initFcm() async {
    if (!_enableFcm) {
      debugPrint(
        'PushNotificationService: FCM off. '
        'Build with --dart-define=ENABLE_FCM=true after adding '
        'android/app/google-services.json.',
      );
      return;
    }

    try {
      FirebaseMessaging.onBackgroundMessage(loFirebaseBackgroundHandler);
      await Firebase.initializeApp();
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(alert: true, badge: true, sound: true);
      await messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      FirebaseMessaging.onMessage.listen(_onForegroundMessage);
      FirebaseMessaging.onMessageOpenedApp.listen((message) {
        final link = _linkOf(message);
        if (link != null) _dispatchLink(link);
      });
      final initial = await messaging.getInitialMessage();
      final initialLink = initial == null ? null : _linkOf(initial);
      if (initialLink != null) _dispatchLink(initialLink);

      _token = await messaging.getToken();
      await _tokenSub?.cancel();
      _tokenSub = messaging.onTokenRefresh.listen((token) {
        _token = token;
        onToken?.call(token);
      });
      _fcmReady = true;
      if (_token != null && _token!.isNotEmpty) {
        onToken?.call(_token!);
      }
      debugPrint('PushNotificationService: FCM ready.');
    } catch (e) {
      _fcmReady = false;
      _token = null;
      debugPrint(
        'PushNotificationService: FCM init failed '
        '(missing google-services.json at build time?): $e',
      );
    }
  }

  Future<String?> getToken() async {
    if (_token != null && _token!.isNotEmpty) return _token;
    if (!_fcmReady) return null;
    try {
      _token = await FirebaseMessaging.instance.getToken();
    } catch (e) {
      debugPrint('PushNotificationService: getToken failed: $e');
    }
    return _token;
  }

  /// Drops the in-memory token. The device token on CAP is left as-is.
  void clearCachedToken() {
    _token = null;
  }

  void _onForegroundMessage(RemoteMessage message) {
    final link = _linkOf(message);
    final title = message.notification?.title ??
        message.data['title']?.toString() ??
        'Liaison Officer';
    final body = message.notification?.body ??
        message.data['body']?.toString() ??
        '';
    final id = DateTime.now().millisecondsSinceEpoch.remainder(100000);
    _showNow(
      id: id,
      title: title,
      body: body,
      payload: link,
      channelId: _pushChannelId,
      channelName: _pushChannelName,
      channelDesc: _pushChannelDesc,
    );
  }

  String? _linkOf(RemoteMessage message) {
    final link = message.data['link']?.toString().trim();
    if (link == null || link.isEmpty) return null;
    return link;
  }

  void _dispatchLink(String link) {
    final handler = onDeepLink;
    if (handler != null) {
      handler(link);
    } else {
      pendingDeepLink = link;
    }
  }

  /// Shell binds this after login so a tap can switch Delegates / Tasks.
  void bindDeepLink(void Function(String link)? handler) {
    onDeepLink = handler;
    final pending = pendingDeepLink;
    if (handler != null && pending != null && pending.isNotEmpty) {
      pendingDeepLink = null;
      handler(pending);
    }
  }

  /// Simulate an incoming push for QA of deep-link handling.
  void debugInject(String link) {
    debugPrint('PushNotificationService.debugInject: $link');
    _dispatchLink(link);
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
    String channelId = _channelId,
    String channelName = _channelName,
    String channelDesc = _channelDesc,
  }) async {
    await _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          channelDescription: channelDesc,
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
}
