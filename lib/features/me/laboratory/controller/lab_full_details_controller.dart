import 'dart:io';

import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/me/laboratory/model/new_lab_full_details_res_model.dart';
import 'package:BlueEra/features/me/laboratory/repo/lab_full_details_repo.dart';
import 'package:BlueEra/features/me/laboratory/repo/lab_profile_repo.dart';
import 'package:BlueEra/features/me/school/repo/upload_file_to_s3.dart';
import 'package:get/get.dart';

/// Top-level controller for the laboratory home screen. Holds the merged
/// `profile + tests + galleries + facility + health camps` payload and
/// handles the banner/logo upload flow used by [lab_header_view].
class LabFullDetailsController extends GetxController {
  final LabFullDetailsRepo _repo = LabFullDetailsRepo();
  final LabProfileRepo _repoProfile = LabProfileRepo();

  final RxBool isLoading = false.obs;
  final RxBool isSaving = false.obs;
  final Rxn<LabDetailsData> details = Rxn<LabDetailsData>();

  /// Flips to `true` once the first [fetchFullDetails] has settled, whatever
  /// the outcome. The dashboard's mandatory-details gate keys off this so it
  /// never mistakes "not fetched yet" for "nothing filled in".
  final RxBool isReady = false.obs;

  /// Populated only when a fetch genuinely failed (network / non-2xx). An
  /// empty-but-successful payload leaves this blank.
  final RxString loadError = ''.obs;

  /// True when the first fetch failed outright. The gate must show a retry in
  /// this state rather than the form: a transport error is not "profile
  /// incomplete", and saving over it would POST a create for a lab that may
  /// already exist.
  bool get hasLoadFailure => loadError.value.isNotEmpty && details.value == null;

  Future<void> fetchFullDetails() async {
    try {
      isLoading.value = true;
      final ResponseModel res = await _repo.getFullDetailsByUser();
      if (res.isSuccess) {
        loadError.value = '';
        details.value =
            LabFullDetailsResModel.fromJson(res.response?.data).data;
      } else {
        loadError.value =
            res.message?.toString() ?? AppStrings.somethingWentWrong.tr;
        logs("LabFullDetailsController.fetchFullDetails: ${res.message}");
      }
    } catch (e) {
      loadError.value = "${AppStrings.errorFetchingData.tr}: $e";
      logs("LabFullDetailsController.fetchFullDetails ERROR $e");
    } finally {
      isLoading.value = false;
      isReady.value = true;
    }
  }

  // ─────────────────────────────────────────────────────────────
  // Mandatory card details (docs/labnew.png)
  //
  // The redesigned listing card renders a cover photo, the lab type line,
  // a description, a test count and a facility count. A card missing any of
  // them reads as broken rather than sparse, so `LabHomeScreenV2` shows
  // `LabRequiredDetailsForm` INSTEAD of its tabs until all five exist —
  // the same shape as the doctor dashboard's gate.
  // ─────────────────────────────────────────────────────────────

  Profile? get profile => details.value?.profile;

  String get coverUrl => (profile?.coverUrl ?? '').trim();

  String get labType => (profile?.labType ?? '').trim();

  String get labDescription => (profile?.description ?? '').trim();

  int get testCount => details.value?.tests?.length ?? 0;

  /// Everything the card counts under "Facilities" — the core five, the
  /// payment/package flags and any custom entries the owner added.
  int get facilityCount => facilityCountOf(details.value?.facility);

  /// What the gate actually requires: at least one *core* facility or one
  /// custom entry. Deliberately the same test [LabFacilitiesTabV2] uses for
  /// its empty state, so the gate and the tab never disagree about whether
  /// the section is filled in.
  bool get hasRequiredFacilities {
    final f = details.value?.facility;
    if (f == null) return false;
    return f.wheelchairAssistance == true ||
        f.doctorConsultationTieUp == true ||
        f.insuranceCashlessSupport == true ||
        f.homeSampleCollection == true ||
        f.digitalReport == true ||
        (f.other?.isNotEmpty ?? false);
  }

  static int facilityCountOf(Facility? f) {
    if (f == null) return 0;
    var count = 0;
    if (f.wheelchairAssistance == true) count++;
    if (f.doctorConsultationTieUp == true) count++;
    if (f.insuranceCashlessSupport == true) count++;
    if (f.homeSampleCollection == true) count++;
    if (f.digitalReport == true) count++;
    if (f.creditCardPayment == true) count++;
    if (f.healthCheckupPkg == true) count++;
    if (f.upiOnline == true) count++;
    count += (f.other ?? [])
        .where((o) => (o.label ?? '').trim().isNotEmpty)
        .length;
    return count;
  }

  /// True once every field the redesigned card needs is filled in. Reads the
  /// observables directly, so call it inside an [Obx].
  ///
  /// [labTypeFallback] is the business sub-category name (what the hospital
  /// card renders in the same slot). It stands in for `labType` so a lab whose
  /// backend does not persist that field yet can still clear the gate — the
  /// form collects and sends the value either way.
  bool isCardProfileComplete({String labTypeFallback = ''}) =>
      coverUrl.isNotEmpty &&
      labDescription.isNotEmpty &&
      (labType.isNotEmpty || labTypeFallback.trim().isNotEmpty) &&
      testCount > 0 &&
      hasRequiredFacilities;

  /// Writes the card's profile-side fields in one call: uploads [coverFile]
  /// when the owner picked a new image, then creates or updates the lab
  /// profile. Only these keys are sent — the PUT is partial, so the About /
  /// contact fields other screens own stay untouched.
  Future<bool> saveRequiredDetails({
    File? coverFile,
    required String labType,
    required String description,
  }) async {
    try {
      isSaving.value = true;

      String? uploadedCoverUrl;
      if (coverFile != null) {
        final UploadResult result = await S3UploadService.uploadFile(coverFile);
        if (!result.isSuccess) {
          commonSnackBar(message: AppStrings.somethingWentWrong.tr);
          return false;
        }
        uploadedCoverUrl = result.url;
      }

      final payload = <String, dynamic>{
        'description': description,
        'labType': labType,
        if (uploadedCoverUrl != null) 'coverUrl': uploadedCoverUrl,
      };

      // `labIDGlobal` is the only reliable "a profile record exists" signal —
      // it is seeded from `profile._id` when the lab screen boots. Empty means
      // this is the first save, which has to be a create.
      final ResponseModel res = labIDGlobal.isNotEmpty
          ? await _repoProfile.putDescription(payload)
          : await _repoProfile.postDescription(payload);

      if (!res.isSuccess) {
        commonSnackBar(
          message: res.response?.data['message'] ??
              AppStrings.labFailedToSave.tr,
        );
        return false;
      }

      await _syncLabIdFrom(res);
      await fetchFullDetails();
      // Second chance at the id in case the create response didn't carry one —
      // the refetched profile always does. Facilities and tests are addressed
      // by lab id, so an empty global here would fail their next write.
      if (labIDGlobal.isEmpty && (profile?.id ?? '').isNotEmpty) {
        labIDGlobal = profile!.id!;
        await setLabID(labIDGlobal);
      }
      return true;
    } catch (e) {
      logs("LabFullDetailsController.saveRequiredDetails ERROR $e");
      commonSnackBar(message: AppStrings.somethingWentWrong.tr);
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  /// A create hands back the freshly minted profile — capture its id so every
  /// later write (facilities, tests, the PUT above) targets the right lab
  /// instead of re-creating one.
  Future<void> _syncLabIdFrom(ResponseModel res) async {
    if (labIDGlobal.isNotEmpty) return;
    final id = res.response?.data?['data']?['_id'];
    if (id is String && id.isNotEmpty) {
      // Assigned directly rather than round-tripping through secure storage:
      // `setLabID` does not await its write, so a read-back here can still see
      // the old (empty) value — and the facilities save that follows needs the
      // id immediately.
      labIDGlobal = id;
      await setLabID(id);
    }
  }

  /// Uploads a banner/logo to S3 then patches the lab profile with the
  /// resulting URL. [uploadVia] is the JSON field to populate (e.g.
  /// `coverUrl` or `logoUrl`).
  Future<void> uploadSchoolLogoOrBannerImage({
    required File uploadFile,
    required String uploadVia,
  }) async {
    try {
      isSaving.value = true;
      final UploadResult result = await S3UploadService.uploadFile(uploadFile);
      if (!result.isSuccess) {
        commonSnackBar(message: AppStrings.somethingWentWrong);
        return;
      }
      final ResponseModel response =
          await _repoProfile.postDescription({uploadVia: result.url});
      if (response.isSuccess) {
        commonSnackBar(message: response.message);
        await fetchFullDetails();
      } else {
        commonSnackBar(message: AppStrings.somethingWentWrong);
      }
    } on Exception catch (e) {
      logs("LabFullDetailsController.uploadSchoolLogoOrBannerImage ERROR $e");
      commonSnackBar(message: AppStrings.somethingWentWrong);
    } finally {
      isSaving.value = false;
    }
  }
}
