/// Committee Automation Portal (CAP) API configuration for Liaison Officer app.
///
/// Mirrors aide-ui's `serviceUrls.ts` so both clients traverse the same
/// gateway. `API_GATEWAY_URL` is the gateway root (ends with `/api`); each
/// microservice is a fixed sub-path on it. `API_BASE_URL` is kept as a legacy
/// override that pins the aide-service URL directly, in case someone wants
/// to short-circuit the gateway for local testing.
///
/// Override at build time with `--dart-define`:
///   USE_MOCK_API         — true/false (default true: in-memory mocks).
///   API_GATEWAY_URL      — gateway root (scheme + host[:port] + `/api`).
///   AIDE_SERVICE_URL     — overrides `${API_GATEWAY_URL}/aideservices`.
///   EVENT_SERVICE_URL    — overrides `${API_GATEWAY_URL}/eventservices`.
///   API_BASE_URL         — legacy alias for `AIDE_SERVICE_URL`.
///
/// Known values:
///   Local Spring Boot (host loopback):   http://localhost:8080
///   Local Spring Boot from Android emu:  http://10.0.2.2:8080
///   GCP gateway:                         https://aeroindia.evenuefy.com/api
///   GCP aide-service:                    https://aeroindia.evenuefy.com/api/aideservices
///   GCP event-services:                  https://aeroindia.evenuefy.com/api/eventservices
///
/// Convenience launch wrappers live in `scripts/run-*.ps1`.
class ApiConfig {
  ApiConfig._();

  /// When true, repositories use in-memory/mock implementations.
  /// Set `--dart-define=USE_MOCK_API=false` for live CAP.
  static const bool useMockApi = bool.fromEnvironment(
    'USE_MOCK_API',
    defaultValue: true,
  );

  /// Gateway root. Both aide-service and event-services sit under it.
  static const String apiGatewayUrl = String.fromEnvironment(
    'API_GATEWAY_URL',
    defaultValue: 'https://aeroindia.evenuefy.com/api',
  );

  /// Legacy single-service URL. Takes precedence over the gateway when set,
  /// so an older run config using `API_BASE_URL=http://localhost:8080` still
  /// works.
  static const String _legacyBaseUrl = String.fromEnvironment('API_BASE_URL');

  /// aide-service (CAP) base. `_legacyBaseUrl` wins when supplied.
  static String get baseUrl =>
      _legacyBaseUrl.isNotEmpty ? _legacyBaseUrl : aideServiceUrl;

  /// aide-service — all paths in this class resolve against it.
  static const String _aideServiceOverride = String.fromEnvironment(
    'AIDE_SERVICE_URL',
  );
  static String get aideServiceUrl => _aideServiceOverride.isNotEmpty
      ? _aideServiceOverride
      : '$apiGatewayUrl/aideservices';

  /// event-services — not called by any current LO repo. Kept here so a
  /// future module can route its Dio client through it without inventing a
  /// second config class.
  static const String _eventServiceOverride = String.fromEnvironment(
    'EVENT_SERVICE_URL',
  );
  static String get eventServiceUrl => _eventServiceOverride.isNotEmpty
      ? _eventServiceOverride
      : '$apiGatewayUrl/eventservices';

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

  /// Active helpline directory for the LO portal.
  /// Committed on aide-service `media-lo-changes`; 404 hides the card until deployed.
  static const String loHelpLinesActivePath = '/app/lo-help-lines/active';
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
  static const String lookupLanguagesPath = '/app/lookups/languages';
  static const String lookupGendersPath = '/app/lookups/genders';
  static const String myLoLanguagesPath = '/app/my-lo/me/languages';
  static String filePath(String fileId) => '/app/files/$fileId';
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

  /// Mobile FCM token registration. CAP sends via Firebase Admin SDK.
  /// Not in public OpenAPI yet — 404 is logged and ignored.
  static const String devicesRegisterPath = '/api/devices/register';

  /// Drops this device token for the signed-in officer. Same 404 behaviour
  /// as register: logout still finishes when the portal has no route yet.
  static const String devicesUnregisterPath = '/api/devices/unregister';
}
