import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/language_localization_service/language_controller_new.dart';
import 'package:BlueEra/features/personal/personal_profile/view/account_setting_screen/account_settings_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/update_profile_view.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';

import '../widget/changes_languages_screen.dart';

class AccountSettingScreen extends StatefulWidget {
  const AccountSettingScreen({super.key});

  @override
  State<AccountSettingScreen> createState() => _AccountSettingScreenState();
}

class _AccountSettingScreenState extends State<AccountSettingScreen> {
  final AccountSettingsController accountController =
      Get.put(AccountSettingsController());
  final controller = Get.put(LanguageControllerNew());

  @override
  void initState() {
    super.initState();
    accountController.setTitle("Account & Settings");
    accountController.setIndex('0');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.whiteF3,
      appBar: CommonBackAppBar(
        onBackTap: () {
          if (accountController.index == '0') {
            Navigator.pop(context);
          } else {
            accountController.setIndex("0");
            accountController.setTitle("Account & Settings");
          }
        },
        title: AppStrings.appSettings,
        isLeading: true,
      ),
      body: Padding(
        padding: EdgeInsets.all(SizeConfig.size16),
        child: Obx(() {
          // ✅ Safe Navigation
          if (accountController.index == '1') {
            Future.microtask(() {
              accountController.setIndex('0');
              navigatePushTo(context, UpdateProfileScreen());
            });
            return SizedBox();
          } else if (accountController.index == '2') {
            return Column(
              children: [
                // SizedBox(height: SizeConfig.size20),
                // _buildHelpFormSection(accountController),
              ],
            );
          } else if (accountController.index == '3') {
            return Text("Data");
            // QueriesCard();
          } else if (accountController.index == '4') {
            Future.microtask(() {
              accountController.setIndex('0');
              navigatePushTo(context, ChangeLanguageScreen());
            });
            return SizedBox();
          }

          return Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    // SizedBox(height: SizeConfig.size20),
                    _helpServiceCard(
                      AppIconAssets.personIcon,
                      AppStrings.editProfile,
                          () {
                        accountController.setIndex("1");
                        accountController.setTitle("Edit Profile");
                      },
                    ),
                    // SizedBox(height: SizeConfig.size20),
                    _helpServiceCard(
                      AppIconAssets.call,
                      AppStrings.changePhoneNumber,
                          () {
                        accountController.setIndex("2");
                        accountController.setTitle("Change Phone number");
                      },
                    ),
                    // SizedBox(height: SizeConfig.size20),
                    Container(
                      padding: EdgeInsets.only(
                        left: SizeConfig.size10,
                        // right: SizeConfig.size10,
                        // bottom: SizeConfig.size10,
                      ),
                      child: buildSettingItem(
                        imagePath: AppIconAssets.notificationOutlineIcon,
                        title:AppStrings.allNotification,
                        control: buildToggleSwitch(
                          value: accountController.allnotify,
                          onChanged:
                          accountController.toggleAllNotification,
                        ),
                      ),
                    )
                  ],
                ),
              ),
              SizedBox(height: SizeConfig.size20),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    _helpServiceCard(
                      AppIconAssets.languageIcon,
                      AppStrings.language,slugId: "Language",
                          () {
                        accountController.setIndex("4");
                        accountController.setTitle("Language");
                      },
                    ),
                    _helpServiceCard(
                      AppIconAssets.verifiedTickIcon,
                      AppStrings.verificationStatus,slugId:  "Verification Status",
                          () {
                        accountController.setIndex("5");
                        accountController.setTitle("Verification Status");
                      },
                    ),
                    Padding(
                      padding:  EdgeInsets.only(right: 5),
                      child: _helpServiceCard(
                        AppIconAssets.walletIcon,
                        AppStrings.manageSubscription,
                        slugId: "Manage Subscription",
                            () {
                          accountController.setIndex("6");
                          accountController.setTitle("Manage Subscription");
                        },
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: SizeConfig.size20),
              /*   Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      SizedBox(height: SizeConfig.size20),
                      _helpServiceCard(
                        AppIconAssets.deleteIcon,
                        'Delete Account',
                        () {
                          accountController.setIndex("7");
                          accountController.setTitle("Delete Account");
                        },
                      ),
                      SizedBox(height: SizeConfig.size20),
                      _helpServiceCard(
                        AppIconAssets.logout,
                        'Logout',
                        () {
                          accountController.setIndex("8");
                          accountController.setTitle("Logout");
                        },
                      ),
                    ],
                  ),
                ),*/
            ],
          );
        }),
      ),
    );
  }
}

// Reusable Card Widget
Widget _helpServiceCard(
    String iconPath, String title, GestureTapCallback? onTap,{String? slugId}) {
  Get.put(AccountSettingsController());
  final lang = Get.put(LanguageControllerNew());

  return InkWell(
    onTap: onTap,
    child: Container(
      padding: EdgeInsets.symmetric(
        // vertical: SizeConfig.size4,
        horizontal: SizeConfig.size4,
      ),
      margin: EdgeInsets.symmetric(horizontal: 1),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20)
      ),
      child:    Row(
        children: [
          Container(
            margin: EdgeInsets.all(SizeConfig.size5),
            padding: EdgeInsets.all(SizeConfig.size10),
            child: SvgPicture.asset(
              iconPath,
              color: Colors.black,
              height: 18,
              width: 18,
            ),
          ),
          SizedBox(width: SizeConfig.size10),
          Expanded(
            child: CustomText(
              title,
              fontSize: SizeConfig.medium,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          if (slugId == "Language")
            Padding(
              padding:  EdgeInsets.only(right: 8.0),
              child: CustomText(lang.selectedLang.toUpperCase()),
            ),
          if (slugId == "Verification Status")
            Container(
              margin: EdgeInsets.all(SizeConfig.size5),
              padding: EdgeInsets.all(SizeConfig.size5),
              decoration: BoxDecoration(
                  color: AppColors.green39,
                  borderRadius: BorderRadius.circular(10)),
              child: CustomText(
                "Owner Verified",
                fontSize: SizeConfig.size10,
                fontWeight: FontWeight.w400,
                color: Colors.black87,
              ),
            ),
          if (slugId == "Manage Subscription")
            CustomText(
              AppStrings.freePlan,
              fontSize: SizeConfig.medium,
              fontWeight: FontWeight.w400,
              color: AppColors.primaryColor,
            ),
        ],
      ),
    ),
  );
}

Widget buildSettingItem({
  required String imagePath, // <-- Replace IconData with image path
  required String title,
  required Widget control,
}) {
  return Row(
    children: [
      // Image Container
      Container(
        width: 40,
        // height: 40,
        // decoration: BoxDecoration(
        //   color: Colors.grey[100],
        //   borderRadius: BorderRadius.circular(8),
        // ),
        child: Padding(
          padding: EdgeInsets.all(0), // optional padding
          child: LocalAssets(
            imagePath:imagePath,
            boxFix: BoxFit.contain,
          ),
        ),
      ),
      SizedBox(width: SizeConfig.size12),

      // Title
      Expanded(
        child: CustomText(
          title,
          fontSize: SizeConfig.medium,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),

      SizedBox(width: SizeConfig.size12),

      // Control
      control,
    ],
  );
}

Widget buildToggleSwitch({
  required RxBool value,
  required VoidCallback onChanged,
}) {
  return Obx(() => Transform.scale(
        scale: 0.75, // Adjust scale to reduce size
        child: Switch(
          value: value.value,
          onChanged: (val) => onChanged(),
          activeColor: AppColors.primaryColor,
          activeTrackColor: AppColors.primaryColor.withValues(alpha: 0.3),
          inactiveTrackColor: Colors.grey[300],
          inactiveThumbColor: Colors.grey[400],
        ),
      ));
}

Widget buildToggleSwitchChip({
  required RxBool value,
  required VoidCallback onChanged,
}) {
  return Obx(() => Transform.scale(
        scale: 0.6, // Adjust scale to reduce size
        child: Switch(
          value: value.value,
          onChanged: (val) => onChanged(),
          activeColor: AppColors.white,
          activeTrackColor: AppColors.primaryColor,
          inactiveTrackColor: Colors.grey[300],
          inactiveThumbColor: Colors.grey[400],
        ),
      ));
}
