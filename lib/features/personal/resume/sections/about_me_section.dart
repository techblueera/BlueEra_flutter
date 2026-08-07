import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
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
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/common_chip.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/delete_dialog.dart';
import 'package:BlueEra/widgets/local_assets.dart';
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
    // No SizedBox separators between the cards: CommonCardWidget already
    // carries `margin: EdgeInsets.all(10)`, so adjacent cards are 20dp
    // apart on their own. The old spacers pushed some gaps to 30dp while
    // others (portfolio → awards → achievements) had none, which is what
    // made the tab look unevenly spaced.
    // `stretch` keeps every card the same width — without it a card whose
    // list is empty (title + Add row only) shrink-wraps and sits narrower
    // than its filled neighbours.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        /// SKILLS
        Obx(() {
          final skills = skillsController.skillsList
              .where((skill) => skill.trim().isNotEmpty)
              .toList();
          return SizedBox(
            width: Get.width,
            child: _ChipSectionCard(
              title: AppStrings.skills,
              addLabel: AppStrings.addSkills,
              onAdd: () => navigatePushTo(context, SkillsResumeScreen()),
              groups: [
                _ChipGroup(
                  chips: skills
                      .map((skill) => _ChipData(
                            label: skill,
                            onDelete: () {
                              showConfirmDialog(
                                context,
                                () {
                                  skillsController.deleteSkillsApi(skill);
                                  Navigator.of(context).pop();
                                },
                                title: AppStrings.deleteSkill,
                                content:
                                    "${AppStrings.deleteConfirm.tr} '$skill'?",
                              );
                            },
                          ))
                      .toList(),
                ),
              ],
            ),
          );
        }),

        /// LANGUAGES
        Obx(() {
          Future<void> openLanguageScreen() async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => AddLanguageScreen()),
            );
            await langController.getLanguagesApi();
          }

          // `isFirstTime` keeps the card in its empty state until the user
          // has actually saved a selection, even if the lists carry
          // defaults — same gate as before.
          final showGroups = !langController.isFirstTime.value;
          return SizedBox(
            width: Get.width,
            child: _ChipSectionCard(
              title: AppStrings.language,
              addLabel: AppStrings.addLanguages,
              onAdd: openLanguageScreen,
              groups: showGroups
                  ? [
                      _ChipGroup(
                        label: AppStrings.languagesSpeakUnderstand,
                        chips: langController.speakLanguages
                            .map((language) => _ChipData(
                                  label: language.label,
                                  onDelete: () =>
                                      showConfirmDialogForLanguageDeletion(
                                    context,
                                    language,
                                    langController,
                                    'speakAndUnderstand',
                                  ),
                                ))
                            .toList(),
                      ),
                      _ChipGroup(
                        label: AppStrings.languagesWrite,
                        chips: langController.writeLanguages
                            .map((language) => _ChipData(
                                  label: language.label,
                                  onDelete: () =>
                                      showConfirmDialogForLanguageDeletion(
                                    context,
                                    language,
                                    langController,
                                    'write',
                                  ),
                                ))
                            .toList(),
                      ),
                    ]
                  : const [],
            ),
          );
        }),

        /// CAREER OBJECTIVE
        Obx(() {
          final String objective = careerController.careerObjective.value;
          final items = objective.isNotEmpty
              ? [
                  {'title': objective}
                ]
              : <Map<String, dynamic>>[];
          return ResumeProfileSectionCard(
            title: AppStrings.careerObjective.tr,
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

        Obx(() {
          final items = portfolioController.portfolioLinks
              .map((link) => {
                    'title': link,
                    '_id': link,
                    'document': [],
                  })
              .toList();

          return ResumeProfileSectionCard(
            title: AppStrings.portfolioWorkSamples.tr,
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
            title: AppStrings.awards.tr,
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
            title: AppStrings.achievements.tr,
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
                await achievementsController.deleteAchievement(id, index);
              });
            },
            titleColor: AppColors.black28,
          );
        }),

        Obx(() {
          final items = certificationsController.certificationsList;

          return ResumeProfileSectionCard(
            title: AppStrings.certifications.tr,
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
                await certificationsController.deleteCertification(id, index);
              });
            },
            titleColor: AppColors.black28,
          );
        }),

        Obx(() {
          final publications = publicationsController.publications;

          return ResumeProfileSectionCard(
            title: AppStrings.publications.tr,
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
                await publicationsController.deletePublicationApi(
                    publications[index]['_id'], index);
                await getResumeController.getMyResume();
                commonSnackBar(message: AppStrings.publicationDeleted);
              });
            },
          );
        }),

        /// HOBBIES
        Obx(() {
          final hobbies = hobbiesController.hobbies
              .where((hobby) =>
                  hobby['name'] != null &&
                  hobby['name'].toString().trim().isNotEmpty)
              .toList();
          return SizedBox(
            width: Get.width,
            child: _ChipSectionCard(
              title: AppStrings.hobbies,
              addLabel: AppStrings.addHobbies,
              // Both states now refresh on return — the old empty state
              // pushed without awaiting the result, so a first hobby only
              // appeared after leaving and re-entering the tab.
              onAdd: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => HobbiesScreen()),
                );
                if (result == true) {
                  await getResumeController.getMyResume();
                }
              },
              groups: [
                _ChipGroup(
                  chips: hobbies
                      .map((hobby) => _ChipData(
                            label: hobby['name'].toString(),
                            onDelete: () {
                              showConfirmDialog(
                                context,
                                () {
                                  hobbiesController
                                      .deleteHobby(hobby['_id'].toString());
                                  Navigator.of(context).pop();
                                },
                                title: AppStrings.deleteHobby,
                                content:
                                    "${AppStrings.deleteConfirm.tr} '${hobby['name']}'?",
                              );
                            },
                          ))
                      .toList(),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

/// One deletable chip inside a [_ChipGroup].
class _ChipData {
  final String label;
  final VoidCallback onDelete;

  const _ChipData({required this.label, required this.onDelete});
}

/// A labelled run of chips. [label] is optional — Skills and Hobbies have a
/// single unlabelled group, Languages splits into "Speak & Understand" and
/// "Write". Groups with no chips are dropped, so an empty section collapses
/// straight to its Add row with no leftover gap.
class _ChipGroup {
  final String? label;
  final List<_ChipData> chips;

  const _ChipGroup({this.label, required this.chips});
}

/// Chip-based section card (Skills / Languages / Hobbies) built with the same
/// anatomy as [ResumeProfileSectionCard] — grey title, `size15` rhythm, and a
/// blue "Add …" row at the bottom — so every card in the About Me tab reads as
/// one family instead of three bespoke layouts.
///
/// The old inline versions used `GestureDetector` around a bare `Row`: no
/// ripple and a hit area only as tall as the text. This uses an [InkWell] with
/// padding, so the whole icon + label block is a comfortable tap target.
class _ChipSectionCard extends StatelessWidget {
  final String title;
  final String addLabel;
  final VoidCallback onAdd;
  final List<_ChipGroup> groups;

  const _ChipSectionCard({
    required this.title,
    required this.addLabel,
    required this.onAdd,
    this.groups = const [],
  });

  @override
  Widget build(BuildContext context) {
    final visibleGroups = groups.where((g) => g.chips.isNotEmpty).toList();

    return CommonCardWidget(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomText(
            title,
            color: AppColors.grey72,
            fontSize: SizeConfig.medium,
          ),
          SizedBox(height: SizeConfig.size15),
          for (final group in visibleGroups) ...[
            if (group.label != null) ...[
              CustomText(
                group.label!,
                fontWeight: FontWeight.w500,
                color: AppColors.grey72,
              ),
              SizedBox(height: SizeConfig.size10),
            ],
            _buildChipWrap(group.chips),
            SizedBox(height: SizeConfig.size15),
          ],
          InkWell(
            onTap: onAdd,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: SizeConfig.size6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  LocalAssets(imagePath: AppIconAssets.addBlueIcon),
                  SizedBox(width: SizeConfig.size4),
                  CustomText(
                    addLabel,
                    color: AppColors.primaryColor,
                    fontSize: SizeConfig.large,
                    fontWeight: FontWeight.w500,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// [LayoutBuilder] caps each chip at the card's content width so a long
  /// skill or language name ellipsizes inside its chip instead of pushing
  /// past the card edge on a narrow screen.
  Widget _buildChipWrap(List<_ChipData> chips) {
    return LayoutBuilder(
      builder: (context, constraints) => Wrap(
        spacing: SizeConfig.size8,
        runSpacing: SizeConfig.size8,
        children: chips
            .map((chip) => ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: constraints.maxWidth),
                  child: CommonChip(
                    label: chip.label,
                    onDeleted: chip.onDelete,
                  ),
                ))
            .toList(),
      ),
    );
  }
}
