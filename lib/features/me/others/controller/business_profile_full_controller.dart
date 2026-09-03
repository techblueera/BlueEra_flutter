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

class BusinessProfileFullController extends GetxController {
  final OtherRepo _repo = OtherRepo();
  /// Starts TRUE: nothing has been fetched yet, and the Overview tab uses this
  /// to tell "still loading" apart from "loaded, and the profile really has no
  /// timings". Getting that backwards is what made the tab accuse every
  /// merchant of not setting their hours for the length of the first fetch.
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
  /// Called from the owning screen's `initState` — Overview is the tab that
  /// screen now OPENS on, so nothing else is going to trigger this.
  ///
  /// It needs `otherServiceIDGlobal`, which is persisted by [setOtherServiceID]
  /// but which NOTHING restores at launch: `getOtherServiceID()` is only ever
  /// called from the create-profile flow. So every cold start fell through to
  /// the lookup request below, and when that request failed the method returned
  /// having fetched no profile, reported no error and scheduled no retry — the
  /// Overview tab simply stayed empty. It only filled in after the merchant
  /// left the Me tab and came back, because the bottom bar rebuilds that screen
  /// from scratch (`_getScreen` is a plain switch, not an IndexedStack) and the
  /// second `initState` tried again.
  ///
  /// Reading the stored id first takes the lookup off the common path entirely;
  /// the request is now only the fallback for an account that has never
  /// resolved an id.
  ///
  /// ## Cache-first
  ///
  /// The controller is an in-memory singleton, so `businessProfile` is null on
  /// every cold start and the screen's "fetch when null" guard fired
  /// `/business-profile/<id>/full` once per app launch — re-asking for a
  /// profile that had not changed since the previous run. A Hive snapshot
  /// ([OtherProfileLocalStore]) now answers that, and a cache hit REPLACES the
  /// request rather than racing it, matching every other vertical in the app.
  ///
  /// Pass [forceRefresh] to go to the network anyway. Every write does: adding
  /// or deleting a gallery photo, saving management, saving timings, updating
  /// banking info. Those are the only things that change this profile from this
  /// device, and each one rewrites the snapshot on the way back.
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
        logs('[OTHER_PROFILE] no business-profile id resolved — '
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
          // Written only after the body has PARSED. Caching first would let a
          // shape this app can't read pin itself on disk and reproduce the
          // blank tab on every launch.
          await OtherProfileLocalStore.write(otherServiceIDGlobal, body);
        }
      }
    } catch (e, s) {
      // Was a bare `catch (_) {}`. Anything thrown in here — a body that isn't
      // the shape `fromJson` expects, a null deref while reading the id — left
      // a blank Overview tab and said nothing, in release AND in debug.
      logs('[OTHER_PROFILE] getBusinessProfileFull failed: $e\n$s');
    } finally {
      isLoading.value = false;
    }
  }

  /// Parses a full-profile response body and publishes it. Returns whether it
  /// produced a usable profile — the caller uses that to decide whether the
  /// body is worth caching, and whether a cache hit was good enough to skip the
  /// network.
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

  /// PUT `other-service/business-profile` with banking fields:
  /// `rbiRegistered` (bool) and `accountType` (list of strings —
  /// e.g. ["Savings", "Current", "Fixed deposit"]).
  Future<bool> updateBankingInfo({
    required bool rbiRegistered,
    required List<String> accountType,
  }) async {
    try {
      final response = await _repo.updateOtherBusinessProfileRepo(reqBODY: {
        "rbiRegistered": rbiRegistered,
        "accountType": accountType,
      });
      if (response.isSuccess) {
        commonSnackBar(
            message: response.response?.data['message'] ?? 'Saved');
        await getBusinessProfileFull(forceRefresh: true);
        return true;
      }
      commonSnackBar(message: AppStrings.somethingWentWrong);
      return false;
    } on Exception {
      commonSnackBar(message: AppStrings.somethingWentWrong);
      return false;
    }
  }

  Future<void> createOtherProfileController(
      {required Map<String, dynamic> reqParm}) async {
    try {
      ResponseModel response =
          await _repo.createOtherBusinessProfileRepo(reqBODY: reqParm);
      if (response.isSuccess) {
        commonSnackBar(message: AppStrings.otherServiceCreatedSuccess.tr);
        createSchoolResponse.value =
            ApiResponse.complete(response.response?.data);
        otherServiceIDGlobal = response.response?.data['data']['_id'];

        if (otherServiceIDGlobal.isNotEmpty) {
          await setOtherServiceID(otherServiceIDGlobal);
        } else {
          await setOtherServiceID("");
        }
        await getOtherServiceID();
        hasProfile.value = otherServiceIDGlobal.isNotEmpty;
        await getBusinessProfileFull(forceRefresh: true);
        await Future.delayed(Duration(milliseconds: 500));
      } else {
        final failure = _createFailureMessage(response);
        commonSnackBar(message: failure);
        createSchoolResponse.value = ApiResponse.error(failure);
      }
    } on Exception {
      // TODO
      createSchoolResponse.value =
          ApiResponse.error(AppStrings.somethingWentWrong);
    }
  }

  /// User-facing reason a business-profile create was rejected.
  ///
  /// The service answers a rejection with a `message` plus an `errors` array of
  /// `{field, message}` — a missing/malformed GSTIN or branch, a GSTIN the
  /// provider does not recognise (both `400`), or a `409` because that GST
  /// number is already registered with that branch. Every one of those is
  /// something the owner can act on, and all of them used to surface as a flat
  /// "something went wrong". See docs/finance-gst-branch-ui-integration.md
  /// §3/§4.
  ///
  /// The `409` messages are already written for the user, so the top-level
  /// `message` is preferred; the per-field messages are appended only when they
  /// say something the headline does not (the "Validation failed." envelope).
  String _createFailureMessage(ResponseModel response) {
    final body = response.response?.data;
    if (body is! Map) return AppStrings.somethingWentWrong;

    final headline = (body['message'] ?? '').toString().trim();
    final fieldErrors = <String>[];
    final errors = body['errors'];
    if (errors is List) {
      for (final error in errors) {
        if (error is! Map) continue;
        final text = (error['message'] ?? '').toString().trim();
        if (text.isNotEmpty && text != headline) fieldErrors.add(text);
      }
    }

    // "Validation failed." is only an envelope — the per-field messages are the
    // informative part. Anything else (a provider rejection, a duplicate
    // GST+branch) is already written for the user, so show it as-is.
    if (headline.isNotEmpty &&
        !headline.toLowerCase().startsWith('validation failed')) {
      return headline;
    }
    if (fieldErrors.isNotEmpty) return fieldErrors.join('\n');
    return headline.isNotEmpty ? headline : AppStrings.somethingWentWrong;
  }
}
