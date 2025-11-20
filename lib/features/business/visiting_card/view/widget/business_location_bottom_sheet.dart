import 'dart:convert';
import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/controller/location_controller.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/features/business/auth/model/viewBusinessProfileModel.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class BusinessLocationBottomSheet extends StatefulWidget {
  final BusinessProfileDetails? prevBusinessDetails;
  final bool isFromCreateUser;

  BusinessLocationBottomSheet({super.key, this.prevBusinessDetails, this.isFromCreateUser = false});

  @override
  State<BusinessLocationBottomSheet> createState() =>
      _BusinessLocationBottomSheetState();
}

class _BusinessLocationBottomSheetState
    extends State<BusinessLocationBottomSheet> {
  final fullBusinessAddressTextController = TextEditingController();
  final picCodeController = TextEditingController();
  final cityController = TextEditingController();
  final RegExp pinRegex = RegExp(r'^[1-9][0-9]{5}$');
  final viewBusinessDetailsController =
  Get.find<ViewBusinessDetailsController>();
  final locationController = Get.put(LocationController());
  bool isValidIndianPincode(String pin) {
    return pinRegex.hasMatch(pin.trim());
  }

  @override
  void initState() {
    super.initState();

    final data = widget.prevBusinessDetails;

    if (data != null) {
      cityController.text = data.cityStatePincode ?? '';
      fullBusinessAddressTextController.text = data.address ?? '';
      picCodeController.text = data.pincode?.toString() ?? '';

      viewBusinessDetailsController.setStartLocation(
          data.businessLocation?.lat?.toDouble(),
          data.businessLocation?.lon?.toDouble(),
          data.address ?? "");

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

    return AnimatedPadding(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: EdgeInsets.only(
          left: SizeConfig.size16,
          right: SizeConfig.size16,
          top: SizeConfig.size16,
          bottom: SizeConfig.size30,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CustomText(
                    AppStrings.businessLocation,

                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              SizedBox(height: SizeConfig.size16),

              CommonTextField(
                readOnly: true,
                maxLine: 3,
                textEditController: fullBusinessAddressTextController,
                title: AppStrings.fullBusinessAddress,
                hintText: AppStrings.fullBusinessAddress,
              ),
              TextButton(
                onPressed: () =>  updateAddressFromLocation(),
                child: CustomText(
                  AppStrings.tapToFetchBusinessLocation,
                  fontSize: SizeConfig.small,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryColor,
                  decoration: TextDecoration.underline,
                  decorationColor: AppColors.primaryColor,
                ),
              ),

              // SizedBox(height: SizeConfig.size16),
              CommonTextField(
                textEditController: cityController,
                title: AppStrings.city,
                readOnly: true,
              ),
              SizedBox(height: SizeConfig.size16),
              CommonTextField(
                onChange: (val){
                  setState(() {

                  });
                },
                validator: (String? value) {
                  if (value == null || value.trim().isEmpty) return AppStrings.pleaseEnterPinCode.tr;
                  return isValidIndianPincode(value) ? null : AppStrings.enterValidIndianPincode.tr;
                  },
                textEditController: picCodeController,
                title: AppStrings.pincodeTitle,
                keyBoardType: TextInputType.number,
              ),
              SizedBox(height: SizeConfig.size24),

              CustomBtn(
                title: AppStrings.save,
                bgColor: AppColors.primaryColor,
                radius: 10,
                onTap:() {
                  if ((viewBusinessDetailsController.addressLat?.value !=0.0) &&
                  (viewBusinessDetailsController.addressLong?.value !=0.0)) {
                  if (picCodeController.text.isNotEmpty&&pinRegex.hasMatch(picCodeController.text.trim())) {
                    Map<String, dynamic> params = {
                      ApiKeys.city_state_pincode: cityController.text,
                      ApiKeys.address: fullBusinessAddressTextController.text,
                      ApiKeys.pincode: picCodeController.text,

                      "business_location": jsonEncode({
                        ApiKeys.lat: viewBusinessDetailsController.addressLat?.value.toString(),
                        ApiKeys.lon:
                        viewBusinessDetailsController.addressLong?.value.toString(),
                      }),
                    };

                    // Call controller to save
                    viewBusinessDetailsController.updateBusinessDetails(params);
                    if (!widget.isFromCreateUser) {
                      Navigator.of(context).pop();
                    } else {
                      Get.offNamedUntil(
                        RouteHelper.getBottomNavigationBarScreenRoute(),
                            (route) => false,
                      );
                    }

                  } else if(!pinRegex.hasMatch(picCodeController.text.trim())) {
                  commonSnackBar(
                     message:'Please Enter Valid Pin code');
                   }else{
                    commonSnackBar(
                        message:AppStrings.pleaseEnterPinCode);
                  }
                  } else {
                    commonSnackBar(
                        message:AppStrings.pleaseEnterAddress);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget _buildAddressStatus() {
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
  //           child: Text(
  //             'GPS location not found (Tap to fetch)',
  //             style: TextStyle(
  //               fontSize: SizeConfig.small,
  //               fontWeight: FontWeight.w600,
  //               color: AppColors.red,
  //               decoration: TextDecoration.underline,
  //             ),
  //           ),
  //         ),
  //       );
  //     }
  //
  //     return SizedBox();
  //   });
  // }
}

