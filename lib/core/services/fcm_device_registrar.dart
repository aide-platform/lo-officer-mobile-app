import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:liaison_officer/core/config/api_config.dart';
import 'package:liaison_officer/core/network/dio_provider.dart';
import 'package:liaison_officer/core/services/push_notification_service.dart';
import 'package:liaison_officer/core/session/session_store.dart';

/// Sends the device FCM token to CAP after login and on token refresh.
///
/// CAP stores the token and sends pushes with the Firebase Admin SDK.
/// A missing endpoint (404) is logged; inbox and local reminders still work.
class FcmDeviceRegistrar {
  FcmDeviceRegistrar._();

  static Future<void> registerIfSignedIn() async {
    final session = SessionStore.current;
    if (session == null || !session.isValid) return;
    if (!PushNotificationService.instance.isFcmEnabled) return;

    final token = await PushNotificationService.instance.getToken();
    if (token == null || token.isEmpty) return;
    if (kDebugMode) {
      debugPrint('FcmDeviceRegistrar: fcmToken $token');
    }

    final platform = switch (defaultTargetPlatform) {
      TargetPlatform.iOS => 'ios',
      TargetPlatform.android => 'android',
      _ => 'android',
    };

    try {
      await createDio().post(
        ApiConfig.devicesRegisterPath,
        data: {
          'email': session.email,
          'fcmToken': token,
          'platform': platform,
        },
      );
      debugPrint('FcmDeviceRegistrar: token registered for ${session.email}.');
    } on DioException catch (e) {
      debugPrint(
        'FcmDeviceRegistrar: register skipped '
        '(${e.response?.statusCode ?? e.type}): ${e.message}',
      );
    } catch (e) {
      debugPrint('FcmDeviceRegistrar: register skipped: $e');
    }
  }
}
