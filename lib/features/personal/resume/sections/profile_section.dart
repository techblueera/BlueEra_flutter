import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/features/personal/resume/controller/bio_controller.dart';
import 'package:BlueEra/features/personal/resume/controller/current_job_controller.dart';
import 'package:BlueEra/features/personal/resume/controller/profile_pic_controller.dart';
import 'package:BlueEra/features/personal/resume/controller/qualification_contoller.dart';
import 'package:BlueEra/features/personal/resume/controller/salary_controller.dart';
import 'package:BlueEra/features/personal/resume/fields/add_bio_screen.dart';
import 'package:BlueEra/features/personal/resume/fields/add_current_job.dart';
import 'package:BlueEra/features/personal/resume/fields/add_salary_details.dart';
import 'package:BlueEra/features/personal/resume/fields/highest_qualification_screen.dart';
import 'package:BlueEra/features/personal/resume/fields/resume_profile_bio.dart';
import 'package:BlueEra/features/personal/resume/fields/resume_profile_header.dart';
import 'package:BlueEra/features/personal/resume/resume_job_section_card.dart';
import 'package:BlueEra/features/personal/resume/resume_profile_section_card.dart';
import 'package:BlueEra/widgets/delete_dialog.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ProfileSection extends StatefulWidget {
  const ProfileSection({super.key});

  @override
  State<ProfileSection> createState() => _ProfileSectionState();
}

class _ProfileSectionState extends State<ProfileSection> {
  final BioController bioController = Get.put(BioController());
  final QualificationContoller qualificationController =
      Get.put(QualificationContoller());
  final SalaryController salaryController = Get.put(SalaryController());
  final CurrentJobController currentJobController =
      Get.put(CurrentJobController());

  final ProfilePicController getResumeController =
      Get.put(ProfilePicController());

  @override
  void initState() {
    super.initState();
    // getResumeController.getMyResume();
  }

  @override
  Widget build(BuildContext context) {
    // No SizedBox separators between the cards: the header, the bio and every
    // section card below are CommonCardWidgets, which already carry
    // `margin: EdgeInsets.all(10)`, so adjacent cards sit 20dp apart on their
    // own — the old spacers made those gaps 30dp.
    // `stretch` replaces the SizedBox(width: double.infinity) the header
    // needed under `start`, and keeps every card the same width: without it a
    // card whose list is empty (title + Add row only) shrink-wraps and sits
    // narrower than its filled neighbours.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ResumeProfileHeader(),

        /// Bio
        ResumeProfileBio(),

        Obx(() {
          final items = bioController.educationList;
          return ResumeProfileSectionCard(
            title: AppStrings.bio,
            items: items.toList(),
            onAddPressed: items.isEmpty
                ? () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => AddBioScreen()),
                    ).then((_) => getResumeController.getMyResume());
                  }
                : null,
            itemsEditCallback: (index) {
              final currentBio = items[index]['title'] ?? '';
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddBioScreen(initialBio: currentBio),
                ),
              ).then((_) => getResumeController.getMyResume());
            },
            itemsDeleteCallback: (index) {
              showConfirmDeleteDialog(context, () async {
                Navigator.of(context).pop();
                await bioController.deleteBio();
              });
            },
          );
        }),

        Obx(() {
          final items = qualificationController.educationList;
          return ResumeProfileSectionCard(
            title: AppStrings.highestQualification,
            items: items.toList(),
            onAddPressed: items.isEmpty
                ? () {
                    qualificationController.clearAll();
                    qualificationController.editReset();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => HighestQualificationScreen(),
                      ),
                    ).then((_) => getResumeController.getMyResume());
                  }
                : null,
            itemsEditCallback: (index) {
              final item = items[index];
              qualificationController.setEditFieldsFromCard(item);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => HighestQualificationScreen(
                    isEdit: true,
                    itemId: item['_id'] ?? '',
                  ),
                ),
              ).then((_) {
                qualificationController
                    .editReset(); // Clear edit state after returning
                getResumeController.getMyResume();
              });
            },
            itemsDeleteCallback: (index) {
              final itemId = items[index]['_id'];
              showConfirmDeleteDialog(context, () async {
                Navigator.of(context).pop(); // Close the dialog
                await qualificationController.deleteEducation(itemId);
              });
            },
            titleColor: AppColors.black28,
          );
        }),

        Obx(() {
          final items = salaryController.workExperienceList;

          final updatedItems = items.map((item) {
            final annualPackageStr = item['annualPackage'] ?? '0';
            final formattedAnnualPackage = "₹ $annualPackageStr LPA";
            return {
              ...item,
              'title': formattedAnnualPackage,
            };
          }).toList();

          return ResumeProfileSectionCard(
            title: AppStrings.salaryDetails,
            items: updatedItems,
            onAddPressed: items.isEmpty
                ? () {
                    salaryController.clearSalaryFields();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              AddSalaryDetailsScreen(isEdit: false)),
                    ).then((_) => getResumeController.getMyResume());
                  }
                : null,
            itemsEditCallback: (index) {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => AddSalaryDetailsScreen(isEdit: true)),
              ).then((_) => getResumeController.getMyResume());
            },
            itemsDeleteCallback: (index) {
              showConfirmDeleteDialog(context, () async {
                Navigator.pop(context);
                await salaryController.deleteSalary();
              });
            },
          );
        }),

        Obx(() {
          final items = currentJobController.workExperienceList;
          return ResumeJobSectionCard(
            title: AppStrings.currentJob,
            items: items.toList(),
            onAddPressed: items.isEmpty
                ? () {
                    currentJobController.clearAllFields();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddCurrentJobScreen(isEdit: false),
                      ),
                    ).then((_) => getResumeController.getMyResume());
                  }
                : null,
            itemsEditCallback: (index) async {
              final rawJobData = currentJobController.rawCurrentJobData;

              if (rawJobData != null) {
                currentJobController.setFieldsFromBackend(rawJobData);
              }
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => AddCurrentJobScreen(
                          isEdit: true,
                          jobData: rawJobData,
                        )),
              ).then((_) => getResumeController.getMyResume());
            },
            itemsDeleteCallback: (index) {
              showConfirmDeleteDialog(context, () async {
                Navigator.of(context).pop();
                await currentJobController.deleteCurrentJob();
              });
            },
          );
        }),
      ],
    );
  }
}
