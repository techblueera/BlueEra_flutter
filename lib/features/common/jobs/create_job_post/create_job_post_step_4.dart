import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/jobs/controller/create_job_post_controller.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class JobPostStep4Controller extends GetxController {
  var confirmAvailability = true.obs;
  var willingToRelocate = false.obs;
  var noticePeriod = false.obs;

  var availabilityOption = "".obs;
  var relocationOption = "".obs;
  var noticePeriodOption = "".obs;

  void resetOptions() {
    availabilityOption.value = "";
    relocationOption.value = "";
    noticePeriodOption.value = "";
  }
}

class CreateJobPostStep4 extends StatefulWidget {
  @override
  State<CreateJobPostStep4> createState() => _CreateJobPostStep4State();
}

class _CreateJobPostStep4State extends State<CreateJobPostStep4> {
  final JobPostStep4Controller controller = Get.put(JobPostStep4Controller());
  final createJobPostController = Get.find<CreateJobPostController>();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeDataFromAPI();

      // Listen for changes in job details (in case API data loads after widget is built)
      ever(createJobPostController.jobDetails, (jobDetails) {
        if (jobDetails != null) {
          _initializeDataFromAPI();
        }
      });
    });
  }

  void _initializeDataFromAPI() {
    try {
      final jobDetails = createJobPostController.jobDetails.value?.job;
      final customQuestions = jobDetails?.customQuestions;

      if (createJobPostController.isEditMode.value && customQuestions != null) {
        controller.confirmAvailability.value =
            jobDetails?.customQuestions?[0].isMandatory ?? false;
        controller.willingToRelocate.value =
            jobDetails?.customQuestions?[1].isMandatory ?? false;
        controller.noticePeriod.value =
            jobDetails?.customQuestions?[2].isMandatory ?? false;
      }
      setState(() {});
    } catch (e) {
      print('Error initializing data from API: $e');
      // Set default values on error
    }
  }

  @override
  Widget build(BuildContext context) {
    final mainController = Get.find<CreateJobPostController>();
    return Scaffold(
      appBar: CommonBackAppBar(
        title: "Create Job Post (Step 4 of 4)",
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(
              horizontal: SizeConfig.size15, vertical: SizeConfig.size15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(left: SizeConfig.size5),
                child: CustomText("Ask the Questions to the Candidates",
                    fontWeight: FontWeight.w700, fontSize: SizeConfig.large),
              ),
              const SizedBox(height: 20),
              Card(
                color: AppColors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(SizeConfig.size12),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: SizeConfig.size15,
                      vertical: SizeConfig.size15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      buildToggleQuestion(
                        title: "Confirm your availability",
                        toggleValue: controller.confirmAvailability,
                        options: [
                          buildRadioOption(
                            label: "Yes, I am available to join immediately",
                            value: "yes",
                            groupValue: controller.availabilityOption,
                          ),
                          buildRadioOption(
                            label: "No (Please specify your availability)",
                            value: "no",
                            groupValue: controller.availabilityOption,
                          ),
                        ],
                      ),
                      buildToggleQuestion(
                        title: "Are you willing to relocate yourself?",
                        toggleValue: controller.willingToRelocate,
                        options: [
                          buildRadioOption(
                            label: "Yes",
                            value: "yes",
                            groupValue: controller.relocationOption,
                          ),
                          buildRadioOption(
                            label: "No",
                            value: "no",
                            groupValue: controller.relocationOption,
                          ),
                        ],
                      ),
                      buildToggleQuestion(
                        title: "What is your notice period?",
                        toggleValue: controller.noticePeriod,
                        options: [
                          buildRadioOption(
                            label: "Less than 7 days",
                            value: "7",
                            groupValue: controller.noticePeriodOption,
                          ),
                          buildRadioOption(
                            label: "Less than 15 days",
                            value: "15",
                            groupValue: controller.noticePeriodOption,
                          ),
                          buildRadioOption(
                            label: "Less than 1 month",
                            value: "30",
                            groupValue: controller.noticePeriodOption,
                          ),
                        ],
                      ),
                      TextButton.icon(
                        onPressed: () {},
                        icon: Icon(
                          Icons.add,
                          color: Color(0xFF2399F5),
                        ),
                        label: CustomText("Add more questions",
                            color: Color(
                              0xFF2399F5,
                            ),
                            fontSize: SizeConfig.large),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(
                height: SizeConfig.size20,
              ),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: SizeConfig.size5,
                ),
                child: PositiveCustomBtn(
                    onTap: () async {
                      final List<Map<String, dynamic>> customQuestions = [];

                      // Confirm your availability
                      if (controller.confirmAvailability.value) {
                        customQuestions.add({
                          ApiKeys.question: "Confirm your availability",
                          ApiKeys.answerType: "Yes/No",
                          ApiKeys.options: ["yes", "no"],
                          ApiKeys.isMandatory: true,
                        });
                      }

                      // Are you willing to relocate yourself?
                      if (controller.willingToRelocate.value) {
                        customQuestions.add({
                          ApiKeys.question:
                              "Are you willing to relocate yourself?",
                          ApiKeys.answerType: "Yes/No",
                          ApiKeys.options: ["yes", "no"],
                          ApiKeys.isMandatory: true,
                        });
                      }

                      // What is your notice period?
                      if (controller.noticePeriod.value) {
                        customQuestions.add({
                          ApiKeys.question: "What is your notice period?",
                          ApiKeys.answerType: "Yes/No",
                          ApiKeys.options: ["7", "15", "30"],
                          ApiKeys.isMandatory: true,
                        });
                      }

                      await mainController.postJobStep4Api(
                        jobId: mainController.jobID.value,
                        customQuestions: customQuestions,
                      );
                    },
                    title: "Continue"),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget buildToggleQuestion({
    required String title,
    required RxBool toggleValue,
    required List<Widget> options,
  }) {
    return Obx(() => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title,
                    style:
                        TextStyle(fontWeight: FontWeight.w400, fontSize: 14)),
                Transform.scale(
                  scale: 0.70,
                  child: Switch(
                    value: toggleValue.value,
                    onChanged: (val) => toggleValue.value = val,
                    activeColor: Colors.white,
                    activeTrackColor: Color(0xFF2399F5),
                    inactiveThumbColor: Colors.white,
                    inactiveTrackColor: Colors.grey,
                  ),
                ),
              ],
            ),
            if (toggleValue.value) ...options,
            const SizedBox(height: 20),
          ],
        ));
  }

  Widget buildRadioOption({
    required String label,
    required String value,
    required RxString groupValue,
  }) {
    return Obx(() => Theme(
          data: ThemeData(
            unselectedWidgetColor: AppColors.primaryColor, // Unselected border
            splashColor: Colors.transparent, // Disable ripple if needed
          ),
          child: RadioListTile<String>(
            contentPadding: EdgeInsets.zero,
            dense: true,
            visualDensity: VisualDensity.compact,
            title: Align(
              alignment: Alignment.centerLeft,
              child: CustomText(
                label,
              ),
            ),
            value: value,
            groupValue: groupValue.value,
            activeColor: Color(0xFF2399F5),
            onChanged: (val) => groupValue.value = val!,
          ),
        ));
  }
}
