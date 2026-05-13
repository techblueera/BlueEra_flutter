/// All `auth-service/*` endpoint constants used by the app.
///
/// Mixed into [BaseService] alongside the other per-service API mixins.
/// Constants are copied verbatim from the original `base_service.dart`.
///
/// Companion: `lib/docs/api-services-index.md`.
mixin AuthServiceApi {
  /// ----------------- API URL END DEVICE-----------------------
  final String sentOtp = 'auth-service/sent-otp';
  final String verifyOtp = 'auth-service/verify-otp';
}
