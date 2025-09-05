import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/common_http_links_textfiled_widget.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/regular_expression.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/controller/location_controller.dart';
import 'package:BlueEra/core/routes/route_constant.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/business/visiting_card/view/widget/contact_number_widget.dart';
import 'package:BlueEra/features/common/auth/model/get_categories_model.dart';
import 'package:BlueEra/features/common/map/view/location_service.dart';
import 'package:BlueEra/l10n/app_localizations.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_circular_profile_image.dart';
import 'package:BlueEra/widgets/common_drop_down-dialoge.dart';
import 'package:BlueEra/widgets/common_drop_down.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:dio/dio.dart' as dioObj;
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/constants/snackbar_helper.dart';
import '../../../../widgets/new_common_date_selection_dropdown.dart';
import '../../../common/auth/views/widget/business_type_common_widget.dart';
import '../../auth/controller/view_business_details_controller.dart';
import '../../auth/model/viewBusinessProfileModel.dart';
import 'business_details_edit_page_two.dart';

class BusinessDetailsEditPageOne extends StatefulWidget {
  const BusinessDetailsEditPageOne({
    super.key,
    this.prevBusinessDetails,
    this.isFromCreateUser = false,
  });

  final bool isFromCreateUser;
  final BusinessProfileDetails? prevBusinessDetails;

  @override
  State<BusinessDetailsEditPageOne> createState() =>
      _BusinessDetailsEditPageOneState();
}

class _BusinessDetailsEditPageOneState
    extends State<BusinessDetailsEditPageOne> {
  final companyOrgNameTextController = TextEditingController();
  final locationTextController = TextEditingController();
  final landlineNumberController = TextEditingController();
  final landlineCodeController = TextEditingController();
  final mobileController = TextEditingController();
  final websiteController = TextEditingController();

  final fullBusinessAddressTextController = TextEditingController();
  final picCodeController = TextEditingController();
  final cityController = TextEditingController();

  final othersCatController = TextEditingController();
  // final landmarkController = TextEditingController();

  ContactType? selectedType = ContactType.Mobile;
  final viewBusinessDetailsController =
      Get.find<ViewBusinessDetailsController>();

  bool validate = false;
  SizeOfBusiness? selectedBusiness;

  final locationController = Get.put(LocationController());

  SizeOfBusiness? getBusinessFromString(String? input) {
    if (input == null) return null;

    return SizeOfBusiness.values.firstWhere(
      (e) => e.displayName.toLowerCase() == input.toLowerCase(),
      orElse: () => SizeOfBusiness.OTHERS,
    );
  }

  @override
  void initState() {
    super.initState();
    viewBusinessDetailsController.getAllCategories();

    final data = widget.prevBusinessDetails;

    if (data != null) {
      companyOrgNameTextController.text = data.businessName ?? '';

      selectedBusiness = getBusinessFromString(data.natureOfBusiness);
      websiteController.text = data.websiteUrl ?? '';
      cityController.text = data.cityStatePincode ?? '';
      fullBusinessAddressTextController.text = data.address ?? '';
      picCodeController.text = data.pincode !=null?data.pincode.toString():"";
      locationTextController.text = data.businessLocation != null
          ? '${data.businessLocation?.lat}, ${data.businessLocation?.lon}'
          : '';
      if (data.businessNumber?.officeMobNo?.number != null) {
        mobileController.text =
            data.businessNumber?.officeMobNo?.number.toString() ?? "";
      }
      if (data.businessNumber?.officeLandlineNo?.number != null) {
        landlineNumberController.text =
            data.businessNumber?.officeLandlineNo?.number.toString() ??
                ""; // Assuming not present in model
        landlineCodeController.text =
            data.businessNumber?.officeLandlineNo?.pre.toString() ?? "";
      }
      // Assuming not present in model
      othersCatController.text = data.natureOfBusiness ?? "";

      // landmarkController.text = data.natureOfBusiness ?? "";

      viewBusinessDetailsController.setStartLocation(
          widget.prevBusinessDetails?.businessLocation?.lat?.toDouble(),
          widget.prevBusinessDetails?.businessLocation?.lon?.toDouble(),
          widget.prevBusinessDetails?.address ?? "");

      if (data.businessNumber?.officeMobNo?.number != null) {
        selectedType = ContactType.Mobile;
      } else if (data.businessNumber?.officeLandlineNo?.number != null) {
        selectedType = ContactType.Landline;
      }

      if(fullBusinessAddressTextController.text.isEmpty &&
          cityController.text.isEmpty &&
          picCodeController.text.isEmpty
        ){
        WidgetsBinding.instance.addPostFrameCallback((_) {
          updateAddressFromLocation();
        });
      }

    }
  }

  Future<void> updateAddressFromLocation() async {
    final locationData = await locationController.checkPermissionAndSetData();
    if (locationData != null) {
      fullBusinessAddressTextController.text = locationData.fullAddress;
      cityController.text = locationData.city;
      picCodeController.text = locationData.pinCode;
    }
  }


  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return WillPopScope(
      onWillPop: () async {
        if (widget.isFromCreateUser) {
          Get.offNamedUntil(
            RouteHelper.getBottomNavigationBarScreenRoute(),
            (route) => false,
          );
        } else {
          Get.back();
        }
        return false;
      },
      child: Scaffold(
        appBar: CommonBackAppBar(
          isLeading: true,
          title: "Business Details (Step 1 of 2)",
          onBackTap: () {
            if (widget.isFromCreateUser) {
              Get.offNamedUntil(
                RouteHelper.getBottomNavigationBarScreenRoute(),
                (route) => false,
              );
            } else {
              Get.back();
            }
          },
        ),
        body: Obx(() {
          return SingleChildScrollView(
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
                    ///UPLOAD PROFILE....
                    Center(
                      child: CommonProfileImage(
                        imagePath:
                            viewBusinessDetailsController.imagePath?.value ??
                                "",
                        onImageUpdate: (image) {
                          viewBusinessDetailsController.imagePath?.value =
                              image;
                          viewBusinessDetailsController.isImageUpdated.value =
                              true;
                        }, dialogTitle:  'Upload Business Logo',
                      ),
                    ),

                    SizedBox(
                      height: SizeConfig.size20,
                    ),
                    Center(
                      child: CustomText(
                        appLocalizations?.businessLogo,
                        fontSize: SizeConfig.large,
                      ),
                    ),
                    Center(
                      child: CustomText(
                        appLocalizations?.youCanUpdateYourLogoAnytime,
                        fontSize: SizeConfig.small,
                        color: AppColors.grey80,
                      ),
                    ),
                    SizedBox(
                      height: SizeConfig.size30,
                    ),

                    CommonTextField(
                      textEditController: companyOrgNameTextController,
                      inputLength: AppConstants.inputCharterLimit50,
                      keyBoardType: TextInputType.text,
                      regularExpression:
                          RegularExpressionUtils.alphabetSpacePattern,
                      title: "Business Name",
                      hintText: AppConstants.companyOrgBusiness,
                      isValidate: false,
                    ),
                    SizedBox(
                      height: SizeConfig.size20,
                    ),

                    CustomText(
                      appLocalizations?.dateOfIncorporation,
                      fontSize: SizeConfig.medium,
                      fontWeight: FontWeight.w500,
                      color: AppColors.black,
                    ),
                    SizedBox(
                      height: SizeConfig.size10,
                    ),
                    NewDatePicker(
                      selectedDay:
                          viewBusinessDetailsController.selectDay?.value,
                      selectedMonth:
                          viewBusinessDetailsController.selectMonth?.value,
                      selectedYear:
                          viewBusinessDetailsController.selectYear?.value,
                      onDayChanged: (value) {
                        viewBusinessDetailsController.selectDay?.value =
                            value ?? 0;
                      },
                      onMonthChanged: (value) {
                        viewBusinessDetailsController.selectMonth?.value =
                            value ?? 0;
                      },
                      onYearChanged: (value) {
                        viewBusinessDetailsController.selectYear?.value =
                            value ?? 0;
                      },
                    ),
                    SizedBox(
                      height: SizeConfig.size20,
                    ),

                    ///SELECT BUSINESS CARD TYPE....

                    CustomText(
                      "Type of the Business",
                      fontSize: SizeConfig.medium,
                      fontWeight: FontWeight.w500,
                      color: AppColors.black,
                    ),
                    SizedBox(
                      height: SizeConfig.size14,
                    ),
                    Obx(() {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          BusinessTypeCard(
                            type: BusinessType.Product,
                            icon: AppIconAssets.store,
                            title: appLocalizations?.shopStore ?? "",
                            subtitle: appLocalizations?.egClothesFood ?? "",
                            selectedType: viewBusinessDetailsController
                                    .selectedBusinessType?.value ??
                                BusinessType.Both,
                            onSelect: (type) {
                              viewBusinessDetailsController
                                  .selectedCategoryOfBusiness.value = null;
                              viewBusinessDetailsController
                                  .selectedSubCategoryOfBusinessNew
                                  .value = null;
                              viewBusinessDetailsController
                                  .businessSubCategoriesList
                                  .clear();
                              viewBusinessDetailsController
                                  .selectedBusinessType?.value = type;
                            },
                          ),
                          SizedBox(width: SizeConfig.size20),
                          BusinessTypeCard(
                            type: BusinessType.Service,
                            icon: AppIconAssets.service,
                            title: appLocalizations?.provideServices ?? "",
                            subtitle: appLocalizations?.egDoctorTutor ?? "",
                            selectedType: viewBusinessDetailsController
                                    .selectedBusinessType?.value ??
                                BusinessType.Both,
                            onSelect: (type) {
                              viewBusinessDetailsController
                                  .selectedCategoryOfBusiness.value = null;
                              viewBusinessDetailsController
                                  .selectedSubCategoryOfBusinessNew
                                  .value = null;
                              viewBusinessDetailsController
                                  .businessSubCategoriesList
                                  .clear();
                              viewBusinessDetailsController
                                  .selectedBusinessType?.value = type;
                            },
                          ),
                          SizedBox(width: SizeConfig.size20),
                          BusinessTypeCard(
                            type: BusinessType.Both,
                            icon: AppIconAssets.store_service,
                            title: "Other" ?? "",
                            subtitle: appLocalizations?.egBikeShowroom ?? "",
                            selectedType: viewBusinessDetailsController
                                    .selectedBusinessType?.value ??
                                BusinessType.Both,
                            onSelect: (type) {
                              viewBusinessDetailsController
                                  .selectedCategoryOfBusiness.value = null;
                              viewBusinessDetailsController
                                  .selectedSubCategoryOfBusinessNew
                                  .value = null;
                              viewBusinessDetailsController
                                  .businessSubCategoriesList
                                  .clear();
                              viewBusinessDetailsController
                                  .selectedBusinessType?.value = type;
                            },
                          ),
                        ],
                      );
                    }),
                    SizedBox(
                      height: SizeConfig.size12,
                    ),

                    // Center(
                    //   child: CustomText(
                    //     appLocalizations?.businessDetails,
                    //     fontSize: SizeConfig.large,
                    //     fontWeight: FontWeight.w600,
                    //   ),
                    // ),
                    SizedBox(
                      height: SizeConfig.size20,
                    ),

                    ///ENTER ORG/COMPANY NAME...

                    ///Supply chain...

                    CustomText(
                      'Nature of the Business',
                      fontSize: SizeConfig.medium,
                      fontWeight: FontWeight.w500,
                      color: AppColors.black,
                    ),
                    SizedBox(
                      height: SizeConfig.size10,
                    ),
                    CommonDropdownDialog<SizeOfBusiness>(
                      items: SizeOfBusiness.values,
                      selectedValue: selectedBusiness,
                      title: 'Nature of the Business',
                      hintText: "Enter Category (if Others)",
                      displayValue: (profession) => profession.displayName,
                      onChanged: (value) {
                        setState(() {
                          selectedBusiness = value;
                        });
                      },
                    ),
                    /*CommonDropdown<SizeOfBusiness>(
                      items: SizeOfBusiness.values,
                      selectedValue: selectedBusiness,
                      hintText: "Enter Category (if Others)",
                      displayValue: (profession) => profession.displayName,
                      onChanged: (value) {
                        setState(() {
                          selectedBusiness = value;
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return appLocalizations?.selectBusinessCategory;
                        }
                        return null;
                      },
                    ),*/

                    (selectedBusiness == SizeOfBusiness.OTHERS)
                        ? SizedBox(
                            height: SizeConfig.size10,
                          )
                        : SizedBox(),
                    (selectedBusiness == SizeOfBusiness.OTHERS)
                        ? CommonTextField(
                            textEditController: othersCatController,
                            inputLength: AppConstants.inputCharterLimit50,
                            keyBoardType: TextInputType.text,
                            regularExpression:
                                RegularExpressionUtils.alphabetSpacePattern,
                            hintText: appLocalizations?.eGMedicalShopKiranaShop,
                            isValidate: false,
                          )
                        : SizedBox(),

                    SizedBox(
                      height: SizeConfig.size20,
                    ),

                    ///Mobile number

                    ContactInputField(
                      mobileController: mobileController,
                      landlineCodeController: landlineCodeController,
                      landlineNumberController: landlineNumberController,
                      selectedType: selectedType ?? ContactType.Mobile,
                      onTypeChanged: (type) {
                        setState(() {
                          selectedType = type;
                        });
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

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CommonTextField(
                          readOnly: true,
                          maxLine: 3,
                          textEditController: fullBusinessAddressTextController,
                          inputLength: AppConstants.inputCharterLimit50,
                          keyBoardType: TextInputType.text,
                          title: appLocalizations?.fullBusinessAddress,
                          regularExpression: RegularExpressionUtils.alphabetSpacePattern,
                          hintText: appLocalizations?.fullBusinessAddress,
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

                    ///ENTER NAME CONTROLLER......
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

                    Row(
                      children: [
                        Expanded(
                          child: CustomBtn(
                            radius: 10,
                            onTap: () {
                              Navigator.of(context).pop();
                            },
                            title: appLocalizations?.cancel,
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
                            bgColor: AppColors.primaryColor,
                            onTap: () async {

                              if (companyOrgNameTextController
                                  .text.isNotEmpty) {
                                if ((viewBusinessDetailsController
                                            .addressLat?.value !=
                                        0.0) &&
                                    (viewBusinessDetailsController
                                            .addressLong?.value !=
                                        0.0)) {
                                  if (picCodeController.text.isNotEmpty) {
                                    navigatePushTo(
                                        context,
                                        BusinessDetailsEditPageTwo(
                                          paramsMap:
                                              await buildBusinessDetailsPayload(),
                                          prevBusinessDetails:
                                              widget.prevBusinessDetails,
                                          isFromCreateUser:
                                              widget.isFromCreateUser,
                                        ));
                                  }
                                  else{
                                    commonSnackBar(
                                        message: "Please Enter Pin Code");

                                  }
                                } else {
                                  commonSnackBar(
                                      message: "Please Enter address");
                                }
                              } else {
                                commonSnackBar(
                                    message: "Please Enter Required Field");
                              }
                            },
                            title: "Next",
                            isValidate: validate,
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
          );
        }),
      ),
    );
  }

  Future<Map<String, dynamic>> buildBusinessDetailsPayload() async {
    dioObj.MultipartFile? imageByPart;
    if (viewBusinessDetailsController.isImageUpdated.value) {
      if (viewBusinessDetailsController.imagePath?.value.isNotEmpty ?? false) {
        String fileName =
            viewBusinessDetailsController.imagePath?.value.split('/').last ??
                "";
        imageByPart = await dioObj.MultipartFile.fromFile(
            viewBusinessDetailsController.imagePath?.value ?? "",
            filename: fileName);
      }
    }

    return {
      ApiKeys.businessId: businessId,
      ApiKeys.business_name: companyOrgNameTextController.text,
      ApiKeys.date_of_incorporation: {
        ApiKeys.date: viewBusinessDetailsController.selectDay?.value,
        ApiKeys.month: viewBusinessDetailsController.selectMonth?.value,
        ApiKeys.year: viewBusinessDetailsController.selectYear?.value
      },
      ApiKeys.type_of_business:
          viewBusinessDetailsController.selectedBusinessType?.value.name ?? '',
      ApiKeys.office_mob_no_Pre: 91,
      if (mobileController.text.isNotEmpty)
        ApiKeys.office_mob_no_number: mobileController.text,
      if (landlineCodeController.text.isNotEmpty)
        ApiKeys.office_landline_no_pre: landlineCodeController.text,
      if (landlineNumberController.text.isNotEmpty)
        ApiKeys.office_landline_no_number: landlineNumberController.text,
      ApiKeys.Nature_of_Business: selectedBusiness == SizeOfBusiness.OTHERS
          ? othersCatController.text
          : selectedBusiness?.displayName ?? '',
      ApiKeys.city_state_pincode: cityController.text,
      ApiKeys.address: viewBusinessDetailsController.businessAddress.value,
      ApiKeys.lat: viewBusinessDetailsController.addressLat?.value.toString(),
      ApiKeys.lon: viewBusinessDetailsController.addressLong?.value.toString(),
      ApiKeys.pincode: picCodeController.text,
      ApiKeys.website_url: websiteController.text,
      ApiKeys.logo_image: viewBusinessDetailsController.isImageUpdated.value
          ? imageByPart
          : null,
    };
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
            onTap: () =>  updateAddressFromLocation(),
            child: CustomText(
              'GPS location not found (Tap to fetch)',
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
