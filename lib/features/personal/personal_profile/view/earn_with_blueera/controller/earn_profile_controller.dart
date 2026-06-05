import 'dart:io';

import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/api/apiService/s3_image_uploader.dart';
import 'package:BlueEra/core/api/model/upload_s3_image_model.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/personal/auth/controller/view_personal_details_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/model/earn_profile_model.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/repo/earn_profile_repo.dart';
import 'package:BlueEra/widgets/app_loader.dart';
import 'package:BlueEra/widgets/uploading_progressing_dialog.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:mime/mime.dart';

class EarnProfileController extends GetxController {
  RxBool isCreatingProfile = false.obs;
  RxBool isProfileLoading = false.obs;
  RxBool isProfileUpdating = false.obs;

  /// The "active" earn profile — the one currently being viewed/edited
  /// (gallery, contact, logo edits all act on this one).
  final Rx<EarnProfileModel?> earnProfile = Rx<EarnProfileModel?>(null);

  /// Every earn profile the user owns, keyed by `profileType`
  /// (homeMadeFood / homeMadeProduct / homeService). Lets each store card
  /// render its own profile when the user has more than one.
  final RxMap<String, EarnProfileModel> profilesByType =
      <String, EarnProfileModel>{}.obs;

  /// The user's profile for [type], or null if they haven't created it.
  EarnProfileModel? profileOfType(String? type) =>
      type == null ? null : profilesByType[type];

  final _uploader = S3ImageUploader();
  final EarnProfileRepo _repo = EarnProfileRepo();

  /// Create earn profile via API, then upload logo + gallery to S3 in parallel.
  Future<bool> createEarnProfile({
    required String serviceName,
    required File serviceLogo,
    required String profileType,
    required String address,
    required double lat,
    required double lng,
    String? foodType,
    String? houseNumber,
    String? alternatePhoneNumber,
    bool homeDelivery = false,
    bool monthlyPayment = false,
    List<File>? galleryImages,
  }) async {
    isCreatingProfile.value = true;

    try {
      // Build all images list (logo first, then gallery)
      final allImages = <UploadS3ImageModel>[];

      allImages.add(UploadS3ImageModel(
        path: serviceLogo.path,
        mimeType: lookupMimeType(serviceLogo.path) ?? 'image/jpeg',
      ));

      if (galleryImages != null) {
        for (final img in galleryImages) {
          allImages.add(UploadS3ImageModel(
            path: img.path,
            mimeType: lookupMimeType(img.path) ?? 'image/jpeg',
          ));
        }
      }

      // Build logo and gallery content types separately
      final logoImage = allImages.first;
      final galleryImagesList = allImages.length > 1
          ? allImages.sublist(1)
          : <UploadS3ImageModel>[];

      final Map<String, dynamic> params = {
        'serviceName': serviceName,
        'profileType': profileType,
        'address': address,
        'lat': lat,
        'lng': lng,
        'homeDelivery': homeDelivery,
        'serviceLogo': logoImage.mimeType,
        if (galleryImagesList.isNotEmpty)
          'galleryImages': galleryImagesList.map((e) => e.mimeType).toList(),
      };

      if (foodType != null) params['foodType'] = foodType;
      if (houseNumber != null && houseNumber.isNotEmpty) {
        params['houseNumber'] = houseNumber;
      }
      if (alternatePhoneNumber != null && alternatePhoneNumber.isNotEmpty) {
        params['alternatePhoneNumber'] = alternatePhoneNumber;
      }
      if (monthlyPayment) params['monthlyPayment'] = monthlyPayment;

      // Step 1: Call API to create profile and get pre-signed URLs
      final response =
          await EarnProfileRepo().createEarnProfileRepo(params: params);

      if (!response.isSuccess) {
        commonSnackBar(
            message: response.message ?? AppStrings.somethingWentWrong);
        return false;
      }

      // Step 2: Extract pre-signed URLs from response
      final data = response.response?.data;
      final uploadUrls = data?['uploadUrls'];
      final List<String> preSignedUrls = [];

      // Logo URL
      final logoUrl = uploadUrls?['serviceLogo'];
      if (logoUrl is String && logoUrl.isNotEmpty) {
        preSignedUrls.add(logoUrl);
      }

      // Gallery URLs
      final galleryUrls = uploadUrls?['galleryImages'];
      if (galleryUrls is List) {
        preSignedUrls.addAll(List<String>.from(galleryUrls));
      }

      if (preSignedUrls.isEmpty) {
        commonSnackBar(message: 'Profile created successfully!');
        await _refreshProfile();
        return true;
      }

      // Step 3: Assign pre-signed URLs to images
      final assigned =
          _uploader.assignPreSignedUrls(
            images: allImages,
            preSignedUrls: preSignedUrls,
          );

      if (!assigned) return false;

      // Step 4: Upload all images in parallel with progress dialog
      UploadProgressDialog.show(initialProgress: 0.2, title: 'Uploading images...');

      final uploadSuccess = await _uploader.uploadAll(allImages);

      UploadProgressDialog.close();

      if (uploadSuccess) {
        commonSnackBar(message: 'Profile created successfully!');
        await _refreshProfile();
        return true;
      } else {
        commonSnackBar(message: 'Profile created but some images failed to upload');
        await _refreshProfile();
        return true;
      }
    } catch (e) {
      UploadProgressDialog.close();
      debugPrint('EarnProfileController.createEarnProfile error: $e');
      commonSnackBar(message: AppStrings.somethingWentWrong);
      return false;
    } finally {
      isCreatingProfile.value = false;
      _uploader.reset();
    }
  }

  /// Refresh personal profile so earnProfileType gets updated in the dashboard.
  Future<void> _refreshProfile() async {
    try {
      final controller = Get.find<ViewPersonalDetailsController>();
      await controller.viewPersonalProfile();
    } catch (_) {}
  }

  /// Fetches every earn profile the user owns — one request per type in
  /// `earnProfileTypes`, each filtered by `profileType` query param —
  /// and populates [profilesByType] so the food / product / service cards all
  /// have their own data on every individual screen.
  ///
  /// Sets the active [earnProfile] to [activeType] when given, else preserves
  /// the current active type, else the first profile.
  ///
  /// When [onlyActiveType] is true and [activeType] is owned, fetches just that
  /// one flavour's profile instead of every owned type. Used by the earn
  /// dashboard, which renders only one flavour — so opening the product
  /// dashboard no longer also fires the food profile request (and vice-versa).
  Future<void> fetchEarnProfile({
    bool showLoading = true,
    String? activeType,
    bool onlyActiveType = false,
  }) async {
    if (userId.isEmpty) return;

    final List<String> ownedTypes =
        Get.isRegistered<ViewPersonalDetailsController>()
            ? Get.find<ViewPersonalDetailsController>().earnProfileType.toList()
            : <String>[];

    if (ownedTypes.isEmpty) {
      profilesByType.clear();
      earnProfile.value = null;
      return;
    }

    // Single-flavour fetch when the dashboard asks for just the active type;
    // otherwise fetch every owned type (Store tab needs all storefront cards).
    final bool fetchSingle = onlyActiveType &&
        activeType != null &&
        ownedTypes.contains(activeType);
    final List<String> types = fetchSingle ? <String>[activeType] : ownedTypes;

    try {
      if (showLoading) isProfileLoading.value = true;

      // One request per requested type, in parallel.
      final entries = await Future.wait(types.map((type) async {
        try {
          final response = await _repo.fetchEarnProfileByUserId(
            userId: userId,
            queryParams: {'profileType': type},
          );
          if (!response.isSuccess) return null;
          final profile = _extractProfile(response.response?.data);
          return profile == null ? null : MapEntry(type, profile);
        } catch (e) {
          debugPrint('fetchEarnProfile($type) error: $e');
          return null;
        }
      }));

      if (fetchSingle) {
        // Merge just the fetched flavour, keeping any previously-loaded ones.
        for (final e in entries) {
          if (e != null) profilesByType[e.key] = e.value;
        }
      } else {
        profilesByType.assignAll({
          for (final e in entries)
            if (e != null) e.key: e.value,
        });
      }

      // Active profile: requested type → currently-active type → first.
      final preferredType = activeType ?? earnProfile.value?.profileType;
      earnProfile.value = profilesByType[preferredType] ??
          (profilesByType.isEmpty ? null : profilesByType.values.first);
    } catch (e) {
      debugPrint('fetchEarnProfile error: $e');
    } finally {
      if (showLoading) isProfileLoading.value = false;
    }
  }

  /// Extracts a single [EarnProfileModel] from a response whose `data` may be
  /// a single object or a list (in which case the first entry is taken).
  EarnProfileModel? _extractProfile(dynamic raw) {
    if (raw is! Map) return null;
    final data = raw['data'];
    if (data is List) {
      final list =
          EarnProfilesListResponse.fromJson(raw as Map<String, dynamic>).data;
      return list.isEmpty ? null : list.first;
    } else if (data is Map<String, dynamic>) {
      return EarnProfileResponse.fromJson(raw as Map<String, dynamic>).data;
    }
    return null;
  }

  /// PATCH /earn-profiles/{id} with arbitrary JSON keys.
  Future<bool> patchEarnProfile(Map<String, dynamic> params) async {
    final id = earnProfile.value?.id;
    if (id == null || id.isEmpty) {
      commonSnackBar(message: 'Profile not loaded yet');
      return false;
    }
    try {
      isProfileUpdating.value = true;
      final response = await _repo.updateEarnProfile(id: id, params: params);
      if (!response.isSuccess) {
        commonSnackBar(
            message: response.message ?? AppStrings.somethingWentWrong);
        return false;
      }
      await fetchEarnProfile(showLoading: false);
      return true;
    } catch (e) {
      commonSnackBar(message: AppStrings.somethingWentWrong);
      return false;
    } finally {
      isProfileUpdating.value = false;
    }
  }

  /// Add one image to the gallery — PATCH with `galleryImages: [mime]`,
  /// upload returned URL, then refetch. Shows a single [AppLoader] overlay
  /// for the whole flow.
  Future<bool> addGalleryImage(File file) async {
    final id = earnProfile.value?.id;
    if (id == null || id.isEmpty) {
      commonSnackBar(message: 'Profile not loaded yet');
      return false;
    }
    final mime = lookupMimeType(file.path) ?? 'image/jpeg';
    final image = UploadS3ImageModel(path: file.path, mimeType: mime);
    AppLoader.show(message: 'Uploading photo...');
    try {
      isProfileUpdating.value = true;
      final response = await _repo.updateEarnProfile(
        id: id,
        params: {
          'galleryImages': [mime]
          //  'galleryImage': mime
        },
      );
      if (!response.isSuccess) {
        commonSnackBar(
            message: response.message ?? AppStrings.somethingWentWrong);
        return false;
      }
      final uploadUrls = response.response?.data?['uploadUrls'];
      final list = uploadUrls is Map ? uploadUrls['galleryImages'] : null;
      if (list is List && list.isNotEmpty) {
        final preSigned = list.first.toString();
        _uploader.reset();
        final assigned = _uploader.assignPreSignedUrls(
          images: [image],
          preSignedUrls: [preSigned],
        );
        if (!assigned) return false;
        final ok = await _uploader.uploadAll([image]);
        if (!ok) {
          commonSnackBar(message: 'Image upload failed');
          return false;
        }
      }
      await fetchEarnProfile(showLoading: false);
      return true;
    } catch (e) {
      commonSnackBar(message: AppStrings.somethingWentWrong);
      return false;
    } finally {
      AppLoader.hide();
      isProfileUpdating.value = false;
      _uploader.reset();
    }
  }

  /// Remove a gallery image by index — PATCHes the profile with the URL.
  /// Shows a labeled loader for the duration of the call.
  Future<bool> removeGalleryImage(int index) async {
    final profile = earnProfile.value;
    if (profile == null || index < 0 || index >= profile.galleryImages.length) {
      return false;
    }
    final url = profile.galleryImages[index];
    AppLoader.show(message: 'Removing photo...');
    try {
      return await patchEarnProfile({'removeGalleryImage': url});
    } finally {
      AppLoader.hide();
    }
  }

  /// PATCH with a single image key (serviceLogo / coverImage) — server returns
  /// a pre-signed URL under [uploadKey] that we PUT the file to.
  Future<bool> patchEarnProfileImage({
    required String uploadKey,
    required File file,
  }) async {
    final id = earnProfile.value?.id;
    if (id == null || id.isEmpty) {
      commonSnackBar(message: 'Profile not loaded yet');
      return false;
    }
    final mime = lookupMimeType(file.path) ?? 'image/jpeg';
    final image = UploadS3ImageModel(path: file.path, mimeType: mime);

    try {
      isProfileUpdating.value = true;
      final ResponseModel response = await _repo.updateEarnProfile(
        id: id,
        params: {uploadKey: mime},
      );
      if (!response.isSuccess) {
        commonSnackBar(
            message: response.message ?? AppStrings.somethingWentWrong);
        return false;
      }
      final uploadUrls = response.response?.data?['uploadUrls'];
      final preSignedUrl = uploadUrls is Map ? uploadUrls[uploadKey] : null;
      if (preSignedUrl is String && preSignedUrl.isNotEmpty) {
        _uploader.reset();
        final assigned = _uploader.assignPreSignedUrls(
          images: [image],
          preSignedUrls: [preSignedUrl],
        );
        if (!assigned) return false;
        UploadProgressDialog.show(
            initialProgress: 0.2, title: 'Uploading image...');
        final ok = await _uploader.uploadAll([image]);
        UploadProgressDialog.close();
        if (!ok) {
          commonSnackBar(message: 'Image upload failed');
          return false;
        }
      }
      await fetchEarnProfile(showLoading: false);
      return true;
    } catch (e) {
      UploadProgressDialog.close();
      commonSnackBar(message: AppStrings.somethingWentWrong);
      return false;
    } finally {
      isProfileUpdating.value = false;
      _uploader.reset();
    }
  }
}
