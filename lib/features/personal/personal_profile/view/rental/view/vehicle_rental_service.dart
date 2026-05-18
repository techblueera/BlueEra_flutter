import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/api/model/place_details.dart';
import 'package:BlueEra/core/common_bloc/place/repo/place_repo.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/regular_expression.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/common/delivery_partner/controller/delivery_partner_controller.dart';
import 'package:BlueEra/features/common/delivery_partner/model/vehicle_enums_response.dart';
import 'package:BlueEra/features/common/delivery_partner/widget/common_multiple_image_upload_section.dart';
import 'package:BlueEra/features/personal/auth/controller/view_personal_details_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/controller/email_verification_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/controller/languge_list_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/my_documents/controller/my_documents_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/my_documents/widget/vehicle_document_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/rental/controller/vehicle_rental_service_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/rental/widget/add_highlights_widget.dart';
import 'package:BlueEra/features/personal/personal_profile/view/rental/widget/add_more_restriction_widget.dart';
import 'package:BlueEra/features/personal/personal_profile/view/rental/widget/custom_switch_card.dart';
import 'package:BlueEra/features/personal/personal_profile/view/rental/widget/vehicle_images_widget.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:BlueEra/widgets/common_drop_down-dialoge.dart';
import 'package:BlueEra/widgets/common_drop_down.dart';
import 'package:BlueEra/widgets/common_location_search_field.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/widgets/update_contact_number.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../../core/api/model/personal_profile_details_model.dart';

class VehicleRentalService extends StatefulWidget {
  const VehicleRentalService({super.key});

  @override
  State<VehicleRentalService> createState() => _VehicleRentalServiceState();
}

class _VehicleRentalServiceState extends State<VehicleRentalService> {
  final controller = getOrPut(() => VehicleRentalServiceController());
  final langController = getOrPut(() => LanguageListController());
  final multipleImageSectionController = getOrPut(() => CommonMultipleImageSectionController());
  final deliveryPartnerController = getOrPut(() => DeliveryPartnerController());
  final emailVerificationController = getOrPut(() => EmailVerificationController());
  final myDocumentsController = getOrPut(() => MyDocumentsController());

  final viewProfileController = Get.find<ViewPersonalDetailsController>();

  @override
  void initState() {
    super.initState();
    loadInitData();
    deliveryPartnerController.fetchVehicleDataEnum();
  }

  Future<void> loadInitData() async {
    User? user = viewProfileController.personalProfileDetails.value.user;
    controller.ownerNameCtrl.text = user?.name ?? "";
    controller.emailCtrl.text = user?.email ?? "";
    controller.mobileNumberCtrl.text = user?.contactNo??'';
    controller.locationCtrl.text = user?.location ?? "";
    controller.pinCodeCtrl.text = user?.pincode.toString() ?? "0.0";
  }

  @override
  void dispose() {
    deleteIfRegistered<VehicleRentalServiceController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result){
        if(didPop){
          return;
        }

        controller.onBackPressed();
      },
      child: Obx(()=> Scaffold(
        appBar: CommonBackAppBar(
          title: controller.currentStep.value == 0
              ? AppStrings.ownerDetails :
               controller.currentStep.value == 1
                     ?  AppStrings.vehicleDetails
                     : controller.currentStep.value == 2
                           ? AppStrings.documentsCondition
                                : controller.currentStep.value == 3
                                  ? AppStrings.rentalInformation : AppStrings.vehicleImages,
          onBackTap: controller.previousStep,
          buildCustomActionWidget: ()=> Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Center(
                  child: Text(
                    "${AppStrings.stepLabel.tr}${controller.currentStep.value + 1}/${controller.totalSteps}",
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
        ),
        body: SafeArea(
          child: Obx(() {
            switch (controller.currentStep.value) {
              case 0:
                return _buildStepOne();
              case 1:
                return _buildStepTwo();
              case 2:
                return _buildStepThree();
              case 3:
                return _buildStepFour();
              case 4:
                return _buildStepFive();
              default:
                return const SizedBox();
            }
          }),
        ),
       )
      ),
    );
  }

  // ---------------- STEP 1 ----------------
  Widget _buildStepOne() {
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: SizeConfig.size15,
        right: SizeConfig.size15,
        top: SizeConfig.size15,
        bottom: SizeConfig.size40,
      ),
      child: Obx(
        (){
          if(viewProfileController.viewPersonalResponse.value.status == Status.COMPLETE) {
            return Form(
              key: controller.formKeyStep1,
              child: CustomFormCard(
                child: Column(
                    children:[
                      CommonTextField(
                        textEditController: controller.ownerNameCtrl,
                        inputLength: AppConstants.inputCharterLimit50,
                        keyBoardType: TextInputType.text,
                        title: AppStrings.ownerName,
                        regularExpression: RegularExpressionUtils.alphabetSpacePattern,
                        hintText: AppStrings.egRahulSharma,
                        isValidate: true,
                      ),
                      SizedBox(height: SizeConfig.paddingM),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          CustomText(
                            AppStrings.contactNumber,
                            fontSize: SizeConfig.small,
                            fontWeight: FontWeight.w400,
                            color: AppColors.mainTextColor,
                          ),
                          InkWell(
                            onTap: () async {
                              final result = await CommonMobileOtpDialog().show(context);

                              if (result == true) {
                                //  OTP successfully verified
                                print("OTP verification successful");
                              } else {
                                // Either cancelled or verification failed
                                print("OTP verification failed or cancelled");
                              }

                            },
                            child: CustomText(
                              AppStrings.edit,
                              fontSize: SizeConfig.small,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryColor,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: SizeConfig.size8),
                      Row(
                        mainAxisSize: MainAxisSize.max,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            height: SizeConfig.size45,
                            width: SizeConfig.size57,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: AppColors.greyE5,
                                width: 1,
                              ),
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [AppShadows.textFieldShadow],
                            ),
                            child: CustomText("+91", fontSize: SizeConfig.large),
                          ),
                          SizedBox(width: SizeConfig.size10),
                          Expanded(
                            child: CommonTextField(
                              textEditController: controller.mobileNumberCtrl,
                              inputLength: 10,
                              maxLength: 10,
                              keyBoardType: TextInputType.number,
                              regularExpression:
                              RegularExpressionUtils.digitsPattern,
                              validationType: ValidationTypeEnum.pNumber,
                              hintText: AppStrings.enterMobileNumber,
                              hintStyle: TextStyle(
                                fontSize: langController.selectedCode.value == 'ta' ? 12 : 14,
                              ),
                              onTapOutsideTrue: false,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: SizeConfig.paddingM),
                      CommonTextField(
                        title: AppStrings.email,
                        hintText: AppStrings.enterYourEmailAddress,
                        textEditController: controller.emailCtrl,
                        validationType: ValidationTypeEnum.email,
                        onChange: (val) {
                          // filedValidation();
                        },
                        sIcon: (viewProfileController
                            .personalProfileDetails.value.user?.emailVerified == true)
                            ? Icon(
                          Icons.verified_user_outlined,
                          color: AppColors.green39,
                        )
                            : null,
                      ),
                      if(viewProfileController.personalProfileDetails
                          .value.user?.emailVerified ==
                          false)
                        ...[
                          SizedBox(height: SizeConfig.size8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: GestureDetector(
                              onTap: () {

                                // Validate just the email field
                                if (controller.emailCtrl.text.isNotEmpty &&
                                    validateEmail(controller.emailCtrl.text)) {
                                  emailVerificationController
                                      .verifyEmail(controller.emailCtrl.text);
                                } else {
                                  commonSnackBar(
                                      message:
                                      AppStrings.pleaseEnterValidEmail);
                                }

                              },
                              child: CustomText(
                                AppStrings.getVerify,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryColor,
                              ),
                            ),
                          ),
                        ],
                      SizedBox(height: SizeConfig.paddingM),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: CommonLocationSearchField(
                              controller: controller.locationCtrl,
                              title: AppStrings.homeLocation,
                              hintText: AppStrings.egLucknowGomtiNagar,
                              onSelected: (placeId, lat, lng, address) async {
                                print("PlaceId: $placeId Selected: $address → ($lat, $lng)");
                                controller.locationCtrl.text = address;
                                controller.currentAddress.value = address;
                                controller.latitude = lat;
                                controller.longitude = lng;

                                controller.isFetchingAddressDetails.value = true;

                                // Fetch and auto-fill details
                                try {
                                  final detailsResponse = await PlaceRepo().getCompletePlaceDetails(placeId: placeId);
                                  final detailsData = detailsResponse.response?.data;

                                  final placeDetails = PlaceDetailsResponse.fromJson(detailsData);
                                  final components = placeDetails.result?.addressComponents ?? [];

                                  String postalCode = '';

                                  for (var comp in components) {
                                    final types = comp.types ?? [];
                                    if (types.contains('locality')) {
                                    } else if (types.contains('administrative_area_level_1')) {
                                    } else if (types.contains('postal_code')) {
                                      postalCode = comp.longName ?? '';
                                    }
                                  }

                                  controller.pinCodeCtrl.text = postalCode;

                                } catch (e) {
                                  print("Error fetching place details: $e");
                                }finally {
                                  controller.isFetchingAddressDetails.value = false;
                                }
                              },
                            ),
                          ),

                          if(controller.currentAddress.isNotEmpty)
                            Padding(
                              padding: EdgeInsets.only(left: SizeConfig.size8, top: SizeConfig.size24),
                              child: (controller.isFetchingAddressDetails.value) ?
                              SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ) :  Icon(Icons.check_circle, color: Colors.green, size: 22),
                            )
                        ],
                      ),
                      SizedBox(height: SizeConfig.paddingM),
                      CommonTextField(
                        textEditController: controller.pinCodeCtrl,
                        title: AppStrings.pincodeTitle,
                        fontSize: SizeConfig.small,
                        fontWeight: FontWeight.w400,
                        titleColor: AppColors.mainTextColor,
                        hintText: AppStrings.pincodeHint,
                        keyBoardType: TextInputType.number,
                        inputLength: AppConstants.inputCharterLimit6,
                        validator: ValidationMethod().validatePin,
                      ),
                      SizedBox(height: SizeConfig.paddingM),
                      CommonTextField(
                        textEditController: controller.landmarkCtrl,
                        inputLength: AppConstants.inputCharterLimit30,
                        title: AppStrings.houseNoAndLandMark,
                        fontSize: SizeConfig.small,
                        fontWeight: FontWeight.w400,
                        titleColor: AppColors.mainTextColor,
                        hintText: AppStrings.egFlat21B,
                        keyBoardType: TextInputType.text,
                        isValidate: true,
                      ),
                      SizedBox(height: SizeConfig.paddingL),
                      CustomBtn(
                        title: AppStrings.nextButton,
                        onTap: controller.validateStepOne,
                        radius: 10.0,
                        bgColor: AppColors.primaryColor,
                      ),
                    ]
                ),
              ),
            );
          }

          return Center(
            child: CircularProgressIndicator(),
          );

        }

      ),
    );
  }

  // ---------------- STEP 2 ----------------
  Widget _buildStepTwo() {
    return Obx(()=> deliveryPartnerController.isVehicleDataEnumLoading.value ?
    Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
      padding: EdgeInsets.only(
        left: SizeConfig.size15,
        right: SizeConfig.size15,
        top: SizeConfig.size15,
        bottom: SizeConfig.size40,
      ),
      child: Form(
        key: controller.formKeyStep2,
        child: CustomFormCard(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children:[
                /// Registration Type
                CustomText(
                  AppStrings.registrationType,
                  fontSize: SizeConfig.small,
                  fontWeight: FontWeight.w400,
                  color: AppColors.mainTextColor,
                ),
                SizedBox(height: SizeConfig.size8),
                CommonDropdownDialog<VehicleEnumItem>(
                  items: deliveryPartnerController.vehicleEnumResponse?.registrationType ?? [],
                  selectedValue: deliveryPartnerController.selectedVehicleRegistrationType.value,
                  title: AppStrings.registrationType,
                  hintText: AppStrings.egPersonalCommercial,
                  displayValue: (value) => value.slugValue,
                  onChanged: (value) {
                    deliveryPartnerController.selectedVehicleRegistrationType.value = value;
                  },
                  // validator: (value) {
                  //   return null;
                  // },
                ),
                SizedBox(height: SizeConfig.paddingM),

                /// Vehicle Type
                CustomText(
                  AppStrings.vehicleType,
                  fontSize: SizeConfig.small,
                  fontWeight: FontWeight.w400,
                  color: AppColors.mainTextColor,
                ),
                SizedBox(height: SizeConfig.size8),
                CommonDropdownDialog<VehicleEnumItem>(
                  items: deliveryPartnerController.vehicleEnumResponse?.vehicleType ?? [],
                  selectedValue: deliveryPartnerController.selectedVehicleType.value,
                  title: AppStrings.vehicleType,
                  hintText: AppStrings.egTwoThreeWheeler,
                  displayValue: (value) => value.slugValue,
                  onChanged: (value) {
                    deliveryPartnerController.selectedVehicleType.value = value;
                  },
                  // validator: (value) {
                  //   return null;
                  // },
                ),
                SizedBox(height: SizeConfig.paddingM),

                /// Vehicle Use Type
                CustomText(
                  AppStrings.vehicleUseType,
                  fontSize: SizeConfig.small,
                  fontWeight: FontWeight.w400,
                  color: AppColors.mainTextColor,
                ),
                SizedBox(height: SizeConfig.size8),
                CommonDropdownDialog<VehicleEnumItem>(
                  items: deliveryPartnerController.vehicleEnumResponse?.vehicleUsesType ?? [],
                  selectedValue: deliveryPartnerController.selectedVehicleUseType.value,
                  title: AppStrings.vehicleUseType,
                  hintText: AppStrings.egPassengerDeliveryGoods,
                  displayValue: (value) => value.slugValue,
                  onChanged: (value) {
                    deliveryPartnerController.selectedVehicleUseType.value = value;
                  },
                  // validator: (value) {
                  //   return null;
                  // },
                ),
                SizedBox(height: SizeConfig.paddingM),

                /// Vehicle Name
                // CommonTextField(
                //   title: AppStrings.vehicleName,
                //   hintText: AppStrings.egSP125,
                //   textEditController: controller.vehicleNameCtrl,
                //   isValidate: true,
                // ),
                SizedBox(height: SizeConfig.paddingM),

                /// Fuel Type
                CustomText(
                  AppStrings.fuelType,
                  fontSize: SizeConfig.small,
                  fontWeight: FontWeight.w400,
                  color: AppColors.mainTextColor,
                ),
                SizedBox(height: SizeConfig.size8),
                CommonDropdownDialog<VehicleEnumItem>(
                  items: deliveryPartnerController.vehicleEnumResponse?.fuelType ?? [],
                  selectedValue: deliveryPartnerController.selectedFuelType.value,
                  title: AppStrings.fuelType,
                  hintText: AppStrings.egPetrolDiesel,
                  displayValue: (value) => value.slugValue,
                  onChanged: (value) {
                    deliveryPartnerController.selectedFuelType.value = value;
                  },
                  // validator: (value) {
                  //   return null;
                  // },
                ),
                SizedBox(height: SizeConfig.paddingM),

                /// Vehicle Number
                CommonTextField(
                  title: AppStrings.vehicleNumber,
                  hintText: AppStrings.egWB5454,
                  textEditController: controller.vehicleRegistrationNumberCtrl,
                  validator: ValidationMethod.validateVehicleNumber,
                  isCapitalize: true,
                  maxLength: 10,
                ),
                SizedBox(height: SizeConfig.paddingM),

                /// Vehicle Model
                CommonTextField(
                  title: AppStrings.vehicleModelYearManufacturing,
                  hintText: AppStrings.eg2020,
                  keyBoardType: TextInputType.number,
                  textEditController: controller.vehicleModelCtrl,
                  isValidate: true,
                  maxLength: 4,
                ),
                SizedBox(height: SizeConfig.paddingM),

                if(deliveryPartnerController.selectedVehicleRegistrationType.value?.slugId != 'commercialGoods')
                  CommonTextField(
                    title: AppStrings.seatingCapacity,
                    hintText: AppStrings.eg10People,
                    keyBoardType: TextInputType.number,
                    textEditController: controller.seatingCapacityCtrl,
                    isValidate: true,
                  )
                else
                  Column(
                    children: [
                      Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                          CustomText(
                            AppStrings.loadCapacity,
                            fontSize: SizeConfig.small,
                            fontWeight: FontWeight.w400,
                            color: AppColors.mainTextColor,
                          ),
                          RadioGroup<LoadCapacity>(
                            groupValue: controller.selectedLoadCapacity.value,
                            onChanged: (value) {
                              if(value!=null) controller.selectedLoadCapacity.value = value;
                            },
                            child: Row(
                              children: [
                                Row(
                                  children: [
                                    Radio<LoadCapacity>(
                                      value: LoadCapacity.KG,
                                      activeColor: AppColors.primaryColor,
                                    ),
                                    CustomText(
                                      AppStrings.kg,
                                      color: AppColors.secondaryTextColor,
                                      fontWeight: FontWeight.w400,
                                      fontSize: SizeConfig.small,
                                    ),
                                  ],
                                ),
                                SizedBox(width: SizeConfig.size10), // spacing between options
                                Row(
                                  children: [
                                    Radio<LoadCapacity>(
                                      value: LoadCapacity.TON,
                                      activeColor: AppColors.primaryColor,
                                    ),
                                    CustomText(
                                      AppStrings.ton,
                                      color: AppColors.secondaryTextColor,
                                      fontWeight: FontWeight.w400,
                                      fontSize: SizeConfig.small,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          )
                        ]
                      ),
                      SizedBox(height: SizeConfig.size8),
                      CommonTextField(
                        hintText: AppStrings.eg100KG,
                        keyBoardType: TextInputType.number,
                        textEditController: controller.loadCapacityCtrl,
                        isValidate: true,
                      )
                    ],
                  ),

                SizedBox(height: SizeConfig.paddingM),

                CommonTextField(
                  textEditController: controller.vehicleDesCtrl,
                  inputLength: AppConstants.inputCharterLimit200,
                  keyBoardType: TextInputType.text,
                  title: AppStrings.vehicleConditionDescription,
                  regularExpression: RegularExpressionUtils.alphabetSpacePattern,
                  hintText: AppStrings.egGoodCondition,
                  validator: ValidationMethod().validateVehicleDescription,
                  maxLine: 3,
                  maxLength: 200,
                ),

                SizedBox(height: SizeConfig.paddingL),

                CustomBtn(
                  title: AppStrings.nextButton,
                  onTap: controller.validateStepTwo,
                  radius: 10.0,
                  bgColor: AppColors.primaryColor,
                ),
              ]
          ),
        ),
      ),
    )
    );
  }

  // ---------------- STEP 3 ----------------
  Widget _buildStepThree() {
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: SizeConfig.size15,
        right: SizeConfig.size15,
        top: SizeConfig.size15,
        bottom: SizeConfig.size40,
      ),
      child: Form(
        key: controller.formKeyStep3,
        child: Column(
            children:[
              CustomFormCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      AppStrings.chargesTypeTitle,
                      fontSize: SizeConfig.medium,
                      color: AppColors.mainTextColor,
                      fontWeight: FontWeight.w400,
                    ),
                    SizedBox(height: SizeConfig.size8),
                    Row(
                      children: [
                        Expanded(
                          child: CommonDropdown<ChargesTypes>(
                              items: ChargesTypes.values.toList(),
                              selectedValue: controller.selectedChargesTypes.value,
                              hintText: AppStrings.chargesTypeHint,
                              displayValue: (item) => item.label,
                              onChanged: (val) {
                                if (val != null) {
                                  controller.selectedChargesTypes.value = val;
                                }
                              },
                              validator: (value){
                                if(value==null){
                                  return AppStrings.selectChargesTypeError.tr;
                                }
                                return null;
                              }
                          ),
                        ),
                        SizedBox(width: SizeConfig.size8),
                        Expanded(
                          child: CommonTextField(
                            textEditController: controller.chargeCtrl,
                            fontSize: SizeConfig.small,
                            fontWeight: FontWeight.w400,
                            titleColor: AppColors.mainTextColor,
                            hintText: AppStrings.egRs2000,
                            keyBoardType: TextInputType.number,
                            isValidate: true,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: SizeConfig.paddingM),
                    CommonTextField(
                      textEditController: controller.securityDepositCtrl,
                      fontSize: SizeConfig.small,
                      fontWeight: FontWeight.w400,
                      title: 'Security Deposit',
                      titleColor: AppColors.mainTextColor,
                      hintText: 'E.g. ₹2000',
                      keyBoardType: TextInputType.number,
                      isValidate: true,
                    ),
                    SizedBox(height: SizeConfig.paddingM),

                    CommonLocationSearchField(
                      controller: controller.pickUpLocationCtrl,
                      title: AppStrings.pickupLocation,
                      hintText: AppStrings.egSubhasPalliGomtiNagar,
                      onSelected: (placeId, lat, lng, address) async {
                        print("PlaceId: $placeId Selected: $address → ($lat, $lng)");
                        controller.pickUpLocationCtrl.text = address;
                        controller.pickUpLocationAddress.value = address;
                        controller.pickUpLocationLatitude = lat;
                        controller.pickUpLocationLongitude = lng;
                      },
                    ),

                  ],
                ),
              ),

              SizedBox(height: SizeConfig.paddingM),

              CustomFormCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      CustomText(
                        'Document Required For Rent',
                        fontSize: SizeConfig.medium,
                        color: AppColors.mainTextColor,
                        fontWeight: FontWeight.w400,
                      ),
                      SizedBox(height: SizeConfig.paddingXSL),

                      // 1. Aadhar Card
                      CommonSwitchCard(
                        title: 'Aadhar Card',
                        value: controller.isAllowAadharCard.value,
                        onChanged: (val) {
                          controller.isAllowAadharCard.value = val;
                        },
                      ),
                      SizedBox(height: SizeConfig.paddingXSL),

                      // 2. Address Proof
                      CommonSwitchCard(
                        title: 'Address Proof',
                        value: controller.isAllowAddressProof.value,
                        onChanged: (val) {
                          controller.isAllowAddressProof.value = val;
                        },
                      ),
                      SizedBox(height: SizeConfig.paddingXSL),

                      // 3. Driving License
                      CommonSwitchCard(
                        title: 'Driving Licence',
                        value: controller.isAllowDrivingLicense.value,
                        onChanged: (val) {
                          controller.isAllowDrivingLicense.value = val;
                        },
                      ),
                      SizedBox(height: SizeConfig.paddingM),

                      _buildAddHighlightsSection(),

                      SizedBox(height: SizeConfig.paddingM),

                      _buildAddRestrictionsSection(),

                      SizedBox(height: SizeConfig.paddingL),

                      CustomBtn(
                        title: controller.isVehicleRentalServiceLoading.value
                            ? null
                            : AppStrings.nextButton,
                        onTap: controller.validateStepThree,
                        radius: 10.0,
                        bgColor: AppColors.primaryColor,
                        isLoading: controller.isVehicleRentalServiceLoading.value
                      ),
                    ],
                  )
              ),
            ]
        ),
      ),
    );
  }

  // ---------------- STEP 4 ----------------
  Widget _buildStepFour() {
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: SizeConfig.size8,
        right: SizeConfig.size8,
        top: SizeConfig.size15,
        bottom: SizeConfig.size40,
      ),
      child: Form(
        key: controller.formKeyStep4,
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              VehicleDocumentsScreen(
                controller: myDocumentsController
              ),

              SizedBox(height: SizeConfig.paddingL),

              CustomBtn(
                title: AppStrings.nextButton,
                onTap: ()=> controller.validateStepFour(myDocumentsController),
                radius: 10.0,
                bgColor: AppColors.primaryColor,
              ),

              SizedBox(height: SizeConfig.paddingM),

            ]
        ),
      ),
    );
  }

  // ---------------- STEP 5 ----------------
  Widget _buildStepFive() {
    return AbsorbPointer(
      absorbing: controller.isVehicleRentalServiceLoading.value,
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: SizeConfig.size15,
          right: SizeConfig.size15,
          top: SizeConfig.size15,
          bottom: SizeConfig.size40,
        ),
        child: Column(
          children: [

            VehicleImagesWidget(
              controller: controller,
              multipleImageSectionController: multipleImageSectionController
            ),

            SizedBox(height: SizeConfig.paddingL),

            CustomBtn(
              title: AppStrings.postNowButton,
              onTap: controller.validateStepFive,
              radius: 10.0,
              bgColor: AppColors.primaryColor,
            )
          ],
        ),
      ),
    );
  }

  Widget _buildAddHighlightsSection() {
    return Column(
      children: [
        Row(
          children: [
            CustomText(
              'Vehicle Highlights',
              fontSize: SizeConfig.small,
              fontWeight: FontWeight.w400,
              color: AppColors.mainTextColor,
            ),

            if(controller.arrHighlights.isNotEmpty)
              ...[
                Spacer(),
                InkWell(
                  onTap: ()=> Get.to(()=> AddHighlightsWidget(
                      initialHighlights: controller.arrHighlights,
                      onSave: (List<String> highlights) {
                        controller.addHighlights(highlights);
                      })),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      const LocalAssets(
                        imagePath: AppIconAssets.addBlueIcon,
                      ),
                      CustomText(
                        AppStrings.addMoreTitle,
                        fontSize: SizeConfig.large,
                        fontWeight: FontWeight.w400,
                        color: AppColors.primaryColor,
                      ),
                    ],
                  ),
                )
              ]

          ],
        ),
        SizedBox(height: SizeConfig.size8),
        (controller.arrHighlights.isNotEmpty)
            ? Container(
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: AppColors.white,
              boxShadow: [AppShadows.textFieldShadow],
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.whiteE5)
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: controller.arrHighlights
                .map((e) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    height: SizeConfig.size6,
                    width: SizeConfig.size6,
                    decoration: BoxDecoration(
                        color: AppColors.secondaryTextColor,
                        shape: BoxShape.circle
                    ),
                  ),
                  SizedBox(width: SizeConfig.size6),
                  Expanded(
                    child: Text(
                      e,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ))
                .toList(),
          ),
        )
            : InkWell(
          onTap: ()=> Get.to(()=> AddHighlightsWidget(
              initialHighlights: controller.arrHighlights,
              onSave: (List<String> highlights) {
                controller.addHighlights(highlights);
              })),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: SizeConfig.size14,
              vertical: SizeConfig.size12,
            ),
            decoration: BoxDecoration(
                color: AppColors.white,
                boxShadow: [AppShadows.textFieldShadow],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.whiteE5)
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(SizeConfig.size4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.white,
                    border: Border.all(
                        color: AppColors.mainTextColor,
                        width: 2
                    ),
                  ),
                  child: LocalAssets(
                      imagePath: AppIconAssets.add,
                      imgColor: AppColors.mainTextColor
                  ),
                ),
                SizedBox(width: SizeConfig.size6),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: CustomText(
                    AppStrings.addHighlightsTitle,
                    fontSize: SizeConfig.large,
                    fontWeight: FontWeight.w400,
                    color: AppColors.mainTextColor,
                  ),
                ),
                Spacer(),
                Icon(
                  Icons.chevron_right,
                  color: AppColors.mainTextColor,
                )
              ],
            ),
          ),
        )
      ],
    );
  }

  Widget _buildAddRestrictionsSection() {
    return Column(
      children: [
        (controller.arrMoreRestriction.isEmpty)
            ? InkWell(
          onTap: ()=> Get.to(()=> AddMoreRestrictionsWidget(
              initialRestriction: controller.arrMoreRestriction,
              onSave: (List<String> restrictions) {
                controller.addMoreRestrictions(restrictions);
              })),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const LocalAssets(
                imagePath: AppIconAssets.addBlueIcon,
                imgColor: AppColors.primaryColor,
              ),
              SizedBox(width: SizeConfig.size5),
              CustomText(
                AppStrings.addRestrictions,
                fontSize: SizeConfig.large,
                fontWeight: FontWeight.w400,
                color: AppColors.primaryColor,
              ),
            ],
          ),
        )
            : Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [

                CustomText(
                  AppStrings.restrictionsHighlightsTitle,
                  fontSize: SizeConfig.small,
                  fontWeight: FontWeight.w400,
                  color: AppColors.mainTextColor,
                ),

                Spacer(),
                InkWell(
                  onTap: ()=> Get.to(()=> AddMoreRestrictionsWidget(
                      initialRestriction: controller.arrMoreRestriction,
                      onSave: (List<String> restrictions) {
                        controller.addMoreRestrictions(restrictions);
                      })),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      const LocalAssets(
                        imagePath: AppIconAssets.addBlueIcon,
                        imgColor: AppColors.primaryColor,
                      ),
                      SizedBox(width: SizeConfig.size3),
                      CustomText(
                        AppStrings.addMoreTitle,
                        fontSize: SizeConfig.large,
                        fontWeight: FontWeight.w400,
                        color: AppColors.primaryColor,
                      ),
                    ],
                  ),
                )

              ],
            ),
            SizedBox(height: SizeConfig.size8),
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: AppColors.white,
                  boxShadow: [AppShadows.textFieldShadow],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.whiteE5)
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: controller.arrMoreRestriction
                    .map((e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        height: SizeConfig.size6,
                        width: SizeConfig.size6,
                        decoration: BoxDecoration(
                            color: AppColors.secondaryTextColor,
                            shape: BoxShape.circle
                        ),
                      ),
                      SizedBox(width: SizeConfig.size6),
                      Expanded(
                        child: CustomText(
                            e,
                            fontSize: SizeConfig.medium
                        ),
                      ),
                    ],
                  ),
                ))
                    .toList(),
              ),
            )
          ],
        ),

      ],
    );
  }


}
