import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Push notification facade.
///
/// Real FCM requires `google-services.json` / `GoogleService-Info.plist` and
/// the Firebase packages. Until those configs ship with the app, this service:
/// - stays a safe no-op for token/registration
/// - still supports [debugInject] for deep-link QA
/// - optionally shows a local notification via platform channels when available
///
/// Enable live FCM later with:
/// `--dart-define=ENABLE_FCM=true` after adding Firebase config files and
/// `firebase_core` / `firebase_messaging` / `flutter_local_notifications`.
class PushNotificationService {
  PushNotificationService._();
  static final PushNotificationService instance = PushNotificationService._();

  static const _enableFcm = bool.fromEnvironment(
    'ENABLE_FCM',
    defaultValue: false,
  );

  void Function(String link)? onDeepLink;
  bool _fcmReady = false;

  bool get isFcmEnabled => _enableFcm && _fcmReady;

  Future<void> initialize() async {
    if (!_enableFcm) {
      debugPrint(
        'PushNotificationService: stub active '
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
        'files found — staying in stub mode.',
      );
      return;
    }

    // Firebase packages are wired when configs are present; until then keep
    // stub so release builds without google-services still compile.
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
