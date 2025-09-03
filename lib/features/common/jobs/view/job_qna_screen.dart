import 'package:BlueEra/core/constants/regular_expression.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/jobs/view/job_details_overview_screen.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../widgets/commom_textfield.dart';
import '../../../../widgets/common_back_app_bar.dart';
import '../../../../widgets/custom_text_cm.dart';

class JobQNAScreen extends StatefulWidget {
  const JobQNAScreen({super.key});

  @override
  State<JobQNAScreen> createState() => _JobQNAScreenState();
}

class _JobQNAScreenState extends State<JobQNAScreen> {
  final TextEditingController availabilityController = TextEditingController();
  final TextEditingController whyRightPersonController = TextEditingController();
  String? selectedAvailability;
  String? selectedRelocation;
  String? selectedNoticePeriod;
  bool validate = false;
  late final String? UserID;
  late final String? resumeId;
  late final String? jobId;

  @override
  void initState() {
    super.initState();
    UserID = Get.arguments?['userId'];
    jobId = Get.arguments?['jobId'];
    resumeId = Get.arguments?['resumeId'];
  }

  @override
  void dispose() {
    availabilityController.dispose();
    whyRightPersonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(SizeConfig.size15),
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10.0),
                  color: AppColors.white,
                ),
                padding: EdgeInsets.symmetric(vertical: SizeConfig.size20, horizontal: SizeConfig.size12),
                child: Column(
                  children: [
                    // Why right person question
                    // descriptionCard(),

                    SizedBox(height: SizeConfig.size24),

                    PollCard(
                        "Confirm your availability?",
                        [
                        "Yes, I am willing to join immediately",
                        "No (Please specify your availability)",
                        ],
                        selectedAvailability,
                            (value) {
                          setState(() {
                            selectedAvailability = value;
                          });
                          validateForm();
                        },
                      ),

                    if(selectedAvailability == "No (Please specify your availability)")...[
                      SizedBox(height: SizeConfig.size16),
                      CommonTextField(
                        textEditController: availabilityController,
                        hintText: "Write your availability",
                        isValidate: true,
                        regularExpression: RegularExpressionUtils.alphabetSpacePattern,
                        onChange: (value) {
                          validateForm();
                        },
                      ),
                    ],

                    SizedBox(height: SizeConfig.size24),

                    PollCard(
                      "Are you willing to relocate yourself?",
                      ["Yes",
                      "No"
                    ],
                      selectedRelocation,
                          (value) {
                        setState(() {
                          selectedRelocation = value;
                        });
                        validateForm();
                      },
                    ),

                    SizedBox(height: SizeConfig.size24),

                    PollCard(
                      "What is your notice period?",
                      [
                        "Less than 7 days",
                        "Less than 15 days",
                        "Less than 1 month"
                      ],
                      selectedNoticePeriod,
                          (value) {
                        setState(() {
                          selectedNoticePeriod = value;
                        });
                        validateForm();
                      },
                    ),

                  ],
                ),
              ),

              SizedBox(height: SizeConfig.size24),

              //Continue button
              CustomBtn(
                title: 'Continue',
                onTap: (validate) ? () {
                  // Collect all answers
                  List<Map<String, dynamic>> selectedAnswers = [];
                  
                  // Add why right person answer if provided
                  if (whyRightPersonController.text.isNotEmpty) {
                    selectedAnswers.add({
                      'question': 'Explain why you are the right person for this job?',
                      'answer': whyRightPersonController.text,
                      'isInput': true,
                      'controller': whyRightPersonController,
                    });
                  }
                  
                  // Add availability answer if selected
                  if (selectedAvailability != null) {
                    String availabilityAnswer = selectedAvailability!;
                    if (selectedAvailability == "No (Please specify your availability)" && availabilityController.text.isNotEmpty) {
                      availabilityAnswer = availabilityController.text;
                    }
                    selectedAnswers.add({
                      'question': 'Confirm your availability',
                      'answer': availabilityAnswer,
                      'isInput': false,
                      'originalSelection': selectedAvailability,
                      'customText': selectedAvailability == "No (Please specify your availability)" ? availabilityController.text : null,
                    });
                  }
                  
                  // Add relocation answer if selected
                  if (selectedRelocation != null) {
                    selectedAnswers.add({
                      'question': 'Are you willing to relocate yourself?',
                      'answer': selectedRelocation!,
                      'isInput': false,
                      'originalSelection': selectedRelocation,
                    });
                  }
                  
                  // Add notice period answer if selected
                  if (selectedNoticePeriod != null) {
                    selectedAnswers.add({
                      'question': 'What is your notice period?',
                      'answer': selectedNoticePeriod!,
                      'isInput': false,
                      'originalSelection': selectedNoticePeriod,
                    });
                  }
                  
                  Get.to(() => JobDetailsOverviewScreen(), arguments: {
                    "jobId": jobId,
                    "resumeId": resumeId,
                    "selectedAnswers": selectedAnswers,
                  });
                } : null,
                isValidate: validate,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget titleWidget(String text){
    return CustomText(
        text,
        fontSize: SizeConfig.medium,
        color: AppColors.black28,
    );
  }

  Widget descriptionCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.0),
          color: AppColors.white,
          border: Border.all(color: AppColors.white12, width: 0.5),
          boxShadow: [
            BoxShadow(
                color: AppColors.black25,
                blurRadius: 6
            )
          ]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(
            "Information",
            fontWeight: FontWeight.w700,
          ),
          SizedBox(height: 5),
          CustomText(
            "Explain why you are the right person for this job",
            color: AppColors.blackA3,
          ),
          SizedBox(height: 10),

          CommonTextField(
            textEditController: whyRightPersonController,
            hintText: "Answer",
            maxLength: 1000,
            minLines: 5,
            maxLine: 10,
            onChange: (value) {
              validateForm();
            },
          ),
        ],
      ),
    );
  }

  Widget PollCard(
      String title,
      List<String> options, // Accept a list of options
      String? groupValue,
      Function(String?) onChanged,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: SizeConfig.size8),
          child: titleWidget(title),
        ),
        SizedBox(height: SizeConfig.size12),
        ...options.map((option) => RadioBtn(option, groupValue, onChanged)).toList(),
      ],
    );
  }


  Theme RadioBtn(String option, String? groupValue, Function(String?) onChanged) {
    return Theme(
      data: ThemeData(
      ),
      child: RadioListTile<String>(
        contentPadding: EdgeInsets.zero,
        visualDensity: VisualDensity(horizontal: -4, vertical: -4),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        title: CustomText(option, fontSize: SizeConfig.small, color: AppColors.grey83),
        value: option,
        groupValue: groupValue,
        onChanged: onChanged,
        dense: true,
        activeColor: AppColors.primaryColor,
      ),
    );
  }

  ///VALIDATE FORM...
  void validateForm() {
    final selectedAvailabilityIsNotEmpty = selectedAvailability!=null;
    final selectedRelocationIsNotEmpty = selectedRelocation!=null;
    final selectedNoticePeriodIsNotEmpty = selectedNoticePeriod!=null;
    final availabilityControllerIsNotEmpty = availabilityController.text.isNotEmpty;
    final whyRightPersonControllerIsNotEmpty = whyRightPersonController.text.isNotEmpty;

    if(selectedAvailabilityIsNotEmpty  ||
        selectedRelocationIsNotEmpty ||
        selectedNoticePeriodIsNotEmpty ||
        whyRightPersonControllerIsNotEmpty
    ){

      if(selectedAvailability == "No (Please specify your availability)"){
        if(!availabilityControllerIsNotEmpty){
        validate = false;
        setState(() {});
        return;
        }
      }

      // All validations passed
      validate = true;
      setState(() {});
      return;
    }

    // All validations passed
    validate = false;
    setState(() {});
  }
}
