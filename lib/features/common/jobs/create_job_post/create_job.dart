import 'dart:io';

import 'package:BlueEra/core/api/apiService/api_keys.dart'; // Fixed import path for ApiKeys
import 'package:BlueEra/core/common_singleton_class/user_session.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/regular_expression.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/routes/route_constant.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/core/services/photo_picker_service.dart';
import 'package:BlueEra/features/common/jobs/controller/create_job_post_controller.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_drop_down.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/dashed_border_container.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Step 1 of the job flow. Opened through
/// [RouteHelper.getCreateJobPostScreenRoute], whose CreateJobPostBinding
/// provides the flow's controllers.
class CreateJobPostScreen extends StatefulWidget {
  const CreateJobPostScreen({super.key});

  @override
  State<CreateJobPostScreen> createState() => _CreateJobPostScreenState();
}

class _CreateJobPostScreenState extends State<CreateJobPostScreen> {
  final createJobPostController = Get.find<CreateJobPostController>();
  Worker? _formLoaded;

  @override
  void initState() {
    super.initState();
    // An edit loads the job asynchronously; widgets that read the controller
    // outside Obx need a rebuild once the form is filled.
    _formLoaded = ever(createJobPostController.formRevision, (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _formLoaded?.dispose();
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
        title: AppStrings.createJobPostStep,
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
                          onTap: () {},
                          child: CustomText(AppStrings.jobDetails,
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: SizeConfig.large),
                        ),
                        SizedBox(height: SizeConfig.size15),

                        Row(
                          children: [
                            CustomText(
                              AppStrings.jobBannerImage,
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
                                          AppStrings.selectBannerTemplate,
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
                                              AppStrings.bannerSelected,
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
                          title: AppStrings.companyName,
                          titleColor: AppColors.black,
                          hintText: AppStrings.companyNameHint,
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
                                    String? address) {
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
                          child: IgnorePointer(
                            ignoring: true,
                            child: CommonTextField(
                              textEditController:
                                  createJobPostController.addressEditController,
                              hintText: AppStrings.locationHint,
                              isValidate: false,
                              title: AppStrings.companyAddress,

                              readOnly: true,
                              // Make it read-only since we'll use the search screen
                            ),
                          ),
                        ),

                        SizedBox(
                          height: SizeConfig.size20,
                        ),
                        CommonTextField(
                          textEditController:
                              createJobPostController.jobTitleController,
                          title: AppStrings.jobTitleDesignation,
                          titleColor: AppColors.black,
                          hintText: AppStrings.jobTitleHint,
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
                          title: AppStrings.department,
                          titleColor: AppColors.black,
                          hintText: AppStrings.departmentHint,
                          isValidate: false,
                          hintTextColor: AppColors.grey9B,
                          fontSize: SizeConfig.medium,
                          fontWeight: FontWeight.w400,
                          onChange: (val) =>
                              createJobPostController.department.value = val,
                        ),

                        SizedBox(height: SizeConfig.size20),
                        CustomText(
                          AppStrings.jobType,
                          color: AppColors.black,
                        ),
                        SizedBox(height: SizeConfig.paddingXSL),
                        CommonDropdown<String>(
                          items: jobTypes,
                          selectedValue:
                              createJobPostController.jobType.value.isEmpty
                                  ? null
                                  : createJobPostController.jobType.value,
                          hintText: AppStrings.jobTypeHint,
                          onChanged: (val) {
                            createJobPostController.jobType.value = val ?? "";
                            setState(() {});
                          },
                          displayValue: (item) => item,
                        ),
                        SizedBox(height: SizeConfig.size20),
                        CustomText(
                          AppStrings.workMode,
                          color: AppColors.black,
                        ),
                        SizedBox(height: SizeConfig.paddingXSL),
                        CommonDropdown<String>(
                          items: workModes,
                          selectedValue:
                              createJobPostController.workMode.value.isEmpty
                                  ? null
                                  : createJobPostController.workMode.value,
                          hintText: AppStrings.workModeHint,
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
                        CustomText(AppStrings.compensation,
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: SizeConfig.large),
                        SizedBox(height: SizeConfig.size15),

                        CustomText(
                          AppStrings.whatIsPayType,
                          color: AppColors.black,
                        ),
                        SizedBox(height: SizeConfig.paddingXSL),
                        CommonDropdown<String>(
                          items: payTypes,
                          selectedValue:
                              createJobPostController.payType.value.isEmpty
                                  ? null
                                  : createJobPostController.payType.value,
                          hintText: AppStrings.payTypeHint,
                          onChanged: (val) {
                            createJobPostController.payType.value = val ?? "";
                            setState(() {});
                          },
                          displayValue: (item) => item,
                        ),
                        SizedBox(height: SizeConfig.size20),
                        CustomText(
                          AppStrings.selectSalary,
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
                                hintText: AppStrings.minSalary,
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
                              AppStrings.salaryTo,
                              color: AppColors.black,
                            ),
                            SizedBox(width: SizeConfig.size12),
                            Expanded(
                              child: CommonTextField(
                                textEditController:
                                    createJobPostController.maxSalaryController,
                                hintText: AppStrings.maxSalary,
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

                        CustomText(AppStrings.additionalPerks,
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
                        CustomText(AppStrings.jobDescription,
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: SizeConfig.large),

                        SizedBox(height: SizeConfig.size15),
                        // Job Highlights (chips)
                        CustomText(AppStrings.jobHighlights,
                            color: Colors.black,
                            fontWeight: FontWeight.w600,
                            fontSize: SizeConfig.medium),
                        SizedBox(height: SizeConfig.paddingXSL),
                        CommonTextField(
                          textEditController:
                              createJobPostController.jobHighlightsController,
                          hintText: AppStrings.jobHighlightsHint,
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
                          title: AppStrings.typeYourJobDescription,
                          hintText: AppStrings.jobDescriptionHint,
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
                        onTap: () async {
                          // Validate required fields including image
                          if (!createJobPostController.isEditMode.value &&
                              (_imagePath == null || _imagePath!.isEmpty)) {
                            commonSnackBar(
                                message: AppStrings.pleaseSelectBanner);
                            return;
                          }

                          // 1. Validate Company Name
                          if (createJobPostController.companyNameController.text
                              .trim()
                              .isEmpty) {
                            commonSnackBar(message: 'Company name is required');
                            return;
                          }

                          // 2. Validate Location
                          if (createJobPostController.addressEditController.text
                                  .trim()
                                  .isEmpty ||
                              createJobPostController.startLocationLat?.value ==
                                  0.0) {
                            commonSnackBar(message: 'Job location is required');
                            return;
                          }

                          // 3. Validate Job Title
                          if (createJobPostController.jobTitleController.text
                              .trim()
                              .isEmpty) {
                            commonSnackBar(message: 'Job title is required');
                            return;
                          }

                          // 3b. Validate Department
                          if (createJobPostController.departmentController.text
                              .trim()
                              .isEmpty) {
                            commonSnackBar(message: 'Department is required');
                            return;
                          }

                          // 4. Validate Job Type
                          if (createJobPostController.jobType.value.isEmpty) {
                            commonSnackBar(message: 'Please select a job type');
                            return;
                          }

                          // 5. Validate Work Mode
                          if (createJobPostController.workMode.value.isEmpty) {
                            commonSnackBar(
                                message: 'Please select a work mode');
                            return;
                          }

                          // 6. Validate Pay Type (Compensation)
                          if (createJobPostController.payType.value.isEmpty) {
                            commonSnackBar(message: 'Please select a pay type');
                            return;
                          }

                          // 7. Validate Job Highlights (Optional but must be quality if provided)
                          if (createJobPostController
                              .jobHighlightsController.text
                              .trim()
                              .isNotEmpty) {
                            final text = createJobPostController
                                .jobHighlightsController.text
                                .trim();
                            if (text.length < 10) {
                              commonSnackBar(
                                  message:
                                      'Job highlights must be at least 10 characters long');
                              return;
                            }
                            if (!RegExp(r'[a-zA-Z0-9]').hasMatch(text)) {
                              commonSnackBar(
                                  message:
                                      'Job highlights must contain at least some letters or numbers');
                              return;
                            }
                          }

                          // 8. Validate Job Description
                          if (createJobPostController
                              .jobDescriptionController.text
                              .trim()
                              .isEmpty) {
                            commonSnackBar(
                                message: 'Job description is required');
                            return;
                          }
                          final description = createJobPostController
                              .jobDescriptionController.text
                              .trim();
                          if (description.length < 20) {
                            commonSnackBar(
                                message:
                                    'Job description must be at least 20 characters long');
                            return;
                          }
                          if (!RegExp(r'[a-zA-Z0-9]').hasMatch(description)) {
                            commonSnackBar(
                                message:
                                    'Job description must contain actual letters or numbers');
                            return;
                          }

                          // Validate salary range
                          int minSalary = int.tryParse(createJobPostController
                                      .minSalaryController.text.isNotEmpty
                                  ? createJobPostController
                                      .minSalaryController.text
                                  : "0") ??
                              0;
                          int maxSalary = int.tryParse(createJobPostController
                                      .maxSalaryController.text.isNotEmpty
                                  ? createJobPostController
                                      .maxSalaryController.text
                                  : "0") ??
                              0;

                          if (minSalary == 0 || maxSalary == 0) {
                            commonSnackBar(
                                message: 'Please enter a valid salary range');
                            return;
                          }

                          if (minSalary >= maxSalary) {
                            commonSnackBar(
                                message:
                                    "Max salary must be greater than Min salary");
                            return;
                          }

                          if (await createJobPostController.submitDetails(
                              imagePath: _imagePath)) {
                            Get.toNamed(
                                RouteHelper.getCreateJobPostStep2Route());
                          }
                        },
                        title: createJobPostController.isEditMode.value
                            ? AppStrings.updateJob
                            : AppStrings.continueTxt,
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
// simple boolean flag

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Builder(builder: (context) {
          final visiblePerks = perks.take(5).toList(); // show first 5 initially

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
            ],
          );
        }),
      ],
    );
  }

  Future<void> _selectImage(BuildContext context) async {
    final String? selected = await PhotoPickerService.pickSinglePhoto(
      context,
      AppStrings.uploadProfilePicture,
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


