import 'dart:io';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/api/model/get_resume_data_model.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/me/professionals_consultant/model/professional_profile_res_model.dart';
import 'package:BlueEra/features/personal/resume/controller/profile_pic_controller.dart';
import 'package:BlueEra/features/personal/resume/repo/resume_repo.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class JobSeekerPortfolioProfessionalsController extends GetxController {
  final ResumeRepo _repo = ResumeRepo();

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

  List<PortfolioProject> get certificates {
    final data = Get.find<ProfilePicController>();
    return data.getResumeData.value.portfolioProject ?? [];
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
    selectedCategory.value = cert.category ?? "";
    // issueDate.value = _parseIsoDate(cert.completionDate);
    List<String>? parts = cert.completionDate?.split('-');

    int day = int.parse(parts?[0]??"");
    int month = int.parse(parts?[1]??"");
    int year = int.parse(parts?[2]??"");
    selectedDay = day;
    selectedMonth =month;
    selectedYear = year;
    selectedFile.value = null;
    isImageEdit.value = false;
    editingCertificateId.value = cert.id;
  }

  Future<void> save() async {
    try {
      isSaving.value = true;
      Map<String,dynamic> payload = {
        "title": titleController.text.trim(),
        "category": selectedCategory.value,
        "description": descriptionController.text.trim(),
        "completionDate": "${selectedDay}-${selectedMonth}-$selectedYear"
      };

      ResponseModel response;
      if (editingCertificateId.value == null) {
        response = await _repo.addEntity1(
            params: payload, imagePath: selectedFile.value?.path);
      } else {
        response = await _repo.updateJobPortfolioResume(
            projectID: editingCertificateId.value??"",
            params: payload,
            imagePath: selectedFile.value?.path);
      }
      // [log] RUN TIME TYPE MultipartFile

      if (response.isSuccess) {
        callAPIGetResume();

        commonSnackBar(message: "Saved Successfully");
      } else {
        commonSnackBar(
            message: response.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      logs("ERROR= $e");
      commonSnackBar(message: AppStrings.somethingWentWrong);
    } finally {
      isSaving.value = false;
    }
  }


  ///DELETE NOTICE....
  Future<void> deleteCertificateController({required String certiId}) async {
    try {
      ResponseModel response = await _repo.deleteJobPortfolioResume(certiId);

      if (response.isSuccess) {
        callAPIGetResume();
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
