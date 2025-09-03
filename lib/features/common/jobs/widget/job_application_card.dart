import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/l10n/app_localizations.dart';
import 'package:BlueEra/widgets/common_circular_profile_image.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/image_view_screen.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../widgets/custom_btn.dart';
import 'job_schedule_feedback_dialog.dart';

class JobApplicationCard extends StatelessWidget {
  final String jobTitle;
  final String companyName;
  final String timeAgo;
  final String location;
  final String salary;
  final String jobType;
  final String verticalLineAsset;
  final String companyLogo;
  final String companyBusinessId;
  final String jobPostImage;
  final String jobStatus;
  final String jobID;
  final String applicationID;
  final bool isShortlisted;
  final bool isFeedBackStatus;
  final VoidCallback feedBackSubmit;
  final VoidCallback removeJobCallBack;

  const JobApplicationCard({
    super.key,
    required this.jobTitle,
    required this.companyName,
    required this.timeAgo,
    required this.location,
    required this.salary,
    required this.jobType,
    required this.jobStatus,
    required this.companyBusinessId,
    required this.companyLogo,
    required this.verticalLineAsset,
    required this.jobPostImage,
    required this.isShortlisted,
    required this.applicationID,
    required this.jobID,
    required this.isFeedBackStatus,
    required this.feedBackSubmit,
    required this.removeJobCallBack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(
          horizontal: SizeConfig.size15, vertical: SizeConfig.size8),
      padding: EdgeInsets.all(SizeConfig.size15),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10.0),
        color: AppColors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
              onTap: () {
                openBusinessProfile(businessUserId: companyBusinessId);
              },
              child: _buildHeader(context)),
          const SizedBox(height: 16),
          _buildJobDetails(context),
          const SizedBox(height: 20),
          Column(
            children: [
              // === Applied ===
              if (jobStatus.toLowerCase() ==
                  AppConstants.Applied.toLowerCase()) ...[
                _buildStatusContainer(context),
                SizedBox(height: 10),
                _buildShortlistBanner(
                  context,
                  "Congratulations, HR will connect you soon!",
                ),
              ],

              // === Screening ===
              if (jobStatus.toLowerCase() ==
                  AppConstants.Screening.toLowerCase())
                _buildShortlistBanner(
                  context,
                  "Your profile is under review.",
                ),

              // === Shortlisted ===
              if (jobStatus.toLowerCase() ==
                  AppConstants.Shortlisted.toLowerCase())
                _buildShortlistBanner(
                  context,
                  "Great! You have been shortlisted for the next round.",
                ),

              // === Interview Scheduled ===
              if (jobStatus.toLowerCase() ==
                  AppConstants.InterviewScheduled.toLowerCase())
                _buildShortlistBanner(
                  context,
                  "Congratulations, Interview Scheduled!",
                ),

              // === Interviewing ===
              if (jobStatus.toLowerCase() ==
                  AppConstants.Interviewing.toLowerCase())
                _buildShortlistBanner(
                  context,
                  "Your interview is in progress. Good luck!",
                ),

              // === Offered ===
              if (jobStatus.toLowerCase() == AppConstants.Offered.toLowerCase())
                _buildShortlistBanner(
                  context,
                  "Congratulations! You have received an offer.",
                ),

              // === Hired ===
              if (jobStatus.toLowerCase() ==
                  AppConstants.Hired.toLowerCase()) ...[
                _buildShortlistBanner(
                  context,
                  // "Vacancy closed — please check other openings."
                  "Congratulations! You got the job!",
                  // closed: true,
                ),
                if (!isFeedBackStatus) ...[
                  SizedBox(height: SizeConfig.size15),
                  PositiveCustomBtn(
                    height: SizeConfig.size32,
                    onTap: () {
                      showExperienceDialog(
                        context,
                        applicationID: applicationID,
                        jobID: jobID,
                        title: "Tell us how was your experience?",
                        subtitle: "Short Description (optional)",
                        hint: "Briefly share how your interview went...",
                        onSubmit: feedBackSubmit,
                        isHiredCandidate: 'FOR_JOB',
                        interviewID: '',
                      );
                    },
                    title: "Tell us how was your experience?",
                    bgColor: AppColors.white,
                    textColor: AppColors.primaryColor,
                  ),
                ],
              ],

              // === Rejected ===
              if (jobStatus.toLowerCase() ==
                  AppConstants.Rejected.toLowerCase())
                _buildShortlistBanner(
                  context,
                  "We regret to inform you that your application was not successful.",
                  closed: true,
                ),

              // === Withdrawn ===
              if (jobStatus.toLowerCase() ==
                  AppConstants.Withdrawn.toLowerCase())
                _buildShortlistBanner(
                  context,
                  "You have withdrawn your application.",
                  closed: true,
                ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CommonCircularImage(
          url: companyLogo,
          title: companyName,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText(
                jobTitle,
                fontWeight: FontWeight.bold,
                color: AppColors.black,
                fontSize: SizeConfig.size16,
                maxLines: 1,
              ),
              const SizedBox(height: 4),
              CustomText(
                "${companyName} • $timeAgo",
                color: AppColors.black28,
                fontSize: SizeConfig.small,
                maxLines: 2,
              ),
            ],
          ),
        ),
        (jobStatus.toLowerCase() == AppConstants.Hired.toLowerCase())
            ? InkWell(
                onTap: removeJobCallBack,
                child: LocalAssets(
                  imagePath: AppIconAssets.close_black,
                  imgColor: Colors.black,
                ),
              )
            : SizedBox() /*LocalAssets(
                imagePath: AppIconAssets.chat,
                imgColor: Colors.black,
              )*/
      ],
    );
  }

  Widget _buildJobDetails(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _infoRow(context, AppIconAssets.location_outline, location),
              const SizedBox(height: 12),
              _infoRow(context, AppIconAssets.moneyOutlinedIcon, salary),
              const SizedBox(height: 12),
              _infoRow(context, AppIconAssets.jobTimeIcon, jobType),
            ],
          ),
        ),
        const SizedBox(width: 16),
        InkWell(
          onTap: () {
            navigatePushTo(
              context,
              ImageViewScreen(
                appBarTitle: AppLocalizations.of(context)!.imageViewer,
                // imageUrls: [post?.author.profileImage ?? ''],
                imageUrls: [jobPostImage],
                initialIndex: 0,
              ),
            );
          },
          child: SizedBox(
            width: SizeConfig.size70,
            height: SizeConfig.size70,
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.horizontal(left: Radius.circular(10.0)),
              child: CachedNetworkImage(
                imageUrl: jobPostImage,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                errorWidget: (context, url, error) => Container(
                  width: SizeConfig.screenWidth,
                  height: SizeConfig.size140,
                  color: Colors.grey[300],
                  child: LocalAssets(imagePath: AppIconAssets.blueEraIcon),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _infoRow(BuildContext context, String icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LocalAssets(imagePath: icon, imgColor: AppColors.black),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.black,
                  fontSize: 14,
                ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusContainer(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10.0),
        color: AppColors.lightSky,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              _circleIcon(true),
              const SizedBox(height: 4),
              LocalAssets(
                  imagePath: verticalLineAsset, imgColor: AppColors.black),
              SizedBox(height: SizeConfig.size1),
              _circleIcon(isShortlisted),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _statusText(
                  context,
                  "Application sent to HR",
                  "If your profile is Shortlisted. HR will call or Message you",
                  isChecked: true,
                ),
                SizedBox(height: SizeConfig.size45),
                _statusText(
                  context,
                  "Application shortlisted By HR",
                  null,
                  isChecked: isShortlisted,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _circleIcon(bool isChecked) {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.black,
          width: 2,
        ),
      ),
      child: isChecked
          ? Center(
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.black,
                ),
              ),
            )
          : null,
    );
  }

  Widget _statusText(BuildContext context, String title, String? subtitle,
      {required bool isChecked}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: isChecked ? FontWeight.w600 : FontWeight.normal,
                color: AppColors.black28,
                fontSize: 13.5,
              ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 11,
                  color: AppColors.black28,
                ),
          ),
        ]
      ],
    );
  }

  Widget _buildShortlistBanner(BuildContext context, String message,
      {bool? closed}) {
    return Container(
      width: Get.width,
      alignment: Alignment.center,
      child: Padding(
        padding: const EdgeInsets.only(top: 0, left: 8, right: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            LocalAssets(
              imagePath: (closed ?? false)
                  ? AppIconAssets.close_black
                  : AppIconAssets.greenCircleTickIcon,
              width: 15,
              height: 15,
              imgColor: (closed ?? false) ? AppColors.red00 : AppColors.green39,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: CustomText(
                message,
                fontSize: SizeConfig.small,
                color: (closed ?? false) ? AppColors.red00 : AppColors.green39,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
