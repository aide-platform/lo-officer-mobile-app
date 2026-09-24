/// Committee Automation Portal (CAP) API configuration.
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

  // ── Session / me ─────────────────────────────────────────────
  static const String mePath = '/app/me';

  // ── My LO portal ─────────────────────────────────────────────
  static const String myLoMePath = '/app/my-lo/me';
  static const String myLoDelegatesPath = '/app/my-lo/me/delegates';
  static const String myLoTasksPath = '/app/my-lo/me/tasks';
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

  // ── Org representative ───────────────────────────────────────
  static const String myOrganisationPath = '/app/my-organisation/me';
  static const String myOrganisationLosPath = '/app/my-organisation/me/los';
  static const String myOrganisationImportTemplatePath =
      '/app/my-organisation/me/los/import-template';
  static const String myOrganisationBulkImportPath =
      '/app/my-organisation/me/los/bulk-import';
  static String myOrganisationLoReminderPath(String loId) =>
      '/app/my-organisation/me/los/$loId/reminder';
  static String myOrganisationLoReNominatePath(String rejectedLoId) =>
      '/app/my-organisation/me/los/$rejectedLoId/re-nominate';
  static const String myOrganisationPendingRemindersPath =
      '/app/my-organisation/me/reminders/pending';
  static const String orgSubNodalOfficersPath = '/app/org-sub-nodal-officers';
  static const String orgSubNodalOfficersMinePath =
      '/app/org-sub-nodal-officers/mine';

  // ── Nodal / committee LO module ──────────────────────────────
  static const String loOrgTypesPath = '/app/lo-org-types';
  static const String loOrganisationsPath = '/app/lo-organisations';
  static const String liaisonOfficersPath = '/app/liaison-officers';
  static String liaisonOfficerReminderPath(String id) =>
      '$liaisonOfficersPath/$id/reminder';
  static const String liaisonOfficersPendingRemindersPath =
      '$liaisonOfficersPath/reminders/pending';
  static String liaisonOfficerActivePath(String id) =>
      '$liaisonOfficersPath/$id/active';
  static String filePath(String id) => '/app/files/$id';
  static const String loAssignmentsPath = '/app/lo-assignments';
  static const String loAssignmentDelegatesPath =
      '/app/lo-assignments/delegates';
  static String loAssignmentDelegateProfilePath(
    String attendeeType,
    String attendeeId,
  ) =>
      '/app/lo-assignments/delegates/$attendeeType/$attendeeId/profile';
  static const String loTasksPath = '/app/lo-tasks';
  static const String loActivitiesPath = '/app/lo-activities';
  static const String emailTemplatesPath = '/app/email-templates';
  static const String doLetterTemplatesPath = '/app/do-letter-templates';
  static String doLetterTemplateFilePath(String id) =>
      '/app/do-letter-templates/$id/file';
  static const String bvQuotaMinePath = '/app/committee/bv-quota/mine';
  static const String bvQuotaAssignBadgePath =
      '/app/committee/bv-quota/assign-badge';
  static String bvQuotaBadgeDownloadPath(String passId) =>
      '/app/committee/bv-quota/badge/$passId/download';

  /// Speculative LO-org DO letter paths (not in public OpenAPI — graceful 404).
  static String loOrgDoLetterPreviewPath(String orgId) =>
      '/app/lo-organisations/$orgId/do-letter/preview';
  static String loOrgDoLetterSignedPath(String orgId) =>
      '/app/lo-organisations/$orgId/do-letter/signed';
  static String loOrgSendNominationPath(String orgId) =>
      '/app/lo-organisations/$orgId/send-nomination';

  // ── Notifications (in-app feed) ──────────────────────────────
  static const String notificationsMinePath = '/app/notifications/mine';
  static String notificationReadPath(String id) =>
      '/app/notifications/mine/$id/read';
  static const String notificationsReadAllPath =
      '/app/notifications/mine/read-all';
  static const String notificationsUnreadCountPath =
      '/app/notifications/mine/unread-count';

  // ── Catering requirements ────────────────────────────────────
  static const String cateringReqsPath = '/app/catering-reqs';
  static const String cateringReqsMinePath = '/app/catering-reqs/mine';
  static const String cateringReqsPendingPath = '/app/catering-reqs/pending';
  static const String cateringReqsCommitteeRecipientsPath =
      '/app/catering-reqs/my-committee-recipients';
  static String cateringReqPath(String id) => '/app/catering-reqs/$id';
  static String cateringReqApprovePath(String id) =>
      '/app/catering-reqs/$id/approve';
  static String cateringReqRejectPath(String id) =>
      '/app/catering-reqs/$id/reject';

  // ── E-Coupons ────────────────────────────────────────────────
  static const String ecouponsPath = '/app/ecoupons';
  static const String ecouponsMinePath = '/app/ecoupons/mine';
  static const String ecouponsForMyCommitteePath =
      '/app/ecoupons/for-my-committee';
  static const String ecouponsForMyCommitteePdfPath =
      '/app/ecoupons/for-my-committee/pdf';
  static const String ecouponsMyPdfPath = '/app/ecoupons/my/pdf';
  static const String ecouponsDistributePath = '/app/ecoupons/distribute';
  static String ecouponPath(String id) => '/app/ecoupons/$id';
  static String ecouponPdfPath(String id) => '/app/ecoupons/$id/pdf';
  static String ecouponsDistributeByReqPath(String cateringReqId) =>
      '/app/ecoupons/distribute/$cateringReqId';

  /// Aliases kept for older call sites / hot-reload stability.
  static const String ecouponsForCommitteePath = ecouponsForMyCommitteePath;
  static const String ecouponsForCommitteePdfPath =
      ecouponsForMyCommitteePdfPath;
  static String ecouponsDistributeForReqPath(String cateringReqId) =>
      ecouponsDistributeByReqPath(cateringReqId);
}
