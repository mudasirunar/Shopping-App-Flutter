/// Application and Backend API Constants
class ApiConstants {
  ApiConstants._();

  /// The deployed Vercel backend base URL
  static const String backendBaseUrl = 'https://shopping-app-flutter.vercel.app';

  /// Shared application security handshake token
  /// Blocks unauthorized public / bot calls to serverless endpoints
  static const String appSecurityToken = 'sh_sec_8f91a7c2b4e60d5e31a89f2c1b4d0e5f';

  /// Endpoints
  static const String sendResetOtpEndpoint = '/api/send-reset-otp';
  static const String verifyResetOtpEndpoint = '/api/verify-reset-otp';

  /// Default headers sent with requests to backend
  static Map<String, String> get authHeaders => {
        'Content-Type': 'application/json',
        'x-app-security-token': appSecurityToken,
      };
}
