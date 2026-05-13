import 'package:BlueEra/core/constants/shared_preference_utils.dart';

/// All `emergency-service/*` endpoint constants used by the app.
///
/// Mixed into [BaseService] alongside the other per-service API mixins.
///
/// Note: `emergency-service/*` is the user-facing emergency profile API.
/// Hospital-side emergency contact/care endpoints live in
/// `HospitalServiceApi`; rider-side `emergencyContacts` lives in
/// `RiderServiceApi`.
mixin EmergencyServiceApi {
  /// Emergency Service (User)
  final String emergencyBasicInfo = 'emergency-service/basic-info';
  final String emergencyPrivacyAlerts = 'emergency-service/privacy-alerts';
  String get emergencyProfile => 'emergency-service/emergency-profile/$userId';
}
