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
import 'package:get/get.dart';

import '../../../../../core/constants/getx_utils.dart';
import '../widget/changes_languages_screen.dart';

class AccountSettingScreen extends StatefulWidget {
  const AccountSettingScreen({super.key});

  @override
  State<AccountSettingScreen> createState() => _AccountSettingScreenState();
}

class _AccountSettingScreenState extends State<AccountSettingScreen> {
  final AccountSettingsController accountController =
  Get.put(AccountSettingsController());
  final controller = getOrPut(() => LanguageControllerNew());


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

          return ListView(
            padding: EdgeInsets.symmetric(horizontal: SizeConfig.size16),
            children: [

              SizedBox(height: SizeConfig.size16),

              _helpServiceCard(
                AppIconAssets.app_setting_edit_profile,
                AppStrings.editProfile,
                    () {
                  accountController.setIndex("1");
                  accountController.setTitle("Edit Profile");
                },
              ),

              _helpServiceCard(
                AppIconAssets.editIcon,
                "Edit Category",
                    () {
                  accountController.setIndex("9");
                  accountController.setTitle("Edit Category");
                },
              ),

              _helpServiceCard(
                AppIconAssets.app_setting_change_phone_number,
                AppStrings.changePhoneNumber,
                    () {
                  accountController.setIndex("2");
                  accountController.setTitle("Change Phone number");
                },
              ),

              _helpServiceCard(
                AppIconAssets.emotionUpdate,
                "Change Your Email",
                    () {
                  accountController.setIndex("10");
                  accountController.setTitle("Change Email");
                },
              ),

              _helpServiceCard(
                AppIconAssets.verifiedIcon,
                "Email Verification",
                    () {},
                slugId: "Email Verification",
              ),

              _helpServiceCard(
                AppIconAssets.app_setting_language,
                AppStrings.language,
                    () {
                  accountController.setIndex("4");
                  accountController.setTitle("Language");
                },
                slugId: "Language",
              ),

              _helpServiceCard(
                AppIconAssets.app_setting_verification,
                AppStrings.verificationStatus,
                    () {
                  accountController.setIndex("5");
                  accountController.setTitle("Verification Status");
                },
                slugId: "Verification Status",
              ),

              _helpServiceCard(
                AppIconAssets.app_setting_manage_subscription,
                AppStrings.manageSubscription,
                    () {
                  accountController.setIndex("6");
                  accountController.setTitle("Manage Subscription");
                },
                slugId: "Manage Subscription",
              ),

              _helpServiceCard(
                AppIconAssets.about_us,
                "Two Step Authentication",
                    () {
                  accountController.setIndex("7");
                  accountController.setTitle("Two Step Authentication");
                },
              ),

              _helpServiceCard(
                AppIconAssets.deleteIcon,
                "Account Delete",
                    () {
                  accountController.setIndex("8");
                  accountController.setTitle("Delete Account");
                },
              ),

              _helpServiceCard(
                AppIconAssets.logout,

                "Device Logout",
                    () {
                  accountController.setIndex("11");
                  accountController.setTitle("Device Logout");
                },
              ),

              SizedBox(height: SizeConfig.size30),
            ],
          );
        }),
      ),
    );
  }
}

Widget _helpServiceCard(
    String iconPath,
    String title,
    GestureTapCallback? onTap,
    {String? slugId}) {

  final lang = getOrPut(() => LanguageControllerNew());

  return Padding(
    padding: EdgeInsets.only(bottom: SizeConfig.size14),
    child: InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.size16,
          vertical: SizeConfig.size16,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [

            LocalAssets(
              imagePath: iconPath,
              height: 22,
              width: 22,
              boxFix: BoxFit.contain,
              imgColor: AppColors.mainTextColor,
            ),

            SizedBox(width: SizeConfig.size14),

            Expanded(
              child: CustomText(
                title,
                fontSize: SizeConfig.medium,
                color: AppColors.mainTextColor,
              ),
            ),

            if (slugId == "Email Verification")
              _greenChip("Verified"),

            if (slugId == "Language")
              _greyChip(lang.selectedLang.value),

            if (slugId == "Verification Status")
              _greenChip("Owner Verified"),

            if (slugId == "Manage Subscription")
              CustomText(
                "Free Plan",
                color: AppColors.primaryColor,
              ),
          ],
        ),
      ),
    ),
  );
}
Widget _greenChip(String text) {
  return Container(
    padding: EdgeInsets.symmetric(
      horizontal: SizeConfig.size14,
      vertical: SizeConfig.size6,
    ),
    decoration: BoxDecoration(
      color: AppColors.green4F,
      borderRadius: BorderRadius.circular(20),
    ),
    child: CustomText(
      text,
      fontSize: SizeConfig.size10,
      color: Colors.white,
    ),
  );
}
Widget _greyChip(String text) {
  return Container(
    padding: EdgeInsets.symmetric(
      horizontal: SizeConfig.size14,
      vertical: SizeConfig.size6,
    ),
    decoration: BoxDecoration(
      color: Colors.grey.shade200,
      borderRadius: BorderRadius.circular(20),
    ),
    child: CustomText(
      text,
      fontSize: SizeConfig.size10,
      color: AppColors.mainTextColor,
    ),
  );
}


Widget buildSettingItem({
  required String imagePath,
  required String title,
  required Widget control,
}) {
  return Padding(
    padding: EdgeInsets.only(bottom: SizeConfig.size14),
    child: Container(
      padding: EdgeInsets.symmetric(
        horizontal: SizeConfig.size14,
        vertical: SizeConfig.size14,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          LocalAssets(
            imagePath: imagePath,
            height: 22,
            width: 22,
          ),
          SizedBox(width: SizeConfig.size14),
          Expanded(
            child: CustomText(title),
          ),
          control,
        ],
      ),
    ),
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