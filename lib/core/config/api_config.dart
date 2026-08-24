/// App-wide API configuration for a future real backend.
///
/// The app currently uses **local mock data only**:
/// - [MockAuthRepository] for login
/// - [MockLoRepository] / [DummyData] for VIPs
///
/// Dio repositories remain available for when a real API exists.
/// Then wire AuthBloc/LoBloc to Dio* repositories and set:
/// `--dart-define=USE_MOCK_API=false --dart-define=API_BASE_URL=https://your.api`
class ApiConfig {
  ApiConfig._();

  /// When true, Dio interceptors short-circuit (unused while blocs use mock repos).
  static const bool useMockApi = bool.fromEnvironment(
    'USE_MOCK_API',
    defaultValue: true,
  );

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.liaison-officer.local',
  );

  static const Duration connectTimeout = Duration(seconds: 20);
  static const Duration receiveTimeout = Duration(seconds: 20);

  static const String loginPath = '/api/auth/signin';
  static const String sendOtpPath = '/api/auth/send-otp';
  static const String verifyOtpPath = '/api/auth/verify-otp';
  static const String loVipsPath = '/api/lo/vips';
}
