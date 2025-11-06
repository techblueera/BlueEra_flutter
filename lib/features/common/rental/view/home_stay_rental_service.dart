import 'package:BlueEra/core/api/model/place_details.dart';
import 'package:BlueEra/core/common_bloc/place/repo/place_repo.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/regular_expression.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/common/delivery_partner/widget/common_multiple_image_upload_section.dart';
import 'package:BlueEra/features/common/rental/controller/home_stay_rental_service_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/controller/languge_list_controller.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:BlueEra/widgets/common_drop_down.dart';
import 'package:BlueEra/widgets/common_location_search_field.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_switch_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/widgets/update_contact_number.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HomeStayRentalService extends StatefulWidget {
  const HomeStayRentalService({super.key});

  @override
  State<HomeStayRentalService> createState() => _HomeStayRentalServiceState();
}

class _HomeStayRentalServiceState extends State<HomeStayRentalService> {
  final controller = Get.put(HomeStayRentalServiceController());
  final langController = Get.put(LanguageListController());
  final multipleImageSectionController = Get.put(CommonMultipleImageSectionController());

  final locationCtrl = TextEditingController();
  final landmarkCtrl = TextEditingController();
  final pinCodeCtrl = TextEditingController();

  RxString currentAddress = ''.obs;
  double latitude = 0.0;
  double longitude = 0.0;
  RxBool isFetchingAddressDetails = false.obs;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    Get.delete<HomeStayRentalServiceController>();
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
                       ? "Home Location" :
          controller.currentStep.value == 1 ? "Details" : "Home Images",
          onBackTap: controller.previousStep,
          buildCustomWidget: ()=>
              Obx(() => Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Center(
                  child: Text(
                    "Step-${controller.currentStep.value + 1}/${controller.totalSteps}",
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              )),
        ),
        body: Obx(() {
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
                maxLine: 3,
                textEditController: controller.propertyNameCtrl,
                inputLength: AppConstants.inputCharterLimit50,
                keyBoardType: TextInputType.text,
                title: "Property Name With House No.",
                regularExpression: RegularExpressionUtils.alphabetSpacePattern,
                hintText: "E.g. Taj Hotel...",
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
                      ),                          onTapOutsideTrue: false,
                      validator: (value) {
                        if (value?.length != 10) {
                          return langController.tr('Please enter valid mobile number');
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
                // readOnly: true,
                title: 'Pincode',
                fontSize: SizeConfig.small,
                fontWeight: FontWeight.w400,
                titleColor: AppColors.mainTextColor,
                hintText: "E.g. 700045....",
                keyBoardType: TextInputType.text,
                isValidate: true,
              ),
              SizedBox(height: SizeConfig.paddingM),
              CommonTextField(
                textEditController: controller.landmarkCtrl,
                title: 'House No. and Land Mark ',
                fontSize: SizeConfig.small,
                fontWeight: FontWeight.w400,
                titleColor: AppColors.mainTextColor,
                hintText: "E.g. Flat 21B, Lake View Apartment....",
                keyBoardType: TextInputType.text,
                isValidate: true,
              ),
              SizedBox(height: SizeConfig.paddingM),
              CommonTextField(
                textEditController: controller.pinCodeCtrl,
                title: 'Near By Railway Station',
                fontSize: SizeConfig.small,
                fontWeight: FontWeight.w400,
                titleColor: AppColors.mainTextColor,
                hintText: "E.g. 700045....",
                keyBoardType: TextInputType.text,
                isValidate: true,
              ),
              SizedBox(height: SizeConfig.paddingM),
              CommonTextField(
                textEditController: controller.nearByRailwayCtrl,
                title: 'Near By Railway Station',
                fontSize: SizeConfig.small,
                fontWeight: FontWeight.w400,
                titleColor: AppColors.mainTextColor,
                hintText: "E.g. Gomtinagar Rail Station ....",
                keyBoardType: TextInputType.text,
                isValidate: true,
              ),
              SizedBox(height: SizeConfig.paddingM),
              CommonTextField(
                textEditController: controller.nearByAirportCtrl,
                title: 'Near By Airport',
                fontSize: SizeConfig.small,
                fontWeight: FontWeight.w400,
                titleColor: AppColors.mainTextColor,
                hintText: "E.g. Subhas Chandra Airport ....",
                keyBoardType: TextInputType.text,
                isValidate: true,
              ),
              SizedBox(height: SizeConfig.paddingM),
              CommonTextField(
                textEditController: controller.nearByBusStandCtrl,
                title: 'Near By Bus Stand',
                fontSize: SizeConfig.small,
                fontWeight: FontWeight.w400,
                titleColor: AppColors.mainTextColor,
                hintText: "E.g. Gomtinagar Bus Stand....",
                keyBoardType: TextInputType.text,
                isValidate: true,
              ),
              SizedBox(height: SizeConfig.paddingM),
              CommonTextField(
                textEditController: controller.nearByFamousPlaceCtrl,
                // readOnly: true,
                title: 'Near By Famous Place',
                fontSize: SizeConfig.small,
                fontWeight: FontWeight.w400,
                titleColor: AppColors.mainTextColor,
                hintText: "E.g. Durga mandir ....",
                keyBoardType: TextInputType.text,
                isValidate: true,
              ),
              SizedBox(height: SizeConfig.paddingL),
              CustomBtn(
                title: 'Next',
                onTap: controller.nextStep,
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
      child: Column(
        children: [
          CustomFormCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CustomText(
                        'Home Stay Description',
                        fontSize: SizeConfig.medium,
                        color: AppColors.mainTextColor,
                        fontWeight: FontWeight.w400,
                      ),
                      CustomText(
                        'Create Via BE ai',
                        fontSize: SizeConfig.medium,
                        color: AppColors.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ],
                  ),
                  SizedBox(height: SizeConfig.size8),

                  CommonTextField(
                    maxLine: 3,
                    textEditController: controller.descriptionCtrl,
                    inputLength: AppConstants.inputCharterLimit200,
                    keyBoardType: TextInputType.text,
                    regularExpression: RegularExpressionUtils.alphabetSpacePattern,
                    hintText: "E.g. 2BHK with swimming pool...",
                    isValidate: true,
                  ),

                  SizedBox(height: SizeConfig.paddingM),

                  CustomText(
                    'How many maximum people can stay here?',
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
                          hintText: "Adults",
                          displayValue: (item) => item,
                          onChanged: (val) {
                            if (val != null) controller.selectedAdults.value = val;
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
                          hintText: "Children",
                          displayValue: (item) => item,
                          onChanged: (val) {
                            if (val != null) controller.selectedChildren.value = val;
                          },
                        )),
                      ),
                    ],
                  ),
                  SizedBox(height: SizeConfig.paddingM),

                  CommonTextField(
                    textEditController: controller.bedsCountCtrl,
                    inputLength: AppConstants.inputCharterLimit200,
                    keyBoardType: TextInputType.number,
                    title: "How many beds will be there?",
                    hintText: "E.g. 2 Beds",
                    isValidate: true,
                  ),
                  SizedBox(height: SizeConfig.paddingM),

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
                          hintText: "E.g. ₹2000",
                          keyBoardType: TextInputType.number,
                          isValidate: true,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: SizeConfig.paddingM),
                  _buildHighlightsSection(),
                ],
              )
          ),

          SizedBox(height: SizeConfig.paddingM),

          CustomFormCard(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start  ,
                    children: [
                      const LocalAssets(
                        imagePath: AppIconAssets.addBlueIcon,
                      ),
                      CustomText(
                        'Add Restrictions',
                        fontSize: SizeConfig.large,
                        fontWeight: FontWeight.w400,
                        color: AppColors.primaryColor,
                      ),

                    ],
                  ),
                  SizedBox(height: SizeConfig.paddingM),

                  Container(
                    padding: EdgeInsets.all(SizeConfig.size15),
                    decoration: BoxDecoration(
                        color: AppColors.whiteFE,
                        borderRadius: BorderRadius.circular(10.0),
                        border: Border.all(
                            color: AppColors.whiteE5
                        ),
                        boxShadow: [AppShadows.textFieldShadow]
                    ),
                    child:  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        CustomText(
                          'Are You Allow Un-Married Couple',
                          fontSize: SizeConfig.medium,
                          color: AppColors.secondaryTextColor,
                          fontWeight: FontWeight.w400,
                        ),
                        CustomSwitch(
                          value: controller.isUnMarried.value,
                          onChanged: (val) {
                            controller.isUnMarried.value = !controller.isUnMarried.value;
                          },
                          containerHeight: SizeConfig.size24,
                          containerWidth: SizeConfig.size50,
                          circleSize: SizeConfig.size18,
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: SizeConfig.paddingL),

                  CustomBtn(
                    title: 'Next',
                    onTap: controller.nextStep,
                    radius: 10.0,
                    bgColor: AppColors.primaryColor,
                  ),
                ],
              )
          )


        ],
      ),
    );
  }

  // ---------------- STEP 3 ----------------
  Widget _buildStepThree(){
    return SingleChildScrollView(
      padding: EdgeInsets.all(SizeConfig.size15),
      child:  Column(
        children: [
          /// roomImageId
          GetBuilder<HomeStayRentalServiceController>(
            id: HomeStayRentalServiceController.roomImageId,
            builder: (ctrl) => CommonMultipleImageUploadSection(
              title: 'Upload Rooms Images',
              minImages: ctrl.maxHomeImageUpload,
              maxImages: ctrl.maxHomeImageUpload,
              images: ctrl.roomImages,
              onAddImage: () async {
                multipleImageSectionController.addImages(
                  label: 'Rooms Images',
                  imageList: ctrl.roomImages,
                  updateId: HomeStayRentalServiceController.roomImageId,
                  maxUploadImages: ctrl.maxHomeImageUpload,
                );
              },
              onRemoveImage: (index) {
                multipleImageSectionController.removeImageAt(
                  imageList: ctrl.roomImages,
                  index: index,
                  updateId: HomeStayRentalServiceController.roomImageId,
                );
              },
            ),
          ),
          SizedBox(height: SizeConfig.paddingM),

          /// kitchenImages
          GetBuilder<HomeStayRentalServiceController>(
            id: HomeStayRentalServiceController.kitchenImageId,
            builder: (ctrl) => CommonMultipleImageUploadSection(
              title: 'Upload Kitchen Images',
              minImages: 2,
              maxImages: ctrl.maxHomeImageUpload,
              images: ctrl.kitchenImages,
              onAddImage: () async {
                multipleImageSectionController.addImages(
                    label: 'Kitchen Images',
                    imageList: ctrl.kitchenImages,
                    updateId: HomeStayRentalServiceController.kitchenImageId,
                    maxUploadImages: controller.maxHomeImageUpload
                );
              },
              onRemoveImage: (index) {
                multipleImageSectionController.removeImageAt(
                  imageList: ctrl.kitchenImages,
                  index: index,
                  updateId: HomeStayRentalServiceController.kitchenImageId,
                );
              },
            ),
          ),
          SizedBox(height: SizeConfig.paddingM),

          /// bathroomImages
          GetBuilder<HomeStayRentalServiceController>(
            id: HomeStayRentalServiceController.bathroomImageId,
            builder: (ctrl) => CommonMultipleImageUploadSection(
              title: 'Upload Bathroom Images',
              minImages: 2,
              maxImages: controller.maxHomeImageUpload,
              images: ctrl.bathroomImages,
              onAddImage: () async {
                multipleImageSectionController.addImages(
                    label: 'Bathroom Images',
                    imageList: ctrl.bathroomImages,
                    updateId: HomeStayRentalServiceController.bathroomImageId,
                    maxUploadImages: controller.maxHomeImageUpload
                );
              },
              onRemoveImage: (index) {
                multipleImageSectionController.removeImageAt(
                  imageList: ctrl.bathroomImages,
                  index: index,
                  updateId: HomeStayRentalServiceController.bathroomImageId,
                );
              },
            ),
          ),

          SizedBox(height: SizeConfig.paddingL),

          CustomBtn(
            // title: controller.isRiderVehicleImagesLoading.value
            //     ? null
            //     : 'Next',
            title: 'Next',
            onTap: controller.nextStep,
            radius: 10.0,
            bgColor: AppColors.primaryColor,
            // isLoading: controller.isRiderVehicleImagesLoading.value,
          )
        ],
      ),
    );
  }

  // ---------------- STEP 4 ----------------
  Widget _buildStepFour(){
    return SingleChildScrollView(
      padding: EdgeInsets.all(SizeConfig.size15),
      child: Column(
        children: [
          /// roadSideImages
          GetBuilder<HomeStayRentalServiceController>(
            id: HomeStayRentalServiceController.roadSideImageId,
            builder: (ctrl) => CommonMultipleImageUploadSection(
              title: 'Upload Road Side Images',
              minImages: 2,
              maxImages: ctrl.maxHomeImageUpload,
              images: ctrl.roadSideImages,
              onAddImage: () async {
                multipleImageSectionController.addImages(
                  label: 'Road Side Images',
                  imageList: ctrl.roadSideImages,
                  updateId: HomeStayRentalServiceController.roadSideImageId,
                  maxUploadImages: ctrl.maxHomeImageUpload,
                );
              },
              onRemoveImage: (index) {
                multipleImageSectionController.removeImageAt(
                  imageList: ctrl.roadSideImages,
                  index: index,
                  updateId: HomeStayRentalServiceController.roadSideImageId,
                );
              },
            ),
          ),
          SizedBox(height: SizeConfig.paddingM),

          /// otherImages
          GetBuilder<HomeStayRentalServiceController>(
            id: HomeStayRentalServiceController.otherImageId,
            builder: (ctrl) => CommonMultipleImageUploadSection(
              title: 'Upload Other Images (Optional)',
              maxImages: ctrl.maxHomeImageUpload,
              images: ctrl.otherImages,
              onAddImage: () async {
                multipleImageSectionController.addImages(
                    label: 'Kitchen Images',
                    imageList: ctrl.otherImages,
                    updateId: HomeStayRentalServiceController.otherImageId,
                    maxUploadImages: controller.maxHomeImageUpload
                );
              },
              onRemoveImage: (index) {
                multipleImageSectionController.removeImageAt(
                  imageList: ctrl.otherImages,
                  index: index,
                  updateId: HomeStayRentalServiceController.otherImageId,
                );
              },
            ),
          ),

          SizedBox(height: SizeConfig.paddingL),

          CustomBtn(
            // title: controller.isRiderVehicleImagesLoading.value
            //     ? null
            //     : 'Next',
            title: 'Post Now',
            onTap: controller.nextStep,
            radius: 10.0,
            bgColor: AppColors.primaryColor,
            // isLoading: controller.isRiderVehicleImagesLoading.value,
          )
        ],
      ),
    );
  }

  Widget _buildHighlightsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(
          'Property Highlights',
          fontSize: SizeConfig.medium,
          color: AppColors.mainTextColor,
          fontWeight: FontWeight.w400,
        ),
        SizedBox(height: SizeConfig.size8),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: SizeConfig.size16,
            vertical: SizeConfig.size10,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.greyE5, width: 1),
          ),
          child: Row(
            children: [
              LocalAssets(imagePath: AppIconAssets.tagIcon),
              SizedBox(width: SizeConfig.size12),
              Expanded(
                child: TextField(
                  controller: controller.highlights,
                  onChanged: (_) => controller.update(["addHighlight"]),
                  decoration: const InputDecoration(
                    hintText: 'Add Highlights',
                    hintStyle: TextStyle(
                      color: AppColors.grey9B,
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    isDense: true,

                  ),
                ),
              ),
              GetBuilder<HomeStayRentalServiceController>(
                id: "addHighlight",
                builder: (_) {
                  return AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    transitionBuilder: (child, anim) =>
                        ScaleTransition(scale: anim, child: child),
                    child: controller.highlights.text.isNotEmpty
                        ? InkWell(
                      key: const ValueKey("add"),
                      onTap: () {
                        controller.addHighlights();
                        controller.update(["addHighlight"]);
                        unFocus();
                      },
                      child: LocalAssets(
                        imagePath: AppIconAssets.addBlueIcon,
                        // imgColor: AppColors.grey9A
                      ),
                    )
                        : const SizedBox.shrink(key: ValueKey("empty")),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Obx(()=> Wrap(
          spacing: 8,
          runSpacing: 8,
          children: controller.arrHighlights.map((h) {
            return Chip(
              label: Text(h),
              backgroundColor: AppColors.lightBlue,
              labelStyle: TextStyle(
                  fontSize: SizeConfig.size14,
                  color: Colors.black87
              ),
              deleteIcon: const Icon(Icons.close,
                  size: 20, color: AppColors.mainTextColor),
              shape: RoundedRectangleBorder(
                  side: BorderSide(color: Colors.transparent),
                  borderRadius: BorderRadius.circular(8.0)),
              onDeleted: () => controller.removeHighlights(h),
              labelPadding: const EdgeInsets.only(left: 12),
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            );
          }).toList(),
        ))
      ],
    );
  }

}
