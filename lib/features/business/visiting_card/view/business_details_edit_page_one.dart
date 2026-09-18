import 'dart:convert';

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_http_links_textfiled_widget.dart';
import 'package:BlueEra/core/constants/no_leading_space_formatter.dart';
import 'package:BlueEra/core/constants/regular_expression.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/controller/location_controller.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/business/visiting_card/view/widget/contact_number_widget.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../../core/constants/snackbar_helper.dart';
import '../../../../widgets/new_common_date_selection_dropdown.dart';
import '../../auth/controller/view_business_details_controller.dart';
import '../../auth/model/viewBusinessProfileModel.dart';

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

  /// Branch / outlet label. Editable here precisely because the business NAME
  /// is not: for a GST-registered business the server owns the name (it is
  /// overwritten from the GST record) while the branch belongs to the user, and
  /// a PUT carrying `branch` alone renames it without re-verifying the GSTIN.
  /// See docs/finance-gst-branch-ui-integration.md §2/§6.
  final branchTextController = TextEditingController();

  /// The branch as it arrived, so the PUT can send the field only when it
  /// actually changed — §6 is a PARTIAL update, and re-sending an unchanged
  /// branch asks the server to re-run the duplicate check for nothing.
  String _initialBranch = '';

  /// Only a GST-registered business carries a branch. Without a GSTIN there is
  /// no (GST + branch) pair to disambiguate, and the name is already editable
  /// above, so the field would be noise.
  bool _hasGstBranch = false;

  /// Whether the typed branch differs from the one that arrived.
  ///
  /// Compared the way the BACKEND compares branches — case-insensitive, with
  /// runs of whitespace collapsed (§4: `"Andheri West"`, `"andheri west"` and
  /// `"Andheri  West"` are the same branch). So re-casing alone is not an edit
  /// and will not trigger a duplicate check; a real rename still will.
  bool get _branchChanged =>
      _normalizeBranch(branchTextController.text) !=
      _normalizeBranch(_initialBranch);

  static String _normalizeBranch(String raw) =>
      raw.trim().toUpperCase().replaceAll(RegExp(r'\s+'), ' ');
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
  NatureOfBusiness? selectedBusiness;
  final _formKey = GlobalKey<FormState>();

  final locationController = Get.put(LocationController());

  NatureOfBusiness? getBusinessFromString(String? input) {
    if (input == null) return null;

    return NatureOfBusiness.values.firstWhere(
          (e) => e.displayName.toLowerCase() == input.toLowerCase(),
      orElse: () => NatureOfBusiness.OTHERS,
    );
  }

  @override
  void initState() {
    super.initState();
    viewBusinessDetailsController.getAllCategories();

    final data = widget.prevBusinessDetails;


    if (data != null) {
      companyOrgNameTextController.text = data.businessName ?? '';

      _initialBranch = (data.branch ?? '').trim();
      branchTextController.text = _initialBranch;
      // `gst.number` is `dynamic` on the model — a profile with no GST can
      // carry null, "" or a missing key, so normalise before deciding.
      _hasGstBranch = (data.gst?.number ?? '').toString().trim().isNotEmpty;

      selectedBusiness = getBusinessFromString(data.natureOfBusiness);
      websiteController.text = data.websiteUrl ?? '';
      cityController.text = data.cityStatePincode ?? '';
      fullBusinessAddressTextController.text = data.address ?? '';
      picCodeController.text =
      data.pincode != null ? data.pincode.toString() : "";
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
            data.businessNumber?.officeLandlineNo?.number.toString() ?? "";
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

      if (fullBusinessAddressTextController.text.isEmpty &&
          cityController.text.isEmpty &&
          picCodeController.text.isEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          updateAddressFromLocation();
        });
      } else {
        locationController.fetchAddressFromGeo.value = true;
      }
    }
  }

  /// Every controller on this page is created here and owned here, so every one
  /// is disposed here. Each holds a `ChangeNotifier` that the text fields
  /// subscribe to; without this they outlive the route, and this form is opened
  /// and closed repeatedly from the profile screen.
  ///
  /// Safe against a read-after-dispose despite the Save handler being async:
  /// `buildBusinessDetailsPayload()` is declared `async` but contains no live
  /// `await` (the only one is commented out), so it resolves in a microtask and
  /// every `controller.text` read happens before the one real suspension point
  /// — the update request itself. Keep it that way: an `await` added inside
  /// that builder would open a window where the user can pop the route and the
  /// reads land on disposed controllers.
  @override
  void dispose() {
    companyOrgNameTextController.dispose();
    branchTextController.dispose();
    locationTextController.dispose();
    landlineNumberController.dispose();
    landlineCodeController.dispose();
    mobileController.dispose();
    websiteController.dispose();
    fullBusinessAddressTextController.dispose();
    picCodeController.dispose();
    cityController.dispose();
    othersCatController.dispose();
    super.dispose();
  }

  Future<void> updateAddressFromLocation() async {
    final locationData = await locationController.checkPermissionAndSetData();
    if (locationData != null) {
      fullBusinessAddressTextController.text = locationData.fullAddress;
      cityController.text = locationData.city;
      picCodeController.text = locationData.pinCode;
      viewBusinessDetailsController.addressLong?.value =
          double.parse(locationData.long);
      viewBusinessDetailsController.addressLat?.value =
          double.parse(locationData.lat);
    }
  }


  @override
  Widget build(BuildContext context) {
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
          title: AppStrings.businessDetailsUpdate,
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
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // ///UPLOAD PROFILE....
                      // Center(
                      //   child: CommonProfileImage(
                      //     imagePath:
                      //     viewBusinessDetailsController.imagePath?.value ??
                      //         "",
                      //     onImageUpdate: (image) {
                      //       viewBusinessDetailsController.imagePath?.value =
                      //           image;
                      //       viewBusinessDetailsController.isImageUpdated.value =
                      //       true;
                      //     },
                      //     dialogTitle: 'Upload Business Logo',
                      //   ),
                      // ),
                      //
                      // SizedBox(
                      //   height: SizeConfig.size20,
                      // ),
                      // Center(
                      //   child: CustomText(
                      //     appLocalizations?.businessLogo,
                      //     fontSize: SizeConfig.large,
                      //   ),
                      // ),
                      // Center(
                      //   child: CustomText(
                      //     appLocalizations?.youCanUpdateYourLogoAnytime,
                      //     fontSize: SizeConfig.small,
                      //     color: AppColors.grey80,
                      //   ),
                      // ),
                      // SizedBox(
                      //   height: SizeConfig.size30,
                      // ),

                      CommonTextField(
                        textEditController: companyOrgNameTextController,
                        inputLength: AppConstants.inputCharterLimit30,
                        keyBoardType: TextInputType.text,

                        regularExpression:
                        RegularExpressionUtils.alphabetSpacePattern,
                        title:AppStrings.businessName,
                        hintText: AppConstants.companyOrgBusiness,
                        isValidate: false,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return AppStrings.businessNameRequired.tr;
                          }
                          if (value.trim().length < 6) {
                            return AppStrings.min6Characters.tr;
                          }
                          if (value.trim().length > 30) {
                            return AppStrings.max30Characters.tr;
                          }
                          return null;
                        },
                      ),
                      SizedBox(
                        height: SizeConfig.size20,
                      ),

                      /// BRANCH — GST businesses only.
                      ///
                      /// The one part of a GST listing's identity the owner is
                      /// allowed to correct. Before this it was write-once at
                      /// signup: a branch typed wrong stayed wrong forever,
                      /// even though the backend has supported renaming it on
                      /// its own since §6 of the integration guide.
                      if (_hasGstBranch) ...[
                        CommonTextField(
                          textEditController: branchTextController,
                          maxLength:
                              ValidationMethod.brandOrBranchNameMaxLength,
                          isCounterVisible: true,
                          keyBoardType: TextInputType.text,
                          textInputAction: TextInputAction.next,
                          title: AppStrings.brandOrBranchName,
                          hintText: AppStrings.brandOrBranchNameHint,
                          // Same formatter set as signup — passing
                          // `inputFormatters` REPLACES the widget's defaults,
                          // so the space rules are re-stated here.
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(
                                RegularExpressionUtils
                                    .brandOrBranchNamePattern)),
                            NoLeadingSpaceFormatter(),
                            NoConsecutiveSpacesFormatter(),
                            LengthLimitingTextInputFormatter(
                                ValidationMethod.brandOrBranchNameMaxLength),
                          ],
                          validator:
                              ValidationMethod.validateBrandOrBranchName,
                        ),
                        CustomText(
                          AppStrings.brandOrBranchNameHelper,
                          fontSize: SizeConfig.small,
                          color: AppColors.grey9B,
                        ),
                        SizedBox(
                          height: SizeConfig.size20,
                        ),
                      ],

                      CustomText(
                        AppStrings.dateOfIncorporation,
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

                      // CustomText(
                      //   "Type of the Business",
                      //   fontSize: SizeConfig.medium,
                      //   fontWeight: FontWeight.w500,
                      //   color: AppColors.black,
                      // ),
                      // SizedBox(
                      //   height: SizeConfig.size14,
                      // ),
                                 /*     Obx(() {
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
                      }),*/
                      // Obx(() {
                      //   return CommonDropdownIconDialog<BusinessCategory>(
                      //     items: typeOfBusinessList,
                      //     selectedValue: viewBusinessDetailsController
                      //         .selectedTypeOfBusiness.value,
                      //     hintText:
                      //     appLocalizations?.selectNatureOfTheBusiness ?? "",
                      //     displayValue: (profession) => profession.title,
                      //     title: appLocalizations?.natureOfBusiness ??
                      //         "Nature of the Business",
                      //     onChanged: (value) {
                      //       viewBusinessDetailsController.selectedTypeOfBusiness
                      //           .value = value!;
                      //       if(value.type==BusinessType.Product.name)
                      //         {
                      //           viewBusinessDetailsController.selectedBusinessType?.value=BusinessType.Product;
                      //
                      //         }
                      //       else if(value.type==BusinessType.Service.name)
                      //         {
                      //           viewBusinessDetailsController.selectedBusinessType?.value=BusinessType.Service;
                      //
                      //         }
                      //       else if(value.type==BusinessType.Food.name)
                      //         {
                      //           viewBusinessDetailsController.selectedBusinessType?.value=BusinessType.Food;
                      //
                      //         }
                      //       else{
                      //         viewBusinessDetailsController.selectedBusinessType?.value=BusinessType.Both;
                      //
                      //       }
                      //       viewBusinessDetailsController
                      //           .selectedCategoryOfBusiness.value = null;
                      //       viewBusinessDetailsController
                      //           .selectedSubCategoryOfBusinessNew
                      //           .value = null;
                      //       viewBusinessDetailsController
                      //           .businessSubCategoriesList
                      //           .clear();
                      //
                      //     },
                      //     displayValueSubTitle: (profession) =>
                      //     profession.subTitle,
                      //     displayValueImagePath: (profession) => profession.icon,
                      //   );
                      // }),
                      // SizedBox(
                      //   height: SizeConfig.size12,
                      // ),

                      // Center(
                      //   child: CustomText(
                      //     appLocalizations?.businessDetails,
                      //     fontSize: SizeConfig.large,
                      //     fontWeight: FontWeight.w600,
                      //   ),
                      // ),

                      ///ENTER ORG/COMPANY NAME...

                      ///Supply chain...
                     /* if (viewBusinessDetailsController. selectedTypeOfBusiness.value.type ==
                          BusinessType.Product.name)...[
                        // SizedBox(
                        //   height: SizeConfig.size20,
                        // ),

                        // CustomText(
                        //   'Nature of the Business',
                        //   fontSize: SizeConfig.medium,
                        //   fontWeight: FontWeight.w500,
                        //   color: AppColors.black,
                        // ),
                        // SizedBox(
                        //   height: SizeConfig.size10,
                        // ),
                        // CommonDropdownDialog<SizeOfBusiness>(
                        //   items: SizeOfBusiness.values,
                        //   selectedValue: selectedBusiness,
                        //   title: 'Nature of the Business',
                        //   hintText: "Enter Category (if Others)",
                        //   displayValue: (profession) => profession.displayName,
                        //   onChanged: (value) {
                        //     setState(() {
                        //       selectedBusiness = value;
                        //     });
                        //
                        //   },
                        // ),


                        // (selectedBusiness == SizeOfBusiness.OTHERS)
                        //     ? SizedBox(
                        //   height: SizeConfig.size10,
                        // )
                        //     : SizedBox(),
                        // (selectedBusiness == SizeOfBusiness.OTHERS)
                        //     ? CommonTextField(
                        //   textEditController: othersCatController,
                        //   inputLength: AppConstants.inputCharterLimit50,
                        //   keyBoardType: TextInputType.text,
                        //   regularExpression:
                        //   RegularExpressionUtils.alphabetSpacePattern,
                        //   hintText: appLocalizations?.eGMedicalShopKiranaShop,
                        //   isValidate: true,
                        //   validator: (value) {
                        //     if (value == null || value.trim().isEmpty) {
                        //       return "Mobile Number is required";
                        //     }
                        //
                        //
                        //     return null;
                        //   },
                        // )
                        //     : SizedBox(),

                        // SizedBox(
                        //   height: SizeConfig.size20,
                        // ),
                      ],*/


                      ///Mobile number
                      CustomText(
                        AppStrings.phoneNumber,
                        fontSize: SizeConfig.medium,
                        fontWeight: FontWeight.w500,
                        color: AppColors.black,
                      ),
                      SizedBox(
                        height: SizeConfig.size10,
                      ),
                      ContactInputField1(
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
                      // SizedBox(
                      //   height: SizeConfig.size20,
                      // ),

                      ///websiteOptional


                      SizedBox(
                        height: SizeConfig.size20,
                      ),
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
                        isUrlValidate: true,
                        hintText: AppStrings.httpsExampleCom,
                      ),
                      SizedBox(
                        height: SizeConfig.size20,
                      ),

                      // Column(
                      //   crossAxisAlignment: CrossAxisAlignment.start,
                      //   children: [
                      //     CommonTextField(
                      //      // readOnly: true,
                      //       maxLine: 3,
                      //       textEditController: fullBusinessAddressTextController,
                      //       inputLength: AppConstants.inputCharterLimit50,
                      //       keyBoardType: TextInputType.text,
                      //       title: appLocalizations?.fullBusinessAddress,
                      //       regularExpression:
                      //       RegularExpressionUtils.alphabetSpacePattern,
                      //       hintText: appLocalizations?.fullBusinessAddress,
                      //       //isValidate: false,
                      //     ),
                      //
                      //     _buildAddressField()
                      //   ],
                      // ),
                      // SizedBox(
                      //   height: SizeConfig.size20,
                      // ),

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
                      // CommonTextField(
                      //   textEditController: cityController,
                      //   inputLength: AppConstants.inputCharterLimit50,
                      //   keyBoardType: TextInputType.text,
                      //   regularExpression:
                      //   RegularExpressionUtils.alphabetSpacePattern,
                      //   title: appLocalizations?.city,
                      //   hintText: appLocalizations?.city,
                      //   isValidate: false,
                      //   readOnly: true,
                      // ),
                      // SizedBox(
                      //   height: SizeConfig.size20,
                      // ),
                      //
                      // ///ENTER PIN CODE NAME ......
                      // CommonTextField(
                      //   textEditController: picCodeController,
                      //   inputLength: AppConstants.inputCharterLimit6,
                      //   keyBoardType: TextInputType.number,
                      //   regularExpression: RegularExpressionUtils.digitsPattern,
                      //   title: "Pin Code",
                      //   hintText: "345434",
                      //   isValidate: true,
                      //   readOnly: true,
                      //   validator: (value) {
                      //     if (value == null || value.isEmpty) {
                      //       return "Please enter Pin Code";
                      //     } else if (!RegExp(RegularExpressionUtils.pinCodeRegExp)
                      //         .hasMatch(value)) {
                      //       return "Enter valid 6-digit Indian Pin Code";
                      //     }
                      //     return null;
                      //   },
                      // ),

                      SizedBox(
                        height: SizeConfig.size28,
                      ),

                      // Row(
                      //   children: [
                      //     Expanded(
                      //       child: CustomBtn(
                      //         radius: 10,
                      //         onTap: () {
                      //           Navigator.of(context).pop();
                      //         },
                      //         title: appLocalizations?.cancel,
                      //         bgColor: Colors.transparent,
                      //         textColor: AppColors.primaryColor,
                      //         borderColor: AppColors.primaryColor,
                      //       ),
                      //     ),
                      //     SizedBox(
                      //       width: SizeConfig.size10,
                      //     ),
                      //     Expanded(
                      //       child: CustomBtn(
                      //         radius: 10,
                      //         bgColor: AppColors.primaryColor,
                      //         onTap: () async {
                      //           if ((_formKey.currentState?.validate() ?? false) == false) {
                      //             commonSnackBar(message: "Please fix errors before saving");
                      //             return;
                      //           }
                      //           if (mobileController.text.isEmpty) {
                      //             commonSnackBar(message: "Please Enter Mobile Number");
                      //             return;
                      //           }
                      //
                      //           /// Validate Business Name
                      //           if (companyOrgNameTextController.text.isEmpty) {
                      //             commonSnackBar(message: "Please Enter Business Name");
                      //             return;
                      //           }
                      //
                      //           /// Validate Address Lat/Long
                      //           // if ((viewBusinessDetailsController.addressLat?.value == 0.0) ||
                      //           //     (viewBusinessDetailsController.addressLong?.value == 0.0)) {
                      //           //   commonSnackBar(message: "Please Enter Address");
                      //           //   return;
                      //           // }
                      //
                      //           /// Validate Pin Code
                      //           if (picCodeController.text.isEmpty) {
                      //             commonSnackBar(message: "Please Enter Pin Code");
                      //             return;
                      //           }
                      //
                      //           /// ✅ All validation passed -> navigate
                      //           navigatePushTo(
                      //             context,
                      //             BusinessDetailsEditPageTwo(
                      //               paramsMap: await buildBusinessDetailsPayload(),
                      //               prevBusinessDetails: widget.prevBusinessDetails,
                      //               isFromCreateUser: widget.isFromCreateUser,
                      //             ),
                      //           );
                      //         },
                      //         title: "Next",
                      //         isValidate: validate,
                      //       ),
                      //     )
                      //
                      //   ],
                      // ),
                      Row(
                        children: [
                          Expanded(
                            child: CustomBtn(
                              radius: 10,
                              onTap: () {
                                Navigator.of(context).pop();
                              },
                              title:AppStrings.cancel,
                              bgColor: Colors.transparent,
                              textColor: AppColors.primaryColor,
                              borderColor: AppColors.primaryColor,
                            ),
                          ),
                          SizedBox(width: SizeConfig.size10),
                          Expanded(
                            child: CustomBtn(
                              radius: 10,
                              bgColor: AppColors.primaryColor,
                              onTap: () async {
                                Map<String, dynamic> updatedParams = await buildBusinessDetailsPayload();

                                if ((_formKey.currentState?.validate() ?? false) == false) {
                                  commonSnackBar(message: AppStrings.fixErrorsBeforeSaving);
                                  return;
                                }

                                /// Validate required fields
                                if (companyOrgNameTextController.text.isEmpty) {
                                  commonSnackBar(message: AppStrings.pleaseEnterBusinessName);
                                  // commonSnackBar(message: "Please Enter Business Name");
                                  return;
                                }

                                if (selectedType == ContactType.Mobile) {
                                  String? phoneError = ValidationMethod.validatePhone(mobileController.text);
                                  if (phoneError != null) {
                                    commonSnackBar(message: phoneError);
                                    return;
                                  }
                                } else if (selectedType == ContactType.Landline) {
                                  String? landlineError = ValidationMethod.validateLandline(landlineNumberController.text);
                                  if (landlineError != null) {
                                    commonSnackBar(message: landlineError);
                                    return;
                                  }
                                }

                                // if (picCodeController.text.isEmpty) {
                                //   commonSnackBar(message: "Please Enter Pin Code");
                                //   return;
                                // }

                                if (websiteController.text.trim().isNotEmpty) {
                                  String? webError = ValidationMethod.urlValidation(websiteController.text.trim());
                                  if (webError != null) {
                                    commonSnackBar(message: webError);
                                    return;
                                  }
                                }

                                /// Build payload for saving available fields
                                updatedParams.addAll({
                                  ApiKeys.business_name: companyOrgNameTextController.text,
                                  //ApiKeys.mobile_no: mobileController.text,
                                  // ApiKeys.date_of_incorporation:
                                  // "${selectedYear}-${selectedMonth}-${selectedDay}", // assuming you have these
                                  ApiKeys.website: websiteController.text.trim(),
                                  ApiKeys.opening_time:
                                  viewBusinessDetailsController.shopOpenTime.value,
                                  ApiKeys.closing_time:
                                  viewBusinessDetailsController.shopCloseTime.value,
                                });

                                /// Call API to update business details
                                final saved =
                                    await Get.find<ViewBusinessDetailsController>()
                                        .updateBusinessDetails(updatedParams);

                                // The result used to be discarded, so the page
                                // popped whether or not the save landed — the
                                // user saw an error snackbar flash past as
                                // their edits disappeared. It matters most for
                                // the branch: a duplicate (GST + branch) pair
                                // comes back 409 with a message that names the
                                // clash and asks for a different branch
                                // (docs/finance-gst-branch-ui-integration.md
                                // §4), which is useless advice on a form the
                                // user has just been thrown off.
                                if (!saved) return;

                                /// After save — navigate back or show success
                                if (widget.isFromCreateUser == false) {
                                  // Guarded on the context: this pop sits in a
                                  // nested callback, and the save above is a
                                  // network call. The `else` branch routes
                                  // through GetX and needs no context.
                                  if (context.mounted) {
                                    Navigator.of(context).pop();
                                  }
                                } else {
                                  Get.offNamedUntil(
                                    RouteHelper.getBottomNavigationBarScreenRoute(),
                                        (route) => false,
                                  );
                                }
                              },
                              title: AppStrings.save,
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
            ),
          );
        }),
      ),
    );
  }

  Future<Map<String, dynamic>> buildBusinessDetailsPayload() async {

    // dioObj.MultipartFile? imageByPart;
    // if (viewBusinessDetailsController.isImageUpdated.value) {
    //   if (viewBusinessDetailsController.imagePath?.value.isNotEmpty ?? false) {
    //     String fileName =
    //         viewBusinessDetailsController.imagePath?.value
    //             .split('/')
    //             .last ??
    //             "";
    //     imageByPart = await dioObj.MultipartFile.fromFile(
    //         viewBusinessDetailsController.imagePath?.value ?? "",
    //         filename: fileName);
    //   }
    // }
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
      ApiKeys.business_number: {
        if (mobileController.text.isNotEmpty)
          "office_mob_no": {
            "pre": 91,
            "number": int.tryParse(mobileController.text) ?? mobileController.text,
          },

        if (landlineNumberController.text.isNotEmpty)
          "office_landline_no": {
            "pre": int.tryParse(landlineCodeController.text) ??
                landlineCodeController.text,
            "number": int.tryParse(landlineNumberController.text) ??
                landlineNumberController.text,
          },

        },
      if (landlineNumberController.text.isNotEmpty)
        ApiKeys.office_landline_no_number: landlineNumberController.text,
      ApiKeys.Nature_of_Business: selectedBusiness == NatureOfBusiness.OTHERS
          ? othersCatController.text
          : selectedBusiness?.displayName ?? '',
      ApiKeys.city_state_pincode: cityController.text,
      ApiKeys.address: fullBusinessAddressTextController.text,
      // ApiKeys.address: viewBusinessDetailsController.businessAddress.value,

      ApiKeys.business_location: jsonEncode({
        ApiKeys.lat: viewBusinessDetailsController.addressLat?.value.toString(),
        ApiKeys.lon:
        viewBusinessDetailsController.addressLong?.value.toString(),
      }),
      ApiKeys.pincode: picCodeController.text,
      ApiKeys.website_url: websiteController.text,

      // Branch, ONLY when it changed. §6 is a partial update, and the server
      // re-runs the (GST + branch) duplicate check on every `branch` it
      // receives — re-sending the unchanged value asks it to check this
      // profile against itself for nothing. Case/whitespace-insensitive to
      // match how the backend compares (§4), so re-casing alone is not
      // treated as an edit.
      if (_hasGstBranch && _branchChanged)
        ApiKeys.branch: branchTextController.text.trim(),

      // ApiKeys.logo_image: viewBusinessDetailsController.isImageUpdated.value
      //     ? imageByPart
      //     : null,
    };
  }

  // Widget _buildAddressField() {
  //   return Obx(() {
  //     if (locationController.isFetchingAddress.value) {
  //       return Padding(
  //         padding: const EdgeInsets.only(top: 8.0),
  //         child: const SizedBox(
  //           width: 16,
  //           height: 16,
  //           child: CircularProgressIndicator(strokeWidth: 2),
  //         ),
  //       );
  //     }
  //
  //     if (!locationController.fetchAddressFromGeo.value) {
  //       return Padding(
  //         padding: const EdgeInsets.only(top: 8.0),
  //         child: GestureDetector(
  //           onTap: () => updateAddressFromLocation(),
  //           child: CustomText(
  //             'GPS location not found (Tap to fetch)',
  //             fontSize: SizeConfig.small,
  //             fontWeight: FontWeight.w600,
  //             color: AppColors.red,
  //             decoration: TextDecoration.underline,
  //             decorationColor: AppColors.red,
  //           ),
  //         ),
  //       );
  //     }
  //
  //     return SizedBox();
  //   });
  // }
}
