import 'dart:io';

import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/me/others/model/business_profile_full_model.dart';
import 'package:BlueEra/features/me/others/repo/other_repo.dart';
import 'package:BlueEra/features/me/others/service/other_profile_local_store.dart';
import 'package:BlueEra/features/me/school/repo/upload_file_to_s3.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AutomotiveBusinessProfileFullController extends GetxController {
  final OtherRepo _repo = OtherRepo();
  /// Starts TRUE: nothing has been fetched yet, and the Overview tab uses this
  /// to tell "still loading" apart from "loaded and genuinely empty". Same
  /// reasoning as the `me/others` fork this module was copied from.
  var isLoading = true.obs;
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
  ///
  /// Cache-first, like the `me/others` fork: this controller is an in-memory
  /// singleton, so `businessProfile` was null on every cold start and the
  /// screen's "fetch when null" guard re-asked for a profile that had not
  /// changed since the previous run. [OtherProfileLocalStore] answers that
  /// instead, and a hit REPLACES the request. Pass [forceRefresh] after a write
  /// — that is the only thing that makes the snapshot stale from this device.
  Future<void> getBusinessProfileFull({bool forceRefresh = false}) async {
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

      if (!forceRefresh) {
        final cached = await OtherProfileLocalStore.read(otherServiceIDGlobal);
        if (cached != null && _applyProfile(cached)) return;
      }

      final response =
          await _repo.getBusinessProfileFullRepo(otherServiceIDGlobal);
      if (response != null && response.isSuccess) {
        final body = response.response?.data;
        if (_applyProfile(body)) {
          // Only after it has PARSED — a shape this app can't read must not
          // pin itself on disk and reproduce a blank tab on every launch.
          await OtherProfileLocalStore.write(otherServiceIDGlobal, body);
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

  /// Parses a full-profile body and publishes it. Returns whether it produced a
  /// usable profile, which is what decides both "is this worth caching" and
  /// "was the cache hit good enough to skip the network".
  bool _applyProfile(dynamic body) {
    if (body == null) return false;
    final model = BusinessProfileFullModel.fromJson(body);
    if (model.success != true || model.data == null) return false;
    businessProfile.value = model.data;
    hasProfile.value = true;
    return true;
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
          getBusinessProfileFull(forceRefresh: true);
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
