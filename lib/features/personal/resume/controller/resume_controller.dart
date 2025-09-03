import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ResumeController extends GetxController {
  final fullName = ''.obs;
  final email = ''.obs;
  final phone = ''.obs;
  final address = ''.obs;
  final bio = ''.obs;
  final careerObjective = ''.obs;

  
  final salaryDetails = ''.obs;
  
  
  final additionalInfo = ''.obs;
  
  final workExperienceList = <Map<String, String>>[].obs;
  final skillsList = <String>[].obs;
  final portfolioLinks = <Map<String, String>>[].obs;
  final achievementsList = <Map<String, String>>[].obs;
  final certificationsList = <Map<String, dynamic>>[].obs;
  final hobbiesList = <String>[].obs;
  final fullTimeExperienceList = <Map<String, String>>[].obs;
  final partTimeExperienceList = <Map<String, String>>[].obs;
  final languagesList = <String>[].obs;
  final awardsList = <Map<String, String>>[].obs;
  final publicationsList = <Map<String, String>>[].obs;
  final additionalInfoList = <Map<String, String>>[].obs;
  final ngoExperienceList = <Map<String, String>>[].obs;
  final patentsList = <Map<String, String>>[].obs;

  final List<String> sectionChips = [
    "Profile",
    "Education",
    "Experience",
    "About Me",
    "Add More",
  ];
  final RxInt selectedChip = 0.obs;

  final maxLength = 200;
  final bioController = TextEditingController();
  final additionalInfoTitleController = TextEditingController();
  final additionalInfoDescriptionController = TextEditingController();
  final isCurrentJobFormValid = false.obs;


 


  @override
  void onInit() {

    additionalInfoDescriptionController.addListener(() {
      additionalInfo.value = additionalInfoDescriptionController.text;
    });

    // careerObjectiveController.addListener(() {
    //   careerObjective.value = careerObjectiveController.text;
    // });
    // getCareerObjectiveApi();
    super.onInit();
  }

  @override
  void onClose() {
    bioController.dispose();
    // careerObjectiveController.dispose();
    additionalInfoTitleController.dispose();
    additionalInfoDescriptionController.dispose();
    super.onClose();
  }


  void addCareerObjectiveToList(String text) {
    portfolioLinks.removeWhere((item) => item['title'] == 'Career Objective');
    portfolioLinks.add({
      'title': 'Career Objective',
      'subtitle1': text,
    });
  }

  void addAdditionalInfoToList(String title, String description) {
    additionalInfoList.add({
      'title': title,
      'subtitle1': description,
    });
  }

  // Future<void> getCareerObjectiveApi() async {
  //   try {
  //     final response = await _repo.getCareerObjective();
  //     if (response.statusCode == 200 && response.response?.data != null) {
  //       final raw = response.response!.data;
  //       if (raw is Map && raw['careerObjective'] != null) {
  //         careerObjective.value = raw['careerObjective'];
  //       } else if (raw is String) {
  //         careerObjective.value = raw;
  //       }
  //     }
  //   } catch (e) {
  //     print("ERROR: $e");
  //   }
  // }

}
