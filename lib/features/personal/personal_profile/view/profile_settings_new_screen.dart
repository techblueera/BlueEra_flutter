import 'dart:developer';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/core/services/hive_services.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/environment_config.dart';
import 'package:BlueEra/features/personal/personal_profile/view/account_setting_screen/account_settings_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/help_and_support_screen/help_and_support_screen.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_dialog.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/widgets/webview_common.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

import '../../../chat/auth/controller/chat_view_controller.dart';
import '../../../chat/auth/service/location_update_service.dart';
import '../../../common/referral/view/referral_page.dart';

class ProfileSettingsNewScreen extends StatelessWidget {
  const ProfileSettingsNewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final LiveLocationService locationService = LiveLocationService();

    return Scaffold(
      appBar: CommonBackAppBar(
        title: AppStrings.settings,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(
            vertical: SizeConfig.size20,
            horizontal: SizeConfig.size15,
          ),
          child: Column(children: [
            CustomFormCard(
                padding: EdgeInsets.symmetric(
                  horizontal: SizeConfig.size15,
                ),
                child: Column(
                  children: [
                    _buildTile(AppIconAssets.accountSetting,
                        AppStrings.accountSettings,
                        onTap: () => Get.to(() => AccountSettingScreen())),
                    _buildTile(AppIconAssets.takeFranchiseIcon,
                        AppStrings.applyForFranchise,
                        onTap: () => Get.to(() => CommonWebView(
                              urlLink: takeFranchise,
                              urlTitle: AppStrings.applyForFranchise,
                            ))),
                    _buildTile(AppIconAssets.referral, AppStrings.referral,
                        onTap: () => Get.to(() => ReferralPage())),
                    _buildTile(
                      AppIconAssets.helpSupport,
                      AppStrings.helpSupport,
                      onTap: () => Get.to(() => HelpAndSupportScreen()),
                    ),
                    // _buildTile(
                    //     AppIconAssets.cards, "My Cards",
                    //     onTap: () => Get.toNamed(RouteHelper.getMoreCardsScreenRoute(),
                    //         arguments: {ApiKeys.isFromHomeScreen: false})
                    // ),
                    // _buildTile(
                    //     AppIconAssets.accountSetting,
                    //     AppStrings.appSettings,
                    //     onTap: () => Get.to(() => AccountSettingScreen())
                    // ),

                    // _buildTile(
                    //     AppIconAssets.accountSetting,
                    //     "Account Settings",
                    //     "Language/Delete Account & More",
                    //     onTap: () => Get.to(() => AccountSettingScreen())
                    // ),
                    // _buildTile(
                    //     AppIconAssets.accountSetting,
                    //     "Account Settings",
                    //     "Language/Delete Account & More",
                    //     onTap: () => Get.to(() => AccountSettingScreen())
                    // ),
                    // _buildTile(
                    //     AppIconAssets.accountSetting,
                    //     "Account Settings",
                    //     "Language/Delete Account & More",
                    //     onTap: () => Get.to(() => AccountSettingScreen())
                    // ),
                  ],
                )),
            SizedBox(height: SizeConfig.size10),
            CustomFormCard(
                child: Column(
              children: [
                CustomBtn(
                    onTap: () async {
                      await showCommonDialog(
                          context: context,
                          text: AppStrings.logoutConfirmationMessage,
                          confirmCallback: () async {
                            deleteIfRegistered<ChatViewController>();
                            await SharedPreferenceUtils.clearPreference();
                            locationService.stop();
                            await clearAllLocalDataOnLogout();
                            Navigator.of(context).pushNamedAndRemoveUntil(
                                RouteHelper.getMobileNumberLoginRoute(),
                                (Route<dynamic> route) => false);
                          },
                          cancelCallback: () {
                            Navigator.of(context).pop(); // Close the dialog
                          },
                          confirmText: AppStrings.yes,
                          cancelText: AppStrings.no);
                    },
                    title: AppStrings.logout,
                    bgColor: Colors.white,
                    textColor: AppColors.primaryColor,
                    borderColor: AppColors.primaryColor,
                    radius: 10.0),
                SizedBox(height: 20),
                CustomBtn(
                    onTap: () async {
                      await showCommonDialog(
                          context: context,
                          text: AppStrings.deleteAccountConfirmationMessage,
                          confirmCallback: () async {
                            await SharedPreferenceUtils.clearPreference();
                            Navigator.of(context).pushNamedAndRemoveUntil(
                                RouteHelper.getMobileNumberLoginRoute(),
                                (Route<dynamic> route) => false);
                          },
                          cancelCallback: () {
                            Navigator.of(context).pop(); // Close the dialog
                          },
                          confirmText: AppStrings.yes,
                          cancelText: AppStrings.no);
                    },
                    title: AppStrings.deleteAccount,
                    bgColor: Colors.white,
                    textColor: AppColors.red00,
                    borderColor: AppColors.red00,
                    radius: 10.0),
                SizedBox(height: 20),
                Center(
                  child: Column(
                    children: [
                      SizedBox(height: 8),
                      Center(
                        child: RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black87,
                            ),
                            children: [
                              TextSpan(
                                text: AppStrings.termsConditions.tr,
                                style: const TextStyle(
                                  color: AppColors.primaryColor,
                                  fontFamily: AppConstants.OpenSans,
                                ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    Get.to(() => CommonWebView(
                                          urlLink: tncLink,
                                          urlTitle:
                                              AppStrings.termsConditions.tr,
                                        ));
                                    // Handle Terms & Conditions tap
                                  },
                              ),
                              const TextSpan(text: ' & '),
                              TextSpan(
                                text: AppStrings.privacyPolicy.tr,
                                style: TextStyle(
                                  color: AppColors.primaryColor,
                                  fontFamily: AppConstants.OpenSans,
                                ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    Get.to(CommonWebView(
                                      urlLink: privacyLink,
                                      urlTitle: AppStrings.privacyPolicy.tr,
                                    ));
                                  },
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CustomText(
                            "v ${appVersion} | ",
                            fontSize: 12,
                          ),
                          LocalAssets(imagePath: AppIconAssets.india_flag),
                          CustomText(
                            " ${AppStrings.makeInIndia.tr}",
                            fontSize: 12,
                          ),
                        ],
                      ),
                    ],
                  ),
                )
              ],
            )),
          ]),
        ),
      ),
    );
  }

  Future<void> clearAllLocalDataOnLogout() async {
    try {
      // 1️⃣ Clear all Hive boxes
      await Hive.deleteFromDisk();

      // 2️⃣ Clear stored media files
      final dir = await getApplicationDocumentsDirectory();
      if (dir.existsSync()) {
        await dir.delete(recursive: true);
      }
      log("✅ Local storage cleared successfully");

      await HiveServices.init();
      log("✅ All Hive data wiped and boxes re-opened successfully.");

    } catch (e) {
      log("❌ Error clearing local data: $e");
    }
  }

  Widget _buildTile(String icon, String title, {VoidCallback? onTap}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: SizeConfig.size18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onTap,
            child: Row(
              children: [
                LocalAssets(
                    imagePath: icon,
                    height: SizeConfig.size24,
                    width: SizeConfig.size24),
                SizedBox(width: SizeConfig.size10),
                CustomText(
                  title,
                  fontFamily: AppConstants.OpenSans,
                  fontSize: SizeConfig.large,
                  fontWeight: FontWeight.w400,
                  color: AppColors.mainTextColor,
                ),
                Spacer(),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Color.fromRGBO(122, 139, 154, 1),
                ),
              ],
            ),
          ),
        ],
      ),

    );
  }
}
