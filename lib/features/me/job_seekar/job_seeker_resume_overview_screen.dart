import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/api/model/get_resume_data_model.dart';
import 'package:BlueEra/features/me/job_seekar/view/update_job_seekar_screen.dart';
import 'package:BlueEra/features/personal/resume/controller/profile_pic_controller.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class JobSeekerResumeOverviewScreen extends StatefulWidget {
  const JobSeekerResumeOverviewScreen({super.key});

  @override
  State<JobSeekerResumeOverviewScreen> createState() =>
      _JobSeekerResumeOverviewScreenState();
}

class _JobSeekerResumeOverviewScreenState
    extends State<JobSeekerResumeOverviewScreen> {
  late final ProfilePicController controller;
  final PageController _educationPageController = PageController();
  int _educationPageIndex = 0;
  final PageController _experiencePageController = PageController();
  int _experiencePageIndex = 0;
  final PageController _projectPageController = PageController();
  int _projectPageIndex = 0;
  final PageController _certAwardPageController =
      PageController(viewportFraction: 0.85);
  int _certAwardPageIndex = 0;

  @override
  void initState() {
    super.initState();
    controller = getOrPut(() => ProfilePicController());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.getMyResume();
    });
  }

  @override
  void dispose() {
    _educationPageController.dispose();
    _experiencePageController.dispose();
    _projectPageController.dispose();
    _certAwardPageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    return Scaffold(
      appBar: CommonBackAppBar(
        title: AppStrings.myPortfolioResume.tr,
      ),
      backgroundColor: Colors.transparent,
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding:
              const EdgeInsets.only(right: 10, left: 10, bottom: 30, top: 10),
          child: PositiveCustomBtn(
              onTap: () {
                Get.to(() => UpdateJobSeekerScreen());
              },
              title: AppStrings.createResume_.tr),
        ),
      ),
      body: Obx(() {
        final status = controller.getSelfResumeResponse.value.status;
        if (status != Status.COMPLETE) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.primaryColor));
        }
        final data = controller.getResumeData.value;
        return LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 800;
            return SingleChildScrollView(
              padding: EdgeInsets.all(SizeConfig.paddingM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  isWide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _buildEducationSection(data)),
                            SizedBox(width: SizeConfig.size12),
                            Expanded(child: _buildExperienceSection(data)),
                          ],
                        )
                      : Column(
                          children: [
                            _buildEducationSection(data),
                            SizedBox(height: SizeConfig.size12),
                            _buildExperienceSection(data),
                          ],
                        ),
                  SizedBox(height: SizeConfig.size20),
                  _buildSkillsSection(data),
                  SizedBox(height: SizeConfig.size20),
                  _buildPortfolioProjectsSection(data),
                  SizedBox(height: SizeConfig.size20),
                  _buildCertsAwardsSection(data),
                  SizedBox(height: SizeConfig.size20),
                  // _buildGallerySection(data),
                  SizedBox(height: SizeConfig.size20),
                  // _buildContactSection(data),
                ],
              ),
            );
          },
        );
      }),
    );
  }

  Widget _title(String text, {Color? titleColor}) {
    return CustomText(
      text,
      fontSize: SizeConfig.extraLarge,
      color: titleColor ?? AppColors.mainTextColor,
      fontWeight: FontWeight.w600,
    );
  }

  Widget _card({required Widget child}) {
    return SizedBox(
        width: Get.width,
        child: CommonCardWidget(
          child: child,
          cardMargin: 0,
          borderColorColor: AppColors.whiteE5,
        ));
  }

  Widget _buildEducationSection(GetResumeDataModel data) {
    final list = data.education ?? [];
    final cardHeight = SizeConfig.isTablet ? 220.0 : 170.0;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _title(AppStrings.education.tr)),
              // GestureDetector(
              //   onTap: () {},
              //   child: CustomText(
              //     "View All",
              //     fontSize: SizeConfig.small,
              //     fontWeight: FontWeight.w600,
              //     color: AppColors.primaryColor,
              //     maxLines: 1,
              //     overflow: TextOverflow.ellipsis,
              //   ),
              // ),
            ],
          ),
          SizedBox(height: SizeConfig.size12),
          if (list.isEmpty)
            CustomText(
              AppStrings.noEducationDetailsFound.tr,
              color: AppColors.grey9B,
              fontSize: SizeConfig.medium,
            )
          else ...[
            SizedBox(
              // height: 170,
              height: cardHeight,
              child: PageView.builder(
                controller: _educationPageController,
                itemCount: list.length,
                onPageChanged: (index) {
                  setState(() => _educationPageIndex = index);
                },
                itemBuilder: (context, index) {
                  final e = list[index];
                  return CommonCardWidget(
                    borderRadius: 12,
                    cardMargin: 0,
                    borderColorColor: AppColors.whiteE5,
                    // padding: 0,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CustomText(
                          e.highestQualification ?? AppStrings.na.tr,
                          fontSize: SizeConfig.large,
                          fontWeight: FontWeight.w700,
                          color: AppColors.mainTextColor,
                        ),
                        SizedBox(height: SizeConfig.size4),
                        CustomText(
                          e.passingYear != null && e.passingYear!.isNotEmpty
                              ? "(${e.passingYear})"
                              : "",
                          fontSize: SizeConfig.small,
                          color: AppColors.grey9B,
                        ),
                        SizedBox(height: SizeConfig.size8),
                        Container(
                          height: 0.6,
                          width: SizeConfig.screenWidth,
                          color: AppColors.greyE5,
                        ),
                        SizedBox(height: SizeConfig.size8),
                        CustomText(
                          e.schoolOrCollegeName ?? AppStrings.na.tr,
                          fontSize: SizeConfig.medium,
                          color: AppColors.secondaryTextColor,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: SizeConfig.size6),
                        CustomText(
                          "${AppStrings.board.tr}: ${e.boardName ?? AppStrings.na.tr}",
                          fontSize: SizeConfig.medium,
                          color: AppColors.secondaryTextColor,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: SizeConfig.size6),
                        CustomText(
                          "${AppStrings.percentage.tr}: ${_formatPercentage(e.percentage)}",
                          fontSize: SizeConfig.medium,
                          color: AppColors.secondaryTextColor,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            if (list.length > 1) ...[
              SizedBox(height: SizeConfig.size12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  list.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    height: 6,
                    width: _educationPageIndex == index ? 20 : 6,
                    decoration: BoxDecoration(
                      color: _educationPageIndex == index
                          ? AppColors.primaryColor
                          : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ]
          ],
        ],
      ),
    );
  }

  Widget _buildExperienceSection(GetResumeDataModel data) {
    final full = data.fullTimeExperience ?? [];
    final part = data.partTimeExperience ?? [];
    final current = data.currentJob;
    final items = <Map<String, dynamic>>[];
    if (current != null) {
      items.add({
        "title": current.designation ?? AppStrings.currentRole.tr,
        "company": current.currentCompanyName ?? "",
        "jobType": current.jobType ?? "",
        "location": current.location ?? "",
        "workMode": current.workMode ?? "",
        "desc": current.description ?? "",
        "start": current.startDate,
        "end": null,
        "isCurrent": current.currentlyWorkingHere ?? true,
      });
    }
    for (final f in full) {
      items.add({
        "title": f.designation ?? AppStrings.fullTime.tr,
        "company": f.previousCompanyName ?? "",
        "jobType": f.jobType ?? "",
        "location": f.location ?? "",
        "workMode": f.workMode ?? "",
        "desc": f.description ?? "",
        "start": f.startDate,
        "end": f.endDate,
        "isCurrent": false,
      });
    }
    for (final p in part) {
      items.add({
        "title": p.designation ?? AppStrings.partTime.tr,
        "company": p.previousCompanyName ?? "",
        "jobType": p.jobType ?? "",
        "location": p.location ?? "",
        "workMode": p.workMode ?? "",
        "desc": p.description ?? "",
        "start": p.startDate,
        "end": p.endDate,
        "isCurrent": false,
      });
    }
    final cardHeight = SizeConfig.isTablet ? 240.0 : 200.0;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _title(AppStrings.workExperience.tr)),
              // GestureDetector(
              //   onTap: () {},
              //   child: CustomText(
              //     "View All",
              //     fontSize: SizeConfig.small,
              //     fontWeight: FontWeight.w600,
              //     color: AppColors.primaryColor,
              //   ),
              // ),
            ],
          ),
          SizedBox(height: SizeConfig.size12),
          if (items.isEmpty)
            CustomText(
              AppStrings.noExperienceAdded.tr,
              color: AppColors.grey9B,
              fontSize: SizeConfig.medium,
            )
          else ...[
            SizedBox(
              height: cardHeight,
              child: PageView.builder(
                controller: _experiencePageController,
                itemCount: items.length,
                onPageChanged: (index) {
                  setState(() => _experiencePageIndex = index);
                },
                itemBuilder: (context, index) {
                  final item = items[index];
                  return _card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: SizeConfig.paddingS,
                            vertical: SizeConfig.size6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.whiteE5,
                            borderRadius:
                                BorderRadius.circular(SizeConfig.size12),
                          ),
                          child: Row(
                            children: [
                              CustomText(
                                _formatMonthYear(item['start']),
                                fontSize: SizeConfig.medium,
                                color: AppColors.black,
                                fontWeight: FontWeight.w600,
                              ),
                              SizedBox(width: SizeConfig.size12),
                              Expanded(
                                child: CustomText(
                                  item['title'] ?? AppStrings.na.tr,
                                  fontSize: SizeConfig.medium,
                                  color: AppColors.black,
                                  fontWeight: FontWeight.w600,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: SizeConfig.size12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            /*   SizedBox(
                              width: SizeConfig.size24,
                              child: Column(
                                children: [
                                  // Container(
                                  //   width: SizeConfig.size6,
                                  //   height: SizeConfig.size6,
                                  //   decoration: const BoxDecoration(
                                  //     color: AppColors.black,
                                  //     shape: BoxShape.circle,
                                  //   ),
                                  // ),
                                  // LayoutBuilder(
                                  //   builder: (context, c) {
                                  //     return Column(
                                  //       mainAxisAlignment:
                                  //           MainAxisAlignment.spaceBetween,
                                  //       children: List.generate(
                                  //         8,
                                  //         (i) => Container(
                                  //           width: 2,
                                  //           height: c.maxHeight / 12,
                                  //           color: AppColors.greyE5,
                                  //         ),
                                  //       ),
                                  //     );
                                  //   },
                                  // ),
                                  // Container(
                                  //   width: SizeConfig.size6,
                                  //   height: SizeConfig.size6,
                                  //   decoration: const BoxDecoration(
                                  //     color: AppColors.black,
                                  //     shape: BoxShape.circle,
                                  //   ),
                                  // ),
                                ],
                              ),
                            ),*/
                            SizedBox(width: SizeConfig.size8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CustomText(
                                    "${item['company']}${item['jobType'].toString().isNotEmpty ? ", ${item['jobType']}" : ""}",
                                    fontSize: SizeConfig.medium,
                                    color: AppColors.secondaryTextColor,
                                  ),
                                  SizedBox(height: SizeConfig.size6),
                                  CustomText(
                                    "${item['location']}${item['workMode'].toString().isNotEmpty ? " - ${item['workMode']}" : ""}",
                                    fontSize: SizeConfig.medium,
                                    color: AppColors.secondaryTextColor,
                                  ),
                                  if ((item['desc'] ?? "")
                                      .toString()
                                      .isNotEmpty) ...[
                                    SizedBox(height: SizeConfig.size8),
                                    CustomText(
                                      item['desc'],
                                      fontSize: SizeConfig.medium,
                                      color: AppColors.secondaryTextColor,
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                  SizedBox(height: SizeConfig.size10),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: SizeConfig.paddingS,
                                      vertical: SizeConfig.size6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.whiteE5,
                                      borderRadius: BorderRadius.circular(
                                          SizeConfig.size12),
                                    ),
                                    child: CustomText(
                                      item['isCurrent'] == true
                                          ? AppStrings.present.tr
                                          : _formatMonthYear(item['end']),
                                      fontSize: SizeConfig.medium,
                                      color: AppColors.black,
                                      fontWeight: FontWeight.w600,
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
                },
              ),
            ),
            if (items.length > 1) ...[
              SizedBox(height: SizeConfig.size8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  items.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    height: 6,
                    width: _experiencePageIndex == index ? 20 : 6,
                    decoration: BoxDecoration(
                      color: _experiencePageIndex == index
                          ? AppColors.primaryColor
                          : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildSkillsSection(GetResumeDataModel data) {
    final skills = data.skills ?? [];
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _title(AppStrings.skills.tr),
          SizedBox(height: SizeConfig.size12),
          if (skills.isEmpty)
            CustomText(
              AppStrings.noSkillsAdded.tr,
              color: AppColors.grey9B,
              fontSize: SizeConfig.medium,
            )
          else
            Wrap(
              spacing: SizeConfig.size8,
              runSpacing: SizeConfig.size8,
              children: skills
                  .map((s) => Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: SizeConfig.paddingS,
                          vertical: SizeConfig.size4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.buttonLiteBlue,
                          borderRadius:
                              BorderRadius.circular(SizeConfig.size12),
                          border: Border.all(color: AppColors.whiteE0),
                        ),
                        child: CustomText(
                          s,
                          fontSize: SizeConfig.small,
                          color: AppColors.blue6B,
                          fontWeight: FontWeight.w600,
                        ),
                      ))
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildPortfolioProjectsSection(GetResumeDataModel data) {
    final projects = data.portfolioProject ?? [];
    final cardHeight = SizeConfig.isTablet ? 380.0 : 340.0;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _title(AppStrings.portfolioProjects.tr)),
              // GestureDetector(
              //   onTap: () {},
              //   child: CustomText(
              //     "View All",
              //     fontSize: SizeConfig.small,
              //     fontWeight: FontWeight.w600,
              //     color: AppColors.primaryColor,
              //   ),
              // ),
            ],
          ),
          SizedBox(height: SizeConfig.size12),
          if (projects.isEmpty)
            CustomText(
              AppStrings.noProjectsAdded.tr,
              color: AppColors.grey9B,
              fontSize: SizeConfig.medium,
            )
          else ...[
            SizedBox(
              height: cardHeight,
              child: PageView.builder(
                controller: _projectPageController,
                itemCount: projects.length,
                onPageChanged: (index) {
                  setState(() => _projectPageIndex = index);
                },
                itemBuilder: (context, index) {
                  final p = projects[index];
                  return Padding(
                    padding: EdgeInsets.only(right: 10),
                    child: _card(
                      // borderRadius: 12,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius:
                                BorderRadius.circular(SizeConfig.size12),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox(
                                  height: SizeConfig.isTablet ? 220 : 200,
                                  width: double.infinity,
                                  child: Image.network(
                                    p.projectImage ?? "",
                                    fit: BoxFit.cover,
                                    errorBuilder: (c, e, s) => Container(
                                      color: AppColors.liteWhite,
                                      alignment: Alignment.center,
                                      child: Icon(Icons.image,
                                          color: AppColors.placeHolder),
                                    ),
                                  ),
                                ),

                              ],
                            ),
                          ),
                          SizedBox(height: SizeConfig.size12),
                          Row(
                            children: [
                              Expanded(
                                child: CustomText(
                                  p.title ?? AppStrings.projectName.tr,
                                  fontSize: SizeConfig.large,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.mainTextColor,
                                ),
                              ),
                              if ((p.completionDate ?? "").isNotEmpty)
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: SizeConfig.paddingS,
                                    vertical: SizeConfig.size6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.whiteE5,
                                    borderRadius: BorderRadius.circular(
                                        SizeConfig.size12),
                                  ),
                                  child: CustomText(
                                    _formatProjectDate(p.completionDate!),
                                    fontSize: SizeConfig.small,
                                    color: AppColors.black,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                            ],
                          ),
                          SizedBox(height: SizeConfig.size6),
                          if ((p.category ?? "").isNotEmpty)
                            CustomText(
                              p.category,
                              fontSize: SizeConfig.medium,
                              color: AppColors.blue6B,
                              fontWeight: FontWeight.w600,
                            ),
                          SizedBox(height: SizeConfig.size8),
                          CustomText(
                            p.description ?? "",
                            fontSize: SizeConfig.medium,
                            color: AppColors.secondaryTextColor,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            if (projects.length > 1) ...[
              SizedBox(height: SizeConfig.size8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  projects.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    height: 6,
                    width: _projectPageIndex == index ? 20 : 6,
                    decoration: BoxDecoration(
                      color: _projectPageIndex == index
                          ? AppColors.primaryColor
                          : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildCertsAwardsSection(GetResumeDataModel data) {
    final certs = data.certifications ?? [];
    final awards = data.awards ?? [];
    final items = <Map<String, String>>[];
    for (final c in certs) {
      items.add({
        "title": c.title ?? AppStrings.certificate.tr,
        "desc": c.issuingOrg ?? "",
        "image": c.certificateAttachment ?? "",
      });
    }
    for (final a in awards) {
      items.add({
        "title": a.title ?? AppStrings.award.tr,
        "desc": a.description ?? "",
        "image": a.attachment ?? "",
      });
    }
    final cardHeight = SizeConfig.isTablet ? 260.0 : 220.0;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _title(AppStrings.certificateAwards.tr)),

            ],
          ),
          SizedBox(height: SizeConfig.size12),
          if (items.isEmpty)
            CustomText(
              AppStrings.noCertificatesOrAwards.tr,
              color: AppColors.grey9B,
              fontSize: SizeConfig.medium,
            )
          else ...[
            SizedBox(
              height: cardHeight,
              child: PageView.builder(
                controller: _certAwardPageController,
                itemCount: items.length,
                onPageChanged: (i) => setState(() => _certAwardPageIndex = i),
                itemBuilder: (context, i) {
                  final it = items[i];
                  return Padding(
                    padding: EdgeInsets.only(right: SizeConfig.size8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(SizeConfig.size12),
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: Image.network(
                              it['image'] ?? "",
                              fit: BoxFit.cover,
                              errorBuilder: (c, e, s) => Container(
                                color: AppColors.liteWhite,
                                alignment: Alignment.center,
                                child: Icon(Icons.image,
                                    color: AppColors.placeHolder),
                              ),
                            ),
                          ),
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            child: Container(
                              padding: EdgeInsets.all(SizeConfig.paddingS),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [
                                    AppColors.black.withValues(alpha: 0.6),
                                    AppColors.black.withValues(alpha: 0.0),
                                  ],
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CustomText(
                                    it['title'],
                                    fontSize: SizeConfig.large,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.white,
                                  ),
                                  SizedBox(height: SizeConfig.size4),
                                  CustomText(
                                    it['desc'],
                                    fontSize: SizeConfig.medium,
                                    color: AppColors.white,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    if (items.length > 1) ...[
      SizedBox(height: SizeConfig.size8),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          items.length,
              (index) => AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            height: 6,
            width: _certAwardPageIndex == index ? 20 : 6,
            decoration: BoxDecoration(
              color: _certAwardPageIndex == index
                  ? AppColors.primaryColor
                  : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ),


    ],

          ],
        ],
      ),
    );
    // ),
  }



  String _formatPercentage(String? p) {
    if (p == null || p.isEmpty) return AppStrings.na.tr;
    final v = double.tryParse(p);
    if (v == null) return p;
    return "${v.toStringAsFixed(2)}%";
  }

  String _formatMonthYear(dynamic d) {
    if (d == null) return AppStrings.na.tr;
    try {
      final m = d.month as int?;
      final y = d.year as int?;
      if (m == null || y == null) return AppStrings.na.tr;
      const months = [
        "Jan",
        "Feb",
        "Mar",
        "Apr",
        "May",
        "Jun",
        "Jul",
        "Aug",
        "Sep",
        "Oct",
        "Nov",
        "Dec"
      ];
      final name = months[(m - 1).clamp(0, 11)];
      return "$name,$y";
    } catch (_) {
      return AppStrings.na.tr;
    }
  }

  String _formatProjectDate(String raw) {
    try {
      final dt = DateTime.tryParse(raw);
      if (dt == null) return raw;
      const months = [
        "January",
        "February",
        "March",
        "April",
        "May",
        "June",
        "July",
        "August",
        "September",
        "October",
        "November",
        "December"
      ];
      final m = months[dt.month - 1];
      return "${dt.day} $m,${dt.year}";
    } catch (_) {
      return raw;
    }
  }
}
