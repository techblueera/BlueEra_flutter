import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/environment_config.dart';
import 'package:BlueEra/features/personal/personal_profile/view/account_setting_screen/account_settings_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/help_and_support_screen/help_and_support_screen.dart';
import 'package:BlueEra/l10n/app_localizations.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_dialog.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/widgets/webview_common.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../chat/auth/controller/chat_view_controller.dart';

class ProfileSettingsNewScreen extends StatelessWidget {
  const ProfileSettingsNewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        title: 'Settings',
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(
            vertical: SizeConfig.size20,
            horizontal: SizeConfig.size15,
          ),
          child: Column(
            children: [
              CustomFormCard(
                padding: EdgeInsets.symmetric(
                  horizontal: SizeConfig.size15,
                ),
                  child: Column(
                     children: [
                       // _buildTile(
                       //     AppIconAssets.cards, "My Cards",
                       //     onTap: () => Get.toNamed(RouteHelper.getMoreCardsScreenRoute(),
                       //         arguments: {ApiKeys.isFromHomeScreen: false})
                       // ),
                       _buildTile(
                           AppIconAssets.accountSetting,
                           "App Settings",
                           onTap: () => Get.to(() => AccountSettingScreen())
                       ),
                       _buildTile(
                           AppIconAssets.accountSetting,
                           "Account Settings",
                           onTap: () => Get.to(() => AccountSettingScreen())
                       ),
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
                       _buildTile(
                         AppIconAssets.helpSupport,
                         "Help & Support",
                         onTap: () => Get.to(() => HelpAndSupportScreen()),
                       ),
                     ],
                  )
              ),
              SizedBox(height: SizeConfig.size10),
              CustomFormCard(
                 child: Column(
                   children: [
                     CustomBtn(
                       onTap: () async {
                         await showCommonDialog(
                             context: context,
                             text:
                             AppLocalizations.of(context)!.areYouSureYouWantToLogout,
                             confirmCallback: () async {
                               Get.delete<ChatViewController>();
                               await SharedPreferenceUtils.clearPreference();
                               Navigator.of(context).pushNamedAndRemoveUntil(
                                   RouteHelper.getMobileNumberLoginRoute(),
                                       (Route<dynamic> route) => false);
                             },
                             cancelCallback: () {
                               Navigator.of(context).pop(); // Close the dialog
                             },
                             confirmText: AppLocalizations.of(context)!.yes,
                             cancelText: AppLocalizations.of(context)!.no);
                       },
                       title: "Logout",
                       bgColor: Colors.white,
                       textColor: AppColors.primaryColor,
                       borderColor: AppColors.primaryColor,
                       radius: 10.0
                     ),
                     SizedBox(height: 20),
                     CustomBtn(
                       onTap: () async {
                         await showCommonDialog(
                             context: context,
                             text: "Are you sure you want to delete account?",
                             confirmCallback: () async {
                               // Get.find<AuthController>().deleteUserController();
                               await SharedPreferenceUtils.clearPreference();
                               Navigator.of(context).pushNamedAndRemoveUntil(
                                   RouteHelper.getMobileNumberLoginRoute(),
                                       (Route<dynamic> route) => false);
                             },
                             cancelCallback: () {
                               Navigator.of(context).pop(); // Close the dialog
                             },
                             confirmText: AppLocalizations.of(context)!.yes,
                             cancelText: AppLocalizations.of(context)!.no);
                       },
                       title: "Delete My Account",
                       bgColor: Colors.white,
                       textColor: AppColors.red00,
                       borderColor: AppColors.red00,
                       radius: 10.0
                     ),
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
                                     text: 'Terms & Conditions',
                                     style: const TextStyle(
                                       color: AppColors.primaryColor,
                                       fontFamily: AppConstants.OpenSans,
                                     ),
                                     recognizer: TapGestureRecognizer()
                                       ..onTap = () {
                                         Get.to(()=> CommonWebView(
                                           urlLink: tncLink,
                                           urlTitle: 'Terms & Conditions',
                                         ));
                                         // Handle Terms & Conditions tap
                                         print('Tapped Terms & Conditions');
                                       },
                                   ),
                                   const TextSpan(text: ' and '),
                                   TextSpan(
                                     text: 'Privacy Policy.',
                                     style: TextStyle(
                                       color: AppColors.primaryColor,
                                       fontFamily: AppConstants.OpenSans,
                                     ),
                                     recognizer: TapGestureRecognizer()
                                       ..onTap = () {
                                         Get.to(CommonWebView(
                                           urlLink: privacyLink,
                                           urlTitle: 'Privacy Policy',
                                         ));

                                         // Handle Privacy Policy tap
                                         print('Tapped Privacy Policy');
                                       },
                                   ),
                                 ],
                               ),
                             ),
                           ),

                           // Text("Terms & Conditions, Privacy Policy",
                           //     style: TextStyle(fontSize: 12)),
                           // Text("See all policies",
                           //     style: TextStyle(
                           //         fontSize: 12,
                           //         fontWeight: FontWeight.bold,
                           //         color: Colors.blue)),
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
                                 " Make in India",
                                 fontSize: 12,
                               ),
                             ],
                           ),
                         ],
                       ),
                     )
                   ],
                 )
             ),
           ]
          ),
        ),
      ),
    );
  }

  Widget _buildTile(String icon, String title,
      {VoidCallback? onTap}) {
    return Padding(
      padding:  EdgeInsets.symmetric(vertical: SizeConfig.size18),
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
                    width: SizeConfig.size24
                ),
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
          // Padding(
          //   padding: const EdgeInsets.symmetric(horizontal: 10.0),
          //   child: Divider(
          //     thickness: 1,
          //     color: Color.fromRGBO(186, 199, 210, 1),
          //   ),
          // ),
        ],
      ),
    );
  }

}
