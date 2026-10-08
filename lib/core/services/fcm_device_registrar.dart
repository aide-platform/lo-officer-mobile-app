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

  /// Set for the logout window so a Firebase token refresh cannot
  /// re-register the officer who is signing out.
  static bool _registerSuspended = false;

  static void resumeRegister() {
    _registerSuspended = false;
  }

  static Future<void> registerIfSignedIn() async {
    if (_registerSuspended) return;
    final session = SessionStore.current;
    if (session == null || !session.isValid) return;
    if (!PushNotificationService.instance.isFcmEnabled) return;

    final token = await PushNotificationService.instance.getToken();
    if (token == null || token.isEmpty) return;
    if (kDebugMode) {
      debugPrint('FcmDeviceRegistrar: fcmToken $token');
    }

    try {
      await createDio().post(
        ApiConfig.devicesRegisterPath,
        data: _tokenBody(session.email, token),
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

  /// Tells the portal to drop this device, then invalidates the Firebase token.
  /// Must run while [SessionStore.current] still has a Bearer token.
  /// A missing route (404) is logged; logout still continues.
  static Future<void> unregisterIfSignedIn() async {
    final session = SessionStore.current;
    if (session == null || !session.isValid) return;
    if (!PushNotificationService.instance.isFcmEnabled) return;

    _registerSuspended = true;
    final token = await PushNotificationService.instance.getToken();
    if (token != null && token.isNotEmpty) {
      try {
        await createDio().post(
          ApiConfig.devicesUnregisterPath,
          data: _tokenBody(session.email, token),
        );
        debugPrint(
          'FcmDeviceRegistrar: token unregistered for ${session.email}.',
        );
      } on DioException catch (e) {
        debugPrint(
          'FcmDeviceRegistrar: unregister skipped '
          '(${e.response?.statusCode ?? e.type}): ${e.message}',
        );
      } catch (e) {
        debugPrint('FcmDeviceRegistrar: unregister skipped: $e');
      }
    }
    await PushNotificationService.instance.deleteDeviceToken();
  }

  static Map<String, String> _tokenBody(String email, String token) {
    final platform = switch (defaultTargetPlatform) {
      TargetPlatform.iOS => 'ios',
      TargetPlatform.android => 'android',
      _ => 'android',
    };
    return {
      'email': email,
      'fcmToken': token,
      'platform': platform,
    };
  }
}
