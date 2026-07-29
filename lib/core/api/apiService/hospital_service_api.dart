import 'package:BlueEra/core/constants/shared_preference_utils.dart';

/// All `hospital-service/*` endpoint constants used by the app.
///
/// Mixed into [BaseService] alongside the other per-service API mixins.
///
/// Note: hospital-side emergency-care/contact endpoints live here. The
/// user-side `emergency-service/*` API is in `EmergencyServiceApi`, and
/// rider-side `emergency-contacts` is in `RiderServiceApi`.
mixin HospitalServiceApi {
  ///HOSPITAL NEW...
  final String aiCreateHospital = 'hospital-service/ai/create-hospital';
  final String userSelfHospital = 'hospital-service/hospitals/user/hospitals';
  final String hospitalVisionMissionBase = 'hospital-service/vision-mission';
  // Getter (not a field) so the current `hospitalIDGlobal` is read on every
  // access. A field initializer would freeze the global's value at the time
  // the mixin is constructed — which is often before the hospital id is loaded,
  // producing URLs like `.../hospital/` with a missing id (404).
  String get hospitalVisionMissionByHospital =>
      'hospital-service/vision-mission/hospital/$hospitalIDGlobal';
  String hospitalVisionMissionById(String id) =>
      'hospital-service/vision-mission/$id';
  final String hospitalHistoryBase = 'hospital-service/history';
  String get hospitalHistoryGet =>
      'hospital-service/history/hospital/$hospitalIDGlobal';
  String hospitalHistoryById(String id) => 'hospital-service/history/$id';

  /// Hospital Management (Doctors/Leadership)
  final String hospitalManagementBase = 'hospital-service/management';
  String get hospitalManagementByHospital =>
      'hospital-service/management/hospital/$hospitalIDGlobal';
  String hospitalManagementById(String id) => 'hospital-service/management/$id';

  /// Hospital Departments
  final String hospitalDepartmentsBase = 'hospital-service/departments';
  String get hospitalDepartmentsByHospital =>
      'hospital-service/departments/hospital/$hospitalIDGlobal';
  String hospitalDepartmentById(String id) =>
      'hospital-service/departments/$id';

  /// Hospital IPD
  final String hospitalIpdBase = 'hospital-service/ipd';
  String hospitalIpdByDepartment(String departmentId) =>
      'hospital-service/ipd/department/$departmentId';
  String hospitalIpdById(String id) => 'hospital-service/ipd/$id';

  /// Hospital OPD
  final String hospitalOpdBase = 'hospital-service/opd';
  String hospitalOpdByDepartment(String departmentId) =>
      'hospital-service/opd/department/$departmentId';
  String hospitalOpdById(String id) => 'hospital-service/opd/$id';

  /// Emergency & Critical Care
  final String emergencyCareBase = 'hospital-service/emergency-care';
  String get emergencyCareByHospital =>
      'hospital-service/emergency-care/hospital/$hospitalIDGlobal';
  String get emergencyCareById =>
      'hospital-service/emergency-care/status/$hospitalIDGlobal';

  /// Emergency Contact
  final String hospitalEmergencyContactBase =
      'hospital-service/emergency-contact';
  String get hospitalEmergencyContactByHospital =>
      'hospital-service/emergency-contact/hospital/$hospitalIDGlobal';

  /// Other Facilities
  final String otherFacilitiesBase = 'hospital-service/other-facilities';
  String get otherFacilitiesByHospital =>
      'hospital-service/other-facilities/hospital/$hospitalIDGlobal';
  String otherFacilitiesById(String id) =>
      'hospital-service/other-facilities/status/$hospitalIDGlobal';

  String hospitalUpdate = '/hospital-service/hospitals/';
  String hospitalContact = 'hospital-service/contact';
  String hospitalDepartmentContact = 'hospital-service/contact/';
  final String hospitalPhotos = 'hospital-service/gallery';
  final String hospitalRemovePhotos = 'hospital-service/gallery/';
  String get hospitalGetAllPhotos =>
      'hospital-service/gallery/hospital/$hospitalIDGlobal';

  /// Healthcare enquiry — HOSPITAL endpoint (be_hospital_service producer).
  /// `POST` raises an enquiry against a Hospital listing (creates the in-chat
  /// `healthcare_enquiry` card + emits `newHealthcareEnquiryReceived`); the
  /// `PUT` status lets the hospital owner accept / decline, emitting
  /// `healthcareEnquiryStatusUpdated`. Non-hospital categories use the
  /// `businessEnquiries` endpoint instead. See
  /// lib/docs/healthcare-enquiry-ui-integration.md.
  final String hospitalEnquiries = 'hospital-service/hospital-enquiries';
  String hospitalEnquiryStatus(String enquiryId) =>
      'hospital-service/hospital-enquiries/$enquiryId/status';

  /// GET one — used by the owner chat card to fetch the enquiry's true
  /// current status when the message metadata's local latch is empty.
  String hospitalEnquiryById(String enquiryId) =>
      'hospital-service/hospital-enquiries/$enquiryId';

  /// Hospital appointment (be_hospital_service producer).
  /// `POST` books an appointment with a specific doctor (opd_id) — creates
  /// the in-chat `healthcare_booking` card + emits
  /// `newHealthcareBookingReceived`. `PUT status` handles owner
  /// accept/decline AND buyer cancel (`cancelled` transition) — same
  /// pattern as the hotel booking. See
  /// `lib/docs/healthcare-appointment-ui-integration.md`.
  final String hospitalAppointments =
      'hospital-service/hospital-appointments';
  String hospitalAppointmentStatus(String appointmentId) =>
      'hospital-service/hospital-appointments/$appointmentId/status';

  /// GET one — used by the chat card to hydrate current status when the
  /// local metadata latch is empty (fresh login on a new device).
  String hospitalAppointmentById(String appointmentId) =>
      'hospital-service/hospital-appointments/$appointmentId';

  /// Customer outbox — appointments I sent (doc §3).
  final String hospitalAppointmentsMe =
      'hospital-service/hospital-appointments/me';

  /// Owner inbox — appointments on my hospital (doc §3).
  final String hospitalAppointmentsOwnerMe =
      'hospital-service/hospital-appointments/owner/me';

  // ───────────────────────────────────────────────────────────────────────
  // STANDALONE DOCTOR (docs/backend/STANDALONE_DOCTOR_FLUTTER_GUIDE.md)
  //
  // A standalone doctor is an INDEPENDENT business account (Healthcare →
  // DOCTORS/CLINICS) — not a row in a hospital's OPD list. These endpoints
  // are entirely separate from the `hospital-service/opd` +
  // `hospital-service/hospital-appointments` pair above, which continue to
  // serve the hospital OPD flow unchanged.
  // ───────────────────────────────────────────────────────────────────────

  /// Doctor professional profile. POST creates (goes live instantly — there
  /// is no approval step); `/me` reads/updates/deletes the caller's own.
  final String doctorsBase = 'hospital-service/doctors';
  final String doctorsMe = 'hospital-service/doctors/me';
  final String doctorsMeStats = 'hospital-service/doctors/me/stats';

  /// Public full profile for a patient viewing a doctor. Takes the OWNER's
  /// user id (`Business.user_id`) — not `Business._id`, not
  /// `DoctorProfile._id`. A 404 here is normal (profile not completed yet).
  String doctorsFullByUserId(String userId) =>
      'hospital-service/doctors/full/$userId';

  /// Basic public profile by `DoctorProfile._id` (no certificates).
  String doctorsById(String id) => 'hospital-service/doctors/$id';

  /// Certificates & Awards.
  final String doctorCertificatesBase = 'hospital-service/doctor-certificates';
  final String doctorCertificatesMe =
      'hospital-service/doctor-certificates/me';
  String doctorCertificateById(String id) =>
      'hospital-service/doctor-certificates/$id';
  String doctorCertificatesByProfile(String doctorProfileId) =>
      'hospital-service/doctor-certificates/doctor/$doctorProfileId';

  /// Appointments. NOTE: no `opd_id` — that field belongs to the hospital
  /// booking API. Ownership is derived server-side from the token.
  final String doctorAppointments = 'hospital-service/doctor-appointments';
  final String doctorAppointmentsMe =
      'hospital-service/doctor-appointments/me';

  /// Owner inbox — this backs the doctor dashboard's Booking tab.
  final String doctorAppointmentsOwnerMe =
      'hospital-service/doctor-appointments/owner/me';
  String doctorAppointmentById(String appointmentId) =>
      'hospital-service/doctor-appointments/$appointmentId';
  String doctorAppointmentStatus(String appointmentId) =>
      'hospital-service/doctor-appointments/$appointmentId/status';
}
