import 'dart:convert'; // Added for jsonDecode

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/common/auth/model/get_job_details_byId_model.dart';
import 'package:BlueEra/features/common/jobs/controller/create_job_post_controller.dart';
import 'package:BlueEra/features/common/jobs/controller/job_details_screen_controller.dart';
import 'package:BlueEra/features/common/jobs/widget/job_header_row.dart';
import 'package:BlueEra/l10n/app_localizations.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_draggable_bottom_sheet.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/expandable_text.dart';
import 'package:BlueEra/widgets/image_view_screen.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';

class JobDetailScreen extends StatefulWidget {
  final String? isPostEdit;
  final String? isPostDirection;
  final String? isPostApply;
  final String? isPostCreate;
  final String jobId;
  final bool? isShowSaveJob;

  const JobDetailScreen(
      {super.key,
      required this.isPostDirection,
      required this.isPostApply,
      required this.jobId,
      required this.isPostEdit,
      required this.isPostCreate,
      this.isShowSaveJob = true});

  @override
  State<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen> {
  late JobDetailsScreenController controller;
  String JOBID = '';

  // late final JobBloc bloc;
  //
  @override
  void initState() {
    super.initState();
    JOBID = widget.jobId;
    // Initialize controller with proper disposal of existing instance
    if (Get.isRegistered<JobDetailsScreenController>()) {
      Get.delete<JobDetailsScreenController>();
    }
    controller = Get.put(JobDetailsScreenController());

    // Use post-frame callback to ensure widget is fully built before making API call
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        controller.fetchJobDetails(JOBID);
      }
    });
  }

  @override
  void dispose() {
    // Clean up controllers to prevent memory leaks
    if (Get.isRegistered<JobDetailsScreenController>()) {
      Get.delete<JobDetailsScreenController>();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(),
      body: SafeArea(
        child: Obx(() {
          // Check if controller is still valid
          if (!Get.isRegistered<JobDetailsScreenController>()) {
            return SizedBox();
          }
          // Show job details if available
          final job = controller.jobDetails.value?.job;
          if (job != null) {
            return _buildJobDetailContent(job);
          }

          // Show message if no job details available
          return Center(
            child: SizedBox(),
          );
        }),
      ),
    );
  }

  Widget titleText(
    String text, {
    Color color = AppColors.black28,
    FontWeight fontWeight = FontWeight.w700,
    double? fontSize,
  }) {
    return CustomText(
      text,
      color: color,
      fontWeight: fontWeight,
      fontSize: fontSize,
    );
  }

  Widget subtitleText(String text,
      {Color color = AppColors.black28,
      FontWeight fontWeight = FontWeight.w400}) {
    return CustomText(
      text,
      color: color,
      fontSize: SizeConfig.medium,
      fontWeight: fontWeight,
    );
  }

  Widget _buildJobDetailContent(Job job) {
    return Container(
      margin: EdgeInsets.only(
          left: SizeConfig.size15,
          right: SizeConfig.size15,
          top: SizeConfig.size15),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          InkWell(
            onTap: () {
              navigatePushTo(
                context,
                ImageViewScreen(
                  appBarTitle: AppLocalizations.of(context)!.imageViewer,
                  // imageUrls: [post?.author.profileImage ?? ''],
                  imageUrls: [job.jobPostImage ?? ""],
                  initialIndex: 0,
                ),
              );
            },
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.horizontal(left: Radius.circular(10.0)),
              child: CachedNetworkImage(
                imageUrl: job.jobPostImage ?? "",
                // <-- Replace with your image URL from API
                fit: BoxFit.cover,
                width: 400,
                height: 400,
                // width: double.infinity,
                // height: double.infinity,
                placeholder: (context, url) =>
                    const Center(child: CircularProgressIndicator()),
                errorWidget: (context, url, error) => Container(
                  width: SizeConfig.screenWidth,
                  height: SizeConfig.size140,
                  color: Colors.grey[300],
                  child: LocalAssets(imagePath: AppIconAssets.blueEraIcon),
                ),
              ),
            ),
          ),
          CommonDraggableBottomSheet(
            maxChildSize: 1.0,
            minChildSize: 0.6,
            padding: EdgeInsets.zero,
            backgroundColor: AppColors.whiteF3,
            borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
            builder: (scrollController) =>
                _buildJobDetailsCard(scrollController, job),
          ),
        ],
      ),
    );
  }

  Widget _buildJobDetailsCard(ScrollController scrollController, Job job) {
    return SingleChildScrollView(
      controller: scrollController,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          topCard(job),
          SizedBox(height: SizeConfig.size10),
          jobDescriptionCard(job),
          SizedBox(height: SizeConfig.size10),
          jobRequirementCard(job),
          SizedBox(height: SizeConfig.size10),
          aboutCompanyCard(job),
          SizedBox(height: SizeConfig.size15)
        ],
      ),
    );
  }

  Widget jobDescriptionCard(Job job) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10.0),
        color: AppColors.white,
      ),
      padding: EdgeInsets.all(SizeConfig.size15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          titleText("Department"),
          SizedBox(height: SizeConfig.size8),
          subtitleText(job.department ?? ""),
          SizedBox(height: SizeConfig.size20),
          titleText("Job description"),
          SizedBox(height: SizeConfig.size8),
          ExpandableText(text: job.jobDescription ?? "", trimLines: 3),
          SizedBox(height: SizeConfig.size20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10.0),
                color: AppColors.skyBlueFF),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                titleText("Job Highlights"),
                SizedBox(height: SizeConfig.size8),
                if (job.jobHighlights != null && job.jobHighlights!.isNotEmpty)
                  ...job.jobHighlights!
                      .expand((item) {
                        try {
                          if (item.trim().isNotEmpty &&
                              item.trim().startsWith('[')) {
                            final decoded = List<String>.from(
                                List<dynamic>.from(jsonDecode(item)));
                            return decoded;
                          }
                        } catch (_) {}
                        return [item];
                      })
                      .map((highlight) => Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              LocalAssets(imagePath: AppIconAssets.fireIcon),
                              SizedBox(width: SizeConfig.size10),
                              Expanded(child: subtitleText(highlight)),
                            ],
                          ))
                      .toList()
                else
                  subtitleText("No highlights available"),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget topCard(Job job) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10.0),
        color: AppColors.white,
      ),
      padding: EdgeInsets.all(SizeConfig.size15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          JobHeaderRow(
            logoUrl: job.businessDetails?.buisness_logo ?? "",
            title: job.jobTitle ?? "",
            jobId: job.sId ?? "",
            companyName: job.companyName ?? "",
            trailingIconPath:
                widget.isShowSaveJob ?? false ? AppIconAssets.unsaved : null,
            businessUserId: job.businessDetails?.id,
          ),
          SizedBox(height: SizeConfig.size20),
          iconTextRow(
              iconPath: AppIconAssets.locationJobIcon,
              text: job.location?.addressString ?? "address"),
          SizedBox(height: SizeConfig.size12),
          iconTextRow(
              iconPath: AppIconAssets.stipendJobIcon,
              text:
                  '₹ ${formatNumber(job.compensation?.minSalary ?? 0)} - ₹ ${formatNumber(job.compensation?.maxSalary ?? 0)} monthly'),
          SizedBox(height: SizeConfig.size12),
          iconTextRow(
              iconPath: AppIconAssets.bagIcon,
              text: '${job.jobType ?? ""} - ${job.workMode ?? ""}'),
          SizedBox(height: SizeConfig.size14),
          Row(
            children: [
              if (widget.isPostEdit == AppConstants.EDIT)
                Expanded(
                  child: CustomBtn(
                    onTap: () {
                      // Debug: Log job ownership information

                      // Navigate to CreateJobPostScreen for editing with edit mode and job ID
                      Navigator.pushNamed(
                          context, RouteHelper.getCreateJobPostScreenRoute(),
                          arguments: {
                            'isEditMode': true,
                            'jobId': JOBID,
                          });
                    },
                    title: 'Edit',
                    bgColor: AppColors.white,
                    borderColor: AppColors.primaryColor,
                    textColor: AppColors.primaryColor,
                  ),
                ),
              if (widget.isPostDirection == AppConstants.DIRECTION)
                Expanded(
                  child: CustomBtn(
                    onTap: () {
                      final lat = double.tryParse(job.location?.latitude ?? '');
                      final lng =
                          double.tryParse(job.location?.longitude ?? '');
                      controller.openMap(lat ?? 0, lng ?? 0);
                    },
                    title: 'Directions',
                    bgColor: AppColors.white,
                    borderColor: AppColors.primaryColor,
                    textColor: AppColors.primaryColor,
                  ),
                ),
              if (widget.isPostCreate == AppConstants.JOB_POST) ...[
                SizedBox(width: SizeConfig.size8),
                Expanded(
                  child: PositiveCustomBtn(
                    onTap: () async {
                      await Get.find<CreateJobPostController>()
                          .publishJobApi(jobId: JOBID);
                    },
                    title: 'Post Job',
                  ),
                ),
              ],
              if (widget.isPostApply == AppConstants.APPLY_NOW&&(!(controller.jobDetails.value?.isApplied??false))) ...[
                SizedBox(width: SizeConfig.size8),
                Expanded(
                  child: PositiveCustomBtn(
                    onTap: () {
                      controller.getAllResumesApi(jobId: JOBID);
                    },
                    title: 'Apply Now',
                  ),
                ),
              ]
            ],
          ),
        ],
      ),
    );
  }

  Widget iconTextRow({
    required String iconPath,
    required String text,
  }) {
    return Row(
      children: [
        LocalAssets(
          imagePath: iconPath,
          imgColor: AppColors.black28,
        ),
        SizedBox(width: SizeConfig.size10),
        Expanded(
          child: CustomText(
            text,
            fontSize: SizeConfig.medium,
            color: AppColors.black28,
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ),
      ],
    );
  }

  Widget aboutCompanyCard(Job job) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10.0),
        color: AppColors.white,
      ),
      padding: EdgeInsets.all(SizeConfig.size15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          titleText("About Company"),
          SizedBox(height: SizeConfig.size20),
          JobHeaderRow(
            jobId: job.sId ?? "",
            logoUrl: job.businessDetails?.buisness_logo ?? "",
            companyName:
                "Since ${job.businessDetails?.dateOfIncorporation?.year}",
            title: job.businessDetails?.businessName ?? "",
            companyNameColor: AppColors.grey9A,
            businessUserId: job.businessDetails?.id ?? "",
          ),
          SizedBox(height: SizeConfig.size15),
          ExpandableText(
            text: job.businessDetails?.businessDescription ?? "",
            trimLines: 4,
            style: TextStyle(
                fontSize: SizeConfig.small, fontWeight: FontWeight.w400),
          ),
        ],
      ),
    );
  }

  Widget jobRoleCard(Job job) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10.0),
          color: AppColors.whiteCC,
          border: Border.all(color: AppColors.white12, width: 0.5),
          boxShadow: [BoxShadow(color: AppColors.black25, blurRadius: 6)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Job Role",
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.black28),
          ),
          const SizedBox(height: 16),
          roleItem(
            icon: LocalAssets(
                imagePath: AppIconAssets.workAddressIcon,
                imgColor: AppColors.black28),
            label: "Work location",
            value: job.location?.addressString ?? "Location not specified",
          ),
          const SizedBox(height: 16),
          roleItem(
            icon: LocalAssets(
                imagePath: AppIconAssets.departmentIcon,
                imgColor: AppColors.black28),
            label: "Department",
            value: job.department ?? "Department not specified",
          ),
          const SizedBox(height: 16),
          roleItem(
            icon: LocalAssets(
                imagePath: AppIconAssets.workLocationIcon,
                imgColor: AppColors.black28),
            label: "Work location",
            value: job.location?.addressString ?? "Location not specified",
          ),
          const SizedBox(height: 16),
          roleItem(
            icon: LocalAssets(
                imagePath: AppIconAssets.jobTypeIcon,
                imgColor: AppColors.black28),
            label: "Job Type",
            value: "${job.jobType ?? ""} - ${job.workMode ?? ""}",
          ),
        ],
      ),
    );
  }

  Widget jobRequirementCard(Job job) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10.0),
        color: AppColors.white,
      ),
      padding: EdgeInsets.all(SizeConfig.size15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          titleText("Job Requirements"),
          SizedBox(height: SizeConfig.size14),
          requirementItem(
            icon: LocalAssets(
                imagePath: AppIconAssets.experienceJobIcon,
                imgColor: AppColors.black28),
            label: "Experience",
            value: "Min. " + (job.experience?.toString() ?? "") + " years",
          ),
          SizedBox(height: SizeConfig.size15),
          requirementItem(
            icon: LocalAssets(
                imagePath: AppIconAssets.educationJobIcon,
                imgColor: AppColors.black28),
            label: "Education",
            value: job.qualifications ?? "",
          ),
          SizedBox(height: SizeConfig.size20),
          // --- Skills Section as Pills ---
          Row(
            children: [
              Expanded(
                flex: 1,

                child: LocalAssets(
                  imagePath: AppIconAssets.skillJobIcon,
                  imgColor: AppColors.black28,
                ),
              ),
              SizedBox(width: SizeConfig.size15),
              Expanded(
                flex: 10,
                child: titleText("Skill",
                    color: AppColors.grey9A,
                    fontWeight: FontWeight.w400,
                    fontSize: SizeConfig.small),
              ),
            ],
          ),
          SizedBox(height: 8),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: SizeConfig.size50),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: (job.skills ?? [])
                  .map((skill) => Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.whiteF3,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: CustomText(skill, color: AppColors.black28),
                      ))
                  .toList(),
            ),
          ),
          SizedBox(height: SizeConfig.size20),
          // --- Languages Section as Pills ---
          Row(
            children: [
              Expanded(
                flex: 1,

                child: LocalAssets(
                  imagePath: AppIconAssets.languageJobIcon,
                  imgColor: AppColors.black28,
                ),
              ),
              SizedBox(width: SizeConfig.size15),
              Expanded(
                flex: 10,
                child: titleText("Languages",
                    color: AppColors.grey9A,
                    fontWeight: FontWeight.w400,
                    fontSize: SizeConfig.small),
              ),
            ],
          ),
          SizedBox(height: 8),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: SizeConfig.size50),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: (job.languages ?? [])
                  .map((lang) => Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.whiteF3,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(lang,
                            style: TextStyle(color: AppColors.black28)),
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget roleItem({
    required Widget icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        icon,
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style:
                      const TextStyle(color: AppColors.black28, fontSize: 13)),
              const SizedBox(height: 4),
              Text(value,
                  style: const TextStyle(
                      color: AppColors.black28,
                      fontSize: 14,
                      fontWeight: FontWeight.w500)),
            ],
          ),
        )
      ],
    );
  }

  Widget requirementItem({
    required Widget icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: icon,flex: 1,),
        SizedBox(width: SizeConfig.size15),
        Expanded(
          flex: 10,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              titleText(label,
                  color: AppColors.grey9A,
                  fontWeight: FontWeight.w400,
                  fontSize: SizeConfig.small),
              SizedBox(height: SizeConfig.size6),
              subtitleText(value),
            ],
          ),
        )
      ],
    );
  }
}

class JobDetailShimmer extends StatelessWidget {
  const JobDetailShimmer({super.key});

  Widget shimmerContainer({
    double height = 16,
    double width = double.infinity,
    BorderRadius? radius,
  }) {
    return Shimmer.fromColors(
      baseColor: AppColors.black23,
      highlightColor: AppColors.blue3F.withValues(alpha: 0.4),
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: AppColors.black23,
          borderRadius: radius ?? BorderRadius.circular(8),
        ),
      ),
    );
  }

  Widget sectionCard({required double height}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.blue3F,
        borderRadius: BorderRadius.circular(12),
      ),
      child: shimmerContainer(height: height),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(SizeConfig.size15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.blue3F,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    shimmerContainer(
                        height: 40,
                        width: 40,
                        radius: BorderRadius.circular(20)),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        shimmerContainer(width: 150, height: 16),
                        const SizedBox(height: 6),
                        shimmerContainer(width: 100, height: 12),
                      ],
                    )
                  ],
                ),
                const SizedBox(height: 16),
                shimmerContainer(width: 200, height: 14),
                const SizedBox(height: 12),
                shimmerContainer(width: 180, height: 14),
                const SizedBox(height: 16),
                shimmerContainer(height: 60),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Job Description
          sectionCard(height: 150),

          // Job Role
          sectionCard(height: 200),

          // Job Requirements
          sectionCard(height: 200),

          // About Company
          sectionCard(height: 150),

          // Apply Button
          const SizedBox(height: 20),
          shimmerContainer(height: 45, radius: BorderRadius.circular(100)),
        ],
      ),
    );
  }
}
