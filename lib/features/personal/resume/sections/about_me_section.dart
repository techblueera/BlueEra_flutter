import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/personal/resume/add_achievement_screen.dart';
import 'package:BlueEra/features/personal/resume/certificate_screen.dart';
import 'package:BlueEra/features/personal/resume/controller/achievements_controller.dart';
import 'package:BlueEra/features/personal/resume/controller/add_career_obj_controller.dart';
import 'package:BlueEra/features/personal/resume/controller/certifications_controller.dart';
import 'package:BlueEra/features/personal/resume/controller/hobbies_controller.dart';
import 'package:BlueEra/features/personal/resume/controller/portfolio_controller.dart';
import 'package:BlueEra/features/personal/resume/controller/profile_pic_controller.dart';
import 'package:BlueEra/features/personal/resume/controller/resume_controller.dart';
import 'package:BlueEra/features/personal/resume/fields/add_awards_screen.dart';
import 'package:BlueEra/features/personal/resume/fields/add_career_obj.dart';
import 'package:BlueEra/features/personal/resume/fields/add_language_screen.dart';
import 'package:BlueEra/features/personal/resume/fields/add_publishing_screen.dart';
import 'package:BlueEra/features/personal/resume/hobbies_screen.dart';
import 'package:BlueEra/features/personal/resume/portfolio_screen.dart';
import 'package:BlueEra/features/personal/resume/resume_profile_section_card.dart';
import 'package:BlueEra/features/personal/resume/skills_resume_screen.dart';
import 'package:BlueEra/widgets/common_chip.dart';
import 'package:BlueEra/widgets/delete_dialog.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/snackbar_helper.dart';
import '../controller/awards_controller.dart';
import '../controller/languages_controller.dart';
import '../controller/publications_controller.dart';
import '../controller/skills_controller.dart';

class AboutMeSection extends StatefulWidget {
  const AboutMeSection({super.key});

  @override
  State<AboutMeSection> createState() => _AboutMeSectionState();
}

class _AboutMeSectionState extends State<AboutMeSection> {
  final ResumeController controller = Get.put(ResumeController());
  final CareerObjectiveController careerController =
      Get.put(CareerObjectiveController());
  final SkillsController skillsController = Get.put(SkillsController());
  final LanguagesController langController = Get.put(LanguagesController());
  final PortfolioController portfolioController =
      Get.put(PortfolioController());

  final AchievementsController achievementsController =
      Get.put(AchievementsController());
  final AwardsController awardsController = Get.put(AwardsController());
  final HobbiesController hobbiesController = Get.put(HobbiesController());
  final PublicationsController publicationsController =
      Get.put(PublicationsController());
  final CertificationsController certificationsController =
      Get.put(CertificationsController());
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
        Obx(() {
          return Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Text(
                  "Skills",
                  style: TextStyle(
                      color: AppColors.grey72, fontSize: SizeConfig.medium),
                ),

                SizedBox(height: 16),

                // Content based on skills availability
                if (skillsController.skillsList.isEmpty)
                  // Empty state - Career Objective jaisa design
                  GestureDetector(
                    onTap: () => navigatePushTo(context, SkillsResumeScreen()),
                    child: Row(
                      children: [
                        Icon(
                          Icons.add,
                          size: 16,
                          color: Colors.blue,
                        ),
                        SizedBox(width: 8),
                        Text(
                          "Add Skills",
                          style: TextStyle(
                            color: Colors.blue,
                            fontSize: SizeConfig.large,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: skillsController.skillsList
                            .where((skill) => skill.trim().isNotEmpty)
                            .map((skill) => CommonChip(
                                  label: skill,
                                  onDeleted: () {
                                    showConfirmDialog(
                                      context,
                                      () {
                                        skillsController.deleteSkillsApi(skill);
                                        Navigator.of(context).pop();
                                      },
                                      title: 'Delete Skill',
                                      content:
                                          "Are you sure you want to delete '$skill'?",
                                    );
                                  },
                                ))
                            .toList(),
                      ),
                      SizedBox(height: 16),
                      GestureDetector(
                        onTap: () =>
                            navigatePushTo(context, SkillsResumeScreen()),
                        child: Row(
                          children: [
                            Icon(
                              Icons.add,
                              size: 16,
                              color: Colors.blue,
                            ),
                            SizedBox(width: 8),
                            Text(
                              "Add Skills",
                              style: TextStyle(
                                color: Colors.blue,
                                fontSize: SizeConfig.large,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          );
        }),
        SizedBox(height: SizeConfig.size10),
        Obx(() {
          return Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Text(
                  "Languages",
                  style: TextStyle(
                      color: AppColors.grey72, fontSize: SizeConfig.medium),
                ),

                SizedBox(height: 16),

                if (langController.isFirstTime.value ||
                    (langController.speakLanguages.isEmpty &&
                        langController.writeLanguages.isEmpty))
                  GestureDetector(
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => AddLanguageScreen()),
                      );
                      await langController.getLanguagesApi();
                    },
                    child: Row(
                      children: [
                        Icon(
                          Icons.add,
                          size: 16,
                          color: Colors.blue,
                        ),
                        SizedBox(width: 8),
                        Text(
                          "Add Languages",
                          style: TextStyle(
                            color: Colors.blue,
                            fontSize: SizeConfig.large,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (langController.speakLanguages.isNotEmpty) ...[
                        Text(
                          "Languages That You Speak & Understand",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: 12),

                        // For Speak and Understand languages
                        Obx(() => Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: langController.speakLanguages
                                  .map(
                                    (language) => CommonChip(
                                      label: language.label,
                                      onDeleted: () {
                                        // Show confirm dialog before removal
                                        showConfirmDialogForLanguageDeletion(
                                          context,
                                          language,
                                          langController,
                                          'speakAndUnderstand',
                                        );
                                      },
                                    ),
                                  )
                                  .toList(),
                            )),
                        SizedBox(height: 20),
                      ],
                      if (langController.writeLanguages.isNotEmpty) ...[
                        Text(
                          "Languages That You Can Write",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: 12),

                        // For Write languages
                        Obx(() => Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: langController.writeLanguages
                                  .map(
                                    (language) => CommonChip(
                                      label: language.label,
                                      onDeleted: () {
                                        // Show confirm dialog before removal
                                        showConfirmDialogForLanguageDeletion(
                                          context,
                                          language,
                                          langController,
                                          'write',
                                        );
                                      },
                                    ),
                                  )
                                  .toList(),
                            )),
                        SizedBox(height: 16),
                      ],
                      GestureDetector(
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => AddLanguageScreen()),
                          );
                          await langController.getLanguagesApi();
                        },
                        child: Row(
                          children: [
                            Icon(
                              Icons.add,
                              size: 16,
                              color: Colors.blue,
                            ),
                            SizedBox(width: 8),
                            Text(
                              "Add Languages",
                              style: TextStyle(
                                color: Colors.blue,
                                fontSize: SizeConfig.large,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          );
        }),
        SizedBox(height: SizeConfig.size10),

        Obx(() {
          final String objective = careerController.careerObjective.value;
          final items = objective.isNotEmpty
              ? [
                  {'title': objective}
                ]
              : <Map<String, dynamic>>[];
          return ResumeProfileSectionCard(
            title: "Career Objective",
            items: items,
            onAddPressed: items.isEmpty
                ? () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            AddCareerObjectiveScreen(isEdit: false),
                      ),
                    );
                    getResumeController.getMyResume();
                  }
                : null,
            itemsEditCallback: (index) async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddCareerObjectiveScreen(isEdit: true),
                ),
              );
              getResumeController.getMyResume();
            },
            itemsDeleteCallback: (index) {
              showConfirmDeleteDialog(context, () async {
                Navigator.of(context).pop();
                await careerController.deleteCareerObjectiveApi();
              });
            },
          );
        }),

        SizedBox(height: SizeConfig.size10),
        Obx(() {
          final items = portfolioController.portfolioLinks
              .map((link) => {
                    'title': link,
                    '_id': link,
                    'document': [],
                  })
              .toList();

          return ResumeProfileSectionCard(
            title: "Portfolio / Work Samples",
            items: items,
            onAddPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PortfolioLinkScreen(),
                ),
              );
              // portfolioController.savePortfolio();
              if (result == true) {
                getResumeController.getMyResume();
              }
            },
            itemsEditCallback: null,
            itemsDeleteCallback: (index) {
              final data = items[index];
              final link = data['_id'] as String?;
              if (link == null) return;
              showConfirmDeleteDialog(context, () async {
                Navigator.of(context).pop();
                portfolioController.deletePortfolioLink(link);
              });
            },
            titleColor: AppColors.primaryColor,
          );
        }),
        Obx(() {
          final items = awardsController.awards.map((award) {
            String? attachmentUrl;

            final attachmentData = award['attachment'];

            if (attachmentData == null) {
              attachmentUrl = null;
            } else if (attachmentData is String) {
              attachmentUrl = attachmentData;
            } else if (attachmentData is List && attachmentData.isNotEmpty) {
              final first = attachmentData[0];
              if (first is String) {
                attachmentUrl = first;
              } else if (first is Map<String, dynamic>) {
                if (first.containsKey('url') && first['url'] is String) {
                  attachmentUrl = first['url'];
                } else if (first.containsKey('path') &&
                    first['path'] is String) {
                  attachmentUrl = first['path'];
                } else {
                  attachmentUrl = first.values.isNotEmpty
                      ? first.values.first.toString()
                      : null;
                }
              } else {
                attachmentUrl = null;
              }
            } else if (attachmentData is Map<String, dynamic>) {
              if (attachmentData.containsKey('url') &&
                  attachmentData['url'] is String) {
                attachmentUrl = attachmentData['url'];
              } else if (attachmentData.containsKey('path') &&
                  attachmentData['path'] is String) {
                attachmentUrl = attachmentData['path'];
              } else {
                attachmentUrl = attachmentData.values.isNotEmpty
                    ? attachmentData.values.first.toString()
                    : null;
              }
            } else {
              attachmentUrl = null;
            }

            if (attachmentUrl != null) {
              try {
                attachmentUrl = attachmentUrl.toString();
              } catch (e) {
                attachmentUrl = null;
              }
            }

            final documents =
                (attachmentUrl != null && attachmentUrl.isNotEmpty)
                    ? [attachmentUrl]
                    : [];

            String formattedDate = "";
            final dateMap = award['issuedDate'];
            if (dateMap is Map<String, dynamic>) {
              int? year = dateMap['year'] is int
                  ? dateMap['year']
                  : int.tryParse("${dateMap['year']}");
              int? month = dateMap['month'] is int
                  ? dateMap['month']
                  : int.tryParse("${dateMap['month']}");
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
              if (year != null && month != null) {
                if (month > 0 && month < months.length) {
                  formattedDate = "${months[month]} $year";
                } else {
                  formattedDate = year.toString();
                }
              }
            }

            return {
              'title': award['title'] ?? '',
              'subtitle1': formattedDate,
              'subtitle2': award['issuedBy'] ?? '',
              'document': documents,
              'subtitle3': award['description'] ?? '',
              '_id': award['_id'],
              'raw': award,
            };
          }).toList();

          return ResumeProfileSectionCard(
            title: "Awards",
            items: items,
            onAddPressed: () {
              awardsController.clearForm();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddAwardsScreen()),
              ).then((_) => getResumeController.getMyResume());
            },
            itemsEditCallback: (index) {
              final data = items[index];
              awardsController.fillFormForEdit(data['raw']);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddAwardsScreen()),
              ).then((_) => getResumeController.getMyResume());
            },
            itemsDeleteCallback: (index) {
              final data = items[index];
              final id = data['_id'] as String?;
              if (id == null) return;
              showConfirmDeleteDialog(context, () async {
                Navigator.of(context).pop();
                await awardsController.deleteAwardApi(id);
                getResumeController.getMyResume();
              });
            },
            titleColor: AppColors.black28,
          );
        }),

        /// ACHIEVEMENTS
        Obx(() {
          final items = achievementsController.achievementsList;
          return ResumeProfileSectionCard(
            title: "Achievements",
            items: items.toList(),
            onAddPressed: () {
              achievementsController.clearForm();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddAchievementScreen(isEdit: false),
                ),
              ).then((_) => getResumeController.getMyResume());
            },
            itemsEditCallback: (index) {
              final data = items[index];
              achievementsController.fillForm(data);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddAchievementScreen(
                    isEdit: true,
                    achievementId: data['_id'],
                  ),
                ),
              ).then((_) => getResumeController.getMyResume());
            },
            itemsDeleteCallback: (index) {
              final data = items[index];
              final String? id = data['_id'];
              if (id == null) return;
              showConfirmDeleteDialog(context, () async {
                Navigator.of(context).pop();
                await achievementsController.deleteAchievement(id);
              });
            },
            titleColor: AppColors.black28,
          );
        }),
        SizedBox(height: SizeConfig.size10),

        Obx(() {
          final items = certificationsController.certificationsList;

          return ResumeProfileSectionCard(
            title: "Certifications",
            items: items.toList(),
            onAddPressed: () {
              certificationsController.clearForm();
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => CertificateScreen(isEdit: false)),
              ).then((_) => getResumeController.getMyResume());
            },
            itemsEditCallback: (index) {
              final items = certificationsController.certificationsList;
              if (index < 0 || index >= items.length) return;
              final data = items[index];
              certificationsController.fillForm(data);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CertificateScreen(
                      isEdit: true, certificationId: data['_id']),
                ),
              ).then((_) => getResumeController.getMyResume());
            },
            itemsDeleteCallback: (index) {
              final data = items[index];
              final id = data['_id'] as String?;
              if (id == null) return;
              showConfirmDeleteDialog(context, () async {
                Navigator.of(context).pop();
                await certificationsController.deleteCertification(id);
              });
            },
            titleColor: AppColors.black28,
          );
        }),

        SizedBox(height: SizeConfig.size10),

        Obx(() {
          final publications = publicationsController.publications;

          return ResumeProfileSectionCard(
            title: "Publications",
            items: publications.map((pub) {
              final pubDate = pub['publishedDate'];
              String pubDateStr = '';
              if (pubDate != null && pubDate is Map) {
                final date = pubDate['date']?.toString() ?? '';
                final month = pubDate['month']?.toString() ?? '';
                final year = pubDate['year']?.toString() ?? '';
                pubDateStr = '$date/$month/$year';
              }

              return {
                'title': pub['title'] ?? '',
                'subtitle1': pub['link'] ?? '',
                'subtitle2': pubDateStr,
                'subtitle3': pub['description'] ?? '',
                '_id': pub['_id'],
              };
            }).toList(),
            titleColor: AppColors.black28,
            subtitle1Color: AppColors.primaryColor,
            onAddPressed: () async {
              navigatePushTo(context, const AddPublishingScreen());
              await getResumeController.getMyResume();
            },
            itemsEditCallback: (index) async {
              publicationsController.fillFormForEdit(publications[index]);
              navigatePushTo(
                context,
                AddPublishingScreen(publicationData: publications[index]),
              );
              await getResumeController.getMyResume();
            },
            itemsDeleteCallback: (index) {
              showConfirmDeleteDialog(context, () async {
                Navigator.of(context).pop();
                await publicationsController
                    .deletePublicationApi(publications[index]['_id']);
                await getResumeController.getMyResume();
                commonSnackBar(message: "Publication deleted successfully");
              });
            },
          );
        }),

        SizedBox(height: SizeConfig.size10),
        Obx(() {
          return Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Text(
                  "Hobbies",
                  style: TextStyle(
                      color: AppColors.grey72, fontSize: SizeConfig.medium),
                ),

                SizedBox(height: 16),

                // Content based on hobbies availability
                if (hobbiesController.hobbies.isEmpty)
                  // Empty state - Career Objective jaisa design
                  GestureDetector(
                    onTap: () => navigatePushTo(context, HobbiesScreen()),
                    child: Row(
                      children: [
                        Icon(
                          Icons.add,
                          size: 16,
                          color: Colors.blue,
                        ),
                        SizedBox(width: 8),
                        Text(
                          "Add Hobbies",
                          style: TextStyle(
                            color: Colors.blue,
                            fontSize: SizeConfig.large,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  // Hobbies exist - Show chips + Add button
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: hobbiesController.hobbies
                            .where((hobby) =>
                                hobby['name'] != null &&
                                hobby['name'].toString().trim().isNotEmpty)
                            .map((hobby) => CommonChip(
                                  label: hobby['name'].toString(),
                                  onDeleted: () {
                                    showConfirmDialog(
                                      context,
                                      () {
                                        hobbiesController.deleteHobby(
                                            hobby['_id'].toString());
                                        Navigator.of(context).pop();
                                      },
                                      title: 'Delete Hobby',
                                      content:
                                          "Are you sure you want to delete '${hobby['name']}'?",
                                    );
                                  },
                                ))
                            .toList(),
                      ),
                      SizedBox(height: 16),
                      GestureDetector(
                        // onTap: () => navigatePushTo(context, HobbiesScreen()),
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => HobbiesScreen()),
                          );
                          if (result == true) {
                            await getResumeController.getMyResume();
                          }
                        },

                        child: Row(
                          children: [
                            Icon(
                              Icons.add,
                              size: 16,
                              color: Colors.blue,
                            ),
                            SizedBox(width: 8),
                            Text(
                              "Add Hobbies",
                              style: TextStyle(
                                color: Colors.blue,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
