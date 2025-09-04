import 'dart:convert';
import 'dart:developer';
import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/model/geo_coding_response.dart';
import 'package:BlueEra/core/common_bloc/place/repo/place_repo.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/common_http_links_textfiled_widget.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/regular_expression.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/features/business/visiting_card/view/widget/contact_number_widget.dart';
import 'package:BlueEra/features/common/map/view/location_service.dart';
import 'package:BlueEra/l10n/app_localizations.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pinput/pinput.dart';

import '../../../../../core/services/location_permission_handler.dart';

class CreateBusinessAccountStepTwo extends StatefulWidget {
  const CreateBusinessAccountStepTwo({super.key});

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
  final businessDescriptionController = TextEditingController();
  final landmarkController = TextEditingController();

  ContactType? selectedType = ContactType.Mobile;

  final viewBusinessDetailsController =
      Get.put(ViewBusinessDetailsController());
  bool isFormValid = false;

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
    businessDescriptionController.addListener(_validateForm);
    picCodeController.addListener(_validateForm);
    landmarkController.addListener(_validateForm);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      checkPermissionAndSetData(context);
    });

  }


  Future<void> checkPermissionAndSetData(BuildContext context) async {
    final locationResult = await LocationPermissionHandler.getCurrentLocation();

    if (locationResult.isSuccess && locationResult.position != null) {
      final pos = locationResult.position!;
      log("📍 lat: ${pos.latitude}, lng: ${pos.longitude}");
      getAddressDetails(position: pos);
    } else {
      log("❌ Location error: ${locationResult.message}");
      // Handle error UI (e.g., show snackbar or dialog)
    }
  }


  void _validateForm() {
    setState(() {
      // Common validation
      bool commonValid = cityController.text.trim().isNotEmpty &&
          fullBusinessAddressTextController.text.trim().isNotEmpty &&
          nameTextController.text.trim().isNotEmpty &&
          yourRoleController.text.trim().isNotEmpty &&
          businessDescriptionController.text.trim().isNotEmpty &&
          picCodeController.text.trim().isNotEmpty &&
          emailTextController.text.trim().isNotEmpty;

      // Type-specific validation
      if (selectedType == ContactType.Mobile) {
        isFormValid = commonValid && mobileController.text.trim().isNotEmpty;
      } else if (selectedType == ContactType.Landline) {
        isFormValid = commonValid &&
            landlineCodeController.text.trim().isNotEmpty &&
            landlineNumberController.text.trim().isNotEmpty;
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
    businessDescriptionController.dispose();
    picCodeController.dispose();
    landmarkController.dispose();
    super.dispose();
  }


  Future<void> getAddressDetails({required Position position}) async {

    try {
      final responseModel = await PlaceRepo().getGeoCode(position: position);

      if (responseModel.isSuccess) {
        final data = GeocodingResponse.fromJson(responseModel.response?.data);

        final result = data.results.first;

        fullBusinessAddressTextController.text = result.formattedAddress;

        // City
        cityController.text = result.addressComponents
            .firstWhere(
              (c) => c.types.contains('locality'),
          orElse: () => AddressComponent(longName: '', shortName: '', types: []),
        )
            .longName;

        // Pincode
        picCodeController.text = result.addressComponents
            .firstWhere(
              (c) => c.types.contains('postal_code'),
          orElse: () => AddressComponent(longName: '', shortName: '', types: []),
        )
            .longName;

        print("full address: ${fullBusinessAddressTextController.text}, city: ${cityController.text}, PinCode: ${picCodeController.text}");
        setState(() {});

      } else {
        // setState(() {
        //   errorMessage =
        //       responseModel.data['error_message'] ?? 'Something went wrong';
        //   isLoading = false;
        // });
      }
    } catch (e) {
      if(!mounted) return;
      // setState(() {
      //   errorMessage = e.toString();
      //   isLoading = false;
      // });
    }
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context);
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

                  ContactInputField(
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
                    appLocalizations?.websiteOptional,
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


                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      CustomText(
                        appLocalizations?.fullBusinessAddress,
                        fontSize: SizeConfig.medium,
                        fontWeight: FontWeight.w500,
                        color: AppColors.black,
                      ),
                      SizedBox(width: SizeConfig.size8),

                      if(fullBusinessAddressTextController.text.isEmpty)
                      IconButton(
                          icon: LocalAssets(imagePath: AppIconAssets.currentLocationIcon),
                          onPressed: ()=> checkPermissionAndSetData(context)
                      ),
                    ],
                  ),


                  CommonTextField(
                    readOnly: true,
                    maxLine: 3,
                    textEditController: fullBusinessAddressTextController,
                    inputLength: AppConstants.inputCharterLimit50,
                    keyBoardType: TextInputType.text,
                    regularExpression: RegularExpressionUtils.alphabetSpacePattern,
                    hintText: appLocalizations?.fullBusinessAddress,
                    isValidate: false,
                  ),

                  SizedBox(
                    height: SizeConfig.size20,
                  ),

                  ///ENTER Landmark ......
                  CommonTextField(
                    textEditController: landmarkController,
                    inputLength: AppConstants.inputCharterLimit200,
                    keyBoardType: TextInputType.text,
                    regularExpression:
                    RegularExpressionUtils.alphabetSpacePattern,
                    title: 'Floor / Building Name / Landmark',
                    hintText: 'Floor / Building Name / Landmark',
                    isValidate: false,
                  ),
                  SizedBox(
                    height: SizeConfig.size20,
                  ),

                  ///ENTER CITY NAME ......
                  CommonTextField(
                    textEditController: cityController,
                    inputLength: AppConstants.inputCharterLimit50,
                    keyBoardType: TextInputType.text,
                    regularExpression:
                        RegularExpressionUtils.alphabetSpacePattern,
                    title: appLocalizations?.city,
                    hintText: appLocalizations?.city,
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
                    title: "Pin Code",
                    hintText: "345434",
                    isValidate: true,
                    readOnly: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Please enter Pin Code";
                      } else if (!RegExp(RegularExpressionUtils.pinCodeRegExp)
                          .hasMatch(value)) {
                        return "Enter valid 6-digit Indian Pin Code";
                      }
                      return null;
                    },
                  ),
                  SizedBox(
                    height: SizeConfig.size28,
                  ),

                  CommonTextField(
                    textEditController: businessDescriptionController,
                    inputLength: AppConstants.inputCharterLimit200,
                    keyBoardType: TextInputType.text,
                    regularExpression:
                        RegularExpressionUtils.alphabetSpacePatternDigitSpace,
                    title: "Short Business Description",
                    hintText:
                        "Eg., Visit our store for casual and traditional wear...",
                    isValidate: false,
                    maxLine: 5,
                  ),
                  SizedBox(height: SizeConfig.size10),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: CustomText(
                      "${businessDescriptionController.text.length}/${AppConstants.inputCharterLimit200}",
                      color: AppColors.grey9B,
                      fontSize: SizeConfig.small,
                    ),
                  ),
                  SizedBox(
                    height: SizeConfig.size28,
                  ),
                  Center(
                    child: CustomText(
                      "Owner Details",
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
                    title: "Your Name",
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
                    title: appLocalizations?.yourRoleInTheBusiness,
                    hintText: appLocalizations?.coFounderOwner,
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
                    title: appLocalizations?.email,
                    hintText: appLocalizations?.email,
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
                          title: appLocalizations?.skip,
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
                                              "Please enter your valid mobile number");
                                      return;
                                    }
                                  }

                                  if (selectedType == ContactType.Landline) {
                                    if (landlineNumberController.length <= 6 && landlineNumberController.length >= 8) {
                                      commonSnackBar(
                                          message:
                                              "Please enter your valid landline number");
                                      return;
                                    }
                                  }

                                  /// Submit action
                                  print("Form submitted!");
                                  Map<String, dynamic> reqParam = {
                                    ApiKeys.businessId: businessId,
                                    ApiKeys.office_mob_no_Pre: 91,
                                    if (mobileController.text.isNotEmpty)
                                      ApiKeys.office_mob_no_number:
                                          mobileController.text,
                                    if (landlineCodeController.text.isNotEmpty)
                                      ApiKeys.office_landline_no_pre:
                                          landlineCodeController.text,
                                    if (landlineNumberController
                                        .text.isNotEmpty)
                                      ApiKeys.office_landline_no_number:
                                          landlineNumberController.text,
                                    ApiKeys.city_state_pincode:
                                        cityController.text,
                                    ApiKeys.address:
                                        viewBusinessDetailsController
                                            .businessAddress.value,
                                    ApiKeys.lat: viewBusinessDetailsController
                                        .addressLat?.value
                                        .toString(),
                                    ApiKeys.lon: viewBusinessDetailsController
                                        .addressLong?.value
                                        .toString(),
                                    ApiKeys.pincode: picCodeController.text,
                                    ApiKeys.website_url: websiteController.text,
                                    ApiKeys.business_description:
                                        businessDescriptionController.text,
                                    ApiKeys.owner_details: jsonEncode([
                                      {
                                        ApiKeys.name: nameTextController.text,
                                        ApiKeys.role_in_business:
                                            yourRoleController.text,
                                        ApiKeys.email: emailTextController.text
                                      }
                                    ]),
                                  };
                                  logs("reqParam === $reqParam");
                                  await viewBusinessDetailsController
                                         .updateBusinessDetails(reqParam);
                                     Get.offNamedUntil(
                                       RouteHelper.getBottomNavigationBarScreenRoute(),
                                           (route) => false,
                                     );
                                }
                              : null,
                          title: "Submit",
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
}
