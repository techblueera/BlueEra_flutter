import 'package:BlueEra/core/api/model/location_data_model.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/controller/location_controller.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/business/visiting_card/view/widget/business_location_widget.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/controller/earn_profile_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/model/earn_profile_model.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/expandable_text.dart';
import 'package:BlueEra/widgets/fetch_location_button.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class EarnServiceContactMapCard extends StatelessWidget {
  final EarnProfileController controller;
  final bool showEditButton;

  const EarnServiceContactMapCard({
    super.key,
    required this.controller,
    this.showEditButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final profile = controller.earnProfile.value;
      final logoUrl = profile?.serviceLogo ?? '';

      return CustomFormCard(
        padding: EdgeInsets.all(SizeConfig.size10),
        margin: const EdgeInsets.only(top: 10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: CustomText(
                    AppStrings.contactUs.tr,
                    fontSize: SizeConfig.large,
                    color: AppColors.mainTextColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (showEditButton)
                  InkWell(
                    onTap: () => _openEditSheet(context, profile),
                    child: LocalAssets(
                      height: 16,
                      imagePath: AppIconAssets.pen_line,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.white,
                border: Border.all(color: AppColors.greyE5),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [AppShadows.textFieldShadow],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        key: ValueKey(logoUrl),
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.white,
                          boxShadow: const [
                            BoxShadow(color: Colors.black12, blurRadius: 10)
                          ],
                          image: DecorationImage(
                            image: logoUrl.isNotEmpty
                                ? NetworkImage(logoUrl) as ImageProvider
                                : AssetImage(AppIconAssets.place_holder_image),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CustomText(
                              profile?.serviceName ?? '',
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                            const SizedBox(height: 5),
                            _buildDescription(profile),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(color: AppColors.greyE5, height: 30),
                  if ((profile?.profileType ?? '').isNotEmpty)
                    _contactItem(
                        AppIconAssets.principal,
                        _profileTypeLabel(profile!.profileType!),
                        AppColors.secondaryTextColor),
                  if ((profile?.email ?? '').isNotEmpty)
                    _contactItem(AppIconAssets.email, profile!.email!,
                        AppColors.secondaryTextColor),
                  if ((profile?.alternatePhoneNumber ?? '').isNotEmpty)
                    _contactItem(
                        AppIconAssets.phone_outline,
                        profile!.alternatePhoneNumber!,
                        AppColors.secondaryTextColor),
                  if ((profile?.address ?? '').isNotEmpty)
                    _contactItem(AppIconAssets.location_new, profile!.address!,
                        AppColors.secondaryTextColor),
                ],
              ),
            ),
            const SizedBox(height: 10),
            BusinessLocationMapWidget(
              latitude: profile?.latitude ?? 0.0,
              longitude: profile?.longitude ?? 0.0,
              businessName: profile?.serviceName ?? '',
            ),
          ],
        ),
      );
    });
  }

  Widget _buildDescription(EarnProfileModel? profile) {
    final type = profile?.profileType ?? '';
    if (type.isEmpty) {
      return CustomText(
        'N/A',
        color: AppColors.secondaryTextColor,
        fontSize: SizeConfig.medium,
      );
    }
    return ExpandableText(
      text: _profileTypeLabel(type),
      trimLines: 3,
      isReadMoreNewLine: false,
      style: TextStyle(
        color: AppColors.secondaryTextColor,
        fontSize: SizeConfig.medium,
        fontWeight: FontWeight.w400,
      ),
    );
  }

  Widget _contactItem(String icon, String label, Color iconColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          LocalAssets(imagePath: icon, imgColor: iconColor),
          const SizedBox(width: 12),
          Expanded(
            child: CustomText(label,
                fontSize: 15, color: AppColors.mainTextColor),
          ),
        ],
      ),
    );
  }

  String _profileTypeLabel(String raw) {
    switch (raw) {
      case 'homeMadeFood':
        return 'Home Made Food';
      case 'homeMadeProduct':
        return 'Home Made Product';
      case 'homeService':
        return 'Home Service';
      default:
        return raw;
    }
  }

  // ── Edit bottom sheet ──────────────────────────────────
  void _openEditSheet(BuildContext context, EarnProfileModel? profile) {
    final addressCtrl = TextEditingController(text: profile?.address ?? '');
    final houseCtrl =
        TextEditingController(text: profile?.houseNumber ?? '');
    final phoneCtrl =
        TextEditingController(text: profile?.alternatePhoneNumber ?? '');
    final emailCtrl = TextEditingController(text: profile?.email ?? '');
    double? lat = profile?.latitude;
    double? lng = profile?.longitude;
    final locationController = Get.put(LocationController());

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      enableDrag: false,
      builder: (ctx) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: SizeConfig.size16,
            vertical: SizeConfig.size16,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    CustomText('Update Contact Info',
                        fontSize: 18, fontWeight: FontWeight.w600),
                    CloseButton(),
                  ],
                ),
                const SizedBox(height: 16),
                CommonLocationFetcher(
                  locationController: locationController,
                  onLocationFetched: (LocationDataModel data) {
                    addressCtrl.text = data.fullAddress;
                    lat = double.tryParse(data.lat);
                    lng = double.tryParse(data.long);
                  },
                  childBuilder: (fetchAction) => PositiveCustomBtn(
                    width: double.infinity,
                    height: SizeConfig.size40,
                    onTap: fetchAction,
                    isLeadingShow: true,
                    leadingIconPath: AppIconAssets.refreshIcon,
                    title: AppStrings.yourBusinessLiveLocation.tr,
                    radius: 8.0,
                    bgColor: AppColors.primaryColor,
                  ),
                ),
                const SizedBox(height: 16),
                CommonTextField(
                  textEditController: addressCtrl,
                  maxLine: 3,
                  title: AppStrings.fullBusinessAddress,
                  hintText: AppStrings.addressHint,
                  isValidate: true,
                ),
                SizedBox(height: SizeConfig.size16),
                CommonTextField(
                  textEditController: houseCtrl,
                  title: 'House Number',
                  hintText: 'e.g. Plot 71',
                  isValidate: false,
                ),
                SizedBox(height: SizeConfig.size16),
                CommonTextField(
                  textEditController: phoneCtrl,
                  keyBoardType: TextInputType.phone,
                  maxLength: 10,
                  title: 'Alternate Phone',
                  hintText: '1234567890',
                  isValidate: false,
                ),
                SizedBox(height: SizeConfig.size16),
                CommonTextField(
                  textEditController: emailCtrl,
                  keyBoardType: TextInputType.emailAddress,
                  title: 'Email',
                  hintText: 'name@example.com',
                  isValidate: false,
                ),
                const SizedBox(height: 24),
                CustomBtn(
                  radius: 10,
                  bgColor: AppColors.primaryColor,
                  title: AppStrings.save,
                  onTap: () async {
                    if (addressCtrl.text.trim().isEmpty) {
                      commonSnackBar(
                          message: AppStrings.noAddressFound.tr);
                      return;
                    }
                    final params = <String, dynamic>{
                      'address': addressCtrl.text.trim(),
                      if (houseCtrl.text.trim().isNotEmpty)
                        'houseNumber': houseCtrl.text.trim(),
                      if (phoneCtrl.text.trim().isNotEmpty)
                        'alternatePhoneNumber': phoneCtrl.text.trim(),
                      if (emailCtrl.text.trim().isNotEmpty)
                        'email': emailCtrl.text.trim(),
                      if (lat != null) 'lat': lat,
                      if (lng != null) 'lng': lng,
                    };
                    final ok = await controller.patchEarnProfile(params);
                    if (ok && ctx.mounted) Navigator.pop(ctx);
                  },
                ),
                SizedBox(height: MediaQuery.of(ctx).padding.bottom),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
