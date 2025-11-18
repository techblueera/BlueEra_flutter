import 'dart:convert';
import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_http_links_textfiled_widget.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/no_leading_space_formatter.dart';
import 'package:BlueEra/core/constants/regular_expression.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/controller/location_controller.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/features/business/business_description/business_description_controller.dart';
import 'package:BlueEra/features/business/visiting_card/view/widget/contact_number_widget.dart';
import 'package:BlueEra/l10n/app_localizations.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:pinput/pinput.dart';

class CreateBusinessAccountStepTwo extends StatefulWidget {
  const CreateBusinessAccountStepTwo({
    super.key,
  });

  @override
  State<CreateBusinessAccountStepTwo> createState() =>
      _CreateBusinessAccountStepTwoState();
}

class _CreateBusinessAccountStepTwoState
    extends State<CreateBusinessAccountStepTwo> {
  final mobileController = TextEditingController();
  final landlineNumberController = TextEditingController();
  final landlineCodeController = TextEditingController();
  final websiteController = TextEditingController();
  final fullBusinessAddressTextController = TextEditingController();
  final cityController = TextEditingController();
  final picCodeController = TextEditingController();
  final nameTextController = TextEditingController();
  final yourRoleController = TextEditingController();
  final emailTextController = TextEditingController();
  ContactType? selectedType = ContactType.Mobile;
  final descriptionController = Get.put(BusinessDescriptionController());
  final viewBusinessDetailsController =
      Get.find<ViewBusinessDetailsController>();
  bool isFormValid = false;
  final locationController = Get.put(LocationController());

  @override
  void initState() {
    super.initState();

    // Add listeners for validation
    mobileController.addListener(_validateForm);
    landlineCodeController.addListener(_validateForm);
    landlineNumberController.addListener(_validateForm);
    websiteController.addListener(_validateForm);
    cityController.addListener(_validateForm);
    fullBusinessAddressTextController.addListener(_validateForm);
    nameTextController.addListener(_validateForm);
    yourRoleController.addListener(_validateForm);
    emailTextController.addListener(_validateForm);
    viewBusinessDetailsController.listingDescriptionController.value
        .addListener(_validateForm);
    picCodeController.addListener(_validateForm);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      updateAddressFromLocation();
    });
  }

  Future<void> updateAddressFromLocation() async {
    final locationData = await locationController.checkPermissionAndSetData();
    if (locationData != null) {
      fullBusinessAddressTextController.text = locationData.fullAddress;
      cityController.text = locationData.city;
      picCodeController.text = locationData.pinCode;
      viewBusinessDetailsController.addressLat?.value =
          double.parse(locationData.lat);
      viewBusinessDetailsController.addressLong?.value =
          double.parse(locationData.long);
    }
  }

  void _validateForm() {
    setState(() {
      bool commonValid = cityController.text.trim().isNotEmpty &&
          fullBusinessAddressTextController.text.trim().isNotEmpty &&
          nameTextController.text.trim().isNotEmpty &&
          yourRoleController.text.trim().isNotEmpty &&
          viewBusinessDetailsController.businessDescription.value
              .trim()
              .isNotEmpty &&
          picCodeController.text.trim().isNotEmpty &&
          emailTextController.text.trim().isNotEmpty;

      if (selectedType == ContactType.Mobile) {
        isFormValid = commonValid &&
            mobileController.text.trim().isNotEmpty &&
            mobileController.text.length == 10;
      } else if (selectedType == ContactType.Landline) {

        isFormValid = commonValid &&
            landlineNumberController.text.trim().isNotEmpty &&
            landlineNumberController.text.length >= 6 &&
            landlineNumberController.text.length <= 8;
      } else {
        isFormValid = false;
      }
    });
  }


  @override
  void dispose() {
    mobileController.dispose();
    landlineCodeController.dispose();
    landlineNumberController.dispose();
    websiteController.dispose();
    cityController.dispose();
    fullBusinessAddressTextController.dispose();
    nameTextController.dispose();
    yourRoleController.dispose();
    emailTextController.dispose();

    picCodeController.dispose();
    // landmarkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
        appBar: CommonBackAppBar(
          isLeading: false,
        ),
        body: SingleChildScrollView(
          child: Container(
            margin: EdgeInsets.symmetric(
                horizontal: SizeConfig.size16, vertical: SizeConfig.size16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: SizeConfig.size16, vertical: SizeConfig.size30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ///Mobile number

                  ContactInputField1(
                    mobileController: mobileController,
                    landlineCodeController: landlineCodeController,
                    landlineNumberController: landlineNumberController,
                    selectedType: selectedType ?? ContactType.Mobile,
                    onTypeChanged: (type) {
                      mobileController.clear();
                      landlineCodeController.clear();
                      landlineNumberController.clear();
                      setState(() {
                        selectedType = type;
                      });

                      _validateForm();
                    },
                    prefixOnChange: (value) => true,
                    mobileNumberOnChange: (String) {},
                  ),
                  SizedBox(
                    height: SizeConfig.size20,
                  ),

                  ///websiteOptional
                  CustomText(
                    AppStrings.websiteOptional,
                    fontSize: SizeConfig.medium,
                    fontWeight: FontWeight.w500,
                    color: AppColors.black,
                  ),
                  SizedBox(
                    height: SizeConfig.size10,
                  ),
                  HttpsTextField(
                    controller: websiteController,
                    hintText: AppLocalizations.of(context)!.websiteLinkHere,
                  ),
                  SizedBox(
                    height: SizeConfig.size20,
                  ),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CommonTextField(
                        readOnly: true,
                        maxLine: 3,
                        textEditController: fullBusinessAddressTextController,
                        inputLength: AppConstants.inputCharterLimit50,
                        keyBoardType: TextInputType.text,
                        title: AppStrings.fullBusinessAddress,
                        regularExpression:
                            RegularExpressionUtils.alphabetSpacePattern,
                        hintText: AppStrings.addressHint,
                        isValidate: false,
                      ),
                      _buildAddressField()
                    ],
                  ),

                  SizedBox(
                    height: SizeConfig.size20,
                  ),

                  ///ENTER Landmark ......
                  // CommonTextField(
                  //   textEditController: landmarkController,
                  //   inputLength: AppConstants.inputCharterLimit200,
                  //   keyBoardType: TextInputType.text,
                  //   regularExpression:
                  //   RegularExpressionUtils.alphabetSpacePattern,
                  //   title: 'Floor / Building Name / Landmark',
                  //   hintText: 'Floor / Building Name / Landmark',
                  //   isValidate: false,
                  // ),
                  // SizedBox(
                  //   height: SizeConfig.size20,
                  // ),

                  ///ENTER CITY NAME ......
                  CommonTextField(
                    textEditController: cityController,
                    inputLength: AppConstants.inputCharterLimit50,
                    keyBoardType: TextInputType.text,
                    regularExpression:
                        RegularExpressionUtils.alphabetSpacePattern,
                    title: AppStrings.city,
                    hintText: AppStrings.city,
                    isValidate: false,
                    readOnly: true,
                  ),
                  SizedBox(
                    height: SizeConfig.size20,
                  ),

                  ///ENTER PIN CODE NAME ......
                  CommonTextField(
                    textEditController: picCodeController,
                    inputLength: AppConstants.inputCharterLimit6,
                    keyBoardType: TextInputType.number,
                    regularExpression: RegularExpressionUtils.digitsPattern,
                    title: AppStrings.pincodeTitle,
                    hintText: AppStrings.pincodeHint,
                    isValidate: true,
                  //  readOnly: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return AppStrings.pleaseEnterPinCode.tr;
                      } else if (!RegExp(RegularExpressionUtils.pinCodeRegExp)
                          .hasMatch(value)) {
                        return AppStrings.enterValidIndianPincode.tr;
                      }
                      return null;
                    },
                  ),
                  SizedBox(
                    height: SizeConfig.size28,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CustomText(
                        AppStrings.shortBusinessDescription,
                        fontSize: SizeConfig.medium,
                        fontWeight: FontWeight.w400,
                        color: AppColors.black,
                      ),
                      InkWell(
                          onTap: () async {
                            await descriptionController.generateDescriptions(
                                onSaved: _validateForm,
                                bodyRequest: {
                                  ApiKeys.business_name:
                                      viewBusinessDetailsController
                                          .businessProfileDetails
                                          ?.data
                                          ?.businessName,
                                  ApiKeys.category:
                                      viewBusinessDetailsController
                                          .businessProfileDetails
                                          ?.data
                                          ?.categoryDetails
                                          ?.name,
                                  ApiKeys.sub_category:
                                      viewBusinessDetailsController
                                          .businessProfileDetails
                                          ?.data
                                          ?.subCategoryDetails
                                          ?.name,
                                  ApiKeys.city: cityController.text,
                                });
                            _validateForm();

                            setState(() {});
                          },
                          child: LocalAssets(
                            height: 25,
                            width: 25,
                            imgColor: AppColors.primaryColor,
                            imagePath: AppIconAssets.ai_generative,
                          )),
                    ],
                  ),
                  SizedBox(height: SizeConfig.paddingXSL),
                  CommonTextField(
                    validator: null,
                    borderWidth: 0,
                    borderColor: Colors.transparent,
                    hintText:
                    AppStrings.businessDescriptionExample,
                    textEditController: viewBusinessDetailsController
                        .listingDescriptionController.value,
                    maxLine: 5,
                    isValidate: false,
                    maxLength: AppConstants.inputCharterLimit400,
                    onChange: (val) {
                      viewBusinessDetailsController.businessDescription.value =
                          val;
                      _validateForm();
                    },
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(
                        AppConstants.inputCharterLimit400,
                      ),
                      NoLeadingSpaceFormatter(),
                      NoConsecutiveSpacesFormatter(),
                    ],
                  ),
                  SizedBox(height: SizeConfig.size10),
                  Obx(() {
                    return Align(
                      alignment: Alignment.bottomRight,
                      child: CustomText(
                        "${viewBusinessDetailsController.businessDescription.value.length}/${AppConstants.inputCharterLimit400}",
                        color: AppColors.grey9B,
                        fontSize: SizeConfig.small,
                      ),
                    );
                  }),
                  SizedBox(
                    height: SizeConfig.size28,
                  ),
                  Center(
                    child: CustomText(
                      AppStrings.ownerDetail,
                      fontSize: SizeConfig.large,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(
                    height: SizeConfig.size20,
                  ),
                  CommonTextField(
                    textEditController: nameTextController,
                    inputLength: AppConstants.inputCharterLimit50,
                    keyBoardType: TextInputType.text,
                    regularExpression:
                        RegularExpressionUtils.alphabetSpacePattern,
                    title: AppStrings.yourNameHint,
                    hintText: AppConstants.name,
                    isValidate: false,
                  ),
                  SizedBox(
                    height: SizeConfig.size20,
                  ),
                  CommonTextField(
                    textEditController: yourRoleController,
                    inputLength: AppConstants.inputCharterLimit50,
                    keyBoardType: TextInputType.text,
                    regularExpression:
                        RegularExpressionUtils.alphabetSpacePattern,
                    title: AppStrings.yourRole,
                    hintText: AppStrings.yourRoleHint,
                    isValidate: false,
                  ),
                  SizedBox(
                    height: SizeConfig.size20,
                  ),
                  CommonTextField(
                    textEditController: emailTextController,
                    inputLength: AppConstants.inputCharterLimit50,
                    keyBoardType: TextInputType.emailAddress,
                    regularExpression: RegularExpressionUtils.emailPattern,
                    title: AppStrings.email,
                    hintText: AppStrings.emailHint,
                    isValidate: true,
                    validationType: ValidationTypeEnum.email,
                  ),
                  SizedBox(
                    height: SizeConfig.size28,
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: CustomBtn(
                          radius: 10,
                          onTap: () {
                            Get.offNamedUntil(
                              RouteHelper.getBottomNavigationBarScreenRoute(),
                              (route) => false,
                            );
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
                          onTap: isFormValid
                              ? () async {
                                  if (selectedType == ContactType.Mobile) {
                                    if (mobileController.length != 10) {
                                      commonSnackBar(
                                          message:
                                          AppStrings.pleaseEnterValidMobileNo);
                                      return;
                                    }
                                  }

                                  if (selectedType == ContactType.Landline) {
                                    if (landlineNumberController.text.length < 6 ||
                                        landlineNumberController.text.length > 8) {
                                      commonSnackBar(message:AppStrings.pleaseEnterValidLandline);
                                      return;
                                    }

                                  }


                                  /// Submit action
                                  Map<String, dynamic> reqParam = {
                                    ApiKeys.businessId: businessId,
                                    ApiKeys.office_mob_no_Pre: 91,
                                    "business_number": {
                                      "office_mob_no": mobileController.text.isNotEmpty
                                          ? {
                                        "pre": "91",
                                        "number": mobileController.text,
                                      }
                                          : null,
                                      "office_landline_no": landlineNumberController.text.isNotEmpty
                                          ? {
                                        "pre": landlineCodeController.text,
                                        "number": landlineNumberController.text,
                                      }
                                          : null,
                                    },

                                    ApiKeys.city_state_pincode:
                                        cityController.text,
                                    ApiKeys.address:
                                        fullBusinessAddressTextController.text,
                                    "business_location": jsonEncode({
                                      ApiKeys.lat: viewBusinessDetailsController
                                          .addressLat?.value
                                          .toString(),
                                      ApiKeys.lon: viewBusinessDetailsController
                                          .addressLong?.value
                                          .toString(),
                                    }),
                                    ApiKeys.pincode: picCodeController.text,
                                    ApiKeys.website_url: websiteController.text,
                                    ApiKeys.business_description:
                                        viewBusinessDetailsController
                                            .businessDescription.value,
                                    ApiKeys.owner_details: jsonEncode([
                                      {
                                        ApiKeys.name: nameTextController.text,
                                        ApiKeys.role_in_business:
                                            yourRoleController.text,
                                        ApiKeys.email: emailTextController.text
                                      }
                                    ]),
                                  };
                                  await viewBusinessDetailsController
                                      .updateBusinessDetails(reqParam);
                                  Get.offNamedUntil(
                                    RouteHelper
                                        .getBottomNavigationBarScreenRoute(),
                                    (route) => false,
                                  );
                                }
                              : null,
                          title: AppStrings.submit,
                          isValidate: isFormValid,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(
                    height: SizeConfig.size20,
                  ),
                ],
              ),
            ),
          ),
        ));
  }

  Widget _buildAddressField() {
    return Obx(() {
      if (locationController.isFetchingAddress.value) {
        return Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      }

      if (!locationController.fetchAddressFromGeo.value) {
        return Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: GestureDetector(
            onTap: () => updateAddressFromLocation(),
            child: CustomText(
              AppStrings.gpsLocationNotFound,
              fontSize: SizeConfig.small,
              fontWeight: FontWeight.w600,
              color: AppColors.red,
              decoration: TextDecoration.underline,
              decorationColor: AppColors.red,
            ),
          ),
        );
      }

      return SizedBox();
    });
  }
}
