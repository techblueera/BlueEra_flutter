import 'dart:io';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/me/school/repo/upload_file_to_s3.dart';
import 'package:BlueEra/features/me/social/model/social_certification_res_model.dart';
import 'package:BlueEra/features/me/social/repo/social_profile_repo.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SocialCertificatesController extends GetxController {
  final SocialProfileRepo _repo = SocialProfileRepo();
  final titleController = TextEditingController();
  final issuedByController = TextEditingController();
  final descriptionController = TextEditingController();
  final description = "".obs;
  final documentType = "Award".obs;
  final issueDate = Rxn<DateTime>();
  final selectedFile = Rxn<File>();
  final isImageEdit = false.obs;
  final isSaving = false.obs;
  final editingCertificateId = RxnString();
  int? selectedDay, selectedMonth, selectedYear;

  RxString docUploadName = ''.obs;
  final Rxn<File> noticeImageFile = Rxn<File>();
  String initialNoticeImageUrl = "";

  @override
  void onInit() {
    getCertificateController();
    super.onInit();
  }

  ///GET BRANCH CONTACT DETAILS...
  RxList<SocialCertificationData>? socialCertificationDataList =
      <SocialCertificationData>[].obs;

  // List<SocialCertificationData> get certificates {
  //   final ai = Get.find<AiProfessionalsController>();
  //   return ai.getProfessionalServiceRes?.value.data?.certificates ?? [];
  // }

  void openForCreate() {
    titleController.clear();
    issuedByController.clear();
    descriptionController.clear();
    documentType.value = "Award";
    issueDate.value = null;
    selectedFile.value = null;
    isImageEdit.value = false;
    editingCertificateId.value = null;
    selectedDay = null;
    selectedMonth = null;
    selectedYear = null;
  }

  void openForEdit(SocialCertificationData cert) {
    titleController.text = cert.title ?? "";
    // issuedByController.text = cert.issuedBy ?? "";
    descriptionController.text = cert.description ?? "";
    // documentType.value = cert.documentType ?? "Award";
    issueDate.value = _parseIsoDate(cert.issuedDate);
    selectedDay = issueDate.value?.day;
    selectedMonth = issueDate.value?.month;
    selectedYear = issueDate.value?.year;
    selectedFile.value = null;
    isImageEdit.value = false;
    editingCertificateId.value = cert.id;
  }

  String? get certificateValidationMessage {
    if (titleController.text.trim().isEmpty) {
      return "Please enter a title for the certificate.";
    }
    if (!isValidIssueDate) {
      return "Please select a valid issued date.";
    }
    if ((editingCertificateId.value?.isEmpty ?? true) &&
        selectedFile.value == null) {
      return AppStrings.uploadImages;
    }
    return null;
  }

  bool get isValidIssueDate {
    if (selectedDay == null || selectedMonth == null || selectedYear == null) {
      return false;
    }
    try {
      final date = DateTime(selectedYear!, selectedMonth!, selectedDay!);
      return date.year == selectedYear &&
          date.month == selectedMonth &&
          date.day == selectedDay;
    } catch (_) {
      return false;
    }
  }

  String _formatIssuedDate() {
    return "${selectedYear.toString().padLeft(4, '0')}-"
        "${selectedMonth.toString().padLeft(2, '0')}-"
        "${selectedDay.toString().padLeft(2, '0')}";
  }

  Future<bool> save() async {
    final validationMessage = certificateValidationMessage;
    if (validationMessage != null) {
      commonSnackBar(message: validationMessage);
      return false;
    }

    try {
      isSaving.value = true;
      UploadResult? uploadResult;

      if (selectedFile.value != null) {
        uploadResult =
            await S3UploadService.uploadFile(selectedFile.value ?? File(""));
      }

      final payload = {
        "title": titleController.text.trim(),
        // "documentType": documentType.value,
        // "issuedBy": issuedByController.text.trim(),
        "issuedDate": _formatIssuedDate(),
        if (uploadResult?.url.isNotEmpty ?? false) "fileUrl": uploadResult?.url,
        "description": descriptionController.text.trim()
      };

      ResponseModel response;
      if (editingCertificateId.value == null) {
        response = await _repo.addSocialCertificateRepo(bodyREQ: payload);
      } else {
        response = await _repo.updateSocialCertificateRepo(
            id: editingCertificateId.value!, bodyREQ: payload);
      }

      if (response.isSuccess) {
        await getCertificateController();
        commonSnackBar(message: "Saved Successfully");
        return true;
      } else {
        commonSnackBar(
            message: response.message ?? AppStrings.somethingWentWrong);
        return false;
      }
    } catch (e) {
      commonSnackBar(message: AppStrings.somethingWentWrong);
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  DateTime? _parseIsoDate(String? s) {
    if (s == null || s.isEmpty) return null;
    try {
      return DateTime.parse(s);
    } catch (_) {
      return null;
    }
  }

  ///DELETE NOTICE....
  Future<void> deleteCertificateController({required String certiId}) async {
    try {
      ResponseModel response =
          await _repo.deleteSocialCertificateRepo(id: certiId);

      if (response.isSuccess) {
        await getCertificateController();
        commonSnackBar(
            message:
                response.response?.data['message'] ?? AppStrings.successful);
      } else {
        commonSnackBar(message: AppStrings.somethingWentWrong);
      }
    } on Exception catch (e) {
      logs("ERROR ${e}");
    }
  }

  ///GET ....
  Future<void> getCertificateController() async {
    try {
      socialCertificationDataList?.clear();
      ResponseModel response = await _repo.getSocialCertificateRepo();

      if (response.isSuccess) {
        SocialCertificationResModel socialCertificationResModel =
            SocialCertificationResModel.fromJson(response.response?.data);
        socialCertificationDataList
            ?.addAll(socialCertificationResModel.data ?? []);
      }
    } on Exception catch (e) {
      logs("ERROR ${e}");
    }
  }
}
