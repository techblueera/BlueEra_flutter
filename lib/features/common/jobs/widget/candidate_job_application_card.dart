import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/api/model/application_candidate_model.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/home/controller/home_screen_controller.dart';
import 'package:BlueEra/features/common/jobs/controller/applied_job_controller.dart';
import 'package:BlueEra/features/common/jobs/controller/job_screen_controller.dart';
import 'package:BlueEra/features/common/jobs/view/application_card.dart';
import 'package:BlueEra/widgets/custom_check_box.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/setup_scroll_visibility_notification.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CandidateJobApplicationCard extends StatefulWidget {
  const CandidateJobApplicationCard({
    super.key,
    required this.onHeaderVisibilityChanged,
    required this.jobId,
    required this.status,
    required this.headerHeight,
  });

  final Function(bool isVisible) onHeaderVisibilityChanged;
  final String? status;
  final String? jobId;
  final double headerHeight;

  @override
  State<CandidateJobApplicationCard> createState() =>
      _CandidateJobApplicationCardState();
}

class _CandidateJobApplicationCardState
    extends State<CandidateJobApplicationCard> {
  final ScrollController _scrollController = ScrollController();
  final appliedController = Get.find<AppliedJobController>();

  @override
  void initState() {
    apiCalling();
    super.initState();
  }

  apiCalling() async {
    await appliedController.getCandidateJobStatusController(
        jobStatus: widget.status, jobId: widget.jobId);
  }

  @override
  Widget build(BuildContext context) {
    return setupScrollVisibilityNotification(
      controller: _scrollController,
      headerHeight: widget.headerHeight,
      // onVisibilityChanged: (visible) {
      //   if (_isVisible != visible && mounted) {
      //     setState(() => _isVisible = visible);
      //     widget.onHeaderVisibilityChanged.call(visible);
      //   }
      // },
      onVisibilityChanged: (visible, offset) {
        final controller = Get.find<JobScreenController>();
        final currentOffset = controller.headerOffset.value;

        // Linear animation step (same speed up/down)
        const step = 0.2; // smaller = smoother, larger = faster

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
      child: SafeArea(
        child: Obx(() {
          if (appliedController
                  .applicationJobCandidateJobResponse.value.status ==
              Status.COMPLETE) {
            if (appliedController.applicationsCandidateList.isNotEmpty) {
              return RefreshIndicator(
                onRefresh: () async {
                  if(Get.find<JobScreenController>().headerOffset.value != 0.0)
                    return;

                  await apiCalling();
                },
                child: Column(
                  children: [
                    // Action buttons section
                    if (widget.status?.isNotEmpty ?? false) ...[
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: SizeConfig.size20,
                          vertical: SizeConfig.size10,
                        ),
                        child: Row(
                          children: [
                            // Select All checkbox
                            Row(
                              children: [
                                Obx(() => CustomCheckBox(
                                      isChecked:
                                          appliedController.selectAll.value,
                                      onChanged: widget.status?.toLowerCase() ==
                                              AppConstants.InterviewScheduled
                                                  .toLowerCase()
                                          ? appliedController
                                              .toggleSelectAllReschedule
                                          : appliedController.toggleSelectAll,
                                      size: 20,
                                      activeColor: AppColors.primaryColor,
                                      borderColor: AppColors.secondaryTextColor,
                                    )),
                                SizedBox(width: SizeConfig.size8),
                                Obx(() => CustomText(
                                      "Select All (${appliedController.selectedCount})",
                                      fontSize: SizeConfig.small,
                                      color: AppColors.secondaryTextColor,
                                    )),
                              ],
                            ),
                            Spacer(),
                            // Schedule Interview button

                          ],
                        ),
                      ),
                      // Action buttons row
                      if ((widget.status?.toLowerCase() !=
                          AppConstants.Hired.toLowerCase()))
                        Container(
                          width: Get.width,
                          // width: Get.width,
                          padding: EdgeInsets.only(
                            left: SizeConfig.size20,
                            right: SizeConfig.size20,
                            bottom: SizeConfig.size15,
                          ),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (widget.status?.toLowerCase() ==
                                    AppConstants.Shortlisted.toLowerCase() ||
                                    widget.status?.toLowerCase() ==
                                        AppConstants.InterviewScheduled
                                            .toLowerCase())
                                  _ActionBtn(
                                    title:  ((widget.status?.toLowerCase() ==
                                        AppConstants.InterviewScheduled
                                            .toLowerCase()) ||
                                        (widget.status?.toLowerCase() ==
                                            AppConstants.Connect
                                                .toLowerCase()))
                                        ? "Reschedule Interview"
                                        : "Schedule Interview",
                                    onTap: () =>appliedController.bulkScheduleInterviews(
                                        context,
                                        (widget.status?.toLowerCase() ==
                                            AppConstants.InterviewScheduled
                                                .toLowerCase())
                                            ? true
                                            : false),
                                    borderColor: AppColors.red00,
                                    textColor: AppColors.red00,
                                  ),
                                SizedBox(width: SizeConfig.size8),

                                // _ActionBtn(
                                //   title: "Send Message",
                                //   onTap: () =>
                                //       appliedController.bulkSendMessage(),
                                //   borderColor: AppColors.primaryColor,
                                //   textColor: AppColors.primaryColor,
                                // ),
                                // SizedBox(width: SizeConfig.size8),
                                // _ActionBtn(
                                //   title: "Send assignment",
                                //   onTap: () =>
                                //       appliedController.bulkSendAssignment(),
                                //   borderColor: AppColors.primaryColor,
                                //   textColor: AppColors.primaryColor,
                                // ),
                                // SizedBox(width: SizeConfig.size8),
                                _ActionBtn(
                                  title: "Not Interested",
                                  onTap: () => appliedController
                                      .bulkMarkNotInterested(context),
                                  borderColor: AppColors.red00,
                                  textColor: AppColors.red00,
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],

                    // Application list
                    Expanded(
                      child: ListView.builder(
                          padding: EdgeInsets.only(
                              right: SizeConfig.size15,
                              left: SizeConfig.size15),
                          itemBuilder: (context, applicationIndex) {
                            ApplicationsCandidateList? userData =
                                appliedController.applicationsCandidateList[
                                        applicationIndex] ??
                                    null;
                            return ApplicationCard(
                              index: applicationIndex,
                              jobDetails: appliedController.jobDetails?.value ??
                                  JobDetails(),
                              data: userData ?? ApplicationsCandidateList(),
                              buttonAction: () {
                                apiCalling();
                              },
                              status: widget.status ?? "",
                            );
                          },
                          itemCount: appliedController
                              .applicationsCandidateList.length),
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
      ),
    );
  }
}

// Action button widget
class _ActionBtn extends StatelessWidget {
  final String title;
  final VoidCallback onTap;
  final Color borderColor;
  final Color textColor;

  const _ActionBtn({
    required this.title,
    required this.onTap,
    required this.borderColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.size12,
          vertical: SizeConfig.size6,
        ),
        decoration: BoxDecoration(
            color: AppColors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppColors.primaryColor)),
        child: CustomText(
          title,
          fontSize: SizeConfig.small,
          fontWeight: FontWeight.w500,
          color: AppColors.primaryColor,
        ),
      ),
    );

  }
}
