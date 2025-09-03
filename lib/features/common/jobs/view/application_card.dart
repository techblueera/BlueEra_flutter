import 'package:BlueEra/core/api/model/application_candidate_model.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/jobs/controller/applied_job_controller.dart';
import 'package:BlueEra/features/common/jobs/widget/interview_schedule_dialog.dart';
import 'package:BlueEra/features/common/jobs/widget/job_schedule_feedback_dialog.dart';
import 'package:BlueEra/widgets/common_circular_profile_image.dart';
import 'package:BlueEra/widgets/common_dialog.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_check_box.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

class ApplicationCard extends StatefulWidget {
  final int index;
  final String status;
  final ApplicationsCandidateList data;
  final JobDetails? jobDetails;
  final VoidCallback buttonAction;

  ApplicationCard({
    Key? key,
    required this.status,
    required this.index,
    required this.data,
    required this.jobDetails,
    required this.buttonAction,
  }) : super(key: key);

  @override
  State<ApplicationCard> createState() => _ApplicationCardState();
}

class _ApplicationCardState extends State<ApplicationCard> {
  final appliedController = Get.find<AppliedJobController>();

  String? currentStatus;

  @override
  Widget build(BuildContext context) {
    currentStatus = widget.data.status?.toLowerCase();
    return Container(
      padding: EdgeInsets.all(SizeConfig.size15),
      margin: EdgeInsets.only(bottom: SizeConfig.size20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.status.isNotEmpty) ...[
                Obx(() => CustomCheckBox(
                      isChecked: (widget.status.toLowerCase() ==
                              AppConstants.InterviewScheduled.toLowerCase())
                          ? appliedController.selectedApplications[
                                  widget.data.interviewId] ??
                              false
                          : appliedController
                                  .selectedApplications[widget.data.id] ??
                              false,
                      onChanged: () {
                        if (widget.status.toLowerCase() ==
                            AppConstants.InterviewScheduled.toLowerCase()) {
                          if (widget.data.interviewId != null) {
                            appliedController
                                .toggleApplicationSelectionReschedule(
                                    widget.data.interviewId!);
                          }
                        } else {
                          if (widget.data.id != null) {
                            appliedController
                                .toggleApplicationSelection(widget.data.id!);

                          }
                        }
                      },
                      size: SizeConfig.size20,
                      activeColor: AppColors.primaryColor,
                      borderColor: AppColors.secondaryTextColor,
                    )),
                SizedBox(width: SizeConfig.size10),
              ],
              InkWell(
                onTap: () {
                  openPersonalProfile(userID: widget.data.resumeData?.userId);
                },
                child: CommonCircularImage(
                  url: widget.data.resumeData?.profilePicture,
                  title: widget.data.candidateName,
                ),
              ),
              SizedBox(width: SizeConfig.size10),
              Expanded(
                child: InkWell(
                  onTap: () {
                    openPersonalProfile(userID: widget.data.resumeData?.userId);
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        widget.data.candidateName,
                        fontSize: SizeConfig.size15,
                        fontWeight: FontWeight.bold,
                      ),
                      SizedBox(height: SizeConfig.size5),
                      widget.jobDetails?.jobTitle != null &&
                              ((widget.data.userAge != null))&&((widget.data.userAge??0)>0)
                          ? CustomText(
                              '${widget.jobDetails?.jobTitle} • Age - ${widget.data.userAge} yrs',
                              fontSize: SizeConfig.size12,
                              color: AppColors.black30,
                            )
                          : (widget.jobDetails?.jobTitle?.isNotEmpty ?? false)
                              ? CustomText(
                                  '${widget.jobDetails?.jobTitle}',
                                  fontSize: SizeConfig.size12,
                                  color: AppColors.black30,
                                )
                              : ((widget.data.userAge ?? 0) > 0)
                                  ? CustomText(
                                      '${widget.jobDetails?.jobTitle} • Age - ${widget.data.userAge} yrs',
                                      fontSize: SizeConfig.size12,
                                      color: AppColors.black30,
                                    )
                                  : SizedBox(),
                    ],
                  ),
                ),
              ),
              // SvgPicture.asset(
              //   AppIconAssets.chat,
              //   width: SizeConfig.size35,
              //   height: SizeConfig.size35,
              //   color: AppColors.black30,
              // ),
            ],
          ),

          SizedBox(height: SizeConfig.size15),

          Row(
            // Inside the build method, in the Row at the beginning of the card

            children: [
              Expanded(
                child: Column(
                  children: [
                    _buildDetailRow(
                        AppIconAssets.educationJobIcon,
                        widget.data.resumeData?.education?.firstOrNull
                                ?.highestQualification ??
                            "N/A"),
                    _buildDetailRow(
                        AppIconAssets.job,
                        widget.data.resumeData?.currentJob
                                    ?.currentCompanyName !=
                                null
                            ? "${widget.data.resumeData?.currentJob?.currentCompanyName ?? "N/A"} (Current)"
                            : "N/A"),
                    _buildDetailRow(
                        AppIconAssets.experienceJobIcon,
                        widget.data.totalExperience != null
                            ? "${widget.data.totalExperience} Experience"
                            : "N/A"),
                    _buildDetailRow(
                        AppIconAssets.job, "${widget.jobDetails?.jobTitle}"),
                    _buildDetailRow(AppIconAssets.moneyOutlinedIcon,
                        "₹${formatNumber(widget.data.resumeData?.salaryDetails?.monthlyTotalEarning ?? 0)} monthly"),
                    _buildDetailRow(AppIconAssets.location_outline,
                        widget.data.address?.city ?? "N/A"),
                  ],
                ),
              ),
              SizedBox(width: SizeConfig.size50),
              Container(
                width: SizeConfig.size40 * 2,
                height: SizeConfig.size40 * 2.5,
                decoration: BoxDecoration(
                  // border: Border.all(color: AppColors.primaryColor, width: 1),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: InkWell(
                    onTap: () async {
                    await  appliedController
                          .candidatePreviewResumeController( candidateResumeId: widget.data.resumeData?.id);

                    },
                    child: LocalAssets(imagePath: AppImageAssets.dummy_resume),
                  ),
                ),
              ),
            ],
          ),

          /// Bottom buttons
          if ((currentStatus != AppConstants.Rejected.toLowerCase()) &&
              (currentStatus != AppConstants.Hired.toLowerCase())) ...[
            SizedBox(height: SizeConfig.size15),
            Row(
              children: [
                Expanded(
                  child: PositiveCustomBtn(
                    onTap: () async {
                      await commonConformationDialog(
                          context: context,
                          text: "Are you sure you are not interested?",
                          confirmCallback: () async {
                            await appliedController
                                .updateCandidateJobStatusController(
                                    applicationId: [widget.data.id ?? ""],
                                    applicationStatus: AppConstants.Rejected);
                            widget.buttonAction();
                          },
                          cancelCallback: () {
                            Get.back();
                          });
                    },
                    title: "Not Interested",
                    bgColor: AppColors.white,
                    textColor: AppColors.red00,
                    borderColor: AppColors.red00,
                  ),
                ),
                SizedBox(width: SizeConfig.size10),
                Expanded(
                  child: 
                  PopupMenuButton<String>(
                    onSelected: (value) async {
                      String applicationId = widget.data.id ?? "";
                      if (value == 'Shortlist Resume') {
                        await appliedController
                            .updateCandidateJobStatusController(
                                applicationId: [applicationId],
                                applicationStatus: AppConstants.Shortlisted);
                        widget.buttonAction();
                      }
                      if (value == 'Hire candidate') {
                        await appliedController
                            .updateCandidateJobStatusController(
                                applicationId: [applicationId],
                                applicationStatus: AppConstants.Hired);
                        widget.buttonAction();
                      }
                      if (value == 'Schedule Interview' ||
                          value == "Reschedule Interview") {
                        showInterviewScheduleDialog(context,
                            applicationId: [applicationId],
                            callBack: widget.buttonAction,
                            interviewId: value == "Reschedule Interview"
                                ? widget.data.id ?? ""
                                : "",
                            isReschedule:
                                value == "Reschedule Interview" ? true : false);
                      }
                    },
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    itemBuilder: (context) => [
                      if (currentStatus == AppConstants.Applied.toLowerCase())
                        PopupMenuItem(
                          value: 'Shortlist Resume',
                          child: CustomText(
                            'Shortlist Resume',
                          ),
                        ),
                      if (currentStatus == AppConstants.Applied.toLowerCase() ||
                          currentStatus ==
                              AppConstants.Shortlisted.toLowerCase())
                        PopupMenuItem(
                          value: 'Schedule Interview',
                          child: CustomText(
                            'Schedule Interview',
                          ),
                        ),
                      if (currentStatus ==
                          AppConstants.InterviewScheduled.toLowerCase())
                        PopupMenuItem(
                          value: 'Reschedule Interview',
                          child: CustomText(
                            'Reschedule Interview',
                          ),
                        ),
                      if (currentStatus ==
                              AppConstants.Shortlisted.toLowerCase() ||
                          (currentStatus ==
                              AppConstants.InterviewScheduled.toLowerCase())||
                          (currentStatus ==
                              AppConstants.rescheduled.toLowerCase()))
                        PopupMenuItem(
                          value: 'Hire candidate',
                          child: CustomText(
                            'Hire candidate',
                          ),
                        ),
                    ],
                    child: PositiveCustomBtn(onTap: null, title: "Next Step"),
                  ),
                ),
              ],
            ),
          ],
          if (currentStatus == AppConstants.Hired.toLowerCase()) ...[
            SizedBox(
              height: SizeConfig.size15,
            ),
            PositiveCustomBtn(
              height: SizeConfig.size32,
              onTap: () {
                showExperienceDialog(
                  context,
                  applicationID: widget.data.id,
                  interviewID: widget.data.interviewId,
                  jobID: widget.data.jobId,
                  title: "Tell us why you hired this candidate?",
                  subtitle: "Short Description (optional)",
                  hint: "Key reason for selecting this candidate...",
                  onSubmit: () {},
                  isHiredCandidate: 'FOR_CANDIDATE',
                );
              },
              title: "Tell us why you hired this candidate?",
              bgColor: AppColors.white,
              textColor: AppColors.primaryColor,
            ),
          ],

          if (currentStatus == AppConstants.Rejected.toLowerCase()) ...[
            Center(
              child: CustomText(
                "Rejected user",
                color: AppColors.red00,
                fontWeight: FontWeight.bold,
              ),
            )
          ]
        ],
      ),
    );
  }

  Widget _buildDetailRow(String svgPath, String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: SizeConfig.size10),
      child: Row(
        children: [
          SvgPicture.asset(
            svgPath,
            width: SizeConfig.size20,
            height: SizeConfig.size20,
            color: AppColors.black30,
          ),
          SizedBox(width: SizeConfig.size10),
          Expanded(
            child: CustomText(
              text,
              fontSize: SizeConfig.size12,
              color: AppColors.black,
            ),
          ),
        ],
      ),
    );
  }
}
