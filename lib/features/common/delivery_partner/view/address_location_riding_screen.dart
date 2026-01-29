import 'package:BlueEra/core/api/model/place_details.dart';
import 'package:BlueEra/core/common_bloc/place/repo/place_repo.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/regular_expression.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/common/delivery_partner/controller/delivery_partner_controller.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_location_search_field.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_switch_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AddressLocationRidingScreen extends StatefulWidget {
  const AddressLocationRidingScreen({super.key, required this.screeName});

  final String screeName;

  @override
  State<AddressLocationRidingScreen> createState() =>
      _AddressLocationRidingScreenState();
}

class _AddressLocationRidingScreenState
    extends State<AddressLocationRidingScreen> {
  final controller = Get.put(DeliveryPartnerController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:widget.screeName != "from_tab_view"
          ? CommonBackAppBar(
        title: AppStrings.addressAndLocation,
        // onBackTap: onBackPressed,
        buildCustomWidget: () => Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Center(
            child: CustomText("${AppStrings.stepLabel.tr}2/3",
                fontWeight: FontWeight.w600),
          ),
        ),
      ):null,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(SizeConfig.size15),
        child: CustomFormCard(
          child: Form(
            key: controller.formKeyStep2,
            child: Obx(
              () => AbsorbPointer(
                  absorbing: controller.isRidersAddressLoading.value,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: CommonLocationSearchField(
                              controller: controller.locationController,
                              title: AppStrings.homeLocation,
                              hintText: AppStrings.egLucknowGomtiNagar,
                              onSelected: (placeId, lat, lng, address) async {
                                print(
                                    "PlaceId: $placeId Selected: $address → ($lat, $lng)");
                                controller.locationController.text = address;
                                controller.currentAddress.value = address;
                                controller.latitude = lat;
                                controller.longitude = lng;

                                controller.isFetchingAddressDetails.value =
                                    true;

                                // Fetch and auto-fill details
                                try {
                                  final detailsResponse = await PlaceRepo()
                                      .getCompletePlaceDetails(
                                          placeId: placeId);
                                  final detailsData =
                                      detailsResponse.response?.data;
                                  logs("detailsResponse====== $detailsData");

                                  final placeDetails =
                                      PlaceDetailsResponse.fromJson(
                                          detailsData);
                                  final components =
                                      placeDetails.result?.addressComponents ??
                                          [];

                                  String city = '';
                                  String state = '';
                                  String postalCode = '';

                                  for (var comp in components) {
                                    final types = comp.types ?? [];
                                    if (types.contains('locality')) {
                                      city = comp.longName ?? '';
                                    } else if (types.contains(
                                        'administrative_area_level_1')) {
                                      state = comp.longName ?? '';
                                    } else if (types.contains('postal_code')) {
                                      postalCode = comp.longName ?? '';
                                    }
                                  }

                                  controller.cityController.text = city;
                                  controller.stateController.text = state;
                                  controller.pinCodeController.text =
                                      postalCode;
                                } catch (e) {
                                  print("Error fetching place details: $e");
                                } finally {
                                  controller.isFetchingAddressDetails.value =
                                      false;
                                }
                              },
                            ),
                          ),
                          if (controller.currentAddress.isNotEmpty)
                            Padding(
                              padding: EdgeInsets.only(
                                  left: SizeConfig.size8,
                                  top: SizeConfig.size24),
                              child: (controller.isFetchingAddressDetails.value)
                                  ? SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    )
                                  : Icon(Icons.check_circle,
                                      color: Colors.green, size: 22),
                            )
                        ],
                      ),
                      SizedBox(height: SizeConfig.paddingM),
                      CommonTextField(
                        textEditController: controller.landmarkController,
                        title: AppStrings.houseNoAndLandMark,
                        inputLength: AppConstants.inputCharterLimit30,
                        hintText: AppStrings.egFlat21B,
                        keyBoardType: TextInputType.text,
                        isValidate: true,
                      ),
                      SizedBox(height: SizeConfig.paddingM),
                      CommonTextField(
                        textEditController: controller.pinCodeController,
                        // readOnly: true,
                        title: AppStrings.pincodeTitle,
                        hintText: AppStrings.pincodeHint,
                        keyBoardType: TextInputType.number,
                        inputLength: AppConstants.inputCharterLimit6,
                        validator: ValidationMethod().validatePin,
                      ),
                      SizedBox(height: SizeConfig.paddingM),
                      CommonTextField(
                        textEditController: controller.cityController,
                        readOnly: true,
                        title: AppStrings.city,
                        hintText: AppStrings.egKolkata,
                        keyBoardType: TextInputType.text,
                        isValidate: true,
                        inputLength: AppConstants.inputCharterLimit50,
                      ),
                      SizedBox(height: SizeConfig.paddingM),
                      CommonTextField(
                        textEditController: controller.stateController,
                        readOnly: true,
                        title: AppStrings.state,
                        hintText: AppStrings.egWestBengal,
                        keyBoardType: TextInputType.text,
                        isValidate: true,
                        inputLength: AppConstants.inputCharterLimit50,
                      ),
                      SizedBox(height: SizeConfig.paddingM),
                      CustomText(
                        AppStrings.enableLiveLocation,
                        fontSize: SizeConfig.medium,
                        color: AppColors.mainTextColor,
                        fontWeight: FontWeight.w600,
                      ),
                      SizedBox(height: SizeConfig.size10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          CustomText(
                            AppStrings.allowLocationAccess,
                            fontSize: SizeConfig.medium,
                            color: AppColors.mainTextColor,
                            fontWeight: FontWeight.w400,
                          ),
                          CustomSwitch(
                            value: controller.enabledLiveLocation.value,
                            onChanged: (val) {
                              controller.enabledLiveLocation.value =
                                  !controller.enabledLiveLocation.value;
                            },
                            containerHeight: SizeConfig.size24,
                            containerWidth: SizeConfig.size50,
                            circleSize: SizeConfig.size18,
                          ),
                        ],
                      ),
                      SizedBox(height: SizeConfig.paddingL),
                      CustomBtn(
                        title: controller.isRidersAddressLoading.value
                            ? null
                            : AppStrings.nextButton,
                        onTap: () => controller.ridersOnboardingAddressApi(),
                        radius: 10.0,
                        bgColor: AppColors.primaryColor,
                        isLoading: controller.isRidersAddressLoading.value,
                      )
                    ],
                  )),
            ),
          ),
        ),
      ),
    );
  }
}
