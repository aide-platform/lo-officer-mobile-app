/// Committee Automation Portal (CAP) API configuration for Liaison Officer app.
///
/// Override at build time:
/// `--dart-define=USE_MOCK_API=true`
/// `--dart-define=API_BASE_URL=http://35.244.48.209:8080`
class ApiConfig {
  ApiConfig._();

  /// When true, repositories use in-memory/mock implementations.
  /// Set `--dart-define=USE_MOCK_API=false` for live CAP.
  static const bool useMockApi = bool.fromEnvironment(
    'USE_MOCK_API',
    defaultValue: true,
  );

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://35.244.48.209:8080',
  );

  static const Duration connectTimeout = Duration(seconds: 25);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // ── Auth (CAPTCHA + Email OTP) ───────────────────────────────
  static const String checkEmailPath = '/api/auth/check-email';
  static const String captchaPath = '/api/auth/captcha';
  static const String requestOtpPath = '/api/auth/request-otp';
  static const String resendOtpPath = '/api/auth/resend-otp';
  static const String verifyOtpPath = '/api/auth/verify-otp';

  // ── My LO portal ─────────────────────────────────────────────
  static const String myLoMePath = '/app/my-lo/me';
  static const String myLoDelegatesPath = '/app/my-lo/me/delegates';
  static const String myLoTasksPath = '/app/my-lo/me/tasks';
  /// CAP issue create; unsynced reports queue in Hive until flush succeeds.
  static const String myLoIssuesPath = '/app/my-lo/me/issues';
  static String myLoTaskStatusPath(String taskId) =>
      '/app/my-lo/me/tasks/$taskId/status';
  static String myLoTravelPath(String assignmentId) =>
      '/app/my-lo/me/assignments/$assignmentId/travel';
  static String myLoArrivalFlightPath(String assignmentId) =>
      '/app/my-lo/me/assignments/$assignmentId/arrival-flight';
  static String myLoVehiclesPath(String assignmentId) =>
      '/app/my-lo/me/assignments/$assignmentId/vehicles';
  static String myLoNominationsPath(String assignmentId) =>
      '/app/my-lo/me/assignments/$assignmentId/nominations';
  static const String myLoExperiencesPath = '/app/my-lo/me/experiences';
  static String myLoExperiencePath(String id) =>
      '/app/my-lo/me/experiences/$id';
  static const String myLoLanguagesPath = '/app/my-lo/me/languages';
  static String myLoLanguagePath(String rowId) =>
      '/app/my-lo/me/languages/$rowId';
  static const String myLoPhotoPath = '/app/my-lo/me/photo';
  static const String myLoSignaturePath = '/app/my-lo/me/signature';
  static const String myLoOrgBadgeFrontPath = '/app/my-lo/me/org-badge-front';
  static const String myLoOrgBadgeBackPath = '/app/my-lo/me/org-badge-back';
  static const String myLoAadhaarFrontPath = '/app/my-lo/me/aadhaar-front';
  static const String myLoAadhaarBackPath = '/app/my-lo/me/aadhaar-back';

  /// LO profile badge PDF download.
  static String bvQuotaBadgeDownloadPath(String passId) =>
      '/app/committee/bv-quota/badge/$passId/download';

  // ── Notifications (in-app feed) ──────────────────────────────
  static const String notificationsMinePath = '/app/notifications/mine';
  static String notificationReadPath(String id) =>
      '/app/notifications/mine/$id/read';
  static const String notificationsReadAllPath =
      '/app/notifications/mine/read-all';
  static const String notificationsUnreadCountPath =
      '/app/notifications/mine/unread-count';
}
