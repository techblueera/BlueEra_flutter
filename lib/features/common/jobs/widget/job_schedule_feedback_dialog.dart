import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/features/common/jobs/controller/applied_job_controller.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

void showExperienceDialog(BuildContext context,
    {required String? jobID,
    required String? applicationID,
    required String? interviewID,
    required String? title,
    required String? subtitle,
    required String? hint,
    required String? isHiredCandidate,
    required VoidCallback onSubmit}) {
  final TextEditingController feedbackController = TextEditingController();

  showDialog(
    context: context,
    builder: (_) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Close button
                  Align(
                    alignment: Alignment.topRight,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.close),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Title
                   CustomText(title??"",
                      fontSize: 18, fontWeight: FontWeight.bold),

                  const SizedBox(height: 8),
                  // Subtitle

                  // Text field
                  CommonTextField(
                    title: subtitle,
                    textEditController: feedbackController,
                    maxLine: 4,
                    maxLength: 200,
                    hintText:hint,
                    isValidate: false,
                    onChange: (value) {
                      feedbackController.text = value;
                      setState(() {});
                    },
                  ),
                  const SizedBox(height: 4),
                  // Character count
                  Align(
                    alignment: Alignment.centerRight,
                    child: CustomText("${feedbackController.text.length}/200",
                        fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                  // Submit button
                  CustomBtn(
                    // onTap: onSubmit,
                    onTap: feedbackController.text.isNotEmpty
                        ? () async {
                            final appliedController =
                                Get.find<AppliedJobController>();
                            if(isHiredCandidate=="FOR_JOB"){
                              await appliedController
                                  .jobFeedBackPostController(bodyReq: {
                                ApiKeys.jobId: jobID,
                                ApiKeys.applicationId: applicationID,
                                ApiKeys.message: feedbackController.text
                              });
                              onSubmit();
                            }
                            else if(isHiredCandidate=="FOR_CANDIDATE"){
                              await appliedController
                                  .interviewFeedBackPostController(bodyReq: {
                                ApiKeys.comments: feedbackController.text,
                              }, interviewId:interviewID );
                            }

                          }
                        : null,
                    title: "Submit",

                    isValidate: feedbackController.text.isNotEmpty,
                  )
                ],
              );
            },
          ),
        ),
      );
    },
  );
}
