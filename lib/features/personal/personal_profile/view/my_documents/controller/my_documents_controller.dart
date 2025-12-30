import 'dart:developer';
import 'dart:io';
import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/api/model/image_upload_response_model.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/common/reel/repo/channel_repo.dart';
import 'package:BlueEra/features/personal/personal_profile/view/my_documents/model/upload_document_response.dart';
import 'package:BlueEra/features/personal/personal_profile/view/my_documents/repo/my_document_repo.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

enum DocStatus {
  notUploaded, // Key not found in API
  pending,     // Key found, isVerified: false
  verified     // Key found, isVerified: true
}

class MyDocumentsController extends GetxController {
  Rx<ApiResponse> fetchAllDocumentResponse = ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> fetchAllDocumentStatusResponse = ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> aadharCardUploadResponse = ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> panCardUploadResponse = ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> addressUploadResponse = ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> drivingLicenseUploadResponse = ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> RcBookUploadResponse = ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> uploadInitResponse = ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> uploadFileToS3Response = ApiResponse.initial('Initial').obs;

  GlobalKey<FormState> formKey = GlobalKey<FormState>();

  RxBool isLoading = false.obs;

  final aadharController = TextEditingController();
  final panNumberController = TextEditingController();
  final addIdProofController = TextEditingController();
  final drivingLicenseController = TextEditingController();
  final rcController = TextEditingController();

  final Rxn<File> aadharFrontImage = Rxn<File>();
  final Rxn<File> aadharBackImage = Rxn<File>();
  final Rxn<File> panCardImage = Rxn<File>();
  final Rxn<File> addIdProofFrontImage = Rxn<File>();
  final Rxn<File> addIdProofBackImage = Rxn<File>();
  final Rxn<File> drivingLicenseFrontImage = Rxn<File>();
  final Rxn<File> drivingLicenseBackImage = Rxn<File>();
  final Rxn<File> rcFrontImage = Rxn<File>();
  final Rxn<File> rcBackImage = Rxn<File>();

  RxList<DocumentsResponse> documents = <DocumentsResponse>[].obs;
  Future<void> fetchAllDocumentApi() async {
    try {
      ResponseModel response = await MyDocumentRepo().getAllDocument();

      if (response.isSuccess) {
        fetchAllDocumentResponse.value = ApiResponse.complete(response);
        final data = response.response?.data;
        if (data is List) {
          // 3. Map it specifically to your Model
          documents.value = data
              .map((e) => DocumentsResponse.fromJson(e))
              .toList();

          log('document length -- ${documents.length}');
        } else {
          log('Error: API Data is not a List');
          documents.clear();
        }
      } else {
        fetchAllDocumentResponse.value = ApiResponse.error('error');
        commonSnackBar(
            message: response.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e, s) {
      log('stack trace-- $s');
      fetchAllDocumentResponse.value = ApiResponse.error('error');
      commonSnackBar(message: AppStrings.somethingWentWrong);
    }
  }

  var documentStatuses = <String, DocStatus>{}.obs;
  Future<void> fetchAllDocumentStatusApi() async {
    try {
      ResponseModel response = await MyDocumentRepo().getAllDocumentStatus();

      if (response.isSuccess) {
        fetchAllDocumentStatusResponse.value = ApiResponse.complete(response);
        updateStatuses(response.response!.data);
      } else {
        fetchAllDocumentStatusResponse.value = ApiResponse.error('error');
        commonSnackBar(
            message: response.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      fetchAllDocumentStatusResponse.value = ApiResponse.error('error');
      commonSnackBar(message: AppStrings.somethingWentWrong);
    }
  }

  void updateStatuses(Map<String, dynamic> data) {
    documentStatuses.clear();

    data.forEach((apiKey, value) {
      String? localKey;

      switch (apiKey) {
        case 'aadhar': localKey = DocumentKeys.aadhar; break;
        case 'pan': localKey = DocumentKeys.pan; break;
        case 'drivingLicense': localKey = DocumentKeys.drivingLicense; break;
        case 'vehicleRC': localKey = DocumentKeys.vehicleRC; break;
        case 'addressProof': localKey = DocumentKeys.addressProof; break;
        case 'noc': localKey = DocumentKeys.noc; break;
        case 'bankersCancelledCheque': localKey = DocumentKeys.bankersCancelledCheque; break;

      // --- Business Keys ---
        case 'gstCertificate': localKey = DocumentKeys.gstCertificate; break;
        case 'fssaiLicense': localKey = DocumentKeys.fssaiLicense; break;
        case 'medicalLicense': localKey = DocumentKeys.medicalLicense; break;
        case 'fireSafetyCertificate': localKey = DocumentKeys.fireSafetyCertificate; break;
        case 'municipalCorpCertificate': localKey = DocumentKeys.municipalCorpCertificate; break;
        case 'msmeCertificate': localKey = DocumentKeys.msmeCertificate; break;
        case 'shopActCertificate': localKey = DocumentKeys.shopActCertificate; break;

        default: localKey = null;
      }

      if (localKey != null && value is Map && value.containsKey('isVerified')) {
        bool isVerified = value['isVerified'] ?? false;
        DocStatus newStatus = isVerified ? DocStatus.verified : DocStatus.pending;

        documentStatuses[localKey] = newStatus;
        // print("[SUCCESS] Mapped '$apiKey' -> '$localKey' | Status: $newStatus");
      }
    });

  }

  DocStatus getStatus(String key) {
    return documentStatuses[key] ?? DocStatus.notUploaded;
  }


  Future<ImageUploadResponseModel?> uploadInit(
      {required String fileType}) async {
    try {
      ResponseModel response = await MyDocumentRepo().initDocumentFileUploadRepo(fileType: fileType);

      if (response.isSuccess) {
        uploadInitResponse.value = ApiResponse.complete(response);
        final imageUploadResponseModel =
        ImageUploadResponseModel.fromJson(response.response?.data);
        return imageUploadResponseModel;
      }
    } catch (e) {
      uploadInitResponse.value = ApiResponse.error('error');
      commonSnackBar(message: AppStrings.somethingWentWrong);
      return null;
    }
    return null;
  }

  Future<void> uploadFileToS3Api({
    required File file,
    required String fileType,
    required String preSignedUrl,
    required Function(double progress) onProgress,
  }) async {
    try {
      ResponseModel? response = await ChannelRepo().uploadVideoToS3(
        onProgress: onProgress,
        file: file,
        fileType: fileType,
        preSignedUrl: preSignedUrl,
      );

      if (response?.isSuccess ?? false) {
        uploadFileToS3Response.value = ApiResponse.complete(response);
      } else {
        uploadFileToS3Response.value = ApiResponse.error('error');
        commonSnackBar(
            message: response?.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      uploadFileToS3Response.value = ApiResponse.error('error');
      commonSnackBar(message: AppStrings.somethingWentWrong);
    }
  }

  RxBool isAadharUploadLoading = false.obs;
  Future<void> aadharCardApi() async {
    // ---------- 1️⃣ VALIDATION ----------

    if(formKey.currentState!.validate()){
      if (aadharFrontImage.value == null) {
        commonSnackBar(message: AppStrings.pleaseSelectAadharFrontImage.tr);
        return;
      }
      if (aadharBackImage.value == null) {
        commonSnackBar(message: AppStrings.pleaseSelectAadharBackImage.tr);
        return;
      }

      try {
        isAadharUploadLoading.value = true;

        // ---------- 2️⃣ INITIALIZE ----------
        String? aadharFrontImageUrl;
        String? aadharBackImageUrl;

        // ---------- 4️⃣ UPLOAD AADHAR FRONT ----------
        aadharFrontImageUrl = await _uploadToS3(aadharFrontImage.value!);

        // ---------- 5️⃣ UPLOAD AADHAR BACK ----------
        aadharBackImageUrl = await _uploadToS3(aadharBackImage.value!);

        // ---------- 7️⃣ PREPARE PAYLOAD ----------
        final params = {
          ApiKeys.documentType: DocumentKeys.aadhar,
          ApiKeys.value: aadharController.text,
          ApiKeys.files: {
            ApiKeys.front: aadharFrontImageUrl,
            ApiKeys.back: aadharBackImageUrl,
          },
        };

        // ---------- 8️⃣ API CALL ----------
        final response = await MyDocumentRepo().addDocument(params: params);

        // ---------- 9️⃣ HANDLE RESPONSE ----------
        if (response.isSuccess) {
          aadharCardUploadResponse.value = ApiResponse.complete(response);
          Get.back();
          aadharController.clear();
          aadharFrontImage.value = null;
          aadharBackImage.value = null;
          fetchAllDocumentStatusApi();
        } else {
          aadharCardUploadResponse.value = ApiResponse.error('error');
          commonSnackBar(
            message: response.message ?? AppStrings.somethingWentWrong,
          );
        }
      } catch (e, s) {
        debugPrint('❌ documentIdentificationRepo error: $e\n$s');
        aadharCardUploadResponse.value = ApiResponse.error('error');
        commonSnackBar(message: AppStrings.somethingWentWrong);
      } finally {
        isAadharUploadLoading.value = false;
      }
    }

  }

  RxBool isPanUploadLoading = false.obs;
  Future<void> panCardApi() async {
    // ---------- 1️⃣ VALIDATION ----------

    if(formKey.currentState!.validate()){
      if (panCardImage.value == null) {
        commonSnackBar(message: AppStrings.pleaseSelectPanCardImage.tr);
        return;
      }

      try {
        isPanUploadLoading.value = true;

        // ---------- 2️⃣ INITIALIZE ----------
        String? panCardImageUrl;

        // ---------- 6️⃣ UPLOAD PAN CARD ----------
        panCardImageUrl = await _uploadToS3(panCardImage.value!);

        // ---------- 7️⃣ PREPARE PAYLOAD ----------
        final params = {
          ApiKeys.documentType: DocumentKeys.pan,
          ApiKeys.value: panNumberController.text,
          ApiKeys.files: {
            ApiKeys.front: panCardImageUrl,
          },
        };

        // ---------- 8️⃣ API CALL ----------
        final response = await MyDocumentRepo().addDocument(params: params);

        // ---------- 9️⃣ HANDLE RESPONSE ----------
        if (response.isSuccess) {
          panCardUploadResponse.value = ApiResponse.complete(response);
          Get.back();
          panNumberController.clear();
          panCardImage.value = null;
          fetchAllDocumentStatusApi();
        } else {
          panCardUploadResponse.value = ApiResponse.error('error');
          commonSnackBar(
            message: response.message ?? AppStrings.somethingWentWrong,
          );
        }
        // await ridersOnboardingStatusRepoApi();
      } catch (e, s) {
        debugPrint('❌ documentIdentificationRepo error: $e\n$s');
        panCardUploadResponse.value = ApiResponse.error('error');
        commonSnackBar(message: AppStrings.somethingWentWrong);
      } finally {
        isPanUploadLoading.value = false;
      }
    }
  }

  RxBool isAddressUploadLoading = false.obs;
  Future<void> addressApi() async {
    // ---------- 1️⃣ VALIDATION ----------
    if(formKey.currentState!.validate()){
      if (addIdProofFrontImage.value == null) {
        commonSnackBar(message: AppStrings.pleaseSelectAddressProofIdFrontImage.tr);
        return;
      }
      if (addIdProofBackImage.value == null) {
        commonSnackBar(message: AppStrings.pleaseSelectAddressProofIdBackImage.tr);
        return;
      }

      try {
        isAddressUploadLoading.value = true;

        // ---------- 2️⃣ INITIALIZE ----------
        String? addIdProofFrontImageUrl;
        String? addIdProofBackImageUrl;

        // ---------- 4️⃣ UPLOAD AADHAR FRONT ----------
        addIdProofFrontImageUrl = await _uploadToS3(aadharFrontImage.value!);

        // ---------- 5️⃣ UPLOAD AADHAR BACK ----------
        addIdProofBackImageUrl = await _uploadToS3(aadharBackImage.value!);

        // ---------- 7️⃣ PREPARE PAYLOAD ----------
        final params = {
          ApiKeys.documentType: DocumentKeys.addressProof,
          ApiKeys.value: addIdProofController.text,
          ApiKeys.files: {
            ApiKeys.front: addIdProofFrontImageUrl,
            ApiKeys.back: addIdProofBackImageUrl,
          },
        };

        // ---------- 8️⃣ API CALL ----------
        final response = await MyDocumentRepo().addDocument(params: params);

        // ---------- 9️⃣ HANDLE RESPONSE ----------
        if (response.isSuccess) {
          addressUploadResponse.value = ApiResponse.complete(response);
          Get.back();
        } else {
          addressUploadResponse.value = ApiResponse.error('error');
          commonSnackBar(
            message: response.message ?? AppStrings.somethingWentWrong,
          );
        }
        // checkStatusManageRoute();
      } catch (e, s) {
        debugPrint('❌ documentIdentificationRepo error: $e\n$s');
        addressUploadResponse.value = ApiResponse.error('error');
        commonSnackBar(message: AppStrings.somethingWentWrong);
      } finally {
        isAddressUploadLoading.value = false;
      }
    }
  }

  Future<String?> _uploadToS3(File file) async {
    try {
      final fileInfo = getFileInfo(file);
      final mimeType = fileInfo['mimeType']!;

      final initModel = await uploadInit(fileType: mimeType);
      if (initModel == null) return null;

      await uploadFileToS3Api(
        file: file,
        fileType: mimeType,
        preSignedUrl: initModel.uploadUrl ?? '',
        onProgress: (progress) {
          debugPrint(
              " Uploading ${file.path.split('/').last}: ${(progress * 100).toStringAsFixed(0)}%");
        },
      );

      return initModel.fileUrl;
    } catch (e) {
      debugPrint("Upload failed for ${file.path}: $e");
      return null;
    }
  }

  RxBool isDrivingVerificationLoading = false.obs;

  Future<void> drivingLicenceUploadApi() async {
    if (drivingLicenseFrontImage.value == null) {
      commonSnackBar(message: AppStrings.pleaseSelectDlFrontImage.tr);
      return;
    }
    if (drivingLicenseBackImage.value == null) {
      commonSnackBar(message: AppStrings.pleaseSelectDlBackImage.tr);
      return;
    }

    try {
      isDrivingVerificationLoading.value = true;

      // ---------- 2️⃣ INITIALIZE ----------

      String? drivingLicenseFrontImageUrl;
      String? drivingLicenseBackImageUrl;

      // ---------- 4️⃣ UPLOAD DRIVING LICENSE IMAGES ----------
      drivingLicenseFrontImageUrl =
      await _uploadToS3(drivingLicenseFrontImage.value!);
      drivingLicenseBackImageUrl =
      await _uploadToS3(drivingLicenseBackImage.value!);

      // ---------- 5️⃣ PREPARE PAYLOAD ----------
      final params = {
        ApiKeys.documentType:  DocumentKeys.drivingLicense,
        ApiKeys.value: drivingLicenseController.text,
        ApiKeys.files: {
          ApiKeys.front: drivingLicenseFrontImageUrl,
          ApiKeys.back: drivingLicenseBackImageUrl,
        },
      };

      // ---------- 6️⃣ CALL API ----------
      final response = await MyDocumentRepo().addDocument(params: params);

      // ---------- 7️⃣ HANDLE RESPONSE ----------
      if (response.isSuccess) {
        drivingLicenseUploadResponse.value = ApiResponse.complete(response);
        Get.back();
      } else {
        drivingLicenseUploadResponse.value = ApiResponse.error('error');
        commonSnackBar(
          message: response.message ?? AppStrings.somethingWentWrong,
        );
      }
      // checkStatusManageRoute();
    } catch (e, s) {
      debugPrint('❌ ridersOnboardingDrivingVerificationApi error: $e\n$s');
      drivingLicenseUploadResponse.value = ApiResponse.error('error');
      commonSnackBar(message: AppStrings.somethingWentWrong);
    } finally {
      isDrivingVerificationLoading.value = false;
    }
  }

  RxBool isRcBookVerificationLoading = false.obs;

  Future<void> rcBookUploadApi() async {
    // ---------- 1️⃣ VALIDATION ----------
    if (rcFrontImage.value == null) {
      commonSnackBar(message: AppStrings.pleaseSelectRcFrontImage.tr);
      return;
    }
    if (rcBackImage.value == null) {
      commonSnackBar(message: AppStrings.pleaseSelectRcBackImage.tr);
      return;
    }

    try {
      isRcBookVerificationLoading.value = true;

      // ---------- 2️⃣ INITIALIZE ----------
      String? rcFrontImageUrl;
      String? rcBackImageUrl;

      // ---------- 3️⃣ UPLOAD RC IMAGES ----------
      rcFrontImageUrl = await _uploadToS3(rcFrontImage.value!);
      rcBackImageUrl = await _uploadToS3(rcBackImage.value!);

      // ---------- 5️⃣ PREPARE PAYLOAD ----------
      final params = {
        ApiKeys.documentType: DocumentKeys.vehicleRC,
        ApiKeys.value: rcController.text,
        ApiKeys.files: {
          ApiKeys.front: rcFrontImageUrl,
          ApiKeys.back: rcBackImageUrl,
        },
      };

      // ---------- 6️⃣ CALL API ----------
      final response = await MyDocumentRepo().addDocument(params: params);

      // ---------- 7️⃣ HANDLE RESPONSE ----------
      if (response.isSuccess) {
        RcBookUploadResponse.value = ApiResponse.complete(response);
        Get.back();
      } else {
        RcBookUploadResponse.value = ApiResponse.error('error');
        commonSnackBar(
          message: response.message ?? AppStrings.somethingWentWrong,
        );
      }
      // checkStatusManageRoute();
    } catch (e, s) {
      debugPrint('❌ ridersOnboardingDrivingVerificationApi error: $e\n$s');
      RcBookUploadResponse.value = ApiResponse.error('error');
      commonSnackBar(message: AppStrings.somethingWentWrong);
    } finally {
      isRcBookVerificationLoading.value = false;
    }
  }



// checkStatusManageRoute()
  // async {
  //   await ridersOnboardingStatusRepoApi();
  //   final allCompleted =
  //   stepStatus.values.every((status) => status == true);
  //   if (allCompleted) {
  //     Get.offNamedUntil(
  //       RouteHelper.getBottomNavigationBarScreenRoute(),
  //           (route) => false,
  //     );
  //     // Get.until((route) =>
  //     // route.settings.name ==
  //     //     RouteHelper.getBottomNavigationBarScreenRoute());
  //   } else {
  //     Get.back();
  //   }
  // }



} 