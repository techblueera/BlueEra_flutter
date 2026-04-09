import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/personal/resume/controller/profile_pic_controller.dart';
import 'package:BlueEra/features/personal/resume/fields/resume_profile_header.dart';
import 'package:BlueEra/widgets/ai_description_field_screen.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_drop_down-dialoge.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_enum.dart';
import '../../../../core/constants/regular_expression.dart';

class JobSeekerPersonalDetailsScreen extends StatefulWidget {
  const JobSeekerPersonalDetailsScreen({Key? key}) : super(key: key);

  @override
  State<JobSeekerPersonalDetailsScreen> createState() =>
      _JobSeekerPersonalDetailsScreenState();
}

class _JobSeekerPersonalDetailsScreenState
    extends State<JobSeekerPersonalDetailsScreen> {
  final controller = getOrPut(() => ProfilePicController());

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final locationController = TextEditingController();
  final descriptionController = TextEditingController();
  final careerObjController = TextEditingController();

  bool isValid = false;
  String? selectedOpenWorkOption, selectedExpLevelOpt;

  final openWorkOptions = ['Yes', "No"];
  final experienceLevelOptions = [
    "Intern",
    "Fresher",
    "Mid Level",
    "Senior Level"
  ];

  @override
  void initState() {
    super.initState();
    final data = controller.getResumeData.value;
    nameController.text = data.name ?? '';
    emailController.text = data.email ?? '';
    phoneController.text = data.phone ?? '';
    locationController.text = data.location ?? '';
    descriptionController.text = data.bio ?? '';
    careerObjController.text = data.careerObjective ?? '';
    selectedOpenWorkOption = data.openToWork?? '';
    selectedExpLevelOpt = data.experienceLevel?? '';

    nameController.addListener(_validate);
    emailController.addListener(_validate);
    phoneController.addListener(_validate);
    locationController.addListener(_validate);

    _validate();
  }

  void _validate() {
    final phoneValid =
        ValidationMethod.validatePhone(phoneController.text.trim()) == null;
    final valid = nameController.text.trim().isNotEmpty &&
        emailController.text.trim().isNotEmpty &&
        careerObjController.text.trim().isNotEmpty &&
        (selectedExpLevelOpt?.isNotEmpty ?? false) &&
        (selectedOpenWorkOption?.isNotEmpty ?? false) &&
        phoneValid &&
        locationController.text.trim().isNotEmpty;
    if (valid != isValid) {
      setState(() {
        isValid = valid;
      });
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    locationController.dispose();
    descriptionController.dispose();
    careerObjController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(title: AppStrings.personalDetails.tr),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(SizeConfig.paddingS),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 500),
              child: Card(
                color: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(SizeConfig.size10),
                ),
                child: Padding(
                  padding: EdgeInsets.all(SizeConfig.paddingL),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ResumeProfileHeader(),
                      ),
                      CommonTextField(
                        onChange: (val) {
                          setState(() {});
                        },
                        title: AppStrings.fullName.tr,
                        hintText: AppStrings.egNameHint.tr,
                        fontSize: SizeConfig.small,
                        textEditController: nameController,
                      ),
                      SizedBox(height: SizeConfig.paddingL),
                      CommonTextField(
                        validationType: ValidationTypeEnum.email,
                        onChange: (email) {
                          final emailRegex = RegExp(
                              r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$');
                          if (emailRegex.hasMatch(email)) {
                            isValid = true;
                          } else {
                            isValid = false;
                          }
                          setState(() {});
                        },
                        validator: (email) {
                          final emailRegex = RegExp(
                              r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$');
                          if (emailRegex.hasMatch(email ?? '')) {
                            isValid = true;
                            return null;
                          } else {
                            isValid = false;
                            return AppStrings.enterValidEmail.tr;
                          }
                        },
                        title: AppStrings.email.tr,
                        hintText: AppStrings.egEmailHint.tr,
                        fontSize: SizeConfig.small,
                        textEditController: emailController,
                        keyBoardType: TextInputType.emailAddress,
                      ),
                      SizedBox(height: SizeConfig.paddingL),
                      CommonTextField(
                        validationType: ValidationTypeEnum.pNumber,
                        onChange: (val) {},
                        title: AppStrings.phoneNumber.tr,
                        hintText: AppStrings.egPhoneHint.tr,
                        textEditController: phoneController,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(10),
                        ],
                        fontSize: SizeConfig.small,
                        keyBoardType: TextInputType.phone,
                      ),
                      SizedBox(height: SizeConfig.paddingL),
                      InkWell(
                        child: CommonTextField(
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              RouteHelper.getSearchLocationScreenRoute(),
                              arguments: {
                                'onPlaceSelected': (double? lat, double? lng,
                                    String? address) {
                                  if (address != null) {
                                    locationController.text = address;
                                    setState(() {});
                                  }
                                },
                                ApiKeys.fromScreen: ""
                              },
                            );
                          },
                          textEditController: locationController,
                          hintText: AppStrings.locationHint.tr,
                          isValidate: false,
                          title: AppStrings.location.tr,

                          // onChange: (value) => controller.validateForm(),
                          readOnly: true,
                          // Make it read-only since we'll use the search screen
                        ),
                      ),
                      SizedBox(height: SizeConfig.paddingL),
                      // Obx(() {
                      //   return
                      AiDescriptionField(
                        label: AppStrings.shortBio.tr,
                        hintText: AppStrings.tellUsMoreAboutInfo.tr,
                        controller: descriptionController,
                        rxValue: "".obs,
                        // Your RX variable from the controller
                        aiType: "Short Bio",
                        aiData: {
                          "name": nameController.text,
                          "email": emailController.text,
                          "phone": phoneController.text
                          // "title": controller.title.value,
                        },
                      ),
                      // }),
                      SizedBox(height: SizeConfig.paddingL),

                      CommonTextField(
                        onChange: (val) {
                          _validate();

                          setState(() {});
                        },
                        title: AppStrings.careerObjective.tr,
                        hintText: AppStrings.egCareerObjective.tr,
                        fontSize: SizeConfig.small,
                        textEditController: careerObjController,
                      ),
                      SizedBox(height: SizeConfig.paddingL),

                      /*   Obx(() => CommonDropdown<String>(
                        items: controller.jobTypeOptions,
                        selectedValue: controller.selectedJobType.value,
                        hintText: AppStrings.jobTypeHint,
                        onChanged: (val) =>
                        controller.selectedJobType.value = val,
                        displayValue: (item) => item,
                      )),*/
                      CommonDropdownDialog<String>(
                        items: openWorkOptions,
                        selectedValue: selectedOpenWorkOption,
                        hintText: AppStrings.selectWorkOption.tr,
                        onChanged: (val) {
                          selectedOpenWorkOption = val ?? "";
                          _validate();

                          setState(() {});
                        },
                        displayValue: (item) => item,
                        title: AppStrings.openToWork.tr,
                        dialogTitle: AppStrings.openToWork.tr,
                      ),
                      SizedBox(height: SizeConfig.paddingL),

                      CommonDropdownDialog<String>(
                        items: experienceLevelOptions,
                        selectedValue: selectedExpLevelOpt,
                        hintText: AppStrings.selectExperienceLevel.tr,
                        onChanged: (val) {
                          selectedExpLevelOpt = val ?? "";
                          _validate();

                          setState(() {});
                        },
                        displayValue: (item) => item,
                        title: AppStrings.experienceLevel.tr,
                        dialogTitle: AppStrings.experienceLevel.tr,
                      ),

                      SizedBox(height: SizeConfig.paddingXXL),
                      CustomBtn(
                        title: AppStrings.update.tr,
                        isValidate: isValid,
                        onTap: (isValid == false)
                            ? null
                            : () async {
                                await controller.updateProfileDetails(
                                    name: nameController.text.trim(),
                                    email: emailController.text.trim(),
                                    phone: phoneController.text.trim(),
                                    location: locationController.text.trim(),
                                    openToWork: selectedOpenWorkOption ?? "",
                                    experienceLevel: selectedExpLevelOpt ?? "",
                                    bio: descriptionController.text,
                                    careerObjective: careerObjController.text);
                              },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
