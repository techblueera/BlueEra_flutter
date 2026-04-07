import 'dart:developer';
import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/me/medical_new/model/medical_profile_fd_model.dart';
import 'package:BlueEra/features/me/medical_new/model/upload_init_model.dart';
import 'package:BlueEra/features/me/medical_new/repo/medical_repo.dart';
import 'package:dio/dio.dart' as dio;
import 'package:get/get.dart';

class MedicalProfileController extends GetxController {

  // ─────────────────────────────────────────────
  // ABOUT US
  // ─────────────────────────────────────────────

  Rx<ApiResponse> aboutUsResponse = ApiResponse.initial('Initial').obs;
  final aboutUsData = Rxn<MedicalAboutUs>();

  RxBool isAboutUsLoading = false.obs;
  Future<void> fetchAboutUs() async {
    try {
      isAboutUsLoading.value = true;
      ResponseModel response = await MedicalRepo().fetchMedicalAboutUsRepo();
      if (response.isSuccess) {
        aboutUsResponse.value = ApiResponse.complete(response);
        aboutUsData.value = MedicalAboutUs.fromJson(response.response?.data);
      } else {
        aboutUsResponse.value = ApiResponse.error('error');
      }
    } catch (e, s) {
      aboutUsResponse.value = ApiResponse.error('error');
      log('fetchAboutUs error: $s');
    } finally {
      isAboutUsLoading.value = false;
    }
  }

  RxBool isUpdateAboutUsLoading = false.obs;
  Future<void> updateAboutUs({
    required String logo,
    required String medicalStoreImage,
  }) async {
    try {
      isUpdateAboutUsLoading.value = true;
      Map<String, dynamic> body = {
        'logo': logo,
        'medicalStoreImage': medicalStoreImage,
      };

      ResponseModel response = await MedicalRepo().updateMedicalAboutUsRepo(params: body);
      if (response.isSuccess) {
        aboutUsData.value = MedicalAboutUs.fromJson(response.response?.data);
        commonSnackBar(message: response.message ?? AppStrings.medicalAboutUsUpdated.tr);
        Get.back();
      } else {
        commonSnackBar(message: response.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e, s) {
      log('updateAboutUs error: $s');
      commonSnackBar(message: AppStrings.somethingWentWrong);
    } finally {
      isUpdateAboutUsLoading.value = false;
    }
  }

  // ─────────────────────────────────────────────
  // CONTACT
  // ─────────────────────────────────────────────

  Rx<ApiResponse> contactResponse = ApiResponse.initial('Initial').obs;
  final contactData = Rxn<MedicalContactInfo>();

  RxBool isContactLoading = false.obs;
  Future<void> fetchContact() async {
    try {
      isContactLoading.value = true;
      ResponseModel response = await MedicalRepo().fetchMedicalContactRepo();
      if (response.isSuccess) {
        contactResponse.value = ApiResponse.complete(response);
        contactData.value = MedicalContactInfo.fromJson(response.response?.data);
      } else {
        contactResponse.value = ApiResponse.error('error');
      }
    } catch (e, s) {
      contactResponse.value = ApiResponse.error('error');
      log('fetchContact error: $s');
    } finally {
      isContactLoading.value = false;
    }
  }

  RxBool isSaveContactLoading = false.obs;
  Future<void> createOrUpdateContact({
    required String pharmacyName,
    String? website,
    String? address,
    required String pincode,
    required String phone,
    String? email,
    String? description,
    String? openFrom,
    String? openTill,
    bool isUpdate = false,
  }) async {
    try {
      isSaveContactLoading.value = true;
      Map<String, dynamic> body = {
        'pharmacyName': pharmacyName,
        ApiKeys.pincode: pincode,
        ApiKeys.phone: phone,
      };
      if (website != null && website.isNotEmpty) body[ApiKeys.website] = website;
      if (address != null && address.isNotEmpty) body[ApiKeys.address] = address;
      if (email != null && email.isNotEmpty) body[ApiKeys.email] = email;
      if (description != null && description.isNotEmpty) body[ApiKeys.description] = description;
      if (openFrom != null && openFrom.isNotEmpty) body['openFrom'] = openFrom;
      if (openTill != null && openTill.isNotEmpty) body['openTill'] = openTill;

      ResponseModel response;
      if (isUpdate) {
        response = await MedicalRepo().updateMedicalContactRepo(params: body);
      } else {
        response = await MedicalRepo().createMedicalContactRepo(params: body);
      }

      if (response.isSuccess) {
        contactData.value = MedicalContactInfo.fromJson(response.response?.data);
        commonSnackBar(message: response.message ?? AppStrings.medicalContactSaved.tr);
        Get.back();
      } else {
        commonSnackBar(message: response.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e, s) {
      log('createOrUpdateContact error: $s');
      commonSnackBar(message: AppStrings.somethingWentWrong);
    } finally {
      isSaveContactLoading.value = false;
    }
  }

  RxBool isDeleteContactLoading = false.obs;
  Future<void> deleteContact() async {
    try {
      isDeleteContactLoading.value = true;
      ResponseModel response = await MedicalRepo().deleteMedicalContactRepo();
      if (response.isSuccess) {
        contactData.value = null;
        commonSnackBar(message: response.message ?? AppStrings.medicalContactDeleted.tr);
      } else {
        commonSnackBar(message: response.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e, s) {
      log('deleteContact error: $s');
    } finally {
      isDeleteContactLoading.value = false;
    }
  }

  // ─────────────────────────────────────────────
  // TESTIMONIALS
  // ─────────────────────────────────────────────

  Rx<ApiResponse> testimonialsResponse = ApiResponse.initial('Initial').obs;
  RxList<MedicalTestimonial> testimonialsList = <MedicalTestimonial>[].obs;

  RxBool isTestimonialsLoading = false.obs;
  Future<void> fetchTestimonials() async {
    try {
      isTestimonialsLoading.value = true;
      ResponseModel response = await MedicalRepo().fetchMedicalTestimonialsRepo();
      if (response.isSuccess) {
        testimonialsResponse.value = ApiResponse.complete(response);
        if (response.response?.data != null && response.response?.data is List) {
          testimonialsList.value = (response.response!.data as List)
              .map((e) => MedicalTestimonial.fromJson(e))
              .toList();
        }
      } else {
        testimonialsResponse.value = ApiResponse.error('error');
      }
    } catch (e, s) {
      testimonialsResponse.value = ApiResponse.error('error');
      log('fetchTestimonials error: $s');
    } finally {
      isTestimonialsLoading.value = false;
    }
  }

  RxBool isCreateTestimonialLoading = false.obs;
  Future<void> createTestimonial({
    required String name,
    String? image,
    required int rating,
    required String message,
    String? designation,
  }) async {
    try {
      isCreateTestimonialLoading.value = true;
      Map<String, dynamic> body = {
        ApiKeys.name: name,
        ApiKeys.rating: rating,
        ApiKeys.message: message,
        ApiKeys.isActive: true,
      };
      if (image != null && image.isNotEmpty) body[ApiKeys.image] = image;
      if (designation != null && designation.isNotEmpty) body[ApiKeys.designation] = designation;

      ResponseModel response = await MedicalRepo().createMedicalTestimonialRepo(params: body);
      if (response.isSuccess) {
        commonSnackBar(message: response.message ?? AppStrings.medicalTestimonialCreated.tr);
        fetchTestimonials();
        Get.back();
      } else {
        commonSnackBar(message: response.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e, s) {
      log('createTestimonial error: $s');
      commonSnackBar(message: AppStrings.somethingWentWrong);
    } finally {
      isCreateTestimonialLoading.value = false;
    }
  }

  RxBool isUpdateTestimonialLoading = false.obs;
  Future<void> updateTestimonial({
    required String testimonialId,
    required String name,
    String? image,
    required int rating,
    required String message,
    String? designation,
  }) async {
    try {
      isUpdateTestimonialLoading.value = true;
      Map<String, dynamic> body = {
        ApiKeys.name: name,
        ApiKeys.rating: rating,
        ApiKeys.message: message,
      };
      if (image != null && image.isNotEmpty) body[ApiKeys.image] = image;
      if (designation != null && designation.isNotEmpty) body[ApiKeys.designation] = designation;

      ResponseModel response = await MedicalRepo().updateMedicalTestimonialRepo(
        testimonialId: testimonialId,
        params: body,
      );
      if (response.isSuccess) {
        commonSnackBar(message: response.message ?? AppStrings.medicalTestimonialUpdated.tr);
        fetchTestimonials();
        Get.back();
      } else {
        commonSnackBar(message: response.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e, s) {
      log('updateTestimonial error: $s');
      commonSnackBar(message: AppStrings.somethingWentWrong);
    } finally {
      isUpdateTestimonialLoading.value = false;
    }
  }

  Future<void> deleteTestimonial({required String testimonialId}) async {
    try {
      ResponseModel response = await MedicalRepo().deleteMedicalTestimonialRepo(
        testimonialId: testimonialId,
      );
      if (response.isSuccess) {
        testimonialsList.removeWhere((t) => t.id == testimonialId);
        commonSnackBar(message: response.message ?? AppStrings.medicalTestimonialDeleted.tr);
      } else {
        commonSnackBar(message: response.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e, s) {
      log('deleteTestimonial error: $s');
    }
  }

  Future<void> toggleTestimonialStatus({required String testimonialId}) async {
    try {
      ResponseModel response = await MedicalRepo().toggleMedicalTestimonialRepo(
        testimonialId: testimonialId,
      );
      if (response.isSuccess) {
        fetchTestimonials();
      } else {
        commonSnackBar(message: response.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e, s) {
      log('toggleTestimonial error: $s');
    }
  }

  // ─────────────────────────────────────────────
  // GALLERY
  // ─────────────────────────────────────────────

  Rx<ApiResponse> galleryResponse = ApiResponse.initial('Initial').obs;
  RxList<MedicalGallery> galleryList = <MedicalGallery>[].obs;

  RxBool isGalleryLoading = false.obs;
  Future<void> fetchGallery() async {
    try {
      isGalleryLoading.value = true;
      ResponseModel response = await MedicalRepo().fetchMedicalGalleryRepo();
      if (response.isSuccess) {
        galleryResponse.value = ApiResponse.complete(response);
        if (response.response?.data != null && response.response?.data is List) {
          galleryList.value = (response.response!.data as List)
              .map((e) => MedicalGallery.fromJson(e))
              .toList();
        }
      } else {
        galleryResponse.value = ApiResponse.error('error');
      }
    } catch (e, s) {
      galleryResponse.value = ApiResponse.error('error');
      log('fetchGallery error: $s');
    } finally {
      isGalleryLoading.value = false;
    }
  }

  RxBool isCreateGalleryLoading = false.obs;
  Future<void> createGallery({
    required String title,
    required List<String> imageUrls,
  }) async {
    try {
      isCreateGalleryLoading.value = true;
      Map<String, dynamic> body = {
        ApiKeys.title: title,
        'imageUrls': imageUrls,
      };

      ResponseModel response = await MedicalRepo().createMedicalGalleryRepo(params: body);
      if (response.isSuccess) {
        commonSnackBar(message: response.message ?? AppStrings.medicalGalleryCreated.tr);
        fetchGallery();
        Get.back();
      } else {
        commonSnackBar(message: response.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e, s) {
      log('createGallery error: $s');
      commonSnackBar(message: AppStrings.somethingWentWrong);
    } finally {
      isCreateGalleryLoading.value = false;
    }
  }

  RxBool isUpdateGalleryLoading = false.obs;
  Future<void> updateGallery({
    required String galleryId,
    required String title,
    required List<String> imageUrls,
  }) async {
    try {
      isUpdateGalleryLoading.value = true;
      Map<String, dynamic> body = {
        ApiKeys.title: title,
        'imageUrls': imageUrls,
      };

      ResponseModel response = await MedicalRepo().updateMedicalGalleryRepo(
        galleryId: galleryId,
        params: body,
      );
      if (response.isSuccess) {
        commonSnackBar(message: response.message ?? AppStrings.medicalGalleryUpdated.tr);
        fetchGallery();
        Get.back();
      } else {
        commonSnackBar(message: response.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e, s) {
      log('updateGallery error: $s');
      commonSnackBar(message: AppStrings.somethingWentWrong);
    } finally {
      isUpdateGalleryLoading.value = false;
    }
  }

  Future<void> deleteGallery({required String galleryId}) async {
    try {
      ResponseModel response = await MedicalRepo().deleteMedicalGalleryRepo(
        galleryId: galleryId,
      );
      if (response.isSuccess) {
        galleryList.removeWhere((g) => g.id == galleryId);
        commonSnackBar(message: response.message ?? AppStrings.medicalGalleryDeleted.tr);
      } else {
        commonSnackBar(message: response.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e, s) {
      log('deleteGallery error: $s');
    }
  }

  Future<void> deleteGalleryImage({
    required String galleryId,
    required String imageUrl,
  }) async {
    try {
      ResponseModel response = await MedicalRepo().deleteMedicalGalleryImageRepo(
        galleryId: galleryId,
        params: {ApiKeys.url: imageUrl},
      );
      if (response.isSuccess) {
        final gallery = galleryList.firstWhereOrNull((g) => g.id == galleryId);
        gallery?.imageUrls?.remove(imageUrl);
        galleryList.refresh();
        commonSnackBar(message: response.message ?? AppStrings.medicalImageDeleted.tr);
      } else {
        commonSnackBar(message: response.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e, s) {
      log('deleteGalleryImage error: $s');
    }
  }

  // ─────────────────────────────────────────────
  // NEAREST PHARMACIES
  // ─────────────────────────────────────────────

  Rx<ApiResponse> nearestPharmaciesResponse = ApiResponse.initial('Initial').obs;
  RxList<NearestPharmacy> nearestPharmaciesList = <NearestPharmacy>[].obs;

  RxBool isNearestPharmaciesLoading = false.obs;
  Future<void> fetchNearestPharmacies({
    required String pincode,
    int radius = 5,
  }) async {
    try {
      isNearestPharmaciesLoading.value = true;
      Map<String, dynamic> body = {
        ApiKeys.pincode: pincode,
        ApiKeys.radius: radius,
      };

      ResponseModel response = await MedicalRepo().fetchNearestPharmaciesRepo(params: body);
      if (response.isSuccess) {
        nearestPharmaciesResponse.value = ApiResponse.complete(response);
        if (response.response?.data != null && response.response?.data is List) {
          nearestPharmaciesList.value = (response.response!.data as List)
              .map((e) => NearestPharmacy.fromJson(e))
              .toList();
        }
      } else {
        nearestPharmaciesResponse.value = ApiResponse.error('error');
      }
    } catch (e, s) {
      nearestPharmaciesResponse.value = ApiResponse.error('error');
      log('fetchNearestPharmacies error: $s');
    } finally {
      isNearestPharmaciesLoading.value = false;
    }
  }

  // ─────────────────────────────────────────────
  // UPLOAD (Pre-signed S3 URL)
  // ─────────────────────────────────────────────

  Future<UploadInitModel?> getUploadUrl({
    required String fileName,
    required String fileType,
  }) async {
    try {
      ResponseModel response = await MedicalRepo().fetchUploadInitRepo(
        queryParams: {
          ApiKeys.fileName: fileName,
          ApiKeys.fileType: fileType,
        },
      );
      if (response.isSuccess) {
        return UploadInitModel.fromJson(response.response?.data);
      } else {
        commonSnackBar(message: response.message ?? AppStrings.somethingWentWrong);
        return null;
      }
    } catch (e, s) {
      log('getUploadUrl error: $s');
      return null;
    }
  }

  /// Upload file to S3 using pre-signed URL, returns publicUrl on success
  Future<String?> uploadFileToS3({
    required String filePath,
    required String fileName,
    required String fileType,
  }) async {
    try {
      final uploadInit = await getUploadUrl(fileName: fileName, fileType: fileType);
      if (uploadInit?.uploadUrl == null) return null;

      final dioClient = dio.Dio();
      final fileBytes = await dio.MultipartFile.fromFile(filePath);
      await dioClient.put(
        uploadInit!.uploadUrl!,
        data: fileBytes,
        options: dio.Options(
          headers: {'Content-Type': fileType},
        ),
      );

      return uploadInit.publicUrl;
    } catch (e, s) {
      log('uploadFileToS3 error: $s');
      commonSnackBar(message: AppStrings.medicalFailedToUploadFile);
      return null;
    }
  }
}