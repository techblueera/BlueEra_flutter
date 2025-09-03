import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/api/model/user_application_listing_model.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/home/controller/home_screen_controller.dart';
import 'package:BlueEra/features/common/jobs/controller/applied_job_controller.dart';
import 'package:BlueEra/features/common/jobs/controller/job_screen_controller.dart';
import 'package:BlueEra/features/common/jobs/widget/job_application_card.dart';
import 'package:BlueEra/widgets/common_dialog.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/setup_scroll_visibility_notification.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AppliedAllScreen extends StatefulWidget {
  AppliedAllScreen(
      {super.key,
      required this.onHeaderVisibilityChanged,
      required this.status,
        required this.headerHeight
      });

  final Function(bool isVisible) onHeaderVisibilityChanged;
  final String? status;
  final double headerHeight;

  @override
  State<AppliedAllScreen> createState() => _AppliedAllScreenState();
}

class _AppliedAllScreenState extends State<AppliedAllScreen> {
  final ScrollController _scrollController = ScrollController();
  final appliedController = Get.find<AppliedJobController>();
  int selectedIndex = 0;

  @override
  void initState() {
    apiCalling();
    super.initState();
  }

  apiCalling() async {
    await appliedController.getUserJobStatusController(
        jobStatus: widget.status);
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
        if (appliedController.appliedAllJobResponse.value.status ==
            Status.COMPLETE) {
          if (appliedController.appliedJobListing.isNotEmpty) {
            return RefreshIndicator(
              onRefresh: () async {
                if(Get.find<JobScreenController>().headerOffset.value != 0.0)
                  return;

                await apiCalling();
              },
              child: Column(
                children: [
                  if ((widget.status?.toLowerCase() ==
                      AppConstants.Hired.toLowerCase()))
                    Align(
                      alignment: Alignment.centerRight,
                      child: InkWell(
                        onTap: () async {
                          await commonConformationDialog(
                              context: context,
                              text: "Are you sure to clear your all job?",
                              confirmCallback: () async {
                                final applicationIDS = appliedController
                                    .appliedJobListing
                                    .map((data) => data?.id)
                                    .toList();
                                logs("applicationIDS==== ${applicationIDS}");
                                await appliedController
                                    .clearUserAppliedJobPostController(
                                        bodyReq: {
                                      ApiKeys.applicationIds: applicationIDS
                                    });

                                await apiCalling();
                              },
                              cancelCallback: () {
                                Get.back();
                              });
                        },
                        child: Padding(
                          padding: EdgeInsets.only(
                              right: SizeConfig.size15, top: SizeConfig.size10),
                          child: CustomText(
                            "Clear All (${appliedController.appliedJobListing.length})",
                            color: AppColors.primaryColor,
                          ),
                        ),
                      ),
                    ),
                  Expanded(
                    child: ListView.builder(
                        padding: EdgeInsets.only(top: SizeConfig.size5),
                        itemBuilder: (context, index) {
                          UserApplications? userData =
                              appliedController.appliedJobListing[index] ??
                                  null;
                          return JobApplicationCard(
                            jobPostImage: userData?.jobId?.jobPostImage ?? "",
                            jobTitle: userData?.jobId?.jobTitle ?? "",
                            companyName: "${userData?.jobId?.companyName}",
                            timeAgo: getTimeAgo(userData?.createdAt ?? ""),
                            location:
                                "${userData?.jobId?.location?.addressString}",
                            salary:
                                "₹ ${formatIndianNumber(userData?.jobId?.compensation?.minSalary ?? 0)} - ₹ ${formatIndianNumber(userData?.jobId?.compensation?.maxSalary ?? 0)} monthly",
                            jobType:
                                "${userData?.jobId?.jobType}, ${userData?.jobId?.workMode}",
                            verticalLineAsset: AppIconAssets.verticalLineIcon,
                            isShortlisted: false,
                            companyLogo: userData
                                    ?.jobId?.businessDetails?.buisnessLogo ??
                                "",
                            companyBusinessId:
                                userData?.jobId?.businessDetails?.id ?? "",
                            jobStatus: userData?.status ?? "",
                            applicationID: userData?.id ?? "",
                            jobID: userData?.jobId?.id ?? "",
                            feedBackSubmit: () {
                              apiCalling();
                              // setState(() {});
                            },
                            isFeedBackStatus:
                                userData?.hasSubmittedFeedback ?? false,
                            removeJobCallBack: () async {
                              await commonConformationDialog(
                                  context: context,
                                  text: "Are you sure to clear your job?",
                                  confirmCallback: () async {
                                    await appliedController
                                        .clearUserAppliedJobPostController(
                                            bodyReq: {
                                          ApiKeys.applicationIds: [userData?.id]
                                        });
                                    await apiCalling();
                                  },
                                  cancelCallback: () {
                                    Get.back();
                                  });
                            },
                          );
                        },
                        itemCount: appliedController.appliedJobListing.length),
                  ),
                ],
              ),
            );
          }
          return Container(
              width: Get.width,
              height: Get.height,
              alignment: Alignment.center,
              child: CustomText("No Job Listing Found"));
        }
        return Container(
            width: Get.width,
            height: Get.height,
            alignment: Alignment.center,
            child: CustomText("No Job Listing Found"));
      }),
    );
  }
}
