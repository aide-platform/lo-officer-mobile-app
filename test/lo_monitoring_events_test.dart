import 'package:flutter_test/flutter_test.dart';
import 'package:liaison_officer/core/services/lo_monitoring_events.dart';

void main() {
  test('event names stay free of personal fields', () {
    expect(LoMonitoringEvents.login, 'login');
    expect(LoMonitoringEvents.tabOpen, 'tab_open');
    expect(LoMonitoringEvents.notificationOpen, 'notification_open');
    expect(LoMonitoringEvents.tabDelegates, 'delegates');
    expect(LoMonitoringEvents.tabTasks, 'tasks');
    expect(LoMonitoringEvents.tabProfile, 'profile');
    expect(LoMonitoringEvents.tabHelplines, 'helplines');
    expect(LoMonitoringEvents.tabAlerts, 'alerts');
    expect(LoMonitoringEvents.feature, 'feature');
    expect(LoMonitoringEvents.loginOtp, 'otp');
    expect(LoMonitoringEvents.loginPassword, 'password');
  });

  test('notification target is delegate or task only', () {
    expect(
      LoMonitoringEvents.notificationTarget('delegate:ASN-2027-004521'),
      'delegate',
    );
    expect(
      LoMonitoringEvents.notificationTarget('aeroindia://delegates/DEL-1'),
      'delegate',
    );
    expect(LoMonitoringEvents.notificationTarget('task:42'), 'task');
    expect(LoMonitoringEvents.notificationTarget('profile'), isNull);
  });

  test('feature allowlist accepts officer actions and rejects personal values', () {
    expect(
      LoMonitoringEvents.isAllowedFeature(LoMonitoringEvents.featureDelegateDetail),
      isTrue,
    );
    expect(
      LoMonitoringEvents.isAllowedFeature(LoMonitoringEvents.featureProfileSave),
      isTrue,
    );
    expect(
      LoMonitoringEvents.isAllowedFeature(LoMonitoringEvents.featureHelplineCall),
      isTrue,
    );
    expect(
      LoMonitoringEvents.isAllowedFeature(LoMonitoringEvents.featureLogout),
      isTrue,
    );
    expect(LoMonitoringEvents.isAllowedFeature('officer@example.com'), isFalse);
    expect(LoMonitoringEvents.isAllowedFeature('+91 98765 43210'), isFalse);
    expect(LoMonitoringEvents.isAllowedFeature('unknown_screen'), isFalse);
  });

  test('http metric url drops query and user info', () {
    final uri = Uri.parse(
      'https://user:secret@34.47.128.151:6080/app/my-lo/me/delegates?token=abc',
    );
    expect(
      LoMonitoringEvents.httpMetricUrl(uri),
      'https://34.47.128.151:6080/app/my-lo/me/delegates',
    );
  });
}
