import 'dart:ui';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
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
      jobTitle: json['job_title'],
      companyName: json['company_name'],
      companyLogo: json['company_logo'],
      posterImage: json['poster_image'],
      jobType: json['job_type'],
      minExperience: json['min_experience'],
      salaryRange: json['salary_range'],
      location: json['location'],
    );
  }

  Map<String, dynamic> toJson() => {
        'job_title': jobTitle,
        'company_name': companyName,
        'company_logo': companyLogo,
        'poster_image': posterImage,
        'job_type': jobType,
        'min_experience': minExperience,
        'salary_range': salaryRange,
        'location': location,
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
              : _buildEmptyState(_dummyJob, context),
        ],
      ),
    );
  }

  // ─── Job Card ───
  Widget _buildJobCard(JobPost job, BuildContext context) {
    return CustomFormCard(
      padding: EdgeInsets.all(10),
      border: Border.all(color: AppColors.greyE5),
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
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                  child: CachedNetworkImage(
                    imageUrl: job.posterImage ?? '',
                    width: SizeConfig.size110,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      width: SizeConfig.size110,
                      color: const Color(0xFFFDD835),
                      child: Center(
                          child: Icon(Icons.work_outline,
                              color: Colors.white, size: 32)),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      width: SizeConfig.size110,
                      color: const Color(0xFFFDD835),
                      child: Center(
                          child: Icon(Icons.work_outline,
                              color: Colors.white, size: 32)),
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
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: AppColors.primaryColor
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: job.companyLogo?.isNotEmpty == true
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: CachedNetworkImage(
                                          imageUrl: job.companyLogo!,
                                          fit: BoxFit.cover),
                                    )
                                  : Center(
                                      child: CustomText(
                                        job.companyName
                                                ?.substring(0, 1)
                                                .toUpperCase() ??
                                            'B',
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

                        Divider(
                            color: AppColors.greyE5, height: SizeConfig.size16),

                        // Job details list
                        _buildJobDetail('Job type', job.jobType ?? '--'),
                        SizedBox(height: SizeConfig.size4),
                        _buildJobDetail(
                            'Min Experience', job.minExperience ?? '--'),
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

  // ─── Dummy data for empty state ───
  static const _dummyJob = JobPost(
    jobTitle: 'Data Entry Operator',
    companyName: 'BlueCs Limited',
    companyLogo: '',
    posterImage: '',
    jobType: 'Full Time - On Site',
    minExperience: '5 yrs',
    salaryRange: '15,000 to 20,000',
    location: 'Gomti Nagar, Lucknow',
  );

  // ─── Empty State — dummy card with overlay ───
  Widget _buildEmptyState(JobPost job, BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        CustomFormCard(
          padding: EdgeInsets.all(10),
          border: Border.all(color: AppColors.greyE5),
          child:    Column(
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
                        topLeft: Radius.circular(12),
                        bottomLeft: Radius.circular(12),
                      ),
                      child: CachedNetworkImage(
                        imageUrl: job.posterImage ?? '',
                        width: SizeConfig.size110,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          width: SizeConfig.size110,
                          color: const Color(0xFFFDD835),
                          child: Center(
                              child: Icon(Icons.work_outline,
                                  color: Colors.white, size: 32)),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          width: SizeConfig.size110,
                          color: const Color(0xFFFDD835),
                          child: Center(
                              child: Icon(Icons.work_outline,
                                  color: Colors.white, size: 32)),
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
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryColor
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: job.companyLogo?.isNotEmpty == true
                                      ? ClipRRect(
                                    borderRadius:
                                    BorderRadius.circular(8),
                                    child: CachedNetworkImage(
                                        imageUrl: job.companyLogo!,
                                        fit: BoxFit.cover),
                                  )
                                      : Center(
                                    child: CustomText(
                                      job.companyName
                                          ?.substring(0, 1)
                                          .toUpperCase() ??
                                          'B',
                                      fontSize: SizeConfig.medium,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primaryColor,
                                    ),
                                  ),
                                ),
                                SizedBox(width: SizeConfig.size8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
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

                            Divider(
                                color: AppColors.greyE5,
                                height: SizeConfig.size16),

                            // Job details list
                            _buildJobDetail('Job type', job.jobType ?? '--'),
                            SizedBox(height: SizeConfig.size4),
                            _buildJobDetail(
                                'Min Experience', job.minExperience ?? '--'),
                            SizedBox(height: SizeConfig.size4),
                            _buildJobDetail(
                                'Monthly Pay', job.salaryRange ?? '--'),
                            SizedBox(height: SizeConfig.size4),
                            _buildJobDetail(
                                'Job Location', job.location ?? '--'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Blur overlay
        Positioned.fill(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10.0),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10.0),
                  color: AppColors.black.withValues(alpha: 0.5),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    LocalAssets(
                      imagePath: AppImageAssets.noMeContent,
                      height: SizeConfig.size60,
                      width: SizeConfig.size60,
                    ),
                    const SizedBox(height: 6.0),
                    CustomText(
                      'You Have Not Post\nAny Job',
                      fontSize: SizeConfig.extraSmall,
                      fontWeight: FontWeight.w600,
                      color: AppColors.white,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10.0),
                    // Glassmorphism button
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6.0),
                      child: BackdropFilter(
                        filter:
                        ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10.0, vertical: 6.0),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10.0),
                            color:
                            AppColors.primaryColor,
                            border: Border.all(
                              color: AppColors.primaryColor,
                            ),
                          ),
                          child: CustomText(
                            'Post Now',
                            fontSize: SizeConfig.small,
                            fontWeight: FontWeight.w600,
                            color: AppColors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
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
}
