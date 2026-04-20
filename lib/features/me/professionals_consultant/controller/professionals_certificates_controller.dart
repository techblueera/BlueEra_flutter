import 'dart:io';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/common/Discover/model/profe_cons_res_model.dart';
import 'package:BlueEra/features/common/reel/repo/channel_repo.dart';
import 'package:BlueEra/features/me/professionals_consultant/controller/ai_professionals_controller.dart';
import 'package:BlueEra/features/me/professionals_consultant/repo/professionals_repo.dart';
import 'package:BlueEra/features/me/school/repo/upload_file_to_s3.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ProfessionalsCertificatesController extends GetxController {
  final ProfessionalsRepo _repo = ProfessionalsRepo();
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

  List<Certificates> get certificates {
    final ai = Get.find<AiProfessionalsController>();
    return ai.getProfessionalServiceRes?.value.data?.certificates ?? [];
  }

  void openForCreate() {
    titleController.clear();
    issuedByController.clear();
    descriptionController.clear();
    documentType.value = "Award";
    issueDate.value = null;
    selectedFile.value = null;
    isImageEdit.value = false;
    editingCertificateId.value = null;
    selectedDay=null;
    selectedMonth=null;
    selectedYear=null;
  }

  void openForEdit(Certificates cert) {
    titleController.text = cert.title ?? "";
    issuedByController.text = cert.issuedBy ?? "";
    descriptionController.text = cert.description ?? "";
    documentType.value = cert.documentType ?? "Award";
    issueDate.value = _parseIsoDate(cert.issueDate);
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
    if (issuedByController.text.trim().isEmpty) {
      return "Please enter the issuer name.";
    }
    if (!isValidIssueDate) {
      return "Please select a valid issue date.";
    }
    if ((editingCertificateId.value?.isEmpty ?? true) &&
        selectedFile.value == null) {
      return "Upload image file is required.";
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

  String _formatIssueDate() {
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
      final contentType = selectedFile.value != null
          ? getMimeType(selectedFile.value!.path)
          : "application/pdf";
      final payload = {
        "title": titleController.text.trim(),
        "documentType": documentType.value,
        "issuedBy": issuedByController.text.trim(),
        "issueDate": _formatIssueDate(),
        "description": descriptionController.text.trim(),
        if (selectedFile.value != null) "contentType": contentType,
      };

      ResponseModel response;
      if (editingCertificateId.value == null) {
        response = await _repo.addProfessionalCertificateRepo(bodyREQ: payload);
      } else {
        response = await _repo.updateProfessionalCertificateRepo(
            id: editingCertificateId.value!, bodyREQ: payload);
      }

      if (response.isSuccess) {
        if (isImageEdit.value && selectedFile.value != null) {
          final uploadUrl = response.response?.data['uploadUrl'] ?? "";
          if (uploadUrl is String && uploadUrl.isNotEmpty) {
            await ChannelRepo().uploadVideoToS3(
              file: selectedFile.value!,
              fileType: contentType,
              preSignedUrl: uploadUrl,
              onProgress: (sent) {},
            );
          }
        }
        await Get.find<AiProfessionalsController>()
            .professionalsFullDetailsController();

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
          await _repo.deleteProfessionalCertificateRepo(id: certiId);

      if (response.isSuccess) {
        await Get.find<AiProfessionalsController>()
            .professionalsFullDetailsController();
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
}
