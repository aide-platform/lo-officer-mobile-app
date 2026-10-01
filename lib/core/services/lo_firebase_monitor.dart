import 'package:dio/dio.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/foundation.dart';
import 'package:liaison_officer/core/services/lo_monitoring_events.dart';

/// Crashlytics, Analytics, and Performance after [Firebase.initializeApp].
///
/// Started only from the FCM path, which already requires `ENABLE_FCM=true`.
class LoFirebaseMonitor {
  LoFirebaseMonitor._();
  static final LoFirebaseMonitor instance = LoFirebaseMonitor._();

  static const _crashlyticsTest = bool.fromEnvironment(
    'CRASHLYTICS_TEST',
    defaultValue: false,
  );

  bool _ready = false;
  bool get isReady => _ready;

  Future<void> start() async {
    if (_ready) return;
    try {
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
      FlutterError.onError =
          FirebaseCrashlytics.instance.recordFlutterFatalError;
      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };
      await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(true);
      await FirebasePerformance.instance.setPerformanceCollectionEnabled(true);
      _ready = true;
      debugPrint('LoFirebaseMonitor: Crashlytics, Analytics, Performance on.');
      if (kDebugMode && _crashlyticsTest) {
        FirebaseCrashlytics.instance.crash();
      }
    } catch (e) {
      _ready = false;
      debugPrint('LoFirebaseMonitor: start skipped: $e');
    }
  }

  void logLogin(String method) {
    if (method != LoMonitoringEvents.loginOtp &&
        method != LoMonitoringEvents.loginPassword) {
      return;
    }
    _log(LoMonitoringEvents.login, {'method': method});
  }

  void logTab(String tab) {
    if (tab != LoMonitoringEvents.tabDelegates &&
        tab != LoMonitoringEvents.tabTasks &&
        tab != LoMonitoringEvents.tabProfile &&
        tab != LoMonitoringEvents.tabHelplines &&
        tab != LoMonitoringEvents.tabAlerts) {
      return;
    }
    _log(LoMonitoringEvents.tabOpen, {'tab': tab});
  }

  void logFeature(String name) {
    if (!LoMonitoringEvents.isAllowedFeature(name)) return;
    _log(LoMonitoringEvents.feature, {'name': name});
  }

  void logNotificationOpen(String link) {
    final target = LoMonitoringEvents.notificationTarget(link);
    if (target == null) return;
    _log(LoMonitoringEvents.notificationOpen, {'target': target});
  }

  void _log(String name, Map<String, String> parameters) {
    if (!_ready) return;
    FirebaseAnalytics.instance.logEvent(name: name, parameters: parameters);
  }
}

/// Times portal HTTP calls. The metric URL has no query string or body.
class LoHttpPerformanceInterceptor extends Interceptor {
  static const _extraKey = 'loHttpMetric';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (!LoFirebaseMonitor.instance.isReady) {
      handler.next(options);
      return;
    }
    try {
      final metric = FirebasePerformance.instance.newHttpMetric(
        LoMonitoringEvents.httpMetricUrl(options.uri),
        _method(options.method),
      );
      options.extra[_extraKey] = metric;
      metric.start();
    } catch (e) {
      debugPrint('LoHttpPerformanceInterceptor: start skipped: $e');
    }
    handler.next(options);
  }

  @override
  void onResponse(Response<dynamic> response, ResponseInterceptorHandler handler) {
    _stop(response.requestOptions, response.statusCode);
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _stop(err.requestOptions, err.response?.statusCode);
    handler.next(err);
  }

  void _stop(RequestOptions options, int? statusCode) {
    final metric = options.extra.remove(_extraKey);
    if (metric is! HttpMetric) return;
    try {
      if (statusCode != null) metric.httpResponseCode = statusCode;
      metric.stop();
    } catch (e) {
      debugPrint('LoHttpPerformanceInterceptor: stop skipped: $e');
    }
  }

  HttpMethod _method(String method) {
    return switch (method.toUpperCase()) {
      'POST' => HttpMethod.Post,
      'PUT' => HttpMethod.Put,
      'DELETE' => HttpMethod.Delete,
      'PATCH' => HttpMethod.Patch,
      'HEAD' => HttpMethod.Head,
      'OPTIONS' => HttpMethod.Options,
      'TRACE' => HttpMethod.Trace,
      'CONNECT' => HttpMethod.Connect,
      _ => HttpMethod.Get,
    };
  }
}
