import 'dart:io';

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
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
import 'package:BlueEra/widgets/setup_scroll_visibility_notification.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class AllJobPostScreen extends StatefulWidget {
  final Function(bool isVisible) onHeaderVisibilityChanged;
  final String? tabName;
  final double headerHeight;

  const AllJobPostScreen(
      {super.key,
      required this.onHeaderVisibilityChanged,
      this.tabName,
      required this.headerHeight});

  @override
  State<AllJobPostScreen> createState() => _AllJobPostScreenState();
}

class _AllJobPostScreenState extends State<AllJobPostScreen> {
  final ScrollController _scrollController = ScrollController();
  final JobScreenController jobScreenController =
      Get.put(JobScreenController());

  @override
  void initState() {
    super.initState();
    apiCalling();
  }

  apiCalling() {
    if (widget.tabName == AppConstants.SCHEDULES) {
      if ((accountTypeGlobal.toUpperCase() == AppConstants.business)) {
        jobScreenController.getBusinessScheduleJobController();
      }
      if ((accountTypeGlobal.toUpperCase() == AppConstants.individual)) {
        jobScreenController.getCandidateScheduleJobController();
      }

      // fire API without await
    } else {
      jobScreenController.getAllJobsApi(); // fire API without await
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return setupScrollVisibilityNotification(
      controller: _scrollController,
      headerHeight: widget.headerHeight,
      onVisibilityChanged: (visible, offset) {
        final controller = Get.find<JobScreenController>();
        final currentOffset = controller.headerOffset.value;

        // Linear animation step (same speed up/down)
        const step = 0.25; // smaller = smoother, larger = faster

        double newOffset = currentOffset;

        if (visible) {
          // show header → decrease offset
          newOffset = (currentOffset - step).clamp(0.0, 1.0);
        } else {
          // hide header → increase offset
          newOffset = (currentOffset + step).clamp(0.0, 1.0);
        }

        controller.headerOffset.value = newOffset;

        controller.isHeaderVisible.value = visible;
        widget.onHeaderVisibilityChanged.call(visible);
      },
      child: Obx(() {
        if (jobScreenController.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return RefreshIndicator(
          onRefresh: () async {
            if(jobScreenController.headerOffset.value != 0.0)
              return;

            await apiCalling();
          },
          child: jobScreenController.jobsData?.isEmpty ?? true
              ? Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: CustomText(AppConstants.SCHEDULES == widget.tabName
                    ? "No Job Schedule Yet"
                    : 'No Jobs Available'),
              ))/*ListView(
                  physics: AlwaysScrollableScrollPhysics(),
                  children: [

                  ],
                )*/
              : ListView.builder(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.all(SizeConfig.size12),
                  itemCount: jobScreenController.jobsData?.length,
                  itemBuilder: (context, index) {
                    Jobs? job = jobScreenController.jobsData?[index];
                    return Padding(
                      padding: EdgeInsets.only(bottom: SizeConfig.size10),
                      child: InkWell(
                        onTap: () {
                          if (isIndividual()) {
                            
                            debugPrint("individual job card tapped");
                            Get.to(() => JobDetailScreen(
                                  jobId: job?.sId.toString() ?? "",
                                  isPostApply: AppConstants.APPLY_NOW,
                                  isPostDirection: AppConstants.DIRECTION,
                                  isPostEdit: '',
                                  isPostCreate: '',
                                ));
                          }
                          if (isBusiness()) {
                            debugPrint("business job card tapped");
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
                          height: isBusiness()
                              ? SizeConfig.size200 - 15
                              : SizeConfig.size200 + 5,
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
                                      appBarTitle: AppLocalizations.of(context)!
                                          .imageViewer,
                                      // imageUrls: [post?.author.profileImage ?? ''],
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
                                      // <-- Replace with your image URL from API
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      height: double.infinity,
                                      errorWidget: (context, url, error) =>
                                          Container(
                                        width: SizeConfig.screenWidth,
                                        height: SizeConfig.size140,
                                        color: Colors.grey[300],
                                        child: LocalAssets(
                                            imagePath:
                                                AppIconAssets.blueEraIcon),
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,

                                    children: [
                                      // SizedBox(height: SizeConfig.size5,),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: [
                                          if (isIndividual()) ...[
                                            CommonCircularImage(
                                              url: job?.businessDetails
                                                      ?.buisness_logo ??
                                                  "",
                                              title: job?.businessDetails
                                                  ?.businessName,
                                            ),
                                            SizedBox(width: SizeConfig.size10),
                                          ],

                                          Expanded(
                                            child: Container(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  CustomText(
                                                    (isBusiness())
                                                        ? job?.jobTitle
                                                        : job?.companyName ??
                                                            "N/A",
                                                    fontSize: SizeConfig.medium,
                                                    color: AppColors.black28,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                  CustomText(
                                                    "Posted On ${formatMonthStringDate(job?.createdAt.toString() ?? "")}",
                                                    fontSize:
                                                        SizeConfig.extraSmall8,
                                                    color: AppColors
                                                        .secondaryTextColor,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),

                                          // Three dots menu
                                          if ((accountTypeGlobal
                                                      .toUpperCase() ==
                                                  AppConstants.business) &&
                                              (widget.tabName !=
                                                  AppConstants.SCHEDULES))
                                            Container(
                                              width: SizeConfig.size20,
                                              height: SizeConfig.size30,
                                              child: PopupMenuButton<String>(
                                                padding: EdgeInsets.zero,
                                                offset: const Offset(-6, 36),
                                                color: AppColors.white,
                                                elevation: 8,
                                                shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10)),
                                                onSelected: (value) async {
                                                  //Get.find<JobScreenController>().jobsData.value = job ;
                                                  if ((job?.status ==
                                                          AppConstants
                                                              .ON_HOLD) ||
                                                      (job?.status ==
                                                          AppConstants
                                                              .CLOSED)) {
                                                    switch (value) {
                                                      case 'Un Hide':
                                                        final Map<String,
                                                            dynamic> params = {
                                                          ApiKeys.status:
                                                              AppConstants.OPEN,
                                                        };

                                                        await jobScreenController
                                                            .updateJobPostDetailsApi(
                                                          jobId: job?.sId ?? "",
                                                          params: params,
                                                        );

                                                        await apiCalling();

                                                        break;

                                                      case 'Open Vacancy':
                                                        // Handle close vacancy action
                                                        final Map<String,
                                                            dynamic> params = {
                                                          ApiKeys.status:
                                                              AppConstants.OPEN,
                                                        };

                                                        await jobScreenController
                                                            .updateJobPostDetailsApi(
                                                          jobId: job?.sId ?? "",
                                                          params: params,
                                                        );
                                                        await apiCalling();

                                                        break;
                                                    }
                                                  } else {
                                                    switch (value) {
                                                      case 'Edit':
                                                        final jobId = job?.sId
                                                                ?.toString()
                                                                .trim() ??
                                                            '';

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
                                                              'isEditMode':
                                                                  true,
                                                              'jobId': jobId,
                                                            });
                                                        // Handle edit action
                                                        break;
                                                      case 'Share':
                                                        // Share job: deep link + optional image preview
                                                        try {
                                                          final linkShare = jobDeepLink(jobId: job?.sId?.toString());

                                                          XFile? xFile;
                                                          final imageUrl = job?.jobPostImage;
                                                          if (imageUrl != null && imageUrl.isNotEmpty) {
                                                            xFile = await urlToCachedXFile(imageUrl);
                                                          }

                                                          await SharePlus.instance.share(ShareParams(
                                                            text: linkShare,
                                                            subject: job?.jobTitle,
                                                            previewThumbnail: xFile,
                                                          ));

                                                          if (xFile != null) {
                                                            final file = File(xFile.path);
                                                            if (await file.exists()) {
                                                              await file.delete();
                                                              print("🗑️ File deleted from cache.");
                                                            }
                                                          }
                                                        } catch (e) {
                                                          print("job card share failed $e");
                                                        }
                                                        break;
                                                      case 'Hide':
                                                        final Map<String,
                                                            dynamic> params = {
                                                          ApiKeys.status:
                                                              "On Hold",
                                                        };

                                                        await jobScreenController
                                                            .updateJobPostDetailsApi(
                                                          jobId: job?.sId ?? "",
                                                          params: params,
                                                        );
                                                        await apiCalling();

                                                        break;
                                                      case 'Close Vacancy':
                                                        final Map<String,
                                                            dynamic> params = {
                                                          ApiKeys.status:
                                                              "Closed",
                                                        };

                                                        await jobScreenController
                                                            .updateJobPostDetailsApi(
                                                          jobId: job?.sId ?? "",
                                                          params: params,
                                                        );
                                                        await apiCalling();

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
                                                    createPopupJobCardItems(
                                                        status: job?.status),
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
                                        buildJobDescriptionContent(
                                            title: 'Job title: ',
                                            subtitle: job?.jobTitle ?? 'N/A'),
                                      buildJobDescriptionContent(
                                          title: 'Job type: ',
                                          subtitle:
                                              '${job?.jobType ?? "N/A"} - ${job?.workMode ?? "N/A"}'),
                                      buildJobDescriptionContent(
                                          title: 'Min Experience: ',
                                          subtitle:
                                              '${job?.experience ?? 0} yrs'),
                                      buildJobDescriptionContent(
                                          title: 'Monthly Pay: ',
                                          subtitle:
                                              '₹${formatIndianNumber(job?.compensation?.minSalary ?? 0)} to ₹ ${formatIndianNumber(job?.compensation?.maxSalary ?? 0)}'),
                                      buildJobDescriptionContent(
                                          title: 'Job Location: ',
                                          subtitle:
                                              job?.location?.addressString ??
                                                  'NA'),
                                      SizedBox(
                                        height: SizeConfig.size10,
                                      ),
// CustomText(job?.status),
                                      /// 🔵 Bottom Buttons
                                      ((accountTypeGlobal.toUpperCase() ==
                                              AppConstants.business))
                                          ? PositiveCustomBtn(
                                              borderColor:
                                                  AppColors.primaryColor,
                                              textColor: AppColors.primaryColor,
                                              bgColor: AppColors.white,
                                              height: SizeConfig.size32,
                                              onTap: () {
                                                if ((job?.applications
                                                            ?.length ??
                                                        0) >
                                                    0) {
                                                  Get.to(JobApplicationsScreen(
                                                    jobsData: job,
                                                    onHeaderVisibilityChanged:
                                                        widget
                                                            .onHeaderVisibilityChanged,
                                                    headerHeight:
                                                        widget.headerHeight,
                                                  ));
                                                } else {
                                                  commonSnackBar(
                                                      message:
                                                          "No application found");
                                                }
                                              },
                                              title: (job?.applications
                                                          ?.isNotEmpty ??
                                                      false)
                                                  ? "Applications (${job?.applications?.length}) "
                                                  : "Applications")
                                          : Row(
                                              children: [
                                                Expanded(
                                                  child: PositiveCustomBtn(
                                                    height: SizeConfig.size32,
                                                    onTap: () async {
                                                      if (job != null) {
                                                        XFile xFile = await urlToCachedXFile( job.jobPostImage??"");
                                                        // https://api.blueera.ai/api/post-service/app/post/
                                                       logs("xFile==== ${xFile.path}");
                                                        final linkShare="https://blueera.ai/app/job/${job.sId.toString()}";
                                                        logs("linkShare====${linkShare}");
                                                        // final shareUrl = postDeepLink(postId: job.sId.toString());
                                                        // final combinedText = shareUrl;
                                                        await SharePlus.instance.share(ShareParams(
                                                            text: linkShare,
                                                            subject: job.jobTitle,
                                                            previewThumbnail: xFile));
                                                        final file = File(xFile.path);
                                                        if (await file.exists()) {
                                                          await file.delete();
                                                          print("🗑️ File deleted from cache.");
                                                        }
                                                      // await  Share.share('https://blueera.ai/app/job/${(job.sId ?? "")}');
                                                        // openGoogleMaps(
                                                        //     locationModel: LocationModel(
                                                        //         latitude: double
                                                        //             .parse(job
                                                        //                     .location
                                                        //                     ?.latitude ??
                                                        //                 "0.0"),
                                                        //         longitude: double
                                                        //             .parse(job
                                                        //                     .location
                                                        //                     ?.longitude ??
                                                        //                 "0.0"),
                                                        //         address: job
                                                        //             .location
                                                        //             ?.addressString));
                                                      }
                                                    },
                                                    title: 'Share',
                                                    bgColor: AppColors.white,
                                                    borderColor:
                                                        AppColors.primaryColor,
                                                    textColor:
                                                        AppColors.primaryColor,
                                                    fontSize: SizeConfig.small,
                                                  ),
                                                ),
                                                SizedBox(
                                                    width: SizeConfig.size8),
                                                if (!(job?.isApplied ??
                                                        false) &&
                                                    job?.status
                                                            ?.toLowerCase() ==
                                                        "open")
                                                  Expanded(
                                                    child: PositiveCustomBtn(
                                                      height: SizeConfig.size32,
                                                      onTap: () {
                                                        Get.to(() =>
                                                            JobDetailScreen(
                                                              jobId: job?.sId
                                                                      .toString() ??
                                                                  "",
                                                              isPostDirection:
                                                                  AppConstants
                                                                      .DIRECTION,
                                                              isPostApply:
                                                                  AppConstants
                                                                      .APPLY_NOW,
                                                              isPostEdit: '',
                                                              isPostCreate: '',
                                                            ));
                                                      },
                                                      title: 'Apply Now',
                                                      fontSize:
                                                          SizeConfig.small,
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
                  },
                ),
        );
      }),
    );
  }
  Future<XFile> urlToCachedXFile(String fileUrl) async {
    // Get temp (cache) directory
    final tempDir = await getTemporaryDirectory();
    final fileName = fileUrl.split('/').last; // keep original name if possible
    final filePath = "${tempDir.path}/$fileName";

    // Download file into cache
    await Dio().download(fileUrl, filePath);

    // Return as XFile
    return XFile(filePath);
  }
}

Widget buildJobDescriptionContent(
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
List<PopupMenuEntry<String>> createPopupJobCardItems(
    {required String? status}) {
  final items =
      ((status == AppConstants.ON_HOLD) || (status == AppConstants.CLOSED))
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
