import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/personal/resume/controller/current_job_controller.dart';
import 'package:BlueEra/features/personal/resume/controller/experience_controller.dart';
import 'package:BlueEra/features/personal/resume/controller/profile_pic_controller.dart';
import 'package:BlueEra/features/personal/resume/fields/add_current_job.dart';
import 'package:BlueEra/features/personal/resume/fields/add_full_time_exp.dart';
import 'package:BlueEra/features/personal/resume/fields/add_part_time_exp.dart';
import 'package:BlueEra/features/personal/resume/resume_job_section_card.dart';
import 'package:BlueEra/widgets/delete_dialog.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ExperienceSection extends StatefulWidget {
  const ExperienceSection({Key? key}) : super(key: key);
  @override
  State<ExperienceSection> createState() => _ExperienceSectionState();
}

class _ExperienceSectionState extends State<ExperienceSection> {
  // final ResumeController resumeController = Get.put(ResumeController());
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
    return Column(
      children: [
        // Obx(() {
        //   final items = currentJobController.workExperienceList;
        //   return ResumeJobSectionCard(
        //     title: "Current Job",
        //     items: items.toList(),
        //     onAddPressed: items.isEmpty
        //         ? () {
        //             currentJobController.clearAllFields();
        //             Navigator.push(
        //               context,
        //               MaterialPageRoute(
        //                 builder: (_) => AddCurrentJobScreen(isEdit: false),
        //               ),
        //             ).then((_) => getResumeController.getMyResume());
        //           }
        //         : null,
        //     itemsEditCallback: (index) async {
        //       await getResumeController.getMyResume();
        //       if (currentJobController.rawCurrentJobData != null) {
        //         currentJobController.setFieldsFromBackend(
        //             currentJobController.rawCurrentJobData!);
        //       }
        //       Navigator.push(
        //         context,
        //         MaterialPageRoute(
        //             builder: (_) => AddCurrentJobScreen(isEdit: true)),
        //       ).then((_) => getResumeController.getMyResume());
        //     },
        //     itemsDeleteCallback: (index) {
        //       showConfirmDeleteDialog(context, () async {
        //         Navigator.of(context).pop();
        //         await currentJobController.deleteCurrentJob();
        //       });
        //     },
        //   );
        // }),
        Obx(() {
          final items = currentJobController.workExperienceList;
          return ResumeJobSectionCard(
            title: "Current Job",
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
              // await getResumeController.getMyResume();
              final rawJobData = currentJobController.rawCurrentJobData;
              // if (currentJobController.rawCurrentJobData != null) {
              //   currentJobController.setFieldsFromBackend(
              //       currentJobController.rawCurrentJobData!);
              // }
              if (rawJobData != null) {
                currentJobController.setFieldsFromBackend(rawJobData);
              } else {
                // Handle null, possibly show error or fallback
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
            title: "Full-Time Experience",
            items: items,
            onAddPressed: () {
              fullTimeExperienceController.clearAllFields();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddFullTimeExperienceScreen(isEdit: false),
                ),
              ).then((_) => getResumeController.getMyResume());
            },
            itemsEditCallback: (index) {
              final data = experiences[index];
              final id = data['_id'] as String?;
              if (id == null) {
                print("Error: Experience ID not found for editing");
                return;
              }
              fullTimeExperienceController.setFieldsFromData(data);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddFullTimeExperienceScreen(
                      isEdit: true, experienceId: id),
                ),
              ).then((_) => getResumeController.getMyResume());
            },
            itemsDeleteCallback: (index) {
              final data = experiences[index];
              final id = data['_id'] as String?;
              if (id == null) {
                print("Error: Experience ID not found for deletion");
                return;
              }
              showConfirmDeleteDialog(context, () async {
                Navigator.of(context).pop();
                final res =
                    await fullTimeExperienceController.deleteExperience(id: id);
                if (res.isSuccess) {
                  await getResumeController.getMyResume();
                  print("Success: Experience deleted");
                } else {
                  print(
                      "Error: ${res.message ?? "Failed to delete experience"}");
                }
              });
            },
          );
        }),

        SizedBox(height: SizeConfig.size10),

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
            title: "Part-Time Experience",
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
                print("Error: Experience ID not found for editing");
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
                print("Error: Experience ID not found for deletion");
                return;
              }
              showConfirmDeleteDialog(context, () async {
                Navigator.of(context).pop();
                final res =
                    await partTimeExperienceController.deleteExperience(id: id);
                if (res.isSuccess) {
                  await getResumeController.getMyResume();
                  print("Success: Experience deleted");
                } else {
                  print(
                      "Error: ${res.message ?? "Failed to delete experience"}");
                }
              });
            },
          );
        }),

        SizedBox(height: SizeConfig.size10),
      ],
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
