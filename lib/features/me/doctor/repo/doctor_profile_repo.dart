import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/base_service.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';

/// `hospital-service/doctors*` — the standalone doctor's professional profile.
///
/// Deliberately separate from `HospitalOpdRepo`: an OPD doctor is a row inside
/// a hospital, this is an independent business account.
class DoctorProfileRepo extends BaseService {
  /// `GET /doctors/me`. Returns `hasProfile` as a sibling of `data`, so the
  /// caller must read `getExtraData('hasProfile')` rather than treating a
  /// null `data` as an error — "no profile yet" is a 200.
  Future<ResponseModel> getMyProfile({bool showProgress = false}) async {
    return ApiBaseHelper().getHTTP(
      doctorsMe,
      showProgress: showProgress,
      onError: (_) {},
      onSuccess: (_) {},
    );
  }

  /// `POST /doctors`. Creating makes the doctor live immediately — there is
  /// no approval step. Never auto-retry: a silent retry after a timeout
  /// produces `400 "User already has a doctor profile"`.
  Future<ResponseModel> createProfile({
    required Map<String, dynamic> body,
  }) async {
    return ApiBaseHelper().postHTTP(
      doctorsBase,
      params: body,
      showProgress: false,
      onError: (_) {},
      onSuccess: (_) {},
    );
  }

  /// `PUT /doctors/me` — PARTIAL. Only the keys present are written; omit a
  /// key to leave it untouched. Sending `[]` clears a list.
  Future<ResponseModel> updateProfile({
    required Map<String, dynamic> body,
  }) async {
    return ApiBaseHelper().putHTTP(
      doctorsMe,
      params: body,
      showProgress: false,
      onError: (_) {},
      onSuccess: (_) {},
    );
  }

  /// `DELETE /doctors/me` — removes the profile AND every certificate.
  /// Appointments are kept so both sides retain their history.
  Future<ResponseModel> deleteProfile() async {
    return ApiBaseHelper().deleteHTTP(
      doctorsMe,
      showProgress: false,
      onError: (_) {},
      onSuccess: (_) {},
    );
  }

  /// `GET /doctors/me/stats` — booking analytics for the Statics tab.
  Future<ResponseModel> getMyStats() async {
    return ApiBaseHelper().getHTTP(
      doctorsMeStats,
      showProgress: false,
      onError: (_) {},
      onSuccess: (_) {},
    );
  }

  /// `GET /doctors/full/:userId` — public profile for a patient.
  /// [ownerUserId] is `Business.user_id`. A 404 is normal (profile not
  /// completed) and must not be surfaced as a page-level error.
  Future<ResponseModel> getPublicProfile({
    required String ownerUserId,
  }) async {
    return ApiBaseHelper().getHTTP(
      doctorsFullByUserId(ownerUserId),
      showProgress: false,
      onError: (_) {},
      onSuccess: (_) {},
    );
  }
}
