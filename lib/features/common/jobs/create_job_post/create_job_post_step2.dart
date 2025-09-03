import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/common/jobs/controller/create_job_post_controller.dart';
import 'package:BlueEra/l10n/app_localizations.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../widgets/common_drop_down.dart';

class CreateJobPostStep2 extends StatefulWidget {
  CreateJobPostStep2({super.key});

  @override
  State<CreateJobPostStep2> createState() => _CreateJobPostStep2State();
}

class _CreateJobPostStep2State extends State<CreateJobPostStep2> {
  final controller = Get.find<CreateJobPostController>();
  
  // Add text controller for skills
  TextEditingController skillsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    
    // Wait for the next frame to ensure controller is properly initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeDataFromAPI();
      
      // Listen for changes in job details (in case API data loads after widget is built)
      ever(controller.jobDetails, (jobDetails) {
        if (jobDetails != null) {
          print('Job details updated, re-initializing data');
          _initializeDataFromAPI();
        }
      });
    });
  }

  void _initializeDataFromAPI() {
    try {
      final jobDetails = controller.jobDetails.value?.job;
      
      // Only initialize if we're in edit mode and have job details
      if (controller.isEditMode.value && jobDetails != null) {
        print('Initializing data from API for edit mode');
        
        // Assign qualification (String)
        controller.selectQualification.value = jobDetails.qualifications ?? "";
        print('Set qualification: ${jobDetails.qualifications}');

        // Assign experience as String
        controller.selectTotalExperience.value = jobDetails.experience?.toString() ?? "";
        print('Set experience: ${jobDetails.experience}');

        // Assign skills safely as List<String>
        if (jobDetails.skills != null && jobDetails.skills!.isNotEmpty) {
          controller.selectedSkills.value = List<String>.from(jobDetails.skills!);
          // Set the skills text field to show the skills
          skillsController.text = jobDetails.skills!.join(', ');
          print('Set skills: ${jobDetails.skills}');
        } else {
          // Clear skills if none exist
          controller.selectedSkills.clear();
          skillsController.clear();
          print('No skills found, cleared skills');
        }

        // Assign gender (custom enum)
        if (jobDetails.gender != null && jobDetails.gender!.isNotEmpty) {
          controller.selectedGender.value = jobDetails.gender!;
          _selectedGender = genderFromString(jobDetails.gender);
          print('Set gender: ${jobDetails.gender}');
          print('Selected gender enum: $_selectedGender');
        } else {
          controller.selectedGender.value = "";
          _selectedGender = null;
          print('No gender found or empty, cleared gender selection');
        }
        
        // Force UI update to reflect the gender selection
        setState(() {});


        // Assign languages
        if (jobDetails.languages != null && jobDetails.languages!.isNotEmpty) {
          controller.selectedLanguages.clear();
          controller.selectedLanguages.addAll(jobDetails.languages!);
          print('Set languages: ${jobDetails.languages}');
        } else {
          // Set default language if none exist
          controller.selectedLanguages.clear();
          controller.selectedLanguages.add('English');
          print('No languages found, set default to English');
        }
      } else {
        print('Not in edit mode or no job details found, using default values');
        // Set default values for new job creation
        controller.selectedLanguages.clear();
        controller.selectedLanguages.add('English'); // Default language
        controller.selectedSkills.clear();
        skillsController.clear();
        controller.selectedGender.value = "";
        _selectedGender = null;
      }
    } catch (e) {
      print('Error initializing data from API: $e');
      // Set default values on error
      controller.selectedLanguages.clear();
      controller.selectedLanguages.add('English');
      controller.selectedSkills.clear();
      skillsController.clear();
      controller.selectedGender.value = "";
      _selectedGender = null;
    }
  }

  @override
  void dispose() {
    skillsController.dispose();
    super.dispose();
  }

  GenderType? genderFromString(String? gender) {
    if (gender == null || gender.isEmpty) {
      print('Gender is null or empty');
      return null;
    }
    
    print('Converting gender string: "$gender"');
    
    switch (gender.toLowerCase().trim()) {
      case 'male':
        print('Converted to GenderType.Male');
        return GenderType.Male;
      case 'female':
        print('Converted to GenderType.Female');
        return GenderType.Female;
      default:
        print('Unknown gender value: "$gender", returning null');
        return null;
    }
  }

  final List<String> qualificationsList = ["10th", "12th", "Diploma", "Degree"];

  final List<String> totalExperienceList = [
    "1 Year",
    "2 Year",
    "3 Year",
    "4 Year",
    "5 Year",
  ];

  GenderType? _selectedGender;

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context);

    return Scaffold(
      appBar: CommonBackAppBar(
        title: "Create Job Post (Step 2 of 4)",
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
              horizontal: SizeConfig.size15, vertical: SizeConfig.size15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                      CustomText("Candidate Basic Requirements",
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: SizeConfig.large),
                      SizedBox(height: SizeConfig.size15),

                      CustomText(
                        "Qualifications",
                        color: AppColors.black,
                      ),
                      SizedBox(height: SizeConfig.size10),
                      Obx(() => CommonDropdown<String>(
                        items: qualificationsList,
                        selectedValue:
                            controller.selectQualification.value.isEmpty
                                ? null
                                : controller.selectQualification.value,
                        hintText: "Eg. 10th ",
                        onChanged: (val) =>
                            controller.selectQualification.value = val ?? "",
                        displayValue: (item) => item,
                      )),
                      SizedBox(height: SizeConfig.size20),
                      _buildLanguageSelection(),
                      SizedBox(height: SizeConfig.size20),

                      CustomText(
                        "Total Experience Required",
                        color: AppColors.black,
                      ),
                      SizedBox(height: SizeConfig.size10),
                      Obx(() => CommonDropdown<String>(
                        items: totalExperienceList,
                        selectedValue:
                            controller.selectTotalExperience.value.isEmpty
                                ? null
                                : controller.selectTotalExperience.value,
                        hintText: "Eg. 1 Years ",
                        onChanged: (val) =>
                            controller.selectTotalExperience.value = val ?? "",
                        displayValue: (item) => item,
                      )),
                      SizedBox(
                        height: SizeConfig.size20,
                      ),
                      CommonTextField(
                        title: "Skill",
                        titleColor: AppColors.black,
                        hintText: "Eg. UI/UX Design",
                        isValidate: false,
                        hintTextColor: AppColors.grey9B,
                        fontSize: SizeConfig.medium,
                        fontWeight: FontWeight.w400,
                        textEditController: skillsController,
                        onChange: (val) {
                          controller.selectedSkills.value = val.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
                        },
                      ),
                      SizedBox(height: SizeConfig.size10),
                      // Display selected skills
                      SizedBox(height: SizeConfig.size20),

                      // Gender
                      CustomText(
                        "${appLocalizations?.selectGender} (Optional)",
                        fontSize: SizeConfig.medium,
                      ),
                      SizedBox(
                        height: SizeConfig.size10,
                      ),
                      CommonDropdown<GenderType>(
                        items: GenderType.values,
                        selectedValue: _selectedGender,
                        hintText: appLocalizations?.selectGenderHint ?? '',
                        displayValue: (value) => value.displayName,
                        onChanged: (value) {
                          setState(() {
                            _selectedGender = value;
                            controller.selectedGender.value = value?.displayName ?? '';
                          });
                        },
                        validator: (value) {
                          if (value == null) {
                            return 'Please select your gender';
                          }
                          return null;
                        },
                      ),
                      SizedBox(
                        height: SizeConfig.size20,
                      ),

                      SizedBox(height: SizeConfig.size5),
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
                      title: "Back",
                      bgColor: AppColors.white,
                      borderColor: AppColors.primaryColor,
                      textColor: AppColors.primaryColor,
                    )),
                    SizedBox(
                      width: SizeConfig.size10,
                    ),
                    Expanded(
                        child: PositiveCustomBtn(
                      onTap: () async {
                        final jobId = controller.jobID.value;
                        if (jobId.isNotEmpty) {
                          await controller.postJobStep2Api(jobId: jobId);
                        } else {
                          commonSnackBar(message: 'Job ID is missing. Please try again.');
                        }
                      },
                      title: "Continue",
                    ))
                  ],
                ),
              ),
              SizedBox(height: SizeConfig.size20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const CustomText(
          'Select Languages',
            fontWeight: FontWeight.w500,
        ),
        const SizedBox(height: 8),
        Obx(() => Wrap(
          spacing: 4,
          runSpacing: 4,
          children: [
            ...controller.selectedLanguages.map((language) {
              return Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.buttonLiteBlue,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CustomText(
                      language,
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () {
                        controller.selectedLanguages.remove(language);
                      },
                      child: LocalAssets(imagePath: AppIconAssets.close_white,height: 15,width: 15,imgColor: AppColors.black,),
                    ),
                  ],
                ),
              );
            }).toList(),
            ...controller.availableLanguages
                .where((language) =>
            !controller.selectedLanguages.contains(language))
                .take(3)
                .map((language) {
              return GestureDetector(
                onTap: () {
                  controller.selectedLanguages.add(language);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.borderGray),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CustomText(
                        language,
                      ),
                      const SizedBox(width: 4),
                      LocalAssets(imagePath: AppIconAssets.add,imgColor: AppColors.borderGray,)
                    ],
                  ),
                ),
              );
            }).toList(),
            if (controller.availableLanguages
                .where((language) =>
            !controller.selectedLanguages.contains(language))
                .length >
                3)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'More',
                      style: TextStyle(
                        color: AppColors.primaryColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    LocalAssets(imagePath:
                      'assets/svg/drop_down.svg',
                      height: 14,
                      width: 14,
                      imgColor: AppColors.primaryColor,
                    ),
                  ],
                ),
              ),
          ],
        )),
      ],
    );
  }
}
