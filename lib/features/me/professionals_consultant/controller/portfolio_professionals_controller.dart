import 'dart:io';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/common/Discover/model/profe_cons_res_model.dart';
import 'package:BlueEra/features/common/reel/repo/channel_repo.dart';
import 'package:BlueEra/features/me/professionals_consultant/controller/ai_professionals_controller.dart';
import 'package:BlueEra/features/me/professionals_consultant/model/professional_profile_res_model.dart';
import 'package:BlueEra/features/me/professionals_consultant/repo/professionals_repo.dart';
import 'package:BlueEra/features/me/school/repo/upload_file_to_s3.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PortfolioProfessionalsController extends GetxController {
  final ProfessionalsRepo _repo = ProfessionalsRepo();
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final description = "".obs;
  final issueDate = Rxn<DateTime>();
  final selectedFile = Rxn<File>();
  final isImageEdit = false.obs;
  final isSaving = false.obs;
  final editingCertificateId = RxnString();
  int? selectedDay, selectedMonth, selectedYear;
  final List<String> categoryList = [
    "Project",
    "Portfolio",
    "Case Study",
    "Web Design",
    "UI/UX",
    "Mobile App",
    "SaaS",
    "E-commerce",
    "Branding",
    "Graphic Design",
    "Product Design",
    "Frontend",
    "Backend",
    "Full Stack",
    "API",
    "Dashboard",
    "Data Visualization",
    "AI/ML",
    "DevOps",
    "Cloud",
    "Open Source",
    "Research",
    "Prototype",
    "MVP",
    "Performance Optimization",
    "Accessibility",
    "Security",
    "Automation",
    "Other"
  ];

  var selectedCategory = "".obs;

  RxString docUploadName = ''.obs;
  // final Rxn<File> noticeImageFile = Rxn<File>();
  String initialNoticeImageUrl = "";

  List<Certificates> get certificates {
    final ai = Get.find<AiProfessionalsController>();
    return ai.getProfessionalServiceRes?.value.data?.certificates ?? [];
  }

  void openForCreate() {
    titleController.clear();
    descriptionController.clear();
    issueDate.value = null;
    selectedFile.value = null;
    isImageEdit.value = false;
    editingCertificateId.value = null;
    selectedDay = null;
    selectedMonth = null;
    selectedYear = null;
    selectedCategory.value = "";
  }

  void openForEdit(ProfessionalPortfolio cert) {
    titleController.text = cert.projectTitle ?? "";
    descriptionController.text = cert.description ?? "";
    selectedCategory.value = cert.category??"";
    issueDate.value = _parseIsoDate(cert.completionDate);

    selectedDay = issueDate.value?.day;
    selectedMonth = issueDate.value?.month;
    selectedYear = issueDate.value?.year;
    selectedFile.value = null;
    isImageEdit.value = false;
    editingCertificateId.value = cert.id;
  }

  Future<void> save() async {
    try {
      isSaving.value = true;
      final contentType = selectedFile.value != null
          ? getMimeType(selectedFile.value!.path)
          : "application/pdf";

      dynamic dataList = [
        {"type": "image", "contentType": contentType}
      ];
      final payload = {
        "projectTitle": titleController.text.trim(),
        "category": selectedCategory.value,
        "description": descriptionController.text.trim(),
        "completionDate": "${selectedDay}-${selectedMonth}-$selectedYear",
        if (selectedFile.value != null) "media": dataList,
      };

      ResponseModel response;
      if (editingCertificateId.value == null) {
        response = await _repo.addProfessionalsPortfolioRepo(bodyREQ: payload);
      } else {
        response = await _repo.updateProfessionalsPortfolioRepo(
            id: editingCertificateId.value!, bodyREQ: payload);
      }

      if (response.isSuccess) {
        if (docUploadName.value.isNotEmpty && selectedFile.value != null) {
          final uploadUrl = response.response?.data['uploadUrls'][0] ?? "";
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
      } else {
        commonSnackBar(
            message: response.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      commonSnackBar(message: AppStrings.somethingWentWrong);
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
          await _repo.deleteProfessionalsPortfolioRepo(id: certiId);

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
