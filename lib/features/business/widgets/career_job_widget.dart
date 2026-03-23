import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class JobPost {
  final String? jobTitle;
  final String? companyName;
  final String? companyLogo;
  final String? posterImage;
  final String? jobType;
  final String? minExperience;
  final String? salaryRange;
  final String? location;

  const JobPost({
    this.jobTitle,
    this.companyName,
    this.companyLogo,
    this.posterImage,
    this.jobType,
    this.minExperience,
    this.salaryRange,
    this.location,
  });

  factory JobPost.fromJson(Map<String, dynamic> json) {
    return JobPost(
      jobTitle:      json['job_title'],
      companyName:   json['company_name'],
      companyLogo:   json['company_logo'],
      posterImage:   json['poster_image'],
      jobType:       json['job_type'],
      minExperience: json['min_experience'],
      salaryRange:   json['salary_range'],
      location:      json['location'],
    );
  }

  Map<String, dynamic> toJson() => {
    'job_title':      jobTitle,
    'company_name':   companyName,
    'company_logo':   companyLogo,
    'poster_image':   posterImage,
    'job_type':       jobType,
    'min_experience': minExperience,
    'salary_range':   salaryRange,
    'location':       location,
  };
}

class CareerJobsWidget extends StatelessWidget {
  final List<JobPost>? jobs;
  final VoidCallback? onViewAll;
  final VoidCallback? onAddJob;

  const CareerJobsWidget({
    super.key,
    this.jobs,
    this.onViewAll,
    this.onAddJob,
  });

  @override
  Widget build(BuildContext context) {
    final hasJobs = jobs?.isNotEmpty ?? false;

    return CustomFormCard(
      padding: EdgeInsets.all(SizeConfig.size12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ─── Header ───
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CustomText(
                'Career / Jobs',
                fontSize: SizeConfig.extraLarge,
                fontWeight: FontWeight.w700,
                color: AppColors.mainTextColor,
              ),
              if (hasJobs)
                InkWell(
                  onTap: onViewAll,
                  child: CustomText(
                    'View All',
                    fontSize: SizeConfig.medium,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primaryColor,
                  ),
                ),
            ],
          ),

          SizedBox(height: SizeConfig.size12),

          // ─── Content ───
          hasJobs
              ? _buildJobCard(jobs!.first, context)
              : _buildEmptyState(context),
        ],
      ),
    );
  }

  // ─── Job Card ───
  Widget _buildJobCard(JobPost job, BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.greyE5),
        boxShadow: [AppShadows.textFieldShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ─── Top Row: Poster + Company Info ───
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [

                // Job poster image
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft:     Radius.circular(12),
                    bottomLeft:  Radius.circular(12),
                  ),
                  child: CachedNetworkImage(
                    imageUrl:    job.posterImage ?? '',
                    width:       SizeConfig.size110,
                    fit:         BoxFit.cover,
                    placeholder: (_, __) => Container(
                      width: SizeConfig.size110,
                      color: const Color(0xFFFDD835),
                      child: Center(child: Icon(Icons.work_outline, color: Colors.white, size: 32)),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      width: SizeConfig.size110,
                      color: const Color(0xFFFDD835),
                      child: Center(child: Icon(Icons.work_outline, color: Colors.white, size: 32)),
                    ),
                  ),
                ),

                // Job details
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(SizeConfig.size10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        // Company logo + name
                        Row(
                          children: [
                            Container(
                              width: 32, height: 32,
                              decoration: BoxDecoration(
                                color: AppColors.primaryColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: job.companyLogo?.isNotEmpty == true
                                  ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: CachedNetworkImage(imageUrl: job.companyLogo!, fit: BoxFit.cover),
                              )
                                  : Center(
                                child: CustomText(
                                  job.companyName?.substring(0, 1).toUpperCase() ?? 'B',
                                  fontSize: SizeConfig.medium,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primaryColor,
                                ),
                              ),
                            ),
                            SizedBox(width: SizeConfig.size8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CustomText(
                                    job.jobTitle ?? '',
                                    fontSize: SizeConfig.medium,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.mainTextColor,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  CustomText(
                                    job.companyName ?? '',
                                    fontSize: SizeConfig.small,
                                    fontWeight: FontWeight.w400,
                                    color: AppColors.secondaryTextColor,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        Divider(color: AppColors.greyE5, height: SizeConfig.size16),

                        // Job details list
                        _buildJobDetail('Job type', job.jobType ?? '--'),
                        SizedBox(height: SizeConfig.size4),
                        _buildJobDetail('Min Experience', job.minExperience ?? '--'),
                        SizedBox(height: SizeConfig.size4),
                        _buildJobDetail('Monthly Pay', job.salaryRange ?? '--'),
                        SizedBox(height: SizeConfig.size4),
                        _buildJobDetail('Job Location', job.location ?? '--'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJobDetail(String label, String value) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: '$label: ',
            style: TextStyle(
              fontSize: SizeConfig.small,
              fontWeight: FontWeight.w400,
              color: AppColors.secondaryTextColor,
              fontFamily: AppConstants.OpenSans,
            ),
          ),
          TextSpan(
            text: value,
            style: TextStyle(
              fontSize: SizeConfig.small,
              fontWeight: FontWeight.w600,
              color: AppColors.mainTextColor,
              fontFamily: AppConstants.OpenSans,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Empty State ───
  Widget _buildEmptyState(BuildContext context) {
    return InkWell(
      onTap: onAddJob,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: SizeConfig.size24),
        decoration: BoxDecoration(
          color: AppColors.primaryColor.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.primaryColor.withValues(alpha: 0.2),
            width: 1.5,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56, height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.work_outline_rounded, color: AppColors.primaryColor, size: 28),
            ),
            SizedBox(height: SizeConfig.size12),
            CustomText(
              'No Job Posts Yet',
              fontSize: SizeConfig.medium,
              fontWeight: FontWeight.w600,
              color: AppColors.mainTextColor,
            ),
            SizedBox(height: SizeConfig.size4),
            CustomText(
              'Post a job to find the right candidate',
              fontSize: SizeConfig.small,
              fontWeight: FontWeight.w400,
              color: AppColors.secondaryTextColor,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: SizeConfig.size14),
            Container(
              padding: EdgeInsets.symmetric(horizontal: SizeConfig.size16, vertical: SizeConfig.size8),
              decoration: BoxDecoration(
                color: AppColors.primaryColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.add_rounded, color: Colors.white, size: 16),
                  SizedBox(width: SizeConfig.size4),
                  CustomText(
                    'Post a Job',
                    fontSize: SizeConfig.small,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}