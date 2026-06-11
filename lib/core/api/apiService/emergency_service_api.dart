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

  /// GET — emergency profile for an explicit profile id (e.g. opened from a
  /// scanned QR / `emergency.beapp.in/<id>` deep link, where the viewer is
  /// not necessarily the profile owner).
  String emergencyProfileById(String id) =>
      'emergency-service/emergency-profile/$id';

  /// PUT — update a single emergency contact by its id.
  String emergencyUpdateContact(String id) =>
      'emergency-service/emergency-contacts/$id';
}
