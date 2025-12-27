import 'dart:io';
import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/api/model/image_upload_response_model.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/common/reel/repo/channel_repo.dart';
import 'package:BlueEra/features/personal/personal_profile/view/my_documents/repo/my_document_repo.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class Document {
  final String id;
  final String name;
  final String date;
  final String filePath;

  Document({
    required this.id,
    required this.name,
    required this.date,
    required this.filePath,
  });
}

class MyDocumentsController extends GetxController {
  Rx<ApiResponse> aadharCardUploadResponse = ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> panCardUploadResponse = ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> addressUploadResponse = ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> uploadInitResponse = ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> uploadFileToS3Response = ApiResponse.initial('Initial').obs;

  GlobalKey<FormState> formKey = GlobalKey<FormState>();

  RxList<Document> documents = <Document>[].obs;
  RxBool isLoading = false.obs;

  final aadharController = TextEditingController();
  final panNumberController = TextEditingController();
  final addIdProofController = TextEditingController();

  final Rxn<File> aadharFrontImage = Rxn<File>();
  final Rxn<File> aadharBackImage = Rxn<File>();
  final Rxn<File> panCardImage = Rxn<File>();
  final Rxn<File> addIdProofFrontImage = Rxn<File>();
  final Rxn<File> addIdProofBackImage = Rxn<File>();

  @override
  void onInit() {
    super.onInit();
    loadDummyData();
  }

  void loadDummyData() {
    documents.value = [
      Document(
        id: '1',
        name: 'Aadhaar Card',
        date: '27th Dec, 2025',
        filePath: 'https://picsum.photos/id/1/400/600',
      ),
      Document(
        id: '2',
        name: 'PAN Card',
        date: '27th Dec, 2025',
        filePath: 'https://picsum.photos/id/2/400/600',
      ),
      Document(
        id: '3',
        name: 'Voter ID Card',
        date: '27th Dec, 2025',
        filePath: 'https://picsum.photos/id/3/400/600',
      ),
    ];
  }

  Future<ImageUploadResponseModel?> uploadInit(
      {required String fileType}) async {
    try {
      ResponseModel response = await MyDocumentRepo()
          .initDocumentFileUploadRepo(fileType: fileType);

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
          ApiKeys.aadharNo: aadharController.text,
          ApiKeys.aadharImages: {
            ApiKeys.front: aadharFrontImageUrl,
            ApiKeys.back: aadharBackImageUrl,
          },
        };

        // ---------- 8️⃣ API CALL ----------
        final response = await MyDocumentRepo().documentIdentificationRepo(params: params);

        // ---------- 9️⃣ HANDLE RESPONSE ----------
        if (response.isSuccess) {
          aadharCardUploadResponse.value = ApiResponse.complete(response);
          Get.back();
        } else {
          aadharCardUploadResponse.value = ApiResponse.error('error');
          commonSnackBar(
            message: response.message ?? AppStrings.somethingWentWrong,
          );
        }
        // checkStatusManageRoute();
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
          ApiKeys.panNo: panNumberController.text,
          ApiKeys.panImages: {
            ApiKeys.front: panCardImageUrl,
          },
        };

        // ---------- 8️⃣ API CALL ----------
        final response = await MyDocumentRepo().documentIdentificationRepo(params: params);

        // ---------- 9️⃣ HANDLE RESPONSE ----------
        if (response.isSuccess) {
          panCardUploadResponse.value = ApiResponse.complete(response);
          Get.back();
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
          ApiKeys.aadharNo: addIdProofController.text,
          ApiKeys.aadharImages: {
            ApiKeys.front: addIdProofFrontImageUrl,
            ApiKeys.back: addIdProofBackImageUrl,
          },
        };

        // ---------- 8️⃣ API CALL ----------
        final response = await MyDocumentRepo().documentIdentificationRepo(params: params);

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