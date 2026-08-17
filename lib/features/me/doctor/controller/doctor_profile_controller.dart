import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/me/doctor/model/doctor_certificate_model.dart';
import 'package:BlueEra/features/me/doctor/model/doctor_profile_model.dart';
import 'package:BlueEra/features/me/doctor/repo/doctor_profile_repo.dart';
import 'package:get/get.dart';

/// Single source of truth for the standalone doctor's professional profile.
///
/// The dashboard loads it once; every tab reads from here rather than calling
/// `GET /doctors/me` again. Writes return the updated document, so state is
/// updated in place instead of re-fetching.
class DoctorProfileController extends GetxController {
  final DoctorProfileRepo _repo = DoctorProfileRepo();

  final Rxn<DoctorProfile> profile = Rxn<DoctorProfile>();

  /// Mirrors the API's own `hasProfile` flag. `GET /doctors/me` answers 200
  /// with `data: null, hasProfile: false` when the doctor has registered but
  /// not completed their profile — that is a normal state, never an error.
  final RxBool hasProfile = false.obs;

  final RxBool isLoading = false.obs;
  final RxBool isSaving = false.obs;

  /// Set only when the fetch itself failed (network/5xx), so the dashboard can
  /// show a retry. `hasProfile == false` does NOT populate this.
  final RxString loadError = ''.obs;

  /// Flips true once the first fetch settles, so the UI can tell
  /// "still loading" from "loaded, and there is no profile".
  final RxBool isReady = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchProfile();
  }

  List<DoctorCertificate> get certificates => profile.value?.certificates ?? const [];

  /// True once every field the redesigned doctor card needs is filled in — see
  /// [DoctorProfile.cardRequiredKeys]. The dashboard gates its tabs on this,
  /// so it reads the observables directly and must be called inside an [Obx].
  bool get isCardProfileComplete =>
      hasProfile.value && (profile.value?.hasCardEssentials ?? false);

  /// The card fields still to be collected. A doctor with no profile at all is
  /// missing all of them, so the gate form starts blank rather than empty.
  List<String> get missingCardFields => hasProfile.value
      ? (profile.value?.missingCardFields ?? DoctorProfile.cardRequiredKeys)
      : DoctorProfile.cardRequiredKeys;

  /// True when the first fetch failed outright. The gate must NOT be shown in
  /// this state: a network error is not "no profile", and posting a create on
  /// top of an existing profile yields `400 "User already has a doctor
  /// profile"`.
  bool get hasLoadFailure => loadError.value.isNotEmpty && profile.value == null;

  /// `GET /doctors/me`. Safe to auto-retry, so pull-to-refresh just calls it.
  Future<void> fetchProfile() async {
    isLoading.value = true;
    loadError.value = '';
    try {
      final ResponseModel response = await _repo.getMyProfile();
      if (!response.isSuccess) {
        loadError.value = response.message?.toString() ??
            AppStrings.somethingWentWrong.tr;
        return;
      }
      _applyProfileResponse(response);
    } on Exception catch (e) {
      loadError.value = '${AppStrings.errorFetchingData.tr}: $e';
    } finally {
      isLoading.value = false;
      isReady.value = true;
    }
  }

  /// Reads the `hasProfile` flag alongside `data`. The flag is a sibling of
  /// `data` in the envelope, so it comes from `getExtraData`, not `data`.
  void _applyProfileResponse(ResponseModel response) {
    final flag = response.getExtraData('hasProfile');
    final data = response.data;
    if (data is Map) {
      profile.value = DoctorProfile.fromJson(Map<String, dynamic>.from(data));
      hasProfile.value = flag is bool ? flag : true;
    } else {
      profile.value = null;
      hasProfile.value = flag is bool ? flag : false;
    }
  }

  /// Creates or updates depending on [hasProfile] — calling the wrong one
  /// yields `400 "User already has a doctor profile"` or a 404.
  ///
  /// [body] must contain ONLY the keys being written: `PUT` is partial, and
  /// sending `"degree": []` clears the list rather than leaving it alone.
  ///
  /// Returns true on success so the caller can pop back.
  Future<bool> saveProfile(Map<String, dynamic> body) async {
    isSaving.value = true;
    try {
      final ResponseModel response = hasProfile.value
          ? await _repo.updateProfile(body: body)
          : await _repo.createProfile(body: body);

      if (!response.isSuccess) {
        // The server message is the useful one here (field-level validation),
        // so surface it verbatim rather than a generic failure.
        commonSnackBar(
          message: response.message?.toString() ??
              AppStrings.somethingWentWrong.tr,
        );
        return false;
      }

      final data = response.data;
      if (data is Map) {
        final updated =
            DoctorProfile.fromJson(Map<String, dynamic>.from(data));
        // Create/update responses carry the profile WITHOUT certificates —
        // keep the ones already loaded so the Overview section doesn't blank
        // out after an edit.
        profile.value = updated.certificates.isEmpty
            ? updated.copyWith(certificates: certificates)
            : updated;
        hasProfile.value = true;
      }
      commonSnackBar(message: AppStrings.genericSavedSuccess.tr);
      return true;
    } on Exception {
      commonSnackBar(message: AppStrings.somethingWentWrong.tr);
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  /// Convenience wrapper for the Overview tab's expertise editor — a partial
  /// update touching only `expertise`.
  ///
  /// Refuses an empty list: `expertise` is the card's Services checklist and
  /// one of [DoctorProfile.cardRequiredKeys], so clearing it here would bounce
  /// the doctor straight back out to the mandatory-details gate.
  Future<bool> saveExpertise(List<String> expertise) {
    if (expertise.isEmpty) {
      commonSnackBar(message: AppStrings.doctorServicesRequired.tr);
      return Future.value(false);
    }
    return saveProfile({'expertise': expertise});
  }

  /// `DELETE /doctors/me` — removes the profile and every certificate.
  /// The caller is responsible for confirming first.
  Future<bool> deleteProfile() async {
    isSaving.value = true;
    try {
      final response = await _repo.deleteProfile();
      if (!response.isSuccess) {
        commonSnackBar(
          message: response.message?.toString() ??
              AppStrings.somethingWentWrong.tr,
        );
        return false;
      }
      profile.value = null;
      hasProfile.value = false;
      commonSnackBar(
        message: response.message?.toString() ?? AppStrings.successful.tr,
      );
      return true;
    } on Exception {
      commonSnackBar(message: AppStrings.somethingWentWrong.tr);
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  /// Replaces the cached certificate list after the certificates screen adds,
  /// edits or deletes one — keeps Overview in sync without a profile refetch.
  void setCertificates(List<DoctorCertificate> list) {
    final current = profile.value;
    if (current == null) return;
    profile.value = current.copyWith(certificates: list);
  }
}
