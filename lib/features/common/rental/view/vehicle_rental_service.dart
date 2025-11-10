import 'dart:io';
import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/api/model/place_details.dart';
import 'package:BlueEra/core/common_bloc/place/repo/place_repo.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/regular_expression.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/common/delivery_partner/widget/common_image_upload_section.dart';
import 'package:BlueEra/features/common/delivery_partner/widget/common_multiple_image_upload_section.dart';
import 'package:BlueEra/features/common/rental/controller/vehicle_rental_service_controller.dart';
import 'package:BlueEra/features/common/rental/widget/add_highlights_widget.dart';
import 'package:BlueEra/features/personal/auth/controller/view_personal_details_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/controller/email_verification_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/controller/languge_list_controller.dart';
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
    await viewProfileController.viewPersonalProfile(isCheckServiceOpt: false);
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
              ? "Owner Details" :
               controller.currentStep.value == 1
                     ?  "Vehicle Details"
                     : controller.currentStep.value == 2
                           ? "Documents & Condition "
                                : controller.currentStep.value == 3
                                  ? "Rental Information" : "Vehicle  Images ",
          onBackTap: controller.previousStep,
          buildCustomWidget: ()=> Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Center(
                  child: Text(
                    "Step-${controller.currentStep.value + 1}/${controller.totalSteps}",
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
                        title: "Owner Name",
                        regularExpression: RegularExpressionUtils.alphabetSpacePattern,
                        hintText: "E.g. Rahul Sharma....",
                        isValidate: true,
                      ),
                      SizedBox(height: SizeConfig.paddingM),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          CustomText(
                            "Contact Number",
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
                              "Edit",
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
                              hintText: langController.tr('Enter your mobile number'),
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
                        title: "Email",
                        hintText: "Enter your email address",
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
                                      'Please enter a valid email address');
                                }

                              },
                              child: CustomText(
                                'Get Verify',
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
                              title: "Home Location",
                              hintText: "E.g. Lucknow, Gomti Nagar...",
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

                                  String city = '';
                                  String state = '';
                                  String postalCode = '';

                                  for (var comp in components) {
                                    final types = comp.types ?? [];
                                    if (types.contains('locality')) {
                                      city = comp.longName ?? '';
                                    } else if (types.contains('administrative_area_level_1')) {
                                      state = comp.longName ?? '';
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
                        title: 'Pincode',
                        fontSize: SizeConfig.small,
                        fontWeight: FontWeight.w400,
                        titleColor: AppColors.mainTextColor,
                        hintText: "E.g. 700045....",
                        keyBoardType: TextInputType.number,
                        inputLength: AppConstants.inputCharterLimit6,
                        validator: ValidationMethod().validatePin,
                      ),
                      SizedBox(height: SizeConfig.paddingM),
                      CommonTextField(
                        textEditController: controller.landmarkCtrl,
                        inputLength: AppConstants.inputCharterLimit30,
                        title: 'House No. and Land Mark ',
                        fontSize: SizeConfig.small,
                        fontWeight: FontWeight.w400,
                        titleColor: AppColors.mainTextColor,
                        hintText: "E.g. Flat 21B, Lake View Apartment....",
                        keyBoardType: TextInputType.text,
                        isValidate: true,
                      ),
                      SizedBox(height: SizeConfig.paddingL),
                      CustomBtn(
                        title: 'Next',
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
                  "Registration Type",
                  fontSize: SizeConfig.small,
                  fontWeight: FontWeight.w400,
                  color: AppColors.mainTextColor,
                ),
                SizedBox(height: SizeConfig.size8),
                CommonDropdown<RentalVehicleRegistrationType>(
                  items: RentalVehicleRegistrationType.values,
                  selectedValue: controller.selectedVehicleRegistrationType.value,
                  hintText: "E.g. Personal, Commercial, Commercial Goods....",
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
                  "Vehicle Type",
                  fontSize: SizeConfig.small,
                  fontWeight: FontWeight.w400,
                  color: AppColors.mainTextColor,
                ),
                SizedBox(height: SizeConfig.size8),
                CommonDropdown<VehicleType>(
                  items: VehicleType.values,
                  selectedValue: controller.selectedVehicleType.value,
                  hintText: "E.g. 'Two Wheeler', Three Wheeler....",
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
                  title: "Vehicle Name",
                  hintText: "E.g. SP125....",
                  textEditController: controller.vehicleNameCtrl,
                  isValidate: true,
                ),
                SizedBox(height: SizeConfig.paddingM),

                /// Fuel Type
                CustomText(
                  "Fuel Type",
                  fontSize: SizeConfig.small,
                  fontWeight: FontWeight.w400,
                  color: AppColors.mainTextColor,
                ),
                SizedBox(height: SizeConfig.size8),
                CommonDropdown<FuelType>(
                  items: FuelType.values,
                  selectedValue: controller.selectedFuelType.value,
                  hintText: "E.g. Petrol, Diesel....",
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
                  title: "Vehicle Number",
                  hintText: "E.g. Wb5454....",
                  textEditController: controller.vehicleRegistrationNumberCtrl,
                  validator: ValidationMethod.validateVehicleNumber,
                  isCapitalize: true,
                  maxLength: 10,
                ),
                SizedBox(height: SizeConfig.paddingM),
                /// Vehicle Model
                CommonTextField(
                  title: "Vehicle Model (Year of Manufacturing)",
                  hintText: "E.g. 2020",
                  keyBoardType: TextInputType.number,
                  textEditController: controller.vehicleModelCtrl,
                  isValidate: true,
                ),
                SizedBox(height: SizeConfig.paddingM),

                if(controller.selectedVehicleRegistrationType != RentalVehicleRegistrationType.CommercialGoods)
                  CommonTextField(
                    title: "Seating Capacity",
                    hintText: "E.g. 10 People....",
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
                            "Load Capacity",
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
                                    "KG",
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
                                    "TON",
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
                        hintText: "E.g. 100KG....",
                        keyBoardType: TextInputType.number,
                        textEditController: controller.loadCapacityCtrl,
                        isValidate: true,
                      )
                    ],
                  ),

                SizedBox(height: SizeConfig.paddingL),
                CustomBtn(
                  title: 'Next',
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
                  title: 'RC Number',
                  fontSize: SizeConfig.small,
                  fontWeight: FontWeight.w400,
                  titleColor: AppColors.mainTextColor,
                  hintText: "E.g. UP32AB12....",
                  keyBoardType: TextInputType.text,
                  validator: ValidationMethod.validateRC,
                  isCapitalize: true,
                  maxLength: 10,
                ),
                SizedBox(height: SizeConfig.paddingM),
                CustomText(
                  'Upload RC (Both Side)',
                  fontSize: SizeConfig.small,
                  color: AppColors.mainTextColor,
                  fontWeight: FontWeight.w400,
                ),
                SizedBox(height: SizeConfig.size8),
                Row(
                  children: [
                    Expanded(
                      child: CommonImageUploadTile(
                        title: 'RC Front',
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
                        title: 'RC Back',
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
                  'Insurance Document Upload',
                  fontSize: SizeConfig.small,
                  color: AppColors.mainTextColor,
                  fontWeight: FontWeight.w400,
                ),
                SizedBox(height: SizeConfig.size8),
                CommonImageUploadTile(
                  title: 'Insurance Document Upload',
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
                  'Pollution Certificate Upload',
                  fontSize: SizeConfig.small,
                  color: AppColors.mainTextColor,
                  fontWeight: FontWeight.w400,
                ),
                SizedBox(height: SizeConfig.size8),
                CommonImageUploadTile(
                  title: 'Pollution Certificate Upload',
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
                  'Fitness Certificate (for commercial use)',
                  fontSize: SizeConfig.small,
                  color: AppColors.mainTextColor,
                  fontWeight: FontWeight.w400,
                ),
                SizedBox(height: SizeConfig.size8),
                CommonImageUploadTile(
                  title: 'Fitness Certificate (for commercial use)',
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
                  title: "Vehicle Condition Description",
                  regularExpression: RegularExpressionUtils.alphabetSpacePattern,
                  hintText: "E.g. Good Condition...",
                  validator: ValidationMethod().validateVehicleDescription,
                  maxLine: 3,
                  maxLength: 200,
                ),

                SizedBox(height: SizeConfig.paddingL),
                CustomBtn(
                  title: 'Next',
                  onTap: controller.nextStep,
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
                      'Charges Type',
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
                            hintText: "E.g. Hourly..",
                            displayValue: (item) => item.label,
                            onChanged: (val) {
                              if (val != null) {
                                controller.selectedChargesTypes.value = val;
                              }
                            },
                              validator: (value){
                                if(value==null){
                                  return 'Please select charges type.';
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
                            hintText: "E.g. ₹2000",
                            keyBoardType: TextInputType.number,
                            isValidate: true,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: SizeConfig.paddingM),
                    CommonLocationSearchField(
                      controller: controller.pickUpLocationCtrl,
                      title: "Pickup Location",
                      hintText: "E.g. Subhas Palli, Gomti Nagar, luckn....",
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
                        title: 'Next',
                        onTap: controller.nextStep,
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
                title: 'Upload Vehicle Number Plate Image',
                maxImages: 1,
                images: controller.vehicleNumberPlateImages,
                onAddImage: () async {
                  multipleImageSectionController.addImages(
                      label: 'Vehicle Number Plate Images',
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
                title: 'Upload Vehicle Right Side Images',
                minImages: 2,
                maxImages: controller.maxVehicleImageUpload,
                images: controller.vehicleRightSideImages,
                onAddImage: () async {
                  multipleImageSectionController.addImages(
                      label: 'Vehicle Right Side Images',
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
                title: 'Upload Vehicle Left Side Images',
                minImages: 2,
                maxImages: controller.maxVehicleImageUpload,
                images: controller.vehicleLeftSideImages,
                onAddImage: () async {
                  multipleImageSectionController.addImages(
                      label: 'Upload Vehicle Left Side Images',
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
                title: 'Upload Vehicle Front and Back Images',
                maxImages: 2,
                images: controller.vehicleFrontImages,
                onAddImage: () async {
                  multipleImageSectionController.addImages(
                      label: 'Vehicle Front and Back Images',
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
                title: 'Upload Vehicle Front and Back Images',
                maxImages: 2,
                images: controller.vehicleBackImages,
                onAddImage: () async {
                  multipleImageSectionController.addImages(
                      label: 'Vehicle Front and Back Images',
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
                  : 'Post Now',
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
              'Home Highlights',
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
                        'Add More',
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
                    'Add Highlights',
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
