import 'package:BlueEra/core/api/model/place_details.dart';
import 'package:BlueEra/core/common_bloc/place/repo/place_repo.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/regular_expression.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/common/delivery_partner/widget/common_multiple_image_upload_section.dart';
import 'package:BlueEra/features/personal/personal_profile/controller/languge_list_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/my_documents/controller/my_documents_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/my_documents/widget/hotel_all_documents.dart';
import 'package:BlueEra/features/personal/personal_profile/view/rental/controller/home_stay_rental_service_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/rental/controller/stay_images_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/rental/widget/add_highlights_widget.dart';
import 'package:BlueEra/features/personal/personal_profile/view/rental/widget/add_more_restriction_widget.dart';
import 'package:BlueEra/features/personal/personal_profile/view/rental/widget/custom_switch_card.dart';
import 'package:BlueEra/features/personal/personal_profile/view/rental/widget/room_images_widget.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:BlueEra/widgets/common_drop_down.dart';
import 'package:BlueEra/widgets/common_location_search_field.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/widgets/time_selection_dropdown.dart';
import 'package:BlueEra/widgets/update_contact_number.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HomeStayRentalService extends StatefulWidget {
  const HomeStayRentalService({super.key});

  @override
  State<HomeStayRentalService> createState() => _HomeStayRentalServiceState();
}

class _HomeStayRentalServiceState extends State<HomeStayRentalService> {
  final controller = getOrPut(() => HomeStayRentalServiceController());
  final langController = getOrPut(() => LanguageListController());
  final multipleImageSectionController = getOrPut(() => CommonMultipleImageSectionController());
  final myDocumentController = getOrPut(() => MyDocumentsController());
  final stayImagesController = getOrPut(() => StayImagesController());

  RxString currentAddress = ''.obs;
  double latitude = 0.0;
  double longitude = 0.0;
  RxBool isFetchingAddressDetails = false.obs;

  @override
  void initState() {
    myDocumentController.fetchAllDocumentStatusApi();
    super.initState();
  }

  @override
  void dispose() {
    deleteIfRegistered<HomeStayRentalServiceController>();
    deleteIfRegistered<StayImagesController>();
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
      child: Scaffold(
        appBar: CommonBackAppBar(
          title: controller.currentStep.value == 0
                       ? AppStrings.homeLocation :
          controller.currentStep.value == 1 ? AppStrings.details : AppStrings.homeImages,
          onBackTap: controller.onBackPressed,
          buildCustomWidget: ()=>
              Obx(() => Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Center(
                  child: Text(
                    "${AppStrings.stepLabel.tr}${controller.currentStep.value + 1}/${controller.totalSteps}",
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              )),
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
              default:
                return const SizedBox(); // fallback (optional)
            }
          }),
        ),
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
      child: Form(
        key: controller.formKeyStep1,
        child: CustomFormCard(
          child: Column(
            children:[
              CommonTextField(
                textEditController: controller.propertyNameCtrl,
                inputLength: AppConstants.inputCharterLimit50,
                keyBoardType: TextInputType.text,
                title: AppStrings.propertyNameWithHouseNo,
                hintText: AppStrings.egTajHotel,
                isValidate: true
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
                      inputLength: AppConstants.inputCharterLimit10,
                      keyBoardType: TextInputType.number,
                      regularExpression:
                      RegularExpressionUtils.digitsPattern,
                      validationType: ValidationTypeEnum.pNumber,
                      hintText: AppStrings.enterMobileNumberHint,
                      hintStyle: TextStyle(
                        fontSize: langController.selectedCode.value == 'ta' ? 12 : 14,
                      ),
                      onTapOutsideTrue: false,
                      validator: (value) {
                        if (value?.length != 10) {
                          return AppStrings.pleaseEnterValidMobileNo.tr;
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: SizeConfig.paddingM),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: CommonLocationSearchField(
                      controller: controller.locationCtrl,
                      title: AppStrings.homeLocation,
                      hintText: AppStrings.propertyLocationHint,
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
                title: AppStrings.landmarkTitle,
                inputLength: AppConstants.inputCharterLimit30,
                fontSize: SizeConfig.small,
                fontWeight: FontWeight.w400,
                titleColor: AppColors.mainTextColor,
                hintText: AppStrings.landmarkHint,
                keyBoardType: TextInputType.text,
                isValidate: true,
              ),
              SizedBox(height: SizeConfig.paddingM),
              CommonTextField(
                textEditController: controller.nearByRailwayCtrl,
                title: AppStrings.nearByRailwayStation,
                fontSize: SizeConfig.small,
                fontWeight: FontWeight.w400,
                titleColor: AppColors.mainTextColor,
                hintText: AppStrings.egGomtinagarRailStation,
                keyBoardType: TextInputType.text,
                isValidate: false,
              ),
              SizedBox(height: SizeConfig.paddingM),
              CommonTextField(
                textEditController: controller.nearByAirportCtrl,
                title: AppStrings.nearByAirport,
                fontSize: SizeConfig.small,
                fontWeight: FontWeight.w400,
                titleColor: AppColors.mainTextColor,
                hintText: AppStrings.egSubhasChandraAirport,
                keyBoardType: TextInputType.text,
                isValidate: false,
              ),
              SizedBox(height: SizeConfig.paddingM),
              CommonTextField(
                textEditController: controller.nearByBusStandCtrl,
                title: AppStrings.nearByBusStand,
                fontSize: SizeConfig.small,
                fontWeight: FontWeight.w400,
                titleColor: AppColors.mainTextColor,
                hintText: AppStrings.egGomtinagarBusStand,
                keyBoardType: TextInputType.text,
                isValidate: false,
              ),
              SizedBox(height: SizeConfig.paddingM),
              CommonTextField(
                textEditController: controller.nearByFamousPlaceCtrl,
                title: AppStrings.nearByFamousPlace,
                fontSize: SizeConfig.small,
                fontWeight: FontWeight.w400,
                titleColor: AppColors.mainTextColor,
                hintText: AppStrings.egDurgaMandir,
                keyBoardType: TextInputType.text,
                isValidate: false,
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
        child: Column(
          children: [
            CustomFormCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [

                    // Check In
                    CustomText(
                      'Check In Time',
                      fontSize: SizeConfig.medium,
                      color: AppColors.mainTextColor,
                      fontWeight: FontWeight.w400,
                    ),
                    SizedBox(height: SizeConfig.size8),
                    TimeSelectionDropdown(
                      selectedHour: controller.checkInHour.value,
                      selectedMinute: controller.checkInMinute.value,
                      selectedPeriod: controller.checkInPeriod.value,
                      onHourChanged: (value) {
                        controller.checkInHour.value = value;
                        controller.updateCheckInTimeController();
                      },
                      onMinuteChanged: (value) {
                        controller.checkInMinute.value = value;
                        controller.updateCheckInTimeController();
                      },
                      onPeriodChanged: (value) {
                        controller.checkInPeriod.value = value;
                        controller.updateCheckInTimeController();
                      },
                    ),
                    SizedBox(height: SizeConfig.paddingM),

                    // Check Out
                    CustomText(
                      'Check Out Time',
                      fontSize: SizeConfig.medium,
                      color: AppColors.mainTextColor,
                      fontWeight: FontWeight.w400,
                    ),
                    SizedBox(height: SizeConfig.size8),
                    TimeSelectionDropdown(
                      selectedHour: controller.checkOutHour.value,
                      selectedMinute: controller.checkOutMinute.value,
                      selectedPeriod: controller.checkOutPeriod.value,
                      onHourChanged: (value) {
                        controller.checkOutHour.value = value;
                        controller.updateCheckOutTimeController();
                      },
                      onMinuteChanged: (value) {
                        controller.checkOutMinute.value = value;
                        controller.updateCheckOutTimeController();
                      },
                      onPeriodChanged: (value) {
                        controller.checkOutPeriod.value = value;
                        controller.updateCheckOutTimeController();
                      },
                    ),
                    SizedBox(height: SizeConfig.paddingM),

                    CustomText(
                      AppStrings.howManyMaxPeople,
                      fontSize: SizeConfig.medium,
                      color: AppColors.mainTextColor,
                      fontWeight: FontWeight.w400,
                    ),
                    SizedBox(height: SizeConfig.size8),
                    Row(
                      children: [
                        // Adult Dropdown
                        Expanded(
                          child: Obx(() => CommonDropdown<String>(
                            items: controller.peopleCountOptions,
                            selectedValue: controller.selectedAdults.value.isEmpty
                                ? null
                                : controller.selectedAdults.value,
                            hintText: AppStrings.adults,
                            displayValue: (item) => item,
                            onChanged: (val) {
                              if (val != null) controller.selectedAdults.value = val;
                            },
                            validator: (value){
                              if(value==null){
                                return 'Please select adult count';
                              }
                              return null;
                            },
                          )),
                        ),

                        SizedBox(width: SizeConfig.size8),

                        // Children Dropdown
                        Expanded(
                          child: Obx(() => CommonDropdown<String>(
                            items: controller.peopleCountOptions,
                            selectedValue: controller.selectedChildren.value.isEmpty
                                ? null
                                : controller.selectedChildren.value,
                            hintText: AppStrings.children,
                            displayValue: (item) => item,
                            onChanged: (val) {
                              if (val != null) controller.selectedChildren.value = val;
                            },
                              validator: (value){
                                if(value==null){
                                  return 'Please select children count';
                                }
                                return null;
                              }
                          )),
                        ),
                      ],
                    ),
                    SizedBox(height: SizeConfig.paddingM),

                    CommonTextField(
                      textEditController: controller.bedsCountCtrl,
                      inputLength: AppConstants.inputCharterLimit6,
                      keyBoardType: TextInputType.number,
                      title: AppStrings.howManyBeds,
                      hintText: AppStrings.eg2Beds,
                      isValidate: true,
                    ),
                    SizedBox(height: SizeConfig.paddingM),

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
                              items: ChargesTypes.values
                                  .where((e) => e != ChargesTypes.KM)
                                  .toList(),
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
                            title: null,
                            fontSize: SizeConfig.small,
                            fontWeight: FontWeight.w400,
                            titleColor: AppColors.mainTextColor,
                            hintText: AppStrings.egRs2000,
                            keyBoardType: TextInputType.number,
                            isValidate: true,
                            inputLength: AppConstants.inputCharterLimit10,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: SizeConfig.paddingM),

                    _buildAddHighlightsSection(),

                    SizedBox(height: SizeConfig.paddingM),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        CustomText(
                          AppStrings.homeStayDescription,
                          fontSize: SizeConfig.medium,
                          color: AppColors.mainTextColor,
                          fontWeight: FontWeight.w400,
                        ),
                        Obx(()=> !controller.isGenerateHomeRentalServiceLoading.value
                            ? InkWell(
                          onTap: (){
                            controller.generateHomeDescriptionApi();
                          },
                          child: CustomText(
                            AppStrings.createViaBEai,
                            fontSize: SizeConfig.medium,
                            color: AppColors.primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        )
                            : SizedBox(
                            height: 15,
                            width: 15,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.0,
                            ))
                         )

                      ],
                    ),

                    SizedBox(height: SizeConfig.size8),

                    CommonTextField(
                      maxLine: 4,
                      textEditController: controller.descriptionCtrl,
                      inputLength: AppConstants.inputCharterLimit200,
                      keyBoardType: TextInputType.text,
                      regularExpression: RegularExpressionUtils.alphabetSpacePattern,
                      hintText: AppStrings.eg2BhkSwimming,
                      validator: ValidationMethod().validateHomeStayDescription,
                    ),

                  ],
                )
            ),

            SizedBox(height: SizeConfig.paddingM),

            CustomFormCard(
                child: Column(
                  children: [

                    _buildRestrictionWidget(),

                    SizedBox(height: SizeConfig.paddingL),

                    CustomBtn(
                      title: AppStrings.nextButton,
                      onTap: controller.validateStepTwo,
                      radius: 10.0,
                      bgColor: AppColors.primaryColor,
                    ),
                  ],
                )
            )

          ],
        ),
      ),
    );
  }

  // // ---------------- STEP 3 ----------------
  // Widget _buildStepThree(){
  //   return AbsorbPointer(
  //     absorbing: controller.isHomeStayRentalServiceLoading.value,
  //     child: SingleChildScrollView(
  //       padding: EdgeInsets.all(SizeConfig.size15),
  //       child:  Column(
  //         children: [
  //           /// roomImageId
  //           GetBuilder<CommonMultipleImageSectionController>(
  //             id: CommonMultipleImageSectionController.roomImageId,
  //             builder: (ctrl) => CommonMultipleImageUploadSection(
  //               title: AppStrings.uploadRoomImages,
  //               minImages: controller.maxHomeImageUpload,
  //               maxImages: controller.maxHomeImageUpload,
  //               images: controller.roomImages,
  //               onAddImage: () async {
  //                 multipleImageSectionController.addImages(
  //                   label: AppStrings.roomsImagesLabel,
  //                   imageList: controller.roomImages,
  //                   updateId: CommonMultipleImageSectionController.roomImageId,
  //                   maxUploadImages: controller.maxHomeImageUpload,
  //                 );
  //               },
  //               onRemoveImage: (index) {
  //                 multipleImageSectionController.removeImageAt(
  //                   imageList: controller.roomImages,
  //                   index: index,
  //                   updateId: CommonMultipleImageSectionController.roomImageId,
  //                 );
  //               },
  //             ),
  //           ),
  //           SizedBox(height: SizeConfig.paddingM),
  //
  //           /// kitchenImages
  //           GetBuilder<CommonMultipleImageSectionController>(
  //             id: CommonMultipleImageSectionController.kitchenImageId,
  //             builder: (ctrl) => CommonMultipleImageUploadSection(
  //               title: AppStrings.uploadKitchenImages,
  //               minImages: 2,
  //               maxImages: controller.maxHomeImageUpload,
  //               images: controller.kitchenImages,
  //               onAddImage: () async {
  //                 multipleImageSectionController.addImages(
  //                     label: AppStrings.kitchenImagesLabel,
  //                     imageList: controller.kitchenImages,
  //                     updateId: CommonMultipleImageSectionController.kitchenImageId,
  //                     maxUploadImages: controller.maxHomeImageUpload
  //                 );
  //               },
  //               onRemoveImage: (index) {
  //                 multipleImageSectionController.removeImageAt(
  //                   imageList: controller.kitchenImages,
  //                   index: index,
  //                   updateId: CommonMultipleImageSectionController.kitchenImageId,
  //                 );
  //               },
  //             ),
  //           ),
  //           SizedBox(height: SizeConfig.paddingM),
  //
  //           /// bathroomImages
  //           GetBuilder<CommonMultipleImageSectionController>(
  //             id: CommonMultipleImageSectionController.bathroomImageId,
  //             builder: (ctrl) => CommonMultipleImageUploadSection(
  //               title: AppStrings.uploadBathroomImages,
  //               minImages: 2,
  //               maxImages: controller.maxHomeImageUpload,
  //               images: controller.bathroomImages,
  //               onAddImage: () async {
  //                 multipleImageSectionController.addImages(
  //                     label: AppStrings.bathroomImagesLabel,
  //                     imageList: controller.bathroomImages,
  //                     updateId: CommonMultipleImageSectionController.bathroomImageId,
  //                     maxUploadImages: controller.maxHomeImageUpload
  //                 );
  //               },
  //               onRemoveImage: (index) {
  //                 multipleImageSectionController.removeImageAt(
  //                   imageList: controller.bathroomImages,
  //                   index: index,
  //                   updateId: CommonMultipleImageSectionController.bathroomImageId,
  //                 );
  //               },
  //             ),
  //           ),
  //
  //           SizedBox(height: SizeConfig.paddingL),
  //
  //           CustomBtn(
  //             // title: controller.isRiderVehicleImagesLoading.value
  //             //     ? null
  //             //     : 'Next',
  //             title: AppStrings.nextButton,
  //             onTap: controller.validateStepThree,
  //             radius: 10.0,
  //             bgColor: AppColors.primaryColor,
  //             // isLoading: controller.isRiderVehicleImagesLoading.value,
  //           )
  //         ],
  //       ),
  //     ),
  //   );
  // }

  // ---------------- STEP 3 ----------------

  Widget _buildStepThree(){
    return AbsorbPointer(
     absorbing: controller.isHomeStayRentalServiceLoading.value,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(SizeConfig.size15),
        child: Column(
          children: [
            HotelAllDocumentsScreen(
              controller: myDocumentController,
            ),
            SizedBox(height: SizeConfig.paddingL),
            CustomBtn(
              // title: controller.isRiderVehicleImagesLoading.value
              //     ? null
              //     : 'Next',
              title: AppStrings.nextButton,
              onTap: controller.validateStepThree,
              radius: 10.0,
              bgColor: AppColors.primaryColor,
              // isLoading: controller.isRiderVehicleImagesLoading.value,
            )
          ],
        ),
      ),
    );
  }

  // ---------------- STEP 4 ----------------
  Widget _buildStepFour(){
    return SingleChildScrollView(
      padding: EdgeInsets.all(SizeConfig.size15),
      child: Column(
        children: [

          roomImagesWidget(
               controller: stayImagesController,
              multipleImageSectionController: multipleImageSectionController
          ),

          SizedBox(height: SizeConfig.paddingL),

          CustomBtn(
            title: controller.isHomeStayRentalServiceLoading.value
                ? null
                : AppStrings.postNowButton,
            onTap: controller.validateStepFour,
            radius: 10.0,
            bgColor: AppColors.primaryColor,
            isLoading: controller.isHomeStayRentalServiceLoading.value,
          )
        ],
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

  Widget _buildRestrictionWidget() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CommonSwitchCard(
          title: AppStrings.doYouAllowUnmarriedCouples,
          value: controller.isUnMarried.value,
          onChanged: (val) {
            controller.isUnMarried.value = val;
          },
        ),

        SizedBox(height: SizeConfig.paddingXSL),

        CommonSwitchCard(
          title: AppStrings.areYouAllowBachelorOrStudent,
          value: controller.isAllowStudentOrBachelor.value,
          onChanged: (val) {
            controller.isAllowStudentOrBachelor.value = val;
          },
        ),

        SizedBox(height: SizeConfig.paddingXSL),

        CommonSwitchCard(
          title:  AppStrings.anyFoodHabitRestrictions,
          value: controller.anyFoodHabitRestriction.value,
          onChanged: (val) {
            controller.anyFoodHabitRestriction.value = val;
          },
        ),

        SizedBox(height: SizeConfig.paddingL),

        _buildAddMoreRestrictionsSection()
      ],
    );
  }

  Widget _buildAddMoreRestrictionsSection() {
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
                AppStrings.addMoreRestrictions,
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
