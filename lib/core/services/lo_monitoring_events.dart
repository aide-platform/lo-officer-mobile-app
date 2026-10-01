/// Event names and parameters sent to Firebase Analytics.
///
/// Values stay free of email, phone, token, and document numbers.
class LoMonitoringEvents {
  LoMonitoringEvents._();

  static const login = 'login';
  static const tabOpen = 'tab_open';
  static const notificationOpen = 'notification_open';

  static const feature = 'feature';

  static const tabDelegates = 'delegates';
  static const tabTasks = 'tasks';
  static const tabProfile = 'profile';
  static const tabHelplines = 'helplines';
  static const tabAlerts = 'alerts';

  static const featureDelegateDetail = 'delegate_detail';
  static const featureIssueReport = 'issue_report';
  static const featureTravelEditor = 'travel_editor';
  static const featureHelp = 'help';
  static const featureInbox = 'inbox';
  static const featureProfileSave = 'profile_save';
  static const featureTaskStatus = 'task_status';
  static const featureTravelUpdate = 'travel_update';
  static const featureMovement = 'movement';
  static const featureBadgeDownload = 'badge_download';
  static const featureDocumentUpload = 'document_upload';
  static const featureLogout = 'logout';
  static const featureHelplineCall = 'helpline_call';

  static const allowedFeatures = <String>{
    featureDelegateDetail,
    featureIssueReport,
    featureTravelEditor,
    featureHelp,
    featureInbox,
    featureProfileSave,
    featureTaskStatus,
    featureTravelUpdate,
    featureMovement,
    featureBadgeDownload,
    featureDocumentUpload,
    featureLogout,
    featureHelplineCall,
  };

  static final RegExp _emailLike = RegExp(r'@');
  static final RegExp _phoneLike = RegExp(r'^[+0-9][0-9 \-]{6,}$');

  /// True only for a known feature name. Emails and phone numbers are refused.
  static bool isAllowedFeature(String name) {
    if (_emailLike.hasMatch(name) || _phoneLike.hasMatch(name.trim())) {
      return false;
    }
    return allowedFeatures.contains(name);
  }

  static const loginOtp = 'otp';
  static const loginPassword = 'password';

  static const targetDelegate = 'delegate';
  static const targetTask = 'task';

  /// `delegate` or `task` when the link is one this app routes. Otherwise null.
  static String? notificationTarget(String link) {
    final lower = link.toLowerCase();
    if (lower.contains('task')) return targetTask;
    if (lower.contains('delegate')) return targetDelegate;
    return null;
  }

  /// URL for a Performance HTTP metric. Query and user info are omitted.
  static String httpMetricUrl(Uri uri) {
    final scheme = uri.scheme.isEmpty ? 'https' : uri.scheme;
    final host = uri.host;
    final port = uri.hasPort ? ':${uri.port}' : '';
    final path = uri.path.isEmpty ? '/' : uri.path;
    return '$scheme://$host$port$path';
  }
}
