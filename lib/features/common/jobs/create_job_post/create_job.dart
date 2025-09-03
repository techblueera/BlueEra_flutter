import 'dart:convert'; // Added for jsonEncode
import 'dart:io';
import 'dart:ui';

import 'package:BlueEra/core/api/apiService/api_keys.dart'; // Fixed import path for ApiKeys
import 'package:BlueEra/core/common_singleton_class/user_session.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/regular_expression.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/routes/route_constant.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/common/auth/views/dialogs/select_profile_picture_dialog.dart';
import 'package:BlueEra/features/common/jobs/controller/create_job_post_controller.dart';
import 'package:BlueEra/l10n/app_localizations.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_drop_down.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CreateJobPostScreen extends StatefulWidget {
  final bool isEditMode;
  final String jobId;

  const CreateJobPostScreen({
    super.key,
    this.isEditMode = false,
    this.jobId = '',
  });

  @override
  State<CreateJobPostScreen> createState() => _CreateJobPostScreenState();
}

class _CreateJobPostScreenState extends State<CreateJobPostScreen> {
  late CreateJobPostController createJobPostController;

  @override
  void initState() {
    super.initState();

    // Initialize controller with proper disposal of existing instance
    if (Get.isRegistered<CreateJobPostController>()) {
      Get.delete<CreateJobPostController>();
    }
    createJobPostController = Get.put(CreateJobPostController());

    // Always reset controller state first to ensure clean state
    createJobPostController.resetControllerState();

    // Only fetch job details if in edit mode and jobId is provided
    if (widget.isEditMode && widget.jobId.isNotEmpty) {
      print('Will fetch job details for jobId: ${widget.jobId}');

      // Fetch job details and populate form fields
      createJobPostController.fetchJobDetails(widget.jobId).then((_) {
        // Populate form fields
        createJobPostController.addressEditController.text =
            createJobPostController
                    .jobDetails.value?.job?.location?.addressString ??
                "";
        createJobPostController.companyNameController.text =
            createJobPostController.jobDetails.value?.job?.companyName ?? "";
        createJobPostController.companyAddressController.text =
            createJobPostController
                    .jobDetails.value?.job?.location?.addressString ??
                "";
        createJobPostController.jobTitleController.text =
            createJobPostController.jobDetails.value?.job?.jobTitle ?? "";
        createJobPostController.departmentController.text =
            createJobPostController.jobDetails.value?.job?.department ?? "";
        createJobPostController.jobDescriptionController.text =
            createJobPostController.jobDetails.value?.job?.jobDescription ?? "";
        createJobPostController.jobType.value =
            createJobPostController.jobDetails.value?.job?.jobType ?? "";
        createJobPostController.workMode.value =
            createJobPostController.jobDetails.value?.job?.workMode ?? "";
        createJobPostController.payType.value =
            createJobPostController.jobDetails.value?.job?.compensation?.type ??
                "";
        createJobPostController.maxSalaryController.text =
            createJobPostController
                    .jobDetails.value?.job?.compensation?.maxSalary
                    .toString() ??
                "";
        createJobPostController.minSalaryController.text =
            createJobPostController
                    .jobDetails.value?.job?.compensation?.minSalary
                    .toString() ??
                "";

        // Initialize benefits (compensation perks)
       if (createJobPostController.jobDetails.value?.job?.benefits != null &&
            createJobPostController
                .jobDetails.value!.job!.benefits!.isNotEmpty) {
          createJobPostController.selectedCompensationPerks.clear();
          createJobPostController.selectedCompensationPerks
              .addAll(createJobPostController.jobDetails.value!.job!.benefits!);
          createJobPostController.selectedJobDescriptionPerks.addAll(
              createJobPostController.jobDetails.value!.job!.jobHighlights!);

      } else {
          createJobPostController.selectedCompensationPerks.clear();
        }


        try {
          // Extract the JSON string from benefits[0][0]
          final rawJsonString =
              createJobPostController.jobDetails.value?.job?.benefits![0][0];

          // Decode the string into a List<dynamic>
          final decoded = jsonDecode(rawJsonString ?? "");

          // Convert List<dynamic> to List<String>
          final stringList = List<String>.from(decoded);

          // Update your controller
          createJobPostController.selectedCompensationPerks
            ..clear()
            ..addAll(stringList);

        } catch (e) {
          createJobPostController.selectedCompensationPerks.clear();

          if (createJobPostController.jobDetails.value?.job?.jobHighlights !=
                  null &&
              createJobPostController
                  .jobDetails.value!.job!.jobHighlights!.isNotEmpty) {
            createJobPostController.selectedJobDescriptionPerks.clear();
            createJobPostController.selectedJobDescriptionPerks.addAll(
                createJobPostController.jobDetails.value!.job!.jobHighlights!);
         } else {
            createJobPostController.selectedJobDescriptionPerks.clear();
          }

          // Force UI update only if widget is still mounted
          if (mounted) {
// Mark data as loaded
            setState(() {});
          }
        }
      }).catchError((error) {
      });
    } else {
    }

    // Use addPostFrameCallback to ensure the controller is properly initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Always set the edit mode based on widget parameter
      createJobPostController.isEditMode.value = widget.isEditMode;

      // Set job ID if in edit mode and jobId is provided
      if (widget.isEditMode && widget.jobId.isNotEmpty) {
        createJobPostController.jobID.value = widget.jobId;
      } else {
        // Reset controller state when not in edit mode
        createJobPostController.resetControllerState();
      }

      // No longer using reactive listeners since we're using setState

      // Debug logging

    });
  }

  @override
  void dispose() {
    // Dispose text controllers
    if (Get.isRegistered<CreateJobPostController>()) {
      createJobPostController.companyNameController.dispose();
      createJobPostController.companyAddressController.dispose();
      createJobPostController.jobTitleController.dispose();
      createJobPostController.departmentController.dispose();
      createJobPostController.minSalaryController.dispose();
      createJobPostController.maxSalaryController.dispose();
      createJobPostController.jobHighlightsController.dispose();
      createJobPostController.jobDescriptionController.dispose();

      // Clean up controller to prevent memory leaks
      Get.delete<CreateJobPostController>();
    }

    super.dispose();
  }

  final List<String> departments = [
    "UI/UX Design",
    "Development",
    "Marketing",
    "Sales",
    "HR"
  ];

  final List<String> jobTypes = [
    "Full-Time",
    "Part-Time",
    "Contract",
    "Internship",
    "Temporary"
  ];

  final List<String> workModes = ["Work from Home", "In-Office", "Hybrid"];

  final List<String> payTypes = [
    "Fixed Only",
    "Fixed + Performance",
    "Performance Only"
  ];

  final List<String> compensationPerks = [
    "Flexible Working Hours",
    "Weekly Payout",
    "Overtime Pay",
    "Joining Bonus",
    "Health Insurance",
    "Paid Leave",
    "Remote Work",
    "Training",
    "Meal Coupons",
    "Performance Bonus"
  ];

  final List<String> jobDescriptionPerks = [
    "Flexible Working Hours",
    "Weekly Payout",
    "Overtime Pay",
    "Joining Bonus",
    "Health Insurance",
    "Paid Leave",
    "Remote Work",
    "Training",
    "Meal Coupons",
    "Performance Bonus"
  ];

  String? _imagePath;

// Track if API data has been loaded

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);

    return Scaffold(
      appBar: CommonBackAppBar(
        title: "Create Job Post (Step 1 of 4)",
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(SizeConfig.size15),
          child: Center(
            child: Column(
              children: [
                ///JOB DETAILS...
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
                        // Job Details Section
                        GestureDetector(
                          onTap: () {
                            // Remove this test call as it's causing issues
                            // createJobPostController.jobdetailcontroller.fetchJobDetails("68872727690a13aa6c4a61bb");
                          },
                          child: CustomText("Job Details",
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: SizeConfig.large),
                        ),
                        SizedBox(height: SizeConfig.size15),
                        // CustomText("Job Post Image",
                        //     color: Colors.black,
                        //     fontWeight: FontWeight.w400,
                        //     fontSize: SizeConfig.medium),
                        // SizedBox(height: SizeConfig.size8),
                        // Job Post Image Selector
                        Row(
                          children: [
                            CustomText(
                              "Job Banner Image",
                              color: AppColors.black,
                              fontWeight: FontWeight.w600,
                              fontSize: SizeConfig.medium,
                            ),
                            CustomText(
                              " *",
                              color: Colors.red,
                              fontWeight: FontWeight.w600,
                              fontSize: SizeConfig.medium,
                            ),
                          ],
                        ),
                        SizedBox(height: SizeConfig.size8),
                        GestureDetector(
                          onTap: () => _selectImage(context),
                          child: DashedBorderContainer(
                            borderColor:
                                (_imagePath != null && _imagePath!.isNotEmpty)
                                    ? AppColors.primaryColor
                                    : const Color(0xFFB0B4BF),
                            child: Container(
                              width: double.infinity,
                              padding: EdgeInsets.symmetric(
                                  vertical: SizeConfig.size20),
                              color: AppColors.white,
                              // very light grey background
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _imagePath?.isNotEmpty == true
                                      ? ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          child: Image(
                                            image: FileImage(File(_imagePath!)),
                                            width: 48,
                                            height: 48,
                                            fit: BoxFit.cover,
                                          ),
                                        )
                                      : Icon(Icons.image_outlined,
                                          color: AppColors.grey99, size: 28),
                                  SizedBox(width: SizeConfig.size10),
                                  (_imagePath == null || _imagePath!.isEmpty)
                                      ? CustomText(
                                          'Select Banner Template (Required)',
                                          color: AppColors.grey99,
                                          fontWeight: FontWeight.w500,
                                          fontSize: SizeConfig.large,
                                        )
                                      : Row(
                                          children: [
                                            Icon(Icons.check_circle,
                                                color: AppColors.primaryColor,
                                                size: 20),
                                            SizedBox(width: SizeConfig.size5),
                                            CustomText(
                                              'Banner Selected',
                                              color: AppColors.primaryColor,
                                              fontWeight: FontWeight.w500,
                                              fontSize: SizeConfig.large,
                                            ),
                                          ],
                                        ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: SizeConfig.size20),
                        CommonTextField(
                          textEditController:
                              createJobPostController.companyNameController,
                          title: "Company Name",
                          titleColor: AppColors.black,
                          hintText: "Eg. BlueCS Limited",
                          isValidate: false,
                          hintTextColor: AppColors.grey9B,
                          fontSize: SizeConfig.medium,
                          fontWeight: FontWeight.w400,
                          // onChange: (val) =>
                          //     createJobPostController.companyName.value = val,
                        ),

                        SizedBox(height: SizeConfig.size20),
                        InkWell(
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              RouteHelper.getSearchLocationScreenRoute(),
                              arguments: {
                                'onPlaceSelected': (double? lat, double? lng,
                                    String? address
                                    ) {
                                  if (address != null) {
                                    createJobPostController
                                        .addressEditController.text = address;
                                    createJobPostController.setJobLocation(
                                        lat, lng, address);
                                  }
                                },
                                ApiKeys.fromScreen:
                                    RouteConstant.CreateJobPostScreen
                              },
                            );
                          },
                          child: CommonTextField(
                            textEditController:
                                createJobPostController.addressEditController,
                            hintText: "E.g., Rajiv Chowk, Delhi",
                            isValidate: false,
                            title: "Company Address",

                            readOnly: true,
                            // Make it read-only since we'll use the search screen
                          ),
                        ),

                        SizedBox(
                          height: SizeConfig.size20,
                        ),
                        CommonTextField(
                          textEditController:
                              createJobPostController.jobTitleController,
                          title: "Job Title / Designation",
                          titleColor: AppColors.black,
                          hintText: "Eg. UI/UX Designer",
                          isValidate: false,
                          hintTextColor: AppColors.grey9B,
                          fontSize: SizeConfig.medium,
                          fontWeight: FontWeight.w400,
                          onChange: (val) =>
                              createJobPostController.jobTitle.value = val,
                        ),
                        SizedBox(height: SizeConfig.size20),
                        CommonTextField(
                          textEditController:
                              createJobPostController.departmentController,
                          title: "Department",
                          titleColor: AppColors.black,
                          hintText: "Eg. department",
                          isValidate: false,
                          hintTextColor: AppColors.grey9B,
                          fontSize: SizeConfig.medium,
                          fontWeight: FontWeight.w400,
                          onChange: (val) =>
                              createJobPostController.department.value = val,
                        ),

                        SizedBox(height: SizeConfig.size20),
                        CustomText(
                          "Job Type",
                          color: AppColors.black,
                        ),
                        SizedBox(height: SizeConfig.paddingXSL),
                        CommonDropdown<String>(
                          items: jobTypes,
                          selectedValue:
                              createJobPostController.jobType.value.isEmpty
                                  ? null
                                  : createJobPostController.jobType.value,
                          hintText: "Eg. Full Time",
                          onChanged: (val) {
                            createJobPostController.jobType.value = val ?? "";
                            setState(() {});
                          },
                          displayValue: (item) => item,
                        ),
                        SizedBox(height: SizeConfig.size20),
                        CustomText(
                          "Work Mode",
                          color: AppColors.black,
                        ),
                        SizedBox(height: SizeConfig.paddingXSL),
                        CommonDropdown<String>(
                          items: workModes,
                          selectedValue:
                              createJobPostController.workMode.value.isEmpty
                                  ? null
                                  : createJobPostController.workMode.value,
                          hintText: "Eg. Work From Home",
                          onChanged: (val) {
                            createJobPostController.workMode.value = val ?? "";
                            setState(() {});
                          },
                          displayValue: (item) => item,
                        ),
                        SizedBox(height: SizeConfig.size5),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: SizeConfig.size5),

                ///COMPENSATION...
                Card(
                  color: Colors.white,
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
                        // Compensation Section
                        CustomText("Compensation",
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: SizeConfig.large),
                        SizedBox(height: SizeConfig.size15),

                        CustomText(
                          "What is the pay type?",
                          color: AppColors.black,
                        ),
                        SizedBox(height: SizeConfig.paddingXSL),
                        CommonDropdown<String>(
                          items: payTypes,
                          selectedValue:
                              createJobPostController.payType.value.isEmpty
                                  ? null
                                  : createJobPostController.payType.value,
                          hintText: "Eg. Fixed Only",
                          onChanged: (val) {
                            createJobPostController.payType.value = val ?? "";
                            setState(() {});
                          },
                          displayValue: (item) => item,
                        ),
                        SizedBox(height: SizeConfig.size20),
                        CustomText(
                          "Select Salary",
                          color: AppColors.black,
                        ),
                        SizedBox(height: SizeConfig.paddingXSL),
                        Row(
                          children: [
                            Expanded(
                              child: CommonTextField(
                                textEditController:
                                    createJobPostController.minSalaryController,
                                titleColor: AppColors.black,
                                hintText: "Min. salary",
                                isValidate: false,
                                hintTextColor: AppColors.grey9B,
                                fontSize: SizeConfig.medium,
                                keyBoardType: TextInputType.number,
                                regularExpression:
                                    RegularExpressionUtils.digitsPattern,
                                fontWeight: FontWeight.w400,
                                onChange: (val) => createJobPostController
                                    .minSalary.value = val,
                              ),
                            ),
                            SizedBox(width: SizeConfig.size12),
                            CustomText(
                              "To",
                              color: AppColors.black,
                            ),
                            SizedBox(width: SizeConfig.size12),
                            Expanded(
                              child: CommonTextField(
                                textEditController:
                                    createJobPostController.maxSalaryController,
                                hintText: "Max. salary",
                                isValidate: false,
                                hintTextColor: AppColors.grey9B,
                                fontSize: SizeConfig.medium,
                                fontWeight: FontWeight.w400,
                                regularExpression:
                                    RegularExpressionUtils.digitsPattern,
                                keyBoardType: TextInputType.number,
                                onChange: (val) => createJobPostController
                                    .maxSalary.value = val,
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: SizeConfig.size20),

                        CustomText("Do you offer any additional perks?",
                            color: Colors.black,
                            fontWeight: FontWeight.w600,
                            fontSize: SizeConfig.medium),
                        SizedBox(height: SizeConfig.paddingM),

                        Builder(
                          builder: (context) {
                            return buildPerksChips(
                                createJobPostController,
                                compensationPerks,
                                true,
                                createJobPostController
                                    .selectedCompensationPerks, (perk) {
                              final selected = createJobPostController
                                  .selectedCompensationPerks
                                  .contains(perk);
                              if (selected) {
                                createJobPostController
                                    .selectedCompensationPerks
                                    .remove(perk);
                              } else {
                                createJobPostController
                                    .selectedCompensationPerks
                                    .add(perk);
                              }
                              setState(() {});
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: SizeConfig.size5),

                ///JOB DESCRIPTION...
                Card(
                  color: Colors.white,
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
                        // Job Description Section
                        CustomText("Job Description",
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: SizeConfig.large),

                        SizedBox(height: SizeConfig.size15),
                        // Job Highlights (chips)
                        CustomText("Job Highlights",
                            color: Colors.black,
                            fontWeight: FontWeight.w600,
                            fontSize: SizeConfig.medium),
                        SizedBox(height: SizeConfig.paddingXSL),
                        CommonTextField(
                          textEditController:
                              createJobPostController.jobHighlightsController,
                          hintText: "Write Highlights of Jobs",
                          isValidate: false,
                          hintTextColor: AppColors.grey9B,
                          fontSize: SizeConfig.medium,
                          fontWeight: FontWeight.w400,
                          onChange: (val) =>
                              createJobPostController.jobHighlights.value =
                                  val.split(',').map((e) => e.trim()).toList(),
                        ),
                        SizedBox(height: SizeConfig.size20),

                        Builder(
                          builder: (context) {
                            return buildPerksChips(
                                createJobPostController,
                                jobDescriptionPerks,
                                false,
                                createJobPostController
                                    .selectedJobDescriptionPerks, (perk) {
                              final selected = createJobPostController
                                  .selectedJobDescriptionPerks
                                  .contains(perk);
                              if (selected) {
                                createJobPostController
                                    .selectedJobDescriptionPerks
                                    .remove(perk);
                              } else {
                                createJobPostController
                                    .selectedJobDescriptionPerks
                                    .add(perk);
                              }
                              setState(() {});
                            });
                          },
                        ),
                        SizedBox(height: SizeConfig.size16),

                        CommonTextField(
                          textEditController:
                              createJobPostController.jobDescriptionController,
                          title: "Type Your Job Description",
                          hintText:
                              "Enter the job description, including the main responsibility and tasks...",
                          isValidate: false,
                          hintTextColor: AppColors.grey9B,
                          fontSize: SizeConfig.medium,
                          fontWeight: FontWeight.w400,
                          maxLine: 5,
                          onChange: (val) => createJobPostController
                              .jobDescription.value = val,
                        ),
                        SizedBox(height: SizeConfig.size5),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: SizeConfig.size30),

                // Continue Button
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: SizeConfig.size15),
                  child: Row(
                    children: [
                      Expanded(
                          child: CustomBtn(
                        onTap: () {
                          // Debug logging for button tap
                          print('=== BUTTON TAP DEBUG ===');
                          print(
                              'isEditMode: ${createJobPostController.isEditMode.value}');
                          print(
                              'jobID: ${createJobPostController.jobID.value}');

                          // Validate required fields including image
                          if (!createJobPostController.isEditMode.value &&
                              (_imagePath == null || _imagePath!.isEmpty)) {
                            commonSnackBar(
                                message: "Please select a job banner image");
                            return;
                          }

                          if (createJobPostController.isEditMode.value) {
                            // In edit mode, call update API with job data
                            final Map<String, dynamic> params = {
                              ApiKeys.jobTitle: createJobPostController
                                  .jobTitleController.text,
                              ApiKeys.companyName: createJobPostController
                                  .companyNameController.text,
                              ApiKeys.jobType:
                                  createJobPostController.jobType.value,
                              ApiKeys.workMode:
                                  createJobPostController.workMode.value,
                              ApiKeys.department: createJobPostController
                                  .departmentController.text,
                              ApiKeys.jobDescription: createJobPostController
                                  .jobDescriptionController.text,
                              ApiKeys.benefits: jsonEncode(
                                  createJobPostController
                                      .selectedCompensationPerks),
                              ApiKeys.jobHighlights: jsonEncode(
                                  createJobPostController
                                      .selectedJobDescriptionPerks),
                              ApiKeys.compensationType:
                                  createJobPostController.payType.value,
                              ApiKeys.compensationMinSalary: int.tryParse(
                                      createJobPostController
                                          .minSalaryController.text) ??
                                  0,
                              ApiKeys.compensationMaxSalary: int.tryParse(
                                      createJobPostController
                                          .maxSalaryController.text) ??
                                  0,
                              ApiKeys.locationLatitude: createJobPostController
                                      .startLocationLat?.value ??
                                  0.0,
                              ApiKeys.locationLongitude: createJobPostController
                                      .startLocationLng?.value ??
                                  0.0,
                              ApiKeys.locationAddress: createJobPostController
                                  .addressEditController.text,
                            };

                            print('=== UPDATE JOB DEBUG ===');
                            print(
                                'Job ID: ${createJobPostController.jobID.value}');
                            print(
                                'Job ID type: ${createJobPostController.jobID.value.runtimeType}');
                            print('Params: $params');

                            createJobPostController.updateJobPostDetailsApi(
                              jobId: createJobPostController.jobID.value,
                              params: params,
                            );
                          } else {
                            createJobPostController.postJobApi(
                                imagePath: _imagePath);
                          }
                        },
                        title: createJobPostController.isEditMode.value
                            ? "Update Job"
                            : "Continue",
                        bgColor: AppColors.primaryColor,
                        textColor: Colors.white,
                        fontWeight: FontWeight.w600,
                        radius: 8,
                        height: SizeConfig.size50,
                      )),
                    ],
                  ),
                ),

                SizedBox(height: SizeConfig.size30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildPerksChips(
    CreateJobPostController controller,
    List<String> perks,
    bool otherPerks,
    List<String> selectedPerks,
    Function(String) onSelectedPerks,
  ) {
    bool showAll = false; // simple boolean flag

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Builder(builder: (context) {
          final visiblePerks = showAll
              ? perks
              : perks.take(5).toList(); // show first 5 initially

          return Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              ...visiblePerks.map((perk) {
                final selected = selectedPerks.contains(perk);
                return GestureDetector(
                  onTap: () => onSelectedPerks(perk),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: SizeConfig.size16,
                      vertical: SizeConfig.size8,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.primaryColor
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected
                            ? AppColors.primaryColor
                            : AppColors.borderGray,
                        width: 1,
                      ),
                      boxShadow: selected
                          ? [
                              BoxShadow(
                                color: AppColors.primaryColor
                                    .withValues(alpha: 0.08),
                                blurRadius: 6,
                                offset: Offset(0, 2),
                              )
                            ]
                          : [],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CustomText(
                          perk,
                          color: selected ? Colors.white : AppColors.grey9A,
                          fontSize: SizeConfig.small,
                          fontWeight: FontWeight.w500,
                        ),
                        SizedBox(width: SizeConfig.size5),
                        LocalAssets(
                          imagePath: AppIconAssets.add,
                          imgColor: selected ? Colors.white : AppColors.grey9A,
                          height: SizeConfig.size15,
                          width: SizeConfig.size15,
                        ),
                        if (selected)
                          Padding(
                            padding: EdgeInsets.only(left: 6),
                            child: Icon(
                              Icons.check,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }).toList(),

          /*    // Show more/less toggle
              if (perks.length > 5)
                GestureDetector(
                  onTap: () {
                    showAll = !showAll;
                    setState(() {});
                  },
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: SizeConfig.size16),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CustomText(
                          showAll
                              ? "Show Less"
                              : "Show ${perks.length - 5} More",
                          color: AppColors.primaryColor,
                          fontSize: SizeConfig.small,
                          fontWeight: FontWeight.w600,
                        ),
                        SizedBox(width: 6),
                        Icon(
                          showAll
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                          color: AppColors.primaryColor,
                        ),
                      ],
                    ),
                  ),
                ),*/
            ],
          );
        }),
        // if (otherPerks)
        //   GestureDetector(
        //     onTap: () {
        //       // Handle add new perk logic here
        //     },
        //     child: Container(
        //       // color: Colors.grey,
        //       margin: EdgeInsets.only(top: SizeConfig.size8),
        //       padding: EdgeInsets.symmetric(horizontal: SizeConfig.size16),
        //       child: Row(
        //         mainAxisSize: MainAxisSize.min,
        //         children: [
        //           LocalAssets(
        //             imagePath: AppIconAssets.add,
        //             imgColor: AppColors.green39,
        //             height: 18,
        //             width: 18,
        //           ),
        //           SizedBox(width: 6),
        //           // CustomText(
        //           //   "Add other perks",
        //           //   color: AppColors.green39,
        //           //   fontSize: SizeConfig.small,
        //           //   fontWeight: FontWeight.w600,
        //           // ),
        //         ],
        //       ),
        //     ),
        //   ),
      ],
    );
  }

  Future<void> _selectImage(BuildContext context) async {
    final loc = AppLocalizations.of(context)!;
    final String? selected = await SelectProfilePictureDialog.showLogoDialog(
      context,
      loc.uploadProfilePicture,
    );

    if (selected?.isNotEmpty ?? false) {
      _imagePath = selected;
      UserSession().imagePath = selected;
      if (mounted) {
        setState(() {});
      }
      // if (_selectedIndex != null) _navigateToCreateAccount();
    }
  }
}

class DashedBorderContainer extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final Color borderColor;
  final double strokeWidth;
  final double dashLength;
  final double gapLength;

  const DashedBorderContainer({
    Key? key,
    required this.child,
    this.borderRadius = 12,
    this.borderColor = const Color(0xFFB0B4BF), // light grey
    this.strokeWidth = 1.2,
    this.dashLength = 6,
    this.gapLength = 4,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedBorderPainter(
        borderRadius: borderRadius,
        color: borderColor,
        strokeWidth: strokeWidth,
        dashLength: dashLength,
        gapLength: gapLength,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: child,
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final double borderRadius;
  final Color color;
  final double strokeWidth;
  final double dashLength;
  final double gapLength;

  _DashedBorderPainter({
    required this.borderRadius,
    required this.color,
    required this.strokeWidth,
    required this.dashLength,
    required this.gapLength,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final RRect rRect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(borderRadius),
    );

    _drawDashedRRect(canvas, rRect, paint);
  }

  void _drawDashedRRect(Canvas canvas, RRect rRect, Paint paint) {
    final Path path = Path()..addRRect(rRect);
    final PathMetrics metrics = path.computeMetrics();
    for (final PathMetric metric in metrics) {
      double distance = 0.0;
      while (distance < metric.length) {
        final double next = distance + dashLength;
        canvas.drawPath(
          metric.extractPath(distance, next),
          paint,
        );
        distance = next + gapLength;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
