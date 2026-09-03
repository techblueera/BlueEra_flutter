import 'dart:io';

import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/me/others/model/business_profile_full_model.dart';
import 'package:BlueEra/features/me/others/repo/other_repo.dart';
import 'package:BlueEra/features/me/school/repo/upload_file_to_s3.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AutomotiveBusinessProfileFullController extends GetxController {
  final OtherRepo _repo = OtherRepo();
  var isLoading = false.obs;
  var businessProfile = Rx<BusinessProfileData?>(null);
  RxBool hasProfile = false.obs;

  String get website {
    if (businessProfile.value == null) return "";
    if (businessProfile.value?.contactUs != null &&
        (businessProfile.value?.contactUs?.isNotEmpty ?? false)) {
      return businessProfile.value?.contactUs?.firstOrNull?.branch?.website ??
          "";
    }
    return "";
  }

  ///GENERATE VIA AI SCHOOL DETAILS....
  final searchController = TextEditingController();
  final websiteController = TextEditingController();
  RxDouble lat = 0.0.obs;
  RxDouble lng = 0.0.obs;

  clearAiGenerateFiled() {
    searchController.clear();
    websiteController.clear();
    lat.value = 0.0;
    lng.value = 0.0;
  }

  Rx<ApiResponse> generateSchoolViaAIResponse =
      ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> createSchoolResponse = ApiResponse.initial('Initial').obs;

  @override
  void onClose() {
    searchController.dispose();
    websiteController.dispose();
    // fullSchoolAddressController.dispose();
    super.onClose();
  }

  /// Loads the full business profile the Overview tab renders.
  ///
  /// Ported verbatim from [BusinessProfileFullController.getBusinessProfileFull]
  /// under `me/others` — this module is a fork of that one and carried the same
  /// bug. See the notes there; in short:
  ///
  /// `otherServiceIDGlobal` is persisted by [setOtherServiceID] but NOTHING
  /// restores it at launch (`getOtherServiceID()` only runs in the
  /// create-profile flow), so every cold start fell through to the lookup
  /// request below. When that request failed the method returned having
  /// fetched no profile, reported no error and scheduled no retry — the
  /// Overview tab just stayed empty until the merchant left the Me tab and came
  /// back, which rebuilds the screen and runs `initState` a second time.
  ///
  /// Reading the stored id first takes the lookup off the common path; the
  /// request is now only the fallback for an account that has never resolved
  /// an id.
  Future<void> getBusinessProfileFull() async {
    isLoading.value = true;
    try {
      if (otherServiceIDGlobal.isEmpty) {
        otherServiceIDGlobal = await _storedOtherServiceId();
      }
      if (otherServiceIDGlobal.isEmpty) {
        final idResponse = await _repo.getBusinessProfileRepo();
        if (idResponse.isSuccess) {
          final id = _readProfileId(idResponse.response?.data);
          otherServiceIDGlobal = id;
          if (id.isNotEmpty) await setOtherServiceID(id);
        }
      }
      if (otherServiceIDGlobal.isEmpty) {
        logs('[AUTOMOTIVE_PROFILE] no business-profile id resolved — '
            'full profile not fetched');
        return;
      }

      // Always call the full profile API directly
      final response =
          await _repo.getBusinessProfileFullRepo(otherServiceIDGlobal);
      if (response != null && response.isSuccess) {
        final model =
            BusinessProfileFullModel.fromJson(response.response?.data);
        if (model.success == true && model.data != null) {
          businessProfile.value = model.data;
          hasProfile.value = true;
        }
      }
    } catch (e, s) {
      // Was a bare `catch (_) {}`. Anything thrown in here — a body that isn't
      // the shape `fromJson` expects, a null deref while reading the id — left
      // a blank Overview tab and said nothing, in release AND in debug.
      logs('[AUTOMOTIVE_PROFILE] getBusinessProfileFull failed: $e\n$s');
    } finally {
      isLoading.value = false;
    }
  }

  /// The persisted business-profile id, or `''` when there isn't one.
  ///
  /// Read defensively rather than through `getOtherServiceID()`: the secure
  /// store is typed `Future<dynamic>` and returns null for a key that was never
  /// written, and that helper assigns the result straight to the non-nullable
  /// [otherServiceIDGlobal] — which throws on exactly the first-run case this
  /// is here to cover.
  Future<String> _storedOtherServiceId() async {
    try {
      final stored = await SharedPreferenceUtils.getSecureValue(
          SharedPreferenceUtils.otherServiceIDKey);
      return (stored ?? '').toString();
    } catch (_) {
      return '';
    }
  }

  /// `data._id` out of the business-profile lookup body, or `''`.
  ///
  /// Indexing `data['data']['_id']` threw on any body that wasn't exactly that
  /// shape — a null `data`, an error envelope — and the blanket catch above
  /// turned the throw into a silently empty screen.
  static String _readProfileId(dynamic body) {
    if (body is! Map) return '';
    final data = body['data'];
    if (data is! Map) return '';
    return (data['_id'] ?? '').toString();
  }

  /// `profileName` to send on a business-profile PUT. The backend validates
  /// it as a string, so a null fails the whole request with
  /// `"profileName" must be a string` — which is what happened on a
  /// logo/banner upload before the full profile had loaded (or on a profile
  /// created without a name). Fall back to the logged-in account's name, and
  /// to an empty string when even that is unavailable.
  String get _profileNameForUpdate {
    final fromProfile =
        businessProfile.value?.profile?.profileName?.trim() ?? '';
    if (fromProfile.isNotEmpty) return fromProfile;
    if (businessNameGlobal.trim().isNotEmpty) return businessNameGlobal.trim();
    return userNameGlobal.trim();
  }

  uploadSchoolLogoOrBannerImage(
      {required File uploadFile, required String uploadVia}) async {
    try {
      UploadResult? result = await S3UploadService.uploadFile(uploadFile);
      if (result.isSuccess) {
        ResponseModel response =
            await _repo.updateOtherBusinessProfileRepo(reqBODY: {
          uploadVia: result.url,
          "profileName": _profileNameForUpdate
        });
        if (response.isSuccess) {
          commonSnackBar(message: response.response?.data['message']);
          getBusinessProfileFull();
        } else {
          commonSnackBar(message: AppStrings.somethingWentWrong);
        }
      }
    } on Exception {
      commonSnackBar(message: AppStrings.somethingWentWrong);

      // TODO
    }
  }

}
