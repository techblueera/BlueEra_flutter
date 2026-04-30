import 'dart:convert';
import 'dart:developer';
import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/model/location_data_model.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_http_links_textfiled_widget.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/regular_expression.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/controller/location_controller.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/features/business/visiting_card/view/widget/contact_number_widget.dart';
import 'package:BlueEra/features/common/bottomNavigationBar/controller/bottom_bar_controller.dart';
import 'package:BlueEra/features/subscription/widget/promo_code_dialog.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/fetch_location_button.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:pinput/pinput.dart';

class CreateBusinessAccountNewStepTwo extends StatefulWidget {
  const CreateBusinessAccountNewStepTwo({
    super.key,
  });

  @override
  State<CreateBusinessAccountNewStepTwo> createState() =>
      _CreateBusinessAccountNewStepTwoState();
}

class _CreateBusinessAccountNewStepTwoState
    extends State<CreateBusinessAccountNewStepTwo> {
  final mobileController = TextEditingController();
  final landlineNumberController = TextEditingController();
  final landlineCodeController = TextEditingController();
  final websiteController = TextEditingController();
  final fullBusinessAddressTextController = TextEditingController();
  final cityController = TextEditingController();
  final picCodeController = TextEditingController();
  ContactType? selectedType = ContactType.Mobile;
  final viewBusinessDetailsController =
      getOrPut(() => ViewBusinessDetailsController(), permanent: true);

  bool isFormValid = false;
  final locationController = Get.put(LocationController());
  GoogleMapController? mapController;
  Set<Marker> _markers = {};
  LocationDataModel? locationData;

  @override
  void initState() {
    super.initState();

    // Add listeners for validation
    mobileController.addListener(_validateForm);
    landlineCodeController.addListener(_validateForm);
    landlineNumberController.addListener(_validateForm);
    websiteController.addListener(_validateForm);
    cityController.addListener(_validateForm);
    fullBusinessAddressTextController.addListener(_validateForm);
    viewBusinessDetailsController.listingDescriptionController.value
        .addListener(_validateForm);
    picCodeController.addListener(_validateForm);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      updateAddressFromLocation();
      _showReferralDialog();
    });
  }

  /// Shown once this screen is mounted — the user has just created their
  /// business account in step one. If they enter a referral code, patch it
  /// onto the new business via `updateBusinessDetails`.
  Future<void> _showReferralDialog() async {
    if (!mounted) return;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PromoCodeDialog(
        onBtnPressed: (code) async {
          Navigator.of(ctx).pop();
          if (code.isNotEmpty) {
            await viewBusinessDetailsController.updateBusinessDetails(
              {ApiKeys.referral_code: code},
              showProgress: false,
            );
          }
        },
      ),
    );
  }

  Future<void> updateAddressFromLocation() async {
    locationData = await locationController.checkPermissionAndSetData();
    if (locationData != null) {
      _updateLocationData(locationData);
    }
  }

  void _updateLocationData(var locationData) {
    fullBusinessAddressTextController.text = locationData!.fullAddress;
    cityController.text = locationData!.city;
    picCodeController.text = locationData!.pinCode;
    viewBusinessDetailsController.addressLat?.value =
        double.parse(locationData!.lat);
    viewBusinessDetailsController.addressLong?.value =
        double.parse(locationData!.long);
    _updateMarkerOnMap();
  }

  void _validateForm() {
    setState(() {
      bool commonValid = cityController.text.trim().isNotEmpty &&
          fullBusinessAddressTextController.text.trim().isNotEmpty &&
          picCodeController.text.trim().isNotEmpty;

      bool isWebsiteValid = websiteController.text.trim().isEmpty ||
          ValidationMethod.isValidURL(websiteController.text.trim());

      if (selectedType == ContactType.Mobile) {
        isFormValid = commonValid &&
            isWebsiteValid &&
            ValidationMethod.validatePhone(mobileController.text) == null;
      } else if (selectedType == ContactType.Landline) {
        isFormValid = commonValid &&
            isWebsiteValid &&
            ValidationMethod.validateLandline(landlineNumberController.text) ==
                null;
      } else {
        isFormValid = false;
      }
    });
  }

  Future<void> _onMapCreated(GoogleMapController controller) async {
    mapController = controller;

    if (locationData != null) {
      _updateMarkerOnMap();
    }
  }

  Future<void> _updateMarkerOnMap() async {
    if (locationData == null) return;

    try {
      double lat = double.parse(locationData!.lat);
      double long = double.parse(locationData!.long);
      LatLng position = LatLng(lat, long);

      // Create the Google Maps Marker
      final Marker newMarker = Marker(
        markerId: const MarkerId("selected_location"),
        position: position,
        icon: BitmapDescriptor.defaultMarker, // Or use custom icon
      );

      setState(() {
        _markers = {newMarker};
      });

      // Animate Camera
      await mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(position, 14),
      );
    } catch (e) {
      print("Error updating marker: $e");
    }
  }

  @override
  void dispose() {
    mobileController.dispose();
    landlineCodeController.dispose();
    landlineNumberController.dispose();
    websiteController.dispose();
    cityController.dispose();
    fullBusinessAddressTextController.dispose();
    picCodeController.dispose();
    // landmarkController.dispose();
    super.dispose();
  }

  void _onBackPressed() {
    final bottomBarController = Get.find<BottomBarController>();
    Get.until((route) =>
        route.settings.name == RouteHelper.getBottomNavigationBarScreenRoute());
    bottomBarController.currentIndex.value = 2;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        _onBackPressed();
      },
      child: Scaffold(
          appBar: CommonBackAppBar(
              isLeading: true,
              title: AppStrings.businessDetailsTitle,
              onBackTap: () => _onBackPressed()),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                  left: SizeConfig.size8,
                  right: SizeConfig.size8,
                  top: SizeConfig.size15,
                  bottom: SizeConfig.size40),
              child: CustomFormCard(
                padding: EdgeInsets.all(
                  SizeConfig.size10,
                ),
                child: AbsorbPointer(
                  absorbing: viewBusinessDetailsController
                      .isUpdateBusinessDetailsLoading.value,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            CustomText(
                              AppStrings.yourBusinessLiveLocation,
                              fontSize: SizeConfig.large,
                              fontWeight: FontWeight.w600,
                              color: AppColors.secondaryTextColor,
                            ),
                            SizedBox(width: SizeConfig.size8),
                            CommonLocationFetcher(
                              locationController: locationController,
                              onLocationFetched: (locationData) {
                                _updateLocationData(locationData);
                              },
                              childBuilder: (fetchAction) {
                                return PositiveCustomBtn(
                                  width: SizeConfig.size80,
                                  height: SizeConfig.size30,
                                  onTap: fetchAction,
                                  isLeadingShow: true,
                                  leadingIconPath: AppIconAssets.refreshIcon,
                                  title: AppStrings.refresh,
                                  radius: 8.0,
                                  bgColor: AppColors.primaryColor,
                                );
                              },
                            )
                          ]),
                      SizedBox(height: SizeConfig.size10),
                      ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: SizedBox(
                            width: double.infinity,
                            height: SizeConfig.size160,
                            child: Stack(
                              children: [
                                /// Google Map
                                GoogleMap(
                                  onMapCreated: _onMapCreated,
                                  initialCameraPosition: CameraPosition(
                                    target: (locationData != null)
                                        ? LatLng(
                                            double.parse(locationData!.lat),
                                            double.parse(locationData!.long),
                                          )
                                        : LatLng(20.5937,
                                            78.9629), // Center of India
                                    zoom: (locationData != null) ? 14 : 4,
                                  ),
                                  markers: _markers,
                                  myLocationEnabled: false,
                                  compassEnabled: false,
                                  zoomGesturesEnabled: false,
                                  rotateGesturesEnabled: true,
                                  tiltGesturesEnabled: true,
                                  scrollGesturesEnabled: true,
                                ),
                                Positioned(
                                  right: SizeConfig.size10,
                                  bottom: SizeConfig.size10,
                                  child: InkWell(
                                    onTap: () async {
                                      if (locationData == null) return;

                                      openGoogleMaps(
                                          latitude:
                                              double.parse(locationData!.lat),
                                          longitude:
                                              double.parse(locationData!.long));
                                    },
                                    child: Container(
                                      padding: EdgeInsets.all(SizeConfig.size8),
                                      decoration: BoxDecoration(
                                        color: AppColors.white,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color: AppColors.skyBlueDF,
                                            width: 1),
                                      ),
                                      child: Transform.rotate(
                                        angle: -0.6,
                                        child: const Icon(
                                          Icons.send_outlined,
                                          color: AppColors.skyBlueDF,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )),

                      SizedBox(height: SizeConfig.size20),

                      /// Full Business Address
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CommonTextField(
                            readOnly: true,
                            maxLine: 3,
                            textEditController:
                                fullBusinessAddressTextController,
                            inputLength: AppConstants.inputCharterLimit50,
                            keyBoardType: TextInputType.text,
                            title: AppStrings.fullBusinessAddress,
                            regularExpression:
                                RegularExpressionUtils.alphabetSpacePattern,
                            hintText: AppStrings.addressHint,
                            isValidate: false,
                          ),
                          CommonLocationFetcher(
                            locationController: locationController,
                            onLocationFetched: (locationData) {
                              _updateLocationData(locationData);
                            },
                            childBuilder: (fetchAction) {
                              return SizedBox();
                            },
                          )
                          // _buildFetchAddressWidgets(
                          //     child: SizedBox()
                          // )
                        ],
                      ),
                      SizedBox(
                        height: SizeConfig.size20,
                      ),

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

                      ///ENTER CITY NAME ......
                      CommonTextField(
                        textEditController: cityController,
                        inputLength: AppConstants.inputCharterLimit50,
                        keyBoardType: TextInputType.text,
                        regularExpression:
                            RegularExpressionUtils.alphabetSpacePattern,
                        title: AppStrings.city,
                        hintText: AppStrings.city,
                        isValidate: true,
                        readOnly: true,
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
                        title: AppStrings.pincodeTitle,
                        hintText: AppStrings.pincodeHint,
                        isValidate: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return AppStrings.pleaseEnterPinCode.tr;
                          } else if (!RegExp(
                                  RegularExpressionUtils.pinCodeRegExp)
                              .hasMatch(value)) {
                            return AppStrings.enterValidIndianPincode.tr;
                          }
                          return null;
                        },
                      ),
                      SizedBox(
                        height: SizeConfig.size28,
                      ),

                      ///Mobile number
                      ContactInputField1(
                        mobileController: mobileController,
                        landlineCodeController: landlineCodeController,
                        landlineNumberController: landlineNumberController,
                        selectedType: selectedType ?? ContactType.Mobile,
                        onTypeChanged: (type) {
                          mobileController.clear();
                          landlineCodeController.clear();
                          landlineNumberController.clear();
                          setState(() {
                            selectedType = type;
                          });

                          _validateForm();
                        },
                        prefixOnChange: (value) => true,
                        mobileNumberOnChange: (String) {},
                      ),
                      SizedBox(
                        height: SizeConfig.size20,
                      ),

                      ///websiteOptional
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
                        hintText: AppStrings.websiteHint,
                        onChange: (value) => _validateForm(),
                      ),

                      SizedBox(
                        height: SizeConfig.size28,
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: CustomBtn(
                              radius: 10,
                              onTap: () {
                                _onBackPressed();
                              },
                              title: AppStrings.previous,
                              bgColor: Colors.transparent,
                              textColor: AppColors.primaryColor,
                              borderColor: AppColors.primaryColor,
                            ),
                          ),
                          SizedBox(
                            width: SizeConfig.size10,
                          ),
                          Expanded(
                            child: Obx(() => CustomBtn(
                                  radius: 10,
                                  onTap: isFormValid
                                      ? () async {
                                          if (selectedType ==
                                              ContactType.Mobile) {
                                            String? phoneError =
                                                ValidationMethod.validatePhone(
                                                    mobileController.text);
                                            if (phoneError != null) {
                                              commonSnackBar(
                                                  message: phoneError);
                                              return;
                                            }
                                          }

                                          if (selectedType ==
                                              ContactType.Landline) {
                                            String? landlineError =
                                                ValidationMethod
                                                    .validateLandline(
                                                        landlineNumberController
                                                            .text);
                                            if (landlineError != null) {
                                              commonSnackBar(
                                                  message: AppStrings
                                                      .pleaseEnterValidLandline
                                                      .tr);
                                              return;
                                            }
                                          }

                                          /// Submit action
                                          Map<String, dynamic> reqParam = {
                                            ApiKeys.businessId: businessId,
                                            ApiKeys.office_mob_no_Pre: 91,
                                            "business_number": {
                                              "office_mob_no": mobileController
                                                      .text.isNotEmpty
                                                  ? {
                                                      "pre": "91",
                                                      "number":
                                                          mobileController.text,
                                                    }
                                                  : null,
                                              "office_landline_no":
                                                  landlineNumberController
                                                          .text.isNotEmpty
                                                      ? {
                                                          "pre":
                                                              landlineCodeController
                                                                  .text,
                                                          "number":
                                                              landlineNumberController
                                                                  .text,
                                                        }
                                                      : null,
                                            },
                                            ApiKeys.city_state_pincode:
                                                cityController.text,
                                            ApiKeys.address:
                                                fullBusinessAddressTextController
                                                    .text,
                                            ApiKeys.business_location:
                                                jsonEncode({
                                              ApiKeys.lat:
                                                  viewBusinessDetailsController
                                                      .addressLat?.value
                                                      .toString(),
                                              ApiKeys.lon:
                                                  viewBusinessDetailsController
                                                      .addressLong?.value
                                                      .toString(),
                                            }),
                                            ApiKeys.pincode:
                                                picCodeController.text,
                                            ApiKeys.website_url:
                                                websiteController.text,
                                          };
                                          await viewBusinessDetailsController
                                              .updateBusinessDetails(reqParam,
                                                  showProgress: false);
                                          if (!mounted) return;
                                          Get.toNamed(
                                              RouteHelper
                                                  .getCreateBusinessAccountNewStepThreeRoute(),
                                              arguments: {
                                                ApiKeys.city:
                                                    cityController.text
                                              });
                                        }
                                      : null,
                                  title: viewBusinessDetailsController
                                          .isUpdateBusinessDetailsLoading.value
                                      ? null // hide text
                                      : AppStrings.submit,
                                  isLoading: viewBusinessDetailsController
                                      .isUpdateBusinessDetailsLoading.value,
                                  isValidate: isFormValid,
                                )),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )),
    );
  }

}
