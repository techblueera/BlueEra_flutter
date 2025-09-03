import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/personal/personal_profile/controller/languge_list_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/account_setting_screen/account_settings_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/help_and_support_screen/help_and_support_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/profile_setup_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/update_profile_view.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
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

  @override
  void initState() {
    super.initState();
    accountController.setTitle("Account & Settings");
    accountController.setIndex('0');
  }

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: CommonBackAppBar(
          onBackTap: () {
            if (accountController.index == '0') {
              Navigator.pop(context);
            } else {
              accountController.setIndex("0");
              accountController.setTitle("Account & Settings");
            }
          },
          title: accountController.title.value,
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
                  SizedBox(height: SizeConfig.size20),
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
                      SizedBox(height: SizeConfig.size20),
                      _helpServiceCard(
                        AppIconAssets.personIcon,
                        'Edit Profile',
                        () {
                          accountController.setIndex("1");
                          accountController.setTitle("Edit Profile");
                        },
                      ),
                      SizedBox(height: SizeConfig.size20),
                      _helpServiceCard(
                        AppIconAssets.call,
                        'Change Phone number',
                        () {
                          accountController.setIndex("2");
                          accountController.setTitle("Change Phone number");
                        },
                      ),
                      SizedBox(height: SizeConfig.size20),
                       Padding(
              padding: EdgeInsets.only(
                left: SizeConfig.size16,
                right: SizeConfig.size16,
                bottom: SizeConfig.size10,
              ),
              child: _buildSettingItem(
                imagePath: AppIconAssets.notificationOutlineIcon,
                title: 'All Notification',
                control: _buildToggleSwitch(
                  value: accountController.allnotify,
                  onChanged: accountController.toggleAllNotification,
                ),
              ))
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
                      SizedBox(height: SizeConfig.size20),
                      _helpServiceCard(
                        AppIconAssets.languageIcon,
                        'Language',
                        () {
                          accountController.setIndex("4");
                          accountController.setTitle("Language");
                        },
                      ),
                      SizedBox(height: SizeConfig.size20),
                      _helpServiceCard(
                        AppIconAssets.verifiedTickIcon,
                        'Verification Status',
                        () {
                          accountController.setIndex("5");
                          accountController.setTitle("Verification Status");
                        },
                      ),
                      SizedBox(height: SizeConfig.size20),
                      _helpServiceCard(
                        AppIconAssets.walletIcon,
                        'Manage Subscription',
                        () {
                          accountController.setIndex("6");
                          accountController.setTitle("Manage Subscription");
                        },
                      ),
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
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}




// Reusable Card Widget
Widget _helpServiceCard(String iconPath, String title, GestureTapCallback? onTap) {
  final controller = Get.put(AccountSettingsController());
  final lang = Get.put(LanguageListController());

  final bool showNotificationSettings = title == "All Notification";

  return InkWell(
    onTap: onTap,
    child: Container(
      padding: EdgeInsets.symmetric(
        vertical: SizeConfig.size4,
        horizontal: SizeConfig.size4,
      ),
      margin: EdgeInsets.symmetric(horizontal: 1),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main row with icon and title
          Row(
            children: [
              Container(
                margin: EdgeInsets.all(SizeConfig.size10),
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
              if(title=="Language")
               Text(lang.selectedLanguageName.toUpperCase()),
               if(title=="Verification Status")
               
               Container(
                 margin: EdgeInsets.all(SizeConfig.size5),
                padding: EdgeInsets.all(SizeConfig.size5),
                decoration: BoxDecoration(
                  color: AppColors.green39,
                  borderRadius: BorderRadius.circular(10)

                ),
                 child: CustomText("Owner Verified", fontSize: SizeConfig.size10,
                  fontWeight: FontWeight.w400,
                  color: Colors.black87,
                               ),
               ),
               if(title=="Manage Subscription")
               
               CustomText("Free Plan", fontSize: SizeConfig.medium,
                fontWeight: FontWeight.w400,
                color: Colors.blue,
                             ),
            ],
          ),

          // Conditionally show additional setting
          // if (showNotificationSettings)
          //   Padding(
          //     padding: EdgeInsets.only(
          //       left: SizeConfig.size16,
          //       right: SizeConfig.size16,
          //       bottom: SizeConfig.size10,
          //     ),
          //     child: _buildSettingItem(
          //       imagePath: ,
          //       title: 'All Notification',
          //       control: _buildToggleSwitch(
          //         value: controller.allnotify,
          //         onChanged: controller.toggleAllNotification,
          //       ),
          //     ),
          //   ),
        ],
      ),
    ),
  );
}

Widget _buildSettingItem({
    required String imagePath, // <-- Replace IconData with image path
    required String title,
    required Widget control,
  }) {

    return Padding(
      padding: EdgeInsets.symmetric(vertical: SizeConfig.size12),
      child: Row(
        children: [
          // Image Container
          Container(
            width: 40,
            height: 40,
            // decoration: BoxDecoration(
            //   color: Colors.grey[100],
            //   borderRadius: BorderRadius.circular(8),
            // ),
            child: Padding(
              padding: EdgeInsets.all(8), // optional padding
              child: SvgPicture.asset(
                imagePath,
                fit: BoxFit.contain,
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
      ),
    );
  

}
  Widget _buildToggleSwitch({
    required RxBool value,
    required VoidCallback onChanged,
  }) {
    return Obx(() => Transform.scale(
      scale: 0.75, // Adjust scale to reduce size
      child: Switch(
        value: value.value,
        onChanged: (val) => onChanged(),
        activeColor: AppColors.primaryColor,
        activeTrackColor: AppColors.primaryColor.withOpacity(0.3),
        inactiveTrackColor: Colors.grey[300],
        inactiveThumbColor: Colors.grey[400],
      ),
    ));
  }
