import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/common/jobs/controller/create_job_post_controller.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/new_common_date_selection_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class JobPostStep3Controller extends GetxController {
  RxString walkInInterview = 'No'.obs;
  final isSelected = false.obs;

  RxMap<String, bool> communicationPreferences = {
    'chat': false,
    'call': false,
    'both': false,
    'weContact': false,
  }.obs;

  RxInt selectedStartDate = 0.obs;
  RxInt selectedStartMonth = 0.obs;
  RxInt selectedStartYear = 0.obs;

  RxInt selectedEndDate = 0.obs;
  RxInt selectedEndMonth = 0.obs;
  RxInt selectedEndYear = 0.obs;

  // Walk-in details controllers
  TextEditingController walkInAddressController = TextEditingController();
  TextEditingController walkInInstructionsController = TextEditingController();

  RxInt walkInStartDay = 0.obs;
  RxInt walkInStartMonth = 0.obs;
  RxInt walkInStartYear = 0.obs;

  RxInt walkInEndDay = 0.obs;
  RxInt walkInEndMonth = 0.obs;
  RxInt walkInEndYear = 0.obs;

  RxString walkInStartTime = ''.obs;
  RxString walkInEndTime = ''.obs;

  /// Helper method to format dates for API
  String _formatDate(int day, int month, int year) {
    if (day == 0 || month == 0 || year == 0) return '';
    return '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
  }

  /// Public getters to send formatted date
  String get formattedStartDate => _formatDate(
        selectedStartDate.value,
        selectedStartMonth.value,
        selectedStartYear.value,
      );

  String get formattedEndDate => _formatDate(
        selectedEndDate.value,
        selectedEndMonth.value,
        selectedEndYear.value,
      );

  void setWalkIn(String? value) {
    if (value != null) {
      walkInInterview.value = value;
    }
  }

  void setCommunicationPreference(String key) {
    // Reset all preferences to false
    communicationPreferences.updateAll((k, v) => false);

    // Set the selected preference to true
    communicationPreferences[key] = true;
  }

  bool get hasCommunicationPreferenceSelected {
    return communicationPreferences.values.any((value) => value == true);
  }
}

class CreateJobPostStep3 extends StatefulWidget {
  CreateJobPostStep3({super.key});

  @override
  State<CreateJobPostStep3> createState() => _CreateJobPostStep3State();
}

class _CreateJobPostStep3State extends State<CreateJobPostStep3> {
  final createJobPostController = Get.find<CreateJobPostController>();

  final controller = Get.put(JobPostStep3Controller());

  @override
  void initState() {
    super.initState();

    // Wait for the next frame to ensure controller is properly initialized
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
      final interviewDetails = jobDetails?.interviewDetails;

      if (createJobPostController.isEditMode.value &&
          interviewDetails != null) {
        if (interviewDetails.isWalkIn == true) {
          controller.walkInInterview.value = 'Yes';
        } else {
          controller.walkInInterview.value = 'No';
        }

        if (interviewDetails.communicationPreferences != null) {
          final commPrefs = interviewDetails.communicationPreferences!;

          controller.communicationPreferences.updateAll((k, v) => false);

          if (commPrefs.chat == true) {
            controller.communicationPreferences['chat'] = true;
          }
          if (commPrefs.call == true) {
            controller.communicationPreferences['call'] = true;
          }
          if (commPrefs.both == true) {
            controller.communicationPreferences['both'] = true;
          }
          if (commPrefs.weContact == true) {
            controller.communicationPreferences['weContact'] = true;
          }
        }

        DateTime startDate =
            DateTime.parse(jobDetails?.interviewDetails?.walkInStartDate ?? "");
        DateTime endDate =
            DateTime.parse(jobDetails?.interviewDetails?.walkInEndDate ?? "");

        String startYear = startDate.year.toString();
        String startMonth = startDate.month.toString().padLeft(2, '0');
        String startDay = startDate.day.toString().padLeft(2, '0');

        String endYear = endDate.year.toString();
        String endMonth = endDate.month.toString().padLeft(2, '0');
        String endDay = endDate.day.toString().padLeft(2, '0');

        controller.selectedStartDate.value = int.parse(startDay);
        controller.selectedStartMonth.value = int.parse(startMonth);
        controller.selectedStartYear.value = int.parse(startYear);

        controller.selectedEndDate.value = int.parse(endDay);
        controller.selectedEndMonth.value = int.parse(endMonth);
        controller.selectedEndYear.value = int.parse(endYear);

        controller.walkInAddressController.text =
            jobDetails?.interviewDetails?.interviewAddress.toString() ?? "";

        controller.walkInStartTime.value =
            jobDetails?.interviewDetails?.walkInStartTime.toString() ?? "";
        controller.walkInEndTime.value =
            jobDetails?.interviewDetails?.walkInEndTime.toString() ?? "";
        controller.walkInInstructionsController.text =
            jobDetails?.interviewDetails?.otherInstructions.toString() ?? "";

        setState(() {});
      } else {
        // Set default values for new job creation
        controller.walkInInterview.value = 'No';
        controller.communicationPreferences.updateAll((k, v) => false);
        controller.communicationPreferences['chat'] = true; // Default to chat
      }
    } catch (e) {
      print('Error initializing data from API: $e');
      // Set default values on error
      controller.walkInInterview.value = 'No';
      controller.communicationPreferences.updateAll((k, v) => false);
      controller.communicationPreferences['chat'] = true;
    }
  }

  void resetControllerState() {}

  @override
  void dispose() {
    // Clean up any resources if needed
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mainController = Get.find<CreateJobPostController>();
    return Scaffold(
      appBar: CommonBackAppBar(
        title: AppStrings.createJobPostStep3,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
            horizontal: SizeConfig.size15, vertical: SizeConfig.size15),
        child: Column(
          children: [
            // ✅ Walk-In Card
            Card(
              color: AppColors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(SizeConfig.size12),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: SizeConfig.size15, vertical: SizeConfig.size15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      AppStrings.interviewMethodAndAddress,
                      fontSize: SizeConfig.large,
                    ),
                    SizedBox(height: SizeConfig.size15),
                    const CustomText(
                      AppStrings.isWalkInInterview,
                    ),
                    SizedBox(height: SizeConfig.size8),
                    Obx(
                      () => RadioGroup<String>(
                        groupValue: controller.walkInInterview.value,
                        onChanged: (val) => controller.setWalkIn(val),
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildRadioOption(
                                AppStrings.yes,
                                'Yes',
                                controller.walkInInterview.value,
                                controller.setWalkIn,
                              ),
                            ),
                            Expanded(
                              child: _buildRadioOption(
                                AppStrings.no,
                                'No',
                                controller.walkInInterview.value,
                                controller.setWalkIn,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(
                      height: SizeConfig.size10,
                    ),

                    // Only show walk-in details if 'Yes' is selected
                    Obx(
                      () => controller.walkInInterview.value == 'Yes'
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CommonTextField(
                                  textEditController:
                                      controller.walkInAddressController,
                                  title: AppStrings.walkInInterviewAddress,
                                  titleColor: AppColors.black,
                                  hintText: AppStrings.addressHint,
                                  isValidate: false,
                                  hintTextColor: AppColors.grey9B,
                                  fontSize: SizeConfig.medium,
                                  fontWeight: FontWeight.w400,
                                  onChange: (val) {
                                    // controller.selectedSkills.value = val.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
                                  },
                                ),

                                SizedBox(
                                  height: SizeConfig.size20,
                                ),

                                /// WALK IN START DATE
                                CustomText(
                                  AppStrings.walkInStartDate,
                                  fontSize: SizeConfig.medium,
                                ),
                                SizedBox(
                                  height: SizeConfig.size10,
                                ),
                                Obx(() {
                                  return NewDatePicker(
                                    selectedDay:
                                        controller.selectedStartDate.value,
                                    selectedMonth:
                                        controller.selectedStartMonth.value,
                                    selectedYear:
                                        controller.selectedStartYear.value,
                                    onDayChanged: (value) {
                                      controller.selectedStartDate.value =
                                          value ?? 0;
                                    },
                                    onMonthChanged: (value) {
                                      controller.selectedStartMonth.value =
                                          value ?? 0;
                                    },
                                    onYearChanged: (value) {
                                      controller.selectedStartYear.value =
                                          value ?? 0;
                                    },
                                    isFutureYear: true,
                                  );
                                }),
                                SizedBox(
                                  height: SizeConfig.size20,
                                ),

                                /// WALK IN INTERVIEW END DATE
                                CustomText(
                                  AppStrings.walkInEndDate,
                                  fontSize: SizeConfig.medium,
                                ),
                                SizedBox(
                                  height: SizeConfig.size10,
                                ),
                                Obx(() {
                                  return NewDatePicker(
                                    selectedDay:
                                        controller.selectedEndDate.value,
                                    selectedMonth:
                                        controller.selectedEndMonth.value,
                                    selectedYear:
                                        controller.selectedEndYear.value,
                                    onDayChanged: (value) {
                                      controller.selectedEndDate.value =
                                          value ?? 0;
                                    },
                                    onMonthChanged: (value) {
                                      controller.selectedEndMonth.value =
                                          value ?? 0;
                                    },
                                    onYearChanged: (value) {
                                      controller.selectedEndYear.value =
                                          value ?? 0;
                                    },
                                    isFutureYear: true,
                                  );
                                }),
                                SizedBox(height: SizeConfig.size15),
                                // Walk-in timings row (styled like text fields)
                                CustomText(AppStrings.walkInTimings),
                                SizedBox(height: SizeConfig.size8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Theme(
                                        data: Theme.of(context).copyWith(
                                          hintColor: AppColors
                                              .grey99, // Force hint color
                                        ),
                                        child: Obx(() =>
                                            DropdownButtonFormField<String>(
                                              value: controller.walkInStartTime
                                                      .value.isEmpty
                                                  ? null
                                                  : controller
                                                      .walkInStartTime.value,
                                              decoration: InputDecoration(
                                                contentPadding:
                                                    EdgeInsets.symmetric(
                                                        vertical: 16,
                                                        horizontal: 12),
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  borderSide: BorderSide(
                                                      color: AppColors.greyE5),
                                                ),
                                                enabledBorder:
                                                    OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  borderSide: BorderSide(
                                                      color: AppColors.greyE5),
                                                ),
                                                hintText: AppStrings.startTimeHint,
                                                // Added space after E.g.
                                                hintStyle: TextStyle(
                                                    color: AppColors.grey99),
                                                filled: true,
                                                fillColor: Colors.white,
                                              ),
                                              isExpanded: true,
                                              icon: Icon(
                                                  Icons
                                                      .keyboard_arrow_down_rounded,
                                                  color: AppColors.grey99),
                                              items: timeOptions
                                                  .map((String value) {
                                                return DropdownMenuItem<String>(
                                                    value: value,
                                                    child: Text(
                                                      value,
                                                      style: TextStyle(
                                                          color: Colors
                                                              .black), // Ensure dropdown text is visible
                                                    ));
                                              }).toList(),
                                              onChanged: (val) {
                                                controller.walkInStartTime
                                                    .value = val ?? '';
                                              },
                                              style: TextStyle(
                                                  color: Colors.black),
                                              // Selected value text color
                                              dropdownColor: Colors.white,
                                              // Dropdown background
                                              validator: (_) => null,
                                            )),
                                      ),
                                    ),
                                    SizedBox(width: 10),
                                    Expanded(
                                      child: Theme(
                                        data: Theme.of(context).copyWith(
                                          hintColor: AppColors
                                              .grey99, // Force hint color
                                        ),
                                        child: Obx(() =>
                                            DropdownButtonFormField<String>(
                                              value: controller.walkInEndTime
                                                      .value.isEmpty
                                                  ? null
                                                  : controller
                                                      .walkInEndTime.value,
                                              decoration: InputDecoration(
                                                contentPadding:
                                                    EdgeInsets.symmetric(
                                                        vertical: 16,
                                                        horizontal: 12),
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  borderSide: BorderSide(
                                                      color: AppColors.greyE5),
                                                ),
                                                enabledBorder:
                                                    OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  borderSide: BorderSide(
                                                      color: AppColors.greyE5),
                                                ),
                                                hintText: AppStrings.endTimeHint,
                                                // Added space after E.g.
                                                hintStyle: TextStyle(
                                                    color: AppColors.grey99),
                                                filled: true,
                                                fillColor: Colors.white,
                                              ),
                                              isExpanded: true,
                                              icon: Icon(
                                                  Icons
                                                      .keyboard_arrow_down_rounded,
                                                  color: AppColors.grey99),
                                              items: timeOptions
                                                  .map((String value) {
                                                return DropdownMenuItem<String>(
                                                    value: value,
                                                    child: Text(
                                                      value,
                                                      style: TextStyle(
                                                          color: Colors.black),
                                                    ));
                                              }).toList(),
                                              onChanged: (val) {
                                                controller.walkInEndTime.value =
                                                    val ?? '';
                                              },
                                              style: TextStyle(
                                                  color: Colors.black),
                                              dropdownColor: Colors.white,
                                              validator: (_) => null,
                                            )),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: SizeConfig.size15),
                                // Other Instructions section
                                CustomText(AppStrings.otherInstructions),
                                SizedBox(height: SizeConfig.size8),
                                CommonTextField(
                                  hintText:
                                  AppStrings.instructionsHint,
                                  textEditController:
                                      controller.walkInInstructionsController,
                                  maxLine: 4,
                                  contentPadding: EdgeInsets.symmetric(
                                      vertical: 16, horizontal: 12),
                                  isValidate: false,
                                  // Not required
                                  validator: (_) => null, // No validation
                                ),
                                SizedBox(height: SizeConfig.size15),
                              ],
                            )
                          : SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ),

            // ✅ Communication Card
            Card(
              color: AppColors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(SizeConfig.size12),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: SizeConfig.size15, vertical: SizeConfig.size15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      AppStrings.communicationPreferences,
                      fontSize: SizeConfig.large,
                      fontWeight: FontWeight.w600,
                    ),
                    SizedBox(height: SizeConfig.size15),
                    const CustomText(
                     AppStrings.contactViaChatAfterApply,
                      fontWeight: FontWeight.w500,
                    ),
                    const SizedBox(height: 8),
                    Obx(() {
                      String? activeKey;
                      for (final e in controller.communicationPreferences.entries) {
                        if (e.value == true) {
                          activeKey = e.key;
                          break;
                        }
                      }
                      return RadioGroup<String>(
                        groupValue: activeKey,
                        onChanged: (val) {
                          if (val != null) {
                            controller.setCommunicationPreference(val);
                          }
                        },
                        child: Wrap(
                          alignment: WrapAlignment.start,
                          children: [
                            _buildCommunicationRadioOption(
                              AppStrings.chat,
                              'chat',
                              controller.communicationPreferences,
                              controller.setCommunicationPreference,
                            ),
                            _buildCommunicationRadioOption(
                              AppStrings.call,
                              'call',
                              controller.communicationPreferences,
                              controller.setCommunicationPreference,
                            ),
                            _buildCommunicationRadioOption(
                              AppStrings.both,
                              'both',
                              controller.communicationPreferences,
                              controller.setCommunicationPreference,
                            ),
                            _buildCommunicationRadioOption(
                              AppStrings.weContactCandidate,
                              'weContact',
                              controller.communicationPreferences,
                              controller.setCommunicationPreference,
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            SizedBox(height: SizeConfig.size15),

            // Action Buttons
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: SizeConfig.size5,
              ),
              child: Row(
                children: [
                  Expanded(
                      child: CustomBtn(
                    onTap: () {
                      Get.back();
                    },
                    title: AppStrings.back,
                    bgColor: AppColors.white,
                    borderColor: AppColors.primaryColor,
                    textColor: AppColors.primaryColor,
                  )),
                  SizedBox(
                    width: SizeConfig.size10,
                  ),
                  Expanded(
                      child: PositiveCustomBtn(
                    onTap: () {
                      // Validate communication preference is selected
                      if (!controller.hasCommunicationPreferenceSelected) {
                        commonSnackBar(
                            message:
                            AppStrings.pleaseSelectCommunicationPref);
                        return;
                      }

                      // Sync local values to main controller
                      Map<String, dynamic> interviewDetails;

                      // Get the selected communication preference key
                      for (var entry
                          in controller.communicationPreferences.entries) {
                        if (entry.value == true) {
                          break;
                        }
                      }

                      // Create communication preferences map
                      Map<String, bool> communicationPrefsMap = {
                        'chat': controller.communicationPreferences['chat'] ??
                            false,
                        'call': controller.communicationPreferences['call'] ??
                            false,
                        'both': controller.communicationPreferences['both'] ??
                            false,
                        'weContact':
                            controller.communicationPreferences['weContact'] ??
                                false,
                      };

                      if (controller.walkInInterview.value == 'Yes') {
                        interviewDetails = {
                          ApiKeys.isWalkIn: true,
                          ApiKeys.interviewAddress:
                              controller.walkInAddressController.text,
                          ApiKeys.walkInStartDate:
                              controller.formattedStartDate,
                          ApiKeys.walkInEndDate: controller.formattedEndDate,
                          ApiKeys.walkInStartTime:
                              controller.walkInStartTime.value,
                          ApiKeys.walkInEndTime: controller.walkInEndTime.value,
                          ApiKeys.communicationPreferences:
                              communicationPrefsMap,
                          ApiKeys.otherInstructions:
                              controller.walkInInstructionsController.text,
                        };
                      } else {
                        interviewDetails = {
                          ApiKeys.isWalkIn: false,
                          ApiKeys.communicationPreferences:
                              communicationPrefsMap,
                        };
                      }

                      mainController.postJobStep3Api(
                        jobId: mainController.jobID.value,
                        interviewDetails: interviewDetails,
                      );
                      // Get.to(() => CreateJobPostStep4());
                    },
                    title: AppStrings.continueTxt,
                  ))
                ],
              ),
            ),
            SizedBox(height: SizeConfig.size20),
          ],
        ),
      ),
    );
  }

  Widget _buildRadioOption(
    String label,
    String value,
    String? groupValue,
    Function(String?) onChanged,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Theme(
          data: ThemeData(
            unselectedWidgetColor: AppColors.primaryColor, // Unselected border
            splashColor: Colors.transparent, // Disable ripple if needed
          ),
          child: Radio<String>(
            value: value,
            activeColor: AppColors.primaryColor,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: CustomText(
            label,
          ),
        ),
      ],
    );
  }

  Widget _buildCommunicationRadioOption(
    String value,
    String key,
    RxMap<String, bool> preferences,
    Function(String) onChanged,
  ) {
    return Obx(() {
      preferences[key]; // observe for reactivity
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Theme(
            data: ThemeData(
              unselectedWidgetColor: AppColors.primaryColor,
              // Unselected border
              splashColor: Colors.transparent, // Disable ripple if needed
            ),
            child: Radio<String>(
              value: key,
              activeColor: AppColors.primaryColor,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: CustomText(
              value,
            ),
          ),
        ],
      );
    });
  }
}

