import 'dart:convert';

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/regular_expression.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/controller/location_controller.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/features/business/auth/model/viewBusinessProfileModel.dart';
import 'package:BlueEra/l10n/app_localizations.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';


class BusinessLocationUpdateWidget extends StatefulWidget {
  const BusinessLocationUpdateWidget({
    super.key,
    this.prevBusinessDetails,
    this.isFromCreateUser = false,
  });

  final bool isFromCreateUser;
  final BusinessProfileDetails? prevBusinessDetails;

  @override
  State<BusinessLocationUpdateWidget> createState() =>
      _BusinessLocationUpdateWidgetState();
}

class _BusinessLocationUpdateWidgetState
    extends State<BusinessLocationUpdateWidget> {

  final fullBusinessAddressTextController = TextEditingController();
  final picCodeController = TextEditingController();
  final cityController = TextEditingController();

  final viewBusinessDetailsController =
  Get.find<ViewBusinessDetailsController>();

  bool validate = false;
  SizeOfBusiness? selectedBusiness;

  final locationController = Get.put(LocationController());

  @override
  void initState() {
    super.initState();
    final data = widget.prevBusinessDetails;

    if (data != null) {
      cityController.text = data.cityStatePincode ?? '';
      fullBusinessAddressTextController.text = data.address ?? '';
      picCodeController.text =
      data.pincode != null ? data.pincode.toString() : "";

      viewBusinessDetailsController.setStartLocation(
          widget.prevBusinessDetails?.businessLocation?.lat?.toDouble(),
          widget.prevBusinessDetails?.businessLocation?.lon?.toDouble(),
          widget.prevBusinessDetails?.address ?? "");

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
        body: SingleChildScrollView(
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

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CommonTextField(
                        maxLine: 3,
                        textEditController: fullBusinessAddressTextController,
                        inputLength: AppConstants.inputCharterLimit50,
                        keyBoardType: TextInputType.text,
                        title: appLocalizations?.fullBusinessAddress,
                        regularExpression:
                        RegularExpressionUtils.alphabetSpacePattern,
                        hintText: appLocalizations?.fullBusinessAddress,
                        isValidate: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Please enter your address";
                          }
                          return null;
                        },
                      ),
                      _buildAddressField()
                    ],
                  ),
                  SizedBox(
                    height: SizeConfig.size20,
                  ),

                  ///ENTER NAME CONTROLLER......
                  CommonTextField(
                    textEditController: cityController,
                    inputLength: AppConstants.inputCharterLimit50,
                    keyBoardType: TextInputType.text,
                    regularExpression:
                    RegularExpressionUtils.alphabetSpacePattern,
                    title: appLocalizations?.city,
                    hintText: appLocalizations?.city,
                    isValidate: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Please enter your city";
                      }
                      return null;
                    },
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

                  CustomBtn(
                    radius: 10,
                    bgColor: AppColors.primaryColor,
                    onTap: () async {
                      Map<String, dynamic> params = await buildBusinessDetailsPayload();
                      await Get.find<ViewBusinessDetailsController>()
                          .updateBusinessDetails(params);
                      if (widget.isFromCreateUser == false) {
                        Navigator.of(context).pop();
                      } else {
                        Get.offNamedUntil(
                          RouteHelper.getBottomNavigationBarScreenRoute(),
                              (route) => false,
                        );
                      }
                    },
                    title: "Update",
                    isValidate: validate,
                  ),

                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<Map<String, dynamic>> buildBusinessDetailsPayload() async {
    return {
      ApiKeys.businessId: businessId,
      ApiKeys.city_state_pincode: cityController.text,
      ApiKeys.address: fullBusinessAddressTextController.text,
      ApiKeys.pincode: picCodeController.text,
      "business_location": jsonEncode({
        ApiKeys.lat: viewBusinessDetailsController.addressLat?.value.toString(),
        ApiKeys.lon:
        viewBusinessDetailsController.addressLong?.value.toString(),
      }),
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
            onTap: () => updateAddressFromLocation(),
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
