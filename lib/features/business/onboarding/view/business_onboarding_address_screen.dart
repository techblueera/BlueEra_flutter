import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/controller/location_controller.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/business/onboarding/controller/business_onboarding_controller.dart';
import 'package:BlueEra/features/business/onboarding/widget/business_onboarding_progress_bar.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_location_search_field.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class BusinessOnboardingAddressScreen extends StatefulWidget {
  const BusinessOnboardingAddressScreen({super.key});

  @override
  State<BusinessOnboardingAddressScreen> createState() =>
      _BusinessOnboardingAddressScreenState();
}

class _BusinessOnboardingAddressScreenState
    extends State<BusinessOnboardingAddressScreen> {
  final controller = getOrPut(() => BusinessOnboardingController());
  final locationController = getOrPut(() => LocationController());

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeOfferCurrentLocation();
    });
  }

  Future<void> _maybeOfferCurrentLocation() async {
    if (controller.fullAddress.value.isNotEmpty) return;
    final loc = await locationController.checkPermissionAndSetData(
      preferNativeGeocoding: true,
    );
    if (!mounted || loc == null) return;
    final detected = loc.fullAddress.trim();
    if (detected.isEmpty) return;
    _showAddressDialog(detected, loc.lat, loc.long, loc.pinCode);
  }

  void _showAddressDialog(
      String detected, String lat, String lng, String pin) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SizeConfig.size12),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: SizeConfig.size20,
            vertical: SizeConfig.size20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CustomText(
                'Update address to:',
                fontSize: SizeConfig.medium,
                color: AppColors.secondaryTextColor,
              ),
              SizedBox(height: SizeConfig.size4),
              CustomText(
                detected,
                fontSize: SizeConfig.large,
                color: AppColors.mainTextColor,
                fontWeight: FontWeight.w600,
              ),
              SizedBox(height: SizeConfig.size20),
              _dialogAction('Update', AppColors.primaryColor, () {
                controller.setAddress(
                  address: detected,
                  latitude: double.tryParse(lat),
                  longitude: double.tryParse(lng),
                  pin: pin,
                );
                Navigator.pop(ctx);
              }),
              _dialogAction('Edit address', AppColors.mainTextColor, () {
                controller.addressController.text = detected;
                controller.fullAddress.value = detected;
                Navigator.pop(ctx);
              }),
              _dialogAction("Don't update", AppColors.grey9B, () {
                Navigator.pop(ctx);
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dialogAction(String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: SizeConfig.size10),
        child: CustomText(
          label,
          fontSize: SizeConfig.large,
          color: color,
          textAlign: TextAlign.right,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: CommonBackAppBar(
        isLeading: true,
        isShadowShow: false,
        showRightTextButton: true,
        rightTextButtonText: 'Skip',
        rightTextButtonColor: AppColors.mainTextColor,
        onRightTextButtonTap: _next,
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Column(
          children: [
            const BusinessOnboardingProgressBar(currentStep: 5),
            SizedBox(height: SizeConfig.size20),
            CustomText(
              'More ways to find\nyou',
              fontSize: SizeConfig.size26,
              fontWeight: FontWeight.w700,
              textAlign: TextAlign.center,
              color: AppColors.mainTextColor,
            ),
            SizedBox(height: SizeConfig.size10),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: SizeConfig.size30),
              child: CustomText(
                'Tell customers where your business is located or where you operate.',
                fontSize: SizeConfig.medium,
                textAlign: TextAlign.center,
                color: AppColors.secondaryTextColor,
              ),
            ),
            SizedBox(height: SizeConfig.size20),
            Expanded(
              child: SingleChildScrollView(
                padding:
                    EdgeInsets.symmetric(horizontal: SizeConfig.size20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Obx(() {
                      return AbsorbPointer(
                        absorbing: controller.noPhysicalLocation.value,
                        child: Opacity(
                          opacity:
                              controller.noPhysicalLocation.value ? 0.5 : 1.0,
                          child: CommonLocationSearchField(
                            controller: controller.addressController,
                            title: '',
                            hintText: 'Address or region',
                            isShowLeading: false,
                            onSelected: (placeId, latitude, longitude, addr) {
                              controller.setAddress(
                                address: addr,
                                latitude: latitude,
                                longitude: longitude,
                              );
                            },
                          ),
                        ),
                      );
                    }),
                    SizedBox(height: SizeConfig.size12),
                    Obx(() {
                      final checked = controller.noPhysicalLocation.value;
                      return InkWell(
                        onTap: () {
                          controller.noPhysicalLocation.value = !checked;
                          if (controller.noPhysicalLocation.value) {
                            controller.clearAddress();
                          }
                        },
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              checked
                                  ? Icons.check_box
                                  : Icons.check_box_outline_blank,
                              color: checked
                                  ? AppColors.mainTextColor
                                  : AppColors.grey9B,
                            ),
                            SizedBox(width: SizeConfig.size8),
                            Expanded(
                              child: CustomText(
                                "My business doesn't have a physical location",
                                fontSize: SizeConfig.medium,
                                color: AppColors.mainTextColor,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    SizedBox(height: SizeConfig.size20),
                    _websiteField(),
                  ],
                ),
              ),
            ),
            _bottomButton(),
          ],
        ),
      ),
    );
  }

  Widget _websiteField() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: SizeConfig.size12,
        vertical: SizeConfig.size4,
      ),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.greyE5),
        borderRadius: BorderRadius.circular(SizeConfig.size8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: SizeConfig.size4),
            child: CustomText(
              'Website',
              fontSize: SizeConfig.small,
              color: AppColors.grey9B,
            ),
          ),
          TextField(
            controller: controller.websiteController,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(
              border: InputBorder.none,
              isDense: true,
              hintText: 'https://',
            ),
          ),
        ],
      ),
    );
  }

  Widget _bottomButton() {
    return Material(
      color: AppColors.white,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: SizeConfig.size20,
            vertical: SizeConfig.size12,
          ),
          child: Obx(() {
            final canProceed = controller.canProceedFromAddress;
            return CustomBtn(
              radius: SizeConfig.size30,
              isValidate: canProceed,
              bgColor: canProceed
                  ? AppColors.mainTextColor
                  : AppColors.whiteF3,
              textColor:
                  canProceed ? AppColors.white : AppColors.grey9B,
              title: 'Next',
              onTap: canProceed ? _next : null,
            );
          }),
        ),
      ),
    );
  }

  void _next() => Get.toNamed(
      RouteHelper.getBusinessOnboardingDescriptionScreenRoute());
}
