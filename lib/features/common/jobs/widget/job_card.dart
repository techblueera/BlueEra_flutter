import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/core/services/open_googlemap_diraction.dart';
import 'package:BlueEra/features/common/auth/model/get_all_jobs_model.dart';
import 'package:BlueEra/features/common/jobs/controller/job_screen_controller.dart';
import 'package:BlueEra/features/common/jobs/view/job_applications.dart';
import 'package:BlueEra/features/common/jobs/view/job_details_screen.dart';
import 'package:BlueEra/l10n/app_localizations.dart';
import 'package:BlueEra/widgets/common_circular_profile_image.dart';
import 'package:BlueEra/widgets/common_horizontal_divider.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/image_view_screen.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class JobCard extends StatelessWidget {
  final Jobs? job;
  final double headerHeight;

  JobCard({
    super.key,
    this.job,
    required this.headerHeight
  });

  final jobScreenController = JobScreenController();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: SizeConfig.size10),
      child: InkWell(
        onTap: () {
          if (isIndividual()) {
            Get.to(() => JobDetailScreen(
                  jobId: job?.sId.toString() ?? "",
                  isPostApply: AppConstants.APPLY_NOW,
                  isPostDirection: AppConstants.DIRECTION,
                  isPostEdit: '',
                  isPostCreate: '',
                ));
          }
          if (isBusiness()) {
            Get.to(() => JobDetailScreen(
                  jobId: job?.sId.toString() ?? "",
                  isPostDirection: '',
                  isPostApply: '',
                  isPostEdit: '',
                  isPostCreate: '',
                ));
          }
        },
        child: Container(
          height:
              isBusiness() ? SizeConfig.size200 - 15 : SizeConfig.size200 + 5,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10.0),
            color: AppColors.white,
          ),
          child: Row(
            children: [
              InkWell(
                onTap: () {
                  navigatePushTo(
                    context,
                    ImageViewScreen(
                      appBarTitle: AppLocalizations.of(context)!.imageViewer,
                      imageUrls: [job?.jobPostImage ?? ""],
                      initialIndex: 0,
                    ),
                  );
                },
                child: SizedBox(
                  width: SizeConfig.screenWidth * 0.35,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.horizontal(
                        left: Radius.circular(10.0)),
                    child: CachedNetworkImage(
                      imageUrl: job?.jobPostImage ?? "",
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      errorWidget: (context, url, error) => Container(
                        width: SizeConfig.screenWidth,
                        height: SizeConfig.size140,
                        color: Colors.grey[300],
                        child:
                            LocalAssets(imagePath: AppIconAssets.blueEraIcon),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                      left: SizeConfig.size14,
                      right: SizeConfig.size12,
                      top: SizeConfig.size10,
                      bottom: SizeConfig.size10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // SizedBox(height: SizeConfig.size5,),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          if (isIndividual()) ...[
                            CommonCircularImage(
                              url: job?.businessDetails?.buisness_logo ?? "",
                              title: job?.businessDetails?.businessName,
                            ),
                            SizedBox(width: SizeConfig.size10),
                          ],

                          Expanded(
                            child: Container(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CustomText(
                                    (isBusiness())
                                        ? job?.jobTitle
                                        : job?.companyName ?? "",
                                    fontSize: SizeConfig.medium,
                                    color: AppColors.black28,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  /*CustomText(
                                    "Posted On ${formatMonthStringDate(job?.createdAt.toString() ?? "")}",
                                    fontSize: SizeConfig.extraSmall8,
                                    color: AppColors.secondaryTextColor,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),*/
                                ],
                              ),
                            ),
                          ),

                          // Three dots menu
                          if ((accountTypeGlobal.toUpperCase() ==
                              AppConstants.business))
                            Container(
                              width: SizeConfig.size20,
                              height: SizeConfig.size30,
                              child: PopupMenuButton<String>(
                                padding: EdgeInsets.zero,
                                offset: const Offset(-6, 36),
                                color: AppColors.white,
                                elevation: 8,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                                onSelected: (value) async {
                                  //Get.find<JobScreenController>().jobsData.value = job ;
                                  if ((job?.status == AppConstants.ON_HOLD) ||
                                      (job?.status == AppConstants.CLOSED)) {
                                    switch (value) {
                                      case 'Un Hide':
                                        final Map<String, dynamic> params = {
                                          ApiKeys.status: AppConstants.OPEN,
                                        };

                                        await jobScreenController
                                            .updateJobPostDetailsApi(
                                          jobId: job?.sId ?? "",
                                          params: params,
                                        );
                                        await jobScreenController
                                            .getAllJobsApi();

                                        break;

                                      case 'Open Vacancy':
                                        // Handle close vacancy action
                                        final Map<String, dynamic> params = {
                                          ApiKeys.status: AppConstants.OPEN,
                                        };

                                        await jobScreenController
                                            .updateJobPostDetailsApi(
                                          jobId: job?.sId ?? "",
                                          params: params,
                                        );
                                        break;
                                    }
                                  } else {
                                    switch (value) {
                                      case 'Edit':
                                        final jobId =
                                            job?.sId?.toString().trim() ?? '';

                                        // Additional validation
                                        if (jobId.isEmpty) {
                                          commonSnackBar(
                                            message:
                                                'Job ID is missing. Cannot edit this job.',
                                          );

                                          return;
                                        }

                                        // Use exactly the same navigation approach as JobDetailsScreen
                                        Navigator.pushNamed(
                                            context,
                                            RouteHelper
                                                .getCreateJobPostScreenRoute(),
                                            arguments: {
                                              'isEditMode': true,
                                              'jobId': jobId,
                                            });
                                        // Handle edit action
                                        break;
                                      case 'Hide':
                                        final Map<String, dynamic> params = {
                                          ApiKeys.status: "On Hold",
                                        };

                                        await jobScreenController
                                            .updateJobPostDetailsApi(
                                          jobId: job?.sId ?? "",
                                          params: params,
                                        );
                                        await jobScreenController
                                            .getAllJobsApi();

                                        break;
                                      case 'Share':
                                        // Handle share action
                                        break;

                                      case 'Close Vacancy':
                                        // Handle close vacancy action
                                        print('Close vacancy: ${job?.sId}');
                                        final Map<String, dynamic> params = {
                                          ApiKeys.status: "Closed",
                                        };

                                        await jobScreenController
                                            .updateJobPostDetailsApi(
                                          jobId: job?.sId ?? "",
                                          params: params,
                                        );
                                        break;
                                    }
                                  }
                                  print('Selected: $value');
                                },
                                icon: Icon(
                                  Icons.more_vert,
                                  color: AppColors.black28,
                                  size: SizeConfig.size20,
                                ),
                                itemBuilder: (context) =>
                                    _createPopupJobCardItems(),
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: SizeConfig.size5),
                      CommonHorizontalDivider(
                          color: AppColors.grey9A, height: 0.5),
                      SizedBox(height: SizeConfig.size4),

                      /// 🔵 Job Info (Flexible to fit available space)
                      if (isIndividual())
                        _buildJobDescriptionContent(
                            title: 'Job title: ',
                            subtitle: job?.jobTitle ?? 'Job Title'),
                      _buildJobDescriptionContent(
                          title: 'Job type: ',
                          subtitle:
                              '${job?.jobType ?? "Job Type"} - ${job?.workMode ?? "Work Mode"}'),
                      _buildJobDescriptionContent(
                          title: 'Min Experience: ',
                          subtitle: '${job?.experience ?? 0} yrs'),
                      _buildJobDescriptionContent(
                          title: 'Monthly Pay: ',
                          subtitle:
                              '₹${formatIndianNumber(job?.compensation?.minSalary ?? 0)} to ₹${formatIndianNumber(job?.compensation?.maxSalary ?? 0)}'),
                      _buildJobDescriptionContent(
                          title: 'Job Location: ',
                          subtitle: job?.location?.addressString ?? 'Location'),
                      SizedBox(
                        height: SizeConfig.size10,
                      ),

                      /// 🔵 Bottom Buttons
                      ((accountTypeGlobal.toUpperCase() ==
                              AppConstants.business))
                          ? PositiveCustomBtn(
                              borderColor: AppColors.primaryColor,
                              textColor: AppColors.primaryColor,
                              bgColor: AppColors.white,
                              height: SizeConfig.size32,
                              onTap: () {
                                Get.to(JobApplicationsScreen(
                                  jobsData: job,
                                  headerHeight: headerHeight,
                                ));
                              },
                              title: (job?.applications?.isNotEmpty ?? false)
                                  ? "Applications (${job?.applications?.length}) "
                                  : "Applications")
                          : Row(
                              children: [
                                Expanded(
                                  child: PositiveCustomBtn(
                                    height: SizeConfig.size32,
                                    onTap: () {
                                      if (job != null) {
                                        openGoogleMaps(
                                            locationModel: LocationModel(
                                                latitude: double.tryParse(job?.location?.latitude ?? "0.0") ?? 0.0,
                                                longitude: double.tryParse(job?.location?.longitude ?? "0.0") ?? 0.0,
                                                address: job
                                                    ?.location?.addressString));
                                      }
                                    },
                                    title: 'Directions',
                                    bgColor: AppColors.white,
                                    borderColor: AppColors.primaryColor,
                                    textColor: AppColors.primaryColor,
                                    fontSize: SizeConfig.small,
                                  ),
                                ),
                                SizedBox(width: SizeConfig.size8),
                                Expanded(
                                  child: PositiveCustomBtn(
                                    height: SizeConfig.size32,
                                    onTap: () {
                                      Get.to(() => JobDetailScreen(
                                            jobId: job?.sId.toString() ?? "",
                                            isPostDirection:
                                                AppConstants.DIRECTION,
                                            isPostApply: AppConstants.APPLY_NOW,
                                            isPostEdit: '',
                                            isPostCreate: '',
                                          ));
                                    },
                                    title: 'Apply Now',
                                    fontSize: SizeConfig.small,
                                  ),
                                ),
                              ],
                            ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildJobDescriptionContent(
      {required String title, required String subtitle}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: SizeConfig.size1),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(
            title,
            fontSize: SizeConfig.small,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            color: AppColors.secondaryTextColor,
          ),
          Flexible(
            child: CustomText(
              subtitle,
              fontSize: SizeConfig.small,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              color: AppColors.mainTextColor,
            ),
          ),
        ],
      ),
    );
  }

  // Method to create popup menu items based on job ownership
  List<PopupMenuEntry<String>> _createPopupJobCardItems() {
    final items = ((job?.status == AppConstants.ON_HOLD) ||
            (job?.status == AppConstants.CLOSED))
        ? <Map<String, dynamic>>[
            {'icon': AppIconAssets.eyeIcon, 'title': 'Un Hide'},
            {'icon': AppIconAssets.openVacancy, 'title': 'Open Vacancy'}
          ]
        : <Map<String, dynamic>>[
            {'icon': AppIconAssets.tablerEditIcon, 'title': 'Edit'},
            {'icon': AppIconAssets.hide, 'title': 'Hide'},
            {'icon': AppIconAssets.uploadIcon, 'title': 'Share'},
            {
              'icon': AppIconAssets.uilSuitcaseOutlinedIcon,
              'title': 'Close Vacancy'
            },
          ];

    final List<PopupMenuEntry<String>> entries = [];

    for (int i = 0; i < items.length; i++) {
      entries.add(
        PopupMenuItem<String>(
          height: SizeConfig.size35,
          value: items[i]['title'],
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              LocalAssets(
                  imagePath: items[i]['icon'],
                  height: SizeConfig.size20,
                  width: SizeConfig.size20),
              SizedBox(width: SizeConfig.size5),
              CustomText(
                items[i]['title'],
                fontSize: SizeConfig.medium,
                color: AppColors.black30,
              ),
            ],
          ),
        ),
      );

      if (i != items.length - 1) {
        entries.add(
          const PopupMenuItem<String>(
            enabled: false,
            padding: EdgeInsets.zero,
            height: 1,
            child: Divider(
              indent: 10,
              endIndent: 10,
              height: 1,
              thickness: 0.2,
              color: AppColors.grey99,
            ),
          ),
        );
      }
    }

    return entries;
  }
}
