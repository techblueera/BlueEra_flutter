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
  final String hospitalVisionMissionByHospital =
      'hospital-service/vision-mission/hospital/$hospitalIDGlobal';
  String hospitalVisionMissionById(String id) =>
      'hospital-service/vision-mission/$id';
  final String hospitalHistoryBase = 'hospital-service/history';
  final String hospitalHistoryGet =
      'hospital-service/history/hospital/$hospitalIDGlobal';
  String hospitalHistoryById(String id) => 'hospital-service/history/$id';

  /// Hospital Management (Doctors/Leadership)
  final String hospitalManagementBase = 'hospital-service/management';
  String hospitalManagementByHospital =
      'hospital-service/management/hospital/$hospitalIDGlobal';
  String hospitalManagementById(String id) => 'hospital-service/management/$id';

  /// Hospital Departments
  final String hospitalDepartmentsBase = 'hospital-service/departments';
  String hospitalDepartmentsByHospital =
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
  String emergencyCareByHospital =
      'hospital-service/emergency-care/hospital/$hospitalIDGlobal';
  String emergencyCareById =
      'hospital-service/emergency-care/status/$hospitalIDGlobal';

  /// Emergency Contact
  final String hospitalEmergencyContactBase =
      'hospital-service/emergency-contact';
  String hospitalEmergencyContactByHospital =
      'hospital-service/emergency-contact/hospital/$hospitalIDGlobal';

  /// Other Facilities
  final String otherFacilitiesBase = 'hospital-service/other-facilities';
  String otherFacilitiesByHospital =
      'hospital-service/other-facilities/hospital/$hospitalIDGlobal';
  String otherFacilitiesById(String id) =>
      'hospital-service/other-facilities/status/$hospitalIDGlobal';

  String hospitalUpdate = '/hospital-service/hospitals/';
  String hospitalContact = 'hospital-service/contact';
  String hospitalDepartmentContact = 'hospital-service/contact/';
  final String hospitalPhotos = 'hospital-service/gallery';
  final String hospitalRemovePhotos = 'hospital-service/gallery/';
  final String hospitalGetAllPhotos =
      'hospital-service/gallery/hospital/$hospitalIDGlobal';
}
