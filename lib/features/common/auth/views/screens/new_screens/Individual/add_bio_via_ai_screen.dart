import 'dart:developer';

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/common/auth/controller/ai_suggestion_controller.dart';
import 'package:BlueEra/features/common/bottomNavigationBar/auth/controller/bottom_bar_controller.dart';
import 'package:BlueEra/features/personal/auth/controller/view_personal_details_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/controller/perosonal__create_profile_controller.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AddBioViaAiScreen extends StatefulWidget {
  final String profession;
  final String? designation;
  final int? selectedYear;
  final int? selectedMonth;
  final int? selectedDay;

  const AddBioViaAiScreen({
    super.key,
    required this.profession,
    required this.designation,
    required this.selectedYear,
    required this.selectedMonth,
    required this.selectedDay});

  @override
  State<AddBioViaAiScreen> createState() => _AddBioViaAiScreenState();
}

class _AddBioViaAiScreenState extends State<AddBioViaAiScreen> {
  final aiController = Get.put(AiSuggestionController());
  final ViewPersonalDetailsController viewPersonalDetailsController =
        Get.find<ViewPersonalDetailsController>();
  final personalCreateProfileController =
        Get.put(PersonalCreateProfileController());
  final TextEditingController bioController = TextEditingController();
  GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool isFormValid = false;

  @override
  void initState() {
    log(
        "PROFILE DATA → "
            "Profession: ${widget.profession}, "
            "Designation: ${widget.designation}, "
            "Year: ${widget.selectedYear}, "
            "Month: ${widget.selectedMonth}, "
            "Day: ${widget.selectedDay}"
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
     appBar: CommonBackAppBar(
       title: AppStrings.personalDetails,
     ),
      body: CustomFormCard(
        margin: EdgeInsets.symmetric(
          horizontal: SizeConfig.size8,
          vertical: SizeConfig.size15,
        ),
        padding: EdgeInsets.all(10.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CustomText(
                    "About Me / Bio",
                    fontSize: SizeConfig.large,
                    fontWeight: FontWeight.w600,
                    color: AppColors.secondaryTextColor,
                  ),
                 SizedBox(width: SizeConfig.size8),
                  InkWell(
                    onTap: () async {
                      await aiController.fetchSuggestions(
                        bodyRequest: {
                          ApiKeys.profession: widget.profession,
                          ApiKeys.designation: widget.designation,
                          ApiKeys.date_of_birth_Obj: {
                            ApiKeys.year: widget.selectedYear,
                            ApiKeys.month: widget.selectedMonth,
                            ApiKeys.date: widget.selectedDay
                          },
                          ApiKeys.gender: viewPersonalDetailsController.personalProfileDetails.value.user?.gender
                        },
                        apiType: "bio",
                        targetController: bioController,
                        onSaved: (){
                          validateForm();
                        }
                      );
                    },
                    child: Obx(()=> aiController.isLoading.value ?
                     SizedBox(
                       height: 25,
                       width: 25,
                       child: CircularProgressIndicator(
                         strokeWidth: 2.0,
                       ),
                     )
                    : LocalAssets(
                      height: 25,
                      width: 25,
                      imagePath: AppIconAssets.ai_generative,
                      imgColor: AppColors.primaryColor,
                    )),
                  ),
                ],
              ),
              SizedBox(height: SizeConfig.paddingXSL),
              CommonTextField(
                maxLength: 900,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return AppStrings.pleaseEnterBio.tr;
                  } else if (value.trim().length < 50) {
                    return AppStrings.bioMinLength.tr;
                  } else if (value.trim().length > 900) {
                    return AppStrings.bioMaxLength.tr;
                  }
                  return null;
                },
                hintText: "${AppStrings.writeYour.tr} ...",
                textEditController: bioController,
                maxLine: 5,
                isCounterVisible: true,
                onChange: (value)=> validateForm(),
              ),
              SizedBox(height: SizeConfig.paddingL),
              Row(
                children: [
                  Expanded(
                    child: CustomBtn(
                      radius: 10,
                      onTap: () {
                        Get.until((route) =>
                                 route.settings.name == RouteHelper.getBottomNavigationBarScreenRoute());
                      },
                      title: AppStrings.skip,
                      bgColor: Colors.transparent,
                      textColor: AppColors.primaryColor,
                      borderColor: AppColors.primaryColor,
                    ),
                  ),
                  SizedBox(
                    width: SizeConfig.size10,
                  ),
                  Expanded(
                    child: CustomBtn(
                      radius: 10,
                      onTap: () async {
                        if (_formKey.currentState!.validate()) {
                          await personalCreateProfileController
                              .updateUserProfileDetails(
                            params: {
                              ApiKeys.bio: bioController.text.trim(),
                            },
                          );

                          final bottomBarController = Get.find<BottomBarController>();

                          // Go back until Bottom Navigation screen
                          Get.until((route) =>
                          route.settings.name ==
                              RouteHelper.getBottomNavigationBarScreenRoute());

                          // Check if profession belongs to Self Employed category
                          if (widget.profession == SELF_EMPLOYED) {
                            print("Self Employed Profession → ${widget.profession}");
                            bottomBarController.currentIndex.value = 2; // Switch to Me tab
                          } else {
                            print("Social Individual Profession → ${widget.profession}");
                            // If needed, you can set a different index here
                            // bottomBarController.currentIndex.value = 0;
                          }
                        }
                      },
                      title: AppStrings.submit,
                      isValidate: isFormValid,
                    ),
                  ),
                ],
              ),
              SizedBox(height: SizeConfig.paddingXSL),
            ],
          ),
        ),
      ),
    );
  }

  void validateForm() {
    log('validate');
    isFormValid = bioController.text.trim().isNotEmpty;
    setState(() {});
  }
}
