import 'dart:developer';

import 'package:BlueEra/core/api/model/place_details.dart';
import 'package:BlueEra/core/common_bloc/place/repo/place_repo.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/regular_expression.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/routes/route_constant.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/common/delivery_partner/widget/common_multiple_image_upload_section.dart';
import 'package:BlueEra/features/personal/personal_profile/controller/languge_list_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/widget/add_more_details_dialog.dart';
import 'package:BlueEra/features/personal/personal_profile/view/rental/controller/add_flat_rental_service_controller.dart';
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
import 'package:BlueEra/widgets/custom_switch_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/widgets/time_selection_dropdown.dart';
import 'package:BlueEra/widgets/update_contact_number.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AddFlatRoomRentalServiceScreen extends StatefulWidget {
  const AddFlatRoomRentalServiceScreen({Key? key}) : super(key: key);

  @override
  State<AddFlatRoomRentalServiceScreen> createState() => _AddFlatRoomRentalServiceScreenState();
}

class _AddFlatRoomRentalServiceScreenState extends State<AddFlatRoomRentalServiceScreen> {
  final controller = getOrPut(() => AddFlatRentalServiceController());
  final langController = getOrPut(() => LanguageListController());
  final multipleImageSectionController = getOrPut(() => CommonMultipleImageSectionController());
  final stayImagesController = getOrPut(() => StayImagesController());

  @override
  void initState() {
    controller.mobile.text = userMobileGlobal;
    super.initState();
  }

  @override
  void dispose() {
    deleteIfRegistered<AddFlatRentalServiceController>();
    deleteIfRegistered<StayImagesController>();
    super.dispose();
  }

  Future<void> showAddMoreDetailsDialog(BuildContext context) async {
    if(controller.arrMoreDetails.length==5){
      commonSnackBar(message: AppStrings.maxDetailsReached.tr);
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => const AddMoreDetailsDialog(
          fromScreen: RouteConstant.addFlatRoomRentalServiceScreen
      ),
    );

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
          title: AppStrings.flatRoomTitle,
          onBackTap: controller.onBackPressed,
          buildCustomActionWidget: ()=>
            Obx(() => Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  "${AppStrings.stepLabel.tr}${controller.currentStep.value + 1}/2",
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            )),
        ),
        body: SafeArea(
          child: Obx(() {
            return controller.currentStep.value == 0
                ? _buildStepOne()
                : _buildStepTwo();
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
        child: Column(
          children: [
            CustomFormCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CommonTextField(
                    textEditController: controller.propertyName,
                    inputLength: AppConstants.inputCharterLimit50,
                    keyBoardType: TextInputType.text,
                    title: AppStrings.propertyNameTitle,
                    hintText: AppStrings.propertyNameHint,
                    isValidate: true,
                  ),
                  SizedBox(height: SizeConfig.paddingM),
                  CommonTextField(
                    textEditController: controller.landmark,
                    title: AppStrings.landmarkTitle,
                    fontSize: SizeConfig.small,
                    fontWeight: FontWeight.w400,
                    titleColor: AppColors.mainTextColor,
                    hintText: AppStrings.landmarkHint,
                    keyBoardType: TextInputType.text,
                    isValidate: true,
                    inputLength: AppConstants.inputCharterLimit30,
                  ),
                  SizedBox(height: SizeConfig.paddingM),
                  Row(
                    children: [
                      Expanded(
                        child: CommonLocationSearchField(
                          controller: controller.location,
                          title: AppStrings.propertyLocationTitle,
                          hintText: AppStrings.propertyLocationHint,
                          onSelected: (placeId, lat, lng, address) async {
                            print("PlaceId: $placeId Selected: $address → ($lat, $lng)");
                            controller.location.text = address;
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

                              controller.pinCode.text = postalCode;

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
                    textEditController: controller.pinCode,
                    title: AppStrings.pincodeTitle,
                    fontSize: SizeConfig.small,
                    fontWeight: FontWeight.w400,
                    titleColor: AppColors.mainTextColor,
                    hintText: AppStrings.pincodeHint,
                    keyBoardType: TextInputType.number,
                    validator: ValidationMethod().validatePin,
                    maxLength: 6,
                  ),
                  SizedBox(height: SizeConfig.paddingM),
                  CommonTextField(
                    textEditController: controller.description,
                    title: AppStrings.propertyDescriptionTitle,
                    fontSize: SizeConfig.small,
                    fontWeight: FontWeight.w400,
                    titleColor: AppColors.mainTextColor,
                    maxLine: 4,
                    inputLength: AppConstants.inputCharterLimit200,
                    hintText: AppStrings.eg2BhkSwimming,
                    keyBoardType: TextInputType.text,
                    validator: ValidationMethod().validatePropertyDescription,
                  ),
                  SizedBox(height: SizeConfig.paddingM),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CustomText(
                        AppStrings.contactNumberTitle,
                        fontSize: SizeConfig.small,
                        fontWeight: FontWeight.w400,
                        color: AppColors.mainTextColor,
                      ),
                      InkWell(
                        onTap: () async {
                          final result = await CommonMobileOtpDialog().show(context);

                          if (result == true) {
                            //  OTP successfully verified
                            log("OTP verification successful");
                          } else {
                            // Either cancelled or verification failed
                            log("OTP verification failed or cancelled");
                          }

                        },
                        child: CustomText(
                          AppStrings.editLabel,
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
                          textEditController: controller.mobile,
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

                  // Charges Type
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
                          textEditController: controller.charge,
                          title: null,
                          fontSize: SizeConfig.small,
                          fontWeight: FontWeight.w400,
                          titleColor: AppColors.mainTextColor,
                          hintText: AppStrings.chargesAmountHint,
                          keyBoardType: TextInputType.number,
                          isValidate: true,
                          inputLength: AppConstants.inputCharterLimit10,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: SizeConfig.paddingM),

                  _buildAddHighlightsSection()

                ],
              ),
            ),

            SizedBox(height: SizeConfig.paddingM),

            CustomFormCard(
                child: Column(
                  children: [
                    _buildRestrictionWidget(),
                    SizedBox(height: SizeConfig.paddingL),
                    _buildAddMoreDetails(),
                    SizedBox(height: SizeConfig.paddingL),
                    CustomBtn(
                        title: controller.isAddFlatRentalServiceLoading.value
                            ? null
                            : AppStrings.postNowButton,
                      // onTap: controller.addFlatRentalServiceApi,
                      onTap: (controller.rentalId == null)
                          ? controller.addFlatRentalServiceApi
                          : controller.updateFlatRentalServiceApi,
                      radius: 10.0,
                      bgColor: AppColors.primaryColor,
                      isLoading: controller.isAddFlatRentalServiceLoading.value
                    ),
                  ],
                )
            )
          ],
        ),
      ),
    );
  }

  // ---------------- STEP 2 ----------------
  Widget  _buildStepTwo() {
    return AbsorbPointer(
      absorbing: controller.isAddFlatRentalServiceLoading.value,
      child: ListView(
        padding: EdgeInsets.only(
          left: SizeConfig.size15,
          right: SizeConfig.size15,
          top: SizeConfig.size15,
          bottom: SizeConfig.size40,
        ),
        children: [

          roomImagesWidget(
              rentalId: controller.rentalId??'',
              controller: stayImagesController,
              multipleImageSectionController: multipleImageSectionController
          ),

          SizedBox(height: SizeConfig.paddingL),


          CustomBtn(
            title: controller.isAddFlatRentalServiceLoading.value
                ? null
                : AppStrings.postNowButton,
            onTap: ()=> controller.validateStepFour(stayImagesController),
            radius: 10.0,
            bgColor: AppColors.primaryColor,
            isLoading: controller.isAddFlatRentalServiceLoading.value,
          ),
        ],
      ),
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
        // Container(
        //   padding: EdgeInsets.all(SizeConfig.size12),
        //   decoration: BoxDecoration(
        //       color: AppColors.whiteFE,
        //       borderRadius: BorderRadius.circular(10.0),
        //       border: Border.all(
        //           color: AppColors.whiteE5
        //       ),
        //       boxShadow: [AppShadows.textFieldShadow]
        //   ),
        //   child:  Row(
        //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
        //     children: [
        //       CustomText(
        //         AppStrings.doYouAllowUnmarriedCouples,
        //         fontSize: SizeConfig.medium,
        //         color: AppColors.secondaryTextColor,
        //         fontWeight: FontWeight.w400,
        //       ),
        //       CustomSwitch(
        //         value: controller.isUnMarried.value,
        //         onChanged: (val) {
        //           controller.isUnMarried.value = !controller.isUnMarried.value;
        //         },
        //         containerHeight: SizeConfig.size24,
        //         containerWidth: SizeConfig.size50,
        //         circleSize: SizeConfig.size18,
        //       ),
        //     ],
        //   ),
        // ),

        SizedBox(height: SizeConfig.paddingXSL),

        CommonSwitchCard(
          title: AppStrings.areYouAllowBachelorOrStudent,
          value: controller.isAllowStudentOrBachelor.value,
          onChanged: (val) {
            controller.isAllowStudentOrBachelor.value = val;
          },
        ),
        // Container(
        //   padding: EdgeInsets.all(SizeConfig.size12),
        //   decoration: BoxDecoration(
        //       color: AppColors.whiteFE,
        //       borderRadius: BorderRadius.circular(10.0),
        //       border: Border.all(
        //           color: AppColors.whiteE5
        //       ),
        //       boxShadow: [AppShadows.textFieldShadow]
        //   ),
        //   child: Row(
        //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
        //     children: [
        //       CustomText(
        //         AppStrings.areYouAllowBachelorOrStudent,
        //         fontSize: SizeConfig.medium,
        //         color: AppColors.secondaryTextColor,
        //         fontWeight: FontWeight.w400,
        //       ),
        //       CustomSwitch(
        //         value: controller.isAllowStudentOrBachelor.value,
        //         onChanged: (val) {
        //           controller.isAllowStudentOrBachelor.value = !controller.isAllowStudentOrBachelor.value;
        //         },
        //         containerHeight: SizeConfig.size24,
        //         containerWidth: SizeConfig.size50,
        //         circleSize: SizeConfig.size18,
        //       ),
        //     ],
        //   ),
        // ),

        SizedBox(height: SizeConfig.paddingXSL),

        // CommonSwitchCard(
        //   title:  AppStrings.anyFoodHabitRestrictions,
        //   value: controller.anyFoodHabitRestriction.value,
        //   onChanged: (val) {
        //     controller.anyFoodHabitRestriction.value = val;
        //   },
        // ),

        Container(
          decoration: BoxDecoration(
              color: AppColors.whiteFE,
              borderRadius: BorderRadius.circular(10.0),
              border: Border.all(
                  color: AppColors.whiteE5
              ),
              boxShadow: [AppShadows.textFieldShadow]
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(
                  left: SizeConfig.size12,
                  right: SizeConfig.size12,
                  top: SizeConfig.size12,
                  bottom: SizeConfig.size12,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CustomText(
                      AppStrings.anyFoodHabitRestrictions,
                      fontSize: SizeConfig.medium,
                      color: AppColors.secondaryTextColor,
                      fontWeight: FontWeight.w400,
                    ),
                    CustomSwitch(
                      value: controller.anyFoodHabitRestriction.value,
                      onChanged: (val) {
                        controller.anyFoodHabitRestriction.value = !controller.anyFoodHabitRestriction.value;
                      },
                      containerHeight: SizeConfig.size24,
                      containerWidth: SizeConfig.size50,
                      circleSize: SizeConfig.size18,
                    ),
                  ],
                ),
              ),

              if(controller.anyFoodHabitRestriction.value)
                ...[
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: SizeConfig.size12),
                    child: CustomText(
                      AppStrings.kindlyIndicateWhichFoodHabits,
                      fontSize: SizeConfig.small,
                      color: AppColors.secondaryTextColor,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  SizedBox(height: SizeConfig.paddingXSL),
                  ...controller.foodHabits.map((habit) {
                    return CheckboxListTile(
                      value: controller.selectedHabits[habit['id']],
                      onChanged: (value) {
                        if (value == true) {
                          // Uncheck all other habits first
                          controller.selectedHabits.forEach((key, _) {
                            controller.selectedHabits[key] = false;
                          });
                          // Then check only the selected one
                          controller.selectedHabits[habit['id']!] = true;
                        } else {
                          controller.selectedHabits[habit['id']!] = false;
                        }                      },
                      title: CustomText(
                        habit['label']!,
                        fontSize: SizeConfig.small,
                        color: AppColors.secondaryTextColor,
                        fontWeight: FontWeight.w400,
                      ),
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      checkColor: Colors.white,
                      dense: true,
                      visualDensity: VisualDensity(horizontal: -4, vertical: -2),
                    );
                  }).toList(),

                ],

            ],
          ),
        ),

        SizedBox(height: SizeConfig.paddingL),

        _buildAddMoreRestrictionsSection(),
      ],
    );
  }

  Widget _buildAddMoreDetails(){
    return Column(
      children: [
        Obx(()=> controller.arrMoreDetails.isNotEmpty ? Column(
          children: List.generate(
            controller.arrMoreDetails.length,
                (index) {
              final item = controller.arrMoreDetails[index];
              return Padding(
                padding: EdgeInsets.only(bottom: SizeConfig.size15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    if(index==0)...[
                      CustomText(
                        AppStrings.detailsTitle,
                        fontSize: SizeConfig.medium,
                        fontWeight: FontWeight.w500,
                        color: AppColors.mainTextColor,
                      ),

                      SizedBox(height: SizeConfig.size12),
                    ],

                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                                color: AppColors.white,
                                boxShadow: [AppShadows.textFieldShadow],
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: AppColors.greyE5,
                                )),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Title + Details
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      CustomText(
                                        item.title,
                                        fontSize: SizeConfig.large,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.mainTextColor,
                                      ),
                                      const SizedBox(height: 4),
                                      CustomText(
                                        item.details,
                                        fontSize: SizeConfig.medium,
                                        fontWeight: FontWeight.w400,
                                        color: AppColors.secondaryTextColor,
                                      ),
                                    ],
                                  ),
                                ),

                              ],
                            ),
                          ),
                        ),
                        Positioned(
                            right: 6,
                            top: -15,
                            child: InkWell(
                              onTap: () => controller.removeDetail(index),
                              child: Container(
                                padding: EdgeInsets.all(6),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                    color: AppColors.white,
                                    boxShadow: [AppShadows.textFieldShadow],
                                    border: Border.all(
                                      color: AppColors.greyE5,
                                    ),
                                    shape: BoxShape.circle
                                ),
                                child: Icon(
                                  Icons.close,
                                  size: 18,
                                ),
                              ),
                            )
                        )
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ) : SizedBox.shrink()),

        InkWell(
          onTap: ()=> showAddMoreDetailsDialog(context),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CustomText(
                AppStrings.addMoreDetailsLabel,
                fontSize: SizeConfig.medium,
                fontWeight: FontWeight.bold,
                color: AppColors.mainTextColor,
              ),
              Container(
                width: 32,
                height: 30,
                decoration: BoxDecoration(
                  color: AppColors.primaryColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.add,
                  color: AppColors.white,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
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
