import 'dart:io';
import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/api/model/place_details.dart';
import 'package:BlueEra/core/common_bloc/place/repo/place_repo.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/regular_expression.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/common/delivery_partner/widget/common_image_upload_section.dart';
import 'package:BlueEra/features/common/delivery_partner/widget/common_multiple_image_upload_section.dart';
import 'package:BlueEra/features/personal/auth/controller/view_personal_details_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/controller/email_verification_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/controller/languge_list_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/rental/controller/vehicle_rental_service_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/rental/widget/add_highlights_widget.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:BlueEra/widgets/common_drop_down.dart';
import 'package:BlueEra/widgets/common_location_search_field.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/widgets/update_contact_number.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class VehicleRentalService extends StatefulWidget {
  const VehicleRentalService({super.key});

  @override
  State<VehicleRentalService> createState() => _VehicleRentalServiceState();
}

class _VehicleRentalServiceState extends State<VehicleRentalService> {
  final controller = Get.put(VehicleRentalServiceController());
  final langController = Get.put(LanguageListController());
  final multipleImageSectionController = Get.put(CommonMultipleImageSectionController());
  final viewProfileController = Get.find<ViewPersonalDetailsController>();
  final emailVerificationController = Get.put(EmailVerificationController());

  @override
  void initState() {
    super.initState();
    loadInitData();
  }

  Future<void> loadInitData() async {
    await viewProfileController.viewPersonalProfile();
    controller.ownerNameCtrl.text =
        viewProfileController.personalProfileDetails.value.user?.name ?? "";
    controller.emailCtrl.text =
        viewProfileController.personalProfileDetails.value.user?.email ?? "";
    controller.mobileNumberCtrl.text = viewProfileController
        .personalProfileDetails.value.user?.contactNo??'';
    controller.locationCtrl.text = viewProfileController.personalProfileDetails.value.user?.location ??
            "";
  }

  @override
  void dispose() {
    Get.delete<VehicleRentalServiceController>();
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
          buildCustomWidget: ()=> Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Center(
                  child: Text(
                    "${AppStrings.stepLabel}${controller.currentStep.value + 1}/${controller.totalSteps}",
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
    return SingleChildScrollView(
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
                CommonDropdown<RentalVehicleRegistrationType>(
                  items: RentalVehicleRegistrationType.values,
                  selectedValue: controller.selectedVehicleRegistrationType.value,
                  hintText: AppStrings.egPersonalCommercial,
                  displayValue: (value) => value.displayName,
                  onChanged: (value) {
                    controller.selectedVehicleRegistrationType.value = value;
                  },
                  validator: (value) {
                    return null;
                  },
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
                CommonDropdown<VehicleType>(
                  items: VehicleType.values,
                  selectedValue: controller.selectedVehicleType.value,
                  hintText: AppStrings.egTwoThreeWheeler,
                  displayValue: (value) => value.displayName,
                  onChanged: (value) {
                    controller.selectedVehicleType.value = value;
                  },
                  validator: (value) {
                    return null;
                  },
                ),
                SizedBox(height: SizeConfig.paddingM),

                /// Vehicle Name
                CommonTextField(
                  title: AppStrings.vehicleName,
                  hintText: AppStrings.egSP125,
                  textEditController: controller.vehicleNameCtrl,
                  isValidate: true,
                ),
                SizedBox(height: SizeConfig.paddingM),

                /// Fuel Type
                CustomText(
                  AppStrings.fuelType,
                  fontSize: SizeConfig.small,
                  fontWeight: FontWeight.w400,
                  color: AppColors.mainTextColor,
                ),
                SizedBox(height: SizeConfig.size8),
                CommonDropdown<FuelType>(
                  items: FuelType.values,
                  selectedValue: controller.selectedFuelType.value,
                  hintText: AppStrings.egPetrolDiesel,
                  displayValue: (value) => value.displayName,
                  onChanged: (value) {
                    controller.selectedFuelType.value = value;
                  },
                  validator: (value) {
                    return null;
                  },
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
                ),
                SizedBox(height: SizeConfig.paddingM),

                if(controller.selectedVehicleRegistrationType != RentalVehicleRegistrationType.CommercialGoods)
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
                          Row(
                            children: [
                              Row(
                                children: [
                                  Radio<LoadCapacity>(
                                    value: LoadCapacity.KG,
                                    groupValue: controller.selectedLoadCapacity.value,
                                    onChanged: (value) {
                                      if(value!=null) controller.selectedLoadCapacity.value = value;
                                    },
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
                                    groupValue: controller.selectedLoadCapacity.value,
                                    onChanged: (value) {
                                      if(value!=null) controller.selectedLoadCapacity.value = value;
                                    },
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
        child: CustomFormCard(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children:[
                /// RC
                CommonTextField(
                  textEditController: controller.rcController,
                  title: AppStrings.rcNumber,
                  fontSize: SizeConfig.small,
                  fontWeight: FontWeight.w400,
                  titleColor: AppColors.mainTextColor,
                  hintText: AppStrings.egUP32AB12,
                  keyBoardType: TextInputType.text,
                  validator: ValidationMethod.validateRC,
                  isCapitalize: true,
                  maxLength: 10,
                ),
                SizedBox(height: SizeConfig.paddingM),
                CustomText(
                  AppStrings.uploadRcBothSide,
                  fontSize: SizeConfig.small,
                  color: AppColors.mainTextColor,
                  fontWeight: FontWeight.w400,
                ),
                SizedBox(height: SizeConfig.size8),
                Row(
                  children: [
                    Expanded(
                      child: CommonImageUploadTile(
                        title: AppStrings.rcFront,
                        imageFile: controller.rcFrontImage,
                        context: context,
                        onImageSelected: () async {
                          final selectedPath = await CommonImageUploadTile.pickImage(context: context);
                          if (selectedPath != null) {
                            controller.rcFrontImage.value = File(selectedPath);
                          }
                        },
                      ),
                    ),
                    SizedBox(width: SizeConfig.size8),
                    Expanded(
                      child:
                      CommonImageUploadTile(
                        title: AppStrings.rcBack,
                        imageFile: controller.rcBackImage,
                        context: context,
                        onImageSelected: () async {
                          final selectedPath = await CommonImageUploadTile.pickImage(context: context);
                          if (selectedPath != null) {
                            controller.rcBackImage.value = File(selectedPath);
                          }
                        },
                      ),
                    ),
                  ],
                ),

                SizedBox(height: SizeConfig.paddingM),
                CustomText(
                  AppStrings.insuranceDocumentUpload,
                  fontSize: SizeConfig.small,
                  color: AppColors.mainTextColor,
                  fontWeight: FontWeight.w400,
                ),
                SizedBox(height: SizeConfig.size8),
                CommonImageUploadTile(
                  title: AppStrings.insuranceDocumentUpload,
                  imageFile: controller.insuranceImage,
                  context: context,
                  onImageSelected: () async {
                    final selectedPath = await CommonImageUploadTile.pickImage(context: context);
                    if (selectedPath != null) {
                      controller.insuranceImage.value = File(selectedPath);
                    }
                  },
                ),

                SizedBox(height: SizeConfig.paddingM),
                CustomText(
                  AppStrings.pollutionCertificateUpload,
                  fontSize: SizeConfig.small,
                  color: AppColors.mainTextColor,
                  fontWeight: FontWeight.w400,
                ),
                SizedBox(height: SizeConfig.size8),
                CommonImageUploadTile(
                  title: AppStrings.pollutionCertificateUpload,
                  imageFile: controller.pucImage,
                  context: context,
                  onImageSelected: () async {
                    final selectedPath = await CommonImageUploadTile.pickImage(context: context);
                    if (selectedPath != null) {
                      controller.pucImage.value = File(selectedPath);
                    }
                  },
                ),

                SizedBox(height: SizeConfig.paddingM),
                CustomText(
                  AppStrings.fitnessCertificateCommercial,
                  fontSize: SizeConfig.small,
                  color: AppColors.mainTextColor,
                  fontWeight: FontWeight.w400,
                ),
                SizedBox(height: SizeConfig.size8),
                CommonImageUploadTile(
                  title: AppStrings.fitnessCertificateCommercial,
                  imageFile: controller.vehicleFitnessCertificateImage,
                  context: context,
                  onImageSelected: () async {
                    final selectedPath = await CommonImageUploadTile.pickImage(context: context);
                    if (selectedPath != null) {
                      controller.vehicleFitnessCertificateImage.value = File(selectedPath);
                    }
                  },
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
                  onTap: controller.validateStepThree,
                  radius: 10.0,
                  bgColor: AppColors.primaryColor,
                ),
                SizedBox(height: SizeConfig.paddingM),


              ]
          ),
        ),
      ),
    );
  }

  // ---------------- STEP 4 ----------------
  Widget _buildStepFour() {
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: SizeConfig.size15,
        right: SizeConfig.size15,
        top: SizeConfig.size15,
        bottom: SizeConfig.size40,
      ),
      child: Form(
        key: controller.formKeyStep4,
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
                                  return AppStrings.selectChargesTypeError;
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

                    // Row(
                    //   crossAxisAlignment: CrossAxisAlignment.center,
                    //   children: [
                    //     Expanded(
                    //       child: CommonLocationSearchField(
                    //         controller: controller.pickUpLocationCtrl,
                    //         title: "Pickup Location",
                    //         hintText: "E.g. Subhas Palli, Gomti Nagar, luckn....",
                    //         onSelected: (placeId, lat, lng, address) async {
                    //           print("PlaceId: $placeId Selected: $address → ($lat, $lng)");
                    //           controller.pickUpLocationCtrl.text = address;
                    //           controller.pickUpLocationAddress.value = address;
                    //               controller.pickUpLocationLatitude = lat;
                    //               controller.pickUpLocationLongitude = lng;
                    //         },
                    //       ),
                    //     ),
                    //
                    //     if(controller.currentAddress.isNotEmpty)
                    //       Padding(
                    //         padding: EdgeInsets.only(left: SizeConfig.size8, top: SizeConfig.size24),
                    //         child: (controller.isFetchingAddressDetails.value) ?
                    //         SizedBox(
                    //           height: 20,
                    //           width: 20,
                    //           child: CircularProgressIndicator(strokeWidth: 2),
                    //         ) :  Icon(Icons.check_circle, color: Colors.green, size: 22),
                    //       )
                    //   ],
                    // ),

                  ],
                ),
              ),

              SizedBox(height: SizeConfig.paddingM),

              CustomFormCard(
                  child: Column(
                    children: [
                      // Row(
                      //   mainAxisAlignment: MainAxisAlignment.start  ,
                      //   children: [
                      //     const LocalAssets(
                      //       imagePath: AppIconAssets.addBlueIcon,
                      //     ),
                      //     CustomText(
                      //       'Add Restrictions',
                      //       fontSize: SizeConfig.large,
                      //       fontWeight: FontWeight.w400,
                      //       color: AppColors.primaryColor,
                      //     ),
                      //
                      //   ],
                      // ),
                      // SizedBox(height: SizeConfig.paddingM),

                      _buildAddHighlightsSection(),

                      SizedBox(height: SizeConfig.paddingL),

                      CustomBtn(
                        title: AppStrings.nextButton,
                        onTap: controller.validateStepFour,
                        radius: 10.0,
                        bgColor: AppColors.primaryColor,
                      ),
                    ],
                  )
              ),
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
            /// vehicleNumberPlateImages
            GetBuilder<CommonMultipleImageSectionController>(
              id: CommonMultipleImageSectionController.vehicleNumberPlateImageId,
              builder: (ctrl) => CommonMultipleImageUploadSection(
                title: AppStrings.uploadVehicleNumberPlateImage,
                maxImages: 1,
                images: controller.vehicleNumberPlateImages,
                onAddImage: () async {
                  multipleImageSectionController.addImages(
                      label: AppStrings.vehicleNumberPlateImages,
                      imageList: controller.vehicleNumberPlateImages,
                      updateId: CommonMultipleImageSectionController.vehicleNumberPlateImageId,
                      maxUploadImages: 1
                  );
                },
                onRemoveImage: (index) {
                  multipleImageSectionController.removeImageAt(
                    imageList: controller.vehicleNumberPlateImages,
                    index: index,
                    updateId: CommonMultipleImageSectionController.vehicleNumberPlateImageId,
                  );
                },
              ),
            ),
            SizedBox(height: SizeConfig.paddingM),

            /// vehicleRightSideImageId
            GetBuilder<CommonMultipleImageSectionController>(
              id: CommonMultipleImageSectionController.vehicleRightSideImageId,
              builder: (ctrl) => CommonMultipleImageUploadSection(
                title: AppStrings.uploadVehicleRightSideImages,
                minImages: 2,
                maxImages: controller.maxVehicleImageUpload,
                images: controller.vehicleRightSideImages,
                onAddImage: () async {
                  multipleImageSectionController.addImages(
                      label: AppStrings.vehicleRightSideImages,
                      imageList: controller.vehicleRightSideImages,
                      updateId: CommonMultipleImageSectionController.vehicleRightSideImageId,
                      maxUploadImages: controller.maxVehicleImageUpload
                  );
                },
                onRemoveImage: (index) {
                  multipleImageSectionController.removeImageAt(
                    imageList: controller.vehicleRightSideImages,
                    index: index,
                    updateId: CommonMultipleImageSectionController.vehicleRightSideImageId,
                  );
                },
              ),
            ),
            SizedBox(height: SizeConfig.paddingM),

            /// vehicleLeftSideImageId
            GetBuilder<CommonMultipleImageSectionController>(
              id: CommonMultipleImageSectionController.vehicleLeftSideImageId,
              builder: (ctrl) => CommonMultipleImageUploadSection(
                title: AppStrings.uploadVehicleLeftSideImages,
                minImages: 2,
                maxImages: controller.maxVehicleImageUpload,
                images: controller.vehicleLeftSideImages,
                onAddImage: () async {
                  multipleImageSectionController.addImages(
                      label: AppStrings.vehicleLeftSideImages,
                      imageList: controller.vehicleLeftSideImages,
                      updateId: CommonMultipleImageSectionController.vehicleLeftSideImageId,
                      maxUploadImages: controller.maxVehicleImageUpload
                  );
                },
                onRemoveImage: (index) {
                  multipleImageSectionController.removeImageAt(
                    imageList: controller.vehicleLeftSideImages,
                    index: index,
                    updateId: CommonMultipleImageSectionController.vehicleLeftSideImageId,
                  );
                },
              ),
            ),
            SizedBox(height: SizeConfig.paddingM),

            /// vehicleFrontImages
            GetBuilder<CommonMultipleImageSectionController>(
              id: CommonMultipleImageSectionController.vehicleFrontImageId,
              builder: (ctrl) => CommonMultipleImageUploadSection(
                title: AppStrings.uploadVehicleFrontImages,
                maxImages: 2,
                images: controller.vehicleFrontImages,
                onAddImage: () async {
                  multipleImageSectionController.addImages(
                      label: AppStrings.vehicleFrontImages,
                      imageList: controller.vehicleFrontImages,
                      updateId: CommonMultipleImageSectionController.vehicleFrontImageId,
                      maxUploadImages: 1
                  );
                },
                onRemoveImage: (index) {
                  multipleImageSectionController.removeImageAt(
                    imageList: controller.vehicleFrontImages,
                    index: index,
                    updateId: CommonMultipleImageSectionController.vehicleFrontImageId,
                  );
                },
              ),
            ),
            SizedBox(height: SizeConfig.paddingM),

            /// vehicleBackImages
            GetBuilder<CommonMultipleImageSectionController>(
              id: CommonMultipleImageSectionController.vehicleBackImageId,
              builder: (ctrl) => CommonMultipleImageUploadSection(
                title: AppStrings.uploadVehicleBackImages,
                maxImages: 2,
                images: controller.vehicleBackImages,
                onAddImage: () async {
                  multipleImageSectionController.addImages(
                      label: AppStrings.vehicleBackImages,
                      imageList: controller.vehicleBackImages,
                      updateId: CommonMultipleImageSectionController.vehicleBackImageId,
                      maxUploadImages: 1
                  );
                },
                onRemoveImage: (index) {
                  multipleImageSectionController.removeImageAt(
                    imageList: controller.vehicleBackImages,
                    index: index,
                    updateId: CommonMultipleImageSectionController.vehicleBackImageId,
                  );
                },
              ),
            ),
            SizedBox(height: SizeConfig.paddingL),

            CustomBtn(
              title: controller.isVehicleRentalServiceLoading.value
                  ? null
                  : AppStrings.postNowButton,
              onTap: controller.validateStepFive,
              radius: 10.0,
              bgColor: AppColors.primaryColor,
              isLoading: controller.isVehicleRentalServiceLoading.value
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
              AppStrings.homeHighlightsTitle,
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

}
