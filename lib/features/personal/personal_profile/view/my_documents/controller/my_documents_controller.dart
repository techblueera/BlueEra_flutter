import 'dart:convert';
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
import 'package:BlueEra/core/services/ai_document_verification_service.dart';
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
class DocumentMeta {
  final String id;
  final DocStatus status;
  final String? frontUrl;
  final String? backUrl;

  DocumentMeta({
    required this.id,
    required this.status,
    this.frontUrl,
    this.backUrl,
  });
}

class MyDocumentsController extends GetxController {
  Rx<ApiResponse> fetchAllDocumentResponse = ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> fetchAllDocumentStatusResponse = ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> uploadInitResponse = ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> uploadFileToS3Response = ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> cancelChequeUploadResponse = ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> genericDocumentUploadResponse = ApiResponse.initial('Initial').obs;

  GlobalKey<FormState> formKey = GlobalKey<FormState>();

  RxBool isLoading = false.obs;

  final genericDocumentController = TextEditingController();
  final bankNameController = TextEditingController();
  final bankAccountNumberController = TextEditingController();
  final IFSCCodeController = TextEditingController();

  final Rxn<File> aadharFrontImage = Rxn<File>();
  final Rxn<File> aadharBackImage = Rxn<File>();
  final Rxn<File> panCardImage = Rxn<File>();
  final Rxn<File> addIdProofFrontImage = Rxn<File>();
  final Rxn<File> addIdProofBackImage = Rxn<File>();
  final Rxn<File> drivingLicenseFrontImage = Rxn<File>();
  final Rxn<File> drivingLicenseBackImage = Rxn<File>();
  final Rxn<File> rcFrontImage = Rxn<File>();
  final Rxn<File> rcBackImage = Rxn<File>();
  final Rxn<File> cancelChequeFrontImage = Rxn<File>();
  final Rxn<File> cancelChequeBackImage = Rxn<File>();

  final Rxn<File> genericDocumentsFrontImage = Rxn<File>();
  final Rxn<File> genericDocumentsBackImage = Rxn<File>();

  RxList<DocumentsResponse> documents = <DocumentsResponse>[].obs;
  Future<void> fetchAllDocumentApi() async {
    if (!isLoggedIn()) return;
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

  var documentStatuses = <String, DocumentMeta>{}.obs;
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

      // Match both the new backend `type` identifiers (UPPER_SNAKE_CASE) and
      // the legacy camelCase keys so a backend still mid-migration keeps
      // working.
      switch (apiKey) {
        case 'AADHAR':
        case 'aadhar': localKey = DocumentKeys.aadhar; break;
        case 'PAN':
        case 'pan': localKey = DocumentKeys.pan; break;
        case 'DRIVING_LICENSE':
        case 'drivingLicense': localKey = DocumentKeys.drivingLicense; break;
        case 'ADDRESS_PROOF':
        case 'addressProof': localKey = DocumentKeys.addressProof; break;
        case 'NOC':
        case 'noc': localKey = DocumentKeys.noc; break;
        case 'BANK_DETAILS':
        case 'bankDetails': localKey = DocumentKeys.bankDetails; break;
        case 'BANKER_CANCEL_CHECK':
        case 'bankersCancelledCheque': localKey = DocumentKeys.bankersCancelledCheque; break;

        case 'RC':
        case 'vehicleRC': localKey = DocumentKeys.vehicleRC; break;
        case 'insuranceDocument': localKey = DocumentKeys.insuranceDocument; break;
        case 'puc': localKey = DocumentKeys.puc; break;
        case 'fitnessCertificate': localKey = DocumentKeys.vehicleFitnessCertificate; break;

        case 'GST_CERTIFICATE':
        case 'gstCertificate': localKey = DocumentKeys.gstCertificate; break;
        case 'FSSAI_LICENSE':
        case 'fssaiLicense': localKey = DocumentKeys.fssaiLicense; break;
        case 'MEDICAL_LICENSE':
        case 'medicalLicense': localKey = DocumentKeys.medicalLicense; break;
        case 'FIRE_SAFETY_CERTIFICATE':
        case 'fireSafetyCertificate': localKey = DocumentKeys.fireSafetyCertificate; break;
        case 'MUNICIPAL_CORP_CERTIFICATE':
        case 'municipalCorpCertificate': localKey = DocumentKeys.municipalCorpCertificate; break;
        case 'MSME_CERTIFICATE':
        case 'msmeCertificate': localKey = DocumentKeys.msmeCertificate; break;
        case 'SHOP_ACT_CERTIFICATE':
        case 'shopActCertificate': localKey = DocumentKeys.shopActCertificate; break;

        case 'hotelTradeLicense': localKey = DocumentKeys.hotelTradeLicense; break;
        case 'hotelPanCard': localKey = DocumentKeys.hotelPanCard; break;
        case 'hotelGstCertificate': localKey = DocumentKeys.hotelGstCertificate; break;
        case 'hotelCancelledCheque': localKey = DocumentKeys.hotelCancelledCheque; break;
        case 'hotelPoliceVerification': localKey = DocumentKeys.hotelPoliceVerification; break;
        case 'hotelFireSafetyCertificate': localKey = DocumentKeys.hotelFireSafetyCertificate; break;
        case 'hotelFssaiLicense': localKey = DocumentKeys.hotelFssaiLicense; break;
        case 'hotelOwnerIdProof': localKey = DocumentKeys.hotelOwnerIdProof; break;
        case 'hotelOnboardingAgreement': localKey = DocumentKeys.hotelOnboardingAgreement; break;
        case 'hotelPropertyAgreement': localKey = DocumentKeys.hotelPropertyAgreement; break;
      }

      if (localKey != null && value is Map) {
        String id = value['_id'] ?? '';
        bool isVerified = value['isVerified'] ?? false;
        String? frontUrl = value['files']?['front'];
        String? backUrl = value['files']?['back'];

        documentStatuses[localKey] = DocumentMeta(
          id: id,
          status: isVerified ? DocStatus.verified : DocStatus.pending,
          frontUrl: frontUrl,
          backUrl: backUrl,
        );
      }
    });
  }


  DocStatus getStatus(String key) {
    return documentStatuses[key]?.status ?? DocStatus.notUploaded;
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

  RxBool isCancelChequeLoading = false.obs;
  Future<void> cancelChequeUploadApi({
    required String documentType,
   }) async {

    // ---------- 1️⃣ VALIDATION ----------
    if(formKey.currentState!.validate()){
      if (cancelChequeFrontImage.value == null) {
        commonSnackBar(message: AppStrings.pleaseSelectRcFrontImage.tr);
        return;
      }
      if (cancelChequeBackImage.value == null) {
        commonSnackBar(message: AppStrings.pleaseSelectRcBackImage.tr);
        return;
      }

      try {
        isCancelChequeLoading.value = true;

        // ---------- 2️⃣ INITIALIZE ----------
        String? cancelChequeFrontImageUrl;
        String? cancelChequeBackImageUrl;

        // ---------- 3️⃣ UPLOAD RC IMAGES ----------
        final results = await Future.wait([
          _uploadToS3(cancelChequeFrontImage.value!),
          _uploadToS3(cancelChequeBackImage.value!),
        ]);

        cancelChequeFrontImageUrl = results[0];
        cancelChequeBackImageUrl = results[1];

        // ---------- 5️⃣ PREPARE PAYLOAD ----------
        final params = {
          ApiKeys.documentType: documentType,
          ApiKeys.value: {
            "accountNumber": bankAccountNumberController.text.trim(),
            "ifscCode": IFSCCodeController.text.trim(),
          },
          ApiKeys.files: {
            ApiKeys.front: cancelChequeFrontImageUrl,
            ApiKeys.back: cancelChequeBackImageUrl,
          },
        };

        // ---------- 6️⃣ CALL API ----------
        final response = await MyDocumentRepo().addDocument(params: params);

        // ---------- 7️⃣ HANDLE RESPONSE ----------
        if (response.isSuccess) {
          cancelChequeUploadResponse.value = ApiResponse.complete(response);
          bankAccountNumberController.clear();
          IFSCCodeController.clear();
          cancelChequeFrontImage.value = null;
          cancelChequeBackImage.value = null;
          Get.back();
        } else {
          cancelChequeUploadResponse.value = ApiResponse.error('error');
          commonSnackBar(
            message: response.message ?? AppStrings.somethingWentWrong,
          );
        }
      } catch (e) {
        cancelChequeUploadResponse.value = ApiResponse.error('error');
        commonSnackBar(message: AppStrings.somethingWentWrong);
      } finally {
        isCancelChequeLoading.value = false;
      }
    }
  }

  /// Bridges a successful *manual* Aadhaar verification into the
  /// document-service, wired as the `onManualVerified` callback of
  /// [AadhaarManualKycController].
  ///
  /// The card images have already been matched against [aadhaarNumber] by the
  /// AI verifier, so they are recorded alongside the number exactly like any
  /// other document upload.
  ///
  /// Throws on failure — the manual screen keeps the user on the form rather
  /// than showing a success state for something that wasn't saved.
  Future<void> recordAadhaarManualVerified(
    String aadhaarNumber,
    File frontImage,
    File backImage,
  ) async {
    try {
      final urls = await Future.wait([
        _uploadToS3(frontImage),
        _uploadToS3(backImage),
      ]);
      final frontUrl = urls[0];
      final backUrl = urls[1];

      if (frontUrl == null || backUrl == null) {
        commonSnackBar(
            message: "Image upload failed. Please check your connection.");
        throw Exception('Aadhaar image upload failed');
      }

      final params = {
        ApiKeys.documentType: DocumentKeys.aadhar,
        ApiKeys.files: {
          ApiKeys.front: frontUrl,
          ApiKeys.back: backUrl,
        },
        ApiKeys.value: jsonEncode({DocumentKeys.aadhar: aadhaarNumber}),
      };

      final response = await MyDocumentRepo().addDocument(params: params);
      if (!response.isSuccess) {
        genericDocumentUploadResponse.value = ApiResponse.error('error');
        commonSnackBar(
            message: response.message ?? AppStrings.somethingWentWrong);
        throw Exception('addDocument failed: ${response.message}');
      }
      genericDocumentUploadResponse.value = ApiResponse.complete(response);
    } finally {
      // Refresh so the Aadhaar tile picks up its new status, whether or not the
      // record landed.
      await fetchAllDocumentStatusApi();
    }
  }

  RxBool isGenericDocumentLoading = false.obs;
  Future<void> genericDocumentApi({
    required String documentType,
    required bool hasInput,
    required bool backImage,
  }) async {

    // ---------- 1️⃣ TEXT VALIDATION (Conditional) ----------
    if (hasInput) {
      if (!formKey.currentState!.validate()) {
        return; // Stop if text validation fails
      }
    }

    // ---------- 2️⃣ IMAGE VALIDATION ----------
    if (genericDocumentsFrontImage.value == null) {
      commonSnackBar(message: _getMissingImageMsg(documentType, isBack: false));
      return;
    }

    if (backImage) {
      if (genericDocumentsBackImage.value == null) {
        commonSnackBar(message: _getMissingImageMsg(documentType, isBack: true));
        return;
      }
    }

    try {
      isGenericDocumentLoading.value = true;

      // ---------- 2.5️⃣ AI DOCUMENT VERIFICATION ----------
      // Only Aadhar / PAN / Driving License / RC support AI verification.
      // Validate that the uploaded images actually match the entered number
      // before spending bandwidth on the S3 upload.
      final verifyDocName = _getVerifiableDocumentName(documentType);
      if (verifyDocName != null) {
        final isValid = await _verifyDocument(
          documentName: verifyDocName,
          documentNumber: genericDocumentController.text.trim(),
          images: [
            genericDocumentsFrontImage.value!,
            if (backImage && genericDocumentsBackImage.value != null)
              genericDocumentsBackImage.value!,
          ],
        );
        if (!isValid) {
          isGenericDocumentLoading.value = false;
          return; // Stop — invalid document, message already shown.
        }
      }

      // ---------- 3️⃣ UPLOAD IMAGES ----------

      String? frontImageUrl;
      String? backImageUrl;

      try {

        List<String?> imageUrls = await Future.wait([
          _uploadToS3(genericDocumentsFrontImage.value!),
          if (backImage) _uploadToS3(genericDocumentsBackImage.value!)
        ]);

        frontImageUrl = imageUrls[0];
        backImageUrl = backImage ? imageUrls[1] : null;
      } catch (e) {
        commonSnackBar(message: "Image upload failed. Please check your connection.");
        isGenericDocumentLoading.value = false;
        return;
      }



      // ---------- 4️⃣ PREPARE PAYLOAD ----------
      final params = {
        ApiKeys.documentType: documentType,
         ApiKeys.files: {
          ApiKeys.front: frontImageUrl,
         if(backImage && backImageUrl!=null) ApiKeys.back: backImageUrl
        },
      };
      if(hasInput) params[ApiKeys.value] = jsonEncode({documentType: genericDocumentController.text.trim()});

      // ---------- 5️⃣ API CALL ----------
      final response = await MyDocumentRepo().addDocument(params: params);

      if (response.isSuccess) {
        genericDocumentUploadResponse.value = ApiResponse.complete(response);
        isGenericDocumentLoading.value = false;
        Get.back();
        fetchAllDocumentStatusApi();
      } else {
        isGenericDocumentLoading.value = false;
        genericDocumentUploadResponse.value = ApiResponse.error('error');
        commonSnackBar(message: response.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e, s) {
      debugPrint('❌ documentIdentificationRepo error: $e\n$s');
      isGenericDocumentLoading.value = false;
      genericDocumentUploadResponse.value = ApiResponse.error('error');
      commonSnackBar(message: AppStrings.somethingWentWrong);
    } finally {

    }
  }

  /// Maps a local [DocumentKeys] type to the `document_name` expected by the
  /// AI verification endpoint. Returns null for document types that are not
  /// verifiable (so the upload proceeds without a verification step).
  String? _getVerifiableDocumentName(String docType) {
    switch (docType) {
      case DocumentKeys.aadhar:
        return AiDocumentVerificationService.aadhaar;
      case DocumentKeys.pan:
        return AiDocumentVerificationService.pan;
      case DocumentKeys.drivingLicense:
        return AiDocumentVerificationService.drivingLicense;
      case DocumentKeys.vehicleRC:
        return AiDocumentVerificationService.vehicleRc;
      default:
        return null;
    }
  }

  /// Runs the AI document check and reports the reason to the user when it
  /// fails. Returns true only when the document was actually verified — any
  /// rejection, network error or unreadable response returns false, so an
  /// unverified document is never uploaded.
  Future<bool> _verifyDocument({
    required String documentName,
    required String documentNumber,
    required List<File> images,
  }) async {
    final result = await AiDocumentVerificationService().verify(
      documentName: documentName,
      documentNumber: documentNumber,
      images: images,
    );
    if (!result.isValid) {
      commonSnackBar(message: result.failureMessage!);
      return false;
    }
    return true;
  }

  String getDocumentName(String docType) {
    switch (docType) {
    // ----------------- PERSONAL DOCUMENTS -----------------
      case DocumentKeys.aadhar:
        return "Aadhaar Card";
      case DocumentKeys.pan:
        return "PAN Card";
      case DocumentKeys.drivingLicense:
        return "Driving License";

      case DocumentKeys.addressProof:
        return "Address Proof";
      case DocumentKeys.noc:
        return "NOC";
      case DocumentKeys.bankDetails:
        return "Bank Details";
      case DocumentKeys.bankersCancelledCheque:
        return "Cancelled Cheque";

    // ----------------- VEHICLE DOCUMENTS -----------------
      case DocumentKeys.vehicleRC:
        return "Vehicle RC";
      case DocumentKeys.insuranceDocument:
        return "Insurance Document";
      case DocumentKeys.puc:
        return "Pollution Certificate";
      case DocumentKeys.vehicleFitnessCertificate:
        return "Vehicle Fitness Certificate";

    // ----------------- BUSINESS DOCUMENTS -----------------
      case DocumentKeys.gstCertificate:
        return "GST Certificate";
      case DocumentKeys.fssaiLicense:
        return "FSSAI License";
      case DocumentKeys.medicalLicense:
        return "Medical License";
      case DocumentKeys.fireSafetyCertificate:
        return "Fire Safety Certificate";
      case DocumentKeys.municipalCorpCertificate:
        return "Municipal Corp Certificate";
      case DocumentKeys.msmeCertificate:
        return "MSME Certificate";
      case DocumentKeys.shopActCertificate:
        return "Shop Act Certificate";

    // ----------------- HOTEL & HOMESTAY DOCUMENTS -----------------
      case DocumentKeys.hotelTradeLicense:
        return "Trade License";
      case DocumentKeys.hotelPanCard:
        return "Hotel PAN Card";
      case DocumentKeys.hotelGstCertificate:
        return "Hotel GST Certificate";
      case DocumentKeys.hotelCancelledCheque:
        return "Hotel Cancelled Cheque";
      case DocumentKeys.hotelPoliceVerification:
        return "Police Verification / NOC";
      case DocumentKeys.hotelFireSafetyCertificate:
        return "Hotel Fire Safety Certificate";
      case DocumentKeys.hotelFssaiLicense:
        return "Hotel FSSAI License";
      case DocumentKeys.hotelOwnerIdProof:
        return "Owner ID Proof";
      case DocumentKeys.hotelOnboardingAgreement:
        return "Signed Agreement";
      case DocumentKeys.hotelPropertyAgreement:
        return "Property/Lease Agreement";

    // ----------------- DEFAULT -----------------
      default:
        return "Document";
    }
  }

  String _getMissingImageMsg(String docType, {bool isBack = false}) {
    String docName = getDocumentName(docType);

    // Return specific message
    if (isBack) {
      return "Please upload $docName back side image";
    } else {
      // For single-side documents (like Cheque/Certificates), this message still works well
      // e.g. "Please upload Cancelled Cheque front side image"
      return "Please upload $docName image";
    }
  }


} 
