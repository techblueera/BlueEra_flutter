import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/personal/resume/controller/profile_pic_controller.dart';
import 'package:BlueEra/widgets/ai_description_field_screen.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_drop_down-dialoge.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_enum.dart';

class JobSeekerPersonalDetailsScreen extends StatefulWidget {
  const JobSeekerPersonalDetailsScreen({Key? key}) : super(key: key);

  @override
  State<JobSeekerPersonalDetailsScreen> createState() =>
      _JobSeekerPersonalDetailsScreenState();
}

class _JobSeekerPersonalDetailsScreenState
    extends State<JobSeekerPersonalDetailsScreen> {
  // final ProfileBioController controller = Get.put(ProfileBioController());
  // final ProfilePicController controller = Get.find<ProfilePicController>();
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
    "Min Level",
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

    nameController.addListener(_validate);
    emailController.addListener(_validate);
    phoneController.addListener(_validate);
    locationController.addListener(_validate);

    _validate();
  }

  void _validate() {
    final phoneValid =
        RegExp(r'^\d{10}$').hasMatch(phoneController.text.trim());
    final valid = nameController.text.trim().isNotEmpty &&
        emailController.text.trim().isNotEmpty &&
        careerObjController.text.trim().isNotEmpty &&
        descriptionController.text.trim().isNotEmpty &&
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
                      CommonTextField(
                        onChange: (val) {
                          setState(() {});
                        },
                        title: AppStrings.fullName,
                        hintText: "E.g. Sujoy Ghosh",
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
                            return 'Enter valid email';
                          }
                        },
                        title: AppStrings.email,
                        hintText: "E.g. bluecs.info@gmail.com",
                        fontSize: SizeConfig.small,
                        textEditController: emailController,
                        keyBoardType: TextInputType.emailAddress,
                      ),
                      SizedBox(height: SizeConfig.paddingL),
                      CommonTextField(
                        validationType: ValidationTypeEnum.pNumber,
                        onChange: (val) {},
                        title: AppStrings.phoneNumber,
                        hintText: "E.g. +91 1234567890",
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
                          hintText: AppStrings.locationHint,
                          isValidate: false,
                          title: AppStrings.location,

                          // onChange: (value) => controller.validateForm(),
                          readOnly: true,
                          // Make it read-only since we'll use the search screen
                        ),
                      ),
                      SizedBox(height: SizeConfig.paddingL),
                      // Obx(() {
                      //   return
                      AiDescriptionField(
                        label: "Short Bio",
                        hintText: "Tell us more about info...",
                        controller: descriptionController,
                        rxValue: "".obs,
                        // Your RX variable from the controller
                        aiType: "Short Bio",
                        aiData: {
                          "name": nameController.text,
                          "email": emailController.text,
                          "phone": phoneController.text,
                          "location": locationController.text,
                          // "title": controller.title.value,
                        },
                      ),
                      // }),
                      SizedBox(height: SizeConfig.paddingL),

                      CommonTextField(
                        onChange: (val) {
                          setState(() {});
                        },
                        title: AppStrings.careerObjective,
                        hintText: "E.g.Give your career objective",
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
                        hintText: "Select Work Option",
                        onChanged: (val) {
                          selectedOpenWorkOption = val ?? "";
                          setState(() {});
                        },
                        displayValue: (item) => item,
                        title: "Open To Work",
                        dialogTitle: "Open To Work",
                      ),
                      SizedBox(height: SizeConfig.paddingL),

                      CommonDropdownDialog<String>(
                        items: experienceLevelOptions,
                        selectedValue: selectedExpLevelOpt,
                        hintText: "Select Experience Level",
                        onChanged: (val) {
                          selectedExpLevelOpt = val ?? "";
                          setState(() {});
                        },
                        displayValue: (item) => item,
                        title: 'Experience Level',
                        dialogTitle: 'Experience Level',
                      ),

                      SizedBox(height: SizeConfig.paddingXXL),
                      CustomBtn(
                        title: AppStrings.update,
                        isValidate: isValid,
                        onTap: (isValid == false ||
                                phoneController.text.isEmpty ||
                                phoneController.text.length < 10)
                            ? null
                            : () async {
                                await controller.updateProfileDetails(
                                  name: nameController.text.trim(),
                                  email: emailController.text.trim(),
                                  phone: phoneController.text.trim(),
                                  location: locationController.text.trim(),
                                );
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
