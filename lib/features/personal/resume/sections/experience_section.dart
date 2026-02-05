import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/features/personal/resume/controller/current_job_controller.dart';
import 'package:BlueEra/features/personal/resume/controller/experience_controller.dart';
import 'package:BlueEra/features/personal/resume/controller/profile_pic_controller.dart';
import 'package:BlueEra/features/personal/resume/fields/add_full_time_exp.dart';
import 'package:BlueEra/features/personal/resume/resume_job_section_card.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/delete_dialog.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ExperienceSection extends StatefulWidget {
  const ExperienceSection({Key? key}) : super(key: key);
  @override
  State<ExperienceSection> createState() => _ExperienceSectionState();
}

class _ExperienceSectionState extends State<ExperienceSection> {
  final ExperienceController fullTimeExperienceController =
      Get.put(ExperienceController(isFullTime: true), tag: 'fullTime');

  final ExperienceController partTimeExperienceController =
      Get.put(ExperienceController(isFullTime: false), tag: 'partTime');
  final CurrentJobController currentJobController =
      Get.put(CurrentJobController());
  final getResumeController = Get.find<ProfilePicController>();

  @override
  void initState() {
    super.initState();
    getResumeController.getMyResume();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(title: AppStrings.experience,),
      body: Column(
        children: [

          /// Full-Time Experience Section
          Obx(() {
            final experiences = fullTimeExperienceController.experienceList;

            final items = experiences.map((e) {
              String startLabel = '';
              String endLabel = '';
              if (e['startDate'] != null &&
                  e['startDate']['month'] != null &&
                  e['startDate']['year'] != null) {
                startLabel =
                '${monthNameShort(e['startDate']['month'])}, ${e['startDate']['year']}';
              }
              if (e['endDate'] != null &&
                  e['endDate']['month'] != null &&
                  e['endDate']['year'] != null) {
                endLabel =
                '${monthNameShort(e['endDate']['month'])}, ${e['endDate']['year']}';
              }
              return {
                'startLabel': startLabel,
                'endLabel': endLabel,
                'designation': e['designation'] ?? '',
                'companyRow':
                '${e['previousCompanyName'] ?? ''}${e['jobType'] != null ? ', ${e['jobType']}' : ''}',
                'locationRow':
                '${e['location'] ?? ''}${e['workMode'] != null ? ' - ${e['workMode']}' : ''}',
                'description': e['description'] ?? '',
              };
            }).toList();

            return ResumeJobSectionCard(
              title: "",
              // title: AppStrings.fullTimeExperience,
              items: items,
              onAddPressed: () {
                fullTimeExperienceController.clearAllFields();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddFullTimeExperienceScreen(isEdit: false),
                  ),
                );
              },
              itemsEditCallback: (index) {
                final data = experiences[index];
                final id = data['_id'] as String?;
                if (id == null) {
                  return;
                }
                fullTimeExperienceController.setFieldsFromData(data);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddFullTimeExperienceScreen(
                        isEdit: true, experienceId: id),
                  ),
                );
              },
              itemsDeleteCallback: (index) {
                final data = experiences[index];
                final id = data['_id'] as String?;
                if (id == null) {
                  return;
                }
                showConfirmDeleteDialog(context, () async {
                  Navigator.of(context).pop();
                  final res =
                  await fullTimeExperienceController.deleteExperience(id: id);

                });
              },
            );
          }),

       /*   Obx(() {
            final items = currentJobController.workExperienceList;
            return ResumeJobSectionCard(
              title:AppStrings.currentJob,
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

          SizedBox(height: SizeConfig.size10),
*/


       /*   SizedBox(height: SizeConfig.size10),

          Obx(() {
            final experiences = partTimeExperienceController.experienceList;
            final items = experiences.map((e) {
              String startLabel = '';
              String endLabel = '';
              if (e['startDate'] != null &&
                  e['startDate']['month'] != null &&
                  e['startDate']['year'] != null) {
                startLabel =
                    '${monthNameShort(e['startDate']['month'])}, ${e['startDate']['year']}';
              }
              if (e['endDate'] != null &&
                  e['endDate']['month'] != null &&
                  e['endDate']['year'] != null) {
                endLabel =
                    '${monthNameShort(e['endDate']['month'])}, ${e['endDate']['year']}';
              }
              return {
                'startLabel': startLabel,
                'endLabel': endLabel,
                'designation': e['designation'] ?? '',
                'companyRow':
                    '${e['previousCompanyName'] ?? ''}${e['jobType'] != null ? ', ${e['jobType']}' : ''}',
                'locationRow':
                    '${e['location'] ?? ''}${e['workMode'] != null ? ' - ${e['workMode']}' : ''}',
                'description': e['description'] ?? '',
              };
            }).toList();

            return ResumeJobSectionCard(
              title: AppStrings.partTimeExperience,
              items: items,
              onAddPressed: () {
                partTimeExperienceController.clearAllFields();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddPartTimeExperienceScreen(isEdit: false),
                  ),
                ).then((_) => getResumeController.getMyResume());
              },
              itemsEditCallback: (index) {
                final data = experiences[index];
                final id = data['_id'] as String?;
                if (id == null) {
                  return;
                }
                partTimeExperienceController.setFieldsFromData(data);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddPartTimeExperienceScreen(
                        isEdit: true, experienceId: id),
                  ),
                ).then((_) => getResumeController.getMyResume());
              },
              itemsDeleteCallback: (index) {
                final data = experiences[index];
                final id = data['_id'] as String?;
                if (id == null) {
                  return;
                }
                showConfirmDeleteDialog(context, () async {
                  Navigator.of(context).pop();
                  final res =
                      await partTimeExperienceController.deleteExperience(id: id);
                  if (res.isSuccess) {
                    await getResumeController.getMyResume();
                  }
                });
              },
            );
          }),

          SizedBox(height: SizeConfig.size10),*/
        ],
      ),
    );
  }
}

String monthNameShort(int month) {
  const months = [
    '',
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec'
  ];
  return months[month];
}
