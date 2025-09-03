import 'dart:io';

import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/api/model/get_resume_data_model.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/personal/resume/controller/achievements_controller.dart';
import 'package:BlueEra/features/personal/resume/controller/add_career_obj_controller.dart';
import 'package:BlueEra/features/personal/resume/controller/add_more_controller.dart';
import 'package:BlueEra/features/personal/resume/controller/additional_info_controller.dart';
import 'package:BlueEra/features/personal/resume/controller/awards_controller.dart';
import 'package:BlueEra/features/personal/resume/controller/bio_controller.dart';
import 'package:BlueEra/features/personal/resume/controller/certifications_controller.dart';
import 'package:BlueEra/features/personal/resume/controller/current_job_controller.dart';
import 'package:BlueEra/features/personal/resume/controller/education_controller.dart';
import 'package:BlueEra/features/personal/resume/controller/experience_controller.dart';
import 'package:BlueEra/features/personal/resume/controller/hobbies_controller.dart';
import 'package:BlueEra/features/personal/resume/controller/languages_controller.dart';
import 'package:BlueEra/features/personal/resume/controller/portfolio_controller.dart';
import 'package:BlueEra/features/personal/resume/controller/publications_controller.dart';
import 'package:BlueEra/features/personal/resume/controller/qualification_contoller.dart';
import 'package:BlueEra/features/personal/resume/controller/salary_controller.dart';
import 'package:BlueEra/features/personal/resume/controller/skills_controller.dart';
import 'package:BlueEra/features/personal/resume/repo/resume_repo.dart';
import 'package:get/get.dart';

class ProfilePicController extends GetxController {
  var isLoading = false.obs;

  final profilePic = ''.obs;
  Rx<ApiResponse> getSelfResumeResponse = ApiResponse.initial('Initial').obs;
  Rx<GetResumeDataModel> getResumeData = GetResumeDataModel().obs;

  Future getMyResume() async {
    try {
      getSelfResumeResponse.value = ApiResponse.initial('Initial');

      print("Fetching resume data...");
      ResponseModel response = await ResumeRepo().getResumeData();
      print("Raw response data: ${response.response?.data}");

      if (response.isSuccess) {
        final model = GetResumeDataModel.fromJson(response.response?.data);
        getResumeData.value = model;
        getSelfResumeResponse.value = ApiResponse.complete(response);
        _updateBioController(getResumeData.value);
        _updateQualificationController(getResumeData.value);
        _updateSalaryController(model);
        _updateCurrentJobController(model);
        _updateEducationController(model);
        _updateFullTimeExperienceController(model);
        _updatePartTimeExperienceController(model);
        _updateSkillsController(model);

        _updateLanguagesController(model);

        _updateCareerObjectiveController(model);

        _updatePortfolioController(model);
        _updateAwardsController(model);
        _updateAchievementsController(model);
        _updateCertificationsController(model);
        _updatePublicationsController(model);
        _updateHobbiesController(model);
        _updateAdditionalInfoController(model);
        _updateNgoOrgsController(model);
        _updatePatentsController(model);
      } else {
        print("API call failed with status: ${response.statusCode}");
        commonSnackBar(message: AppStrings.somethingWentWrong);
        getSelfResumeResponse.value = ApiResponse.error('error');
      }
    } catch (e, st) {
      print("Error fetching resume: $e");
      print(st);
      getSelfResumeResponse.value = ApiResponse.error('error');
    }
  }

  ///PROFILE PICTURE
  Future<void> updateProfilePic(File imageFile) async {
    try {
      final res = await ResumeRepo().editProfilePicWithFile(imageFile);
      if (res.isSuccess) {
        final newUrl = res.response?.data['profilePicture'];
        if (newUrl != null && newUrl.isNotEmpty) {
          profilePic.value = newUrl;
        }

        commonSnackBar(
            message:
                res.response?.data['message'] ?? "Profile picture updated");
      } else {
        commonSnackBar(
            message: res.message ?? "Failed to update profile picture");
      }
    } catch (e) {
      commonSnackBar(message: "Error uploading profile picture");
    }
  }

  /// Profile Bio
  Future<void> updateProfileDetails({
    required String name,
    required String email,
    required String phone,
    required String location,
  }) async {
    isLoading.value = true;
    final params = {
      'name': name,
      'email': email,
      'phone': phone,
      'location': location,
    };
    final response = await ResumeRepo().updateProfile(params);
    isLoading.value = false;

    if (response.isSuccess) {
      await getMyResume(); 
      Get.back();
      commonSnackBar(message: "Personal details updated");
    } else {
      commonSnackBar(message: response.message ?? "Failed to update details");
    }
  }

  ///BIO DATA
  void _updateBioController(GetResumeDataModel data) {
    try {
      final BioController bioController = Get.find<BioController>();
      if (data.bio != null && data.bio!.trim().isNotEmpty) {
        bioController.bio.value = data.bio!;
        bioController.educationList.clear();
        bioController.educationList.add({'title': data.bio!});
      } else {
        bioController.bio.value = '';
        bioController.educationList.clear();
      }
    } catch (e) {
      print('Error updating controllers with resume data: $e');
    }
  }

  /// QUALIFICATION DATA
  void _updateQualificationController(GetResumeDataModel data) {
    try {
      final qualificationController = Get.find<QualificationContoller>();

      qualificationController.educationList.clear();

      if (data.education != null && data.education!.isNotEmpty) {
        print("Number of education entries: ${data.education!.length}");

        for (final edu in data.education!) {
          final hasData = (edu.highestQualification != null &&
                  edu.highestQualification!.trim().isNotEmpty) ||
              (edu.schoolOrCollegeName != null &&
                  edu.schoolOrCollegeName!.trim().isNotEmpty);

          if (!hasData) {
            print("Skipping incomplete education entry with id: ${edu.id}");
            continue; // Skip incomplete entries with no visible data
          }

          print("Adding education entry: ${edu.toJson()}");

          qualificationController.educationList.add({
            'title': edu.highestQualification ?? '',
            'subtitle1': edu.schoolOrCollegeName ?? '',
            'subtitle2': 'Passing Year: ${edu.passingYear ?? ""}',
            'subtitle3': 'Percentage: ${edu.percentage ?? ""}',
            'trailing': edu.boardName ?? '',
            '_id': edu.id ?? '',
          });
        }
      } else {
        print("No education entries found.");
      }
    } catch (e) {
      print('Error updating QualificationController: $e');
    }
  }

  ///SALRY DATA

  void _updateSalaryController(GetResumeDataModel model) {
    try {
      final salaryController = Get.find<SalaryController>();
      salaryController.setSalaryDetails(model.salaryDetails);
    } catch (e) {
      print("Error updating SalaryController: $e");
    }
  }

  ///CURRENT JOB DATA

  void _updateCurrentJobController(GetResumeDataModel data) {
    try {
      final currentJobController = Get.find<CurrentJobController>();
      currentJobController.setCurrentJobFromModel(data.currentJob);
    } catch (e) {
      print("Error updating CurrentJobController: $e");
    }
  }

  ///EDUCATION DATA
  void _updateEducationController(GetResumeDataModel model) {
    try {
      final educationController = Get.find<EducationController>();
      educationController.setEducationListFromModel(model.education);
    } catch (e) {
      print("Error updating EducationController: $e");
    }
  }

  ///experiencedata
  void _updateFullTimeExperienceController(GetResumeDataModel data) {
    try {
      final fullTimeExperienceController =
          Get.find<ExperienceController>(tag: 'fullTime');
      fullTimeExperienceController
          .setExperienceListFromModel(data.fullTimeExperience);
    } catch (e) {
      print("Error updating FullTimeExperienceController: $e");
    }
  }

  void _updatePartTimeExperienceController(GetResumeDataModel data) {
    try {
      final partTimeExperienceController =
          Get.find<ExperienceController>(tag: 'partTime');
      partTimeExperienceController
          .setExperienceListFromModel(data.partTimeExperience);
    } catch (e) {
      print("Error updating PartTimeExperienceController: $e");
    }
  }

  ///SKILLS
  void _updateSkillsController(GetResumeDataModel data) {
    try {
      final skillsController = Get.find<SkillsController>();
      skillsController.setSkillsFromModel(data.skills);
    } catch (e) {
      print('Error updating SkillsController: $e');
    }
  }

  ///LANGUAGE
  void _updateLanguagesController(GetResumeDataModel data) {
    try {
      final LanguagesController langController =
          Get.find<LanguagesController>();

      // Extract first item from languages list (as per your JSON)
      final langData = data.languages?.first;

      if (langData != null) {
        final speakList = langData.speakAndUnderstand ?? [];
        final writeList = langData.write ?? [];

        langController.speakLanguages.clear();
        langController.writeLanguages.clear();

        langController.speakLanguages.addAll(speakList.map((e) =>
            LanguageType.values.firstWhere((l) => l.label == e,
                orElse: () => LanguageType.english)));

        langController.writeLanguages.addAll(writeList.map((e) =>
            LanguageType.values.firstWhere((l) => l.label == e,
                orElse: () => LanguageType.english)));

        langController.isFirstTime.value =
            (speakList.isEmpty && writeList.isEmpty);
      }
    } catch (e) {
      print('Error updating LanguagesController: $e');
    }
  }

  ///CAREER OBJECTIVE
  void _updateCareerObjectiveController(GetResumeDataModel data) {
    try {
      final careerController = Get.find<CareerObjectiveController>();
      final objective = data.careerObjective ?? '';
      careerController.careerObjective.value = objective;
      // Optionally update TextEditingController text:
      careerController.careerObjectiveController.text = objective;
    } catch (e) {
      print('Error updating Career Objective: $e');
    }
  }

  ///PORTFOLIO
  void _updatePortfolioController(GetResumeDataModel data) {
    try {
      final portfolioController = Get.find<PortfolioController>();

      // Clear existing links first
      portfolioController.portfolioLinks.clear();

      if (data.portfolios != null && data.portfolios!.isNotEmpty) {
        // Add new links from data
        portfolioController.portfolioLinks.addAll(data.portfolios!);
      }

      // Run validation or other updates if necessary
      portfolioController.validateForm();
    } catch (e) {
      print('Error updating PortfolioController: $e');
    }
  }

  ///AWARDS
  void _updateAwardsController(GetResumeDataModel data) {
    try {
      final awardsController = Get.find<AwardsController>();

      if (data.awards != null && data.awards!.isNotEmpty) {
        final mappedAwards = data.awards!.map((award) {
          // Provide issuedDate as Map for the Obx card widget's legacy parser
          Map<String, dynamic>? issuedDateMap;
          if (award.issuedDate != null) {
            issuedDateMap = {
              'date': award.issuedDate?.date,
              'month': award.issuedDate?.month,
              'year': award.issuedDate?.year,
            };
          } else {
            issuedDateMap = null;
          }

          // Always assign attachment in same format as backend/model
          dynamic attachmentRaw = award.attachment;

          return {
            'title': award.title ?? '',
            'issuedBy': award.issuedBy ?? '',
            'description': award.description ?? '',
            'attachment': attachmentRaw, // SAME format as model
            'issuedDate': issuedDateMap, // ALWAYS a map or null
            '_id': award.id,
            'raw': award.toJson(),
          };
        }).toList();

        awardsController.awards.assignAll(mappedAwards);
      } else {
        awardsController.awards.clear();
      }
    } catch (e) {
      print('Error updating AwardsController: $e');
    }
  }

  ///ACHIEVEMENTS
  void _updateAchievementsController(GetResumeDataModel data) {
    try {
      final achievementsController = Get.find<AchievementsController>();

      if (data.achievements != null && data.achievements!.isNotEmpty) {
        final mappedAchievements = data.achievements!.map((a) {
          // Build achieveDate Map for legacy UI compatibility
          Map<String, dynamic>? achieveDateMap;
          if (a.achieveDate != null) {
            achieveDateMap = {
              'date': a.achieveDate?.date,
              'month': a.achieveDate?.month,
              'year': a.achieveDate?.year,
            };
          } else {
            achieveDateMap = null;
          }

          String formattedDate = '';
          if (achieveDateMap != null) {
            final int? month = achieveDateMap['month'] is int
                ? achieveDateMap['month']
                : int.tryParse(achieveDateMap['month']?.toString() ?? "");
            final int? year = achieveDateMap['year'] is int
                ? achieveDateMap['year']
                : int.tryParse(achieveDateMap['year']?.toString() ?? "");
            const months = [
              '',
              'January',
              'February',
              'March',
              'April',
              'May',
              'June',
              'July',
              'August',
              'September',
              'October',
              'November',
              'December'
            ];
            if (month != null &&
                year != null &&
                month > 0 &&
                month < months.length) {
              formattedDate = '${months[month]} $year';
            } else if (year != null) {
              formattedDate = '$year';
            }
          }

          dynamic attachmentRaw = a.attachment;
          List<String> document = [];
          if (attachmentRaw is String && attachmentRaw.isNotEmpty) {
            document = [attachmentRaw];
          } else if (attachmentRaw is List && attachmentRaw.isNotEmpty) {
            if (attachmentRaw.first is String &&
                (attachmentRaw.first as String).isNotEmpty) {
              document = [attachmentRaw.first];
            }
          }

          return {
            '_id': a.id,
            'title': a.title ?? '',
            'subtitle1': formattedDate,
            'subtitle2': a.description ?? '',
            'achieveDate': achieveDateMap,
            'attachment': attachmentRaw,
            'document': document,
            'raw': a.toJson(),
          };
        }).toList();

        achievementsController.achievementsList.assignAll(mappedAchievements);
      } else {
        achievementsController.achievementsList.clear();
      }
    } catch (e) {
      print('Error updating AchievementsController: $e');
    }
  }

  ///CERTIFIACTION
  void _updateCertificationsController(GetResumeDataModel data) {
    try {
      final certificationsController = Get.find<CertificationsController>();

      if (data.certifications != null && data.certifications!.isNotEmpty) {
        final mappedCerts = data.certifications!.map((cert) {
          // Prepare certificateDate as Map<String, dynamic> for UI
          Map<String, dynamic>? certDateMap;
          if (cert.certificateDate != null) {
            certDateMap = {
              'date': cert.certificateDate?.date,
              'month': cert.certificateDate?.month,
              'year': cert.certificateDate?.year,
            };
          } else {
            certDateMap = null;
          }

          // Format the MONTH YEAR for subtitle
          String formattedMonthYear = '';
          if (certDateMap != null) {
            final m = certDateMap['month'];
            final y = certDateMap['year'];
            const months = [
              '',
              'January',
              'February',
              'March',
              'April',
              'May',
              'June',
              'July',
              'August',
              'September',
              'October',
              'November',
              'December'
            ];
            int? month = m is int ? m : int.tryParse(m?.toString() ?? "");
            int? year = y is int ? y : int.tryParse(y?.toString() ?? "");
            if (month != null &&
                year != null &&
                month > 0 &&
                month < months.length) {
              formattedMonthYear = '${months[month]} $year';
            } else if (year != null) {
              formattedMonthYear = '$year';
            }
          }

          // Document as List<String>
          List<String> doc = [];
          final certAtt = cert.certificateAttachment;
          if (certAtt != null && certAtt.isNotEmpty) {
            doc = [certAtt];
          }

          // Compose subtitle: "Org, Month Year"
          final org = cert.issuingOrg ?? '';
          String subtitle1 = '';
          if (org.isNotEmpty && formattedMonthYear.isNotEmpty) {
            subtitle1 = '$org, $formattedMonthYear';
          } else if (org.isNotEmpty) {
            subtitle1 = org;
          } else if (formattedMonthYear.isNotEmpty) {
            subtitle1 = formattedMonthYear;
          }

          return {
            '_id': cert.id,
            'title': cert.title ?? '',
            'subtitle1': subtitle1,
            'document': doc,
            'issuingOrg': cert.issuingOrg ?? '',
            'certificateDate': certDateMap,
            'certificateAttachmentRaw': certAtt ?? '',
            'raw': cert.toJson(),
          };
        }).toList();

        certificationsController.certificationsList.assignAll(mappedCerts);
      } else {
        certificationsController.certificationsList.clear();
      }
    } catch (e) {
      print('Error updating CertificationsController: $e');
    }
  }

  ///PUBLICATIONS
  void _updatePublicationsController(GetResumeDataModel data) {
    try {
      final publicationsController = Get.find<PublicationsController>();

      if (data.publications != null && data.publications!.isNotEmpty) {
        final mappedPubs = data.publications!.map((p) {
          // Prepare publishedDate as Map<String, dynamic> for widget compatibility
          Map<String, dynamic>? pubDateMap;
          if (p.publishedDate != null) {
            pubDateMap = {
              'date': p.publishedDate?.date,
              'month': p.publishedDate?.month,
              'year': p.publishedDate?.year,
            };
          } else {
            pubDateMap = null;
          }

          return {
            '_id': p.id,
            'title': p.title ?? '',
            'link': p.link ?? '',
            'description': p.description ?? '',
            'publishedDate': pubDateMap,
            'raw': p.toJson(),
          };
        }).toList();

        publicationsController.publications.assignAll(mappedPubs);
      } else {
        publicationsController.publications.clear();
      }
    } catch (e) {
      print('Error updating PublicationsController: $e');
    }
  }

  /// HOBBIES
  void _updateHobbiesController(GetResumeDataModel data) {
    try {
      final hobbiesController = Get.find<HobbiesController>();

      // Your "hobbies" model is List<Hobbies> in GetResumeDataModel
      if (data.hobbies != null && data.hobbies!.isNotEmpty) {
        final mappedHobbies = data.hobbies!.map((hobby) {
          return {
            "_id": hobby.id ?? "",
            "name": hobby.name ?? "",
            "description": hobby.description ?? ""
          };
        }).toList();

        hobbiesController.hobbies.assignAll(mappedHobbies);
      } else {
        hobbiesController.hobbies.clear();
      }
      hobbiesController.validateForm();
    } catch (e) {
      print('Error updating HobbiesController: $e');
    }
  }

  ///ADDTIONAL INFORMATION
  void _updateAdditionalInfoController(GetResumeDataModel data) {
    try {
      final additionalInfoController = Get.find<AdditionalInfoController>();

      if (data.additionalInformation != null &&
          data.additionalInformation!.isNotEmpty) {
        final mappedAdditionalInfos = data.additionalInformation!.map((info) {
          // Format the date as "d/m/y" string for subtitle1
          String formattedDate = '';
          if (info.infoDate != null) {
            final day = info.infoDate?.date?.toString() ?? '';
            final month = info.infoDate?.month?.toString() ?? '';
            final year = info.infoDate?.year?.toString() ?? '';
            if (day.isNotEmpty && month.isNotEmpty && year.isNotEmpty) {
              formattedDate = '$day/$month/$year';
            }
          }
          // Document as List<String> (empty if no photoURL)
          List<String> doc = [];
          if (info.photoURL != null && info.photoURL!.isNotEmpty) {
            doc = [info.photoURL!];
          }

          return {
            '_id': info.id ?? '',
            'title': info.title ?? '',
            'subtitle1': formattedDate,
            'subtitle2': info.info ?? '',
            'subtitle3': info.additionalDesc ?? '',
            'document': doc,
            // Keep original infoDate and photoURL etc. for editing, if needed later:
            'infoDate': info.infoDate != null
                ? {
                    'date': info.infoDate?.date,
                    'month': info.infoDate?.month,
                    'year': info.infoDate?.year,
                  }
                : null,
            'photoURL': info.photoURL ?? '',
            'raw': info.toJson(),
          };
        }).toList();

        additionalInfoController.additionalInfoList
            .assignAll(mappedAdditionalInfos);
      } else {
        additionalInfoController.additionalInfoList.clear();
      }
    } catch (e) {
      print('Error updating AdditionalInfoController: $e');
    }
  }

  /// NGO & PATENT
  void _updateNgoOrgsController(GetResumeDataModel data) {
    try {
      final ngoController = Get.find<EntityController>(
          tag: 'ngo'); // tag if you're using separate GetxControllers

      if (data.ngoOrStudentOrgs != null && data.ngoOrStudentOrgs!.isNotEmpty) {
        final mappedNgo = data.ngoOrStudentOrgs!.map((ngo) {
          // Format date dd/mm/yyyy for subtitle1
          String formattedDate = '';
          if (ngo.certifiedDate != null) {
            final d = ngo.certifiedDate?.date?.toString() ?? '';
            final m = ngo.certifiedDate?.month?.toString() ?? '';
            final y = ngo.certifiedDate?.year?.toString() ?? '';
            if (d.isNotEmpty && m.isNotEmpty && y.isNotEmpty) {
              formattedDate = '$d/$m/$y';
            }
          }
          // Prepare document list (for image)
          List<String> doc = [];
          if (ngo.attachment != null && ngo.attachment!.isNotEmpty) {
            doc = [ngo.attachment!];
          }
          return {
            '_id': ngo.id ?? '',
            'title': ngo.title ?? '',
            'subtitle1': formattedDate,
            'subtitle2': ngo.description ?? '',
            'document': doc,
            'certifiedDate': ngo.certifiedDate != null
                ? {
                    'date': ngo.certifiedDate?.date,
                    'month': ngo.certifiedDate?.month,
                    'year': ngo.certifiedDate?.year,
                  }
                : null,
            'attachment': ngo.attachment ?? '',
            'raw': ngo.toJson(),
          };
        }).toList();

        ngoController.entityList.assignAll(mappedNgo);
      } else {
        ngoController.entityList.clear();
      }
    } catch (e) {
      print('Error updating NgoOrgsController: $e');
    }
  }

  void _updatePatentsController(GetResumeDataModel data) {
    try {
      final patentController = Get.find<EntityController>(tag: 'patent');

      if (data.patents != null && data.patents!.isNotEmpty) {
        final mappedPatents = data.patents!.map((patent) {
          // Format issuedDate dd/mm/yyyy for subtitle1
          String formattedDate = '';
          if (patent.issuedDate != null) {
            final d = patent.issuedDate?.date?.toString() ?? '';
            final m = patent.issuedDate?.month?.toString() ?? '';
            final y = patent.issuedDate?.year?.toString() ?? '';
            if (d.isNotEmpty && m.isNotEmpty && y.isNotEmpty) {
              formattedDate = '$d/$m/$y';
            }
          }
          List<String> doc = [];
          if (patent.patentCertification != null &&
              patent.patentCertification!.isNotEmpty) {
            doc = [patent.patentCertification!];
          }
          return {
            '_id': patent.id ?? '',
            'title': patent.title ?? '',
            'subtitle1': formattedDate,
            'subtitle2': patent.description ?? '',
            'document': doc,
            'issuedDate': patent.issuedDate != null
                ? {
                    'date': patent.issuedDate?.date,
                    'month': patent.issuedDate?.month,
                    'year': patent.issuedDate?.year,
                  }
                : null,
            'patentCertification': patent.patentCertification ?? '',
            'raw': patent.toJson(),
          };
        }).toList();

        patentController.entityList.assignAll(mappedPatents);
      } else {
        patentController.entityList.clear();
      }
    } catch (e) {
      print('Error updating PatentsController: $e');
    }
  }
}
